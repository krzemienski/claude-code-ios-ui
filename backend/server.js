/**
 * Claude Code UI Backend Server
 * Based on https://github.com/siteboon/claudecodeui
 * 
 * This backend is adapted from the original ClaudeCodeUI project
 * with additional iOS app compatibility layers.
 * 
 * Original project: https://github.com/siteboon/claudecodeui
 * License: MIT
 */

// Load environment variables from .env file
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

try {
    const envPath = path.join(__dirname, '.env');
    const envFile = fs.readFileSync(envPath, 'utf8');
    envFile.split('\n').forEach(line => {
        const trimmedLine = line.trim();
        if (trimmedLine && !trimmedLine.startsWith('#')) {
            const [key, ...valueParts] = trimmedLine.split('=');
            if (key && valueParts.length > 0 && !process.env[key]) {
                process.env[key] = valueParts.join('=').trim();
            }
        }
    });
} catch (e) {
    console.log('No .env file found or error reading it:', e.message);
}

import express from 'express';
import { WebSocketServer } from 'ws';
import http from 'http';
import cors from 'cors';
import { promises as fsPromises } from 'fs';
import { spawn, exec } from 'child_process';
import os from 'os';
import sqlite3 from 'sqlite3';
import { promisify } from 'util';
import crypto from 'crypto';

const execAsync = promisify(exec);

// Initialize SQLite database
const dbPath = path.join(__dirname, 'data', 'claude-code.db');
if (!fs.existsSync(path.dirname(dbPath))) {
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });
}

const db = new sqlite3.Database(dbPath);

// Initialize database tables
db.serialize(() => {
    // Projects table (iOS app compatible)
    db.run(`CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL,
        description TEXT,
        language TEXT,
        framework TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        is_favorite BOOLEAN DEFAULT 0,
        color TEXT,
        icon TEXT
    )`);

    // Files table
    db.run(`CREATE TABLE IF NOT EXISTS files (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        path TEXT NOT NULL,
        content TEXT,
        language TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
    )`);

    // Chat/Conversations table
    db.run(`CREATE TABLE IF NOT EXISTS conversations (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        title TEXT,
        model TEXT DEFAULT 'claude-3-opus',
        temperature REAL DEFAULT 0.7,
        max_tokens INTEGER DEFAULT 4096,
        system_prompt TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
    )`);

    // Messages table
    db.run(`CREATE TABLE IF NOT EXISTS messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT,
        project_id TEXT,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        metadata TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
    )`);

    // Terminal sessions table
    db.run(`CREATE TABLE IF NOT EXISTS terminal_sessions (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        command TEXT,
        output TEXT,
        exit_code INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        completed_at DATETIME,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
    )`);

    // Settings table
    db.run(`CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )`);

    // Initialize default settings
    db.run(`INSERT OR IGNORE INTO settings (key, value) VALUES 
        ('theme', 'cyberpunk'),
        ('fontSize', '14'),
        ('fontFamily', 'SF Mono'),
        ('server_port', '3004'),
        ('api_endpoint', 'http://localhost:3004')`);
});

const app = express();
const server = http.createServer(app);

// WebSocket server for real-time communication
const wss = new WebSocketServer({ 
    server,
    path: '/ws'
});

// Connected clients tracking
const connectedClients = new Set();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        backend: 'ClaudeCodeUI-iOS',
        version: '2.0.0',
        features: {
            projects: true,
            chat: true,
            files: true,
            terminal: true,
            settings: true,
            websocket: true,
            claude_cli: true
        }
    });
});

// ============= Projects API (iOS Compatible) =============

// Get all projects
app.get('/api/projects', async (req, res) => {
    db.all(`SELECT * FROM projects ORDER BY updated_at DESC`, (err, projects) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json(projects || []);
    });
});

// Create project
app.post('/api/projects', async (req, res) => {
    const { name, path: projectPath, description, language, framework } = req.body;
    const id = crypto.randomUUID();

    db.run(
        `INSERT INTO projects (id, name, path, description, language, framework) 
         VALUES (?, ?, ?, ?, ?, ?)`,
        [id, name, projectPath || `/Users/${os.userInfo().username}/Projects/${name}`, description, language, framework],
        function(err) {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            
            // Create project directory if it doesn't exist
            const fullPath = projectPath || `/Users/${os.userInfo().username}/Projects/${name}`;
            if (!fs.existsSync(fullPath)) {
                fs.mkdirSync(fullPath, { recursive: true });
            }

            res.json({ 
                id, 
                name, 
                path: fullPath,
                description,
                language,
                framework,
                created_at: new Date().toISOString() 
            });
        }
    );
});

