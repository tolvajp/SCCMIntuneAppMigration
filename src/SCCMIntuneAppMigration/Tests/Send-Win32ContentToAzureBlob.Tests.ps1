Set-StrictMode -Version Latest

Describe 'Send-Win32ContentToAzureBlob' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'uploads blocks and block list' {
            $tempFile = Join-Path $env:TEMP ("upload_" + [guid]::NewGuid().ToString() + '.bin')
            [System.IO.File]::WriteAllBytes($tempFile, (1..1048576 | ForEach-Object { [byte]($_ % 255) }))

            try {
                $script:webCalls = 0
                Mock -CommandName Invoke-WebRequest -MockWith {
                    $script:webCalls++
                    [pscustomobject]@{ StatusCode = 201 }
                }

                Send-Win32ContentToAzureBlob -FilePath $tempFile -AzureStorageUri 'https://storage.example/blob?sas=1' -BlockSizeInBytes 1048576
                $script:webCalls | Should -BeGreaterThan 1
            }
            finally {
                Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
            }
        }

        It 'throws when upload file does not exist' {
            { Send-Win32ContentToAzureBlob -FilePath 'C:\does-not-exist\missing.bin' -AzureStorageUri 'https://storage.example/blob?sas=1' } | Should -Throw "Upload file not found*"
        }

        It 'wraps web upload errors' {
            $tempFile = Join-Path $env:TEMP ("upload_" + [guid]::NewGuid().ToString() + '.bin')
            [System.IO.File]::WriteAllBytes($tempFile, (1..1048576 | ForEach-Object { [byte]($_ % 255) }))

            try {
                Mock -CommandName Invoke-WebRequest -MockWith { throw 'network error' }

                { Send-Win32ContentToAzureBlob -FilePath $tempFile -AzureStorageUri 'https://storage.example/blob?sas=1' -BlockSizeInBytes 1048576 } | Should -Throw 'Azure blob upload failed*'
            }
            finally {
                Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
            }
        }
    }
}
