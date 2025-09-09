#!/bin/bash

# Backend Server Startup Script for Claude Code iOS
# This script starts the FastAPI backend server on port 3004

echo "========================================="
echo "Claude Code Backend Server Startup Script"
echo "========================================="

# Configuration
BACKEND_DIR="/Users/nick/Documents/claude-code-monorepo/services/backend"
PORT=3004
HOST="0.0.0.0"  # Listen on all interfaces for iOS simulator access

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if port is in use
check_port() {
    if lsof -i :$PORT > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Port $PORT is already in use${NC}"
        echo "Checking what's running on port $PORT..."
        lsof -i :$PORT
        echo ""
        read -p "Do you want to kill the existing process? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Killing existing process on port $PORT..."
            lsof -ti :$PORT | xargs kill -9 2>/dev/null
            sleep 2
        else
            echo -e "${RED}Cannot start backend. Port $PORT is occupied.${NC}"
            exit 1
        fi
    fi
}

# Function to check Python installation
check_python() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: Python 3 is not installed${NC}"
        echo "Please install Python 3: brew install python3"
        exit 1
    fi
    echo -e "${GREEN}✓ Python 3 found: $(python3 --version)${NC}"
}

# Function to check backend directory
check_backend_dir() {
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${RED}Error: Backend directory not found at $BACKEND_DIR${NC}"
        echo "The backend code appears to be missing."
        echo ""
        echo "To fix this:"
        echo "1. Clone the monorepo: git clone [repository-url] /Users/nick/Documents/claude-code-monorepo"
        echo "2. Or create a minimal backend in the iOS project's backend/ directory"
        exit 1
    fi
    echo -e "${GREEN}✓ Backend directory found${NC}"
}

# Function to install dependencies
install_dependencies() {
    echo "Checking Python dependencies..."
    cd "$BACKEND_DIR"
    
    if [ -f "requirements.txt" ]; then
        echo "Installing dependencies from requirements.txt..."
        pip3 install -r requirements.txt --quiet --disable-pip-version-check
        echo -e "${GREEN}✓ Dependencies installed${NC}"
    else
        echo -e "${YELLOW}Warning: requirements.txt not found${NC}"
        echo "Installing minimal FastAPI dependencies..."
        pip3 install fastapi uvicorn websockets redis sqlalchemy --quiet --disable-pip-version-check
        echo -e "${GREEN}✓ Minimal dependencies installed${NC}"
    fi
}

# Function to create minimal backend if needed
create_minimal_backend() {
    echo -e "${YELLOW}Creating minimal backend server...${NC}"
    
    # Create backend directory in iOS project
    mkdir -p /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/backend
    
    cat > /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/backend/server.py << 'EOF'
"""
Minimal FastAPI backend for Claude Code iOS
Provides basic API endpoints for development and testing
"""

from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import asyncio
import json
from typing import List, Dict, Any
from datetime import datetime

app = FastAPI(title="Claude Code iOS Backend", version="1.0.0")

# CORS configuration for iOS simulator
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for development
projects = []
sessions = []
messages = []
connected_websockets: List[WebSocket] = []

@app.get("/")
async def root():
    return {"message": "Claude Code Backend API", "status": "running", "port": 3004}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/api/projects")
async def get_projects():
    return {"projects": projects, "count": len(projects)}

@app.post("/api/projects")
async def create_project(project: Dict[str, Any]):
    project["id"] = len(projects) + 1
    project["created_at"] = datetime.now().isoformat()
    projects.append(project)
    return {"project": project, "status": "created"}

@app.get("/api/sessions")
async def get_sessions():
    return {"sessions": sessions, "count": len(sessions)}

@app.post("/api/sessions")
async def create_session(session: Dict[str, Any]):
    session["id"] = len(sessions) + 1
    session["created_at"] = datetime.now().isoformat()
    sessions.append(session)
    return {"session": session, "status": "created"}

@app.get("/api/messages")
async def get_messages():
    return {"messages": messages, "count": len(messages)}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    connected_websockets.append(websocket)
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Echo message back to all connected clients
            for ws in connected_websockets:
                if ws != websocket:
                    await ws.send_text(json.dumps({
                        "type": "message",
                        "data": message,
                        "timestamp": datetime.now().isoformat()
                    }))
            
            # Store message
            messages.append(message)
            
    except Exception as e:
        print(f"WebSocket error: {e}")
    finally:
        if websocket in connected_websockets:
            connected_websockets.remove(websocket)

if __name__ == "__main__":
    print(f"Starting Claude Code Backend on port 3004...")
    print(f"API Documentation: http://localhost:3004/docs")
    print(f"Health Check: http://localhost:3004/health")
    uvicorn.run(app, host="0.0.0.0", port=3004, log_level="info")
EOF
    
    echo -e "${GREEN}✓ Minimal backend created${NC}"
}

# Main execution
echo "Starting backend server setup..."
echo ""

# Check Python
check_python

# Check if port is available
check_port

# Check if backend exists
if [ -d "$BACKEND_DIR" ] && [ -f "$BACKEND_DIR/app/main.py" ]; then
    echo "Using production backend from monorepo..."
    check_backend_dir
    install_dependencies
    
    # Start the production backend
    echo ""
    echo -e "${GREEN}Starting FastAPI backend server...${NC}"
    echo "Server URL: http://192.168.0.155:$PORT"
    echo "API Docs: http://192.168.0.155:$PORT/docs"
    echo "WebSocket: ws://192.168.0.155:$PORT/ws"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo "========================================="
    
    cd "$BACKEND_DIR"
    # Set environment variable for port and start server
    PORT=$PORT python3 -m uvicorn app.main:app --host $HOST --port $PORT --reload
    
else
    echo -e "${YELLOW}Production backend not found. Using minimal backend...${NC}"
    create_minimal_backend
    
    # Install minimal dependencies if needed
    pip3 install fastapi uvicorn --quiet --disable-pip-version-check
    
    # Start the minimal backend
    echo ""
    echo -e "${GREEN}Starting minimal backend server...${NC}"
    echo "Server URL: http://192.168.0.155:$PORT"
    echo "API Docs: http://192.168.0.155:$PORT/docs"
    echo "WebSocket: ws://192.168.0.155:$PORT/ws"
    echo ""
    echo "Press Ctrl+C to stop the server"
    echo "========================================="
    
    cd /Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/backend
    python3 server.py
fi