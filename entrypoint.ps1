#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'

# workaround for https://github.com/PowerShell/PSResourceGet/issues/1806
Get-PSResourceRepository | Out-Null

$ModuleManifests = Get-ChildItem -Recurse -Filter '*.psd1' | Select-Object -ExpandProperty FullName

foreach ($ManifestPath in $ModuleManifests) {
    $ModuleDir = Split-Path $ManifestPath -Parent
    Write-Host "Processing manifest: $ManifestPath..."

    # by design, [Test-ModuleManifest](https://github.com/PowerShell/PowerShell/blob/master/src/System.Management.Automation/engine/Modules/TestModuleManifestCommand.cs#L196)
    # will fail if a required module is not installed.  since we have no way of anticipating what modules an author might require
    # we load and install everything first
    $Manifest = Import-PowerShellDataFile -Path $ManifestPath
    $RequiredModules = @()
    if ($Manifest.RequiredModules) {
        foreach ($Module in $Manifest.RequiredModules) {
            if ($Module -is [string]) {
                $RequiredModules += $Module
            } elseif ($Module -is [hashtable]) {
                $RequiredModules += $Module.ModuleName
            }
        }
    }
    foreach ($ModuleName in $RequiredModules) {
        if (-not (Get-InstalledPSResource -Name $ModuleName -ErrorAction SilentlyContinue)) {
            Write-Host "Installing required module: $ModuleName..."
            Install-Module -Name $ModuleName -Scope CurrentUser -Force
        }
    }

    Write-Host "Validating module manifest: $ManifestPath..."
    Test-ModuleManifest -Path $ManifestPath | Format-List

    Write-Host "Publishing '$ModuleDir' to PowerShell Gallery..."
    Publish-PSResource -ApiKey $env:INPUT_APIKEY -Path $ModuleDir

    Write-Host "...'$ModuleDir' published to PowerShell Gallery"
}
