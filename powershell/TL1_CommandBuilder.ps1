Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir
$LogsDir   = Join-Path $RootDir "logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }
$LogFile   = Join-Path $LogsDir ("app-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

# Settings
$SettingsPath = Join-Path $ScriptDir "appsettings.json"
if (!(Test-Path $SettingsPath)) {
  $default = @{ LogDir="..\\logs"; DefaultHost=""; DefaultPort=23; AutoIncrementCTAG=$true;
                SecureCRTPath=""; Window=@{Width=1150;Height=760}; Debug=$true } | ConvertTo-Json -Depth 5
  $default | Out-File -FilePath $SettingsPath -Encoding UTF8
}
try { $Settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json } catch {
  $Settings = [pscustomobject]@{ LogDir="..\\logs"; DefaultHost=""; DefaultPort=23; AutoIncrementCTAG=$true; SecureCRTPath=""; Window=@{Width=1150;Height=760}; Debug=$true }
}

# Logging helpers
$global:ConsoleBox=$null
function Write-Log([string]$Message,[string]$Level="INFO"){
  $line="[${((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))}] [$Level] $Message"
  Add-Content -Path $LogFile -Value $line
  if($global:ConsoleBox){ $global:ConsoleBox.AppendText("$line`r`n"); $global:ConsoleBox.ScrollToEnd() }
}
function Try-Do([scriptblock]$Block,[string]$Context="RUN"){ try{ & $Block }catch{ Write-Log "$Context failed: $($_.Exception.Message)" "ERROR" } }

# Command registry (placeholder groups; [] optional honored by skipping blanks)
$Categories=[ordered]@{
  "System Settings/Maintenance"=@(@{Name="ALW-USER";Desc="Allow user";Optional=@("PRM","MASK")},@{Name="INH-USER";Desc="Inhibit user";Optional=@("PRM","MASK")},@{Name="SET-ATTR";Desc="Set attribute";Optional=@("ATTR","VALUE")},@{Name="ABT-OPR";Desc="Abort operation";Optional=@("REASON")},@{Name="CONFIG-SYS";Desc="Configure system";Optional=@("MODE")},@{Name="CPY-CFG";Desc="Copy config";Optional=@("SRC","DST")})
  "Alarms"=@(@{Name="ALM-ACK";Desc="Acknowledge alarm";Optional=@("ALM","COND")},@{Name="COND-RPT";Desc="Condition report";Optional=@("TYPE")})
  "Retrieve Information"=@(@{Name="RTRV-STAT";Desc="Retrieve status";Optional=@("SCOPE","VERBOSITY")},@{Name="RTRV-INV";Desc="Retrieve inventory";Optional=@("FILTER")})
  "Troubleshooting"=@(@{Name="CONN-LB";Desc="Loopback connect";Optional=@("TYPE","DUR")},@{Name="DGN-PORT";Desc="Diagnostics port";Optional=@("TEST","DUR")},@{Name="DISC-LB";Desc="Loopback disconnect";Optional=@("TYPE")},@{Name="OPR-TEST";Desc="Operate test";Optional=@("TEST","PATTERN")},@{Name="RLS-RES";Desc="Release resource";Optional=@("RES")},@{Name="RD-REG";Desc="Read register";Optional=@("REG")},@{Name="TST-LOOP";Desc="Test loop";Optional=@("PATTERN","DUR")},@{Name="SW-TRAFF";Desc="Switch traffic";Optional=@("MODE")},@{Name="CHG-ACCMD-T1";Desc="Change access cmd T1";Optional=@("LEVEL")})
  "Provisioning"=@(@{Name="ENT-SRVC";Desc="Enter service";Optional=@("BAND","OPT")},@{Name="ED-SRVC";Desc="Edit service";Optional=@("FIELD","VALUE")},@{Name="RMV-SRVC";Desc="Remove service";Optional=@("FORCE")},@{Name="RST-UNIT";Desc="Reset unit";Optional=@("SOFT","HARD")},@{Name="DLT-OBJ";Desc="Delete object";Optional=@("CONFIRM")})
}

# XAML UI
[xml]$xaml=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="TL1 Command Builder" WindowStartupLocation="CenterScreen"
        Width="${($Settings.Window.Width)}" Height="${($Settings.Window.Height)}" Background="#0f1115">
  <DockPanel LastChildFill="True">
    <Border DockPanel.Dock="Left" Width="270" Background="#161a22" BorderBrush="#2a2f3a" BorderThickness="0,0,1,0">
      <StackPanel>
        <TextBlock Text="Categories" Foreground="#cbd5e1" FontWeight="Bold" Margin="10,10,10,6"/>
        <TreeView Name="CategoryTree" Margin="8" Background="#0f1115" Foreground="#e5e7eb" BorderThickness="0"/>
      </StackPanel>
    </Border>
    <Grid Margin="10">
      <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="160"/></Grid.RowDefinitions>
      <Border Grid.Row="0" Background="#161a22" Padding="8" CornerRadius="8" BorderBrush="#2a2f3a" BorderThickness="1">
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="160"/><ColumnDefinition Width="220"/><ColumnDefinition Width="120"/><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <StackPanel Orientation="Horizontal" Grid.Column="0" VerticalAlignment="Center" Margin="4,0">
            <TextBlock Text="System:" Foreground="#cbd5e1" Margin="0,0,6,0"/>
            <ComboBox Name="SystemBox" Width="110"><ComboBoxItem Content="1603 SM"/><ComboBoxItem Content="16034 SMX"/></ComboBox>
          </StackPanel>
          <StackPanel Orientation="Horizontal" Grid.Column="1" VerticalAlignment="Center" Margin="4,0"><TextBlock Text="Host/IP:" Foreground="#cbd5e1" Margin="0,0,6,0"/><TextBox Name="HostBox" Width="150"/></StackPanel>
          <StackPanel Orientation="Horizontal" Grid.Column="2" VerticalAlignment="Center" Margin="4,0"><TextBlock Text="Port:" Foreground="#cbd5e1" Margin="0,0,6,0"/><TextBox Name="PortBox" Width="60"/></StackPanel>
          <StackPanel Orientation="Horizontal" Grid.Column="3" VerticalAlignment="Center" Margin="4,0"><Button Name="ConnectBtn" Content="Connect" Width="80" Margin="0,0,6,0"/><Button Name="DisconnectBtn" Content="Disconnect" Width="90"/></StackPanel>
          <StackPanel Orientation="Horizontal" Grid.Column="4" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="4,0"><CheckBox Name="DebugChk" Content="Debug" Foreground="#cbd5e1" IsChecked="${$Settings.Debug}"/><TextBlock Name="StatusText" Text="Disconnected" Foreground="#fca5a5" Margin="10,0,0,0"/></StackPanel>
        </Grid>
      </Border>
      <Border Grid.Row="1" Background="#161a22" Padding="8" CornerRadius="8" BorderBrush="#2a2f3a" BorderThickness="1" Margin="0,10,0,10">
        <Grid>
          <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
          <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,8"><TextBlock Text="Command:" Foreground="#cbd5e1" Margin="0,0,6,0"/><ComboBox Name="CommandBox" Width="240"/><TextBlock Text="Desc:" Foreground="#94a3b8" Margin="20,0,6,0"/><TextBlock Name="CmdDesc" Foreground="#94a3b8"/></StackPanel>
          <StackPanel Orientation="Horizontal" Grid.Row="1" Margin="0,0,0,8">
            <TextBlock Text="TID:" Foreground="#cbd5e1"/><TextBox Name="TidBox" Width="100" Margin="6,0,20,0"/>
            <TextBlock Text="AID:" Foreground="#cbd5e1"/><TextBox Name="AidBox" Width="120" Margin="6,0,20,0"/>
            <TextBlock Text="CTAG:" Foreground="#cbd5e1"/><TextBox Name="CtagBox" Width="80" Margin="6,0,20,0"/>
            <CheckBox Name="CtagAuto" Content="Auto-increment" Foreground="#cbd5e1" IsChecked="True"/>
          </StackPanel>
          <StackPanel Grid.Row="2"><TextBlock Text="Optional Parameters (skip freely — [] means optional):" Foreground="#cbd5e1" Margin="0,0,0,6"/><WrapPanel Name="OptionalPanel"/></StackPanel>
          <StackPanel Grid.Row="3" Orientation="Vertical" Margin="0,10,0,0"><TextBlock Text="Preview:" Foreground="#cbd5e1"/><TextBox Name="PreviewBox" Height="60" IsReadOnly="True" TextWrapping="Wrap" Background="#0f1115" Foreground="#e5e7eb"/><StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,8,0,0"><Button Name="CopyBtn" Content="Copy" Width="90" Margin="6,0"/><Button Name="SendBtn" Content="Send" Width="90" Margin="6,0"/><Button Name="LogBtn" Content="Log Only" Width="90" Margin="6,0"/></StackPanel></StackPanel>
        </Grid>
      </Border>
      <TextBox Name="ConsoleBox" Grid.Row="2" Background="#0b0e14" Foreground="#e5e7eb" FontFamily="Consolas" FontSize="12" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" IsReadOnly="True"/>
    </Grid>
  </DockPanel>
</Window>
"@
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load($reader)

# Bind
$CategoryTree=$Window.FindName("CategoryTree"); $SystemBox=$Window.FindName("SystemBox"); $HostBox=$Window.FindName("HostBox"); $PortBox=$Window.FindName("PortBox")
$ConnectBtn=$Window.FindName("ConnectBtn"); $DisconnectBtn=$Window.FindName("DisconnectBtn"); $DebugChk=$Window.FindName("DebugChk"); $StatusText=$Window.FindName("StatusText")
$CommandBox=$Window.FindName("CommandBox"); $CmdDesc=$Window.FindName("CmdDesc"); $TidBox=$Window.FindName("TidBox"); $AidBox=$Window.FindName("AidBox")
$CtagBox=$Window.FindName("CtagBox"); $CtagAuto=$Window.FindName("CtagAuto"); $OptionalPanel=$Window.FindName("OptionalPanel"); $PreviewBox=$Window.FindName("PreviewBox")
$ConsoleBox=$Window.FindName("ConsoleBox"); $CopyBtn=$Window.FindName("CopyBtn"); $SendBtn=$Window.FindName("SendBtn"); $LogBtn=$Window.FindName("LogBtn")
$global:ConsoleBox=$ConsoleBox

# Init
$PortBox.Text="$($Settings.DefaultPort)"; $HostBox.Text="$($Settings.DefaultHost)"; $StatusText.Text="Disconnected"

# Populate categories
$Categories.Keys | ForEach-Object {
  $cat=$_; $catNode=New-Object System.Windows.Controls.TreeViewItem; $catNode.Header=$cat
  foreach($entry in $Categories[$cat]){ $cmdNode=New-Object System.Windows.Controls.TreeViewItem; $cmdNode.Header=$entry.Name; $cmdNode.Tag=$entry; $catNode.Items.Add($cmdNode) | Out-Null }
  $CategoryTree.Items.Add($catNode) | Out-Null
}

function Refresh-OptionalFields{
  $OptionalPanel.Children.Clear(); $sel=$CommandBox.SelectedItem; if(-not $sel){return}
  $entry=$sel.Tag; if(-not $entry){return}
  foreach($name in ($entry.Optional | ForEach-Object { $_ })){
    $sp=New-Object System.Windows.Controls.StackPanel; $sp.Orientation="Horizontal"
    $lbl=New-Object System.Windows.Controls.TextBlock; $lbl.Text="$name="; $lbl.Foreground="White"
    $tb=New-Object System.Windows.Controls.TextBox; $tb.Width=140; $tb.Margin="6,0,12,6"
    $sp.Children.Add($lbl)|Out-Null; $sp.Children.Add($tb)|Out-Null; $OptionalPanel.Children.Add($sp)|Out-Null
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
function Update-Preview{
  $cmd= if($CommandBox.SelectedItem){ $CommandBox.SelectedItem.Content } else { "" }
  $tid=$TidBox.Text; $aid=$AidBox.Text; $ctag=$CtagBox.Text
  if($Settings.AutoIncrementCTAG -and $CtagAuto.IsChecked -and [string]::IsNullOrWhiteSpace($ctag)){ $CtagBox.Text="1"; $ctag="1" }
  $opt=Build-OptionalList
  $tid=$tid??""; $aid=$aid??""; $ctag=$ctag??""
  $left="$cmd::$tid:$aid:$ctag"
  $right= if([string]::IsNullOrWhiteSpace($opt)) { "" } else { "::"+$opt }
  $PreviewBox.Text="$left$right;"
}

# Events
$CategoryTree.Add_SelectedItemChanged({
  $item=$CategoryTree.SelectedItem
  if($item -and $item.Tag){
    $CommandBox.Items.Clear()
    $entry=$item.Tag
    $cbItem=New-Object System.Windows.Controls.ComboBoxItem
    $cbItem.Content=$entry.Name
    $cbItem.Tag=$entry
    $CommandBox.Items.Add($cbItem)|Out-Null
    $CommandBox.SelectedIndex=0
    $CmdDesc.Text=$entry.Desc
    Refresh-OptionalFields
    Update-Preview
  }
})
$CommandBox.Add_SelectionChanged({ $CmdDesc.Text= if($CommandBox.SelectedItem){ $CommandBox.SelectedItem.Tag.Desc } else { "" }; Refresh-OptionalFields; Update-Preview })
$TidBox.Add_TextChanged({ Update-Preview }); $AidBox.Add_TextChanged({ Update-Preview }); $CtagBox.Add_TextChanged({ Update-Preview })
$CtagAuto.Add_Click({ if($CtagAuto.IsChecked -and [string]::IsNullOrWhiteSpace($CtagBox.Text)){ $CtagBox.Text="1" }; Update-Preview })

$ConnectBtn.Add_Click({ $host=$HostBox.Text; $port=$PortBox.Text
  if([string]::IsNullOrWhiteSpace($host)){ Write-Log "Host/IP is empty." "WARN"; return }
  Write-Log "Simulated connect to $host:$port" "NET"; $StatusText.Text="Connected (simulated)"; $StatusText.Foreground='LightGreen'
})
$DisconnectBtn.Add_Click({ Write-Log "Disconnected." "NET"; $StatusText.Text="Disconnected"; $StatusText.Foreground='#fca5a5' })

$CopyBtn.Add_Click({ Try-Do { Set-Clipboard -Value $PreviewBox.Text } "COPY"; Write-Log "Copied: $($PreviewBox.Text)" })
$LogBtn.Add_Click({ Write-Log "LOG ONLY: $($PreviewBox.Text)" "LOG" })
$SendBtn.Add_Click({
  $cmdText=$PreviewBox.Text
  Write-Log "SEND: $cmdText" "SEND"
  $crt=$Settings.SecureCRTPath
  $sendScript=Join-Path $ScriptDir "send_tl1.ps1"
  if(Test-Path $sendScript){
    Try-Do { & powershell -NoProfile -ExecutionPolicy Bypass -File $sendScript -CommandText $cmdText -SecureCRTPath $crt } "SEND_HELPER"
  } else {
    Write-Log "send_tl1.ps1 not found; logged only." "WARN"
  }
})

Write-Log "=== TL1 Command Builder started ===" "BOOT"
$Window.ShowDialog() | Out-Null
