"""
Settings API Router
Handles settings.json read/write operations
"""
import json
from fastapi import APIRouter, HTTPException

from ..models.schemas import Settings
from ..services.registry import registry
from ..logging_conf import get_logger


logger = get_logger(__name__)
router = APIRouter(prefix="/api/settings", tags=["settings"])


@router.get("", response_model=Settings)
async def get_settings():
    """Get current settings"""
    try:
        settings_file = registry.settings_json
        
        if not settings_file.exists():
            # Return default settings
            return Settings(
                connection={"host": "localhost", "port": 10201, "timeout": 30},
                defaults={"lastTID": "", "lastAID": "", "nextCTAG": 1, "platform": "1603 SM"},
                logging={"logRoot": "./logs", "debugMode": False, "rotationEnabled": True},
                ui={"theme": "light", "autoConnect": False}
            )
        
        with open(settings_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return Settings(**data)
    
    except Exception as e:
        logger.error(f"Failed to get settings: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("")
async def update_settings(settings: Settings):
    """Update settings"""
    try:
        settings_file = registry.settings_json
        
        with open(settings_file, 'w', encoding='utf-8') as f:
            json.dump(settings.model_dump(), f, indent=2)
        
        logger.info("Settings updated")
        return {"status": "ok", "message": "Settings updated"}
    
    except Exception as e:
        logger.error(f"Failed to update settings: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/ctag/increment")
async def increment_ctag():
    """Increment and return next CTAG"""
    try:
        settings_file = registry.settings_json
        
        # Read current settings
        with open(settings_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Increment CTAG
        current_ctag = data.get('defaults', {}).get('nextCTAG', 1)
        next_ctag = current_ctag + 1
        
        # Update settings
        if 'defaults' not in data:
            data['defaults'] = {}
        data['defaults']['nextCTAG'] = next_ctag
        
        # Write back
        with open(settings_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        
        return {"currentCTAG": current_ctag, "nextCTAG": next_ctag}
    
    except Exception as e:
        logger.error(f"Failed to increment CTAG: {e}")
        raise HTTPException(status_code=500, detail=str(e))
