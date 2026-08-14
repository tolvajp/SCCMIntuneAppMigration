Set-StrictMode -Version Latest

Describe 'New-Win32LobAppBody' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'builds expected win32 body' {
            $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\X'; fileOrFolderName = 'a.exe' }
            $body = New-Win32LobAppBody -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -SetupFilePath 'setup.exe' -DetectionRules @($rule)

            $body.'@odata.type' | Should -Be '#microsoft.graph.win32LobApp'
            $body.displayName | Should -Be 'App'
            $body.setupFilePath | Should -Be 'setup.exe'
            $body.fileName | Should -Be 'setup.exe'
            $body.minimumSupportedOperatingSystem.v10_1607 | Should -BeTrue
            $body.ContainsKey('minimumSupportedWindowsRelease') | Should -BeFalse
            $body.detectionRules.Count | Should -Be 1
            $body.returnCodes.Count | Should -Be 5
        }

        It 'throws when detection rules are empty' {
            { New-Win32LobAppBody -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -SetupFilePath 'setup.exe' -DetectionRules @() } | Should -Throw
        }

        It 'includes optional largeIcon and requirementRules' {
            $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\X'; fileOrFolderName = 'a.exe' }
            $req = @{ '@odata.type' = '#microsoft.graph.win32LobAppOperatingSystemRequirement'; minimumSupportedWindowsRelease = 'Windows10_1607' }
            $icon = @{ '@odata.type' = '#microsoft.graph.mimeContent'; type = 'image/png'; value = 'AA==' }

            $body = New-Win32LobAppBody -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -SetupFilePath 'setup.exe' -DetectionRules @($rule) -RequirementRules @($req) -LargeIcon $icon
            $body.requirementRules.Count | Should -Be 1
            $body.largeIcon.type | Should -Be 'image/png'
        }

        It 'includes non-default minimum Windows release' {
            $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\App'; fileOrFolderName = 'app.exe' }

            $body = New-Win32LobAppBody -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -SetupFilePath 'setup.exe' -DetectionRules @($rule) -MinimumSupportedWindowsRelease 'Windows11_23H2'

            $body.minimumSupportedWindowsRelease | Should -Be 'Windows11_23H2'
        }
    }
}
