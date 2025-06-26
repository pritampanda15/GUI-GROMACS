from fastapi import FastAPI, File, UploadFile, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import os
import shutil
import subprocess
import json
import asyncio
from typing import List, Optional, Dict, Any
import uuid
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="GROMACS GUI API", version="1.0.0")

# CORS middleware for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # React dev server
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create necessary directories
os.makedirs("uploads", exist_ok=True)
os.makedirs("projects", exist_ok=True)
os.makedirs("logs", exist_ok=True)

# Data models
class ProjectCreate(BaseModel):
    name: str
    description: Optional[str] = ""

class SimulationConfig(BaseModel):
    project_id: str
    forcefield: str
    temperature: float = 300.0
    pressure: float = 1.0
    time_step: float = 0.002
    total_time: float = 10.0  # ns
    gpu_enabled: bool = True
    ntomp: int = 4
    ntmpi: int = 1

class FileInfo(BaseModel):
    filename: str
    file_type: str
    size: int
    upload_time: datetime

# In-memory storage (replace with database in production)
projects: Dict[str, Dict] = {}
active_connections: List[WebSocket] = []

# WebSocket manager for real-time logging
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)

manager = ConnectionManager()

@app.get("/")
async def root():
    return {"message": "GROMACS GUI API is running"}

@app.post("/api/projects/create")
async def create_project(project: ProjectCreate):
    """Create a new simulation project"""
    project_id = str(uuid.uuid4())
    project_dir = f"projects/{project_id}"
    os.makedirs(project_dir, exist_ok=True)
    
    projects[project_id] = {
        "id": project_id,
        "name": project.name,
        "description": project.description,
        "created_at": datetime.now().isoformat(),
        "status": "created",
        "files": [],
        "config": None
    }
    
    return {"project_id": project_id, "status": "created"}

@app.get("/api/projects")
async def list_projects():
    """List all projects"""
    return list(projects.values())

@app.get("/api/projects/{project_id}")
async def get_project(project_id: str):
    """Get project details"""
    if project_id not in projects:
        raise HTTPException(status_code=404, detail="Project not found")
    return projects[project_id]

@app.post("/api/projects/{project_id}/upload")
async def upload_file(project_id: str, file: UploadFile = File(...)):
    """Upload files to a project"""
    if project_id not in projects:
        raise HTTPException(status_code=404, detail="Project not found")
    
    # Validate file type
    allowed_extensions = ['.pdb', '.gro', '.mol2', '.sdf', '.itp', '.top', '.mdp']
    file_ext = os.path.splitext(file.filename)[1].lower()
    
    if file_ext not in allowed_extensions:
        raise HTTPException(status_code=400, detail=f"File type {file_ext} not allowed")
    
    # Save file
    project_dir = f"projects/{project_id}"
    file_path = os.path.join(project_dir, file.filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Update project info
    file_info = FileInfo(
        filename=file.filename,
        file_type=file_ext,
        size=os.path.getsize(file_path),
        upload_time=datetime.now()
    )
    
    projects[project_id]["files"].append(file_info.dict())
    
    return {"message": "File uploaded successfully", "file_info": file_info}

@app.get("/api/forcefields")
async def get_forcefields():
    """Get available GROMACS force fields"""
    # This would normally check GROMACS installation
    forcefields = [
        {"name": "amber99sb-ildn", "description": "AMBER99SB-ILDN protein force field"},
        {"name": "charmm36-jul2022", "description": "CHARMM36 all-atom force field"},
        {"name": "gromos54a7", "description": "GROMOS 54A7 united-atom force field"},
        {"name": "oplsaa", "description": "OPLS-AA all-atom force field"},
        {"name": "amber14sb", "description": "AMBER14SB protein force field"}
    ]
    return forcefields

@app.post("/api/projects/{project_id}/configure")
async def configure_simulation(project_id: str, config: SimulationConfig):
    """Configure simulation parameters"""
    if project_id not in projects:
        raise HTTPException(status_code=404, detail="Project not found")
    
    projects[project_id]["config"] = config.dict()
    projects[project_id]["status"] = "configured"
    
    return {"message": "Simulation configured successfully"}

@app.post("/api/projects/{project_id}/start")
async def start_simulation(project_id: str):
    """Start GROMACS simulation"""
    if project_id not in projects:
        raise HTTPException(status_code=404, detail="Project not found")
    
    project = projects[project_id]
    if not project.get("config"):
        raise HTTPException(status_code=400, detail="Project not configured")
    
    # Update status
    projects[project_id]["status"] = "running"
    
    # Start simulation in background
    asyncio.create_task(run_gromacs_simulation(project_id))
    
    return {"message": "Simulation started", "project_id": project_id}

async def run_gromacs_simulation(project_id: str):
    """Run GROMACS simulation asynchronously"""
    try:
        project = projects[project_id]
        project_dir = f"projects/{project_id}"
        config = project["config"]
        
        # Broadcast status updates
        await manager.broadcast(f"Starting simulation for project {project_id}")
        
        # Step 1: Generate topology (simplified example)
        cmd = ["echo", "Generating topology..."]  # Replace with actual GROMACS commands
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=project_dir
        )
        
        stdout, stderr = await process.communicate()
        
        if stdout:
            await manager.broadcast(f"STDOUT: {stdout.decode()}")
        if stderr:
            await manager.broadcast(f"STDERR: {stderr.decode()}")
        
        # Update project status
        projects[project_id]["status"] = "completed"
        await manager.broadcast(f"Simulation completed for project {project_id}")
        
    except Exception as e:
        projects[project_id]["status"] = "failed"
        await manager.broadcast(f"Simulation failed: {str(e)}")

@app.websocket("/ws/{project_id}")
async def websocket_endpoint(websocket: WebSocket, project_id: str):
    """WebSocket for real-time logging"""
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Echo back for now
            await manager.send_personal_message(f"Echo: {data}", websocket)
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@app.get("/api/projects/{project_id}/logs")
async def get_logs(project_id: str):
    """Get simulation logs"""
    if project_id not in projects:
        raise HTTPException(status_code=404, detail="Project not found")
    
    log_file = f"logs/{project_id}.log"
    if os.path.exists(log_file):
        with open(log_file, 'r') as f:
            return {"logs": f.read()}
    return {"logs": "No logs available"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
