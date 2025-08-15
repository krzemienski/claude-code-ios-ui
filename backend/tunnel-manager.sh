#!/bin/bash

# Tunnel Manager - Complete self-contained script for Cloudflare tunnel management
# Handles cleanup, process management, and API testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_PORT=3004
BACKEND_DIR="$(dirname "$0")"
TUNNEL_URL_FILE="$BACKEND_DIR/cloudflare/current-tunnel-url.txt"
PID_DIR="$BACKEND_DIR/.pids"
BACKEND_PID_FILE="$PID_DIR/backend.pid"
TUNNEL_PID_FILE="$PID_DIR/tunnel.pid"

# Create PID directory if it doesn't exist
mkdir -p "$PID_DIR"

# Function to print colored messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to cleanup all processes
cleanup_all() {
    log_info "Starting cleanup of existing processes..."
    
    # Kill backend server
    if [ -f "$BACKEND_PID_FILE" ]; then
        PID=$(cat "$BACKEND_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            log_info "Killing backend server (PID: $PID)..."
            kill -9 $PID 2>/dev/null || true
        fi
        rm -f "$BACKEND_PID_FILE"
    fi
    
    # Kill any node process on port 3004
    lsof -ti:$BACKEND_PORT | xargs -r kill -9 2>/dev/null || true
    
    # Kill cloudflared tunnel
    if [ -f "$TUNNEL_PID_FILE" ]; then
        PID=$(cat "$TUNNEL_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            log_info "Killing Cloudflare tunnel (PID: $PID)..."
            kill -9 $PID 2>/dev/null || true
        fi
        rm -f "$TUNNEL_PID_FILE"
    fi
    
    # Kill any remaining cloudflared processes
    pkill -f cloudflared 2>/dev/null || true
    
    log_success "Cleanup completed"
}

# Function to start backend server
start_backend() {
    log_info "Starting backend server on port $BACKEND_PORT..."
    
    cd "$BACKEND_DIR"
    
    # Start the backend server in background
    nohup node server/index.js > "$BACKEND_DIR/backend.log" 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > "$BACKEND_PID_FILE"
    
    # Wait for server to be ready
    log_info "Waiting for backend server to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:$BACKEND_PORT/api/auth/status > /dev/null 2>&1; then
            log_success "Backend server is running (PID: $BACKEND_PID)"
            return 0
        fi
        sleep 1
    done
    
    log_error "Backend server failed to start"
    return 1
}

# Function to start Cloudflare tunnel
start_tunnel() {
    log_info "Starting Cloudflare tunnel..."
    
    # Start cloudflared tunnel in background
    nohup cloudflared tunnel --url http://localhost:$BACKEND_PORT > "$BACKEND_DIR/cloudflare/tunnel.log" 2>&1 &
    TUNNEL_PID=$!
    echo $TUNNEL_PID > "$TUNNEL_PID_FILE"
    
    # Wait for tunnel URL
    log_info "Waiting for tunnel URL..."
    for i in {1..30}; do
        if grep -q "https://.*\.trycloudflare\.com" "$BACKEND_DIR/cloudflare/tunnel.log" 2>/dev/null; then
            TUNNEL_URL=$(grep -o "https://.*\.trycloudflare\.com" "$BACKEND_DIR/cloudflare/tunnel.log" | head -1)
            echo "$TUNNEL_URL" > "$TUNNEL_URL_FILE"
            log_success "Tunnel is running (PID: $TUNNEL_PID)"
            log_success "Tunnel URL: $TUNNEL_URL"
            return 0
        fi
        sleep 1
    done
    
    log_error "Failed to get tunnel URL"
    return 1
}

# Function to test API endpoints
test_api_endpoints() {
    local BASE_URL=$1
    log_info "Testing API endpoints at $BASE_URL..."
    
    # Test auth status
    echo -e "\n${BLUE}Testing Auth Status:${NC}"
    curl -s -X GET "$BASE_URL/api/auth/status" | jq '.' 2>/dev/null || echo "Response: $(curl -s -X GET "$BASE_URL/api/auth/status")"
    
    # Test projects
    echo -e "\n${BLUE}Testing Projects:${NC}"
    curl -s -X GET "$BASE_URL/api/projects" | jq '.' 2>/dev/null || echo "Response: $(curl -s -X GET "$BASE_URL/api/projects")"
    
    # Test health
    echo -e "\n${BLUE}Testing Health:${NC}"
    curl -s -X GET "$BASE_URL/api/health" | jq '.' 2>/dev/null || echo "Response: $(curl -s -X GET "$BASE_URL/api/health")"
}

# Function to test WebSocket connection
test_websocket() {
    local WS_URL=$1
    log_info "Testing WebSocket connection at $WS_URL..."
    
    # Use websocat if available, otherwise use node
    if command -v websocat &> /dev/null; then
        echo '{"type":"ping"}' | timeout 5 websocat "$WS_URL" 2>&1 | head -5
    else
        log_warning "websocat not installed. Install with: brew install websocat"
        # Basic connection test using curl
        curl -s -i -N \
            -H "Connection: Upgrade" \
            -H "Upgrade: websocket" \
            -H "Sec-WebSocket-Version: 13" \
            -H "Sec-WebSocket-Key: $(openssl rand -base64 16)" \
            "$WS_URL" | head -10
    fi
}

# Function to monitor services
monitor_services() {
    log_info "Monitoring services..."
    
    # Check backend
    if [ -f "$BACKEND_PID_FILE" ]; then
        PID=$(cat "$BACKEND_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Backend server is running (PID: $PID)"
        else
            echo -e "${RED}✗${NC} Backend server is not running"
        fi
    else
        echo -e "${RED}✗${NC} Backend PID file not found"
    fi
    
    # Check tunnel
    if [ -f "$TUNNEL_PID_FILE" ]; then
        PID=$(cat "$TUNNEL_PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Cloudflare tunnel is running (PID: $PID)"
        else
            echo -e "${RED}✗${NC} Cloudflare tunnel is not running"
        fi
    else
        echo -e "${RED}✗${NC} Tunnel PID file not found"
    fi
    
    # Check tunnel URL
    if [ -f "$TUNNEL_URL_FILE" ]; then
        TUNNEL_URL=$(cat "$TUNNEL_URL_FILE")
        echo -e "${BLUE}Tunnel URL:${NC} $TUNNEL_URL"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}=== Cloudflare Tunnel Manager ===${NC}"
    
    case "${1:-start}" in
        start)
            log_info "Starting services with cleanup..."
            cleanup_all
            start_backend
            start_tunnel
            
            if [ -f "$TUNNEL_URL_FILE" ]; then
                TUNNEL_URL=$(cat "$TUNNEL_URL_FILE")
                echo -e "\n${GREEN}=== Services Started Successfully ===${NC}"
                echo -e "${BLUE}Backend:${NC} http://localhost:$BACKEND_PORT"
                echo -e "${BLUE}Tunnel:${NC} $TUNNEL_URL"
                
                # Test endpoints
                echo -e "\n${BLUE}=== Testing API Endpoints ===${NC}"
                test_api_endpoints "http://localhost:$BACKEND_PORT"
                
                echo -e "\n${BLUE}=== Testing Tunnel API ===${NC}"
                test_api_endpoints "$TUNNEL_URL"
                
                # Test WebSocket
                echo -e "\n${BLUE}=== Testing WebSocket ===${NC}"
                WS_URL="${TUNNEL_URL/https:/wss:}/ws"
                test_websocket "$WS_URL"
                
                # Show iOS configuration
                echo -e "\n${GREEN}=== iOS App Configuration ===${NC}"
                echo -e "${BLUE}Update AppConfig.swift with:${NC}"
                echo "baseURL = \"$TUNNEL_URL\""
                echo "wsURL = \"$WS_URL\""
            fi
            ;;
            
        stop)
            log_info "Stopping all services..."
            cleanup_all
            ;;
            
        restart)
            log_info "Restarting all services..."
            cleanup_all
            sleep 2
            start_backend
            start_tunnel
            ;;
            
        status)
            monitor_services
            ;;
            
        test)
            if [ -f "$TUNNEL_URL_FILE" ]; then
                TUNNEL_URL=$(cat "$TUNNEL_URL_FILE")
                test_api_endpoints "$TUNNEL_URL"
                WS_URL="${TUNNEL_URL/https:/wss:}/ws"
                test_websocket "$WS_URL"
            else
                log_error "No tunnel URL found. Run '$0 start' first."
            fi
            ;;
            
        logs)
            echo -e "${BLUE}=== Backend Logs ===${NC}"
            tail -20 "$BACKEND_DIR/backend.log"
            echo -e "\n${BLUE}=== Tunnel Logs ===${NC}"
            tail -20 "$BACKEND_DIR/cloudflare/tunnel.log"
            ;;
            
        *)
            echo "Usage: $0 {start|stop|restart|status|test|logs}"
            echo ""
            echo "Commands:"
            echo "  start    - Clean up and start all services"
            echo "  stop     - Stop all services"
            echo "  restart  - Restart all services"
            echo "  status   - Check service status"
            echo "  test     - Test API endpoints and WebSocket"
            echo "  logs     - Show recent logs"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"