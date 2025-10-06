# TL1 Command Builder (Windows WPF PowerShell)
Linux: run the one-shot paste-to-terminal bootstrap (this script). Then:
  cd ~/1603_assistant && git add . && git commit -m "Add TL1 GUI package" && git push
Windows: pull repo; double-click Start-TL1.cmd to launch the GUI.
Logs: ./logs/ ; Settings: powershell/appsettings.json ; SecureCRT send = stub (logs only).

## Windows GUI (TL1 Command Builder)
1. Clone or pull this repo on Windows (path like `C:\...\1603_assistant`).
2. Double-click **Start-TL1.cmd**.
3. In the GUI: enter **Host/IP** and **Port** → **Connect** → build TL1 → **Send**.
   - Logs: `.\\logs\\`
   - Settings: `.\\powershell\\appsettings.json`
   - Works on Windows PowerShell 5.1 and PowerShell 7 (STA enforced by launcher).
