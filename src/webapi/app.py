"""
TL1 Assistant FastAPI Application
Main entry point for the Web API
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path

from .logging_conf import setup_logging, get_logger
from .services.registry import registry
from .routers import commands, settings, playbooks, send
from .models.schemas import HealthResponse

# Initialize logging
settings_data = {}
try:
    import json
    if registry.settings_json.exists():
        with open(registry.settings_json, 'r') as f:
            settings_data = json.load(f)
except:
    pass

log_root = settings_data.get('logging', {}).get('logRoot', './logs')
debug_mode = settings_data.get('logging', {}).get('debugMode', False)
setup_logging(log_root=log_root, debug_mode=debug_mode)

logger = get_logger(__name__)

# Create FastAPI app
app = FastAPI(
    title="TL1 Assistant API",
    description="FastAPI backend for TL1 command management and execution",
    version="1.0.0"
)

# CORS configuration - localhost only for security
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:8000",
        "http://127.0.0.1:5173",
        "http://127.0.0.1:8000"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(commands.router)
app.include_router(settings.router)
app.include_router(playbooks.router)
app.include_router(send.router)


@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="ok",
        versions={
            "api": "1.0.0",
            "ui": "1.0.0"
        }
    )


@app.on_event("startup")
async def startup_event():
    """Application startup"""
    logger.info("=" * 60)
    logger.info("TL1 Assistant Web API Starting")
    logger.info(f"API Version: 1.0.0")
    logger.info(f"Data Root: {registry.root}")
    logger.info(f"Commands: {registry.commands_json}")
    logger.info(f"Playbooks: {registry.playbooks_json}")
    logger.info(f"Settings: {registry.settings_json}")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown"""
    logger.info("TL1 Assistant Web API Shutting Down")


# Serve static files (if webui is built)
webui_dist = Path(__file__).parent.parent.parent / "webui" / "dist"
if webui_dist.exists():
    app.mount("/", StaticFiles(directory=str(webui_dist), html=True), name="static")
    logger.info(f"Serving static UI from: {webui_dist}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        log_level="info"
    )
