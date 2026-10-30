[CmdletBinding()]
param(
    [string]$Device = '',
    [string]$BaseUrl = 'http://127.0.0.1',
    [ValidateRange(1, 65535)][int]$FoodPort = 8000,
    [ValidateRange(1, 65535)][int]$ChatPort = 8001,
    [switch]$NoBackend,
    [switch]$NoFlutter,
    [switch]$UseMockApi
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$started = @()
$logDir = Join-Path $projectRoot 'run_logs'

function Wait-Server {
    param([string]$Url, [System.Diagnostics.Process]$Process)
    for ($attempt = 0; $attempt -lt 120; $attempt++) {
        if ($Process.HasExited) { throw "Serveur arrete. Consulter $logDir" }
        try {
            $health = Invoke-RestMethod -Uri $Url -TimeoutSec 2
            Write-Host "$Url : $($health | ConvertTo-Json -Compress)"
            return
        } catch [System.Net.WebException] {
            Start-Sleep -Milliseconds 500
        } catch [System.Net.Http.HttpRequestException] {
            Start-Sleep -Milliseconds 500
        }
    }
    throw "Le serveur ne repond pas : $Url. Consulter $logDir"
}

Push-Location $projectRoot
try {
    if (-not $NoBackend -and -not $UseMockApi) {
        if ($FoodPort -eq $ChatPort) { throw 'Les deux services doivent avoir des ports differents.' }
        # Refuse occupied ports; never terminate another application.
        foreach ($port in @($FoodPort, $ChatPort)) {
            if (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) {
                throw "Port $port deja occupe. Choisir un autre port ou utiliser -NoBackend."
            }
        }
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        foreach ($service in @(
            @{ Name = 'food_server'; Port = $FoodPort },
            @{ Name = 'chatbot_server'; Port = $ChatPort }
        )) {
            $serviceDir = Join-Path $projectRoot "backend/$($service.Name)"
            $pythonPath = Join-Path $serviceDir '.venv/Scripts/python.exe'
            if (-not (Test-Path -LiteralPath $pythonPath)) {
                throw "Environnement absent : $pythonPath. Suivre le README."
            }
            $process = Start-Process -FilePath $pythonPath -WindowStyle Hidden `
                -ArgumentList '-m', 'uvicorn', 'main:app', '--host', '0.0.0.0', '--port', $service.Port `
                -WorkingDirectory $serviceDir -PassThru `
                -RedirectStandardOutput (Join-Path $logDir "$($service.Name).out.log") `
                -RedirectStandardError (Join-Path $logDir "$($service.Name).err.log")
            $started += $process
            Wait-Server -Url "http://127.0.0.1:$($service.Port)/health" -Process $process
        }
    }
    if ($NoFlutter) {
        Write-Host 'Serveurs actifs. Ctrl+C pour arreter les processus lances par ce script.'
        while ($started.Count -gt 0) {
            foreach ($process in $started) {
                if ($process.HasExited) { throw 'Un serveur a quitte. Consulter run_logs.' }
            }
            Start-Sleep -Seconds 1
        }
    } else {
        $flutterArgs = @('run', "--dart-define=FOOD_API_URL=$BaseUrl`:$FoodPort",
            "--dart-define=CHAT_API_URL=$BaseUrl`:$ChatPort",
            "--dart-define=USE_MOCK_API=$($UseMockApi.IsPresent.ToString().ToLowerInvariant())")
        if ($Device) { $flutterArgs += @('-d', $Device) }
        & flutter @flutterArgs
        if ($LASTEXITCODE -ne 0) { throw 'Echec Flutter. Consulter le message ci-dessus.' }
    }
} finally {
    foreach ($process in $started) {
        if (-not $process.HasExited) { Stop-Process -Id $process.Id -ErrorAction SilentlyContinue }
    }
    Pop-Location
}
