# TL1 Assistant - Quick Start Guide

Get up and running with the TL1 Assistant in under 2 minutes!

## 🚀 One-Click Start

### Windows
1. Double-click `Start-WebGUI.cmd`
2. Web browser opens automatically
3. Start managing your TL1 devices!

### Linux/Mac
1. Open terminal in project directory
2. Run: `./start-webgui.sh`
3. Web browser opens automatically at http://localhost:8080

### Manual Start
```bash
python3 tl1_web_gui.py
```

## 📋 What You Get

✅ **630 TL1 Commands** - Pre-loaded and ready to use  
✅ **Zero Installation** - No admin rights or software installation needed  
✅ **Cross-Platform** - Works on Windows, Linux, and Mac  
✅ **Direct Telnet** - Connect directly to your network elements  
✅ **Smart Command Builder** - Parameter validation and syntax help  

## 🎯 Basic Usage

### 1. Connect to Device
- Enter device IP address
- Set port (default: 23)
- Click "Connect"

### 2. Select Platform
- Choose "1603 SM" (561 commands)
- Or "1603 SMX" (609 commands)

### 3. Build Commands
- Browse command categories
- Click on any command
- Fill in the parameter form
- See real-time command preview

### 4. Execute Commands
- Review the built command
- Click "Send Command"
- View device response

## 🔧 First Commands to Try

### Login
```
ACT-USER:MYSITE:ADMIN:1::PASSWORD;
```

### Get System Info
```
RTRV-HDR:MYSITE::2::;
```

### Check Alarms
```
RTRV-ALM-ALL:MYSITE::3::;
```

### Logout
```
CANC-USER:MYSITE:ADMIN:4::;
```

## ⚠️ Important Notes

### Command Safety
- **Green** commands are safe to run
- **Yellow** commands may affect services
- **Red** commands can impact system operation

### Parameter Guidelines
- **TID**: Your network element ID (required)
- **AID**: Specific port/resource (often optional)
- **CTAG**: Command sequence number (required)

### Common Patterns
- Always start with login (`ACT-USER`)
- Use retrieve commands (`RTRV-*`) for monitoring
- Be careful with provisioning commands (`ENT-*`, `DLT-*`)
- End sessions with logout (`CANC-USER`)

## 🆘 Quick Troubleshooting

### Connection Issues
❌ **"Connection failed"**  
✅ Check IP address and port  
✅ Verify network connectivity  
✅ Confirm device supports Telnet  

### Command Errors
❌ **"DENY" response**  
✅ Check command syntax  
✅ Verify user permissions  
✅ Ensure correct platform selection  

### Web Interface Issues
❌ **Browser won't open**  
✅ Manually go to http://localhost:8080  
✅ Check if port 8080 is available  
✅ Try different browser  

## 📚 Need More Help?

- **Full Documentation**: See `README.md`
- **Command Reference**: Check `tl1_syntax.md`
- **Troubleshooting**: Review `tap-001.md`
- **Examples**: Browse `command_examples.json`

## 🎉 You're Ready!

The TL1 Assistant provides everything you need for professional network element management. Start with basic retrieve commands and gradually explore more advanced functionality as you become comfortable with the interface.

**Happy TL1 commanding!** 🚀