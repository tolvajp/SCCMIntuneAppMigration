Set-StrictMode -Version Latest

Describe 'Get-Win32AppIdByDisplayName' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'returns id for a unique win32 app match' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {
                @{
                    value = @(
                        @{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'app-1'; displayName = 'Dep App' }
                    )
                }
            }

            $id = Get-Win32AppIdByDisplayName -DisplayName 'Dep App'
            $id | Should -Be 'app-1'
        }

        It 'URL-encodes special characters in the display name filter' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {
                param($Method, $Uri)
                $Uri | Should -Be "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=displayName%20eq%20%27Notepad%2B%2B%20Bob%27%27s%27"
                @{ value = @(@{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'app-1' }) }
            }

            Get-Win32AppIdByDisplayName -DisplayName "Notepad++ Bob's" | Should -Be 'app-1'
        }

        It 'throws when no win32 app is found' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{ value = @() } }
            { Get-Win32AppIdByDisplayName -DisplayName 'Missing App' } | Should -Throw '*No Win32 app found*'
        }

        It 'throws when multiple win32 apps are found' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {
                @{
                    value = @(
                        @{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'app-1'; displayName = 'Dup App' },
                        @{ '@odata.type' = '#microsoft.graph.win32LobApp'; id = 'app-2'; displayName = 'Dup App' }
                    )
                }
            }

            { Get-Win32AppIdByDisplayName -DisplayName 'Dup App' } | Should -Throw '*Multiple Win32 apps found*'
        }

        It 'ignores non-win32 app matches and throws when no win32 remains' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {
                @{
                    value = @(
                        @{ '@odata.type' = '#microsoft.graph.iosStoreApp'; id = 'ios-1'; displayName = 'Dep App' }
                    )
                }
            }

            { Get-Win32AppIdByDisplayName -DisplayName 'Dep App' } | Should -Throw '*No Win32 app found*'
        }
    }
}
