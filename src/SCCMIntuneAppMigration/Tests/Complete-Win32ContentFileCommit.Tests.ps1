Set-StrictMode -Version Latest

Describe 'Complete-Win32ContentFileCommit' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'posts commit request with encryption metadata' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith {}
            $enc = [pscustomobject]@{
                EncryptionKey = 'a'; MacKey = 'b'; InitializationVector = 'c'; Mac = 'd'; ProfileIdentifier = 'e'; FileDigest = 'f'; FileDigestAlgorithm = 'g'
            }

            { Complete-Win32ContentFileCommit -AppId 'app-1' -ContentVersionId 'v1' -FileId 'f1' -EncryptionInfo $enc } | Should -Not -Throw
            Assert-MockCalled -CommandName Invoke-IntuneGraphRequest -Times 1 -Exactly
        }

        It 'propagates commit request errors' {
            Mock -CommandName Invoke-IntuneGraphRequest -MockWith { throw 'commit failed' }
            $enc = [pscustomobject]@{
                EncryptionKey = 'a'; MacKey = 'b'; InitializationVector = 'c'; Mac = 'd'; ProfileIdentifier = 'e'; FileDigest = 'f'; FileDigestAlgorithm = 'g'
            }

            { Complete-Win32ContentFileCommit -AppId 'app-1' -ContentVersionId 'v1' -FileId 'f1' -EncryptionInfo $enc } | Should -Throw 'commit failed'
        }
    }
}
