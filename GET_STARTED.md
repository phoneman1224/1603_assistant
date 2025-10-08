# 🚀 TL1 Assistant - Quick Start

## One-Click Start

### Windows
Double-click: **`START.bat`**

### Linux/Mac
Run: **`./start.sh`**

---

## What This Does

This is a **TL1 Command Management System** for Alcatel 1603 SM/SMX network equipment.

- **630+ TL1 Commands** - Complete command database
- **Modern Web Interface** - Easy-to-use browser GUI  
- **Direct Network Connection** - No SecureCRT needed
- **PowerShell Integration** - Windows telnet support

---

## After Launch

1. **Web Interface** opens at: http://localhost:8000
2. Enter your device **IP address and port**  
3. Choose your platform (**1603 SM** or **SMX**)
4. Start building and sending TL1 commands!

---

## Need Help?

- **Full Documentation**: [README.md](README.md)
- **Setup Guide**: [docs/setup/STARTUP_GUIDE.md](docs/setup/STARTUP_GUIDE.md)
- **TL1 Reference**: [docs/tl1_syntax.md](docs/tl1_syntax.md)

---

## Troubleshooting

**Web GUI doesn't connect?**
- Check that your TL1 device IP/port is correct
- Ensure firewall allows connections
- Try telnet manually first: `telnet <ip> <port>`

**Desktop GUI doesn't start?**
- Use the web interface instead (better experience)
- Or run: `python scripts/tl1_web_gui.py`