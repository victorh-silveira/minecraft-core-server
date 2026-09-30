param(
  [Parameter(Mandatory = $true)][string]$HostName,
  [Parameter(Mandatory = $true)][int]$Port,
  [int]$TimeoutMs = 3000
)
$client = New-Object System.Net.Sockets.TcpClient
try {
  $async = $client.BeginConnect($HostName, $Port, $null, $null)
  if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
    exit 1
  }
  $client.EndConnect($async)
  if ($client.Connected) { exit 0 }
  exit 1
} catch {
  exit 1
} finally {
  $client.Close()
}
