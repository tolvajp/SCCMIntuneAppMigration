Set-StrictMode -Version Latest

function Import-SccmIntuneModuleForTests {
    [CmdletBinding()]
    param()

    $candidates = New-Object System.Collections.Generic.List[string]

    if ($PSScriptRoot) {
        $candidates.Add([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\SCCMIntuneAppMigration.psd1')))
    }

    if ($PSCommandPath) {
        $scriptFolder = Split-Path -Parent $PSCommandPath
        $candidates.Add([System.IO.Path]::GetFullPath((Join-Path $scriptFolder '..\SCCMIntuneAppMigration.psd1')))
    }

    $invocationPath = $null
    if ($MyInvocation -and $MyInvocation.MyCommand -and $MyInvocation.MyCommand.PSObject.Properties['Path']) {
        $invocationPath = $MyInvocation.MyCommand.Path
    }

    if ($invocationPath) {
        $scriptFolder = Split-Path -Parent $invocationPath
        $candidates.Add([System.IO.Path]::GetFullPath((Join-Path $scriptFolder '..\SCCMIntuneAppMigration.psd1')))
    }

    $candidates.Add([System.IO.Path]::GetFullPath((Join-Path (Get-Location) 'src\SCCMIntuneAppMigration\SCCMIntuneAppMigration.psd1')))

    $moduleManifestPath = $candidates |
        Select-Object -Unique |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1

    if (-not $moduleManifestPath) {
        throw "Module manifest not found. Checked: $($candidates -join '; ')"
    }

    Import-Module -Name $moduleManifestPath -Force
}
