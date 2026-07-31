Set-StrictMode -Version Latest

Describe 'Publish-IntuneWin32App' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    It 'is exported as public command' {
        (Get-Command -Name Publish-IntuneWin32App -Module SCCMIntuneAppMigration -ErrorAction Stop).Name | Should -Be 'Publish-IntuneWin32App'
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'orchestrates full flow and returns summary object' {
            Mock -CommandName Assert-GraphSessionForWin32App -MockWith {}
            Mock -CommandName Assert-Win32AppDoesNotExist -MockWith {}
            Mock -CommandName New-IntuneWin32Package -MockWith { [pscustomobject]@{ FullName = 'C:\tmp\app.intunewin' } }
            Mock -CommandName Get-IntuneWinPackageMetadata -MockWith {
                [pscustomobject]@{
                    ExtractionPath = 'C:\tmp\extract'
                    EncryptedFilePath = 'C:\tmp\enc.bin'
                    EncryptedFileName = 'enc.bin'
                    EncryptedFileSize = 100
                    UnencryptedContentSize = 90
                    EncryptionInfo = [pscustomobject]@{ EncryptionKey='a'; MacKey='b'; InitializationVector='c'; Mac='d'; ProfileIdentifier='e'; FileDigest='f'; FileDigestAlgorithm='g' }
                }
            }
            Mock -CommandName New-Win32LobAppBody -MockWith { @{ displayName = 'App' } }
            Mock -CommandName New-Win32LobApp -MockWith { @{ id = 'app-1'; displayName = 'App' } }
            Mock -CommandName New-Win32ContentVersion -MockWith { @{ id = 'v1' } }
            Mock -CommandName New-Win32ContentFilePlaceholder -MockWith { @{ id = 'f1' } }
            Mock -CommandName Wait-Win32ContentFileAzureStorageUri -MockWith { @{ id = 'f1'; azureStorageUri = 'https://storage.example/sas' } }
            Mock -CommandName Send-Win32ContentToAzureBlob -MockWith {}
            Mock -CommandName Complete-Win32ContentFileCommit -MockWith {}
            Mock -CommandName Wait-Win32ContentFileCommit -MockWith {}
            Mock -CommandName Set-Win32AppCommittedContentVersion -MockWith {}
            Mock -CommandName Set-Win32AppDependencies -MockWith {}
            Mock -CommandName Remove-TemporaryPackageExtraction -MockWith {}

            $src = Join-Path $env:TEMP ("pub_src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("pub_out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null

            try {
                $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\Program Files\App'; fileOrFolderName = 'app.exe' }
                $result = Publish-IntuneWin32App -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -SourceFolder $src -SetupFileName 'setup.exe' -OutputLocation $out -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @($rule)

                $result.AppId | Should -Be 'app-1'
                $result.ContentVersionId | Should -Be 'v1'
                $result.ContentFileId | Should -Be 'f1'
                $result.DependencyCount | Should -Be 0
                Assert-MockCalled -CommandName Set-Win32AppCommittedContentVersion -Times 1 -Exactly
                Assert-MockCalled -CommandName Set-Win32AppDependencies -Times 0 -Exactly
                Assert-MockCalled -CommandName Remove-TemporaryPackageExtraction -Times 1 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'applies dependencies when provided' {
            Mock -CommandName Assert-GraphSessionForWin32App -MockWith {}
            Mock -CommandName Assert-Win32AppDoesNotExist -MockWith {}
            Mock -CommandName New-IntuneWin32Package -MockWith { [pscustomobject]@{ FullName = 'C:\tmp\app.intunewin' } }
            Mock -CommandName Get-IntuneWinPackageMetadata -MockWith {
                [pscustomobject]@{
                    ExtractionPath = 'C:\tmp\extract'
                    EncryptedFilePath = 'C:\tmp\enc.bin'
                    EncryptedFileName = 'enc.bin'
                    EncryptedFileSize = 100
                    UnencryptedContentSize = 90
                    EncryptionInfo = [pscustomobject]@{ EncryptionKey='a'; MacKey='b'; InitializationVector='c'; Mac='d'; ProfileIdentifier='e'; FileDigest='f'; FileDigestAlgorithm='g' }
                }
            }
            Mock -CommandName New-Win32LobAppBody -MockWith { @{ displayName = 'App' } }
            Mock -CommandName New-Win32LobApp -MockWith { @{ id = 'app-1'; displayName = 'App' } }
            Mock -CommandName New-Win32ContentVersion -MockWith { @{ id = 'v1' } }
            Mock -CommandName New-Win32ContentFilePlaceholder -MockWith { @{ id = 'f1' } }
            Mock -CommandName Wait-Win32ContentFileAzureStorageUri -MockWith { @{ id = 'f1'; azureStorageUri = 'https://storage.example/sas' } }
            Mock -CommandName Send-Win32ContentToAzureBlob -MockWith {}
            Mock -CommandName Complete-Win32ContentFileCommit -MockWith {}
            Mock -CommandName Wait-Win32ContentFileCommit -MockWith {}
            Mock -CommandName Set-Win32AppCommittedContentVersion -MockWith {}
            Mock -CommandName Set-Win32AppDependencies -MockWith {}
            Mock -CommandName Remove-TemporaryPackageExtraction -MockWith {}

            $src = Join-Path $env:TEMP ("pub_src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("pub_out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null

            try {
                $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\Program Files\App'; fileOrFolderName = 'app.exe' }
                $deps = @(
                    @{ targetDisplayName = 'Dependency One'; dependencyType = 'autoInstall' },
                    @{ targetDisplayName = 'Dependency Two'; dependencyType = 'detect' }
                )
                $result = Publish-IntuneWin32App -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -SourceFolder $src -SetupFileName 'setup.exe' -OutputLocation $out -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @($rule) -Dependencies $deps

                $result.DependencyCount | Should -Be 2
                Assert-MockCalled -CommandName Set-Win32AppDependencies -Times 1 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'stops immediately when app already exists' {
            Mock -CommandName Assert-GraphSessionForWin32App -MockWith {}
            Mock -CommandName Assert-Win32AppDoesNotExist -MockWith { throw 'already exists' }
            Mock -CommandName New-IntuneWin32Package -MockWith { throw 'should not be called' }

            $src = Join-Path $env:TEMP ("pub_src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("pub_out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null

            try {
                $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\Program Files\App'; fileOrFolderName = 'app.exe' }
                { Publish-IntuneWin32App -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -SourceFolder $src -SetupFileName 'setup.exe' -OutputLocation $out -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @($rule) } | Should -Throw 'already exists'

                Assert-MockCalled -CommandName New-IntuneWin32Package -Times 0 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'runs cleanup when failure happens after metadata extraction' {
            Mock -CommandName Assert-GraphSessionForWin32App -MockWith {}
            Mock -CommandName Assert-Win32AppDoesNotExist -MockWith {}
            Mock -CommandName New-IntuneWin32Package -MockWith { [pscustomobject]@{ FullName = 'C:\tmp\app.intunewin' } }
            Mock -CommandName Get-IntuneWinPackageMetadata -MockWith {
                [pscustomobject]@{
                    ExtractionPath = 'C:\tmp\extract'
                    EncryptedFilePath = 'C:\tmp\enc.bin'
                    EncryptedFileName = 'enc.bin'
                    EncryptedFileSize = 100
                    UnencryptedContentSize = 90
                    EncryptionInfo = [pscustomobject]@{ EncryptionKey='a'; MacKey='b'; InitializationVector='c'; Mac='d'; ProfileIdentifier='e'; FileDigest='f'; FileDigestAlgorithm='g' }
                }
            }
            Mock -CommandName New-Win32LobAppBody -MockWith { @{ displayName = 'App' } }
            Mock -CommandName New-Win32LobApp -MockWith { throw 'create failed' }
            Mock -CommandName Remove-TemporaryPackageExtraction -MockWith {}

            $src = Join-Path $env:TEMP ("pub_src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("pub_out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null

            try {
                $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\Program Files\App'; fileOrFolderName = 'app.exe' }
                { Publish-IntuneWin32App -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -SourceFolder $src -SetupFileName 'setup.exe' -OutputLocation $out -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @($rule) } | Should -Throw 'create failed'

                Assert-MockCalled -CommandName Remove-TemporaryPackageExtraction -Times 1 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'does not run cleanup when metadata extraction itself fails' {
            Mock -CommandName Assert-GraphSessionForWin32App -MockWith {}
            Mock -CommandName Assert-Win32AppDoesNotExist -MockWith {}
            Mock -CommandName New-IntuneWin32Package -MockWith { [pscustomobject]@{ FullName = 'C:\tmp\app.intunewin' } }
            Mock -CommandName Get-IntuneWinPackageMetadata -MockWith { throw 'metadata failed' }
            Mock -CommandName Remove-TemporaryPackageExtraction -MockWith {}

            $src = Join-Path $env:TEMP ("pub_src_" + [guid]::NewGuid().ToString())
            $out = Join-Path $env:TEMP ("pub_out_" + [guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $src | Out-Null
            New-Item -ItemType Directory -Path $out | Out-Null

            try {
                $rule = @{ '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'; detectionType = 'exists'; path = 'C:\Program Files\App'; fileOrFolderName = 'app.exe' }
                { Publish-IntuneWin32App -DisplayName 'App' -Description 'Desc' -Publisher 'Pub' -SourceFolder $src -SetupFileName 'setup.exe' -OutputLocation $out -InstallCommandLine 'setup.exe /S' -UninstallCommandLine 'uninst.exe /S' -DetectionRules @($rule) } | Should -Throw 'metadata failed'

                Assert-MockCalled -CommandName Remove-TemporaryPackageExtraction -Times 0 -Exactly
            }
            finally {
                Remove-Item -LiteralPath $src -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $out -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
