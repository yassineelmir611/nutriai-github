[CmdletBinding()]
param(
    [string]$BaseUrl = 'http://127.0.0.1',
    [int]$FoodPort = 8000,
    [int]$ChatPort = 8001,
    [string]$DeviceId = '',
    [switch]$RebuildApk,
    [switch]$InstallApk
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-AdbPath {
    $candidates = @()

    $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($adbCmd) {
        $candidates += $adbCmd.Source
    }

    if ($env:ANDROID_SDK_ROOT) {
        $candidates += (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe')
    }

    if ($env:ANDROID_HOME) {
        $candidates += (Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe')
    }

    if ($env:LOCALAPPDATA) {
        $candidates += (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    throw 'adb introuvable. Installe Android platform-tools ou ajoute adb au PATH.'
}

function Get-ConnectedDeviceIds {
    param([Parameter(Mandatory = $true)][string]$AdbPath)

    $raw = & $AdbPath devices
    if ($LASTEXITCODE -ne 0) {
        throw 'Impossible de lister les appareils ADB.'
    }

    $ids = @()
    foreach ($line in $raw) {
        if ($line -match '^\s*([^\s]+)\s+device$') {
            $ids += $matches[1]
        }
    }

    return $ids
}

function Wait-HttpHealth {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Name
    )

    for ($i = 0; $i -lt 30; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                Write-Host "$Name OK -> $Url"
                return
            }
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }

    throw "$Name ne repond pas sur $Url"
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$adb = Resolve-AdbPath
Write-Host "ADB: $adb"
Write-Host "Projet: $projectRoot"

Write-Host 'Les serveurs doivent deja tourner : .\start_all.ps1 -NoFlutter dans un autre terminal.'

Wait-HttpHealth -Url "$BaseUrl`:$FoodPort/health" -Name 'Food server'
Wait-HttpHealth -Url "$BaseUrl`:$ChatPort/health" -Name 'Chatbot server'

$devices = @(Get-ConnectedDeviceIds -AdbPath $adb)
if ($devices.Count -eq 0) {
    throw 'Aucun telephone detecte. Active le debogage USB puis rebranche le cable.'
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
    $DeviceId = $devices[0]
}

if ($devices -notcontains $DeviceId) {
    throw "Le device '$DeviceId' n'est pas connecte. Devices: $($devices -join ', ')"
}

if ($devices.Count -gt 1 -and [string]::IsNullOrWhiteSpace($PSBoundParameters['DeviceId'])) {
    Write-Warning "Plusieurs devices detectes. Utilisation de: $DeviceId"
}

Write-Host "Telephone cible: $DeviceId"
Write-Host 'Activation du pont USB (adb reverse)...'
& $adb -s $DeviceId reverse "tcp:$FoodPort" "tcp:$FoodPort" | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Echec adb reverse pour le port $FoodPort"
}

& $adb -s $DeviceId reverse "tcp:$ChatPort" "tcp:$ChatPort" | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Echec adb reverse pour le port $ChatPort"
}

if ($RebuildApk) {
    Write-Host 'Build APK debug...'
    & flutter build apk --debug "--dart-define=FOOD_API_URL=http://127.0.0.1:$FoodPort" "--dart-define=CHAT_API_URL=http://127.0.0.1:$ChatPort"
    if ($LASTEXITCODE -ne 0) {
        throw 'Echec flutter build apk.'
    }
}

if ($InstallApk -or $RebuildApk) {
    $apkPath = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path $apkPath)) {
        throw "APK introuvable: $apkPath"
    }

    Write-Host 'Installation APK sur le telephone...'
    & $adb -s $DeviceId install -r $apkPath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Echec installation APK.'
    }
}

Write-Host 'Ouverture de l application...'
& $adb -s $DeviceId shell am start -n com.example.nutriai/.MainActivity | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Impossible de lancer l application sur le telephone.'
}

Write-Host ''
Write-Host 'Connexion telephone + serveurs active.'
Write-Host "Food API   : 127.0.0.1:$FoodPort (sur le telephone)"
Write-Host "Chat API   : 127.0.0.1:$ChatPort (sur le telephone)"
Write-Host "Device ID  : $DeviceId"
Write-Host ''
Write-Host 'Astuce:'
Write-Host '  .\connect_phone.ps1'
Write-Host '  .\connect_phone.ps1 -InstallApk'
Write-Host '  .\connect_phone.ps1 -RebuildApk -InstallApk'
