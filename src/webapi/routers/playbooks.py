"""
Playbooks API Router
Handles troubleshooting and provisioning playbooks
"""
from typing import Dict
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from ..models.schemas import TroubleshootRequest, ProvisionRequest
from ..services.runner import runner
from ..logging_conf import get_logger


logger = get_logger(__name__)
router = APIRouter(prefix="/api/playbooks", tags=["playbooks"])


@router.get("")
async def get_playbooks():
    """Get all playbooks"""
    try:
        playbooks = runner.get_all_playbooks()
        return playbooks
    except Exception as e:
        logger.error(f"Failed to get playbooks: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{flow_name}")
async def get_playbook(flow_name: str):
    """Get a specific playbook"""
    try:
        playbook = runner.get_playbook(flow_name)
        if not playbook:
            raise HTTPException(status_code=404, detail=f"Playbook not found: {flow_name}")
        return playbook
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get playbook {flow_name}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/troubleshoot")
async def troubleshoot(request: TroubleshootRequest):
    """
    Run a troubleshooting playbook
    Returns results (non-streaming for simplicity)
    """
    try:
        results = []
        async for update in runner.run_troubleshooting(
            flow_name=request.flowName,
            tid=request.TID or "",
            aid=request.AID or "",
            ctag_start=1,
            sender_func=None  # Would need to integrate with send service
        ):
            results.append(update)
        
        return {"status": "ok", "results": results}
    
    except Exception as e:
        logger.error(f"Troubleshooting failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/provision")
async def provision(request: ProvisionRequest):
    """
    Run a provisioning workflow
    Returns preview or result
    """
    try:
        result = await runner.run_provisioning(
            flow_name=request.flowName,
            step_state=request.stepState,
            tid=request.TID or "",
            ctag=1,
            send=False,  # Preview only by default
            sender_func=None
        )
        
        return result
    
    except Exception as e:
        logger.error(f"Provisioning failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
