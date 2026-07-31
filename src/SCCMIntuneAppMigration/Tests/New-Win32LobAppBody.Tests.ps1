Set-StrictMode -Version Latest

Describe 'New-Win32LobAppBody' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'builds expected win32 body' {
            $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\X'; fileOrFolderName = 'a.exe' }
            $body = New-Win32LobAppBody -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @($rule)

            $body.'@odata.type' | Should -Be '#microsoft.graph.win32LobApp'
            $body.displayName | Should -Be 'App'
            $body.detectionRules.Count | Should -Be 1
            $body.returnCodes.Count | Should -Be 5
        }

        It 'throws when detection rules are empty' {
            { New-Win32LobAppBody -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @() } | Should -Throw
        }

        It 'includes optional largeIcon and requirementRules' {
            $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\X'; fileOrFolderName = 'a.exe' }
            $req = @{ '@odata.type' = '#microsoft.graph.win32LobAppOperatingSystemRequirement'; minimumSupportedWindowsRelease = 'Windows10_1607' }
            $icon = @{ '@odata.type' = '#microsoft.graph.mimeContent'; type = 'image/png'; value = 'AA==' }

            $body = New-Win32LobAppBody -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @($rule) -RequirementRules @($req) -LargeIcon $icon
            $body.requirementRules.Count | Should -Be 1
            $body.largeIcon.type | Should -Be 'image/png'
        }
    }
}
