import express from 'express';
import { v4 as uuidv4 } from 'uuid';

const router = express.Router();

// In-memory storage for MCP servers (in production, use database)
let mcpServers = [];

// Initialize with default servers
const initializeDefaultServers = () => {
  mcpServers = [
    {
      id: uuidv4(),
      name: 'Claude MCP',
      url: 'https://api.anthropic.com/mcp',
      description: 'Official Claude Model Context Protocol server',
      type: 'rest',
      apiKey: null,
      isDefault: true,
      isConnected: false,
      lastConnected: null,
      configuration: {}
    },
    {
      id: uuidv4(),
      name: 'Local Development',
      url: 'http://localhost:3004/mcp',
      description: 'Local MCP server for development',
      type: 'websocket',
      apiKey: null,
      isDefault: false,
      isConnected: true,
      lastConnected: new Date().toISOString(),
      configuration: {}
    },
    {
      id: uuidv4(),
      name: 'GitHub Copilot',
      url: 'https://api.github.com/copilot',
      description: 'GitHub Copilot integration server',
      type: 'graphql',
      apiKey: null,
      isDefault: false,
      isConnected: false,
      lastConnected: null,
      configuration: {}
    }
  ];
};

// Initialize default servers on startup
initializeDefaultServers();

// GET /api/mcp/servers - List all MCP servers
router.get('/servers', (req, res) => {
  console.log('📋 GET /api/mcp/servers - Listing MCP servers');
  res.json(mcpServers);
});

// POST /api/mcp/servers - Add a new MCP server
router.post('/servers', (req, res) => {
  try {
    const { name, url, description, type, apiKey, isDefault, configuration } = req.body;
    
    console.log('➕ POST /api/mcp/servers - Adding MCP server:', name);
    
    // Validate required fields
    if (!name || !url || !type) {
      return res.status(400).json({ 
        error: 'Missing required fields', 
        required: ['name', 'url', 'type'] 
      });
    }
    
    // If this is set as default, unset other defaults
    if (isDefault) {
      mcpServers.forEach(server => {
        server.isDefault = false;
      });
    }
    
    const newServer = {
      id: uuidv4(),
      name,
      url,
      description: description || '',
      type,
      apiKey: apiKey || null,
      isDefault: isDefault || false,
      isConnected: false,
      lastConnected: null,
      configuration: configuration || {}
    };
    
    mcpServers.push(newServer);
    
    console.log('✅ MCP server added successfully:', newServer.id);
    res.status(201).json(newServer);
  } catch (error) {
    console.error('❌ Error adding MCP server:', error);
    res.status(500).json({ error: 'Failed to add MCP server', details: error.message });
  }
});

// PUT /api/mcp/servers/:id - Update an MCP server
router.put('/servers/:id', (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    console.log('🔄 PUT /api/mcp/servers/:id - Updating MCP server:', id);
    
    const index = mcpServers.findIndex(server => server.id === id);
    if (index === -1) {
      return res.status(404).json({ error: 'MCP server not found' });
    }
    
    // If this is set as default, unset other defaults
    if (updates.isDefault && !mcpServers[index].isDefault) {
      mcpServers.forEach((server, i) => {
        if (i !== index) {
          server.isDefault = false;
        }
      });
    }
    
    // Update the server
    mcpServers[index] = {
      ...mcpServers[index],
      ...updates,
      id: mcpServers[index].id // Ensure ID doesn't change
    };
    
    console.log('✅ MCP server updated successfully');
    res.json(mcpServers[index]);
  } catch (error) {
    console.error('❌ Error updating MCP server:', error);
    res.status(500).json({ error: 'Failed to update MCP server', details: error.message });
  }
});

// DELETE /api/mcp/servers/:id - Delete an MCP server
router.delete('/servers/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('🗑️ DELETE /api/mcp/servers/:id - Deleting MCP server:', id);
    
    const index = mcpServers.findIndex(server => server.id === id);
    if (index === -1) {
      return res.status(404).json({ error: 'MCP server not found' });
    }
    
    mcpServers.splice(index, 1);
    
    console.log('✅ MCP server deleted successfully');
    res.status(204).send();
  } catch (error) {
    console.error('❌ Error deleting MCP server:', error);
    res.status(500).json({ error: 'Failed to delete MCP server', details: error.message });
  }
});

// POST /api/mcp/servers/:id/test - Test MCP server connection
router.post('/servers/:id/test', async (req, res) => {
  try {
    const { id } = req.params;
    
    console.log('🔌 POST /api/mcp/servers/:id/test - Testing MCP server connection:', id);
    
    const server = mcpServers.find(s => s.id === id);
    if (!server) {
      return res.status(404).json({ error: 'MCP server not found' });
    }
    
    // Simulate connection test
    const startTime = Date.now();
    
    // In a real implementation, you would actually test the connection
    // For now, we'll simulate with a timeout
    await new Promise(resolve => setTimeout(resolve, Math.random() * 1000 + 500));
    
    const latency = Date.now() - startTime;
    const success = Math.random() > 0.2; // 80% success rate for demo
    
    // Update server status
    if (success) {
      server.isConnected = true;
      server.lastConnected = new Date().toISOString();
    } else {
      server.isConnected = false;
    }
    
    const result = {
      success,
      message: success ? 'Connection successful' : 'Connection failed: Unable to reach server',
      latency: success ? latency : null
    };
    
    console.log(`✅ Connection test result: ${success ? 'SUCCESS' : 'FAILED'} (${latency}ms)`);
    res.json(result);
  } catch (error) {
    console.error('❌ Error testing MCP server connection:', error);
    res.status(500).json({ 
      success: false,
      message: 'Connection test failed: ' + error.message,
      latency: null
    });
  }
});

// POST /api/mcp/cli - Execute MCP CLI command
router.post('/cli', async (req, res) => {
  try {
    const { command, args } = req.body;
    
    console.log('🖥️ POST /api/mcp/cli - Executing MCP command:', command, args);
    
    // Validate command
    if (!command) {
      return res.status(400).json({ error: 'Missing command' });
    }
    
    // In a real implementation, you would execute the command
    // For now, we'll return a mock response
    const mockOutput = `Executing MCP command: ${command} ${args ? args.join(' ') : ''}\n` +
                      `Command completed successfully.\n` +
                      `Output: Mock response for demonstration purposes.`;
    
    res.json({
      output: mockOutput,
      success: true
    });
  } catch (error) {
    console.error('❌ Error executing MCP command:', error);
    res.status(500).json({ 
      output: '',
      success: false,
      error: 'Failed to execute MCP command: ' + error.message 
    });
  }
});

export default router;