Set-StrictMode -Version Latest

Describe 'New-MsiDetectionRule' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'creates product code existence rule' {
            $rule = New-MsiDetectionRule -ProductCode '{11111111-2222-3333-4444-555555555555}' -ProductCodeExists

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppProductCodeDetection'
            $rule.productCode | Should -Be '{11111111-2222-3333-4444-555555555555}'
            $rule.ContainsKey('productVersionOperator') | Should -BeFalse
            $rule.ContainsKey('productVersion') | Should -BeFalse
        }

        It 'creates product version rule' {
            $rule = New-MsiDetectionRule -ProductCode '{11111111-2222-3333-4444-555555555555}' -ProductVersion -ProductVersionOperator greaterThanOrEqual -VersionValue '8.9.7.0'

            $rule.productVersionOperator | Should -Be 'greaterThanOrEqual'
            $rule.productVersion | Should -Be '8.9.7.0'
        }

        It 'throws on invalid product code GUID' {
            { New-MsiDetectionRule -ProductCode 'not-a-guid' -ProductCodeExists } | Should -Throw 'Invalid MSI product code*'
        }

        It 'throws when version operator is empty in version mode' {
            { New-MsiDetectionRule -ProductCode '{11111111-2222-3333-4444-555555555555}' -ProductVersion -ProductVersionOperator '' -VersionValue '1.0.0.0' } | Should -Throw
        }
    }
}
