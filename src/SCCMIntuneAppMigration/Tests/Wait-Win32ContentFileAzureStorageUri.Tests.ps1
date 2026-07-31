Set-StrictMode -Version Latest

Describe 'Wait-Win32ContentFileAzureStorageUri' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'returns file object once azureStorageUri is present' {
            $script:calls = 0
            Mock -CommandName Get-Win32ContentFile -MockWith {
                $script:calls++
                if ($script:calls -lt 2) { return @{ azureStorageUri = '' } }
                return @{ azureStorageUri = 'https://storage.example/sas' }
            }
            Mock -CommandName Start-Sleep -MockWith {}

            (Wait-Win32ContentFileAzureStorageUri -AppId 'a' -ContentVersionId 'v' -FileId 'f' -TimeoutSeconds 5 -PollIntervalSeconds 1).azureStorageUri | Should -Be 'https://storage.example/sas'
        }

        It 'throws on timeout when azureStorageUri never appears' {
            Mock -CommandName Get-Win32ContentFile -MockWith { @{ azureStorageUri = '' } }
            Mock -CommandName Start-Sleep -MockWith {}

            { Wait-Win32ContentFileAzureStorageUri -AppId 'a' -ContentVersionId 'v' -FileId 'f' -TimeoutSeconds 1 -PollIntervalSeconds 1 } | Should -Throw '*Timed out*'
        }
    }
}
