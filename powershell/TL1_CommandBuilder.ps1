# Error handling and logging setup
$ErrorActionPreference = 'Continue'  # Changed from 'Stop' to prevent immediate exit
$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'

# Add console output for debugging
Write-Host "🚀 TL1 Command Builder Starting..." -ForegroundColor Cyan
Write-Host "Current Directory: $($PWD.Path)" -ForegroundColor Gray

# Version and environment checks
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "OS Version: $([System.Environment]::OSVersion.Version)" -ForegroundColor Gray

if ($PSVersionTable.PSVersion.Major -gt 5) {
    Write-Host "❌ ERROR: This script requires Windows PowerShell 5.1" -ForegroundColor Red
    Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    Write-Host "Please run using 'Windows PowerShell' (blue icon) instead of 'PowerShell Core' (black icon)" -ForegroundColor Yellow
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# --- STA guard for WPF ---
try { 
    $isSta = [System.Threading.Thread]::CurrentThread.ApartmentState -eq 'STA' 
} catch { 
    $isSta = $false 
}

if (-not $isSta) {
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $argsList = @('-NoProfile','-ExecutionPolicy','Bypass','-STA','-File',('"{0}"' -f $PSCommandPath))
    Start-Process -FilePath $ps -ArgumentList $argsList -WorkingDirectory (Split-Path -Parent $PSCommandPath)
    return
}
# --- end STA guard ---

# Load required assemblies
try {
    Write-Host "Loading WPF assemblies..." -ForegroundColor Yellow
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Write-Host "✅ WPF assemblies loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to load WPF assemblies" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    Write-Host "This might indicate:" -ForegroundColor Yellow
    Write-Host "• Windows Desktop features are not installed" -ForegroundColor Yellow
    Write-Host "• .NET Framework version is too old" -ForegroundColor Yellow
    Write-Host "• Running on Windows Server Core (GUI not available)" -ForegroundColor Yellow
    Write-Host "" -ForegroundColor Yellow
    Write-Host "Stack Trace:" -ForegroundColor Gray
    Write-Host $_.Exception.StackTrace -ForegroundColor Gray
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Resolve paths relative to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

# Ensure app data directory exists in user profile (for portable operation)
$AppDataDir = Join-Path $env:LOCALAPPDATA "TL1_CommandBuilder"
if (!(Test-Path $AppDataDir)) { 
    New-Item -ItemType Directory -Path $AppDataDir | Out-Null 
}

# Set up logging
# Initialize logging system after all functions are defined

# Settings with safe defaults - store in script directory for portability
$SettingsPath = Join-Path $ScriptDir "appsettings.json"
if (!(Test-Path $SettingsPath)) {
  $default = @{
    LogDir="..\\logs"; DefaultHost=""; DefaultPort=23; AutoIncrementCTAG=$true
    Window=@{Width=1150;Height=760}; Debug=$true
  } | ConvertTo-Json -Depth 5
  $default | Out-File -FilePath $SettingsPath -Encoding UTF8
}
try { $Settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json } catch {
  $Settings = [pscustomobject]@{ LogDir="..\\logs"; DefaultHost=""; DefaultPort=23; AutoIncrementCTAG=$true; Window=@{Width=1150;Height=760}; Debug=$true }
}

# Safe numeric window size
$WinWidth  = 1150; $WinHeight = 760
try {
  if ($Settings.Window -and $Settings.Window.Width)  { $w = $Settings.Window.Width -as [int]; if ($w -gt 0) { $WinWidth = $w } }
  if ($Settings.Window -and $Settings.Window.Height) { $h = $Settings.Window.Height -as [int]; if ($h -gt 0) { $WinHeight = $h } }
} catch {}

# Enhanced structured logging system with background job support
$global:ConsoleBox=$null
$global:LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
$global:BackgroundJobs = @{}

function Initialize-StructuredLogging {
    # Ensure logs directory exists with year-month structure
    $LogYear = (Get-Date).ToString("yyyy")
    $LogMonth = (Get-Date).ToString("yyyy-MM")
    $LogDir = Join-Path $PSScriptRoot "logs\$LogMonth"
    
    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }
    
    $global:LogFile = Join-Path $LogDir "tl1_$((Get-Date).ToString('yyyy-MM-dd')).log"
    
    # Start background log processor
    Start-LogProcessor
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Context = "",
        [hashtable]$Metadata = @{}
    )
    
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
    $processId = $PID
    $thread = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    
    # Build structured log entry
    $logEntry = @{
        timestamp = $timestamp
        level = $Level.ToUpper()
        message = $Message
        context = $Context
        process_id = $processId
        thread_id = $thread
        metadata = $Metadata
    }
    
    # Format for file output
    $fileOutput = "[$timestamp] [$Level] "
    if ($Context) { $fileOutput += "[$Context] " }
    $fileOutput += $Message
    if ($Metadata.Count -gt 0) {
        $metaStr = ($Metadata.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
        $fileOutput += " | $metaStr"
    }
    
    # Format for console output
    $consoleOutput = "[$timestamp] [$Level] $Message"
    
    # Queue for background processing
    $global:LogQueue.Enqueue($fileOutput)
    
    # Update GUI console immediately
    if ($global:ConsoleBox) {
        try {
            $global:ConsoleBox.Dispatcher.Invoke([System.Windows.Threading.DispatcherPriority]::Normal, [System.Action]{
                $global:ConsoleBox.AppendText("$consoleOutput`r`n")
                $global:ConsoleBox.ScrollToEnd()
            })
        } catch {
            # Fallback if dispatcher not available
            $global:ConsoleBox.AppendText("$consoleOutput`r`n")
            $global:ConsoleBox.ScrollToEnd()
        }
    }
}

function Start-LogProcessor {
    if ($global:LogProcessorJob) {
        Stop-Job -Job $global:LogProcessorJob -ErrorAction SilentlyContinue
        Remove-Job -Job $global:LogProcessorJob -ErrorAction SilentlyContinue
    }
    
    $global:LogProcessorJob = Start-Job -ScriptBlock {
        param($LogFile, $LogQueue)
        
        while ($true) {
            $items = @()
            while ($LogQueue.TryDequeue([ref]$item)) {
                $items += $item
            }
            
            if ($items.Count -gt 0) {
                try {
                    Add-Content -Path $LogFile -Value $items -ErrorAction SilentlyContinue
                } catch {
                    # Ignore file access errors
                }
            }
            
            Start-Sleep -Milliseconds 100
        }
    } -ArgumentList $global:LogFile, $global:LogQueue
}

function Start-TL1BackgroundCommand {
    param(
        [string]$Command,
        [string]$JobName,
        [hashtable]$Parameters = @{},
        [scriptblock]$OnComplete = {},
        [scriptblock]$OnError = {}
    )
    
    $jobId = [System.Guid]::NewGuid().ToString("N")[0..7] -join ""
    
    Write-Log "Starting background TL1 command" "SEND" "Background" @{
        command = $Command
        job_id = $jobId
        parameters = ($Parameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ", "
    }
    
    $job = Start-Job -ScriptBlock {
        param($Command, $Parameters, $JobId)
        
        # Simulate TL1 command execution
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 5)
        
        # Return result
        @{
            JobId = $JobId
            Command = $Command
            Status = "COMPLD"
            Response = "M $($Parameters.CTAG) COMPLD`n;"
            Timestamp = Get-Date
            Duration = (Get-Random -Minimum 500 -Maximum 3000)
        }
    } -ArgumentList $Command, $Parameters, $jobId
    
    $global:BackgroundJobs[$jobId] = @{
        Job = $job
        Command = $Command
        StartTime = Get-Date
        OnComplete = $OnComplete
        OnError = $OnError
        Parameters = $Parameters
    }
    
    return $jobId
}

function Monitor-BackgroundJobs {
    $completedJobs = @()
    
    foreach ($jobEntry in $global:BackgroundJobs.GetEnumerator()) {
        $jobId = $jobEntry.Key
        $jobInfo = $jobEntry.Value
        $job = $jobInfo.Job
        
        if ($job.State -eq "Completed") {
            try {
                $result = Receive-Job -Job $job
                $duration = ((Get-Date) - $jobInfo.StartTime).TotalMilliseconds
                
                Write-Log "Background command completed" "RECV" "Background" @{
                    job_id = $jobId
                    command = $jobInfo.Command
                    status = $result.Status
                    duration_ms = [int]$duration
                }
                
                # Execute completion callback
                if ($jobInfo.OnComplete) {
                    & $jobInfo.OnComplete $result
                }
                
                $completedJobs += $jobId
            } catch {
                Write-Log "Background command failed: $($_.Exception.Message)" "ERROR" "Background" @{
                    job_id = $jobId
                    command = $jobInfo.Command
                }
                
                if ($jobInfo.OnError) {
                    & $jobInfo.OnError $_
                }
                
                $completedJobs += $jobId
            } finally {
                Remove-Job -Job $job -ErrorAction SilentlyContinue
            }
        }
        elseif ($job.State -eq "Failed") {
            Write-Log "Background job failed" "ERROR" "Background" @{
                job_id = $jobId
                command = $jobInfo.Command
            }
            
            if ($jobInfo.OnError) {
                & $jobInfo.OnError "Job failed"
            }
            
            Remove-Job -Job $job -ErrorAction SilentlyContinue
            $completedJobs += $jobId
        }
    }
    
    # Remove completed jobs from tracking
    foreach ($jobId in $completedJobs) {
        $global:BackgroundJobs.Remove($jobId)
    }
}

# Load TL1 commands from the data-driven catalog
function Load-TL1Commands {
    param([string]$selectedPlatform = "1603 SM")  # Default to 1603 SM
    
    Write-Log "Loading data-driven commands for platform: $selectedPlatform"
    
    $AllCommands = [ordered]@{}
    
    # Load the main data-driven catalog
    $CatalogPath = Join-Path $RootDir "data\commands.json"
    if (Test-Path $CatalogPath) {
        try {
            $Catalog = Get-Content $CatalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Log "Loaded data-driven catalog with $($Catalog.commands.PSObject.Properties.Count) commands"
            
            # Process each command in the catalog
            $Catalog.commands.PSObject.Properties | ForEach-Object {
                $commandId = $_.Name
                $command = $_.Value
                
                # Filter by platform
                if ($command.platforms -contains $selectedPlatform) {
                    $categoryName = $command.category
                    
                    if (-not $AllCommands.Contains($categoryName)) {
                        $AllCommands[$categoryName] = @()
                    }
                    
                    # Convert paramSchema to required/optional lists
                    $requiredParams = @()
                    $optionalParams = @()
                    $paramDetails = @{}
                    
                    if ($command.paramSchema) {
                        $command.paramSchema.PSObject.Properties | ForEach-Object {
                            $paramName = $_.Name
                            $paramInfo = $_.Value
                            $paramDetails[$paramName] = $paramInfo
                            
                            if ($command.requires -contains $paramName) {
                                $requiredParams += $paramName
                            } else {
                                $optionalParams += $paramName
                            }
                        }
                    }
                    
                    # Create command entry compatible with existing GUI
                    $commandEntry = @{
                        Name = $command.id
                        DisplayName = $command.displayName
                        Desc = $command.description
                        DetailedDesc = $command.description
                        Required = $requiredParams
                        Optional = $optionalParams
                        Parameters = $paramDetails
                        Syntax = $command.syntax
                        Restrictions = ""
                        ResponseFormat = $command.response_format
                        SafetyLevel = $command.safety_level
                        ServiceAffecting = $command.service_affecting
                        SourceFile = "commands.json (data-driven)"
                        Platform = $selectedPlatform
                        Category = $command.category
                        Verb = $command.verb
                        Object = $command.object
                        Modifier = $command.modifier
                        ParamSchema = $command.paramSchema
                        IsProvisioning = if ($command.provisioning) { $command.provisioning } else { $false }
                    }
                    
                    $AllCommands[$categoryName] += $commandEntry
                    Write-Log "  Added command: $($command.id) to $categoryName"
                }
            }
            
        } catch {
            Write-Log "Error loading data-driven catalog: $_" "ERROR"
        }
    } else {
        Write-Log "Data-driven catalog not found at $CatalogPath" "ERROR"
        # Fallback to basic commands if catalog is missing
        $AllCommands = @{
            "Network Maintenance" = @(
                @{Name="RTRV-ALM";Desc="Retrieve Alarms";Required=@("TID","CTAG");Optional=@("ALMCD","NTFCNCDE");Platform=$selectedPlatform},
                @{Name="RTRV-HDR";Desc="Retrieve Header";Required=@("TID","CTAG");Optional=@();Platform=$selectedPlatform}
            )
            "System Administration" = @(
                @{Name="ACT-USER";Desc="Activate User";Required=@("UID");Optional=@("PID");Platform=$selectedPlatform},
                @{Name="CANC-USER";Desc="Cancel User Session";Required=@("UID");Optional=@();Platform=$selectedPlatform}
            )
        }
    }
    
    $totalCommands = ($AllCommands.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Write-Log "Loaded $($AllCommands.Keys.Count) categories with $totalCommands total commands for $selectedPlatform"
    
    # Log detailed breakdown
    foreach ($category in $AllCommands.Keys) {
        $count = $AllCommands[$category].Count
        Write-Log "  ${category}: $count commands"
    }
    
    return $AllCommands
}

# Settings persistence functions
function Load-Settings {
    $SettingsPath = Join-Path $RootDir "settings.json"
    
    $DefaultSettings = @{
        Connection = @{
            Host = ""
            Port = 23
        }
        LastUsed = @{
            TID = ""
            AID = ""
            NextCTAG = 1
        }
        UI = @{
            Platform = "1603 SM"
        }
        Window = @{
            Width = 1150
            Height = 760
        }
    }
    
    if (Test-Path $SettingsPath) {
        try {
            $loadedSettings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
            # Merge with defaults to ensure all properties exist
            if ($loadedSettings.Connection) {
                if ($loadedSettings.Connection.Host) { $DefaultSettings.Connection.Host = $loadedSettings.Connection.Host }
                if ($loadedSettings.Connection.Port) { $DefaultSettings.Connection.Port = $loadedSettings.Connection.Port }
            }
            if ($loadedSettings.LastUsed) {
                if ($loadedSettings.LastUsed.TID) { $DefaultSettings.LastUsed.TID = $loadedSettings.LastUsed.TID }
                if ($loadedSettings.LastUsed.AID) { $DefaultSettings.LastUsed.AID = $loadedSettings.LastUsed.AID }
                if ($loadedSettings.LastUsed.NextCTAG) { $DefaultSettings.LastUsed.NextCTAG = $loadedSettings.LastUsed.NextCTAG }
            }
            if ($loadedSettings.UI -and $loadedSettings.UI.Platform) {
                $DefaultSettings.UI.Platform = $loadedSettings.UI.Platform
            }
            if ($loadedSettings.Window) {
                if ($loadedSettings.Window.Width) { $DefaultSettings.Window.Width = $loadedSettings.Window.Width }
                if ($loadedSettings.Window.Height) { $DefaultSettings.Window.Height = $loadedSettings.Window.Height }
            }
            Write-Log "Settings loaded from $SettingsPath"
        } catch {
            Write-Log "Error loading settings: $_" "WARN"
        }
    } else {
        Write-Log "No settings file found, using defaults"
    }
    
    return $DefaultSettings
}

function Save-Settings {
    param([hashtable]$Settings)
    
    $SettingsPath = Join-Path $RootDir "settings.json"
    try {
        $Settings | ConvertTo-Json -Depth 3 | Set-Content $SettingsPath -Encoding UTF8
        Write-Log "Settings saved to $SettingsPath"
    } catch {
        Write-Log "Error saving settings: $_" "ERROR"
    }
}

function Update-CTAG {
    param([int]$NewCTAG = -1)
    
    if ($NewCTAG -eq -1) {
        $global:Settings.LastUsed.NextCTAG = $global:Settings.LastUsed.NextCTAG + 1
    } else {
        $global:Settings.LastUsed.NextCTAG = $NewCTAG
    }
    
    Save-Settings -Settings $global:Settings
    return $global:Settings.LastUsed.NextCTAG
}

# Load settings at startup
$global:Settings = Load-Settings

# Load playbooks
function Load-Playbooks {
    $PlaybooksPath = Join-Path $RootDir "data\playbooks.json"
    
    if (Test-Path $PlaybooksPath) {
        try {
            $playbooks = Get-Content $PlaybooksPath -Raw | ConvertFrom-Json
            Write-Log "Loaded playbooks from $PlaybooksPath"
            return $playbooks
        } catch {
            Write-Log "Error loading playbooks: $_" "ERROR"
            return $null
        }
    } else {
        Write-Log "No playbooks file found at $PlaybooksPath" "WARN"
        return $null
    }
}

# Execute a playbook with token substitution
function Invoke-Playbook {
    param(
        [string]$PlaybookCategory,
        [string]$PlaybookName,
        [hashtable]$Tokens = @{}
    )
    
    $playbooks = Load-Playbooks
    if (-not $playbooks) {
        Write-Log "No playbooks available" "ERROR"
        return
    }
    
    $playbook = $playbooks.playbooks.$PlaybookCategory.$PlaybookName
    if (-not $playbook) {
        Write-Log "Playbook not found: $PlaybookCategory.$PlaybookName" "ERROR"
        return
    }
    
    Write-Log "Starting playbook: $($playbook.name)" "TROUBLESHOOT"
    $global:ConsoleBox.AppendText("[TROUBLESHOOT] Starting: $($playbook.name)`r`n")
    $global:ConsoleBox.AppendText("[TROUBLESHOOT] Description: $($playbook.description)`r`n")
    $global:ConsoleBox.ScrollToEnd()
    
    $stepCount = 0
    $successCount = 0
    
    foreach ($step in $playbook.steps) {
        $stepCount++
        
        # Check conditions if specified
        if ($step.condition) {
            $conditionMet = $false
            try {
                # Simple condition evaluation for $AID checks
                if ($step.condition -like "*`$AID*") {
                    $aidValue = $Tokens['AID']
                    if ($step.condition -eq "`$AID != ''" -and $aidValue -and $aidValue.Trim() -ne "") {
                        $conditionMet = $true
                    }
                }
            } catch {
                Write-Log "Error evaluating condition: $($step.condition)" "WARN"
            }
            
            if (-not $conditionMet) {
                Write-Log "Step $stepCount skipped - condition not met: $($step.condition)" "TROUBLESHOOT"
                continue
            }
        }
        
        Write-Log "Step $stepCount/$($playbook.steps.Count): $($step.name)" "TROUBLESHOOT"
        $global:ConsoleBox.AppendText("[TROUBLESHOOT] Step ${stepCount}: $($step.name)`r`n")
        $global:ConsoleBox.ScrollToEnd()
        
        # Find the command
        $commandId = $step.command_id
        $command = $null
        
        # Look for command in loaded categories
        foreach ($category in $global:Categories.Keys) {
            foreach ($cmd in $global:Categories[$category]) {
                if ($cmd.Name -eq $commandId -or $cmd.id -eq $commandId) {
                    $command = $cmd
                    break
                }
            }
            if ($command) { break }
        }
        
        if (-not $command) {
            Write-Log "Command not found: $commandId" "ERROR"
            if ($step.on_error -eq "abort") {
                Write-Log "Aborting playbook due to missing command" "ERROR"
                return
            }
            continue
        }
        
        # Build command with token substitution
        $cmdText = ""
        try {
            # Substitute tokens in parameters
            $substitutedParams = @{}
            if ($step.params) {
                $step.params.PSObject.Properties | ForEach-Object {
                    $value = $_.Value
                    # Substitute tokens
                    foreach ($token in $Tokens.Keys) {
                        $value = $value -replace "\`$$token", $Tokens[$token]
                    }
                    $substitutedParams[$_.Name] = $value
                }
            }
            
            # Build command using the syntax template
            $cmdText = $command.Syntax
            if ($cmdText) {
                # Simple parameter substitution
                foreach ($param in $substitutedParams.Keys) {
                    $value = $substitutedParams[$param]
                    $cmdText = $cmdText -replace "\[$param\]", $value
                    $cmdText = $cmdText -replace "<$param>", $value
                }
                
                # Clean up any remaining placeholders
                $cmdText = $cmdText -replace "\[.*?\]", ""
                $cmdText = $cmdText -replace "<.*?>", ""
            }
        } catch {
            Write-Log "Error building command: $_" "ERROR"
            if ($step.on_error -eq "abort") {
                Write-Log "Aborting playbook due to command build error" "ERROR"
                return
            }
            continue
        }
        
        if ($cmdText.Trim() -eq "") {
            Write-Log "Empty command generated for step $stepCount" "ERROR"
            continue
        }
        
        # Log the command
        Write-Log "Executing: $cmdText" "TROUBLESHOOT"
        $global:ConsoleBox.AppendText("[TROUBLESHOOT] > $cmdText`r`n")
        $global:ConsoleBox.ScrollToEnd()
        
        # Execute the command (simplified - just log for now)
        # In full implementation, this would actually send the command
        $global:ConsoleBox.AppendText("[TROUBLESHOOT] < Command logged (execution not implemented)`r`n")
        $successCount++
        
        # Increment CTAG for next command
        $newCTAG = Update-CTAG
        $Tokens['CTAG'] = $newCTAG
        
        # Delay if specified
        if ($step.delay_after -and $step.delay_after -gt 0) {
            Write-Log "Waiting $($step.delay_after) seconds..." "TROUBLESHOOT"
            Start-Sleep -Seconds $step.delay_after
        }
    }
    
    # Summary
    Write-Log "Playbook completed: $successCount/$stepCount steps successful" "TROUBLESHOOT"
    $global:ConsoleBox.AppendText("[SUMMARY] Troubleshooting completed: $successCount/$stepCount steps successful`r`n")
    $global:ConsoleBox.AppendText("[SUMMARY] $($playbook.name) finished`r`n")
    $global:ConsoleBox.ScrollToEnd()
}

# Initial load with platform from settings
$global:CurrentPlatform = $global:Settings.UI.Platform
$Categories = Load-TL1Commands -selectedPlatform $global:CurrentPlatform

# -------------------- LIGHT THEME XAML --------------------
$xaml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Title="TL1 Command Builder"
  WindowStartupLocation="CenterScreen"
  Width="${WinWidth}" Height="${WinHeight}"
  Background="#ffffff">
  <Window.Resources>
    <SolidColorBrush x:Key="PanelBg" Color="#f5f7fb"/>
    <SolidColorBrush x:Key="PanelBorder" Color="#c7cdd9"/>
    <SolidColorBrush x:Key="TextMain" Color="#111827"/>
    <SolidColorBrush x:Key="TextMuted" Color="#374151"/>
    <Style TargetType="TextBlock">
      <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="Background" Value="#ffffff"/>
      <Setter Property="BorderBrush" Value="#c7cdd9"/>
    </Style>
    <Style TargetType="TreeView">
      <Setter Property="Background" Value="#ffffff"/>
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="BorderThickness" Value="0"/>
    </Style>
    <Style TargetType="TreeViewItem">
      <Setter Property="Foreground" Value="#111827"/>
    </Style>
    <Style TargetType="Button">
      <Setter Property="Foreground" Value="#111827"/>
      <Setter Property="Background" Value="#e5e7eb"/>
      <Setter Property="BorderBrush" Value="#c7cdd9"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="6,4"/>
    </Style>
  </Window.Resources>

  <DockPanel LastChildFill="True">
    <Border DockPanel.Dock="Left" Width="270" Background="{StaticResource PanelBg}" BorderBrush="{StaticResource PanelBorder}" BorderThickness="0,0,1,0">
      <StackPanel>
        <TextBlock Text="Categories" FontWeight="Bold" Margin="10,10,10,6"/>
        <TreeView Name="CategoryTree" Margin="8"/>
      </StackPanel>
    </Border>

    <Grid Margin="10">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="180"/>
      </Grid.RowDefinitions>

      <!-- Connection bar -->
      <Border Grid.Row="0" Background="{StaticResource PanelBg}" Padding="8" CornerRadius="8" BorderBrush="{StaticResource PanelBorder}" BorderThickness="1">
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="170"/>
            <ColumnDefinition Width="240"/>
            <ColumnDefinition Width="120"/>
            <ColumnDefinition Width="240"/>  <!-- widened for buttons -->
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>

          <StackPanel Orientation="Horizontal" Grid.Column="0" VerticalAlignment="Center" Margin="4,0">
            <TextBlock Text="System:" Margin="0,0,6,0"/>
            <ComboBox Name="SystemBox" Width="120">
              <ComboBoxItem Content="1603 SM"/>
              <ComboBoxItem Content="1603 SMX"/>
            </ComboBox>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="1" VerticalAlignment="Center" Margin="4,0">
            <TextBlock Text="Host/IP:" Margin="0,0,6,0"/>
            <TextBox Name="HostBox" Width="170"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="2" VerticalAlignment="Center" Margin="4,0">
            <TextBlock Text="Port:" Margin="0,0,6,0"/>
            <TextBox Name="PortBox" Width="70"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="3" VerticalAlignment="Center" Margin="4,0">
            <Button Name="ConnectBtn" Content="Connect" Width="100" Margin="0,0,8,0"/>
            <Button Name="DisconnectBtn" Content="Disconnect" Width="120"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="4" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="4,0">
            <CheckBox Name="DebugChk" Content="Debug"/>
            <TextBlock Name="StatusText" Text="Disconnected" Margin="12,0,0,0" Foreground="#b91c1c"/>
          </StackPanel>
        </Grid>
      </Border>

      <!-- Builder -->
      <Border Grid.Row="1" Background="{StaticResource PanelBg}" Padding="8" CornerRadius="8" BorderBrush="{StaticResource PanelBorder}" BorderThickness="1" Margin="0,10,0,10">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,8">
            <TextBlock Text="Command:" Margin="0,0,6,0"/>
            <ComboBox Name="CommandBox" Width="280"/>
            <TextBlock Text="Desc:" Margin="20,0,6,0" Foreground="{StaticResource TextMuted}"/>
            <TextBlock Name="CmdDesc" Foreground="{StaticResource TextMuted}"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Row="1" Margin="0,0,0,8">
            <TextBlock Text="TID:"/>
            <TextBox Name="TidBox" Width="120" Margin="6,0,20,0"/>
            <TextBlock Text="AID:"/>
            <TextBox Name="AidBox" Width="140" Margin="6,0,20,0"/>
            <TextBlock Text="CTAG:"/>
            <TextBox Name="CtagBox" Width="90" Margin="6,0,20,0"/>
            <CheckBox Name="CtagAuto" Content="Auto-increment" IsChecked="True"/>
          </StackPanel>

          <StackPanel Grid.Row="2">
            <TextBlock Text="Optional Parameters (skip freely - [] means optional):" Margin="0,0,0,6"/>
            <WrapPanel Name="OptionalPanel"/>
          </StackPanel>

          <StackPanel Grid.Row="3" Orientation="Vertical" Margin="0,10,0,0">
            <TextBlock Text="Preview:"/>
            <TextBox Name="PreviewBox" Height="70" IsReadOnly="True" TextWrapping="Wrap" Background="#ffffff" Foreground="#111827"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,8,0,0">
              <Button Name="WizardBtn" Content="Provisioning Wizard" Width="150" Margin="6,0" Background="#10b981" Foreground="White"/>
              <Button Name="TroubleshootBtn" Content="Run Troubleshooting" Width="150" Margin="6,0" Background="#f59e0b" Foreground="White"/>
              <Button Name="CopyBtn" Content="Copy" Width="100" Margin="6,0"/>
              <Button Name="SendBtn" Content="Send" Width="100" Margin="6,0"/>
              <Button Name="LogBtn" Content="Log Only" Width="100" Margin="6,0"/>
            </StackPanel>
          </StackPanel>
        </Grid>
      </Border>

      <!-- Console -->
      <TextBox Name="ConsoleBox" Grid.Row="2" Background="#ffffff" Foreground="#111827"
               FontFamily="Consolas" FontSize="12" TextWrapping="Wrap"
               VerticalScrollBarVisibility="Auto" IsReadOnly="True"/>
    </Grid>
  </DockPanel>
</Window>
"@

# ---- Build visual tree
$Window = [Windows.Markup.XamlReader]::Parse($xaml)

# ---- Bind controls
$CategoryTree=$Window.FindName("CategoryTree"); $SystemBox=$Window.FindName("SystemBox")
$HostBox=$Window.FindName("HostBox"); $PortBox=$Window.FindName("PortBox")
$ConnectBtn=$Window.FindName("ConnectBtn"); $DisconnectBtn=$Window.FindName("DisconnectBtn")
$DebugChk=$Window.FindName("DebugChk"); $StatusText=$Window.FindName("StatusText")
$CommandBox=$Window.FindName("CommandBox"); $CmdDesc=$Window.FindName("CmdDesc")
$TidBox=$Window.FindName("TidBox"); $AidBox=$Window.FindName("AidBox")
$CtagBox=$Window.FindName("CtagBox"); $CtagAuto=$Window.FindName("CtagAuto")
$OptionalPanel=$Window.FindName("OptionalPanel"); $PreviewBox=$Window.FindName("PreviewBox")
$ConsoleBox=$Window.FindName("ConsoleBox"); $CopyBtn=$Window.FindName("CopyBtn")
$SendBtn=$Window.FindName("SendBtn"); $LogBtn=$Window.FindName("LogBtn")
$TroubleshootBtn=$Window.FindName("TroubleshootBtn")
$WizardBtn=$Window.FindName("WizardBtn")
$global:ConsoleBox=$ConsoleBox

# ---- Init defaults from settings
$PortBox.Text = [string]$global:Settings.Connection.Port
$HostBox.Text = $global:Settings.Connection.Host
$StatusText.Text = "Disconnected"

# Populate last used values
$TidBox.Text = $global:Settings.LastUsed.TID
$AidBox.Text = $global:Settings.LastUsed.AID  
$CtagBox.Text = [string]$global:Settings.LastUsed.NextCTAG

# ---- Provisioning Wizard Functions
function Show-ProvisioningWizard {
    param([string]$wizardName = "Cross_Connect_Wizard")
    
    try {
        # Load wizard definition from playbooks
        if (-not $global:Playbooks -or -not $global:Playbooks.playbooks.Provisioning.$wizardName) {
            Write-Log "Wizard '$wizardName' not found in playbooks" "ERROR"
            return
        }
        
        $wizard = $global:Playbooks.playbooks.Provisioning.$wizardName
        Write-Log "Starting provisioning wizard: $($wizard.name)" "WIZARD"
        
        # Create wizard window
        $wizardXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="$($wizard.name)" Height="600" Width="800"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Wizard Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Name="WizardTitle" Text="$($wizard.name)" FontSize="20" FontWeight="Bold"/>
            <TextBlock Name="WizardDesc" Text="$($wizard.description)" FontSize="12" Foreground="#666"/>
            <TextBlock Name="StepIndicator" Text="Step 1 of X" FontSize="10" Margin="0,5,0,0"/>
        </StackPanel>
        
        <!-- Progress Bar -->
        <ProgressBar Name="WizardProgress" Grid.Row="1" Height="8" Margin="0,0,0,20" Value="0"/>
        
        <!-- Wizard Content -->
        <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
            <StackPanel Name="WizardContent" Margin="0,0,0,20"/>
        </ScrollViewer>
        
        <!-- Wizard Buttons -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Name="BackBtn" Content="Back" Width="100" Margin="0,0,10,0" IsEnabled="False"/>
            <Button Name="NextBtn" Content="Next" Width="100" Margin="0,0,10,0"/>
            <Button Name="CancelBtn" Content="Cancel" Width="100"/>
        </StackPanel>
    </Grid>
</Window>
"@
        
        $wizardWindow = [Windows.Markup.XamlReader]::Parse($wizardXaml)
        
        # Bind controls
        $wizardTitle = $wizardWindow.FindName("WizardTitle")
        $wizardDesc = $wizardWindow.FindName("WizardDesc")
        $stepIndicator = $wizardWindow.FindName("StepIndicator")
        $wizardProgress = $wizardWindow.FindName("WizardProgress")
        $wizardContent = $wizardWindow.FindName("WizardContent")
        $backBtn = $wizardWindow.FindName("BackBtn")
        $nextBtn = $wizardWindow.FindName("NextBtn")
        $cancelBtn = $wizardWindow.FindName("CancelBtn")
        
        # Initialize wizard state
        $wizardState = @{
            wizard = $wizard
            currentStep = 1
            totalSteps = $wizard.wizard_steps.Count
            data = @{}
        }
        
        # Update step indicator and progress
        $stepIndicator.Text = "Step $($wizardState.currentStep) of $($wizardState.totalSteps)"
        $wizardProgress.Maximum = $wizardState.totalSteps
        $wizardProgress.Value = 1
        
        # Load current step
        Show-WizardStep -wizardWindow $wizardWindow -wizardState $wizardState
        
        # Event handlers
        $nextBtn.Add_Click({
            if (Validate-WizardStep -wizardWindow $wizardWindow -wizardState $wizardState) {
                if ($wizardState.currentStep -lt $wizardState.totalSteps) {
                    $wizardState.currentStep++
                    Show-WizardStep -wizardWindow $wizardWindow -wizardState $wizardState
                } else {
                    # Execute wizard
                    Execute-Wizard -wizardState $wizardState
                    $wizardWindow.Close()
                }
            }
        })
        
        $backBtn.Add_Click({
            if ($wizardState.currentStep -gt 1) {
                $wizardState.currentStep--
                Show-WizardStep -wizardWindow $wizardWindow -wizardState $wizardState
            }
        })
        
        $cancelBtn.Add_Click({
            $wizardWindow.Close()
        })
        
        # Show wizard
        [void]$wizardWindow.ShowDialog()
        
    } catch {
        Write-Log "Error showing provisioning wizard: $_" "ERROR"
    }
}

function Show-WizardStep {
    param($wizardWindow, $wizardState)
    
    $currentStepDef = $wizardState.wizard.wizard_steps[$wizardState.currentStep - 1]
    $wizardContent = $wizardWindow.FindName("WizardContent")
    $stepIndicator = $wizardWindow.FindName("StepIndicator")
    $wizardProgress = $wizardWindow.FindName("WizardProgress")
    $backBtn = $wizardWindow.FindName("BackBtn")
    $nextBtn = $wizardWindow.FindName("NextBtn")
    
    # Clear previous content
    $wizardContent.Children.Clear()
    
    # Update indicators
    $stepIndicator.Text = "Step $($wizardState.currentStep) of $($wizardState.totalSteps)"
    $wizardProgress.Value = $wizardState.currentStep
    
    # Update button states
    $backBtn.IsEnabled = ($wizardState.currentStep -gt 1)
    if ($wizardState.currentStep -eq $wizardState.totalSteps) {
        $nextBtn.Content = "Provision"
    } else {
        $nextBtn.Content = "Next"
    }
    
    # Add step title and description
    $stepTitle = New-Object System.Windows.Controls.TextBlock
    $stepTitle.Text = $currentStepDef.name
    $stepTitle.FontSize = 16
    $stepTitle.FontWeight = "Bold"
    $stepTitle.Margin = "0,0,0,10"
    $wizardContent.Children.Add($stepTitle)
    
    $stepDesc = New-Object System.Windows.Controls.TextBlock
    $stepDesc.Text = $currentStepDef.description
    $stepDesc.Margin = "0,0,0,20"
    $stepDesc.TextWrapping = "Wrap"
    $wizardContent.Children.Add($stepDesc)
    
    # Add fields for current step
    foreach ($field in $currentStepDef.fields) {
        $fieldPanel = New-Object System.Windows.Controls.StackPanel
        $fieldPanel.Margin = "0,0,0,15"
        
        # Field label
        $label = New-Object System.Windows.Controls.TextBlock
        $label.Text = $field.description
        if ($field.required) { $label.Text += " *" }
        $label.Margin = "0,0,0,5"
        $fieldPanel.Children.Add($label)
        
        # Field input based on type
        if ($field.type -eq "enum") {
            $comboBox = New-Object System.Windows.Controls.ComboBox
            $comboBox.Name = $field.name
            $comboBox.Width = 300
            $comboBox.HorizontalAlignment = "Left"
            foreach ($value in $field.values) {
                [void]$comboBox.Items.Add($value)
            }
            if ($field.default) {
                $comboBox.SelectedItem = $field.default
            }
            # Restore previous value if exists
            if ($wizardState.data.ContainsKey($field.name)) {
                $comboBox.SelectedItem = $wizardState.data[$field.name]
            }
            $fieldPanel.Children.Add($comboBox)
        } else {
            $textBox = New-Object System.Windows.Controls.TextBox
            $textBox.Name = $field.name
            $textBox.Width = 300
            $textBox.HorizontalAlignment = "Left"
            if ($field.example) {
                $textBox.ToolTip = "Example: $($field.example)"
            }
            # Restore previous value if exists
            if ($wizardState.data.ContainsKey($field.name)) {
                $textBox.Text = $wizardState.data[$field.name]
            }
            $fieldPanel.Children.Add($textBox)
        }
        
        $wizardContent.Children.Add($fieldPanel)
    }
}

function Validate-WizardStep {
    param($wizardWindow, $wizardState)
    
    $currentStepDef = $wizardState.wizard.wizard_steps[$wizardState.currentStep - 1]
    $wizardContent = $wizardWindow.FindName("WizardContent")
    $isValid = $true
    
    # Clear previous data for this step
    foreach ($field in $currentStepDef.fields) {
        if ($wizardState.data.ContainsKey($field.name)) {
            $wizardState.data.Remove($field.name)
        }
    }
    
    # Validate and collect field data
    foreach ($control in $wizardContent.Children) {
        if ($control -is [System.Windows.Controls.StackPanel]) {
            foreach ($child in $control.Children) {
                if ($child.Name -and ($child -is [System.Windows.Controls.TextBox] -or $child -is [System.Windows.Controls.ComboBox])) {
                    $fieldDef = $currentStepDef.fields | Where-Object { $_.name -eq $child.Name }
                    if ($fieldDef) {
                        $value = if ($child -is [System.Windows.Controls.ComboBox]) { $child.SelectedItem } else { $child.Text }
                        
                        # Required field validation
                        if ($fieldDef.required -and [string]::IsNullOrWhiteSpace($value)) {
                            Write-Log "Required field '$($fieldDef.name)' is empty" "ERROR"
                            $isValid = $false
                            continue
                        }
                        
                        # Pattern validation
                        if ($fieldDef.pattern -and $value -and $value -notmatch $fieldDef.pattern) {
                            Write-Log "Field '$($fieldDef.name)' does not match required pattern" "ERROR"
                            $isValid = $false
                            continue
                        }
                        
                        $wizardState.data[$fieldDef.name] = $value
                    }
                }
            }
        }
    }
    
    return $isValid
}

function Execute-Wizard {
    param($wizardState)
    
    try {
        Write-Log "Executing provisioning wizard with collected data" "WIZARD"
        
        # Log collected data
        foreach ($key in $wizardState.data.Keys) {
            Write-Log "  $key = $($wizardState.data[$key])" "WIZARD"
        }
        
        # Execute the wizard steps (for now, just log the commands that would be executed)
        if ($wizardState.wizard.wizard_steps) {
            Write-Log "Wizard would execute the following provisioning sequence:" "WIZARD"
            
            # Build ENT-CRS command based on collected data
            $tid = $TidBox.Text
            $ctag = Update-CTAG
            $sourceAid = $wizardState.data['source_aid']
            $destAid = $wizardState.data['dest_aid']
            $connType = if ($wizardState.data['connection_type']) { $wizardState.data['connection_type'] } else { "2WAY" }
            
            $command = "ENT-CRS-STS1:${tid}:${ctag}::${sourceAid},${destAid},${connType};"
            Write-Log "  Command: $command" "WIZARD"
            
            # Here you would actually send the command if connected
            # For now, just show it in the preview
            $PreviewBox.Text = $command
        }
        
        Write-Log "Provisioning wizard completed successfully" "WIZARD"
        
    } catch {
        Write-Log "Error executing wizard: $_" "ERROR"
    }
}

# ---- Populate categories tree
function Populate-CategoryTree {
    $CategoryTree.Items.Clear()
    $CommandBox.Items.Clear()
    $CmdDesc.Text = "Select a system and category to begin"
    
    $Categories.Keys | ForEach-Object {
      $cat=$_
      $catNode=New-Object System.Windows.Controls.TreeViewItem
      $catNode.Header="$cat ($(($Categories[$cat]).Count) commands)"
      foreach($entry in $Categories[$cat]){
        $cmdNode=New-Object System.Windows.Controls.TreeViewItem
        $cmdNode.Header=$entry.Name
        $cmdNode.Tag=$entry
        [void]$catNode.Items.Add($cmdNode)
      }
      [void]$CategoryTree.Items.Add($catNode)
    }
    
    Write-Log "Category tree populated with $($Categories.Keys.Count) categories for $global:CurrentPlatform"
}

# Initial tree population
Populate-CategoryTree

# ---- System dropdown change handler
$SystemBox.Add_SelectionChanged({
    $selected = $SystemBox.SelectedItem
    if ($selected) {
        $newPlatform = $selected.Content
        if ($newPlatform -ne $global:CurrentPlatform) {
            Write-Log "Platform changed from '$global:CurrentPlatform' to '$newPlatform'"
            $global:CurrentPlatform = $newPlatform
            
            # Show loading indicator
            $CmdDesc.Text = "Loading commands for $newPlatform..."
            $CmdDesc.Foreground = "#1f2937"
            
            # Reload commands for new platform
            try {
                $global:Categories = Load-TL1Commands -selectedPlatform $newPlatform
                Populate-CategoryTree
                $CmdDesc.Text = "Platform changed to $newPlatform. Select a category to view commands."
                $CmdDesc.Foreground = "#15803d"  # Green
            } catch {
                Write-Log "Error loading commands for ${newPlatform}: $_" "ERROR"
                $CmdDesc.Text = "Error loading commands for $newPlatform. Check debug log."
                $CmdDesc.Foreground = "#dc2626"  # Red
            }
        }
    }
})

# ---- Tree selection handler
$CategoryTree.Add_SelectedItemChanged({
  $selected = $CategoryTree.SelectedItem
  if ($selected -and $selected.Tag) {
    # Command selected
    $entry = $selected.Tag
    $CommandBox.Items.Clear()
    $cmdItem = New-Object System.Windows.Controls.ComboBoxItem
    $cmdItem.Content = $entry.Name
    $cmdItem.Tag = $entry
    [void]$CommandBox.Items.Add($cmdItem)
    $CommandBox.SelectedIndex = 0
    
    # Show platform-specific description
    $platformInfo = if ($entry.Platform) { " [$($entry.Platform)]" } else { "" }
    $CmdDesc.Text = $entry.Desc + $platformInfo
    
    # Show safety warnings
    if ($entry.SafetyLevel -eq "caution" -or $entry.ServiceAffecting) {
      $warning = ""
      if ($entry.SafetyLevel -eq "caution") { $warning += "[CAUTION] " }
      if ($entry.ServiceAffecting) { $warning += "[SERVICE AFFECTING] " }
      $CmdDesc.Text = $warning + $entry.Desc + $platformInfo
      $CmdDesc.Foreground = "#b91c1c"  # Red warning
    } else {
      $CmdDesc.Foreground = "#6b7280"  # Normal gray
    }
    
    Refresh-OptionalFields
  } elseif ($selected -and $selected.Header -and $Categories.ContainsKey($selected.Header.Split('(')[0].Trim())) {
    # Category selected - populate command dropdown with all commands in category
    $categoryHeader = $selected.Header.Split('(')[0].Trim()  # Remove count from header
    $CommandBox.Items.Clear()
    $CmdDesc.Text = "Select a command from the '$categoryHeader' category for $global:CurrentPlatform"
    foreach($entry in $Categories[$categoryHeader]) {
      $cmdItem = New-Object System.Windows.Controls.ComboBoxItem
      $cmdItem.Content = $entry.Name
      $cmdItem.Tag = $entry
      [void]$CommandBox.Items.Add($cmdItem)
    }
  }
})

# ---- Command dropdown handler
$CommandBox.Add_SelectionChanged({
  $selected = $CommandBox.SelectedItem
  if ($selected -and $selected.Tag) {
    $entry = $selected.Tag
    
    # Show platform-specific description
    $platformInfo = if ($entry.Platform) { " [$($entry.Platform)]" } else { "" }
    $CmdDesc.Text = $entry.Desc + $platformInfo
    
    # Show safety warnings
    if ($entry.SafetyLevel -eq "caution" -or $entry.ServiceAffecting) {
      $warning = ""
      if ($entry.SafetyLevel -eq "caution") { $warning += "[CAUTION] " }
      if ($entry.ServiceAffecting) { $warning += "[SERVICE AFFECTING] " }
      $CmdDesc.Text = $warning + $entry.Desc + $platformInfo
      $CmdDesc.Foreground = "#b91c1c"  # Red warning
    } else {
      $CmdDesc.Foreground = "#6b7280"  # Normal gray
    }
    
    Refresh-OptionalFields
    Update-Preview
  }
})

# ---- Parameter fields with enhanced PDF information
function Refresh-OptionalFields{
  $OptionalPanel.Children.Clear()
  $sel=$CommandBox.SelectedItem
  if(-not $sel){return}
  $entry=$sel.Tag
  if(-not $entry){return}
  
  # Show source information if from PDF
  if ($entry.SourceFile) {
    $sourceHeader=New-Object System.Windows.Controls.TextBlock
    $platformInfo = if ($entry.Platform) { " ($($entry.Platform))" } else { "" }
    $sourceHeader.Text="Source: $($entry.SourceFile)$platformInfo"
    $sourceHeader.FontStyle="Italic"
    $sourceHeader.Foreground="#6b7280"
    $sourceHeader.FontSize=10
    $sourceHeader.Margin="0,0,0,8"
    [void]$OptionalPanel.Children.Add($sourceHeader)
  }
  
  # Show detailed description if available
  if ($entry.DetailedDesc -and $entry.DetailedDesc.Trim() -ne "") {
    $detailHeader=New-Object System.Windows.Controls.TextBlock
    $detailHeader.Text="Detailed Description:"
    $detailHeader.FontWeight="Bold"
    $detailHeader.Foreground="#1f2937"
    [void]$OptionalPanel.Children.Add($detailHeader)
    
    $detailText=New-Object System.Windows.Controls.TextBlock
    $detailText.Text=$entry.DetailedDesc
    $detailText.TextWrapping="Wrap"
    $detailText.Foreground="#374151"
    $detailText.Margin="0,2,0,8"
    [void]$OptionalPanel.Children.Add($detailText)
  }
  
  # Show restrictions if available
  if ($entry.Restrictions -and $entry.Restrictions.Trim() -ne "") {
    $restrHeader=New-Object System.Windows.Controls.TextBlock
    $restrHeader.Text="Restrictions:"
    $restrHeader.FontWeight="Bold"
    $restrHeader.Foreground="#dc2626"
    [void]$OptionalPanel.Children.Add($restrHeader)
    
    $restrText=New-Object System.Windows.Controls.TextBlock
    $restrText.Text=$entry.Restrictions
    $restrText.TextWrapping="Wrap"
    $restrText.Foreground="#dc2626"
    $restrText.Margin="0,2,0,8"
    [void]$OptionalPanel.Children.Add($restrText)
  }
  
  # Add required parameters first
  if ($entry.Required -and $entry.Required.Count -gt 0) {
    $reqHeader=New-Object System.Windows.Controls.TextBlock
    $reqHeader.Text="Required Parameters:"
    $reqHeader.FontWeight="Bold"
    $reqHeader.Foreground="#b91c1c"
    $reqHeader.Margin="0,4,0,4"
    [void]$OptionalPanel.Children.Add($reqHeader)
    
    foreach($name in $entry.Required) {
      $sp=New-Object System.Windows.Controls.StackPanel; $sp.Orientation="Vertical"; $sp.Margin="0,0,0,8"
      
      # Parameter name and input
      $inputSp=New-Object System.Windows.Controls.StackPanel; $inputSp.Orientation="Horizontal"
      $lbl=New-Object System.Windows.Controls.TextBlock; 
      $lbl.Text="$name="; $lbl.FontWeight="Bold"; $lbl.Width=80
      
      # Create appropriate input control based on paramSchema
      $inputControl = $null
      $paramSchema = $null
      if ($entry.ParamSchema -and $entry.ParamSchema.$name) {
        $paramSchema = $entry.ParamSchema.$name
        
        if ($paramSchema.type -eq "enum") {
          # Create ComboBox for enum types
          $cb = New-Object System.Windows.Controls.ComboBox
          $cb.Width = 300
          $cb.Margin = "6,0,0,0"
          $cb.BorderBrush = "#dc2626"  # Red border for required
          
          # Add enum values
          if ($paramSchema.values) {
            foreach ($value in $paramSchema.values) {
              [void]$cb.Items.Add($value)
            }
          }
          
          # Set default if specified
          if ($paramSchema.default) {
            $cb.SelectedItem = $paramSchema.default
          }
          
          $cb.Add_SelectionChanged({ Update-Preview })
          $inputControl = $cb
          
        } elseif ($paramSchema.type -eq "password") {
          # Create PasswordBox for password types
          $pb = New-Object System.Windows.Controls.PasswordBox
          $pb.Width = 300
          $pb.Margin = "6,0,0,0" 
          $pb.BorderBrush = "#dc2626"
          $pb.Add_PasswordChanged({ Update-Preview })
          $inputControl = $pb
          
        } else {
          # Create TextBox for other types
          $tb = New-Object System.Windows.Controls.TextBox
          $tb.Width = 300
          $tb.Margin = "6,0,0,0"
          $tb.BorderBrush = "#dc2626"  # Red border for required
          
          # Set placeholder or example if available
          if ($paramSchema.example) {
            $tb.Text = $paramSchema.example
            $tb.Foreground = "#9ca3af"  # Gray for placeholder
            $tb.Add_GotFocus({
              if ($this.Foreground.ToString() -eq "#FF9CA3AF") {
                $this.Text = ""
                $this.Foreground = "#000000"
              }
            })
            $tb.Add_LostFocus({
              if ($this.Text -eq "") {
                $this.Text = $paramSchema.example
                $this.Foreground = "#9ca3af"
              }
            })
          }
          
          $tb.Add_TextChanged({ Update-Preview })
          $inputControl = $tb
        }
      } else {
        # Fallback to TextBox if no schema
        $tb = New-Object System.Windows.Controls.TextBox
        $tb.Width = 300
        $tb.Margin = "6,0,0,0"
        $tb.BorderBrush = "#dc2626"  # Red border for required
        $tb.Add_TextChanged({ Update-Preview })
        $inputControl = $tb
      }
      
      [void]$inputSp.Children.Add($lbl)
      [void]$inputSp.Children.Add($inputControl)
      [void]$sp.Children.Add($inputSp)
      
      # Show detailed parameter description
      $description = ""
      if ($paramSchema -and $paramSchema.description) {
        $description = $paramSchema.description
      } elseif ($entry.Parameters -and $entry.Parameters.$name) {
        $description = $entry.Parameters.$name
      }
      
      if ($description) {
        $paramDesc=New-Object System.Windows.Controls.TextBlock
        $paramDesc.Text = $description
        $paramDesc.TextWrapping="Wrap"
        $paramDesc.FontSize=10
        $paramDesc.Foreground="#6b7280"
        $paramDesc.Margin="86,2,0,0"  # Indent to align with input
        [void]$sp.Children.Add($paramDesc)
      }
      
      [void]$OptionalPanel.Children.Add($sp)
    }
  }
  
  # Add optional parameters
  if ($entry.Optional -and $entry.Optional.Count -gt 0) {
    if ($entry.Required -and $entry.Required.Count -gt 0) {
      $spacer=New-Object System.Windows.Controls.TextBlock; $spacer.Text=""; $spacer.Height=8
      [void]$OptionalPanel.Children.Add($spacer)
    }
    
    $optHeader=New-Object System.Windows.Controls.TextBlock
    $optHeader.Text="Optional Parameters:"
    $optHeader.FontWeight="Bold"
    $optHeader.Foreground="#6b7280"
    $optHeader.Margin="0,4,0,4"
    [void]$OptionalPanel.Children.Add($optHeader)
    
    foreach($name in $entry.Optional) {
      $sp=New-Object System.Windows.Controls.StackPanel; $sp.Orientation="Vertical"; $sp.Margin="0,0,0,8"
      
      # Parameter name and input
      $inputSp=New-Object System.Windows.Controls.StackPanel; $inputSp.Orientation="Horizontal"
      $lbl=New-Object System.Windows.Controls.TextBlock; 
      $lbl.Text="$name="; $lbl.Width=80
      
      # Create appropriate input control based on paramSchema
      $inputControl = $null
      $paramSchema = $null
      if ($entry.ParamSchema -and $entry.ParamSchema.$name) {
        $paramSchema = $entry.ParamSchema.$name
        
        if ($paramSchema.type -eq "enum") {
          # Create ComboBox for enum types
          $cb = New-Object System.Windows.Controls.ComboBox
          $cb.Width = 300
          $cb.Margin = "6,0,0,0"
          
          # Add enum values
          if ($paramSchema.values) {
            foreach ($value in $paramSchema.values) {
              [void]$cb.Items.Add($value)
            }
          }
          
          # Set default if specified
          if ($paramSchema.default) {
            $cb.SelectedItem = $paramSchema.default
          }
          
          $cb.Add_SelectionChanged({ Update-Preview })
          $inputControl = $cb
          
        } else {
          # Create TextBox for other types
          $tb = New-Object System.Windows.Controls.TextBox
          $tb.Width = 300
          $tb.Margin = "6,0,0,0"
          
          # Set placeholder or default if available
          if ($paramSchema.default) {
            $tb.Text = $paramSchema.default
          } elseif ($paramSchema.example) {
            $tb.Text = $paramSchema.example
            $tb.Foreground = "#9ca3af"  # Gray for placeholder
            $tb.Add_GotFocus({
              if ($this.Foreground.ToString() -eq "#FF9CA3AF") {
                $this.Text = ""
                $this.Foreground = "#000000"
              }
            })
            $tb.Add_LostFocus({
              if ($this.Text -eq "") {
                if ($paramSchema.example) {
                  $this.Text = $paramSchema.example
                  $this.Foreground = "#9ca3af"
                }
              }
            })
          }
          
          $tb.Add_TextChanged({ Update-Preview })
          $inputControl = $tb
        }
      } else {
        # Fallback to TextBox if no schema
        $tb = New-Object System.Windows.Controls.TextBox
        $tb.Width = 300
        $tb.Margin = "6,0,0,0"
        $tb.Add_TextChanged({ Update-Preview })
        $inputControl = $tb
      }
      
      [void]$inputSp.Children.Add($lbl)
      [void]$inputSp.Children.Add($inputControl)
      [void]$sp.Children.Add($inputSp)
      
      # Show detailed parameter description
      $description = ""
      if ($paramSchema -and $paramSchema.description) {
        $description = $paramSchema.description
      } elseif ($entry.Parameters -and $entry.Parameters.$name) {
        $description = $entry.Parameters.$name
      }
      
      if ($description) {
        $paramDesc=New-Object System.Windows.Controls.TextBlock
        $paramDesc.Text = $description
        $paramDesc.TextWrapping="Wrap"
        $paramDesc.FontSize=10
        $paramDesc.Foreground="#6b7280"
        $paramDesc.Margin="86,2,0,0"  # Indent to align with input
        [void]$sp.Children.Add($paramDesc)
      }
      
      [void]$OptionalPanel.Children.Add($sp)
    }
  }
  
  # Show syntax if available
  if ($entry.Syntax -and $entry.Syntax.Trim() -ne "") {
    $spacer=New-Object System.Windows.Controls.TextBlock; $spacer.Text=""; $spacer.Height=8
    [void]$OptionalPanel.Children.Add($spacer)
    
    $syntaxHeader=New-Object System.Windows.Controls.TextBlock
    $syntaxHeader.Text="Syntax:"
    $syntaxHeader.FontWeight="Bold"
    $syntaxHeader.Foreground="#1f2937"
    [void]$OptionalPanel.Children.Add($syntaxHeader)
    
    $syntaxText=New-Object System.Windows.Controls.TextBlock
    $syntaxText.Text=$entry.Syntax
    $syntaxText.FontFamily="Consolas"
    $syntaxText.FontSize=11
    $syntaxText.Foreground="#374151"
    $syntaxText.TextWrapping="Wrap"
    $syntaxText.Margin="0,2,0,0"
    [void]$OptionalPanel.Children.Add($syntaxText)
  }
  
  # Show response format if available
  if ($entry.ResponseFormat -and $entry.ResponseFormat.Trim() -ne "") {
    $spacer=New-Object System.Windows.Controls.TextBlock; $spacer.Text=""; $spacer.Height=8
    [void]$OptionalPanel.Children.Add($spacer)
    
    $respHeader=New-Object System.Windows.Controls.TextBlock
    $respHeader.Text="Response Format:"
    $respHeader.FontWeight="Bold"
    $respHeader.Foreground="#1f2937"
    [void]$OptionalPanel.Children.Add($respHeader)
    
    $respText=New-Object System.Windows.Controls.TextBlock
    $respText.Text=$entry.ResponseFormat
    $respText.FontFamily="Consolas"
    $respText.FontSize=10
    $respText.Foreground="#6b7280"
    $respText.TextWrapping="Wrap"
    $respText.Margin="0,2,0,0"
    [void]$OptionalPanel.Children.Add($respText)
  }
}
function Build-OptionalList{
  $pairs=@()
  foreach($child in $OptionalPanel.Children){
    if($child -is [System.Windows.Controls.StackPanel]){
      # Look for nested input StackPanel
      foreach($nestedChild in $child.Children) {
        if($nestedChild -is [System.Windows.Controls.StackPanel] -and $nestedChild.Children.Count -ge 2){
          $k=$nestedChild.Children[0].Text.Trim('=')
          $v=$nestedChild.Children[1].Text
          if($v -and $v.Trim() -ne ""){ $pairs+=$v.Trim() }  # Just the value, not key=value
          break  # Only process first input panel per container
        }
      }
    }
  }
  ($pairs -join ",")
}

# ---- Preview builder  <CMD>:<TID>:<AID>:<CTAG>::op1,op2,...;
function Update-Preview{
  $cmd= if($CommandBox.SelectedItem){ $CommandBox.SelectedItem.Content } else { "" }
  $tid=$TidBox.Text; $aid=$AidBox.Text; $ctag=$CtagBox.Text
  if($Settings.AutoIncrementCTAG -and $CtagAuto.IsChecked -and [string]::IsNullOrWhiteSpace($ctag)){ $CtagBox.Text="1"; $ctag="1" }
  if ($null -eq $tid)  { $tid  = "" }
  if ($null -eq $aid)  { $aid  = "" }
  if ($null -eq $ctag) { $ctag = "" }
  $opt=Build-OptionalList
  $left = "${cmd}:$($tid):$($aid):$($ctag)"
  $right = if([string]::IsNullOrWhiteSpace($opt)) { "" } else { "::" + $opt }
  $PreviewBox.Text = "$left$right;"
}

# ---- Telnet noise cleaner
function Remove-TelnetNoise([byte[]]$bytes){
  $result = New-Object System.Collections.Generic.List[byte]
  for($i=0; $i -lt $bytes.Length; $i++){
    $b = $bytes[$i]
    if ($b -eq 255) { if ($i + 2 -lt $bytes.Length) { $i += 2 }; continue } # IAC + cmd + opt
    if (($b -ge 32 -and $b -le 126) -or $b -in 9,10,13) { [void]$result.Add($b) }
  }
  ,$result.ToArray()
}

# ---- TELNET session state & handlers ----
$global:tl1_client  = $null
$global:tl1_stream  = $null
$global:tl1_writer  = $null

# Connect
$ConnectBtn.Add_Click({
  $destHost = $HostBox.Text
  $destPort = 23
  if ($PortBox.Text -and $PortBox.Text -match '^\d+$') { $destPort = [int]$PortBox.Text }
  if([string]::IsNullOrWhiteSpace($destHost)){ Write-Log "Host/IP is empty." "WARN"; return }
  try{
    $global:tl1_client = [System.Net.Sockets.TcpClient]::new()
    $iar = $global:tl1_client.BeginConnect($destHost, $destPort, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne(1500, $false)) { throw "Connect timeout" }
    $global:tl1_client.EndConnect($iar)
    $global:tl1_stream = $global:tl1_client.GetStream()
    $global:tl1_writer = New-Object System.IO.StreamWriter($global:tl1_stream, [Text.Encoding]::ASCII)
    $global:tl1_writer.NewLine="`r`n"; $global:tl1_writer.AutoFlush=$true
    Write-Log ("Connected to {0}:{1}" -f $destHost, $destPort) "NET"
    $StatusText.Text="Connected"; $StatusText.Foreground="#15803d"
  } catch {
    Write-Log ("Connect failed: {0}" -f $_.Exception.Message) "ERROR"
    $StatusText.Text="Disconnected"; $StatusText.Foreground="#b91c1c"
  }
})

$SendBtn.Add_Click({
  $cmdText=$PreviewBox.Text
  
  # Update settings with current connection info and TID/AID
  $global:Settings.Connection.Host = $HostBox.Text
  $global:Settings.Connection.Port = [int]$PortBox.Text
  $global:Settings.LastUsed.TID = $TidBox.Text
  $global:Settings.LastUsed.AID = $AidBox.Text
  
  if (-not $global:tl1_client -or -not $global:tl1_client.Connected) {
    Write-Log "Not connected. Using one-shot send helper..." "WARN"
    try {
      $sendScript=Join-Path $ScriptDir "send_tl1.ps1"
      if (-not (Test-Path $sendScript)) { throw "send_tl1.ps1 missing" }
      $resp = & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File $sendScript -CommandText $cmdText -Host $HostBox.Text -Port ([int]$PortBox.Text)
      if ($resp) { foreach($line in $resp -split "`r?`n"){ if($line){ $ConsoleBox.AppendText("$line`r`n") } } $ConsoleBox.ScrollToEnd() }
      Write-Log "One-shot send complete." "SEND"
      
      # Increment CTAG and save settings after successful send
      $newCTAG = Update-CTAG
      $CtagBox.Text = [string]$newCTAG
      
    } catch {
      Write-Log ("Send failed: {0}" -f $_.Exception.Message) "ERROR"
    }
    return
  }
  try {
    Write-Log ("SEND: {0}" -f $cmdText) "SEND"
    # send without newline
    $null=$global:tl1_writer.Write($cmdText)
    # read raw bytes briefly; clean telnet noise
    $sw=[Diagnostics.Stopwatch]::StartNew()
    $ms = New-Object System.IO.MemoryStream
    $tmp = New-Object byte[] 8192
    while($sw.ElapsedMilliseconds -lt 1500){
      if($global:tl1_stream.DataAvailable){
        $n=$global:tl1_stream.Read($tmp,0,$tmp.Length)
        if($n -gt 0){ $ms.Write($tmp,0,$n) }
      } else { Start-Sleep -Milliseconds 50 }
    }
    $raw = $ms.ToArray()
    $clean = Remove-TelnetNoise $raw
    $resp = [Text.Encoding]::ASCII.GetString($clean)
    if([string]::IsNullOrWhiteSpace($resp)){ $resp = "<no response>" }
    foreach($line in $resp -split "`r?`n"){ if($line){ $ConsoleBox.AppendText("$line`r`n") } }
    $ConsoleBox.ScrollToEnd()
    
    # Increment CTAG and save settings after successful send
    $newCTAG = Update-CTAG
    $CtagBox.Text = [string]$newCTAG
    
  } catch {
    Write-Log ("Send failed: {0}" -f $_.Exception.Message) "ERROR"
  }
})

# Disconnect
$DisconnectBtn.Add_Click({
  try{
    if($global:tl1_client -and $global:tl1_client.Connected){ $global:tl1_client.Close() }
    $global:tl1_client=$null; $global:tl1_stream=$null; $global:tl1_writer=$null
    Write-Log "Disconnected." "NET"
  } finally {
    $StatusText.Text="Disconnected"; $StatusText.Foreground="#b91c1c"
  }
})

# Troubleshooting button event handler
$TroubleshootBtn.Add_Click({
  try {
    $tid = $TidBox.Text
    $aid = $AidBox.Text
    if([string]::IsNullOrWhiteSpace($tid) -or [string]::IsNullOrWhiteSpace($aid)) {
      Write-Log "TID and AID required for troubleshooting." "ERROR"
      return
    }
    
    # Execute Port_Check playbook
    Invoke-Playbook -playbookName "Port_Check" -tid $tid -aid $aid
  } catch {
    Write-Log "Troubleshooting error: $($_.Exception.Message)" "ERROR"
  }
})

# Provisioning Wizard button event handler
$WizardBtn.Add_Click({
  try {
    # Ensure playbooks are loaded
    if (-not $global:Playbooks) {
      Load-Playbooks
    }
    
    # Launch provisioning wizard
    Show-ProvisioningWizard -wizardName "Cross_Connect_Wizard"
  } catch {
    Write-Log "Wizard error: $($_.Exception.Message)" "ERROR"
  }
})

# Initialize logging system before main GUI
Initialize-StructuredLogging

Write-Log "=== TL1 Command Builder started ===" "BOOT"
[void]$Window.ShowDialog()
