# CloudFlare Tunnel Setup for Claude Code UI Backend

This guide helps you expose your Claude Code UI backend server running on your MacBook to the internet using CloudFlare Tunnel, allowing your iOS app to connect from anywhere.

## 🎯 Overview

CloudFlare Tunnel (formerly Argo Tunnel) creates a secure connection between your backend server and CloudFlare's edge network without exposing your home IP address or opening firewall ports.

### Benefits:
- ✅ **No Port Forwarding**: No need to configure your router
- ✅ **Secure**: All traffic is encrypted through CloudFlare
- ✅ **DDoS Protection**: CloudFlare's built-in protection
- ✅ **SSL/TLS**: Automatic HTTPS with CloudFlare certificates
- ✅ **WebSocket Support**: Real-time chat and terminal work seamlessly
- ✅ **Zero Trust**: Only authenticated requests reach your server

## 📋 Prerequisites

1. **CloudFlare Account**: Sign up at [cloudflare.com](https://www.cloudflare.com)
2. **Domain Name**: You need a domain managed by CloudFlare
3. **macOS**: This guide is for MacBook setup
4. **Backend Running**: The Claude Code UI backend should be working locally

## 🚀 Quick Setup

### Step 1: Initial Setup
```bash
cd backend/cloudflare-tunnel
chmod +x *.sh

# Run the main setup script
./setup-tunnel.sh
```

This will:
1. Install Homebrew (if needed)
2. Install cloudflared via Homebrew
3. Authenticate with CloudFlare (opens browser)
4. Create a tunnel named "claude-code-ui-backend"
5. Configure DNS routing
6. Test the tunnel connection

### Step 2: Configure Backend
```bash
# Update backend configuration for CloudFlare
node update-backend-config.js
```

This adds CloudFlare-specific settings to your backend.

### Step 3: Set Up Auto-Start (Optional)
```bash
# Install as a system service
./install-service.sh
```

This configures the tunnel to start automatically when your Mac boots.

### Step 4: Update iOS App
```bash
# Generate iOS configuration
./update-ios-config.swift
```

Enter your CloudFlare tunnel URL when prompted. This creates a `CloudFlareConfig.swift` file to add to your iOS project.

## 🔧 Manual Configuration

### CloudFlare Dashboard Setup

1. **Login to CloudFlare Dashboard**
   - Go to [dash.cloudflare.com](https://dash.cloudflare.com)
   - Select your domain

2. **Navigate to Zero Trust**
   - Click "Zero Trust" in the sidebar
   - Go to "Access" → "Tunnels"

3. **Configure Tunnel**
   - Find "claude-code-ui-backend" tunnel
   - Click "Configure" 
   - Add public hostname if not already added

### Custom Configuration

Edit `~/.cloudflared/config.yml`:

```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: ~/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  # Main backend
  - hostname: claude-backend.yourdomain.com
    service: http://localhost:3004
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      
  # WebSocket for chat
  - hostname: claude-backend.yourdomain.com
    path: /ws
    service: http://localhost:3004
    originRequest:
      noTLSVerify: true
      
  # Shell WebSocket
  - hostname: claude-backend.yourdomain.com
    path: /shell
    service: http://localhost:3004
    originRequest:
      noTLSVerify: true
      
  # Catch-all
  - service: http_status:404
```

## 🏃 Running the Services

### Option 1: Combined Startup (Recommended)
```bash
# Start both backend and tunnel together
./start-with-tunnel.sh
```

This ensures the backend is running before the tunnel connects.

### Option 2: Separate Processes

Terminal 1 - Backend:
```bash
cd backend
npm run server
```

Terminal 2 - Tunnel:
```bash
cloudflared tunnel run claude-code-ui-backend
```

### Option 3: System Service (Auto-Start)
```bash
# The tunnel will auto-start on boot if you ran install-service.sh
# To manually control:
sudo launchctl load /Library/LaunchDaemons/com.cloudflare.cloudflared.plist    # Start
sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.cloudflared.plist  # Stop
```

## 📱 iOS App Configuration

### 1. Add CloudFlareConfig.swift to your project

Copy the generated `CloudFlareConfig.swift` to your iOS project:
```bash
cp CloudFlareConfig.swift ../../ClaudeCodeUI-iOS/Core/Config/
```

### 2. Update ChatViewController

Replace hardcoded URLs with CloudFlare config:
```swift
// Before:
let url = "ws://localhost:3004/ws"

// After:
let url = CloudFlareConfig.webSocketURL
```

### 3. Update APIClient

Use dynamic base URL:
```swift
// Before:
static let baseURL = "http://localhost:3004"

// After:
static let baseURL = CloudFlareConfig.baseURL
```

### 4. Test Connection

1. Ensure backend is running
2. Ensure tunnel is active
3. Build and run iOS app
4. Check console for successful connection

## 🔍 Troubleshooting

### Check Tunnel Status
```bash
# List all tunnels
cloudflared tunnel list

# Check tunnel info
cloudflared tunnel info claude-code-ui-backend

# View tunnel metrics
cloudflared tunnel metrics claude-code-ui-backend
```

### View Logs
```bash
# Tunnel logs
tail -f /var/log/cloudflared.log

# Error logs
tail -f /var/log/cloudflared.error.log

# Backend logs
# Check terminal where npm run server is running
```

### Common Issues

#### 1. Tunnel Won't Connect
- Check if backend is running: `curl http://localhost:3004/api/health`
- Verify CloudFlare authentication: `cloudflared tunnel login`
- Check DNS records in CloudFlare dashboard

#### 2. WebSocket Connection Fails
- Ensure ingress rules include `/ws` and `/shell` paths
- Check CloudFlare WebSocket settings are enabled
- Verify SSL/TLS mode is "Full" or "Flexible"

#### 3. iOS App Can't Connect
- Verify tunnel URL in CloudFlareConfig.swift
- Check for HTTPS vs HTTP in URLs
- Test tunnel URL in browser first

#### 4. Authentication Issues
- Ensure JWT tokens are being sent
- Check CloudFlare Access policies if enabled
- Verify CORS settings in backend

### Reset Everything
```bash
# Delete tunnel
cloudflared tunnel delete claude-code-ui-backend -f

# Remove service
sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.cloudflared.plist
sudo rm /Library/LaunchDaemons/com.cloudflare.cloudflared.plist

# Clear config
rm -rf ~/.cloudflared

# Start fresh
./setup-tunnel.sh
```

## 🔒 Security Considerations

### 1. Authentication
- The backend uses JWT authentication
- Always use HTTPS through CloudFlare
- Consider adding CloudFlare Access for additional security

### 2. CloudFlare Access (Optional)
Add an extra authentication layer:
1. Go to Zero Trust → Access → Applications
2. Create new application
3. Set policy (e.g., require email OTP)
4. Associate with your tunnel

### 3. Rate Limiting
The backend includes rate limiting configuration:
- 100 requests per 15 minutes per IP
- Configurable in `.env` file

### 4. IP Whitelisting (Optional)
In CloudFlare dashboard:
1. Security → WAF → Tools
2. Create IP Access Rule
3. Allow only specific IPs

## 📊 Monitoring

### CloudFlare Analytics
1. Login to CloudFlare dashboard
2. Navigate to your tunnel
3. View metrics:
   - Request count
   - Bandwidth usage
   - Error rates
   - Response times

### Local Monitoring
```bash
# Check if services are running
ps aux | grep -E "cloudflared|node"

# Monitor network connections
netstat -an | grep 3004

# Check system resources
top -o cpu
```

## 🔄 Maintenance

### Update cloudflared
```bash
brew update
brew upgrade cloudflared
```

### Rotate Tunnel Credentials
```bash
# Delete old tunnel
cloudflared tunnel delete claude-code-ui-backend -f

# Create new tunnel
cloudflared tunnel create claude-code-ui-backend

# Update DNS
cloudflared tunnel route dns claude-code-ui-backend your-subdomain.yourdomain.com
```

### Backup Configuration
```bash
# Backup CloudFlare config
cp -r ~/.cloudflared ~/.cloudflared.backup

# Backup backend config
cp backend/.env backend/.env.backup
```

## 📚 Additional Resources

- [CloudFlare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [CloudFlare Zero Trust](https://www.cloudflare.com/products/zero-trust/)
- [WebSocket Support in CloudFlare](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/configuration/websockets/)
- [iOS Network Configuration](https://developer.apple.com/documentation/network)

## 💡 Tips

1. **Use a subdomain**: Instead of your main domain, use something like `claude-backend.yourdomain.com`
2. **Enable CloudFlare caching**: For static assets, but exclude API endpoints
3. **Set up health checks**: CloudFlare can monitor your tunnel and alert you if it goes down
4. **Use CloudFlare Workers**: For additional request processing or authentication
5. **Enable Argo Smart Routing**: For better performance (paid feature)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review CloudFlare tunnel logs
3. Check the backend server logs
4. Verify iOS app configuration
5. Test with `curl` commands to isolate issues

---

**Note**: This setup assumes you have a CloudFlare account with a registered domain. The free tier of CloudFlare is sufficient for personal use.