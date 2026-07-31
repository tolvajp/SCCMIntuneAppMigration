function Get-Win32ContentFile {
    <#
    .SYNOPSIS
    Gets a Win32 content file metadata object from Graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [string]$ContentVersionId,

        [Parameter(Mandatory)]
        [string]$FileId
    )

    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppId/microsoft.graph.win32LobApp/contentVersions/$ContentVersionId/files/$FileId"
    return Invoke-IntuneGraphRequest -Method GET -Uri $uri
}
