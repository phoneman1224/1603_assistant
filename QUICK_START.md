# QUICK START GUIDE - Getting Copilot to Build Your GUI

## Step 1: Add Files to Your Repository

Copy these files into your GitHub repository in this structure:

```
1603_assistant/
├── data/
│   └── platforms/
│       └── alcatel_1603/
│           ├── DIRECTORY_STRUCTURE.md      ← Add this
│           ├── tl1_syntax.md               ← Add this
│           ├── commands/
│           │   └── command_examples.json   ← Add this
│           └── tap_procedures/
│               └── TAP-001.md              ← Add this
```

### Files I Created for You:

1. **tl1_syntax.md** - Complete TL1 command syntax reference
2. **command_examples.json** - Command database with examples
3. **TAP-001.md** - Sample troubleshooting procedure
4. **DIRECTORY_STRUCTURE.md** - File organization guide
5. **COPILOT_PROMPT.txt** - Complete prompt for Copilot

## Step 2: Commit Files to GitHub

```bash
# In your local repo
git add data/platforms/alcatel_1603/
git commit -m "Add documentation for 1603 Assistant"
git push origin main
```

## Step 3: Open GitHub Copilot Chat

In your IDE (VS Code, etc.) with GitHub Copilot:

1. Open the GitHub Copilot Chat panel
2. Make sure you're in the 1603_assistant repository
3. Copy the entire contents of **COPILOT_PROMPT.txt**
4. Paste it into Copilot Chat
5. Hit Enter

## Step 4: Review What Copilot Creates

Copilot should create:
- `src/gui/main_window.py` - Main application
- `src/gui/tl1_builder.py` - Command builder
- `src/gui/ai_assistant.py` - AI assistant
- `src/telnet/connection.py` - Telnet connection
- `launch.py` - Application launcher
- `requirements.txt` - Dependencies

## Step 5: Test the Application

```bash
# Install dependencies
pip install -r requirements.txt

# Launch the application
python launch.py
```

## What the Application Should Do

### Connection Panel
- Enter host and port
- Click "Connect" to establish telnet connection
- Status indicator shows connection state

### Command Builder
- Select VERB, MODIFIER, OBJECT from dropdowns
- Fill in TID, AID, CTAG as needed
- **VACANT FIELDS STAY EMPTY** (no placeholder text!)
- Preview command before sending
- Send to equipment

### Response Display
- Shows all TL1 responses
- Displays autonomous alarms
- Scrollable history
- Save to file option

### AI Assistant
- Type natural language queries
- Get matched TAP/DLP procedures
- Receive suggested commands
- See step-by-step instructions

## Critical Success Criteria

✅ **The command builder MUST handle vacant parameters correctly:**
- Empty TID = `:::` (not `:TID::`)
- Empty AID = `:::` (not `::AID:`)
- No "null", "empty", or placeholder text

Example correct commands:
```
RTRV-ALM-ALL:::123::;              ← TID and AID vacant
RTRV-ALM-ALL:SITE01::456::;        ← Only AID vacant
```

## Troubleshooting

### If Copilot Doesn't Reference Your Files:
Tell it explicitly:
```
Please read the file data/platforms/alcatel_1603/tl1_syntax.md 
and follow the vacant parameter rules described there.
```

### If Command Builder Uses Placeholders:
Tell Copilot:
```
CRITICAL FIX NEEDED: The command builder is putting placeholder text 
in vacant parameters. Read tl1_syntax.md section "CRITICAL: Vacant 
Parameter Rules" and fix the build_command() method to leave vacant 
parameters completely empty (just colons, no text).
```

### If AI Assistant Doesn't Load TAPs:
Tell Copilot:
```
The AI assistant needs to read TAP-001.md from 
data/platforms/alcatel_1603/tap_procedures/ and display 
the content when users mention alarms.
```

## Next Steps After GUI is Built

1. **Add More TAP Procedures**
   - Download from your Google Drive
   - Add to `data/platforms/alcatel_1603/tap_procedures/`
   - Format as markdown

2. **Add DLP Procedures**
   - Create `dlp_procedures/` folder
   - Add operational procedures
   - Reference in AI assistant

3. **Enhance Command Database**
   - Add more commands to `command_examples.json`
   - Include more examples
   - Add command categories

4. **Test with Real Equipment**
   - Connect to actual 1603 equipment
   - Verify command syntax
   - Test alarm handling

## Getting Help

If something doesn't work:

1. **Check the documentation files are in the repo**
2. **Verify Copilot has access to read them**
3. **Be explicit about what needs to be fixed**
4. **Reference the specific file and section** with the rules

## Example Copilot Follow-up Prompts

If you need to refine what Copilot builds:

```
Add syntax highlighting to the response display area. 
Use different colors for COMPLD vs DENY responses.
```

```
Add a command history feature that saves the last 20 commands 
and lets users recall them with up/down arrow keys.
```

```
Improve the AI assistant to suggest multiple TAP procedures 
when there are multiple matching keywords in the user's query.
```

```
Add connection profile saving so users can save multiple 
equipment connections (host, port, name) and switch between them.
```

## Success! 🎉

When you can:
- Connect via telnet ✓
- Build TL1 commands with proper vacant parameters ✓  
- Send commands and see responses ✓
- Get AI help with troubleshooting ✓

You're ready to use the 1603 Assistant!

---

**Remember:** The most critical feature is **proper vacant parameter handling**. 
If commands have placeholder text in vacant fields, they will fail on real equipment.
