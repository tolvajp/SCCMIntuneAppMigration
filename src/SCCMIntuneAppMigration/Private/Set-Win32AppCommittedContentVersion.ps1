function Set-Win32AppCommittedContentVersion {
    <#
    .SYNOPSIS
    Sets committedContentVersion on a Win32 LOB app.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [string]$ContentVersionId
    )

    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppId"
    $body = @{
        '@odata.type' = '#microsoft.graph.win32LobApp'
        committedContentVersion = $ContentVersionId
    }

    Invoke-IntuneGraphRequest -Method PATCH -Uri $uri -Body $body | Out-Null
}
