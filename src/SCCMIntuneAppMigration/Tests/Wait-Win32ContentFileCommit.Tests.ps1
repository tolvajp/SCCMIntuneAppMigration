Set-StrictMode -Version Latest

Describe 'Wait-Win32ContentFileCommit' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'returns when commit state becomes success' {
            $script:calls = 0
            Mock -CommandName Get-Win32ContentFile -MockWith {
                $script:calls++
                if ($script:calls -lt 2) { return @{ uploadState = 'commitFilePending' } }
                return @{ uploadState = 'commitFileSuccess' }
            }
            Mock -CommandName Start-Sleep -MockWith {}

            { Wait-Win32ContentFileCommit -AppId 'a' -ContentVersionId 'v' -FileId 'f' -TimeoutSeconds 5 -PollIntervalSeconds 1 } | Should -Not -Throw
        }

        It 'throws when commit state reports error' {
            Mock -CommandName Get-Win32ContentFile -MockWith { @{ uploadState = 'commitFileFailed' } }
            Mock -CommandName Start-Sleep -MockWith {}

            { Wait-Win32ContentFileCommit -AppId 'a' -ContentVersionId 'v' -FileId 'f' -TimeoutSeconds 5 -PollIntervalSeconds 1 } | Should -Throw '*failed*'
        }

        It 'throws on timeout when commit never completes' {
            Mock -CommandName Get-Win32ContentFile -MockWith { @{ uploadState = 'commitFilePending' } }
            Mock -CommandName Start-Sleep -MockWith {}

            { Wait-Win32ContentFileCommit -AppId 'a' -ContentVersionId 'v' -FileId 'f' -TimeoutSeconds 1 -PollIntervalSeconds 1 } | Should -Throw '*Timed out*'
        }
    }
}
