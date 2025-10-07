"""
Commands API Router
Handles command listing, filtering, and preview
"""
from typing import List, Optional
from fastapi import APIRouter, Query, HTTPException

from ..models.schemas import Command, Category, CommandRequest, PreviewResponse
from ..services.catalog import catalog
from ..services.builder import builder
from ..logging_conf import get_logger


logger = get_logger(__name__)
router = APIRouter(prefix="/api/commands", tags=["commands"])


@router.get("", response_model=List[Command])
async def get_commands(platform: Optional[str] = Query(None)):
    """Get all commands, optionally filtered by platform"""
    try:
        commands = catalog.get_all_commands(platform=platform)
        return commands
    except Exception as e:
        logger.error(f"Failed to get commands: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/categories", response_model=List[Category])
async def get_categories(platform: Optional[str] = Query(None)):
    """Get list of categories for a platform"""
    try:
        categories = catalog.get_categories(platform=platform)
        return categories
    except Exception as e:
        logger.error(f"Failed to get categories: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{cmd_id}", response_model=Command)
async def get_command(cmd_id: str):
    """Get a specific command by ID"""
    try:
        command = catalog.get_command(cmd_id)
        if not command:
            raise HTTPException(status_code=404, detail=f"Command not found: {cmd_id}")
        return command
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get command {cmd_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/preview", response_model=PreviewResponse)
async def preview_command(request: CommandRequest):
    """Build and preview a command"""
    try:
        command, warnings = builder.build_command(
            cmd_id=request.id,
            tid=request.TID or "",
            aid=request.AID or "",
            ctag=request.CTAG,
            optional=request.optional
        )
        
        return PreviewResponse(command=command, warnings=warnings)
    
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to preview command: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/reload")
async def reload_catalog():
    """Reload the command catalog"""
    try:
        catalog.reload()
        return {"status": "ok", "message": "Catalog reloaded"}
    except Exception as e:
        logger.error(f"Failed to reload catalog: {e}")
        raise HTTPException(status_code=500, detail=str(e))
