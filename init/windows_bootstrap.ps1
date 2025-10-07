$ErrorActionPreference = "Stop"
$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
$venvPy = Join-Path $ROOT ".venv\Scripts\python.exe"
$sysPy = "python"
try {
  & $sysPy -m venv (Join-Path $ROOT ".venv")
  & $venvPy -m pip install --upgrade pip
  & $venvPy -m pip install jsonschema==4.22.0
  $py = $venvPy
} catch {
  Write-Warning "Venv failed; using system Python."
  $py = $sysPy
}
& $py (Join-Path $ROOT "src\entrypoint.py") --validate
& $py (Join-Path $ROOT "src\entrypoint.py") --catalog tl1 --find RTRV-ATTR-T1
& $py (Join-Path $ROOT "src\entrypoint.py") --catalog tap --find TAP-047
& $py (Join-Path $ROOT "src\entrypoint.py") --catalog dlp --find DLP-203
& $py (Join-Path $ROOT "src\entrypoint.py") --parse (Join-Path $ROOT "tests\vectors\discovery\RTRV-HDR_basic\raw.txt")
Write-Host "[bootstrap] Done."
