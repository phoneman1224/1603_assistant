"""
Tests for TL1 Builder Service
"""
import pytest
from unittest.mock import Mock, patch
from src.webapi.services.builder import TL1Builder


class TestTL1Builder:
    """Test cases for TL1Builder"""
    
    def setup_method(self):
        """Setup for each test"""
        self.builder = TL1Builder()
    
    def test_build_simple_command(self, mock_catalog, sample_command_data):
        """Test building a simple TL1 command"""
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="RTRV-ALM-ALL",
                tid="SITE01",
                aid="",
                ctag="123"
            )
            
            assert command == "RTRV-ALM-ALL:SITE01::123::;"
            assert len(warnings) == 0
    
    def test_build_command_with_empty_tid(self, mock_catalog):
        """Test building command with empty TID"""
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="RTRV-ALM-ALL",
                tid="",
                aid="ALL",
                ctag="456"
            )
            
            assert command == "RTRV-ALM-ALL::ALL:456::;"
            assert len(warnings) == 0
    
    def test_build_command_with_optional_params(self, mock_catalog):
        """Test building command with optional parameters"""
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="RTRV-ALM-ALL",
                tid="SITE01",
                aid="ALL",
                ctag="789",
                optional={"MONDAT": "20251008", "MONTIM": "120000"}
            )
            
            assert command == "RTRV-ALM-ALL:SITE01:ALL:789::MONDAT=20251008,MONTIM=120000;"
            assert len(warnings) == 0
    
    def test_build_command_auto_ctag(self, mock_catalog):
        """Test auto-generation of CTAG when empty"""
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="RTRV-ALM-ALL",
                tid="SITE01",
                aid="",
                ctag=""
            )
            
            assert command == "RTRV-ALM-ALL:SITE01::1::;"
            assert "CTAG is required, defaulting to '1'" in warnings
    
    def test_build_command_with_modifier(self, mock_catalog):
        """Test building command with modifier"""
        # Create a command with modifier
        cmd_with_modifier = {
            "id": "ED-STS1",
            "verb": "ED",
            "object": "STS1",
            "modifier": "CRS",
            "syntax": "ED-CRS-STS1:[tid]:[aid]:[ctag]::;",
            "requires": ["TID", "CTAG"],
            "optional": ["AID"]
        }
        mock_catalog.commands["ED-STS1"] = cmd_with_modifier
        
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="ED-STS1",
                tid="SITE01",
                aid="STS1-1",
                ctag="100"
            )
            
            assert command == "ED-CRS-STS1:SITE01:STS1-1:100::;"
            assert len(warnings) == 0
    
    def test_build_command_not_found(self, mock_catalog):
        """Test building non-existent command"""
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            with pytest.raises(ValueError, match="Command not found: INVALID-CMD"):
                self.builder.build_command(
                    cmd_id="INVALID-CMD",
                    tid="SITE01",
                    aid="",
                    ctag="123"
                )
    
    def test_build_command_service_affecting_warning(self, mock_catalog):
        """Test warning for service-affecting commands"""
        # Create service-affecting command
        service_cmd = mock_catalog.commands["RTRV-ALM-ALL"].copy()
        service_cmd["service_affecting"] = True
        mock_catalog.commands["RTRV-ALM-ALL"] = service_cmd
        
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="RTRV-ALM-ALL",
                tid="SITE01",
                aid="",
                ctag="123"
            )
            
            assert command == "RTRV-ALM-ALL:SITE01::123::;"
            assert "WARNING: This command is service-affecting!" in warnings
    
    def test_build_command_safety_level_warning(self, mock_catalog):
        """Test warning for dangerous commands"""
        # Create dangerous command
        dangerous_cmd = mock_catalog.commands["RTRV-ALM-ALL"].copy()
        dangerous_cmd["safety_level"] = "dangerous"
        mock_catalog.commands["RTRV-ALM-ALL"] = dangerous_cmd
        
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="RTRV-ALM-ALL",
                tid="SITE01",
                aid="",
                ctag="123"
            )
            
            assert command == "RTRV-ALM-ALL:SITE01::123::;"
            assert "CAUTION: Safety level is 'dangerous'" in warnings
    
    def test_preview_command_manual(self):
        """Test manual command building"""
        command, warnings = self.builder.preview_command(
            verb="RTRV",
            obj="ALM-ALL",
            tid="SITE01",
            aid="",
            ctag="123",
            params="MONDAT=20251008"
        )
        
        assert command == "RTRV-ALM-ALL:SITE01::123::MONDAT=20251008;"
        assert len(warnings) == 0
    
    def test_preview_command_with_modifier(self):
        """Test manual command building with modifier"""
        command, warnings = self.builder.preview_command(
            verb="ED",
            obj="STS1",
            modifier="CRS",
            tid="SITE01",
            aid="STS1-1",
            ctag="100"
        )
        
        assert command == "ED-CRS-STS1:SITE01:STS1-1:100::;"
        assert len(warnings) == 0
    
    def test_filter_empty_optional_params(self, mock_catalog):
        """Test filtering of empty optional parameters"""
        with patch('src.webapi.services.builder.catalog', mock_catalog):
            command, warnings = self.builder.build_command(
                cmd_id="RTRV-ALM-ALL",
                tid="SITE01",
                aid="",
                ctag="123",
                optional={
                    "PARAM1": "value1",
                    "PARAM2": "",  # Empty string should be filtered
                    "PARAM3": None,  # None should be filtered
                    "PARAM4": "value4"
                }
            )
            
            assert command == "RTRV-ALM-ALL:SITE01::123::PARAM1=value1,PARAM4=value4;"
            assert len(warnings) == 0