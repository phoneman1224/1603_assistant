"""
Tests for TL1 Transport Service
"""
import pytest
import asyncio
from unittest.mock import Mock, AsyncMock, patch
from src.webapi.services.transport import TL1Transport, TL1Session, send_tl1_command


class TestTL1Transport:
    """Test cases for TL1Transport"""
    
    def setup_method(self):
        """Setup for each test"""
        self.transport = TL1Transport(timeout=5)
    
    @pytest.mark.asyncio
    async def test_connect_success(self):
        """Test successful connection"""
        mock_reader = Mock()
        mock_writer = Mock()
        
        with patch('asyncio.open_connection', return_value=(mock_reader, mock_writer)):
            result = await self.transport.connect("localhost", 23)
            assert result is True
            assert self.transport.connected is True
            assert self.transport.reader == mock_reader
            assert self.transport.writer == mock_writer
    
    @pytest.mark.asyncio
    async def test_connect_timeout(self):
        """Test connection timeout"""
        with patch('asyncio.open_connection', side_effect=asyncio.TimeoutError()):
            result = await self.transport.connect("localhost", 23)
            assert result is False
            assert self.transport.connected is False
    
    @pytest.mark.asyncio
    async def test_connect_refused(self):
        """Test connection refused"""
        with patch('asyncio.open_connection', side_effect=ConnectionRefusedError()):
            result = await self.transport.connect("localhost", 23)
            assert result is False
            assert self.transport.connected is False
    
    @pytest.mark.asyncio
    async def test_send_command_success(self):
        """Test successful command sending"""
        # Mock reader and writer
        mock_reader = AsyncMock()
        mock_writer = Mock()
        mock_writer.write = Mock()
        mock_writer.drain = AsyncMock()
        
        # Mock response
        response_lines = [
            b"   SITE01 25-10-08 12:30:45\\n",
            b"M  123 COMPLD\\n", 
            b";\\n"
        ]
        mock_reader.readline.side_effect = response_lines
        
        # Setup transport
        self.transport.connected = True
        self.transport.reader = mock_reader
        self.transport.writer = mock_writer
        
        # Send command
        result = await self.transport.send_command("RTRV-ALM-ALL:SITE01::123::;")
        
        # Verify
        mock_writer.write.assert_called_once()
        assert len(result) == 3
        assert "COMPLD" in result[1]
    
    @pytest.mark.asyncio
    async def test_send_command_not_connected(self):
        """Test sending command when not connected"""
        with pytest.raises(RuntimeError, match="Not connected to TL1 device"):
            await self.transport.send_command("RTRV-ALM-ALL:SITE01::123::;")
    
    @pytest.mark.asyncio
    async def test_disconnect(self):
        """Test disconnection"""
        mock_writer = Mock()
        mock_writer.close = Mock()
        mock_writer.wait_closed = AsyncMock()
        
        self.transport.connected = True
        self.transport.writer = mock_writer
        
        await self.transport.disconnect()
        
        mock_writer.close.assert_called_once()
        mock_writer.wait_closed.assert_called_once()
        assert self.transport.connected is False
    
    @pytest.mark.asyncio
    async def test_context_manager(self):
        """Test async context manager usage"""
        mock_reader = Mock()
        mock_writer = Mock()
        mock_writer.close = Mock()
        mock_writer.wait_closed = AsyncMock()
        
        with patch('asyncio.open_connection', return_value=(mock_reader, mock_writer)):
            async with TL1Transport() as transport:
                assert transport is not None
            
            # Should be disconnected after context
            mock_writer.close.assert_called_once()


