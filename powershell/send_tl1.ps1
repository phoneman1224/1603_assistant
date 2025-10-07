# send_tl1.ps1 - Authoritative TL1 TCP Sender
# Native TCP/Telnet implementation for sending TL1 commands

param(
    [Parameter(Mandatory=$true)]
    [string]$Host,
    
    [Parameter(Mandatory=$true)]
    [int]$Port,
    
    [Parameter(Mandatory=$true)]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 30
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    Write-Output "[$Level] $timestamp $Message"
}

function Send-TL1Command {
    param(
        [string]$TargetHost,
        [int]$TargetPort,
        [string]$Cmd,
        [int]$TimeoutSec
    )
    
    $tcpClient = $null
    $stream = $null
    
    try {
        Write-Log "INFO" "Connecting to ${TargetHost}:${TargetPort}..."
        
        # Create TCP client
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($TargetHost, $TargetPort)
        
        if (-not $tcpClient.Connected) {
            Write-Log "ERROR" "Failed to connect to ${TargetHost}:${TargetPort}"
            return $null
        }
        
        Write-Log "INFO" "Connected successfully"
        
        # Get network stream
        $stream = $tcpClient.GetStream()
        $stream.ReadTimeout = $TimeoutSec * 1000
        
        # Ensure command ends with semicolon and newline
        if (-not $Cmd.EndsWith(";")) {
            $Cmd += ";"
        }
        $Cmd += "`n"
        
        # Send command
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($Cmd)
        Write-Log "SEND" $Cmd.Trim()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
        
        # Read response
        $response = ""
        $buffer = New-Object Byte[] 4096
        $startTime = Get-Date
        
        while ($true) {
            if ($stream.DataAvailable) {
                $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -gt 0) {
                    $chunk = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
                    $response += $chunk
                    
                    # Check for TL1 response completion (ends with semicolon)
                    if ($response -match ";\s*$") {
                        break
                    }
                }
            }
            
            # Check timeout
            if (((Get-Date) - $startTime).TotalSeconds -gt $TimeoutSec) {
                Write-Log "WARN" "Response timeout after ${TimeoutSec} seconds"
                break
            }
            
            Start-Sleep -Milliseconds 100
        }
        
        # Clean up response
        $response = $response.Trim()
        
        if ($response) {
            Write-Log "RECV" $response
            
            # Check for COMPLD or DENY
            if ($response -match "COMPLD") {
                Write-Log "INFO" "Command completed successfully"
            } elseif ($response -match "DENY") {
                Write-Log "WARN" "Command denied by device"
            }
        } else {
            Write-Log "WARN" "No response received"
        }
        
        return $response
        
    } catch {
        Write-Log "ERROR" "Exception: $($_.Exception.Message)"
        return $null
    } finally {
        # Cleanup
        if ($stream) {
            $stream.Close()
        }
        if ($tcpClient) {
            $tcpClient.Close()
        }
        Write-Log "INFO" "Connection closed"
    }
}

# Execute
$result = Send-TL1Command -TargetHost $Host -TargetPort $Port -Cmd $Command -TimeoutSec $Timeout

# Return exit code
if ($result) {
    exit 0
} else {
    exit 1
}
