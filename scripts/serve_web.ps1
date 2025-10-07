# serve_web.ps1 - Run FastAPI + Vite concurrently

param(
    [switch]$Production = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "TL1 Assistant - Hybrid Web GUI Launcher" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory and root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath

Write-Host "[INFO] Root directory: $rootPath" -ForegroundColor Green

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    Write-Host "[OK] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Python not found. Please install Python 3.8 or higher." -ForegroundColor Red
    exit 1
}

# Check if Node.js is available
try {
    $nodeVersion = node --version 2>&1
    Write-Host "[OK] Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Node.js not found. Please install Node.js 18 or higher." -ForegroundColor Red
    exit 1
}

# Install Python dependencies if needed
Write-Host ""
Write-Host "[1/4] Installing Python dependencies..." -ForegroundColor Yellow
Push-Location $rootPath
try {
    python -m pip install -q -r requirements.txt
    Write-Host "[OK] Python dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to install Python dependencies" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Install Node dependencies if needed
Write-Host ""
Write-Host "[2/4] Installing Node dependencies..." -ForegroundColor Yellow
$webuiPath = Join-Path $rootPath "webui"
Push-Location $webuiPath
try {
    if (-not (Test-Path "node_modules")) {
        npm install
    }
    Write-Host "[OK] Node dependencies installed" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to install Node dependencies" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Start FastAPI backend
Write-Host ""
Write-Host "[3/4] Starting FastAPI backend on http://127.0.0.1:8000..." -ForegroundColor Yellow
$apiJob = Start-Job -ScriptBlock {
    param($rootPath)
    Set-Location $rootPath
    python -m uvicorn src.webapi.app:app --host 127.0.0.1 --port 8000
} -ArgumentList $rootPath

Write-Host "[OK] FastAPI backend started (Job ID: $($apiJob.Id))" -ForegroundColor Green

# Wait for API to be ready
Write-Host "[INFO] Waiting for API to be ready..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$apiReady = $false

while (-not $apiReady -and $attempt -lt $maxAttempts) {
    Start-Sleep -Seconds 1
    try {
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/health" -TimeoutSec 2 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $apiReady = $true
        }
    } catch {
        # Still waiting
    }
    $attempt++
}

if (-not $apiReady) {
    Write-Host "[ERROR] API did not start within timeout" -ForegroundColor Red
    Stop-Job $apiJob
    Remove-Job $apiJob
    exit 1
}

Write-Host "[OK] API is ready!" -ForegroundColor Green

# Start Vite dev server or serve production build
Write-Host ""
if ($Production) {
    Write-Host "[4/4] Building production UI..." -ForegroundColor Yellow
    Push-Location $webuiPath
    try {
        npm run build
        Write-Host "[OK] Production build complete" -ForegroundColor Green
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host "TL1 Assistant is running!" -ForegroundColor Green
        Write-Host "API: http://127.0.0.1:8000/api/" -ForegroundColor Cyan
        Write-Host "UI: http://127.0.0.1:8000/" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "The UI is served from the API server." -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Yellow
    } catch {
        Write-Host "[ERROR] Build failed" -ForegroundColor Red
        Stop-Job $apiJob
        Remove-Job $apiJob
        Pop-Location
        exit 1
    }
    Pop-Location
    
    # Wait for user to stop
    try {
        Wait-Job $apiJob
    } finally {
        Stop-Job $apiJob
        Remove-Job $apiJob
    }
    
} else {
    Write-Host "[4/4] Starting Vite dev server on http://127.0.0.1:5173..." -ForegroundColor Yellow
    $viteJob = Start-Job -ScriptBlock {
        param($webuiPath)
        Set-Location $webuiPath
        npm run dev
    } -ArgumentList $webuiPath
    
    Write-Host "[OK] Vite dev server started (Job ID: $($viteJob.Id))" -ForegroundColor Green
    
    Start-Sleep -Seconds 3
    
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "TL1 Assistant is running!" -ForegroundColor Green
    Write-Host "API: http://127.0.0.1:8000/api/" -ForegroundColor Cyan
    Write-Host "UI: http://127.0.0.1:5173/" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press Ctrl+C to stop both servers." -ForegroundColor Yellow
    Write-Host ""
    
    # Open browser
    Start-Process "http://127.0.0.1:5173"
    
    # Wait for user to stop
    try {
        while ($true) {
            Start-Sleep -Seconds 1
            
            # Check if jobs are still running
            if ($apiJob.State -ne 'Running') {
                Write-Host "[WARN] API server stopped unexpectedly" -ForegroundColor Yellow
                break
            }
            if ($viteJob.State -ne 'Running') {
                Write-Host "[WARN] Vite server stopped unexpectedly" -ForegroundColor Yellow
                break
            }
        }
    } finally {
        Write-Host ""
        Write-Host "[INFO] Shutting down..." -ForegroundColor Yellow
        Stop-Job $apiJob -ErrorAction SilentlyContinue
        Stop-Job $viteJob -ErrorAction SilentlyContinue
        Remove-Job $apiJob -ErrorAction SilentlyContinue
        Remove-Job $viteJob -ErrorAction SilentlyContinue
        Write-Host "[OK] Servers stopped" -ForegroundColor Green
    }
}
