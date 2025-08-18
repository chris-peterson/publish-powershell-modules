#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'


# ANSI color codes
$AnsiReset   = "`e[0m"
$AnsiVerbose = "`e[90m"   # Bright black (gray)
$AnsiInfo    = "`e[36m"   # Cyan
$AnsiSuccess = "`e[32m"   # Green

# workaround for https://github.com/PowerShell/PSResourceGet/issues/1806
Get-PSResourceRepository | Out-Null

Get-ChildItem -Recurse -Filter '*.psd1' | ForEach-Object {
    Write-Host "${AnsiReset}"
    Write-Host "Processing '${AnsiInfo}$_${AnsiReset}'..."

    $Manifest   = Import-PowerShellDataFile -Path $_
    $ModuleDir  = $_.Directory
    $ModuleName = $_.Directory.Name

    # by design, [Test-ModuleManifest](https://github.com/PowerShell/PowerShell/blob/master/src/System.Management.Automation/engine/Modules/TestModuleManifestCommand.cs#L196)
    # will fail if a required module is not installed.  since we have no way of anticipating what modules an author might require
    # we load and install everything first
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
    foreach ($Module in $RequiredModules) {
        if (-not (Get-InstalledPSResource -Name $Module -ErrorAction SilentlyContinue)) {
            Write-Host "${AnsiVerbose}`tInstalling required module '${AnsiInfo}$Module${AnsiVerbose}'...${AnsiReset}"
            Install-Module -Name $Module -Scope CurrentUser -Force
        }
    }

    Write-Host "${AnsiReset}`tValidating '${AnsiInfo}$ModuleName${AnsiReset}' manifest..."
    $Manifest = Test-ModuleManifest -Path $_

    try {
        $FormatEnumerationLimit = -1
        $MaxLineLength = 120
        $Manifest | Format-List | Out-String -Stream | ForEach-Object {
            if ($_.Trim() -eq '') {
                return
            }
            $Line = $_
            $Index = $Line.IndexOf(':')
            if ($Index -gt 0) {
                $Value = $Line.Substring($Index + 1).Trim()
                if ($Value -eq '' -or $Value -eq '{}'){
                    return
                }
            }
            if ($Line.Length -le $MaxLineLength) {
                Write-Host "${AnsiVerbose}`t`t$Line${AnsiReset}"
            } elseif ($Line.Contains(',')) {
                $Index = $Line.IndexOf(':')
                if ($Index -gt 0) {
                    $Property = $Line.Substring(0, $Index + 1)
                    $Value = $Line.Substring($Index + 1).TrimStart()
                    Write-Host "${AnsiVerbose}`t`t$Property {${AnsiReset}"
                    $Parts = $Value.TrimStart('{').TrimEnd('}').Split(',')
                    $CurrentLine = ''
                    foreach ($Part in $Parts) {
                        $Trimmed = $Part.Trim()
                        if ($CurrentLine.Length + $Trimmed.Length + 2 -gt $MaxLineLength) {
                            Write-Host "${AnsiVerbose}`t`t`t$CurrentLine,${AnsiReset}"
                            $CurrentLine = $Trimmed
                        } else {
                            if ($CurrentLine) {
                                $CurrentLine += ', '
                            }
                            $CurrentLine += $Trimmed
                        }
                    }
                    if ($CurrentLine) {
                        Write-Host "${AnsiVerbose}`t`t`t$CurrentLine${AnsiReset}"
                    }
                    Write-Host "${AnsiVerbose}`t`t}${AnsiReset}"
                } else {
                    Write-Host "${AnsiVerbose}`t`t$Line${AnsiReset}"
                }
            }
        }
    }
    catch {
        Write-Warning "`tError formatting manifest: $_"
        Write-Warning "Please open a bug report at https://github.com/chris-peterson/publish-powershell-modules/issues"
    }

    Write-Host "${AnsiReset}`tPublishing '${AnsiInfo}$ModuleName${AnsiReset}' to $($(Get-PSResourceRepository).Uri.AbsoluteUri)${AnsiReset}"
    Publish-PSResource -ApiKey $env:INPUT_APIKEY -Path $ModuleDir

    Write-Host "${AnsiSuccess}`✅ Published https://$($(Get-PSResourceRepository).Uri.Host)/packages/$ModuleName${AnsiReset}"
}
