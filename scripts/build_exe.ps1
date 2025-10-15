Param(
    [string]$Python = "python",
    [string]$Spec = "tl1_assistant.spec"
)

if (-not (Test-Path $Spec)) {
    Write-Host "Generating PyInstaller spec file..."
    & $Python -m PyInstaller --name TL1Assistant --onefile --noconfirm --icon app.ico ui/app.py
} else {
    Write-Host "Using existing spec file $Spec"
    & $Python -m PyInstaller $Spec
}
