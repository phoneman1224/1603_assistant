# TL1 Assistant — Copilot Development Plan

> **Purpose**: This document tells GitHub Copilot (and contributors) exactly how to continue building the TL1 Assistant from the current repository state. It captures what exists, the target architecture, concrete tasks (with acceptance criteria), and code scaffolds/pseudocode to accelerate implementation.

Repo root assumed: `1603_assistant/`

---

## 0) Current State Snapshot (from repo analysis)

**Key files**
- `powershell/TL1_CommandBuilder.ps1` — WPF GUI shell, logging, settings bootstrap, console pane.
- `powershell/send_tl1.ps1` — Raw Telnet/TcpClient sender + response cleanup + logging.
- `windows_bootstrap.ps1` — Python venv/bootstrap for validators/tools.
- `docs/` — design notes & dev documentation.
- `tests/vectors/` — rich set of TL1 examples and responses.
- `data/shared/profiles/` — device/profile scaffolding (extend for commands).

**Confirmed features**
- ✅ WPF GUI loads successfully (XAML inline), with bottom console.
- ✅ Central logging (`Write-Log`) into `./logs` with datestamped files.
- ✅ Path-agnostic design (no hard-coded machine paths).
- ✅ Telnet transport implemented in `send_tl1.ps1` (works without SecureCRT).
- ✅ Settings file is initialized on first run.

**Partial/missing**
- ⚠️ Wizard isn’t fully data-driven from a command catalog.
- ⚠️ Validation is not yet a standalone, lenient module.
- ❌ No JSON-driven **playbooks** for automated troubleshooting.
- ❌ No conditional flow control based on device responses.
- ⚠️ CTAG auto-increment / TID-AID memory not persisted to settings.
- ⚠️ Background runspace wiring for “send and stream to console” not finalized.
- ⚠️ Settings not fully leveraged (connection auto-reconnect, last context).

---

## 1) Guiding Principles (keep Copilot aligned)

1. **Portable**: No absolute paths. Resolve via `$PSScriptRoot` everywhere.
2. **Lenient**: `[]` in manuals = optional. Never block builds on missing optional fields.
3. **Data-driven**: Commands and playbooks live in JSON. GUI renders from data.
4. **Non-blocking UI**: Network IO in background runspaces; UI thread stays responsive.
5. **Everything logged**: Console shows what logs write; timestamps + levels `[INFO|WARN|ERROR|SEND|RECV|TROUBLESHOOT]`.
6. **Stateless to stateful**: Defaults come from last values (persisted in `settings.json`).

---

## 2) File/Folder Layout (target)

```
1603_assistant/
  powershell/
    TL1_CommandBuilder.ps1
    send_tl1.ps1
  data/
    commands.json            # catalog: verbs, params, schema
    playbooks.json           # troubleshooting flows (sequences + conditions)
  logs/
  settings.json              # created/updated at runtime
  README.md
  Copilot_Development_Plan.md
```

> **Note**: `commands.json` can be bootstrapped from `tests/vectors/` and manual tarballs later.

---

## 3) Schemas

### 3.1 commands.json (catalog)
```jsonc
[
  {
    "id": "RTRV-ALM",
    "displayName": "Retrieve Alarms",
    "platforms": ["1603_SM","16034_SMX"],
    "category": "Retrieve Information",
    "verb": "RTRV",
    "object": "ALM",
    "mod": null,
    "requires": ["TID","AID","CTAG"],           // minimum fields
    "optional": ["COND","LOC","DATETIME"],      // optional params
    "paramSchema": {
      "TID": { "type": "string", "hint": "Target ID", "example": "NE1" },
      "AID": { "type": "string", "hint": "Access ID", "example": "1-1-1" },
      "CTAG": { "type": "string", "hint": "Client Tag", "example": "1001" },
      "COND": { "type": "enum", "enum": ["CR","MJ","MN","CL"] },
      "LOC": { "type": "enum", "enum": ["NEND","FEND","BOTH"] },
      "DATETIME": { "type": "string", "hint": "YYYY-MM-DD HH:MM" }
    },
    "examples": [
      "RTRV-ALM::NE1-1-1:1001::;",
      "RTRV-ALM::NE1-1-1:1001::COND=CR,LOC=NEND;"
    ]
  }
]
```

