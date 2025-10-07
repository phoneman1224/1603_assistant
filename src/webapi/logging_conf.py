"""
Structured logging configuration with daily rotation
Format: [$LEVEL] yyyy-MM-dd HH:mm:ss.fff message
"""
import logging
import sys
from pathlib import Path
from datetime import datetime
from logging.handlers import TimedRotatingFileHandler


class StructuredFormatter(logging.Formatter):
    """Custom formatter for structured logs"""
    
    LEVEL_MAP = {
        'DEBUG': 'DEBUG',
        'INFO': 'INFO',
        'WARNING': 'WARN',
        'ERROR': 'ERROR',
        'CRITICAL': 'ERROR'
    }
    
    def format(self, record):
        # Map Python log levels to our format
        level = self.LEVEL_MAP.get(record.levelname, 'INFO')
        
        # Special handling for TL1-specific log levels
        if hasattr(record, 'tl1_level'):
            level = record.tl1_level
        
        timestamp = datetime.fromtimestamp(record.created).strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
        message = record.getMessage()
        
        return f"[{level}] {timestamp} {message}"


def setup_logging(log_root: str = "./logs", debug_mode: bool = False):
    """
    Setup structured logging with daily rotation
    
    Args:
        log_root: Root directory for log files
        debug_mode: Enable debug level logging
    """
    log_path = Path(log_root)
    log_path.mkdir(parents=True, exist_ok=True)
    
    # Create monthly subdirectory
    now = datetime.now()
    monthly_dir = log_path / now.strftime("%Y-%m")
    monthly_dir.mkdir(parents=True, exist_ok=True)
    
    # Log file name with date
    log_file = monthly_dir / f"tl1_{now.strftime('%Y-%m-%d')}.log"
    
    # Create handlers
    file_handler = TimedRotatingFileHandler(
        filename=log_file,
        when='midnight',
        interval=1,
        backupCount=90,  # Keep 90 days
        encoding='utf-8'
    )
    
    console_handler = logging.StreamHandler(sys.stdout)
    
    # Set formatter
    formatter = StructuredFormatter()
    file_handler.setFormatter(formatter)
    console_handler.setFormatter(formatter)
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.DEBUG if debug_mode else logging.INFO)
    root_logger.addHandler(file_handler)
    root_logger.addHandler(console_handler)
    
    return root_logger


def get_logger(name: str):
    """Get a logger instance"""
    return logging.getLogger(name)


def log_tl1(level: str, message: str):
    """
    Log with TL1-specific levels
    Levels: SEND, RECV, TROUBLESHOOT, SUMMARY
    """
    logger = get_logger('tl1')
    record = logger.makeRecord(
        name='tl1',
        level=logging.INFO,
        fn='',
        lno=0,
        msg=message,
        args=(),
        exc_info=None
    )
    record.tl1_level = level
    logger.handle(record)
