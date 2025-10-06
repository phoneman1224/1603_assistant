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

# Command placeholders (we can load real set later)
$Categories=[ordered]@{
  "System Settings/Maintenance"=@(
    @{Name="ALW-USER";Desc="Allow user";Optional=@("PRM","MASK")},
    @{Name="INH-USER";Desc="Inhibit user";Optional=@("PRM","MASK")},
    @{Name="SET-ATTR";Desc="Set attribute";Optional=@("ATTR","VALUE")},
    @{Name="ABT-OPR";Desc="Abort operation";Optional=@("REASON")},
    @{Name="CONFIG-SYS";Desc="Configure system";Optional=@("MODE")},
    @{Name="CPY-CFG";Desc="Copy config";Optional=@("SRC","DST")}
  )
  "Alarms"=@(
    @{Name="ALM-ACK";Desc="Acknowledge alarm";Optional=@("ALM","COND")},
    @{Name="COND-RPT";Desc="Condition report";Optional=@("TYPE")}
  )
  "Retrieve Information"=@(
    @{Name="RTRV-STAT";Desc="Retrieve status";Optional=@("SCOPE","VERBOSITY")},
    @{Name="RTRV-INV";Desc="Retrieve inventory";Optional=@("FILTER")}
  )
  "Troubleshooting"=@(
    @{Name="CONN-LB";Desc="Loopback connect";Optional=@("TYPE","DUR")},
    @{Name="DGN-PORT";Desc="Diagnostics port";Optional=@("TEST","DUR")},
    @{Name="DISC-LB";Desc="Loopback disconnect";Optional=@("TYPE")},
    @{Name="OPR-TEST";Desc="Operate test";Optional=@("TEST","PATTERN")},
    @{Name="RLS-RES";Desc="Release resource";Optional=@("RES")},
    @{Name="RD-REG";Desc="Read register";Optional=@("REG")},
    @{Name="TST-LOOP";Desc="Test loop";Optional=@("PATTERN","DUR")},
    @{Name="SW-TRAFF";Desc="Switch traffic";Optional=@("MODE")},
    @{Name="CHG-ACCMD-T1";Desc="Change access cmd T1";Optional=@("LEVEL")}
  )
  "Provisioning"=@(
    @{Name="ENT-SRVC";Desc="Enter service";Optional=@("BAND","OPT")},
    @{Name="ED-SRVC";Desc="Edit service";Optional=@("FIELD","VALUE")},
    @{Name="RMV-SRVC";Desc="Remove service";Optional=@("FORCE")},
    @{Name="RST-UNIT";Desc="Reset unit";Optional=@("SOFT","HARD")},
    @{Name="DLT-OBJ";Desc="Delete object";Optional=@("CONFIRM")}
  )
}

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

# ---- Populate categories
$Categories.Keys | ForEach-Object {
  $cat=$_
  $catNode=New-Object System.Windows.Controls.TreeViewItem
  $catNode.Header=$cat
  foreach($entry in $Categories[$cat]){
    $cmdNode=New-Object System.Windows.Controls.TreeViewItem
    $cmdNode.Header=$entry.Name
    $cmdNode.Tag=$entry
    [void]$catNode.Items.Add($cmdNode)
  }
  [void]$CategoryTree.Items.Add($catNode)
}

# ---- Optional fields
function Refresh-OptionalFields{
  $OptionalPanel.Children.Clear()
  $sel=$CommandBox.SelectedItem
  if(-not $sel){return}
  $entry=$sel.Tag
  if(-not $entry){return}
  foreach($name in ($entry.Optional | ForEach-Object { $_ })){
    $sp=New-Object System.Windows.Controls.StackPanel; $sp.Orientation="Horizontal"
    $lbl=New-Object System.Windows.Controls.TextBlock; $lbl.Text="$name=";
    $tb=New-Object System.Windows.Controls.TextBox; $tb.Width=160; $tb.Margin="6,0,12,6"
    [void]$sp.Children.Add($lbl); [void]$sp.Children.Add($tb); [void]$OptionalPanel.Children.Add($sp)
    $tb.Add_TextChanged({ Update-Preview })
  }
}
function Build-OptionalList{
  $pairs=@()
  foreach($child in $OptionalPanel.Children){
    if($child -is [System.Windows.Controls.StackPanel] -and $child.Children.Count -ge 2){
      $k=$child.Children[0].Text.Trim('=')
      $v=$child.Children[1].Text
      if($v -and $v.Trim() -ne ""){ $pairs+=("{0}={1}" -f $k,$v.Trim()) }
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
