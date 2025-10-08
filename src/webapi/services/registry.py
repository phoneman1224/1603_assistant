"""
Path registry and helper utilities
Centralized path management for data files and logs
"""
from pathlib import Path
from datetime import datetime


class PathRegistry:
    """Centralized path management"""
    
    def __init__(self, root_path: Path = None):
        if root_path is None:
            # Default to repository root (3 levels up from this file)
            root_path = Path(__file__).parent.parent.parent.parent
        
        self.root = root_path.resolve()
        self.data = self.root / "data"
        self.logs = self.root / "logs"
        self.powershell = self.root / "powershell"
        
        # Ensure directories exist
        self.data.mkdir(parents=True, exist_ok=True)
        self.logs.mkdir(parents=True, exist_ok=True)
        self.powershell.mkdir(parents=True, exist_ok=True)
    
    @property
    def commands_json(self) -> Path:
        """Path to commands.json"""
        return self.data / "commands.json"
    
    @property
    def playbooks_json(self) -> Path:
        """Path to playbooks.json"""
        return self.data / "playbooks.json"
    
    @property
    def settings_json(self) -> Path:
        """Path to settings.json"""
        return self.root / "settings.json"
    
    @property
    def send_tl1_script(self) -> Path:
        """Path to PowerShell send_tl1.ps1"""
        return self.powershell / "send_tl1.ps1"
    
    def get_log_file(self, date: datetime = None) -> Path:
        """
        Get log file path for a specific date
        Creates monthly subdirectory structure
        """
        if date is None:
            date = datetime.now()
        
        monthly_dir = self.logs / date.strftime("%Y-%m")
        monthly_dir.mkdir(parents=True, exist_ok=True)
        
        return monthly_dir / f"tl1_{date.strftime('%Y-%m-%d')}.log"


# Global instance
registry = PathRegistry()
