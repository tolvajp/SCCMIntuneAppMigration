Set-StrictMode -Version Latest

Describe 'Set-Win32AppCommittedContentVersion' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'patches app committed content version' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {}

            { Set-Win32AppCommittedContentVersion -AppId 'app-1' -ContentVersionId 'v2' } | Should -Not -Throw
            Assert-MockCalled -CommandName Invoke-IntuneGraphRequest -Times 1 -Exactly
        }

        It 'propagates patch errors' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { throw 'patch failed' }

            { Set-Win32AppCommittedContentVersion -AppId 'app-1' -ContentVersionId 'v2' } | Should -Throw 'patch failed'
        }
    }
}
