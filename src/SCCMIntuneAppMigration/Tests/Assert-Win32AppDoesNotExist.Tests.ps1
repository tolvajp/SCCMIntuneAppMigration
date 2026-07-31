Set-StrictMode -Version Latest

Describe 'Assert-Win32AppDoesNotExist' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'does not throw when app does not exist' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{ value = @() } }

            { Assert-Win32AppDoesNotExist -DisplayName 'NoSuchApp' } | Should -Not -Throw
        }

        It 'throws when app already exists' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {
                @{ value = @(@{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'app-1' }) }
            }

            { Assert-Win32AppDoesNotExist -DisplayName 'ExistingApp' } | Should -Throw "*already exists*"
        }

        It 'does not throw when result contains non-win32 app type' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {
                @{ value = @(@{ '@odata.type' = '#microsoft.graph.iosStoreApp'; id = 'ios-1' }) }
            }

            { Assert-Win32AppDoesNotExist -DisplayName 'ExistingApp' } | Should -Not -Throw
        }

        It 'escapes single quotes in display name for filter query' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{ value = @() } } -Verifiable -ParameterFilter {
                $Uri -like "*displayName eq 'App''s Name'*"
            }

            Assert-Win32AppDoesNotExist -DisplayName "App's Name"
            Assert-VerifiableMock
        }
    }
}
