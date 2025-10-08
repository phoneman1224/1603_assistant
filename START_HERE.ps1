# windows_bootstrap.ps1 - Complete setup and launch for Windows

param(
    [switch]$SkipValidation = $false,
    [switch]$Production = $false,
    [switch]$LaunchDesktop = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "TL1 Assistant - Windows Bootstrap" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory and root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = $scriptPath  # Script is now in root directory

Write-Host "[INFO] Script directory: $scriptPath" -ForegroundColor Green
Write-Host "[INFO] Root directory: $rootPath" -ForegroundColor Green
Write-Host ""

# Change to root directory to ensure we're in the right place
Set-Location $rootPath
Write-Host "[INFO] Working directory set to: $(Get-Location)" -ForegroundColor Green

# Verify we're in the correct directory by checking for key files
$keyFiles = @("requirements.txt", "data\commands.json", "webui\package.json")
$missingFiles = @()

foreach ($file in $keyFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "[ERROR] Not in correct directory! Missing files:" -ForegroundColor Red
    foreach ($missing in $missingFiles) {
        Write-Host "  - $missing" -ForegroundColor Red
    }
    Write-Host "[ERROR] Please ensure you're running this script from the 1603_assistant directory." -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Directory validation passed" -ForegroundColor Green
Write-Host ""

# Step 1: Check Python
Write-Host "[1/6] Checking Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found. Please install Python 3.8 or higher." -ForegroundColor Red
    exit 1
}

# Step 2: Create/activate virtual environment
Write-Host ""
Write-Host "[2/6] Setting up Python virtual environment..." -ForegroundColor Yellow
Push-Location $rootPath
$venvPath = Join-Path $rootPath ".venv"

if (-not (Test-Path $venvPath)) {
    Write-Host "[INFO] Creating virtual environment..." -ForegroundColor Yellow
    python -m venv .venv
    Write-Host "[OK] Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "[INFO] Virtual environment already exists" -ForegroundColor Gray
}

# Activate venv
$activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
if (Test-Path $activateScript) {
    Write-Host "[INFO] Activating virtual environment..." -ForegroundColor Yellow
    & $activateScript
    Write-Host "[OK] Virtual environment activated" -ForegroundColor Green
} else {
    Write-Host "[WARN] Could not activate virtual environment" -ForegroundColor Yellow
}

# Step 3: Install Python dependencies
Write-Host ""
Write-Host "[3/6] Installing Python dependencies..." -ForegroundColor Yellow
try {
    python -m pip install --upgrade pip -q
    python -m pip install -r requirements.txt -q
    Write-Host "[OK] Python dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to install Python dependencies" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Step 4: Validate data files (optional)
if (-not $SkipValidation) {
    Write-Host ""
    Write-Host "[4/6] Validating data files..." -ForegroundColor Yellow
    
    $commandsFile = Join-Path $rootPath "data\commands.json"
    $playbooksFile = Join-Path $rootPath "data\playbooks.json"
    $settingsFile = Join-Path $rootPath "settings.json"
    
    $validationOk = $true
    
    if (Test-Path $commandsFile) {
        Write-Host "[OK] commands.json found" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] commands.json not found" -ForegroundColor Red
        $validationOk = $false
    }
    
    if (Test-Path $playbooksFile) {
        Write-Host "[OK] playbooks.json found" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] playbooks.json not found" -ForegroundColor Red
        $validationOk = $false
    }
    
    if (Test-Path $settingsFile) {
        Write-Host "[OK] settings.json found" -ForegroundColor Green
    } else {
        Write-Host "[WARN] settings.json not found (will use defaults)" -ForegroundColor Yellow
    }
    
    if (-not $validationOk) {
        Write-Host "[ERROR] Data validation failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "[4/6] Skipping data validation" -ForegroundColor Gray
}

# Step 5: Check Node.js and install UI dependencies
Write-Host ""
Write-Host "[5/6] Checking Node.js and UI dependencies..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    Write-Host "[OK] Node.js found: $nodeVersion" -ForegroundColor Green
    
    $webuiPath = Join-Path $rootPath "webui"
    if (Test-Path $webuiPath) {
        Push-Location $webuiPath
        if (-not (Test-Path "node_modules")) {
            Write-Host "[INFO] Installing Node dependencies..." -ForegroundColor Yellow
            npm install
            Write-Host "[OK] Node dependencies installed" -ForegroundColor Green
        } else {
            Write-Host "[INFO] Node dependencies already installed" -ForegroundColor Gray
        }
        Pop-Location
    }
} catch {
    Write-Host "[WARN] Node.js not found. Web UI will not be available." -ForegroundColor Yellow
    Write-Host "[INFO] Install Node.js 18+ to enable Web UI" -ForegroundColor Yellow
}

# Step 6: Launch desktop or web
Write-Host ""
Write-Host "[6/6] Launching application..." -ForegroundColor Yellow
Write-Host ""

if ($LaunchDesktop) {
    Write-Host "[INFO] Launching Desktop GUI..." -ForegroundColor Cyan
    $desktopScript = Join-Path $rootPath "powershell\TL1_CommandBuilder.ps1"
    if (Test-Path $desktopScript) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $desktopScript
    } else {
        Write-Host "[ERROR] Desktop GUI script not found: $desktopScript" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[INFO] Launching Web GUI..." -ForegroundColor Cyan
    $serveScript = Join-Path $rootPath "scripts\serve_web.ps1"
    if (Test-Path $serveScript) {
        if ($Production) {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $serveScript -Production
        } else {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $serveScript
        }
    } else {
        Write-Host "[ERROR] Web serve script not found: $serveScript" -ForegroundColor Red
        exit 1
    }
}
