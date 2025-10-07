# Error handling and logging setup
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'

# Version and environment checks
Write-Debug "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Debug "OS Version: $([System.Environment]::OSVersion.Version)"
Write-Debug "Current Directory: $($PWD.Path)"

if ($PSVersionTable.PSVersion.Major -gt 5) {
    Write-Error "This script requires Windows PowerShell 5.1. Current version: $($PSVersionTable.PSVersion)"
    Write-Error "Please run using 'Windows PowerShell' (blue icon) instead of 'PowerShell Core' (black icon)"
    Start-Sleep -Seconds 5
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
    Write-Debug "Loading WPF assemblies..."
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Write-Debug "WPF assemblies loaded successfully"
} catch {
    Write-Error "Failed to load WPF assemblies. Error: $_"
    Write-Error "This might indicate Windows Desktop features are not installed."
    Write-Debug "Stack Trace: $($_.Exception.StackTrace)"
    Write-Host "Press any key to exit..."
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
$LogsDir = Join-Path $AppDataDir "logs"
if (!(Test-Path $LogsDir)) { 
    New-Item -ItemType Directory -Path $LogsDir | Out-Null 
}
$LogFile = Join-Path $LogsDir ("app-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

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

# Simple logger
$global:ConsoleBox=$null
function Write-Log([string]$Message,[string]$Level="INFO"){
  $line="[${((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))}] [$Level] $Message"
  Add-Content -Path $LogFile -Value $line
  if($global:ConsoleBox){ $global:ConsoleBox.AppendText("$line`r`n"); $global:ConsoleBox.ScrollToEnd() }
}

# Load TL1 commands from JSON files and extracted PDF data with platform filtering
function Load-TL1Commands {
    param([string]$selectedPlatform = "SM")  # Default to SM
    
    $AllCommands = [ordered]@{}
    $platformMap = @{
        "1603 SM" = @("SM", "1603_SM")
        "16034 SMX" = @("SMX", "16034_SMX")
    }
    
    $platformIds = $platformMap[$selectedPlatform]
    if (-not $platformIds) {
        # Default mapping if not found
        $platformIds = if ($selectedPlatform -like "*SMX*") { @("SMX", "16034_SMX") } else { @("SM", "1603_SM") }
    }
    
    Write-Log "Loading commands for platform: $selectedPlatform (IDs: $($platformIds -join ', '))"
    
    # First load from extracted PDF data (comprehensive documentation)
    $ExtractedDir = Join-Path $RootDir "data\extracted_commands"
    if (Test-Path $ExtractedDir) {
        Write-Log "Loading extracted PDF command data from $ExtractedDir"
        
        # Load platform-specific extracted data
        $platformFile = Join-Path $ExtractedDir "$($platformIds[1])_commands.json"
        if (Test-Path $platformFile) {
            try {
                $content = Get-Content $platformFile -Raw -Encoding UTF8 | ConvertFrom-Json
                Write-Log "Processing platform-specific file: $($platformIds[1])_commands.json"
                
                # Process extracted PDF data structure
                $content.PSObject.Properties | ForEach-Object {
                    $categoryName = $_.Name
                    $commands = $_.Value
                    
                    if (-not $AllCommands.Contains($categoryName)) {
                        $AllCommands[$categoryName] = @()
                    }
                    
                    $commands | ForEach-Object {
                        $cmd = $_
                        $requiredParams = @()
                        $optionalParams = @()
                        
                        # Parse parameters from detailed parameter info
                        if ($cmd.parameters) {
                            $cmd.parameters.PSObject.Properties | ForEach-Object {
                                $paramName = $_.Name
                                $paramDesc = $_.Value
                                
                                # Determine if required based on syntax and description
                                if ($cmd.syntax -and $cmd.syntax -like "*[$paramName]*") {
                                    if ($cmd.syntax -like "*:$paramName:*" -or $paramDesc -like "*required*") {
                                        $requiredParams += $paramName
                                    } else {
                                        $optionalParams += $paramName
                                    }
                                } else {
                                    $optionalParams += $paramName
                                }
                            }
                        }
                        
                        $AllCommands[$categoryName] += @{
                            Name = $cmd.command_code
                            Desc = $cmd.description
                            DetailedDesc = $cmd.function
                            Required = $requiredParams
                            Optional = $optionalParams
                            Parameters = $cmd.parameters
                            Syntax = if ($cmd.syntax) { $cmd.syntax } else { "" }
                            Restrictions = if ($cmd.restrictions) { $cmd.restrictions } else { "" }
                            ResponseFormat = if ($cmd.response_format) { $cmd.response_format } else { "" }
                            SafetyLevel = if ($cmd.safety_level) { $cmd.safety_level } else { "safe" }
                            ServiceAffecting = if ($cmd.service_affecting) { $cmd.service_affecting } else { $false }
                            SourceFile = if ($cmd.source_file) { $cmd.source_file } else { "" }
                            Platform = $selectedPlatform
                        }
                    }
                }
            } catch {
                Write-Log "Error loading platform file $platformFile: $_" "ERROR"
            }
        }
    }
    
    # Then load from shared TL1 catalogs (supplement any missing) with platform filtering
    $TL1Dir = Join-Path $RootDir "data\shared\catalogs\tl1"
    if (Test-Path $TL1Dir) {
        Write-Log "Loading shared TL1 catalogs from $TL1Dir with platform filter"
        Get-ChildItem -Path $TL1Dir -Filter "*.json" | ForEach-Object {
            try {
                $content = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                Write-Log "Processing shared catalog: $($_.Name)"
                
                # Handle different JSON structures with platform filtering
                if ($content.commands -and $content.commands -is [PSCustomObject]) {
                    # Object with categories
                    $content.commands.PSObject.Properties | ForEach-Object {
                        $categoryName = $_.Name
                        $commands = $_.Value
                        
                        if (-not $AllCommands.Contains($categoryName)) {
                            $AllCommands[$categoryName] = @()
                        }
                        
                        # Filter and add commands for selected platform
                        $commands | ForEach-Object {
                            $cmd = $_
                            
                            # Check if command is applicable to selected platform
                            $isApplicable = $false
                            if ($cmd.platforms) {
                                $isApplicable = $platformIds | Where-Object { $cmd.platforms -contains $_ }
                            } elseif ($cmd.applicable_models) {
                                $isApplicable = $platformIds | Where-Object { $cmd.applicable_models -contains $_ }
                            } else {
                                # If no platform info, include for all platforms
                                $isApplicable = $true
                            }
                            
                            if ($isApplicable) {
                                # Only add if command doesn't already exist from PDF extraction
                                $exists = $AllCommands[$categoryName] | Where-Object { $_.Name -eq $cmd.command_code }
                                if (-not $exists) {
                                    $AllCommands[$categoryName] += @{
                                        Name = $cmd.command_code
                                        Desc = $cmd.description
                                        Required = if ($cmd.parameters.required) { $cmd.parameters.required } else { @() }
                                        Optional = if ($cmd.parameters.optional) { $cmd.parameters.optional } else { @() }
                                        Syntax = if ($cmd.syntax) { $cmd.syntax } else { "" }
                                        SafetyLevel = if ($cmd.safety_level) { $cmd.safety_level } else { "safe" }
                                        ServiceAffecting = if ($cmd.service_affecting) { $cmd.service_affecting } else { $false }
                                        Platform = $selectedPlatform
                                    }
                                }
                            }
                        }
                    }
                } elseif ($content -is [Array]) {
                    # Array format with platform filtering
                    $content | ForEach-Object {
                        $cmd = $_
                        
                        # Check if command is applicable to selected platform
                        $isApplicable = $false
                        if ($cmd.platforms) {
                            $isApplicable = $platformIds | Where-Object { $cmd.platforms -contains $_ }
                        } elseif ($cmd.applicable_models) {
                            $isApplicable = $platformIds | Where-Object { $cmd.applicable_models -contains $_ }
                        } else {
                            $isApplicable = $true
                        }
                        
                        if ($isApplicable) {
                            $categoryName = if ($cmd.category) { $cmd.category } else { "General" }
                            
                            if (-not $AllCommands.Contains($categoryName)) {
                                $AllCommands[$categoryName] = @()
                            }
                            
                            # Only add if command doesn't already exist
                            $exists = $AllCommands[$categoryName] | Where-Object { $_.Name -eq $cmd.command_code }
                            if (-not $exists) {
                                $requiredParams = @()
                                $optionalParams = @()
                                
                                if ($cmd.parameters) {
                                    $cmd.parameters.PSObject.Properties | ForEach-Object {
                                        if ($_.Value.required -eq $true) {
                                            $requiredParams += $_.Name
                                        } else {
                                            $optionalParams += $_.Name
                                        }
                                    }
                                }
                                
                                $AllCommands[$categoryName] += @{
                                    Name = $cmd.command_code
                                    Desc = if ($cmd.command_name) { $cmd.command_name } else { $cmd.description }
                                    Required = $requiredParams
                                    Optional = $optionalParams
                                    Syntax = if ($cmd.syntax) { $cmd.syntax } else { "" }
                                    SafetyLevel = if ($cmd.safety_level) { $cmd.safety_level } else { "safe" }
                                    ServiceAffecting = if ($cmd.service_affecting) { $cmd.service_affecting } else { $false }
                                    Platform = $selectedPlatform
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Log "Error loading shared catalog $($_.Name): $_" "ERROR"
            }
        }
    }
    
    if ($AllCommands.Keys.Count -eq 0) {
        Write-Log "No commands loaded for $selectedPlatform - using fallback" "WARN"
        return @{
            "System Management" = @(
                @{Name="ACT-USER";Desc="Activate User";Required=@("UID");Optional=@("PID");Platform=$selectedPlatform},
                @{Name="CANC-USER";Desc="Cancel User Session";Required=@("UID");Optional=@();Platform=$selectedPlatform}
            )
        }
    }
    
    $totalCommands = ($AllCommands.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Write-Log "Loaded $($AllCommands.Keys.Count) categories with $totalCommands total commands for $selectedPlatform"
    return $AllCommands
}

# Initial load with default platform
$global:CurrentPlatform = "1603 SM"
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
              <ComboBoxItem Content="16034 SMX"/>
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
$global:ConsoleBox=$ConsoleBox

# ---- Init defaults
$PortBox.Text = ([string]([int]($Settings.DefaultPort -as [int])))
$HostBox.Text = [string]$Settings.DefaultHost
$StatusText.Text = "Disconnected"
$DebugChk.IsChecked = [bool]$Settings.Debug

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
                Write-Log "Error loading commands for $newPlatform: $_" "ERROR"
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
      $tb=New-Object System.Windows.Controls.TextBox; 
      $tb.Width=300; $tb.Margin="6,0,0,0"
      $tb.BorderBrush="#dc2626"  # Red border for required
      [void]$inputSp.Children.Add($lbl); [void]$inputSp.Children.Add($tb)
      [void]$sp.Children.Add($inputSp)
      
      # Show detailed parameter description if available
      if ($entry.Parameters -and $entry.Parameters.$name) {
        $paramDesc=New-Object System.Windows.Controls.TextBlock
        $paramDesc.Text=$entry.Parameters.$name
        $paramDesc.TextWrapping="Wrap"
        $paramDesc.FontSize=10
        $paramDesc.Foreground="#6b7280"
        $paramDesc.Margin="86,2,0,0"  # Indent to align with input
        [void]$sp.Children.Add($paramDesc)
      }
      
      [void]$OptionalPanel.Children.Add($sp)
      $tb.Add_TextChanged({ Update-Preview })
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
      $tb=New-Object System.Windows.Controls.TextBox; 
      $tb.Width=300; $tb.Margin="6,0,0,0"
      [void]$inputSp.Children.Add($lbl); [void]$inputSp.Children.Add($tb)
      [void]$sp.Children.Add($inputSp)
      
      # Show detailed parameter description if available
      if ($entry.Parameters -and $entry.Parameters.$name) {
        $paramDesc=New-Object System.Windows.Controls.TextBlock
        $paramDesc.Text=$entry.Parameters.$name
        $paramDesc.TextWrapping="Wrap"
        $paramDesc.FontSize=10
        $paramDesc.Foreground="#6b7280"
        $paramDesc.Margin="86,2,0,0"  # Indent to align with input
        [void]$sp.Children.Add($paramDesc)
      }
      
      [void]$OptionalPanel.Children.Add($sp)
      $tb.Add_TextChanged({ Update-Preview })
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
          if($v -and $v.Trim() -ne ""){ $pairs+=("{0}={1}" -f $k,$v.Trim()) }
          break  # Only process first input panel per container
        }
      }
    }
  }
  ($pairs -join ",")
}

# ---- Preview builder  <CMD>::<TID>:<AID>:<CTAG>::op1=val,...;
function Update-Preview{
  $cmd= if($CommandBox.SelectedItem){ $CommandBox.SelectedItem.Content } else { "" }
  $tid=$TidBox.Text; $aid=$AidBox.Text; $ctag=$CtagBox.Text
  if($Settings.AutoIncrementCTAG -and $CtagAuto.IsChecked -and [string]::IsNullOrWhiteSpace($ctag)){ $CtagBox.Text="1"; $ctag="1" }
  if ($null -eq $tid)  { $tid  = "" }
  if ($null -eq $aid)  { $aid  = "" }
  if ($null -eq $ctag) { $ctag = "" }
  $opt=Build-OptionalList
  $left = "$cmd::$($tid):$($aid):$($ctag)"
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

# Send (session if connected; else one-shot helper)
$SendBtn.Add_Click({
  $cmdText=$PreviewBox.Text
  if (-not $global:tl1_client -or -not $global:tl1_client.Connected) {
    Write-Log "Not connected. Using one-shot send helper..." "WARN"
    try {
      $sendScript=Join-Path $ScriptDir "send_tl1.ps1"
      if (-not (Test-Path $sendScript)) { throw "send_tl1.ps1 missing" }
      $resp = & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Sta -File $sendScript -CommandText $cmdText -Host $HostBox.Text -Port ([int]$PortBox.Text)
      if ($resp) { foreach($line in $resp -split "`r?`n"){ if($line){ $ConsoleBox.AppendText("$line`r`n") } } $ConsoleBox.ScrollToEnd() }
      Write-Log "One-shot send complete." "SEND"
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

Write-Log "=== TL1 Command Builder started ===" "BOOT"
[void]$Window.ShowDialog()
