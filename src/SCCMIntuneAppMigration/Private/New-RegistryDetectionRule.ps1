function New-RegistryDetectionRule {
    <#
    .SYNOPSIS
    Creates a Microsoft Graph Win32 registry detection rule object.

    .DESCRIPTION
    Builds a hashtable for the Graph resource type microsoft.graph.win32LobAppRegistryDetection.
    The function is fail-fast and validates parameter combinations by using parameter sets.

    Supported detection methods are aligned to Microsoft documentation:
    exists, doesNotExist, string, integer, version.

    Microsoft references:
    https://learn.microsoft.com/graph/api/resources/intune-apps-win32lobappregistrydetection?view=graph-rest-beta
    https://learn.microsoft.com/graph/api/resources/intune-apps-win32lobappregistrydetectiontype?view=graph-rest-beta
    https://learn.microsoft.com/graph/api/resources/intune-apps-win32lobappdetectionoperator?view=graph-rest-beta

    .PARAMETER KeyPath
    Registry key path to evaluate (for example: HKEY_LOCAL_MACHINE\SOFTWARE\Contoso).

    .PARAMETER Check32BitOn64System
    Indicates whether the rule should evaluate 32-bit context on 64-bit clients.

    .PARAMETER KeyExists
    Creates an "exists" detection rule for a registry key.

    .PARAMETER ValueExists
    Creates an "exists" detection rule for a registry value. Requires ValueName.

    .PARAMETER KeyDoesNotExist
    Creates a "doesNotExist" detection rule for a registry key.

    .PARAMETER ValueDoesNotExist
    Creates a "doesNotExist" detection rule for a registry value. Requires ValueName.

    .PARAMETER String
    Creates a "string" detection rule. Requires ValueName, Operator and StringValue.

    .PARAMETER Integer
    Creates an "integer" detection rule. Requires ValueName, Operator and IntegerValue.

    .PARAMETER Version
    Creates a "version" detection rule. Requires ValueName, Operator and VersionValue.

    .PARAMETER ValueName
    Registry value name used for value-based detection methods.

    .PARAMETER Operator
    Comparison operator for string/integer/version detection methods.
    Valid values: equal, notEqual, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual.

    .PARAMETER StringValue
    Comparison value used by String method.

    .PARAMETER IntegerValue
    Comparison value used by Integer method.

    .PARAMETER VersionValue
    Comparison value used by Version method.

    .OUTPUTS
    hashtable
    #>
    [CmdletBinding(DefaultParameterSetName = 'KeyExists')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyPath,

        [Parameter(ParameterSetName = 'KeyExists', Mandatory)]
        [switch]$KeyExists,

        [Parameter(ParameterSetName = 'ValueExists', Mandatory)]
        [switch]$ValueExists,

        [Parameter(ParameterSetName = 'KeyDoesNotExist', Mandatory)]
        [switch]$KeyDoesNotExist,

        [Parameter(ParameterSetName = 'ValueDoesNotExist', Mandatory)]
        [switch]$ValueDoesNotExist,

        [Parameter(ParameterSetName = 'String', Mandatory)]
        [switch]$String,

        [Parameter(ParameterSetName = 'Integer', Mandatory)]
        [switch]$Integer,

        [Parameter(ParameterSetName = 'Version', Mandatory)]
        [switch]$Version,

        [Parameter(ParameterSetName = 'ValueExists', Mandatory)]
        [Parameter(ParameterSetName = 'ValueDoesNotExist', Mandatory)]
        [Parameter(ParameterSetName = 'String', Mandatory)]
        [Parameter(ParameterSetName = 'Integer', Mandatory)]
        [Parameter(ParameterSetName = 'Version', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ValueName,

        [Parameter(ParameterSetName = 'String', Mandatory)]
        [Parameter(ParameterSetName = 'Integer', Mandatory)]
        [Parameter(ParameterSetName = 'Version', Mandatory)]
        [ValidateSet('equal', 'notEqual', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual')]
        [string]$Operator,

        [Parameter(ParameterSetName = 'String', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$StringValue,

        [Parameter(ParameterSetName = 'Integer', Mandatory)]
        [int64]$IntegerValue,

        [Parameter(ParameterSetName = 'Version', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [version]$VersionValue,

        [Parameter()]
        [bool]$Check32BitOn64System = $false
    )

    $rule = @{
        '@odata.type' = '#microsoft.graph.win32LobAppRegistryDetection'
        keyPath = $KeyPath
        check32BitOn64System = $Check32BitOn64System
    }

    switch ($PSCmdlet.ParameterSetName) {
        'KeyExists' {
            $rule.detectionType = 'exists'
            break
        }
        'ValueExists' {
            $rule.detectionType = 'exists'
            $rule.valueName = $ValueName
            break
        }
        'KeyDoesNotExist' {
            $rule.detectionType = 'doesNotExist'
            break
        }
        'ValueDoesNotExist' {
            $rule.detectionType = 'doesNotExist'
            $rule.valueName = $ValueName
            break
        }
        'String' {
            $rule.detectionType = 'string'
            $rule.valueName = $ValueName
            $rule.operator = $Operator
            $rule.detectionValue = $StringValue
            break
        }
        'Integer' {
            $rule.detectionType = 'integer'
            $rule.valueName = $ValueName
            $rule.operator = $Operator
            $rule.detectionValue = [string]$IntegerValue
            break
        }
        'Version' {
            $rule.detectionType = 'version'
            $rule.valueName = $ValueName
            $rule.operator = $Operator
            $rule.detectionValue = $VersionValue.ToString()
            break
        }
        default {
            throw "Unsupported parameter set '$($PSCmdlet.ParameterSetName)'."
        }
    }

    return $rule
}
