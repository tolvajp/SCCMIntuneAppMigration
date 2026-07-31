Set-StrictMode -Version Latest

Describe 'Assert-GraphSessionForWin32App' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'does not throw when required scopes exist' {
            Mock -CommandName Get-MgContext -MockWith {
                [pscustomobject]@{ Scopes = @('DeviceManagementApps.ReadWrite.All', 'DeviceManagementConfiguration.ReadWrite.All') }
            }

            { Assert-GraphSessionForWin32App } | Should -Not -Throw
        }

        It 'throws when context is missing' {
            Mock -CommandName Get-MgContext -MockWith { $null }

            { Assert-GraphSessionForWin32App } | Should -Throw 'No active Microsoft Graph session found*'
        }

        It 'throws when a required scope is missing' {
            Mock -CommandName Get-MgContext -MockWith {
                [pscustomobject]@{ Scopes = @('DeviceManagementApps.ReadWrite.All') }
            }

            { Assert-GraphSessionForWin32App } | Should -Throw "Missing required Graph scope 'DeviceManagementConfiguration.ReadWrite.All'."
        }
    }
}
