"""
Pydantic schemas for request/response validation
"""
from typing import Dict, List, Optional, Any
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    versions: Dict[str, str]


class Settings(BaseModel):
    connection: Dict[str, Any]
    defaults: Dict[str, Any]
    logging: Dict[str, Any]
    ui: Dict[str, Any]


class CommandRequest(BaseModel):
    id: str
    TID: Optional[str] = ""
    AID: Optional[str] = ""
    CTAG: str
    optional: Optional[Dict[str, Any]] = {}


class PreviewResponse(BaseModel):
    command: str
    warnings: Optional[List[str]] = []


class SendRequest(BaseModel):
    command: str
    host: str
    port: int


class SendResponse(BaseModel):
    job_id: str
    status: str
    message: str


class JobStatus(BaseModel):
    id: str
    status: str
    output: List[str]
    completed: bool


class TroubleshootRequest(BaseModel):
    flowName: str
    TID: Optional[str] = ""
    AID: Optional[str] = ""


class ProvisionRequest(BaseModel):
    flowName: str
    stepState: Dict[str, Any]
    TID: Optional[str] = ""


class Command(BaseModel):
    id: str
    name: str
    verb: str
    object: str
    modifier: Optional[str] = ""
    category: str
    platform: List[str]
    description: str
    required: List[str]
    optional: List[str]
    paramSchema: Dict[str, Any]
    examples: List[str]
    safety_level: str
    service_affecting: bool
    response_format: str


class Playbook(BaseModel):
    id: str
    name: str
    description: str
    steps: List[Dict[str, Any]]


class Category(BaseModel):
    name: str
    description: str
    icon: str
    count: int