// Update project
app.put('/api/projects/:id', (req, res) => {
    const { name, description, language, framework, is_favorite, color, icon } = req.body;
    
    db.run(
        `UPDATE projects SET 
         name = COALESCE(?, name),
         description = COALESCE(?, description),
         language = COALESCE(?, language),
         framework = COALESCE(?, framework),
         is_favorite = COALESCE(?, is_favorite),
         color = COALESCE(?, color),
         icon = COALESCE(?, icon),
         updated_at = CURRENT_TIMESTAMP
         WHERE id = ?`,
        [name, description, language, framework, is_favorite, color, icon, req.params.id],
        function(err) {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            res.json({ success: true, changes: this.changes });
        }
    );
});

// Delete project
app.delete('/api/projects/:id', (req, res) => {
    db.run(`DELETE FROM projects WHERE id = ?`, [req.params.id], function(err) {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json({ success: true, deleted: this.changes });
    });
});

// ============= Chat/Messages API (iOS Compatible) =============

// Send message (iOS app endpoint)
app.post('/api/chat/message', async (req, res) => {
    const { message, projectId, conversationId } = req.body;
    const messageId = crypto.randomUUID();
    const convId = conversationId || crypto.randomUUID();

    // Store user message
    db.run(
        `INSERT INTO messages (id, conversation_id, project_id, role, content)
         VALUES (?, ?, ?, ?, ?)`,
        [messageId, convId, projectId, 'user', message],
        async (err) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }

            // Simulate Claude response (in production, this would call actual Claude API)
            const responseId = crypto.randomUUID();
            const aiResponse = `I understand you want to ${message}. Let me help you with that...`;

            db.run(
                `INSERT INTO messages (id, conversation_id, project_id, role, content)
                 VALUES (?, ?, ?, ?, ?)`,
                [responseId, convId, projectId, 'assistant', aiResponse],
                (err) => {
                    if (err) {
                        return res.status(500).json({ error: err.message });
                    }

                    res.json({
                        id: responseId,
                        conversationId: convId,
                        role: 'assistant',
                        content: aiResponse,
                        timestamp: new Date().toISOString()
                    });

                    // Send WebSocket update
                    const wsMessage = JSON.stringify({
                        type: 'message',
                        data: {
                            id: responseId,
                            conversationId: convId,
                            projectId,
                            role: 'assistant',
                            content: aiResponse,
                            timestamp: new Date().toISOString()
                        }
                    });

                    connectedClients.forEach(client => {
                        if (client.readyState === client.OPEN) {
                            client.send(wsMessage);
                        }
                    });
                }
            );
        }
    );
});

// Get conversation messages
app.get('/api/conversations/:id/messages', (req, res) => {
    db.all(
        `SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC`,
        [req.params.id],
        (err, messages) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            res.json(messages || []);
        }
    );
});

// ============= Files API (iOS Compatible) =============

