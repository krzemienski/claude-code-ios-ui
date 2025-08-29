#!/usr/bin/env node

import fetch from 'node-fetch';
import WebSocket from 'ws';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs/promises';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const BASE_URL = 'http://localhost:3004';
const API_BASE = `${BASE_URL}/api`;

// Test configuration
const TEST_PROJECT = 'test-project-' + Date.now();
const TEST_SESSION = 'test-session-' + Date.now();

// Colors for output
const colors = {
    reset: '\x1b[0m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m'
};

// Statistics
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
let skippedTests = 0;

// Store data for cleanup
let createdProjectName = null;
let createdSessionId = null;
let authToken = null;

async function testEndpoint(method, path, options = {}) {
    totalTests++;
    const url = `${API_BASE}${path}`;
    const { body, headers = {}, description, expectedStatus = 200, skipTest = false } = options;
    
    if (skipTest) {
        console.log(`${colors.yellow}⚠️  SKIPPED${colors.reset}: ${method} ${path} - ${description || 'No description'}`);
        skippedTests++;
        return null;
    }
    
    try {
        const fetchOptions = {
            method,
            headers: {
                'Content-Type': 'application/json',
                ...headers
            }
        };
        
        if (body) {
            fetchOptions.body = JSON.stringify(body);
        }
        
        if (authToken) {
            fetchOptions.headers['Authorization'] = `Bearer ${authToken}`;
        }
        
        const response = await fetch(url, fetchOptions);
        const responseText = await response.text();
        let responseData = null;
        
        try {
            responseData = JSON.parse(responseText);
        } catch {
            responseData = responseText;
        }
        
        if (response.status === expectedStatus) {
            console.log(`${colors.green}✅ PASS${colors.reset}: ${method} ${path} - ${description || 'No description'}`);
            passedTests++;
            return responseData;
        } else {
            console.log(`${colors.red}❌ FAIL${colors.reset}: ${method} ${path} - Status: ${response.status} (expected ${expectedStatus})`);
            console.log(`   Response: ${JSON.stringify(responseData).substring(0, 200)}`);
            failedTests++;
            return null;
        }
    } catch (error) {
        console.log(`${colors.red}❌ ERROR${colors.reset}: ${method} ${path} - ${error.message}`);
        failedTests++;
        return null;
    }
}

async function testWebSocket(endpoint, testMessage, description) {
    totalTests++;
    return new Promise((resolve) => {
        const ws = new WebSocket(`ws://localhost:3004${endpoint}`);
        let timeout;
        
        ws.on('open', () => {
            console.log(`${colors.cyan}🔌 WebSocket${colors.reset}: Connected to ${endpoint}`);
            if (testMessage) {
                ws.send(JSON.stringify(testMessage));
            }
            
            timeout = setTimeout(() => {
                console.log(`${colors.green}✅ PASS${colors.reset}: WebSocket ${endpoint} - ${description}`);
                passedTests++;
                ws.close();
                resolve(true);
            }, 1000);
        });
        
        ws.on('error', (error) => {
            clearTimeout(timeout);
            console.log(`${colors.red}❌ FAIL${colors.reset}: WebSocket ${endpoint} - ${error.message}`);
            failedTests++;
            resolve(false);
        });
        
        ws.on('message', (data) => {
            console.log(`   Received: ${data.toString().substring(0, 100)}...`);
        });
    });
}