### 3.2 playbooks.json (auto-troubleshooting)
```jsonc
{
  "Troubleshooting": {
    "Port_Check": {
      "description": "Check port alarms, loopback, and PM counters",
      "platforms": ["1603_SM","16034_SMX"],
      "steps": [
        {
          "command": "RTRV-ALM",
          "params": { "TID": "$TID", "AID": "$AID", "CTAG": "$CTAG" },
          "expect": ["COMPLD","DENY"],
          "onSuccess": "Loopback_Test",
          "onFail": "End"
        },
        {
          "label": "Loopback_Test",
          "command": "TST-PORT",
          "params": { "TID": "$TID", "AID": "$AID", "CTAG": "$CTAG" },
          "expect": ["COMPLD"],
          "onSuccess": "Retrieve_PM",
          "onFail": "End"
        },
        {
          "label": "Retrieve_PM",
          "command": "RTRV-PM",
          "params": { "TID": "$TID", "AID": "$AID", "CTAG": "$CTAG" },
          "expect": ["COMPLD"],
          "onSuccess": "End"
        }
      ]
    }
  }
}
```

### 3.3 settings.json (runtime)
```jsonc
{
  "Connection": { "Host": "10.0.0.1", "Port": 23, "AutoConnect": true },
  "Defaults": { "LastTID": "NE1", "LastAID": "1-1-1", "NextCTAG": 1001 },
  "UI": { "Window": { "Width": 1200, "Height": 800 }, "DebugMode": false },
  "LogRoot": ".\\logs"
}
```

---

## 4) WPF Control Naming (bind to these IDs)

- `SystemSelector` (ComboBox: 1603 SM / 16034 SMX)
- `CategoryList` (ListBox)
- `CommandList` (ListBox)
- `WizardPanel` (StackPanel where dynamic fields are rendered)
- `PreviewBox` (TextBox, read-only)
- `RunButton` (Send/Build button)
- `TroubleshootButton` (Button)
- `CancelButton` (Button, hidden until running)
- `ConsoleBox` (TextBox, read-only, bottom pane)
- `HostBox` (TextBox), `PortBox` (TextBox), `ConnectButton` (Button), `StatusLabel` (TextBlock)

---

## 5) PowerShell Modules & Function Contracts

> Implement these in `TL1_CommandBuilder.ps1` unless noted otherwise.

### 5.1 Catalog & Settings

```powershell
function Get-AppRoot { param(); if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path } }

function Load-Settings {
  $root = Get-AppRoot
  $path = Join-Path $root "..\settings.json"
  if (!(Test-Path $path)) {
    $default = @{
      Connection = @{ Host = "127.0.0.1"; Port = 23; AutoConnect = $false }
      Defaults   = @{ LastTID = ""; LastAID = ""; NextCTAG = 1000 }
      UI         = @{ Window = @{ Width = 1200; Height = 800 }; DebugMode = $false }
      LogRoot    = ".\logs"
    } | ConvertTo-Json -Depth 6
    $default | Set-Content -Path $path -Encoding UTF8
  }
  Get-Content $path -Raw | ConvertFrom-Json
}

function Save-Settings { param([pscustomobject]$Settings)
  $root = Get-AppRoot
  $path = Join-Path $root "..\settings.json"
  ($Settings | ConvertTo-Json -Depth 6) | Set-Content -Path $path -Encoding UTF8
}

function Load-Catalog {
  $root = Get-AppRoot
  $path = Join-Path $root "..\data\commands.json"
  if (!(Test-Path $path)) { throw "Missing data/commands.json" }
  (Get-Content $path -Raw) | ConvertFrom-Json
}

function Load-Playbooks {
  $root = Get-AppRoot
  $path = Join-Path $root "..\data\playbooks.json"
  if (!(Test-Path $path)) { return @{} }
  (Get-Content $path -Raw) | ConvertFrom-Json
}
```

### 5.2 Logging & Console

```powershell
function Write-Console { param([string]$Message, [string]$Level = "INFO")
  $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
  $line = "[$Level] $stamp $Message"
  $ConsoleBox.Dispatcher.Invoke({ $ConsoleBox.AppendText($line + "`r`n"); $ConsoleBox.ScrollToEnd() })
  Write-Log -Message $line
}
```

### 5.3 Builder & Validator

