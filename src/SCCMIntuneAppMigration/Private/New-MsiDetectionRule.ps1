function New-MsiDetectionRule {
    <#
    .SYNOPSIS
    Creates a Microsoft Graph Win32 MSI product code detection rule object.

    .DESCRIPTION
    Builds a hashtable for the Graph resource type microsoft.graph.win32LobAppProductCodeDetection.
    The function is fail-fast and validates parameter combinations by using parameter sets.

    Microsoft reference:
    https://learn.microsoft.com/graph/api/resources/intune-apps-win32lobappproductcodedetection?view=graph-rest-beta

    .PARAMETER ProductCode
    MSI product code (GUID).

    .PARAMETER ProductCodeExists
    Creates a rule that checks MSI existence by product code only.

    .PARAMETER ProductVersion
    Creates a rule that checks MSI version by product code and version comparison.

    .PARAMETER ProductVersionOperator
    Comparison operator for MSI version detection.
    Valid values: equal, notEqual, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual.

    .PARAMETER VersionValue
    Product version value used with ProductVersion parameter set.

    .OUTPUTS
    hashtable

    .EXAMPLE
    New-MsiDetectionRule -ProductCode '{11111111-2222-3333-4444-555555555555}' -ProductCodeExists

    .EXAMPLE
    New-MsiDetectionRule -ProductCode '{11111111-2222-3333-4444-555555555555}' -ProductVersion -ProductVersionOperator greaterThanOrEqual -VersionValue '8.9.7.0'
    #>
    [CmdletBinding(DefaultParameterSetName = 'ProductCodeExists')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ProductCode,

        [Parameter(ParameterSetName = 'ProductCodeExists', Mandatory)]
        [switch]$ProductCodeExists,

        [Parameter(ParameterSetName = 'ProductVersion', Mandatory)]
        [switch]$ProductVersion,

        [Parameter(ParameterSetName = 'ProductVersion', Mandatory)]
        [ValidateSet('equal', 'notEqual', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual')]
        [string]$ProductVersionOperator,

        [Parameter(ParameterSetName = 'ProductVersion', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [version]$VersionValue
    )

    try {
        $parsedGuid = [guid]::Parse($ProductCode)
    }
    catch {
        throw "Invalid MSI product code '$ProductCode'. Expected a GUID value."
    }

    $rule = @{
        '@odata.type' = '#microsoft.graph.win32LobAppProductCodeDetection'
        productCode = $parsedGuid.ToString('B').ToUpperInvariant()
    }

    if ($PSCmdlet.ParameterSetName -eq 'ProductVersion') {
        $rule.productVersionOperator = $ProductVersionOperator
        $rule.productVersion = $VersionValue.ToString()
    }

    return $rule
}
