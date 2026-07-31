function New-Win32LobApp {
    <#
    .SYNOPSIS
    Creates a Win32 LOB app draft in Intune.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Body
    )

    $app = Invoke-IntuneGraphRequest -Method POST -Uri 'https://graph.microsoft.com/beta/deviceAppManagement/mobileApps' -Body $Body
    if (-not $app.id) {
        throw 'Win32 app creation returned no app id.'
    }

    return $app
}
