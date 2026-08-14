function Get-Win32AppIdByDisplayName {
    <#
    .SYNOPSIS
    Resolves a Win32 app id from Intune by display name.

    .DESCRIPTION
    Queries Microsoft Graph mobileApps endpoint with displayName filter,
    restricts matches to win32LobApp, and returns a single id.
    Throws when not found or when multiple Win32 apps share the same display name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName
    )

    $escapedDisplayName = $DisplayName.Replace("'", "''")
    $encodedFilter = [Uri]::EscapeDataString("displayName eq '$escapedDisplayName'")
    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$filter=$encodedFilter"
    $result = Invoke-IntuneGraphRequest -Method GET -Uri $uri

    $matches = @($result.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.win32LobApp' })

    if ($matches.Count -eq 0) {
        throw "No Win32 app found with display name '$DisplayName'."
    }

    if ($matches.Count -gt 1) {
        $ids = ($matches | ForEach-Object { $_.id }) -join ', '
        throw "Multiple Win32 apps found with display name '$DisplayName'. Matching ids: $ids"
    }

    return [string]$matches[0].id
}
