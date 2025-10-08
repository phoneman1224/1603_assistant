"""
Test configuration and fixtures
"""
import pytest
import asyncio
from pathlib import Path


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def sample_command_data():
    """Sample command data for testing"""
    return {
        "id": "RTRV-ALM-ALL",
        "displayName": "Retrieve All Alarms",
        "platforms": ["1603 SM", "1603 SMX"],
        "category": "Alarm Management",
        "verb": "RTRV",
        "object": "ALM-ALL",
        "modifier": None,
        "description": "Retrieve all active alarms",
        "syntax": "RTRV-ALM-ALL:[tid]:[aid]:[ctag]::;",
        "requires": ["TID", "CTAG"],
        "optional": ["AID"],
        "response_format": "M [ctag] COMPLD\\n[alarm data]\\n;",
        "safety_level": "safe",
        "service_affecting": False,
        "examples": ["RTRV-ALM-ALL:SITE01::123::;"],
        "paramSchema": {
            "TID": {
                "type": "string",
                "maxLength": 20,
                "description": "Target identifier"
            },
            "AID": {
                "type": "string",
                "maxLength": 32,
                "description": "Access identifier"
            },
            "CTAG": {
                "type": "string",
                "maxLength": 6,
                "description": "Correlation tag"
            }
        }
    }


@pytest.fixture
def mock_catalog(sample_command_data):
    """Mock catalog service for testing"""
    class MockCatalog:
        def __init__(self):
            self.commands = {"RTRV-ALM-ALL": sample_command_data}
        
        def get_command(self, cmd_id):
            return self.commands.get(cmd_id)
        
        def get_all_commands(self, platform=None):
            commands = list(self.commands.values())
            if platform:
                commands = [cmd for cmd in commands if platform in cmd['platforms']]
            return commands
    
    return MockCatalog()


@pytest.fixture
def test_data_dir():
    """Path to test data directory"""
    return Path(__file__).parent / "data"