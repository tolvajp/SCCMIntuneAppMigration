function Get-IntuneWinPackageMetadata {
    <#
    .SYNOPSIS
    Reads metadata from an .intunewin package required for upload and commit.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$IntuneWinFilePath
    )

    if (-not (Test-Path -LiteralPath $IntuneWinFilePath -PathType Leaf)) {
        throw "Intune package file not found: '$IntuneWinFilePath'."
    }

    $extractPath = Join-Path $env:TEMP ("sccmintune_" + [guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $extractPath -ErrorAction Stop | Out-Null

    Expand-Archive -LiteralPath $IntuneWinFilePath -DestinationPath $extractPath -Force

    $detectionXmlPath = Join-Path $extractPath 'IntuneWinPackage\Metadata\Detection.xml'
    if (-not (Test-Path -LiteralPath $detectionXmlPath -PathType Leaf)) {
        throw "Detection.xml not found in package '$IntuneWinFilePath'."
    }

    [xml]$detectionXml = Get-Content -LiteralPath $detectionXmlPath -ErrorAction Stop

    $innerFileName = [string]$detectionXml.ApplicationInfo.FileName
    if ([string]::IsNullOrWhiteSpace($innerFileName)) {
        throw 'Package metadata does not contain ApplicationInfo.FileName.'
    }

    $encryptedFilePath = Join-Path $extractPath (Join-Path 'IntuneWinPackage\Contents' $innerFileName)
    if (-not (Test-Path -LiteralPath $encryptedFilePath -PathType Leaf)) {
        throw "Encrypted content file not found in package contents: '$encryptedFilePath'."
    }

    $encryptedFile = Get-Item -LiteralPath $encryptedFilePath -ErrorAction Stop
    $unencryptedContentSize = [int64]$detectionXml.ApplicationInfo.UnencryptedContentSize
    if ($unencryptedContentSize -lt 0) {
        throw 'Invalid UnencryptedContentSize in Detection.xml.'
    }

    return [pscustomobject]@{
        ExtractionPath = $extractPath
        EncryptedFilePath = $encryptedFile.FullName
        EncryptedFileName = $encryptedFile.Name
        EncryptedFileSize = [int64]$encryptedFile.Length
        UnencryptedContentSize = $unencryptedContentSize
        EncryptionInfo = [pscustomobject]@{
            EncryptionKey = [string]$detectionXml.ApplicationInfo.EncryptionInfo.EncryptionKey
            MacKey = [string]$detectionXml.ApplicationInfo.EncryptionInfo.MacKey
            InitializationVector = [string]$detectionXml.ApplicationInfo.EncryptionInfo.InitializationVector
            Mac = [string]$detectionXml.ApplicationInfo.EncryptionInfo.Mac
            ProfileIdentifier = [string]$detectionXml.ApplicationInfo.EncryptionInfo.ProfileIdentifier
            FileDigest = [string]$detectionXml.ApplicationInfo.EncryptionInfo.FileDigest
            FileDigestAlgorithm = [string]$detectionXml.ApplicationInfo.EncryptionInfo.FileDigestAlgorithm
        }
    }
}
