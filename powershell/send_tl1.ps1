# send_tl1.ps1  (TELNET via TcpClient, no newline after ';', telnet noise filtered)
param(
    [Parameter(Mandatory=$true)][string]$CommandText,
    [Parameter(Mandatory=$true)][string]$Host,
    [Parameter(Mandatory=$true)][int]$Port,
    [int]$TimeoutMs = 1500
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path -Parent $ScriptDir
$LogsDir   = Join-Path $RootDir "logs"
if (!(Test-Path $LogsDir)) { New-Item -ItemType Directory -Path $LogsDir | Out-Null }
$LogFile   = Join-Path $LogsDir ("send-{0}.log" -f (Get-Date -Format "yyyyMMdd"))

function Remove-TelnetNoise([byte[]]$bytes){
    # Strip telnet negotiations (IAC 255) and non-printables except CR(13), LF(10), TAB(9)
    $result = New-Object System.Collections.Generic.List[byte]
    for($i=0; $i -lt $bytes.Length; $i++){
        $b = $bytes[$i]
        if ($b -eq 255) { if ($i + 2 -lt $bytes.Length) { $i += 2 }; continue } # IAC + cmd + opt
        if (($b -ge 32 -and $b -le 126) -or $b -in 9,10,13) { [void]$result.Add($b) }
    }
    ,$result.ToArray()
}

$ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
Add-Content -Path $LogFile -Value "[${ts}] CONNECT $Host:$Port"

$client = [System.Net.Sockets.TcpClient]::new()
try {
    $iar = $client.BeginConnect($Host, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { throw "Connect timeout ($TimeoutMs ms)" }
    $client.EndConnect($iar)

    $stream  = $client.GetStream()
    $writer  = New-Object System.IO.StreamWriter($stream, [Text.Encoding]::ASCII)
    $writer.AutoFlush = $true

    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "[${ts}] SEND $CommandText"
    # IMPORTANT: send exactly the text; NO newline after ';'
    $writer.Write($CommandText)

    # Read raw bytes briefly; clean telnet noise
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $mem = New-Object System.IO.MemoryStream
    $tmp = New-Object byte[] 8192
    while ($sw.ElapsedMilliseconds -lt $TimeoutMs) {
        if ($stream.DataAvailable) {
            $n = $stream.Read($tmp, 0, $tmp.Length)
            if ($n -gt 0) { $mem.Write($tmp, 0, $n) }
        } else { Start-Sleep -Milliseconds 50 }
    }
    $raw = $mem.ToArray()
    $clean = Remove-TelnetNoise $raw
    $resp = [Text.Encoding]::ASCII.GetString($clean)
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
