const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const { WebSocketServer } = require('ws');
const multer = require('multer');
const sqlite3 = require('sqlite3').verbose();
const morgan = require('morgan');
const compression = require('compression');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const path = require('path');
const http = require('http');

// Load environment variables
require('dotenv').config();

// Create Express app
const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3004;

// Create necessary directories
const dirs = ['data', 'uploads', 'logs'];
dirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Database setup
const db = new sqlite3.Database('./data/database.sqlite');

// Initialize database tables
db.serialize(() => {
  // Projects table
  db.run(`CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT,
    status TEXT DEFAULT 'active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Messages table
  db.run(`CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    project_id TEXT,
    content TEXT,
    sender TEXT,
    type TEXT DEFAULT 'text',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects (id)
  )`);

  // Feedback table
  db.run(`CREATE TABLE IF NOT EXISTS feedback (
    id TEXT PRIMARY KEY,
    type TEXT,
    message TEXT,
    email TEXT,
    device_info TEXT,
    app_version TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Settings table
  db.run(`CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: ['http://localhost:*', 'http://127.0.0.1:*'],
  credentials: true
}));
app.use(compression());
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('dev'));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// File upload configuration
const upload = multer({
  dest: 'uploads/',
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

// Static file serving
app.use('/uploads', express.static('uploads'));

// ================== API ROUTES ==================

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Projects endpoints
app.get('/api/projects', (req, res) => {
  db.all('SELECT * FROM projects ORDER BY updated_at DESC', (err, rows) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json(rows || []);
  });
});

app.post('/api/projects', (req, res) => {
  const { name, path } = req.body;
  const id = uuidv4();
  
  db.run(
    'INSERT INTO projects (id, name, path) VALUES (?, ?, ?)',
    [id, name, path],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ id, name, path, status: 'active' });
    }
  );
});

app.put('/api/projects/:id', (req, res) => {
  const { name, path, status } = req.body;
  const { id } = req.params;
  
  db.run(
    'UPDATE projects SET name = ?, path = ?, status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
    [name, path, status, id],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ id, name, path, status });
    }
  );
});

app.delete('/api/projects/:id', (req, res) => {
  const { id } = req.params;
  
  db.run('DELETE FROM projects WHERE id = ?', [id], function(err) {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: 'Project deleted successfully' });
  });
});

// Chat messages endpoints
app.get('/api/chat/messages/:projectId', (req, res) => {
  const { projectId } = req.params;
  
  db.all(
    'SELECT * FROM messages WHERE project_id = ? ORDER BY created_at ASC',
    [projectId],
    (err, rows) => {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json(rows || []);
    }
  );
});

app.post('/api/chat/message', (req, res) => {
  const { projectId, content, sender, type } = req.body;
  const id = uuidv4();
  
  db.run(
    'INSERT INTO messages (id, project_id, content, sender, type) VALUES (?, ?, ?, ?, ?)',
    [id, projectId, content, sender, type || 'text'],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      
      // Broadcast to WebSocket clients
      broadcastMessage({
        id,
        projectId,
        content,
        sender,
        type: type || 'text',
        timestamp: new Date().toISOString()
      });
      
      res.json({ id, projectId, content, sender, type });
    }
  );
});

// File operations (mock implementation)
app.get('/api/files/:projectId', (req, res) => {
  // Return mock file tree
  res.json({
    name: 'root',
    type: 'directory',
    children: [
      { name: 'src', type: 'directory', children: [] },
      { name: 'README.md', type: 'file', size: 1024 },
      { name: 'package.json', type: 'file', size: 512 }
    ]
  });
});

app.post('/api/files/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file provided' });
  }
  res.json({
    filename: req.file.filename,
    originalName: req.file.originalname,
    size: req.file.size
  });
});

// Terminal execution (mock implementation)
app.post('/api/terminal/execute', (req, res) => {
  const { command, projectId } = req.body;
  
  // Mock terminal output
  const outputs = {
    'ls': 'src/  README.md  package.json  node_modules/',
    'pwd': '/Users/claude/projects/test-project',
    'echo': command.replace('echo ', ''),
    'date': new Date().toString()
  };
  
  const cmd = command.split(' ')[0];
  const output = outputs[cmd] || `Command executed: ${command}`;
  
  res.json({
    command,
    output,
    exitCode: 0,
    timestamp: new Date().toISOString()
  });
});

// Feedback submission
app.post('/api/feedback', (req, res) => {
  const { type, message, email, deviceInfo, appVersion } = req.body;
  const id = uuidv4();
  
  db.run(
    'INSERT INTO feedback (id, type, message, email, device_info, app_version) VALUES (?, ?, ?, ?, ?, ?)',
    [id, type, message, email, deviceInfo, appVersion],
    function(err) {
      if (err) {
        return res.status(500).json({ error: err.message });
      }
      res.json({ id, message: 'Feedback submitted successfully' });
    }
  );
});

// Settings endpoints
app.get('/api/settings', (req, res) => {
  db.all('SELECT * FROM settings', (err, rows) => {
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

app.post('/api/settings', (req, res) => {
  const settings = req.body;
  
  db.serialize(() => {
    const stmt = db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)');
    
    Object.entries(settings).forEach(([key, value]) => {
      stmt.run(key, JSON.stringify(value));
    });
    
    stmt.finalize();
    res.json({ message: 'Settings updated successfully' });
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ================== WEBSOCKET SERVER ==================

const wss = new WebSocketServer({ server });
const clients = new Set();

wss.on('connection', (ws) => {
  console.log('New WebSocket connection');
  clients.add(ws);
  
  // Send welcome message
  ws.send(JSON.stringify({
    type: 'status',
    content: 'Connected to Claude Code backend',
    timestamp: new Date().toISOString()
  }));
  
  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      console.log('Received message:', message);
      
      // Broadcast to all clients
      broadcastMessage(message);
    } catch (err) {
      console.error('Error parsing message:', err);
    }
  });
  
  ws.on('close', () => {
    console.log('WebSocket connection closed');
    clients.delete(ws);
  });
  
  ws.on('error', (err) => {
    console.error('WebSocket error:', err);
    clients.delete(ws);
  });
  
  // Ping to keep connection alive
  const pingInterval = setInterval(() => {
    if (ws.readyState === ws.OPEN) {
      ws.ping();
    } else {
      clearInterval(pingInterval);
    }
  }, 30000);
});

function broadcastMessage(message) {
  const data = JSON.stringify(message);
  clients.forEach(client => {
    if (client.readyState === client.OPEN) {
      client.send(data);
    }
  });
}

// ================== START SERVER ==================

server.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════╗
║                                               ║
║   Claude Code iOS Backend Server              ║
║   Version: 1.0.0                              ║
║                                               ║
║   Server running on:                          ║
║   → http://localhost:${PORT}                    ║
║   → WebSocket: ws://localhost:${PORT}           ║
║                                               ║
║   Endpoints:                                  ║
║   → Health: GET /api/health                  ║
║   → Projects: GET/POST/PUT/DELETE /api/projects ║
║   → Chat: POST /api/chat/message             ║
║   → Files: GET /api/files/:projectId         ║
║   → Terminal: POST /api/terminal/execute     ║
║   → Feedback: POST /api/feedback             ║
║   → Settings: GET/POST /api/settings         ║
║                                               ║
║   Press Ctrl+C to stop                       ║
║                                               ║
╚═══════════════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    db.close();
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\nSIGINT signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    db.close();
    process.exit(0);
  });
});