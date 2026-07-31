Set-StrictMode -Version Latest

Describe 'Set-Win32AppDependencies' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'posts updateRelationships for valid dependencies' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {} -Verifiable -ParameterFilter {
                $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/app-1/updateRelationships' -and $Body.relationships.Count -eq 2
            }
            Mock -CommandName Get-Win32AppIdByDisplayName -MockWith {
                switch ($DisplayName) {
                    'dep-app-1' { 'dep-1' }
                    'dep-app-2' { 'dep-2' }
                    default { throw 'unexpected display name' }
                }
            }

            $dependencies = @(
                @{ targetDisplayName = 'dep-app-1'; dependencyType = 'autoInstall' },
                @{ targetDisplayName = 'dep-app-2'; dependencyType = 'detect' }
            )

            Set-Win32AppDependencies -AppId 'app-1' -Dependencies $dependencies
            Assert-VerifiableMock
            Assert-MockCalled -CommandName Get-Win32AppIdByDisplayName -Times 2 -Exactly
        }

        It 'returns without Graph call when dependency list is empty' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {}

            Set-Win32AppDependencies -AppId 'app-1' -Dependencies @()
            Assert-MockCalled -CommandName Invoke-IntuneGraphRequest -Times 0 -Exactly
        }

        It 'throws when dependency targetDisplayName is missing' {
            { Set-Win32AppDependencies -AppId 'app-1' -Dependencies @(@{ dependencyType = 'autoInstall' }) } | Should -Throw '*targetDisplayName*'
        }

        It 'throws when dependency type is invalid' {
            Mock -CommandName Get-Win32AppIdByDisplayName -MockWith { 'dep-1' }
            { Set-Win32AppDependencies -AppId 'app-1' -Dependencies @(@{ targetDisplayName = 'dep-app-1'; dependencyType = 'bad' }) } | Should -Throw '*Unsupported dependencyType*'
        }

        It 'throws when app depends on itself' {
            Mock -CommandName Get-Win32AppIdByDisplayName -MockWith { 'app-1' }
            { Set-Win32AppDependencies -AppId 'app-1' -Dependencies @(@{ targetDisplayName = 'app-self'; dependencyType = 'autoInstall' }) } | Should -Throw '*cannot depend on itself*'
        }

        It 'propagates id resolution failure' {
            Mock -CommandName Get-Win32AppIdByDisplayName -MockWith { throw 'not found' }
            { Set-Win32AppDependencies -AppId 'app-1' -Dependencies @(@{ targetDisplayName = 'missing'; dependencyType = 'autoInstall' }) } | Should -Throw 'not found'
        }
    }
}
