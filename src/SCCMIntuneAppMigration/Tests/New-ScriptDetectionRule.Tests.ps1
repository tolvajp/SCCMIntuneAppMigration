Set-StrictMode -Version Latest

Describe 'New-ScriptDetectionRule' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'creates a base64 encoded PowerShell script detection rule' {
            $script = "Write-Output 'Detected'"

            $rule = New-ScriptDetectionRule -ScriptContent $script -EnforceSignatureCheck $false -RunAs32Bit $true

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppPowerShellScriptDetection'
            [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($rule.scriptContent)) | Should -Be $script
            $rule.enforceSignatureCheck | Should -BeFalse
            $rule.runAs32Bit | Should -BeTrue
        }
    }
}