```powershell
function Build-Tl1Command {
  param(
    [string]$Verb, [string]$Object, [string]$Mod,
    [string]$TID, [string]$AID, [string]$CTAG,
    [hashtable]$OptionalParams
  )
  $head = if ($Mod) { "{0}-{1}:{2}" -f $Verb,$Object,$Mod } else { "{0}-{1}" -f $Verb,$Object }
  $addr = "{0}:{1}-{2}:{3}" -f $head,$TID,$AID,$CTAG
  $opt = if ($OptionalParams.Keys.Count -gt 0) { $pairs = $OptionalParams.GetEnumerator() | Where-Object { $_.Value } | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }; "::" + ($pairs -join ",") } else { "::" }
  $cmd = "$addr$opt;"
  $cmd
}

function Validate-Tl1Command {
  param([string]$CommandText)
  if (-not $CommandText.Trim().EndsWith(";")) { return @{ Ok=$false; Error="Missing semicolon" } }
  if ($CommandText -notmatch "^[A-Z\-]+:") { return @{ Ok=$false; Error="Malformed head (VERB-OBJECT[:MOD])" } }
  return @{ Ok=$true; Warning=$null }
}
```

### 5.4 Dynamic Wizard Rendering

```powershell
function Render-WizardFromSchema {
  param($CommandSpec, [pscustomobject]$Settings)
  $WizardPanel.Children.Clear()

  $fields = @()
  foreach ($name in $CommandSpec.requires + $CommandSpec.optional) {
    $meta = $CommandSpec.paramSchema.$name
    $tb = New-Object System.Windows.Controls.TextBox
    $tb.Margin = "0,4,0,4"
    $tb.Tag = $name
    $tb.Text = switch ($name) {
      "TID" { $Settings.Defaults.LastTID }
      "AID" { $Settings.Defaults.LastAID }
      "CTAG" { [string]$Settings.Defaults.NextCTAG }
      default { "" }
    }
    $WizardPanel.Children.Add($tb) | Out-Null
    $fields += $tb
  }

  # Recompute preview on change
  foreach ($tb in $fields) {
    $tb.Add_TextChanged({
      Render-Preview
    })
  }
}

function Render-Preview {
  $spec = $Global:SelectedCommandSpec
  $values = Get-WizardValues
  $cmd = Build-Tl1Command -Verb $spec.verb -Object $spec.object -Mod $spec.mod -TID $values.TID -AID $values.AID -CTAG $values.CTAG -OptionalParams $values.Optional
  $PreviewBox.Text = $cmd
}
```

### 5.5 Sending (runspace)

```powershell
function Send-PreviewCommand {
  $cmd = $PreviewBox.Text
  $val = Validate-Tl1Command -CommandText $cmd
  if (-not $val.Ok) { Write-Console "Validation error: $($val.Error)" "WARN" }

  $root = Get-AppRoot
  $send = Join-Path $root "..\powershell\send_tl1.ps1"

  $HostTxt = $HostBox.Text; $PortTxt = [int]$PortBox.Text

  $job = Start-Job -ScriptBlock {
    param($send, $cmd, $HostTxt, $PortTxt)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $send -CommandText $cmd -Host $HostTxt -Port $PortTxt
  } -ArgumentList $send, $cmd, $HostTxt, $PortTxt

  Write-Console "Sent: $cmd" "SEND"
}
```

### 5.6 Troubleshooting Engine (playbook runner)

```powershell
function Start-TroubleshootingProcess {
  param([string]$FlowName, [string]$TID, [string]$AID)
  $pb = $Global:Playbooks.Troubleshooting.$FlowName
  if (-not $pb) { Write-Console "Playbook '$FlowName' not found" "ERROR"; return }

  $ctag = [int]$Global:Settings.Defaults.NextCTAG
  foreach ($step in $pb.steps) {
    $spec = Find-CommandSpec -Id $step.command
    $params = @{}
    foreach ($k in $step.params.Keys) {
      $v = $step.params.$k
      switch ($v) {
        "$TID" { $params[$k] = $TID }
        "$AID" { $params[$k] = $AID }
        "$CTAG" { $params[$k] = $ctag }
        default { $params[$k] = $v }
      }
    }
    $cmd = Build-Tl1Command -Verb $spec.verb -Object $spec.object -Mod $spec.mod -TID $params.TID -AID $params.AID -CTAG $params.CTAG -OptionalParams (@{})
    $PreviewBox.Text = $cmd
    Send-PreviewCommand
    $ctag++
    Start-Sleep -Milliseconds 200  # pacing
  }
  $Global:Settings.Defaults.NextCTAG = $ctag
  Save-Settings -Settings $Global:Settings
}
```

