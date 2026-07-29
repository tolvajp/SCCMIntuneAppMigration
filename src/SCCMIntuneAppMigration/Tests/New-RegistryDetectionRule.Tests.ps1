Set-StrictMode -Version Latest

Describe 'New-RegistryDetectionRule' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'creates key exists rule' {
            $rule = New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -KeyExists

            $rule.'@odata.type' | Should -Be '#microsoft.graph.win32LobAppRegistryDetection'
            $rule.detectionType | Should -Be 'exists'
            $rule.ContainsKey('valueName') | Should -BeFalse
        }

        It 'creates value exists rule' {
            $rule = New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueExists -ValueName 'InstallPath'

            $rule.detectionType | Should -Be 'exists'
            $rule.valueName | Should -Be 'InstallPath'
        }

        It 'creates key doesNotExist rule' {
            $rule = New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -KeyDoesNotExist

            $rule.detectionType | Should -Be 'doesNotExist'
            $rule.ContainsKey('valueName') | Should -BeFalse
        }

        It 'creates value doesNotExist rule' {
            $rule = New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueDoesNotExist -ValueName 'InstallPath'

            $rule.detectionType | Should -Be 'doesNotExist'
            $rule.valueName | Should -Be 'InstallPath'
        }

        It 'creates string comparison rule' {
            $rule = New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -String -ValueName 'Channel' -Operator equal -StringValue 'stable'

            $rule.detectionType | Should -Be 'string'
            $rule.operator | Should -Be 'equal'
            $rule.detectionValue | Should -Be 'stable'
        }

        It 'creates integer comparison rule' {
            $rule = New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -Integer -ValueName 'Build' -Operator greaterThan -IntegerValue 100

            $rule.detectionType | Should -Be 'integer'
            $rule.operator | Should -Be 'greaterThan'
            $rule.detectionValue | Should -Be '100'
        }

        It 'creates version comparison rule' {
            $rule = New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -Version -ValueName 'Version' -Operator greaterThanOrEqual -VersionValue '1.2.3.4'

            $rule.detectionType | Should -Be 'version'
            $rule.operator | Should -Be 'greaterThanOrEqual'
            $rule.detectionValue | Should -Be '1.2.3.4'
        }

        It 'throws when key path is empty' {
            { New-RegistryDetectionRule -KeyPath '' -KeyExists } | Should -Throw
        }

        It 'throws when value name is empty for value exists' {
            { New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -ValueExists -ValueName '' } | Should -Throw
        }

        It 'throws on invalid operator' {
            { New-RegistryDetectionRule -KeyPath 'HKEY_LOCAL_MACHINE\SOFTWARE\Contoso' -String -ValueName 'Channel' -Operator invalid -StringValue 'stable' } | Should -Throw
        }
    }
}