class TestTL1Session:
    """Test cases for TL1Session"""
    
    @pytest.mark.asyncio
    async def test_execute_success(self):
        """Test successful command execution"""
        mock_transport = Mock()
        mock_transport.connected = False
        mock_transport.connect = AsyncMock(return_value=True)
        mock_transport.send_command = AsyncMock(return_value=[
            "   SITE01 25-10-08 12:30:45",
            "M  123 COMPLD",
            ";"
        ])
        
        session = TL1Session("localhost", 23)
        session.transport = mock_transport
        
        response, success = await session.execute("RTRV-ALM-ALL:SITE01::123::;")
        
        assert success is True
        assert len(response) == 3
        assert "COMPLD" in response[1]
        assert len(session.session_log) == 1
    
    @pytest.mark.asyncio
    async def test_execute_failure(self):
        """Test command execution failure"""
        mock_transport = Mock()
        mock_transport.connected = False
        mock_transport.connect = AsyncMock(return_value=True)
        mock_transport.send_command = AsyncMock(return_value=[
            "   SITE01 25-10-08 12:30:45",
            "M  123 DENY",
            "IDNV",
            ";"
        ])
        
        session = TL1Session("localhost", 23)
        session.transport = mock_transport
        
        response, success = await session.execute("INVALID-CMD:SITE01::123::;")
        
        assert success is False
        assert len(response) == 4
        assert "DENY" in response[1]
    
    @pytest.mark.asyncio
    async def test_execute_connection_failure(self):
        """Test command execution with connection failure"""
        mock_transport = Mock()
        mock_transport.connected = False
        mock_transport.connect = AsyncMock(return_value=False)
        
        session = TL1Session("localhost", 23)
        session.transport = mock_transport
        
        response, success = await session.execute("RTRV-ALM-ALL:SITE01::123::;")
        
        assert success is False
        assert len(response) == 0
    
    @pytest.mark.asyncio
    async def test_execute_exception(self):
        """Test command execution with exception"""
        mock_transport = Mock()
        mock_transport.connected = False
        mock_transport.connect = AsyncMock(side_effect=Exception("Network error"))
        
        session = TL1Session("localhost", 23)
        session.transport = mock_transport
        
        response, success = await session.execute("RTRV-ALM-ALL:SITE01::123::;")
        
        assert success is False
        assert len(response) == 1
        assert "ERROR: Network error" in response[0]
    
    @pytest.mark.asyncio
    async def test_session_log(self):
        """Test session logging functionality"""
        mock_transport = Mock()
        mock_transport.connected = False
        mock_transport.connect = AsyncMock(return_value=True)
        mock_transport.send_command = AsyncMock(return_value=["M 123 COMPLD", ";"])
        
        session = TL1Session("localhost", 23)
        session.transport = mock_transport
        
        await session.execute("CMD1:SITE01::123::;")
        await session.execute("CMD2:SITE01::124::;")
        
        log = session.get_session_log()
        assert len(log) == 2
        assert log[0][0] == "CMD1:SITE01::123::;"
        assert log[1][0] == "CMD2:SITE01::124::;"


class TestConvenienceFunctions:
    """Test convenience functions"""
    
    @pytest.mark.asyncio
    async def test_send_tl1_command(self):
        """Test send_tl1_command convenience function"""
        with patch('src.webapi.services.transport.TL1Session') as mock_session_class:
            mock_session = Mock()
            mock_session.execute = AsyncMock(return_value=(["COMPLD"], True))
            mock_session_class.return_value.__aenter__.return_value = mock_session
            
            response, success = await send_tl1_command(
                "localhost", 23, "RTRV-ALM-ALL:SITE01::123::;"
            )
            
            assert success is True
            assert response == ["COMPLD"]
            mock_session.execute.assert_called_once_with("RTRV-ALM-ALL:SITE01::123::;")


class MockTL1Device:
    """Mock TL1 device for integration testing"""
    
    def __init__(self, host="localhost", port=23):
        self.host = host
        self.port = port
        self.server = None
        self.responses = {
            "RTRV-ALM-ALL": ["   SITE01 25-10-08 12:30:45", "M  123 COMPLD", ";"],
            "RTRV-INV": ["   SITE01 25-10-08 12:30:45", "M  124 COMPLD", "\"SLOT-1:CARD=OC48\"", ";"],
            "INVALID": ["   SITE01 25-10-08 12:30:45", "M  125 DENY", "IDNV", ";"]
        }
    
    async def handle_client(self, reader, writer):
        """Handle client connections"""
        try:
            while True:
                data = await reader.readline()
                if not data:
                    break
                
                command = data.decode('ascii').strip()
                
                # Determine response based on command
                response_lines = ["   SITE01 25-10-08 12:30:45", "M  999 COMPLD", ";"]
                for cmd_pattern, response in self.responses.items():
                    if cmd_pattern in command:
                        response_lines = response
                        break
                
                # Send response
                for line in response_lines:
                    writer.write((line + "\\n").encode('ascii'))
                    await writer.drain()
                
        except Exception:
            pass
        finally:
            writer.close()
    
    async def start(self):
        """Start the mock server"""
        self.server = await asyncio.start_server(
            self.handle_client, self.host, self.port
        )
    
    async def stop(self):
        """Stop the mock server"""
        if self.server:
            self.server.close()
            await self.server.wait_closed()


@pytest.fixture
async def mock_tl1_device():
    """Fixture for mock TL1 device"""
    device = MockTL1Device(port=12345)  # Use different port to avoid conflicts
    await device.start()
    yield device
    await device.stop()


class TestIntegration:
    """Integration tests with mock TL1 device"""
    
    @pytest.mark.asyncio
    async def test_full_integration(self, mock_tl1_device):
        """Test full integration with mock device"""
        response, success = await send_tl1_command(
            "localhost", 12345, "RTRV-ALM-ALL:SITE01::123::;", timeout=5
        )
        
        assert success is True
        assert len(response) >= 2
        assert any("COMPLD" in line for line in response)