"""
TL1 Transport Service
Handles low-level TL1 communication via sockets
"""
import asyncio
from datetime import datetime
from typing import List, Tuple, Optional

from ..logging_conf import get_logger


logger = get_logger(__name__)


class TL1Transport:
    """TL1 transport layer for socket communication"""
    
    def __init__(self, timeout: int = 30):
        self.timeout = timeout
        self.reader: Optional[asyncio.StreamReader] = None
        self.writer: Optional[asyncio.StreamWriter] = None
        self.connected = False
    
    async def connect(self, host: str, port: int) -> bool:
        """
        Connect to TL1 device
        
        Returns:
            bool: True if connected successfully
        """
        try:
            logger.info(f"Connecting to {host}:{port}")
            
            self.reader, self.writer = await asyncio.wait_for(
                asyncio.open_connection(host, port),
                timeout=self.timeout
            )
            
            self.connected = True
            logger.info(f"Connected to {host}:{port}")
            return True
            
        except asyncio.TimeoutError:
            logger.error(f"Connection timeout to {host}:{port}")
            return False
        except ConnectionRefusedError:
            logger.error(f"Connection refused by {host}:{port}")
            return False
        except Exception as e:
            logger.error(f"Connection failed to {host}:{port}: {e}")
            return False
    
    async def send_command(self, command: str) -> List[str]:
        """
        Send TL1 command and receive response
        
        Args:
            command: TL1 command string
            
        Returns:
            List of response lines
        """
        if not self.connected or not self.writer:
            raise RuntimeError("Not connected to TL1 device")
        
        try:
            # Send command
            command_bytes = (command + "\\n").encode('ascii')
            self.writer.write(command_bytes)
            await self.writer.drain()
            
            logger.info(f"Sent: {command}")
            
            # Read response
            response_lines = []
            start_time = datetime.now()
            
            while True:
                try:
                    # Read with shorter timeout for individual lines
                    line = await asyncio.wait_for(self.reader.readline(), timeout=5.0)
                    
                    if not line:
                        logger.warning("Connection closed by remote host")
                        break
                    
                    line_str = line.decode('ascii', errors='ignore').strip()
                    if line_str:
                        response_lines.append(line_str)
                        logger.debug(f"Received: {line_str}")
                        
                        # Check for TL1 completion indicators
                        if any(indicator in line_str for indicator in [';', 'COMPLD', 'DENY', 'PRTL']):
                            logger.info("TL1 response complete")
                            break
                    
                    # Check overall timeout
                    elapsed = (datetime.now() - start_time).seconds
                    if elapsed > self.timeout:
                        logger.warning(f"Response timeout after {elapsed}s")
                        break
                        
                except asyncio.TimeoutError:
                    logger.info("No more response data")
                    break
            
            logger.info(f"Received {len(response_lines)} response lines")
            return response_lines
            
        except Exception as e:
            logger.error(f"Send/receive failed: {e}")
            raise
    
    async def disconnect(self):
        """Close connection"""
        if self.writer and self.connected:
            try:
                self.writer.close()
                await self.writer.wait_closed()
                logger.info("Disconnected from TL1 device")
            except Exception as e:
                logger.warning(f"Error during disconnect: {e}")
            finally:
                self.connected = False
                self.reader = None
                self.writer = None
    
    async def __aenter__(self):
        """Async context manager entry"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self.disconnect()


class TL1Session:
    """Higher-level TL1 session management"""
    
    def __init__(self, host: str, port: int, timeout: int = 30):
        self.host = host
        self.port = port
        self.timeout = timeout
        self.transport = TL1Transport(timeout)
        self.session_log: List[Tuple[str, str, datetime]] = []
    
    async def execute(self, command: str) -> Tuple[List[str], bool]:
        """
        Execute TL1 command and return response
        
        Args:
            command: TL1 command string
            
        Returns:
            Tuple of (response_lines, success)
        """
        timestamp = datetime.now()
        
        try:
            # Connect if not already connected
            if not self.transport.connected:
                if not await self.transport.connect(self.host, self.port):
                    return [], False
            
            # Send command and get response
            response_lines = await self.transport.send_command(command)
            
            # Log the interaction
            response_text = "\\n".join(response_lines)
            self.session_log.append((command, response_text, timestamp))
            
            # Determine success based on TL1 response
            success = any(
                'COMPLD' in line or 'PRTL' in line 
                for line in response_lines
            )
            
            return response_lines, success
            
        except Exception as e:
            error_msg = f"ERROR: {str(e)}"
            self.session_log.append((command, error_msg, timestamp))
            logger.error(f"Command execution failed: {e}")
            return [error_msg], False
    
    async def close(self):
        """Close the session"""
        await self.transport.disconnect()
    
    def get_session_log(self) -> List[Tuple[str, str, datetime]]:
        """Get complete session log"""
        return self.session_log.copy()
    
    async def __aenter__(self):
        """Async context manager entry"""
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit"""
        await self.close()


# Convenience functions
async def send_tl1_command(host: str, port: int, command: str, timeout: int = 30) -> Tuple[List[str], bool]:
    """
    Send a single TL1 command (convenience function)
    
    Args:
        host: Target host
        port: Target port
        command: TL1 command string
        timeout: Connection timeout in seconds
        
    Returns:
        Tuple of (response_lines, success)
    """
    async with TL1Session(host, port, timeout) as session:
        return await session.execute(command)


# Global transport instance for reuse
transport = TL1Transport()