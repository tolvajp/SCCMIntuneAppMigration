function Complete-Win32ContentFileCommit {
    <#
    .SYNOPSIS
    Commits uploaded Win32 content file with encryption metadata.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [string]$ContentVersionId,

        [Parameter(Mandatory)]
        [string]$FileId,

        [Parameter(Mandatory)]
        [pscustomobject]$EncryptionInfo
    )

    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppId/microsoft.graph.win32LobApp/contentVersions/$ContentVersionId/files/$FileId/commit"
    $body = @{
        fileEncryptionInfo = @{
            '@odata.type' = '#microsoft.graph.fileEncryptionInfo'
            encryptionKey = $EncryptionInfo.EncryptionKey
            macKey = $EncryptionInfo.MacKey
            initializationVector = $EncryptionInfo.InitializationVector
            mac = $EncryptionInfo.Mac
            profileIdentifier = $EncryptionInfo.ProfileIdentifier
            fileDigest = $EncryptionInfo.FileDigest
            fileDigestAlgorithm = $EncryptionInfo.FileDigestAlgorithm
        }
    }

    Invoke-IntuneGraphRequest -Method POST -Uri $uri -Body $body | Out-Null
}
