# send_tl1.ps1  (TELNET via TcpClient)
param(
    [Parameter(Mandatory=$true)][string]$CommandText,
    [Parameter(Mandatory=$true)][string]$Host,
    [Parameter(Mandatory=$true)][int]$Port,
    [int]$TimeoutMs = 1500
)

Add-Type -AssemblyName System.Net.Sockets
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir
$LogsDir   = Join-Path $RootDir "logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }
$LogFile   = Join-Path $LogsDir ("send-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

$ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content -Path $LogFile -Value "[${ts}] CONNECT $Host:$Port"

$client = New-Object System.Net.Sockets.TcpClient
try {
    $iar = $client.BeginConnect($Host, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { throw "Connect timeout ($TimeoutMs ms)" }
    $client.EndConnect($iar)

    $stream  = $client.GetStream()
    $writer  = New-Object System.IO.StreamWriter($stream)
    $reader  = New-Object System.IO.StreamReader($stream)
    $writer.NewLine = "`r`n"
    $writer.AutoFlush = $true

    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[${ts}] SEND $CommandText"
    $null = $writer.WriteLine($CommandText)

    # brief read loop
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $buf = New-Object System.Text.StringBuilder
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        if ($stream.DataAvailable) {
            $line = $reader.ReadLine()
            if ($line -ne $null) { $null = $buf.AppendLine($line) }
        } else {
            Start-Sleep -Milliseconds 50
        }
    }
    $resp = $buf.ToString()
    if ([string]::IsNullOrWhiteSpace($resp)) { $resp = "<no response>" }
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[${ts}] RECV $($resp.Trim())"
    $resp
}
catch {
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[${ts}] ERROR $($_.Exception.Message)"
    throw
}
finally {
    if ($client.Connected) { $client.Close() }
}