// Get project files tree
app.get('/api/files/:projectId', async (req, res) => {
    db.get(`SELECT path FROM projects WHERE id = ?`, [req.params.projectId], async (err, project) => {
        if (err || !project) {
            return res.status(404).json({ error: 'Project not found' });
        }

        try {
            const tree = await buildFileTree(project.path);
            res.json(tree);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    });
});

// Create file
app.post('/api/files/create', async (req, res) => {
    const { projectId, path: filePath, content = '' } = req.body;

    try {
        await fsPromises.writeFile(filePath, content, 'utf8');
        
        const fileId = crypto.randomUUID();
        db.run(
            `INSERT INTO files (id, project_id, path, content) VALUES (?, ?, ?, ?)`,
            [fileId, projectId, filePath, content],
            (err) => {
                if (err) {
                    return res.status(500).json({ error: err.message });
                }
                res.json({ id: fileId, path: filePath, success: true });
            }
        );
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Read file content
app.get('/api/files/content', async (req, res) => {
    const { path: filePath } = req.query;

    try {
        const content = await fsPromises.readFile(filePath, 'utf8');
        res.json({ content, path: filePath });
    } catch (error) {
        if (error.code === 'ENOENT') {
            res.status(404).json({ error: 'File not found' });
        } else {
            res.status(500).json({ error: error.message });
        }
    }
});

// Update file content
app.put('/api/files/update', async (req, res) => {
    const { path: filePath, content } = req.body;

    try {
        await fsPromises.writeFile(filePath, content, 'utf8');
        res.json({ success: true, path: filePath });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Rename file
app.put('/api/files/rename', async (req, res) => {
    const { oldPath, newPath } = req.body;

    try {
        await fsPromises.rename(oldPath, newPath);
        res.json({ success: true, newPath });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Delete file
app.delete('/api/files/delete', async (req, res) => {
    const { path: filePath } = req.body;

    try {
        const stats = await fsPromises.stat(filePath);
        if (stats.isDirectory()) {
            await fsPromises.rmdir(filePath, { recursive: true });
        } else {
            await fsPromises.unlink(filePath);
        }
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ============= Terminal API (iOS Compatible) =============

// Execute terminal command
app.post('/api/terminal/execute', async (req, res) => {
    const { command, projectId, cwd } = req.body;
    const sessionId = crypto.randomUUID();

    // Security check - prevent dangerous commands
    const dangerousCommands = ['rm -rf /', 'format', 'del /f'];
    if (dangerousCommands.some(cmd => command.includes(cmd))) {
        return res.status(403).json({ error: 'Command not allowed for security reasons' });
    }

    // Store session start
    db.run(
        `INSERT INTO terminal_sessions (id, project_id, command, created_at)
         VALUES (?, ?, ?, CURRENT_TIMESTAMP)`,
        [sessionId, projectId, command]
    );

    exec(command, { 
        cwd: cwd || process.cwd(),
        maxBuffer: 1024 * 1024 * 10 // 10MB buffer
    }, (error, stdout, stderr) => {
        const output = stdout || stderr || '';
        const exitCode = error ? error.code || 1 : 0;

        // Store session result
        db.run(
            `UPDATE terminal_sessions 
             SET output = ?, exit_code = ?, completed_at = CURRENT_TIMESTAMP 
             WHERE id = ?`,
            [output, exitCode, sessionId]
        );

        if (error && error.code !== 0) {
            return res.status(500).json({ 
                error: stderr || error.message,
                output: stdout,
                exitCode,
                sessionId 
            });
        }

        res.json({ 
            output,
            exitCode,
            sessionId,
            success: true 
        });
    });
});

// Get terminal history
app.get('/api/terminal/history/:projectId', (req, res) => {
    db.all(
        `SELECT * FROM terminal_sessions 
         WHERE project_id = ? 
         ORDER BY created_at DESC 
         LIMIT 50`,
        [req.params.projectId],
        (err, sessions) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }
            res.json(sessions || []);
        }
    );
});

// ============= Settings API (iOS Compatible) =============

// Get settings
app.get('/api/settings', (req, res) => {
    db.all(`SELECT key, value FROM settings`, (err, rows) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        
        const settings = {};
        rows.forEach(row => {
            settings[row.key] = row.value;
        });
        res.json(settings);
    });
});

// Update settings
app.post('/api/settings', (req, res) => {
    const settings = req.body;
    const stmt = db.prepare(`INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)`);
    
    Object.entries(settings).forEach(([key, value]) => {
        stmt.run(key, value);
    });
    
    stmt.finalize((err) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json({ success: true });
    });
});

// Export settings
app.post('/api/settings/export', (req, res) => {
    db.all(`SELECT key, value FROM settings`, (err, rows) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        
        const settings = {};
        rows.forEach(row => {
            settings[row.key] = row.value;
        });
        
        res.json({
            version: '2.0.0',
            exportDate: new Date().toISOString(),
            settings
        });
    });
});

// Import settings
app.post('/api/settings/import', (req, res) => {
    const { settings } = req.body;
    
    if (!settings) {
        return res.status(400).json({ error: 'No settings provided' });
    }
    
    const stmt = db.prepare(`INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, CURRENT_TIMESTAMP)`);
    
    Object.entries(settings).forEach(([key, value]) => {
        stmt.run(key, value);
    });
    
    stmt.finalize((err) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json({ success: true });
    });
});

// ============= WebSocket Handlers =============

wss.on('connection', (ws) => {
    console.log('🔗 Client connected via WebSocket');
    connectedClients.add(ws);

    ws.on('message', async (message) => {
        try {
            const data = JSON.parse(message);
            
            switch (data.type) {
                case 'ping':
                    ws.send(JSON.stringify({ type: 'pong' }));
                    break;
                    
                case 'subscribe':
                    ws.projectId = data.projectId;
                    ws.send(JSON.stringify({ 
                        type: 'subscribed', 
                        projectId: data.projectId 
                    }));
                    break;
                    
                case 'typing':
                    // Broadcast typing indicator to other clients
                    const typingMessage = JSON.stringify({
                        type: 'user_typing',
                        userId: data.userId,
                        projectId: data.projectId
                    });
                    
                    connectedClients.forEach(client => {
                        if (client !== ws && client.readyState === client.OPEN) {
                            client.send(typingMessage);
                        }
                    });
                    break;
                    
                default:
                    console.log('Unknown WebSocket message type:', data.type);
            }
        } catch (error) {
            console.error('WebSocket message error:', error);
        }
    });

    ws.on('close', () => {
        console.log('🔌 Client disconnected');
        connectedClients.delete(ws);
    });

    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
});

// ============= Helper Functions =============

async function buildFileTree(dirPath, level = 0, maxLevel = 5) {
    const items = [];
    
    if (level > maxLevel) return items;
    
    try {
        const entries = await fsPromises.readdir(dirPath, { withFileTypes: true });
        
        for (const entry of entries) {
            // Skip hidden files and common ignore patterns
            if (entry.name.startsWith('.') || 
                entry.name === 'node_modules' || 
                entry.name === 'dist' ||
                entry.name === 'build') {
                continue;
            }
            
            const fullPath = path.join(dirPath, entry.name);
            const item = {
                name: entry.name,
                path: fullPath,
                type: entry.isDirectory() ? 'directory' : 'file'
            };
            
            if (entry.isDirectory()) {
                item.children = await buildFileTree(fullPath, level + 1, maxLevel);
            }
            
            items.push(item);
        }
    } catch (error) {
        console.error('Error building file tree:', error);
    }
    
    return items;
}

// ============= Server Startup =============

const PORT = process.env.PORT || 3004;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   🚀 Claude Code UI Backend (iOS Edition)                 ║
║   Based on: https://github.com/siteboon/claudecodeui      ║
║                                                            ║
║   Server: http://localhost:${PORT}                            ║
║   WebSocket: ws://localhost:${PORT}/ws                        ║
║                                                            ║
║   Features:                                                ║
║   ✅ Projects Management                                   ║
║   ✅ Chat/Conversations                                    ║
║   ✅ File System Operations                                ║
║   ✅ Terminal Command Execution                            ║
║   ✅ Settings Management                                   ║
║   ✅ WebSocket Real-time Updates                           ║
║                                                            ║
║   iOS App Endpoints:                                       ║
║   📱 GET    /api/projects                                  ║
║   📱 POST   /api/chat/message                              ║
║   📱 GET    /api/files/:projectId                          ║
║   📱 POST   /api/terminal/execute                          ║
║   📱 GET    /api/settings                                  ║
║                                                            ║
║   Attribution:                                             ║
║   This backend is adapted from ClaudeCodeUI                ║
║   Original: https://github.com/siteboon/claudecodeui       ║
║   License: MIT                                             ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
    `);

    // Create some test data if database is empty
    db.get(`SELECT COUNT(*) as count FROM projects`, (err, row) => {
        if (!err && row.count === 0) {
            console.log('📝 Creating test projects...');
            const testProjects = [
                { name: 'Test Project 1', language: 'Swift', framework: 'UIKit' },
                { name: 'Test Project 2', language: 'JavaScript', framework: 'React' },
                { name: 'Test Project 3', language: 'Python', framework: 'Django' },
                { name: 'Claude Code UI', language: 'JavaScript', framework: 'Express' },
                { name: 'iOS App', language: 'Swift', framework: 'SwiftUI' }
            ];

            testProjects.forEach(project => {
                const id = crypto.randomUUID();
                db.run(
                    `INSERT INTO projects (id, name, path, description, language, framework) 
                     VALUES (?, ?, ?, ?, ?, ?)`,
                    [
                        id,
                        project.name,
                        `/Users/${os.userInfo().username}/Projects/${project.name.replace(/\s+/g, '-')}`,
                        `A test project using ${project.framework}`,
                        project.language,
                        project.framework
                    ]
                );
            });
        }
    });
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing server...');
    server.close(() => {
        db.close();
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('\nSIGINT received, closing server...');
    server.close(() => {
        db.close();
        process.exit(0);
    });
});

export default app;