# TL1_CommandBuilder.ps1 — Windows WPF TL1 GUI (Telnet) — PS5/PS7-safe
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir
$LogsDir   = Join-Path $RootDir "logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }
$LogFile   = Join-Path $LogsDir ("app-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

# Settings (robust defaults)
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

# Safe window size numbers
$WinWidth  = 1150
$WinHeight = 760
try {
  if ($Settings.Window -and $Settings.Window.Width) {
    $w = $Settings.Window.Width -as [int]; if ($w -and $w -gt 0) { $WinWidth = $w }
  }
  if ($Settings.Window -and $Settings.Window.Height) {
    $h = $Settings.Window.Height -as [int]; if ($h -and $h -gt 0) { $WinHeight = $h }
  }
} catch {}

# Logging
$global:ConsoleBox=$null
function Write-Log([string]$Message,[string]$Level="INFO"){
  $line="[${((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))}] [$Level] $Message"
  Add-Content -Path $LogFile -Value $line
  if($global:ConsoleBox){ $global:ConsoleBox.AppendText("$line`r`n"); $global:ConsoleBox.ScrollToEnd() }
}
function Try-Do([scriptblock]$Block,[string]$Context="RUN"){ try{ & $Block }catch{ Write-Log "$Context failed: $($_.Exception.Message)" "ERROR" } }

# Command registry (placeholders)
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

# --- XAML (uses numeric $WinWidth/$WinHeight) ---
[xml]$xaml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="TL1 Command Builder"
        WindowStartupLocation="CenterScreen"
        Width="${WinWidth}" Height="${WinHeight}"
        Background="#0f1115">
  <DockPanel LastChildFill="True">
    <Border DockPanel.Dock="Left" Width="270" Background="#161a22" BorderBrush="#2a2f3a" BorderThickness="0,0,1,0">
      <StackPanel>
        <TextBlock Text="Categories" Foreground="#cbd5e1" FontWeight="Bold" Margin="10,10,10,6"/>
        <TreeView Name="CategoryTree" Margin="8" Background="#0f1115" Foreground="#e5e7eb" BorderThickness="0"/>
      </StackPanel>
    </Border>

    <Grid Margin="10">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="160"/>
      </Grid.RowDefinitions>

      <!-- Connection bar -->
      <Border Grid.Row="0" Background="#161a22" Padding="8" CornerRadius="8" BorderBrush="#2a2f3a" BorderThickness="1">
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="160"/>
            <ColumnDefinition Width="220"/>
            <ColumnDefinition Width="120"/>
            <ColumnDefinition Width="120"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>

          <StackPanel Orientation="Horizontal" Grid.Column="0" VerticalAlignment="Center" Margin="4,0">
            <TextBlock Text="System:" Foreground="#cbd5e1" Margin="0,0,6,0"/>
            <ComboBox Name="SystemBox" Width="110">
              <ComboBoxItem Content="1603 SM"/>
              <ComboBoxItem Content="16034 SMX"/>
            </ComboBox>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="1" VerticalAlignment="Center" Margin="4,0">
            <TextBlock Text="Host/IP:" Foreground="#cbd5e1" Margin="0,0,6,0"/>
            <TextBox Name="HostBox" Width="150"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="2" VerticalAlignment="Center" Margin="4,0">
            <TextBlock Text="Port:" Foreground="#cbd5e1" Margin="0,0,6,0"/>
            <TextBox Name="PortBox" Width="60"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="3" VerticalAlignment="Center" Margin="4,0">
            <Button Name="ConnectBtn" Content="Connect" Width="80" Margin="0,0,6,0"/>
            <Button Name="DisconnectBtn" Content="Disconnect" Width="90"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Column="4" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="4,0">
            <CheckBox Name="DebugChk" Content="Debug" Foreground="#cbd5e1"/>
            <TextBlock Name="StatusText" Text="Disconnected" Foreground="#fca5a5" Margin="10,0,0,0"/>
          </StackPanel>
        </Grid>
      </Border>

      <!-- Builder -->
      <Border Grid.Row="1" Background="#161a22" Padding="8" CornerRadius="8" BorderBrush="#2a2f3a" BorderThickness="1" Margin="0,10,0,10">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,8">
            <TextBlock Text="Command:" Foreground="#cbd5e1" Margin="0,0,6,0"/>
            <ComboBox Name="CommandBox" Width="240"/>
            <TextBlock Text="Desc:" Foreground="#94a3b8" Margin="20,0,6,0"/>
            <TextBlock Name="CmdDesc" Foreground="#94a3b8"/>
          </StackPanel>

          <StackPanel Orientation="Horizontal" Grid.Row="1" Margin="0,0,0,8">
            <TextBlock Text="TID:" Foreground="#cbd5e1"/>
            <TextBox Name="TidBox" Width="100" Margin="6,0,20,0"/>
            <TextBlock Text="AID:" Foreground="#cbd5e1"/>
            <TextBox Name="AidBox" Width="120" Margin="6,0,20,0"/>
            <TextBlock Text="CTAG:" Foreground="#cbd5e1"/>
            <TextBox Name="CtagBox" Width="80" Margin="6,0,20,0"/>
            <CheckBox Name="CtagAuto" Content="Auto-increment" Foreground="#cbd5e1" IsChecked="True"/>
          </StackPanel>

          <StackPanel Grid.Row="2">
            <TextBlock Text="Optional Parameters (skip freely — [] means optional):" Foreground="#cbd5e1" Margin="0,0,0,6"/>
            <WrapPanel Name="OptionalPanel"/>
          </StackPanel>

          <StackPanel Grid.Row="3" Orientation="Vertical" Margin="0,10,0,0">
            <TextBlock Text="Preview:" Foreground="#cbd5e1"/>
            <TextBox Name="PreviewBox" Height="60" IsReadOnly="True" TextWrapping="Wrap" Background="#0f1115" Foreground="#e5e7eb"/>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,8,0,0">
              <Button Name="CopyBtn" Content="Copy" Width="90" Margin="6,0"/>
              <Button Name="SendBtn" Content="Send" Width="90" Margin="6,0"/>
              <Button Name="LogBtn" Content="Log Only" Width="90" Margin="6,0"/>
            </StackPanel>
          </StackPanel>
        </Grid>
      </Border>

      <!-- Console -->
      <TextBox Name="ConsoleBox" Grid.Row="2" Background="#0b0e14" Foreground="#e5e7eb"
               FontFamily="Consolas" FontSize="12" TextWrapping="Wrap"
               VerticalScrollBarVisibility="Auto" IsReadOnly="True"/>
    </Grid>
  </DockPanel>
</Window>
"@

# Build visual tree
$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Bind controls
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

# Init defaults
$PortBox.Text = ([string]([int]($Settings.DefaultPort -as [int])))
$HostBox.Text = [string]$Settings.DefaultHost
$StatusText.Text = "Disconnected"
$DebugChk.IsChecked = [bool]$Settings.Debug

# Populate categories
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

# Optional fields rendering
function Refresh-OptionalFields{
  $OptionalPanel.Children.Clear()
  $sel=$CommandBox.SelectedItem
  if(-not $sel){return}
  $entry=$sel.Tag
  if(-not $entry){return}
  foreach($name in ($entry.Optional | ForEach-Object { $_ })){
    $sp=New-Object System.Windows.Controls.StackPanel; $sp.Orientation="Horizontal"
    $lbl=New-Object System.Windows.Controls.TextBlock; $lbl.Text="$name="; $lbl.Foreground="White"
    $tb=New-Object System.Windows.Controls.TextBox; $tb.Width=140; $tb.Margin="6,0,12,6"
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
  return ($pairs -join ",")
}

# Build TL1 string  <CMD>::<TID>:<AID>:<CTAG>::op1=val,...;
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

# Selection events
$CategoryTree.Add_SelectedItemChanged({
  $item=$CategoryTree.SelectedItem
  if($item -and $item.Tag){
    $CommandBox.Items.Clear()
    $entry=$item.Tag
    $cbItem=New-Object System.Windows.Controls.ComboBoxItem
    $cbItem.Content=$entry.Name
    $cbItem.Tag=$entry
    [void]$CommandBox.Items.Add($cbItem)
    $CommandBox.SelectedIndex=0
    $CmdDesc.Text=$entry.Desc
    Refresh-OptionalFields
    Update-Preview
  }
})
$CommandBox.Add_SelectionChanged({
  $CmdDesc.Text= if($CommandBox.SelectedItem){ $CommandBox.SelectedItem.Tag.Desc } else { "" }
  Refresh-OptionalFields
  Update-Preview
})
$TidBox.Add_TextChanged({ Update-Preview })
$AidBox.Add_TextChanged({ Update-Preview })
$CtagBox.Add_TextChanged({ Update-Preview })
$CtagAuto.Add_Click({ if($CtagAuto.IsChecked -and [string]::IsNullOrWhiteSpace($CtagBox.Text)){ $CtagBox.Text="1" }; Update-Preview })

# ---- TELNET session state & handlers ----
$global:tl1_client  = $null
$global:tl1_stream  = $null
$global:tl1_writer  = $null
$global:tl1_reader  = $null

# Connect
$ConnectBtn.Add_Click({
  $destHost = $HostBox.Text
  $destPort = 23
  if ($PortBox.Text -and $PortBox.Text -match '^\d+$') { $destPort = [int]$PortBox.Text }
  if([string]::IsNullOrWhiteSpace($destHost)){ Write-Log "Host/IP is empty." "WARN"; return }
  try{
    Add-Type -AssemblyName System.Net.Sockets
    $global:tl1_client = New-Object System.Net.Sockets.TcpClient
    $iar = $global:tl1_client.BeginConnect($destHost, $destPort, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne(1500, $false)) { throw "Connect timeout" }
    $global:tl1_client.EndConnect($iar)
    $global:tl1_stream = $global:tl1_client.GetStream()
    $global:tl1_writer = New-Object System.IO.StreamWriter($global:tl1_stream)
    $global:tl1_reader = New-Object System.IO.StreamReader($global:tl1_stream)
    $global:tl1_writer.NewLine="`r`n"; $global:tl1_writer.AutoFlush=$true
    Write-Log ("Connected to {0}:{1}" -f $destHost, $destPort) "NET"
    $StatusText.Text="Connected"; $StatusText.Foreground='LightGreen'
  } catch {
    Write-Log ("Connect failed: {0}" -f $_.Exception.Message) "ERROR"
    $StatusText.Text="Disconnected"; $StatusText.Foreground='#fca5a5'
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
    $null=$global:tl1_writer.WriteLine($cmdText)
    $sw=[Diagnostics.Stopwatch]::StartNew()
    while($sw.ElapsedMilliseconds -lt 1500){
      if($global:tl1_stream.DataAvailable){
        $line=$global:tl1_reader.ReadLine()
        if($line -ne $null){ $ConsoleBox.AppendText("$line`r`n") }
      } else { Start-Sleep -Milliseconds 50 }
    }
    $ConsoleBox.ScrollToEnd()
  } catch {
    Write-Log ("Send failed: {0}" -f $_.Exception.Message) "ERROR"
  }
})

# Disconnect
$DisconnectBtn.Add_Click({
  try{
    if($global:tl1_client -and $global:tl1_client.Connected){ $global:tl1_client.Close() }
    $global:tl1_client=$null; $global:tl1_stream=$null; $global:tl1_writer=$null; $global:tl1_reader=$null
    Write-Log "Disconnected." "NET"
  } finally {
    $StatusText.Text="Disconnected"; $StatusText.Foreground='#fca5a5'
  }
})

Write-Log "=== TL1 Command Builder started ===" "BOOT"
[void]$Window.ShowDialog()
