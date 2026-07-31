function Set-Win32AppDependencies {
    <#
    .SYNOPSIS
    Sets dependency relationships for a Win32 app using updateRelationships.

    .DESCRIPTION
    Resolves dependency app ids by display name, then sends a POST request to
    /deviceAppManagement/mobileApps/{mobileAppId}/updateRelationships with a
    mobileAppDependency relationships collection.

    Microsoft Learn reference:
    https://learn.microsoft.com/graph/api/intune-apps-mobileapp-updaterelationships?view=graph-rest-beta
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AppId,

        [Parameter()]
        [AllowNull()]
        [hashtable[]]$Dependencies = @()
    )

    if ($null -eq $Dependencies -or $Dependencies.Count -eq 0) {
        return
    }

    $relationships = @()
    foreach ($dependency in $Dependencies) {
        if (-not $dependency.ContainsKey('targetDisplayName') -or [string]::IsNullOrWhiteSpace([string]$dependency.targetDisplayName)) {
            throw 'Each dependency must contain a non-empty targetDisplayName.'
        }

        $targetDisplayName = [string]$dependency.targetDisplayName
        $targetId = Get-Win32AppIdByDisplayName -DisplayName $targetDisplayName

        if ($targetId -eq $AppId) {
            throw 'A Win32 app cannot depend on itself.'
        }

        if (-not $dependency.ContainsKey('dependencyType') -or [string]::IsNullOrWhiteSpace([string]$dependency.dependencyType)) {
            throw 'Each dependency must contain dependencyType (detect or autoInstall).'
        }

        $dependencyType = [string]$dependency.dependencyType
        if ($dependencyType -notin @('detect', 'autoInstall')) {
            throw "Unsupported dependencyType '$dependencyType'. Allowed values: detect, autoInstall."
        }

        $relationships += @{
            '@odata.type' = '#microsoft.graph.mobileAppDependency'
            targetId = $targetId
            dependencyType = $dependencyType
        }
    }

    $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppId/updateRelationships"
    $body = @{ relationships = $relationships }
    Invoke-IntuneGraphRequest -Method POST -Uri $uri -Body $body | Out-Null
}
