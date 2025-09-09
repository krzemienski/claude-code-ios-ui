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