# TL1_CommandBuilder.ps1 - Desktop WPF GUI for TL1 Command Building
# Preserves desktop functionality alongside Web UI

Add-Type -AssemblyName PresentationFramework

# Load settings
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
$settingsPath = Join-Path $rootPath "settings.json"
$commandsPath = Join-Path $rootPath "data\commands.json"

if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath | ConvertFrom-Json
} else {
    $settings = @{
        connection = @{ host = "localhost"; port = 10201 }
        defaults = @{ lastTID = ""; lastAID = ""; nextCTAG = 1; platform = "1603 SM" }
    }
}

# XAML Definition
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="TL1 Assistant - Desktop GUI" Height="600" Width="900"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <!-- Connection Panel -->
        <GroupBox Header="Connection" Grid.Row="0" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="200"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="100"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <Label Grid.Column="0" Content="Host:" VerticalAlignment="Center"/>
                <TextBox Name="txtHost" Grid.Column="1" Margin="5" VerticalAlignment="Center"/>
                
                <Label Grid.Column="2" Content="Port:" VerticalAlignment="Center"/>
                <TextBox Name="txtPort" Grid.Column="3" Margin="5" VerticalAlignment="Center"/>
                
                <Button Name="btnConnect" Grid.Column="5" Content="Connect" Width="80" Margin="5"/>
            </Grid>
        </GroupBox>
        
        <!-- Command Builder -->
        <GroupBox Header="Command Builder" Grid.Row="1" Margin="0,0,0,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                
                <Grid Grid.Row="0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Column="0" Content="Platform:" VerticalAlignment="Center"/>
                    <ComboBox Name="cbPlatform" Grid.Column="1" Margin="5" VerticalAlignment="Center">
                        <ComboBoxItem Content="1603 SM" IsSelected="True"/>
                        <ComboBoxItem Content="1603 SMX"/>
                    </ComboBox>
                    
                    <Label Grid.Column="2" Content="Category:" VerticalAlignment="Center"/>
                    <ComboBox Name="cbCategory" Grid.Column="3" Margin="5" VerticalAlignment="Center"/>
                    
                    <Label Grid.Column="4" Content="Command:" VerticalAlignment="Center"/>
                    <ComboBox Name="cbCommand" Grid.Column="5" Margin="5" VerticalAlignment="Center"/>
                </Grid>
                
                <Grid Grid.Row="1" Margin="0,5,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Column="0" Content="TID:" VerticalAlignment="Center"/>
                    <TextBox Name="txtTID" Grid.Column="1" Margin="5" VerticalAlignment="Center"/>
                    
                    <Label Grid.Column="2" Content="AID:" VerticalAlignment="Center"/>
                    <TextBox Name="txtAID" Grid.Column="3" Margin="5" VerticalAlignment="Center"/>
                    
                    <Label Grid.Column="4" Content="CTAG:" VerticalAlignment="Center"/>
                    <TextBox Name="txtCTAG" Grid.Column="5" Margin="5" VerticalAlignment="Center"/>
                </Grid>
                
                <Grid Grid.Row="2" Margin="0,5,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <Label Grid.Column="0" Content="Preview:" VerticalAlignment="Center"/>
                    <TextBox Name="txtPreview" Grid.Column="1" Margin="5" IsReadOnly="True" Background="LightYellow"/>
                    <Button Name="btnSend" Grid.Column="2" Content="Send" Width="80" Margin="5"/>
                </Grid>
            </Grid>
        </GroupBox>
        
        <!-- Console Output -->
        <GroupBox Header="Console" Grid.Row="2">
            <TextBox Name="txtConsole" VerticalScrollBarVisibility="Auto" 
                     IsReadOnly="True" FontFamily="Consolas" FontSize="10"
                     Background="Black" Foreground="LightGreen"/>
        </GroupBox>
    </Grid>
</Window>
"@

# Create window
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$txtHost = $window.FindName("txtHost")
$txtPort = $window.FindName("txtPort")
$btnConnect = $window.FindName("btnConnect")
$cbPlatform = $window.FindName("cbPlatform")
$cbCategory = $window.FindName("cbCategory")
$cbCommand = $window.FindName("cbCommand")
$txtTID = $window.FindName("txtTID")
$txtAID = $window.FindName("txtAID")
$txtCTAG = $window.FindName("txtCTAG")
$txtPreview = $window.FindName("txtPreview")
$btnSend = $window.FindName("btnSend")
$txtConsole = $window.FindName("txtConsole")

# Initialize values from settings
$txtHost.Text = $settings.connection.host
$txtPort.Text = $settings.connection.port
$txtCTAG.Text = $settings.defaults.nextCTAG

# Add console log function
function Add-ConsoleLog {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtConsole.AppendText("[$timestamp] $Message`r`n")
    $txtConsole.ScrollToEnd()
}

Add-ConsoleLog "TL1 Assistant Desktop GUI Started"
Add-ConsoleLog "Ready to connect..."

# Show window
$window.ShowDialog() | Out-Null
