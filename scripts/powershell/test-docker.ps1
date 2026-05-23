param(
    [string]$WslDistribution = "",
    [string]$ProjectPath = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    $ProjectPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

function ConvertTo-WslPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolved = (Resolve-Path -LiteralPath $Path).ProviderPath
    if ($resolved -match '^([A-Za-z]):\\(.*)$') {
        $drive = $Matches[1].ToLower()
        $rest = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive/$rest"
    }

    throw "Caminho Windows invalido: $Path"
}

function Invoke-WslCommand {
    param(
        [string]$Command
    )

    $wslArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($WslDistribution)) {
        $wslArgs += @("-d", $WslDistribution)
    }
    $wslArgs += @("bash", "-lc", $Command)

    & wsl @wslArgs | Out-Host
    return $LASTEXITCODE
}

Write-Host ">>> Teste Docker via WSL"
Write-Host "Projeto Windows: $ProjectPath"

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
    Write-Host "[FAIL] WSL nao encontrado no PATH do Windows"
    exit 1
}

try {
    $wslPath = ConvertTo-WslPath -Path $ProjectPath
}
catch {
    Write-Host "[FAIL] Nao foi possivel converter o caminho para WSL: $($_.Exception.Message)"
    exit 1
}

Write-Host "Projeto WSL: $wslPath"

$preflight = @"
set -e
command -v docker >/dev/null
docker compose version >/dev/null
test -f '$wslPath/.env' || test -f '$wslPath/.env.example'
"@

$preflightExit = Invoke-WslCommand -Command $preflight
if ($preflightExit -ne 0) {
    Write-Host "[FAIL] Pre-check WSL/Docker/.env falhou"
    exit $preflightExit
}

Write-Host "[OK] WSL e Docker acessiveis"

$testCommand = "cd '$wslPath' && chmod +x scripts/bash/test-docker.sh && bash scripts/bash/test-docker.sh"
$testExit = Invoke-WslCommand -Command $testCommand

if ($testExit -eq 0) {
    Write-Host ""
    Write-Host "[SUCESSO] test-docker.ps1 finalizado com sucesso"
    exit 0
}

Write-Host ""
Write-Host "[ERRO] test-docker.ps1 detectou falhas (exit=$testExit)"
exit $testExit
