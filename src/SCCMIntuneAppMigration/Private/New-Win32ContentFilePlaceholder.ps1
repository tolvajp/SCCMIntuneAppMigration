function New-Win32ContentFilePlaceholder {
    <#
    .SYNOPSIS
    Creates a content file placeholder for Win32 package upload.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ContentVersionId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName,

        [Parameter(Mandatory)]
        [ValidateRange(1, [int64]::MaxValue)]
        [int64]$UnencryptedSize,

        [Parameter(Mandatory)]
        [ValidateRange(1, [int64]::MaxValue)]
        [int64]$EncryptedSize
    )

    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppId/microsoft.graph.win32LobApp/contentVersions/$ContentVersionId/files"
    $body = @{
        '@odata.type' = '#microsoft.graph.mobileAppContentFile'
        name = $FileName
        size = $UnencryptedSize
        sizeEncrypted = $EncryptedSize
        isDependency = $false
    }

    $contentFile = Invoke-IntuneGraphRequest -Method POST -Uri $uri -Body $body
    if (-not $contentFile.id) {
        throw 'Content file placeholder creation returned no file id.'
    }

    return $contentFile
}
