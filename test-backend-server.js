const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3001;

// Enable CORS for all origins (for local development)
app.use(cors());
app.use(express.json());

// Mock projects data
const mockProjects = [
  {
    id: "1",
    name: "claudecode-ios",
    path: "/home/nick/claudecode-ios",
    displayName: "Claude Code iOS",
    createdAt: new Date("2025-01-05T10:00:00Z"),
    updatedAt: new Date("2025-01-05T15:30:00Z")
  },
  {
    id: "2",
    name: "sample-project",
    path: "/home/nick/Projects/sample",
    displayName: "Sample Project",
    createdAt: new Date("2025-01-04T08:00:00Z"),
    updatedAt: new Date("2025-01-04T18:00:00Z")
  },
  {
    id: "3",
    name: "test-app",
    path: "/home/nick/Projects/test-app",
    displayName: "Test Application",
    createdAt: new Date("2025-01-03T12:00:00Z"),
    updatedAt: new Date("2025-01-05T09:00:00Z")
  }
];

// Projects endpoint
app.get('/api/projects', (req, res) => {
  console.log('📱 iOS app requested projects');
  res.json({ projects: mockProjects });
});

// Create project endpoint
app.post('/api/projects', (req, res) => {
  const { name, path } = req.body;
  const newProject = {
    id: String(Date.now()),
    name: name.toLowerCase().replace(/\s+/g, '-'),
    path: path,
    displayName: name,
    createdAt: new Date(),
    updatedAt: new Date()
  };
  mockProjects.push(newProject);
  res.json(newProject);
});

// Delete project endpoint
app.delete('/api/projects/:id', (req, res) => {
  const index = mockProjects.findIndex(p => p.id === req.params.id);
  if (index !== -1) {
    mockProjects.splice(index, 1);
    res.json({ success: true });
  } else {
    res.status(404).json({ error: 'Project not found' });
  }
});

// WebSocket placeholder
app.ws = (path, handler) => {
  console.log(`WebSocket endpoint registered: ${path}`);
};

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Test backend server running on http://0.0.0.0:${PORT}`);
  console.log(`📱 iOS app can connect to http://192.168.0.36:${PORT}`);
});