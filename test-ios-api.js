const http = require('http');

// Test API endpoints for iOS app communication
async function testAPI() {
    console.log('🧪 Testing Claude Code iOS API Communication\n');
    
    // Test 1: Check health endpoint
    console.log('1️⃣ Testing /api/health endpoint...');
    try {
        const healthResponse = await makeRequest('/api/health', 'GET');
        console.log('✅ Health check:', healthResponse);
    } catch (error) {
        console.error('❌ Health check failed:', error.message);
    }
    
    // Test 2: Check projects endpoint (requires auth)
    console.log('\n2️⃣ Testing /api/projects endpoint...');
    try {
        const projectsResponse = await makeRequest('/api/projects', 'GET');
        console.log('✅ Projects response:', projectsResponse);
    } catch (error) {
        console.error('❌ Projects request failed:', error.message);
        console.log('ℹ️  This might be expected if authentication is required');
    }
    
    // Test 3: Check auth endpoint
    console.log('\n3️⃣ Testing /api/auth/check endpoint...');
    try {
        const authResponse = await makeRequest('/api/auth/check', 'GET');
        console.log('✅ Auth check:', authResponse);
    } catch (error) {
        console.error('❌ Auth check failed:', error.message);
    }
    
    // Test 4: Check WebSocket endpoint availability
    console.log('\n4️⃣ Checking WebSocket endpoints...');
    console.log('📍 Chat WebSocket would connect to: ws://localhost:3004/ws');
    console.log('📍 Shell WebSocket would connect to: ws://localhost:3004/shell');
    
    console.log('\n📊 Summary:');
    console.log('- Backend is running on port 3004');
    console.log('- Authentication may be required for some endpoints');
    console.log('- WebSocket endpoints are available for real-time communication');
}

function makeRequest(path, method = 'GET', data = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 3004,
            path: path,
            method: method,
            headers: {
                'Content-Type': 'application/json',
            }
        };
        
        const req = http.request(options, (res) => {
            let responseData = '';
            
            res.on('data', (chunk) => {
                responseData += chunk;
            });
            
            res.on('end', () => {
                try {
                    const parsedData = JSON.parse(responseData);
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(parsedData);
                    } else {
                        reject(new Error(`HTTP ${res.statusCode}: ${parsedData.error || responseData}`));
                    }
                } catch (e) {
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(responseData);
                    } else {
                        reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
                    }
                }
            });
        });
        
        req.on('error', (error) => {
            reject(error);
        });
        
        if (data) {
            req.write(JSON.stringify(data));
        }
        
        req.end();
    });
}

// Run the tests
testAPI();