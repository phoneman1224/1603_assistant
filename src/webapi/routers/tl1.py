"""
TL1 API Router
Handles TL1 command building, sending, and logging
"""
import asyncio
import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional

from fastapi import APIRouter, HTTPException

from ..models.schemas import (
    CommandRequest, PreviewResponse, SendRequest, SendResponse, 
    JobStatus, LogRequest, LogResponse
)
from ..services.builder import builder
from ..services.transport import send_tl1_command
from ..services.registry import registry
from ..logging_conf import get_logger, log_tl1


logger = get_logger(__name__)
router = APIRouter(prefix="/api/tl1", tags=["tl1"])

# Job storage (in-memory for simplicity)
jobs: Dict[str, JobStatus] = {}


@router.post("/build", response_model=PreviewResponse)
async def build_command(request: CommandRequest):
    """Build and preview a TL1 command"""
    try:
        command, warnings = builder.build_command(
            cmd_id=request.id,
            tid=request.TID or "",
            aid=request.AID or "",
            ctag=request.CTAG,
            optional=request.optional
        )
        
        logger.info(f"Built command: {command}")
        return PreviewResponse(command=command, warnings=warnings)
    
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to build command: {e}")
        raise HTTPException(status_code=500, detail=str(e))


async def run_socket_send(host: str, port: int, command: str, job_id: str, timeout: int = 30):
    """Send TL1 command via transport service"""
    try:
        # Update job status
        jobs[job_id].status = "connecting"
        jobs[job_id].output.append(f"[INFO] Connecting to {host}:{port}")
        
        # Send command using transport service
        response_lines, success = await send_tl1_command(host, port, command, timeout)
        
        # Update job with results
        jobs[job_id].output.append(f"[SEND] {command}")
        log_tl1('SEND', command)
        
        for line in response_lines:
            jobs[job_id].output.append(f"[RECV] {line}")
            log_tl1('RECV', line)
        
        jobs[job_id].status = "completed" if success else "failed"
        jobs[job_id].completed = True
        
        status_msg = "completed successfully" if success else "failed"
        jobs[job_id].output.append(f"[INFO] Command {status_msg}, {len(response_lines)} response lines")
        
        logger.info(f"Job {job_id} {status_msg}")
        
    except Exception as e:
        jobs[job_id].status = "failed"
        jobs[job_id].output.append(f"[ERROR] {str(e)}")
        jobs[job_id].completed = True
        logger.error(f"Job {job_id} failed: {e}")


@router.post("/send", response_model=SendResponse)
async def send_command(request: SendRequest):
    """Send TL1 command via socket connection"""
    try:
        # Generate job ID
        job_id = str(uuid.uuid4())
        
        # Initialize job
        jobs[job_id] = JobStatus(
            id=job_id,
            status="queued",
            output=[],
            completed=False
        )
        
        # Start async task
        asyncio.create_task(
            run_socket_send(request.host, request.port, request.command, job_id)
        )
        
        return SendResponse(
            job_id=job_id,
            status="queued",
            message="Command queued for sending..."
        )
    
    except Exception as e:
        logger.error(f"Failed to queue command: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/jobs/{job_id}", response_model=JobStatus)
async def get_job_status(job_id: str):
    """Get status of a send job"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return jobs[job_id]


@router.delete("/jobs/{job_id}")
async def delete_job(job_id: str):
    """Delete a completed job"""
    if job_id not in jobs:
        raise HTTPException(status_code=404, detail="Job not found")
    
    del jobs[job_id]
    return {"status": "ok", "message": "Job deleted"}


@router.post("/log", response_model=LogResponse)
async def log_session(request: LogRequest):
    """Log TL1 session data to daily log file"""
    try:
        # Generate log filename based on current date
        today = datetime.now().strftime("%Y%m%d")
        log_file = registry.logs_dir / f"{today}.txt"
        
        # Ensure logs directory exists
        registry.logs_dir.mkdir(exist_ok=True)
        
        # Prepare log entry
        timestamp = datetime.now().isoformat()
        log_entry = {
            "timestamp": timestamp,
            "command": request.command,
            "response": request.response,
            "host": request.host,
            "port": request.port
        }
        
        # Append to log file
        with open(log_file, 'a', encoding='utf-8') as f:
            f.write(json.dumps(log_entry) + "\\n")
        
        logger.info(f"Logged session data to {log_file}")
        
        return LogResponse(
            status="ok",
            message=f"Session logged to {log_file.name}",
            log_file=str(log_file)
        )
        
    except Exception as e:
        logger.error(f"Failed to log session: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/logs")
async def list_log_files():
    """List available log files"""
    try:
        if not registry.logs_dir.exists():
            return {"logs": []}
        
        log_files = []
        for log_file in registry.logs_dir.glob("*.txt"):
            log_files.append({
                "name": log_file.name,
                "path": str(log_file),
                "size": log_file.stat().st_size,
                "modified": datetime.fromtimestamp(log_file.stat().st_mtime).isoformat()
            })
        
        return {"logs": sorted(log_files, key=lambda x: x["name"], reverse=True)}
        
    except Exception as e:
        logger.error(f"Failed to list log files: {e}")
        raise HTTPException(status_code=500, detail=str(e))