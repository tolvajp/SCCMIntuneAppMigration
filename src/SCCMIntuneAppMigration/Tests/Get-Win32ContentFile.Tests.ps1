Set-StrictMode -Version Latest

Describe 'Get-Win32ContentFile' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'delegates to Graph request wrapper' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{ id = 'file-1' } }

            (Get-Win32ContentFile -AppId 'app-1' -ContentVersionId 'v1' -FileId 'file-1').id | Should -Be 'file-1'
        }

        It 'propagates Graph wrapper errors' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { throw 'graph down' }

            { Get-Win32ContentFile -AppId 'app-1' -ContentVersionId 'v1' -FileId 'file-1' } | Should -Throw 'graph down'
        }
    }
}
