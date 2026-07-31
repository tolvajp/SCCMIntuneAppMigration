Set-StrictMode -Version Latest

Describe 'New-Win32ContentVersion' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'returns content version when Graph returns id' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{ id = 'v1' } }

            (New-Win32ContentVersion -AppId 'app-1').id | Should -Be 'v1'
        }

        It 'throws when Graph response has no id' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{} }

            { New-Win32ContentVersion -AppId 'app-1' } | Should -Throw 'Content version creation returned no id.'
        }
    }
}
