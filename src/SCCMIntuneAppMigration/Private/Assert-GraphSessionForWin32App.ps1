function Assert-GraphSessionForWin32App {
    <#
    .SYNOPSIS
    Validates that an active Microsoft Graph session exists with required scopes.
    #>
    [CmdletBinding()]
    param()

    $context = Get-MgContext
    if (-not $context) {
        throw "No active Microsoft Graph session found. Connect first with: Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All','DeviceManagementConfiguration.ReadWrite.All'"
    }

    $requiredScopes = @(
        'DeviceManagementApps.ReadWrite.All',
        'DeviceManagementConfiguration.ReadWrite.All'
    )

    foreach ($scope in $requiredScopes) {
        if ($context.Scopes -notcontains $scope) {
            throw "Missing required Graph scope '$scope'."
        }
    }
}