---

## 6) Tasks & Acceptance Criteria

### Task A — Seed `data/commands.json`
- **Do**: Create a minimal catalog with 10–15 commands spanning all 5 categories for both platforms.
- **Accept**: App loads catalog without errors; Category → Command lists populate; selecting a command renders wizard fields.

### Task B — Wire dynamic wizard
- **Do**: Implement `Render-WizardFromSchema`, `Get-WizardValues`, `Render-Preview`.
- **Accept**: Typing in TID/AID/CTAG/optional fields updates preview live; semicolon enforced; validator warns only.

### Task C — Connect send path
- **Do**: Hook “Send” button to `Send-PreviewCommand` → `send_tl1.ps1` (background job).
- **Accept**: Console logs `[SEND]` and shows device response (from `send_tl1.ps1`); UI stays responsive.

### Task D — Persist state
- **Do**: Save/restore `LastTID`, `LastAID`, `NextCTAG`, Host/Port, Debug flag.
- **Accept**: Restarting the app repopulates fields; CTAG increments across runs.

### Task E — Add `data/playbooks.json` and runner
- **Do**: Implement playbook file + `Start-TroubleshootingProcess` + GUI button.
- **Accept**: Clicking “Run Troubleshooting” executes a sequence of 3+ commands, logs each step, increments CTAG, and prints a summary.

### Task F — Console levels & debug mode
- **Do**: Add level tags and toggle for verbose logs; include timestamps.
- **Accept**: `[INFO]`, `[WARN]`, `[ERROR]`, `[SEND]`, `[RECV]`, `[TROUBLESHOOT]` appear; when Debug on, include extra details (timings, raw responses).

---

## 7) Copilot Prompt Snippets (paste into editor)

- “Generate `Load-Catalog` and `Load-Playbooks` PowerShell functions to read JSON files from the `data/` folder using `$PSScriptRoot`-safe resolution.”
- “Create a `Render-WizardFromSchema` function that takes a command JSON spec and dynamically renders TextBoxes/ComboBoxes with hints, and updates a live preview TextBox.”
- “Write `Build-Tl1Command` that accepts verb/object/mod/TID/AID/CTAG and a hashtable of optional params, and returns a well-formed TL1 string ending in a semicolon.”
- “Implement `Send-PreviewCommand` that starts a background job to run `powershell\send_tl1.ps1` with `-CommandText`, `-Host`, `-Port`, and pipes the response back to the GUI console.”
- “Create a `Start-TroubleshootingProcess` function that reads a playbook (JSON) sequence and executes commands with auto-increment CTAG and conditional branching.”

---

## 8) Testing & QA

- **Unit-ish** (Pester optional):
  - `Build-Tl1Command` handles with/without `mod`, with/without optional params.
  - Validator warns on missing `;`, malformed head.
- **Manual**:
  - Change wizard fields → preview updates.
  - Send command to a test TL1 endpoint or loopback; verify console shows request/response.
  - Run Troubleshooting on a dummy playbook; ensure CTAG increments and summary prints.
- **Performance**:
  - App launches < 2s; sending does not freeze UI.

---

## 9) Roadmap After MVP

- Parse `/mnt/data/1603_SM.tar` and `/mnt/data/1603_SMX.tar` into `commands.json` automatically.
- Add fuzzy search over commands.
- Multi-session Telnet with tabs.
- Batch mode (run queued commands).
- Export last N commands & summaries as a report.

---

## 10) Done Definition for “Automated Troubleshooting”

- A technician selects a platform + enters Host/Port + picks an AID.
- Clicking **Run Troubleshooting** executes the named playbook.
- Each step:
  - Builds the correct TL1 string using current TID/AID/CTAG.
  - Sends it via Telnet.
  - Logs `[SEND]` + `[RECV]` and parses status tokens (`COMPLD`, `DENY`, etc.).
  - Decides next step per playbook.
- Console shows live progress and a final summary.
- `settings.json` persists CTAG, last TID/AID, host/port.
- No SecureCRT required.

---

*End of Copilot Development Plan.*
