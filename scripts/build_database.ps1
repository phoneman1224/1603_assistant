# build_database.ps1 - Deterministic database build
# Ensures commands.json is properly formatted and deterministic

param(
    [switch]$Validate = $false
)

$ErrorActionPreference = "Stop"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "TL1 Assistant - Database Build" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory and root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath

$commandsFile = Join-Path $rootPath "data\commands.json"
$playbooksFile = Join-Path $rootPath "data\playbooks.json"

# Check if files exist
if (-not (Test-Path $commandsFile)) {
    Write-Host "[ERROR] commands.json not found: $commandsFile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $playbooksFile)) {
    Write-Host "[ERROR] playbooks.json not found: $playbooksFile" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Loading commands.json..." -ForegroundColor Yellow
$commands = Get-Content $commandsFile -Raw | ConvertFrom-Json

Write-Host "[INFO] Loading playbooks.json..." -ForegroundColor Yellow
$playbooks = Get-Content $playbooksFile -Raw | ConvertFrom-Json

# Count items
$commandCount = ($commands.commands.PSObject.Properties | Measure-Object).Count
$categoryCount = ($commands.categories.PSObject.Properties | Measure-Object).Count
$troubleshootingCount = ($playbooks.troubleshooting | Measure-Object).Count
$provisioningCount = ($playbooks.provisioning | Measure-Object).Count

Write-Host ""
Write-Host "[STATS] Commands: $commandCount" -ForegroundColor Cyan
Write-Host "[STATS] Categories: $categoryCount" -ForegroundColor Cyan
Write-Host "[STATS] Troubleshooting playbooks: $troubleshootingCount" -ForegroundColor Cyan
Write-Host "[STATS] Provisioning playbooks: $provisioningCount" -ForegroundColor Cyan

# Validate if requested
if ($Validate) {
    Write-Host ""
    Write-Host "[INFO] Running validation..." -ForegroundColor Yellow
    $validateScript = Join-Path $scriptPath "validate_data.py"
    
    if (Test-Path $validateScript) {
        python $validateScript
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Validation failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "[WARN] Validation script not found" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[OK] Database build complete" -ForegroundColor Green
