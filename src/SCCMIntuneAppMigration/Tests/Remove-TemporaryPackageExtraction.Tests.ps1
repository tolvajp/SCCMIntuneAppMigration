Set-StrictMode -Version Latest

Describe 'Remove-TemporaryPackageExtraction' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'removes existing folder' {
            $dir = Join-Path $env:TEMP ("remove_test_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $dir | Out-Null
            Set-Content -LiteralPath (Join-Path $dir 'a.txt') -Value 'x'

            Remove-TemporaryPackageExtraction -ExtractionPath $dir
            (Test-Path -LiteralPath $dir) | Should -BeFalse
        }

        It 'does nothing for empty path' {
            { Remove-TemporaryPackageExtraction -ExtractionPath '' } | Should -Not -Throw
        }

        It 'does nothing for non-existing folder path' {
            $dir = Join-Path $env:TEMP ("remove_test_missing_" + [guid]::NewGuid().ToString())
            { Remove-TemporaryPackageExtraction -ExtractionPath $dir } | Should -Not -Throw
        }
    }
}
