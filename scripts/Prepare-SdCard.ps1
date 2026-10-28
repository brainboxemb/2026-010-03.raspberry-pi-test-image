param(
    [Parameter(Mandatory = $true)]
    [string]$BootDrive,

    [string]$LocalDirectory = (Join-Path $PSScriptRoot "..\local")
)

$ErrorActionPreference = "Stop"

$boot = (Resolve-Path $BootDrive).Path
$userData = Join-Path $LocalDirectory "user-data"
$networkConfig = Join-Path $LocalDirectory "network-config"

foreach ($path in @($userData, $networkConfig)) {
    if (-not (Test-Path $path)) {
        throw "Missing local device configuration: $path"
    }
}

Copy-Item -Force $userData (Join-Path $boot "user-data")
Copy-Item -Force $networkConfig (Join-Path $boot "network-config")

Write-Host "Device configuration copied to $boot"
Write-Host "No credentials were stored in the GitHub-built image."
