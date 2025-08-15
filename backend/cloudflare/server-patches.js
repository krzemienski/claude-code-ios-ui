// CloudFlare Tunnel Server Patches
// Add these configurations to your server/index.js file

// 1. Trust CloudFlare proxy headers
// Add after express initialization:
/*
app.set('trust proxy', true);
app.use((req, res, next) => {
    // CloudFlare headers
    req.realIP = req.headers['cf-connecting-ip'] || 
                 req.headers['x-forwarded-for'] || 
                 req.ip;
    req.protocol = req.headers['x-forwarded-proto'] || req.protocol;
    req.hostname = req.headers['x-forwarded-host'] || req.hostname;
    next();
});
*/

// 2. Update CORS configuration for CloudFlare domains
// Replace existing CORS setup with:
/*
const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = [
            'http://localhost:3001',
            'http://localhost:3004',
            'https://claude-code-api.yourdomain.com',
            'https://claude-code.yourdomain.com',
            // Add your iOS app's bundle identifier for native requests
            'capacitor://localhost',
            'ionic://localhost'
        ];
        
        // Allow requests with no origin (mobile apps, Postman, etc.)
        if (!origin) return callback(null, true);
        
        if (allowedOrigins.indexOf(origin) !== -1 || 
            origin.includes('localhost') || 
            origin.includes('.cfargotunnel.com')) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    exposedHeaders: ['X-Total-Count', 'X-Page', 'X-Per-Page']
};

app.use(cors(corsOptions));
*/

// 3. WebSocket configuration for CloudFlare
// Update WebSocket server initialization:
/*
wss.on('connection', (ws, request) => {
    // Get real IP from CloudFlare headers
    const clientIP = request.headers['cf-connecting-ip'] || 
                    request.headers['x-forwarded-for'] || 
                    request.socket.remoteAddress;
    
    console.log(`WebSocket connection from ${clientIP}`);
    
    // Handle CloudFlare keepalive
    const pingInterval = setInterval(() => {
        if (ws.readyState === ws.OPEN) {
            ws.ping();
        } else {
            clearInterval(pingInterval);
        }
    }, 30000); // CloudFlare timeout is 100s, ping every 30s
    
    ws.on('close', () => {
        clearInterval(pingInterval);
    });
    
    // ... rest of WebSocket logic
});
*/

// 4. Health check endpoint for CloudFlare monitoring
// Add this endpoint:
/*
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        tunnel: req.headers['cf-ray'] ? 'cloudflare' : 'direct',
        clientIP: req.realIP || req.ip,
        services: {
            backend: 'running',
            websocket: wss.clients.size > 0 ? 'connected' : 'ready',
            database: 'connected'
        }
    });
});
*/

// 5. Request logging for CloudFlare
// Add CloudFlare-specific logging:
/*
app.use((req, res, next) => {
    if (req.headers['cf-ray']) {
        console.log(`[CloudFlare] ${req.method} ${req.path} - Ray ID: ${req.headers['cf-ray']}`);
    }
    next();
});
*/

// Export the patches as a module
module.exports = {
    applyCloudflareTrustProxy: (app) => {
        app.set('trust proxy', true);
        app.use((req, res, next) => {
            req.realIP = req.headers['cf-connecting-ip'] || 
                         req.headers['x-forwarded-for'] || 
                         req.ip;
            req.protocol = req.headers['x-forwarded-proto'] || req.protocol;
            req.hostname = req.headers['x-forwarded-host'] || req.hostname;
            next();
        });
    },
    
    getCorsOptions: () => {
        return {
            origin: function (origin, callback) {
                const allowedOrigins = process.env.ALLOWED_ORIGINS 
                    ? process.env.ALLOWED_ORIGINS.split(',')
                    : ['http://localhost:3001', 'http://localhost:3004'];
                
                if (!origin) return callback(null, true);
                
                if (allowedOrigins.some(allowed => origin.includes(allowed)) ||
                    origin.includes('localhost') || 
                    origin.includes('.cfargotunnel.com')) {
                    callback(null, true);
                } else {
                    callback(new Error('Not allowed by CORS'));
                }
            },
            credentials: true,
            methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
            allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
            exposedHeaders: ['X-Total-Count', 'X-Page', 'X-Per-Page']
        };
    },
    
    setupWebSocketPing: (ws, request) => {
        const clientIP = request.headers['cf-connecting-ip'] || 
                        request.headers['x-forwarded-for'] || 
                        request.socket.remoteAddress;
        
        console.log(`WebSocket connection from ${clientIP}`);
        
        const pingInterval = setInterval(() => {
            if (ws.readyState === ws.OPEN) {
                ws.ping();
            } else {
                clearInterval(pingInterval);
            }
        }, 30000);
        
        ws.on('close', () => {
            clearInterval(pingInterval);
        });
        
        return pingInterval;
    }
};