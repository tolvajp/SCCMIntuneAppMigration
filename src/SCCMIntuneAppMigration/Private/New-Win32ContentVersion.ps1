function New-Win32ContentVersion {
    <#
    .SYNOPSIS
    Creates a new content version for an existing Win32 LOB app.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppId
    )

    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppId/microsoft.graph.win32LobApp/contentVersions"
    $contentVersion = Invoke-IntuneGraphRequest -Method POST -Uri $uri -Body @{}
    if (-not $contentVersion.id) {
        throw 'Content version creation returned no id.'
    }

    return $contentVersion
}
