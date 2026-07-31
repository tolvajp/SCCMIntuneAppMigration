function Assert-Win32AppDoesNotExist {
    <#
    .SYNOPSIS
    Throws if a Win32 app with the same display name already exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName
    )

    $escapedDisplayName = $DisplayName.Replace("'", "''")
    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=displayName eq '$escapedDisplayName'"
    $result = Invoke-IntuneGraphRequest -Method GET -Uri $uri

    if (-not $result.value) {
        return
    }

    $existing = $result.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.win32LobApp' } | Select-Object -First 1
    if ($existing) {
        throw "A Win32 app already exists with display name '$DisplayName' (id: $($existing.id))."
    }
}
