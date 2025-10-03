param(
    [Parameter(Mandatory=$true)][string]$CommandText,
    [string]$SecureCRTPath = "",
    [switch]$DryRun
)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir
$LogsDir   = Join-Path $RootDir "logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }
$LogFile   = Join-Path $LogsDir ("send-{0}.log" -f (Get-Date -Format "yyyyMMdd"))
$line = "[{0}] SEND {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $CommandText
Add-Content -Path $LogFile -Value $line
if ($DryRun) { Write-Output "DryRun: $CommandText"; exit 0 }
if ($SecureCRTPath -and (Test-Path $SecureCRTPath)) {
    Write-Output "SecureCRT configured at: $SecureCRTPath (sending stub)"
} else {
    Write-Output "No SecureCRT path configured. Command logged only."
}
