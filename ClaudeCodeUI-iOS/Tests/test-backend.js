#!/usr/bin/env node

/**
 * Simple test backend server for UI testing
 * Provides mock data for ClaudeCodeUI iOS UI tests
 * 
 * Usage: node test-backend.js
 * Default port: 3004
 */

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3004;

// Middleware
app.use(express.json());
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    console.log('Headers:', req.headers);
    if (req.body && Object.keys(req.body).length > 0) {
        console.log('Body:', req.body);
    }
    next();
});

// CORS headers for iOS app
app.use((req, res, next) => {
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});

// Test projects data
const testProjects = [
    {
        name: "claude-ui-tests",
        displayName: "Claude UI Tests",
        path: "/projects/claude-ui-tests",
        createdAt: "2025-01-21T10:00:00Z",
        updatedAt: "2025-01-21T10:00:00Z",
        sessions: ["session1", "session2"],
        sessionMeta: { total: 2 }
    },
    {
        name: "sample-project",
        displayName: "Sample Project",
        path: "/projects/sample-project",
        createdAt: "2025-01-20T09:00:00Z",
        updatedAt: "2025-01-20T09:00:00Z",
        sessions: ["session3"],
        sessionMeta: { total: 1 }
    },
    {
        name: "test-automation",
        displayName: "Test Automation",
        path: "/projects/test-automation",
        createdAt: "2025-01-19T08:00:00Z",
        updatedAt: "2025-01-19T08:00:00Z",
        sessions: [],
        sessionMeta: { total: 0 }
    }
];

// Routes

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Auth status (always authenticated for testing)
app.get('/api/auth/status', (req, res) => {
    res.json({
        authenticated: true,
        user: {
            id: 1,
            username: 'testuser',
            email: 'test@example.com'
        }
    });
});

// Projects endpoint - returns test projects
app.get('/api/projects', (req, res) => {
    console.log('✅ Returning test projects:', testProjects.length);
    res.json(testProjects);
});

// Get specific project
app.get('/api/projects/:name', (req, res) => {
    const project = testProjects.find(p => p.name === req.params.name);
    if (project) {
        res.json(project);
    } else {
        res.status(404).json({ error: 'Project not found' });
    }
});

// Create project
app.post('/api/projects/create', (req, res) => {
    const { name, path } = req.body;
    const newProject = {
        name,
        displayName: name,
        path: path || `/projects/${name}`,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        sessions: [],
        sessionMeta: { total: 0 }
    };
    testProjects.push(newProject);
    res.status(201).json(newProject);
});

// Delete project
app.delete('/api/projects/:name', (req, res) => {
    const index = testProjects.findIndex(p => p.name === req.params.name);
    if (index !== -1) {
        testProjects.splice(index, 1);
        res.status(204).send();
    } else {
        res.status(404).json({ error: 'Project not found' });
    }
});

// Sessions for a project
app.get('/api/projects/:name/sessions', (req, res) => {
    const project = testProjects.find(p => p.name === req.params.name);
    if (project) {
        const sessions = project.sessions.map((id, index) => ({
            id,
            uuid: `uuid-${id}`,
            name: `Session ${index + 1}`,
            createdAt: new Date().toISOString(),
            messageCount: Math.floor(Math.random() * 10) + 1
        }));
        res.json({ sessions, total: sessions.length });
    } else {
        res.status(404).json({ error: 'Project not found' });
    }
});

// Messages for a session
app.get('/api/projects/:project/sessions/:session/messages', (req, res) => {
    const messages = [
        {
            uuid: 'msg-1',
            type: 'claude-response',
            message: {
                role: 'user',
                content: 'Hello, Claude!'
            },
            timestamp: new Date().toISOString()
        },
        {
            uuid: 'msg-2',
            type: 'claude-response',
            message: {
                role: 'assistant',
                content: [
                    { type: 'text', text: 'Hello! How can I help you today?' }
                ]
            },
            timestamp: new Date().toISOString()
        }
    ];
    res.json({ messages, total: messages.length });
});

// WebSocket endpoint (mock)
app.get('/ws', (req, res) => {
    console.log('WebSocket connection requested (not implemented in mock)');
    res.status(426).send('Upgrade Required');
});

// Shell WebSocket endpoint (mock)
app.get('/shell', (req, res) => {
    console.log('Shell WebSocket connection requested (not implemented in mock)');
    res.status(426).send('Upgrade Required');
});

// Start server
app.listen(PORT, () => {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('🚀 Test Backend Server for ClaudeCodeUI iOS');
    console.log(`📡 Running on http://localhost:${PORT}`);
    console.log('═══════════════════════════════════════════════════════════');
    console.log('');
    console.log('📊 Test Data:');
    console.log(`  • ${testProjects.length} projects available`);
    console.log('  • Auth bypass enabled (always authenticated)');
    console.log('  • CORS enabled for all origins');
    console.log('');
    console.log('🔌 Endpoints:');
    console.log(`  GET  /health                   - Health check`);
    console.log(`  GET  /api/auth/status          - Auth status`);
    console.log(`  GET  /api/projects             - List projects`);
    console.log(`  GET  /api/projects/:name       - Get project`);
    console.log(`  POST /api/projects/create      - Create project`);
    console.log(`  DEL  /api/projects/:name       - Delete project`);
    console.log(`  GET  /api/projects/:n/sessions - List sessions`);
    console.log('');
    console.log('Press Ctrl+C to stop the server');
    console.log('═══════════════════════════════════════════════════════════');
});

// Handle shutdown
process.on('SIGINT', () => {
    console.log('\n👋 Shutting down test backend server...');
    process.exit(0);
});