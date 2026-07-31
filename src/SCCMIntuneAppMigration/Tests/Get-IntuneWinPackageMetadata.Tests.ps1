Set-StrictMode -Version Latest

Describe 'Get-IntuneWinPackageMetadata' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestBootstrap.ps1')
        Import-SccmIntuneModuleForTests
    }

    InModuleScope 'SCCMIntuneAppMigration' {
        It 'reads metadata from valid intunewin package structure' {
            $root = Join-Path $env:TEMP ("meta_src_" + [guid]::NewGuid().ToString())
            $pkgPath = Join-Path $env:TEMP ("meta_" + [guid]::NewGuid().ToString() + '.intunewin')

            try {
                $metaDir = Join-Path $root 'IntuneWinPackage\Metadata'
                $contentDir = Join-Path $root 'IntuneWinPackage\Contents'
                New-Item -ItemType Directory -Path $metaDir -Force | Out-Null
                New-Item -ItemType Directory -Path $contentDir -Force | Out-Null

                $encryptedName = 'encrypted.bin'
                [System.IO.File]::WriteAllBytes((Join-Path $contentDir $encryptedName), [byte[]](1,2,3,4))

                $xml = @"
<ApplicationInfo>
  <FileName>$encryptedName</FileName>
  <UnencryptedContentSize>4</UnencryptedContentSize>
  <EncryptionInfo>
    <EncryptionKey>a</EncryptionKey>
    <MacKey>b</MacKey>
    <InitializationVector>c</InitializationVector>
    <Mac>d</Mac>
    <ProfileIdentifier>e</ProfileIdentifier>
    <FileDigest>f</FileDigest>
    <FileDigestAlgorithm>g</FileDigestAlgorithm>
  </EncryptionInfo>
</ApplicationInfo>
"@
                Set-Content -LiteralPath (Join-Path $metaDir 'Detection.xml') -Value $xml -Encoding UTF8

                $zipPath = [System.IO.Path]::ChangeExtension($pkgPath, '.zip')
                Compress-Archive -Path (Join-Path $root '*') -DestinationPath $zipPath -Force
                Move-Item -LiteralPath $zipPath -Destination $pkgPath -Force

                $meta = Get-IntuneWinPackageMetadata -IntuneWinFilePath $pkgPath
                $meta.EncryptedFileName | Should -Be $encryptedName
                $meta.UnencryptedContentSize | Should -Be 4
                $meta.EncryptionInfo.FileDigestAlgorithm | Should -Be 'g'

                Remove-TemporaryPackageExtraction -ExtractionPath $meta.ExtractionPath
            }
            finally {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $pkgPath -Force -ErrorAction SilentlyContinue
            }
        }

        It 'throws when package file does not exist' {
            { Get-IntuneWinPackageMetadata -IntuneWinFilePath 'C:\does-not-exist\app.intunewin' } | Should -Throw 'Intune package file not found*'
        }

        It 'throws when Detection.xml is missing' {
            $root = Join-Path $env:TEMP ("meta_src_" + [guid]::NewGuid().ToString())
            $pkgPath = Join-Path $env:TEMP ("meta_" + [guid]::NewGuid().ToString() + '.intunewin')

            try {
                New-Item -ItemType Directory -Path (Join-Path $root 'IntuneWinPackage\Metadata') -Force | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $root 'IntuneWinPackage\Contents') -Force | Out-Null

                $zipPath = [System.IO.Path]::ChangeExtension($pkgPath, '.zip')
                Compress-Archive -Path (Join-Path $root '*') -DestinationPath $zipPath -Force
                Move-Item -LiteralPath $zipPath -Destination $pkgPath -Force

                { Get-IntuneWinPackageMetadata -IntuneWinFilePath $pkgPath } | Should -Throw '*Detection.xml not found*'
            }
            finally {
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $pkgPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
