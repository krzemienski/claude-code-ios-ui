# CloudFlare Tunnel Setup for Claude Code UI

This guide will help you set up CloudFlare Tunnel to expose your local Claude Code UI backend to the internet, allowing your iOS app to connect to your home MacBook from anywhere.

## Prerequisites

- macOS (this guide is for Mac)
- CloudFlare account (free tier works)
- A domain managed by CloudFlare (or use CloudFlare's free subdomain)
- Node.js and npm installed
- Claude Code UI backend running locally

## Quick Start

### Step 1: Install CloudFlare Tunnel

```bash
cd /Users/nick/Documents/claude-code-ios-ui/backend/cloudflare
chmod +x *.sh
./install-cloudflared.sh
```

### Step 2: Authenticate with CloudFlare

```bash
cloudflared tunnel login
```

This will open a browser window. Log in to CloudFlare and select the domain you want to use.

### Step 3: Create the Tunnel

```bash
./create-tunnel.sh
```

This creates a tunnel named `claude-code-ui` and generates the configuration files.

### Step 4: Configure Your Domain

1. Open `~/.cloudflared/config.yml`
2. Replace `YOURDOMAIN.com` with your actual domain
3. Add DNS records in CloudFlare dashboard:
   - Type: CNAME
   - Name: `claude-code-api`
   - Target: `[TUNNEL_UUID].cfargotunnel.com`

### Step 5: Start the Tunnel

For testing (foreground):
```bash
./start-tunnel.sh
```

For production (auto-start on boot):
```bash
./install-service.sh
```

## iOS App Configuration

### Update AppConfig.swift

```swift
// In ClaudeCodeUI-iOS/Core/Config/AppConfig.swift

struct AppConfig {
    // For production (CloudFlare Tunnel)
    static let apiBaseURL = "https://claude-code-api.yourdomain.com"
    static let wsBaseURL = "wss://claude-code-api.yourdomain.com"
    
    // For local development
    // static let apiBaseURL = "http://localhost:3004"
    // static let wsBaseURL = "ws://localhost:3004"
}
```

### Update Info.plist (if needed)

If using a custom domain without HTTPS during development:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>yourdomain.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## Backend Server Updates

Add CloudFlare support to your backend:

```javascript
// In server/index.js, after express initialization:

// Trust CloudFlare proxy
app.set('trust proxy', true);

// Update CORS for CloudFlare domains
const corsOptions = {
    origin: function (origin, callback) {
        const allowedOrigins = [
            'http://localhost:3001',
            'http://localhost:3004',
            'https://claude-code-api.yourdomain.com',
            'https://claude-code.yourdomain.com'
        ];
        
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true
};

app.use(cors(corsOptions));
```

## Service Management

### Start Services
```bash
# Start backend
launchctl start com.claudecode.backend

# Start tunnel
launchctl start com.claudecode.tunnel
```

### Stop Services
```bash
# Stop backend
launchctl stop com.claudecode.backend

# Stop tunnel
launchctl stop com.claudecode.tunnel
```

### Check Status
```bash
launchctl list | grep claudecode
```

### View Logs
```bash
# Tunnel logs
tail -f ~/Documents/claude-code-ios-ui/backend/cloudflare/tunnel.log

# Backend logs
tail -f ~/Documents/claude-code-ios-ui/backend/logs/backend.log
```

## Troubleshooting

### Tunnel Won't Start
- Check authentication: `cloudflared tunnel list`
- Verify config: `cat ~/.cloudflared/config.yml`
- Check logs: `tail -f cloudflare/tunnel.log`

### iOS App Can't Connect
- Verify tunnel is running: `curl https://claude-code-api.yourdomain.com/api/health`
- Check CORS settings in backend
- Ensure JWT token is being sent correctly
- Check iOS app logs in Xcode console

### WebSocket Issues
- Ensure `/ws` and `/shell` paths are configured in tunnel
- Check WebSocket upgrade headers are being passed
- Verify pingInterval is set (CloudFlare timeout is 100s)

### Backend Not Accessible
- Check firewall settings
- Verify backend is listening on 0.0.0.0:3004
- Check CloudFlare DNS records are correct

## Security Considerations

1. **Authentication**: Always use JWT authentication in production
2. **HTTPS Only**: CloudFlare provides free SSL/TLS
3. **IP Restrictions**: Can configure CloudFlare firewall rules
4. **Rate Limiting**: Enable CloudFlare rate limiting for API endpoints
5. **Access Tokens**: Rotate JWT secrets regularly

## Advanced Configuration

### Multiple Environments

Create different tunnels for dev/staging/prod:
```bash
cloudflared tunnel create claude-code-dev
cloudflared tunnel create claude-code-staging
cloudflared tunnel create claude-code-prod
```

### Zero Trust Access

Use CloudFlare Access for additional security:
1. Go to CloudFlare Zero Trust dashboard
2. Create an Access application
3. Set up authentication (Google, GitHub, etc.)
4. Apply to your tunnel hostname

### Performance Optimization

1. Enable CloudFlare caching for static assets
2. Use CloudFlare Workers for edge computing
3. Enable Argo Smart Routing for better performance
4. Configure WebSocket compression

## Monitoring

### CloudFlare Analytics
- View tunnel metrics in CloudFlare dashboard
- Monitor request rates and errors
- Set up alerts for downtime

### Health Checks
```bash
# Local check
curl http://localhost:3004/api/health

# Remote check
curl https://claude-code-api.yourdomain.com/api/health
```

## Backup and Recovery

### Backup Tunnel Credentials
```bash
cp ~/.cloudflared/*.json ~/backups/cloudflare/
```

### Restore Tunnel
```bash
# Copy credentials back
cp ~/backups/cloudflare/*.json ~/.cloudflared/

# Restart tunnel
./start-tunnel.sh
```

## Support

- CloudFlare Tunnel Docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- CloudFlare Community: https://community.cloudflare.com/
- Project Issues: https://github.com/yourusername/claude-code-ui/issues

## License

This setup is part of the Claude Code UI project and follows the same MIT license.