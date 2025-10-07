# TL1 Assistant Launcher
# This script launches the TL1 Command Builder GUI
# Ensures proper PowerShell version and handles common issues

param(
    [switch]$Debug,
    [switch]$Verbose
)

# Set error handling
$ErrorActionPreference = 'Continue'
if ($Debug) { $DebugPreference = 'Continue' }
if ($Verbose) { $VerbosePreference = 'Continue' }

Write-Host "🚀 TL1 Assistant Launcher" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PowerShellDir = Join-Path $RootDir "powershell"
$MainScript = Join-Path $PowerShellDir "TL1_CommandBuilder.ps1"

Write-Host "📁 Root Directory: $RootDir" -ForegroundColor Green
Write-Host "📁 PowerShell Dir: $PowerShellDir" -ForegroundColor Green
Write-Host "📄 Main Script: $MainScript" -ForegroundColor Green
Write-Host ""

# Check if main script exists
if (-not (Test-Path $MainScript)) {
    Write-Host "❌ ERROR: TL1_CommandBuilder.ps1 not found!" -ForegroundColor Red
    Write-Host "   Expected location: $MainScript" -ForegroundColor Red
    Write-Host ""
    Write-Host "📁 Available files in powershell directory:" -ForegroundColor Yellow
    if (Test-Path $PowerShellDir) {
        Get-ChildItem $PowerShellDir -File | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Yellow }
    } else {
        Write-Host "   ❌ PowerShell directory not found!" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Check PowerShell version
Write-Host "🔍 Checking PowerShell environment..." -ForegroundColor Yellow
Write-Host "   PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "   Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray
Write-Host "   OS: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Gray

if ($PSVersionTable.PSVersion.Major -gt 5) {
    Write-Host ""
    Write-Host "⚠️  WARNING: PowerShell Core detected!" -ForegroundColor Yellow
    Write-Host "   This application requires Windows PowerShell 5.1" -ForegroundColor Yellow
    Write-Host "   Please run using Windows PowerShell (blue icon)" -ForegroundColor Yellow
    Write-Host "   Instead of PowerShell Core (black icon)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🔄 Attempting to launch with Windows PowerShell..." -ForegroundColor Cyan
    
    $winPS = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path $winPS) {
        $args = @(
            '-NoProfile'
            '-ExecutionPolicy', 'Bypass'
            '-File', "`"$MainScript`""
        )
        if ($Debug) { $args += '-Debug' }
        if ($Verbose) { $args += '-Verbose' }
        
        Write-Host "   Launching: $winPS" -ForegroundColor Gray
        Start-Process -FilePath $winPS -ArgumentList $args -WorkingDirectory $PowerShellDir
        return
    } else {
        Write-Host "❌ Windows PowerShell not found at: $winPS" -ForegroundColor Red
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

Write-Host "✅ PowerShell environment OK" -ForegroundColor Green
Write-Host ""

# Check execution policy
$execPolicy = Get-ExecutionPolicy
Write-Host "🔒 Execution Policy: $execPolicy" -ForegroundColor Gray

if ($execPolicy -eq 'Restricted') {
    Write-Host "⚠️  WARNING: Execution policy is Restricted" -ForegroundColor Yellow
    Write-Host "   This may prevent the script from running" -ForegroundColor Yellow
    Write-Host "   You may need to run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
    Write-Host ""
}

# Launch the main script
Write-Host "🚀 Launching TL1 Command Builder..." -ForegroundColor Cyan
Write-Host ""

try {
    # Change to PowerShell directory for proper relative paths
    Push-Location $PowerShellDir
    
    # Execute the main script
    & $MainScript
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR launching TL1 Command Builder:" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Debug Information:" -ForegroundColor Yellow
    Write-Host "   Script Path: $MainScript" -ForegroundColor Gray
    Write-Host "   Working Directory: $PowerShellDir" -ForegroundColor Gray
    Write-Host "   Error Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 Common Solutions:" -ForegroundColor Cyan
    Write-Host "   1. Ensure you are using Windows PowerShell (not PowerShell Core)" -ForegroundColor Gray
    Write-Host "   2. Run as Administrator if needed" -ForegroundColor Gray
    Write-Host "   3. Check that .NET Framework 4.5+ is installed" -ForegroundColor Gray
    Write-Host "   4. Verify Windows Desktop features are enabled" -ForegroundColor Gray
    Write-Host ""
    Write-Host "📋 Full Error Details:" -ForegroundColor Yellow
    Write-Host $_.Exception.ToString() -ForegroundColor Gray
    
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")