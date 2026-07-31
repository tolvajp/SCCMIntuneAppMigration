Set-StrictMode -Version Latest

Describe 'New-Win32ContentFilePlaceholder' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'creates placeholder and returns file id' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{ id = 'file-1' } }

            (New-Win32ContentFilePlaceholder -AppId 'app-1' -ContentVersionId 'v1' -FileName 'c.bin' -UnencryptedSize 10 -EncryptedSize 20).id | Should -Be 'file-1'
        }

        It 'throws when Graph response has no file id' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { @{} }

            { New-Win32ContentFilePlaceholder -AppId 'app-1' -ContentVersionId 'v1' -FileName 'c.bin' -UnencryptedSize 10 -EncryptedSize 20 } | Should -Throw 'Content file placeholder creation returned no file id.'
        }
    }
}
