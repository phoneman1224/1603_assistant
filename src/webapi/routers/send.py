"""
Send API Router
Handles TL1 command sending via PowerShell script
"""
import asyncio
import subprocess
import uuid
from typing import Dict
from fastapi import APIRouter, HTTPException

from ..models.schemas import SendRequest, SendResponse, JobStatus
from ..services.registry import registry
from ..logging_conf import get_logger, log_tl1


logger = get_logger(__name__)
router = APIRouter(prefix="/api/send", tags=["send"])

# Job storage (in-memory for simplicity)
jobs: Dict[str, JobStatus] = {}


async def run_powershell_send(host: str, port: int, command: str, job_id: str):
    """Run PowerShell send_tl1.ps1 script asynchronously"""
    script_path = registry.send_tl1_script
    
    if not script_path.exists():
        logger.error(f"PowerShell script not found: {script_path}")
        jobs[job_id].status = "error"
        jobs[job_id].output.append(f"ERROR: Script not found: {script_path}")
        jobs[job_id].completed = True
        return
    
    try:
        # Build PowerShell command
        ps_command = [
            "powershell.exe" if registry.root.drive else "pwsh",
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", str(script_path),
            "-Host", host,
            "-Port", str(port),
            "-Command", command
        ]
        
        logger.info(f"Executing: {' '.join(ps_command)}")
        
        # Run process
        process = await asyncio.create_subprocess_exec(
            *ps_command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        # Read output
        stdout, stderr = await process.communicate()
        
        # Parse output lines
        output_lines = []
        if stdout:
            for line in stdout.decode('utf-8', errors='ignore').split('\n'):
                line = line.strip()
                if line:
                    output_lines.append(line)
                    
                    # Log TL1-specific lines
                    if '[SEND]' in line:
                        log_tl1('SEND', line.replace('[SEND]', '').strip())
                    elif '[RECV]' in line:
                        log_tl1('RECV', line.replace('[RECV]', '').strip())
        
        if stderr:
            error_lines = stderr.decode('utf-8', errors='ignore').strip()
            if error_lines:
                output_lines.append(f"ERROR: {error_lines}")
        
        # Update job status
        jobs[job_id].output.extend(output_lines)
        jobs[job_id].status = "completed" if process.returncode == 0 else "failed"
        jobs[job_id].completed = True
        
        logger.info(f"Job {job_id} completed with return code {process.returncode}")
    
    except Exception as e:
        logger.error(f"Failed to run PowerShell script: {e}")
        jobs[job_id].status = "error"
        jobs[job_id].output.append(f"ERROR: {str(e)}")
        jobs[job_id].completed = True


@router.post("", response_model=SendResponse)
async def send_command(request: SendRequest):
    """Send TL1 command via PowerShell script"""
    try:
        # Generate job ID
        job_id = str(uuid.uuid4())
        
        # Initialize job
        jobs[job_id] = JobStatus(
            id=job_id,
            status="running",
            output=[],
            completed=False
        )
        
        # Start async task
        asyncio.create_task(
            run_powershell_send(request.host, request.port, request.command, job_id)
        )
        
        return SendResponse(
            job_id=job_id,
            status="running",
            message="Command sent, processing..."
        )
    
    except Exception as e:
        logger.error(f"Failed to send command: {e}")
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
