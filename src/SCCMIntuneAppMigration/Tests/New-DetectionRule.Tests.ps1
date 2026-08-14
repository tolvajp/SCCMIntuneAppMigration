Set-StrictMode -Version Latest

Describe 'New-DetectionRule' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'routes File rule creation to file helper' {
            $rule = New-DetectionRule -RuleType File -Parameters @{
                Path = 'C:\Program Files\Notepad++'
                FileOrFolderName = 'notepad++.exe'
                Exists = $true
            }

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppFileSystemDetection'
        }

        It 'routes Registry rule creation to registry helper' {
            $rule = New-DetectionRule -RuleType Registry -Parameters @{
                KeyPath = 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso'
                ValueExists = $true
                ValueName = 'InstallPath'
            }

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppRegistryDetection'
            $rule.valueName | Should -Be 'InstallPath'
        }

        It 'routes Msi rule creation to msi helper' {
            $rule = New-DetectionRule -RuleType Msi -Parameters @{
                ProductCode = '{11111111-2222-3333-4444-555555555555}'
                ProductCodeExists = $true
            }

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppProductCodeDetection'
        }

        It 'routes Script rule creation to script helper' {
            $rule = New-DetectionRule -RuleType Script -Parameters @{
                ScriptContent = "Write-Output 'Detected'"
            }

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppPowerShellScriptDetection'
        }

        It 'wraps forwarded helper errors in dispatcher context' {
            { New-DetectionRule -RuleType Msi -Parameters @{ ProductCode = 'bad-guid'; ProductCodeExists = $true } } |
                Should -Throw "Failed to build 'Msi' detection rule by 'New-MsiDetectionRule'. Error:*"
        }
    }
}
