param(
  [Parameter(Mandatory = $true)][int]$Port,
  [Parameter(Mandatory = $true)][string]$ConnectHost,
  [string]$LanHost = "192.168.0.50"
)

$ErrorActionPreference = "Stop"

netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=$Port 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=$Port connectaddress=$ConnectHost connectport=$Port

netsh advfirewall firewall delete rule name="MCS Minecraft $Port" 2>$null | Out-Null
netsh advfirewall firewall add rule name="MCS Minecraft $Port" dir=in action=allow protocol=TCP localport=$Port profile=any | Out-Null

Write-Output "[OK] LAN: ${LanHost}:${Port} -> WSL ${ConnectHost}:${Port}"
