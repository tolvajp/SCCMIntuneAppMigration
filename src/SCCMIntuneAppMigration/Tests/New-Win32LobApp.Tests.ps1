Set-StrictMode -Version Latest

Describe 'New-Win32LobApp' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'returns app when Graph create succeeds' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{ id = 'app-1'; displayName = 'App' } }

            (New-Win32LobApp -Body @{ displayName = 'App' }).id | Should -Be 'app-1'
        }

        It 'throws when no app id is returned' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{} }

            { New-Win32LobApp -Body @{ displayName = 'App' } } | Should -Throw
        }
    }
}