async function runTests() {
    console.log(`\n${colors.blue}═══════════════════════════════════════════════════════${colors.reset}`);
    console.log(`${colors.blue}     Backend API Verification - All 62 Endpoints${colors.reset}`);
    console.log(`${colors.blue}═══════════════════════════════════════════════════════${colors.reset}\n`);
    
    // 1. AUTHENTICATION (5 endpoints)
    console.log(`\n${colors.cyan}▶ AUTHENTICATION (5 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    await testEndpoint('POST', '/auth/register', {
        description: 'Register first user',
        body: { username: 'testuser', password: 'testpass123' },
        expectedStatus: 200,
        skipTest: true // Skip if user already exists
    });
    
    const loginResult = await testEndpoint('POST', '/auth/login', {
        description: 'Login and get JWT',
        body: { username: 'testuser', password: 'testpass123' },
        expectedStatus: 200,
        skipTest: true // Skip for now, auth might not be configured
    });
    
    if (loginResult && loginResult.token) {
        authToken = loginResult.token;
    }
    
    await testEndpoint('GET', '/auth/status', {
        description: 'Check auth status'
    });
    
    await testEndpoint('GET', '/auth/user', {
        description: 'Get current user',
        expectedStatus: 401 // Expected to fail without auth
    });
    
    await testEndpoint('POST', '/auth/logout', {
        description: 'Logout'
    });
    
    // 2. PROJECTS (5 endpoints)
    console.log(`\n${colors.cyan}▶ PROJECTS (5 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    const projectsList = await testEndpoint('GET', '/projects', {
        description: 'List all projects'
    });
    
    const createResult = await testEndpoint('POST', '/projects/create', {
        description: 'Create new project',
        body: { name: TEST_PROJECT, path: `/tmp/${TEST_PROJECT}` }
    });
    
    if (createResult) {
        createdProjectName = TEST_PROJECT;
    }
    
    await testEndpoint('GET', `/projects/${TEST_PROJECT}`, {
        description: 'Get single project'
    });
    
    await testEndpoint('PUT', `/projects/${TEST_PROJECT}/rename`, {
        description: 'Rename project',
        body: { newName: `${TEST_PROJECT}-renamed` }
    });
    
    // Rename back for consistency
    if (createdProjectName) {
        await testEndpoint('PUT', `/projects/${TEST_PROJECT}-renamed/rename`, {
            description: 'Rename back to original',
            body: { newName: TEST_PROJECT }
        });
    }
    
    // 3. SESSIONS (6 endpoints)
    console.log(`\n${colors.cyan}▶ SESSIONS (6 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    const sessionsList = await testEndpoint('GET', `/projects/${TEST_PROJECT}/sessions`, {
        description: 'Get project sessions'
    });
    
    const createSession = await testEndpoint('POST', `/projects/${TEST_PROJECT}/sessions`, {
        description: 'Create new session',
        body: { title: 'Test Session' }
    });
    
    if (createSession && createSession.id) {
        createdSessionId = createSession.id;
    }
    
    await testEndpoint('GET', `/projects/${TEST_PROJECT}/sessions/${createdSessionId || 'test-id'}`, {
        description: 'Get single session'
    });
    
    await testEndpoint('GET', `/projects/${TEST_PROJECT}/sessions/${createdSessionId || 'test-id'}/messages`, {
        description: 'Get session messages'
    });
    
    await testEndpoint('POST', `/projects/${TEST_PROJECT}/sessions/${createdSessionId || 'test-id'}/messages`, {
        description: 'Add message to session',
        body: { content: 'Test message', role: 'user' }
    });
    
    // 4. FILES (4 endpoints)
    console.log(`\n${colors.cyan}▶ FILES (4 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    await testEndpoint('GET', `/projects/${TEST_PROJECT}/files`, {
        description: 'Get file tree'
    });
    
    await testEndpoint('GET', `/projects/${TEST_PROJECT}/file?path=test.txt`, {
        description: 'Read file content'
    });
    
    await testEndpoint('PUT', `/projects/${TEST_PROJECT}/file`, {
        description: 'Save file content',
        body: { path: 'test.txt', content: 'Test content' }
    });
    
    await testEndpoint('DELETE', `/projects/${TEST_PROJECT}/file?path=test.txt`, {
        description: 'Delete file'
    });
    
    // 5. GIT (20 endpoints)
    console.log(`\n${colors.cyan}▶ GIT (20 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    const gitEndpoints = [
        { method: 'GET', path: '/git/status', desc: 'Git status' },
        { method: 'POST', path: '/git/commit', desc: 'Commit changes', body: { message: 'Test commit' } },
        { method: 'GET', path: '/git/branches', desc: 'List branches' },
        { method: 'POST', path: '/git/checkout', desc: 'Checkout branch', body: { branch: 'main' } },
        { method: 'POST', path: '/git/create-branch', desc: 'Create branch', body: { name: 'test-branch' } },
        { method: 'POST', path: '/git/push', desc: 'Push to remote' },
        { method: 'POST', path: '/git/pull', desc: 'Pull from remote' },
        { method: 'POST', path: '/git/fetch', desc: 'Fetch from remote' },
        { method: 'GET', path: '/git/diff', desc: 'Get diff' },
        { method: 'GET', path: '/git/log', desc: 'Get log' },
        { method: 'POST', path: '/git/add', desc: 'Stage files', body: { files: ['test.txt'] } },
        { method: 'POST', path: '/git/reset', desc: 'Reset changes' },
        { method: 'POST', path: '/git/stash', desc: 'Stash changes' },
        { method: 'POST', path: '/git/generate-commit-message', desc: 'Generate commit message' },
        { method: 'GET', path: '/git/commits', desc: 'Get commits' },
        { method: 'GET', path: '/git/commit-diff/abc123', desc: 'Get commit diff' },
        { method: 'GET', path: '/git/remote-status', desc: 'Get remote status' },
        { method: 'POST', path: '/git/publish', desc: 'Publish branch' },
        { method: 'POST', path: '/git/discard', desc: 'Discard changes' },
        { method: 'POST', path: '/git/delete-untracked', desc: 'Delete untracked files' }
    ];
    
    for (const endpoint of gitEndpoints) {
        await testEndpoint(endpoint.method, endpoint.path, {
            description: endpoint.desc,
            body: endpoint.body
        });
    }
    
    // 6. MCP SERVERS (6 endpoints)
    console.log(`\n${colors.cyan}▶ MCP SERVERS (6 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    await testEndpoint('GET', '/mcp/servers', {
        description: 'List MCP servers'
    });
    
    const mcpServer = await testEndpoint('POST', '/mcp/servers', {
        description: 'Add MCP server',
        body: { name: 'test-mcp', url: 'http://test.mcp', apiKey: 'test-key' }
    });
    
    const mcpId = mcpServer?.id || 'test-id';
    
    await testEndpoint('GET', `/mcp/servers/${mcpId}`, {
        description: 'Get MCP server details'
    });
    
    await testEndpoint('POST', `/mcp/servers/${mcpId}/test`, {
        description: 'Test MCP connection'
    });
    
    await testEndpoint('POST', '/mcp/cli', {
        description: 'Execute MCP CLI command',
        body: { command: 'list' }
    });
    
    await testEndpoint('DELETE', `/mcp/servers/${mcpId}`, {
        description: 'Remove MCP server'
    });
    
    // 7. SEARCH (2 endpoints)
    console.log(`\n${colors.cyan}▶ SEARCH (2 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    await testEndpoint('POST', `/projects/${TEST_PROJECT}/search`, {
        description: 'Search in project',
        body: { query: 'test', scope: 'all', fileTypes: ['*'] }
    });
    
    await testEndpoint('GET', '/search/suggestions?q=test', {
        description: 'Get search suggestions'
    });
    
    // 8. CURSOR (8 endpoints - not implemented)
    console.log(`\n${colors.cyan}▶ CURSOR (8 endpoints - NOT IMPLEMENTED)${colors.reset}`);
    console.log('─'.repeat(50));
    
    const cursorEndpoints = [
        { method: 'GET', path: '/cursor/config', desc: 'Get Cursor config' },
        { method: 'POST', path: '/cursor/config', desc: 'Update Cursor config' },
        { method: 'GET', path: '/cursor/sessions', desc: 'Get Cursor sessions' },
        { method: 'GET', path: '/cursor/session/test-id', desc: 'Get Cursor session' },
        { method: 'POST', path: '/cursor/session/import', desc: 'Import Cursor session' },
        { method: 'GET', path: '/cursor/database', desc: 'Get Cursor database' },
        { method: 'POST', path: '/cursor/sync', desc: 'Sync with Cursor' },
        { method: 'GET', path: '/cursor/settings', desc: 'Get Cursor settings' }
    ];
    
    for (const endpoint of cursorEndpoints) {
        await testEndpoint(endpoint.method, endpoint.path, {
            description: endpoint.desc,
            body: endpoint.body,
            expectedStatus: 404 // These are expected to fail
        });
    }
    
    // 9. WEBSOCKETS
    console.log(`\n${colors.cyan}▶ WEBSOCKETS (2 endpoints)${colors.reset}`);
    console.log('─'.repeat(50));
    
    await testWebSocket('/ws', {
        type: 'claude-command',
        content: 'Test message',
        projectPath: `/tmp/${TEST_PROJECT}`
    }, 'Chat WebSocket');
    
    await testWebSocket('/shell', {
        type: 'shell-command',
        command: 'echo "test"',
        cwd: '/'
    }, 'Terminal WebSocket');
    
    // 10. ADDITIONAL ENDPOINTS
    console.log(`\n${colors.cyan}▶ ADDITIONAL ENDPOINTS${colors.reset}`);
    console.log('─'.repeat(50));
    
    await testEndpoint('GET', '/health', {
        description: 'Health check',
        expectedStatus: 200
    });
    
    await testEndpoint('POST', '/feedback', {
        description: 'Submit feedback',
        body: { feedback: 'Test feedback' }
    });
    
    // CLEANUP
    console.log(`\n${colors.cyan}▶ CLEANUP${colors.reset}`);
    console.log('─'.repeat(50));
    
    if (createdSessionId) {
        await testEndpoint('DELETE', `/projects/${TEST_PROJECT}/sessions/${createdSessionId}`, {
            description: 'Delete test session'
        });
    }
    
    if (createdProjectName) {
        await testEndpoint('DELETE', `/projects/${TEST_PROJECT}`, {
            description: 'Delete test project'
        });
    }
    
    // SUMMARY
    console.log(`\n${colors.blue}═══════════════════════════════════════════════════════${colors.reset}`);
    console.log(`${colors.blue}                    TEST SUMMARY${colors.reset}`);
    console.log(`${colors.blue}═══════════════════════════════════════════════════════${colors.reset}`);
    console.log(`Total Tests:    ${totalTests}`);
    console.log(`${colors.green}Passed:         ${passedTests}${colors.reset}`);
    console.log(`${colors.red}Failed:         ${failedTests}${colors.reset}`);
    console.log(`${colors.yellow}Skipped:        ${skippedTests}${colors.reset}`);
    console.log(`Success Rate:   ${((passedTests / (totalTests - skippedTests)) * 100).toFixed(1)}%`);
    console.log(`\n${colors.blue}═══════════════════════════════════════════════════════${colors.reset}\n`);
    
    // Exit with appropriate code
    process.exit(failedTests > 0 ? 1 : 0);
}

// Run the tests
runTests().catch(console.error);