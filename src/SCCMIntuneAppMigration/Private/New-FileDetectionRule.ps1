function New-FileDetectionRule {
    <#
    .SYNOPSIS
    Creates a Microsoft Graph Win32 file system detection rule object.

    .DESCRIPTION
    Builds a hashtable for the Graph resource type microsoft.graph.win32LobAppFileSystemDetection.
    The function is fail-fast and validates parameter combinations by using parameter sets.

    Supported detection methods are aligned to Microsoft documentation:
    exists, doesNotExist, modifiedDate, createdDate, version, sizeInMB.

    .PARAMETER Path
    File or folder path to evaluate on the client.

    .PARAMETER FileOrFolderName
    File or folder name to evaluate under Path.

    .PARAMETER Check32BitOn64System
    Indicates whether the rule should evaluate 32-bit context on 64-bit clients.

    .PARAMETER Exists
    Creates an "exists" detection rule.

    .PARAMETER DoesNotExist
    Creates a "doesNotExist" detection rule.

    .PARAMETER ModifiedDate
    Creates a "modifiedDate" detection rule. Requires Operator and DateTimeValue.

    .PARAMETER CreatedDate
    Creates a "createdDate" detection rule. Requires Operator and DateTimeValue.

    .PARAMETER Version
    Creates a "version" detection rule. Requires Operator and VersionValue.

    .PARAMETER SizeInMB
    Creates a "sizeInMB" detection rule. Requires Operator and SizeValueInMB.

    .PARAMETER Operator
    Comparison operator for date/version/size detection methods.
    Valid values: equal, notEqual, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual.

    .PARAMETER DateTimeValue
    Comparison date/time value used by ModifiedDate or CreatedDate methods.

    .PARAMETER VersionValue
    Comparison version value used by Version method.

    .PARAMETER SizeValueInMB
    Comparison size value in MB used by SizeInMB method.

    .OUTPUTS
    hashtable

    .EXAMPLE
    New-FileDetectionRule -Path 'C:\Program Files\Notepad++' -FileOrFolderName 'notepad++.exe' -Exists

    .EXAMPLE
    New-FileDetectionRule -Path 'C:\Program Files\Notepad++' -FileOrFolderName 'notepad++.exe' -Version -Operator greaterThanOrEqual -VersionValue '8.9.7.0'

    .EXAMPLE
    New-FileDetectionRule -Path 'C:\Program Files\Contoso' -FileOrFolderName 'agent.dll' -ModifiedDate -Operator greaterThan -DateTimeValue (Get-Date '2025-01-01T00:00:00Z')
    #>
    [CmdletBinding(DefaultParameterSetName = 'Exists')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FileOrFolderName,

        [Parameter(ParameterSetName = 'Exists', Mandatory)]
        [switch]$Exists,

        [Parameter(ParameterSetName = 'DoesNotExist', Mandatory)]
        [switch]$DoesNotExist,

        [Parameter(ParameterSetName = 'ModifiedDate', Mandatory)]
        [switch]$ModifiedDate,

        [Parameter(ParameterSetName = 'CreatedDate', Mandatory)]
        [switch]$CreatedDate,

        [Parameter(ParameterSetName = 'Version', Mandatory)]
        [switch]$Version,

        [Parameter(ParameterSetName = 'SizeInMB', Mandatory)]
        [switch]$SizeInMB,

        [Parameter(ParameterSetName = 'ModifiedDate', Mandatory)]
        [Parameter(ParameterSetName = 'CreatedDate', Mandatory)]
        [Parameter(ParameterSetName = 'Version', Mandatory)]
        [Parameter(ParameterSetName = 'SizeInMB', Mandatory)]
        [ValidateSet('equal', 'notEqual', 'greaterThan', 'greaterThanOrEqual', 'lessThan', 'lessThanOrEqual')]
        [string]$Operator,

        [Parameter(ParameterSetName = 'ModifiedDate', Mandatory)]
        [Parameter(ParameterSetName = 'CreatedDate', Mandatory)]
        [datetime]$DateTimeValue,

        [Parameter(ParameterSetName = 'Version', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [version]$VersionValue,

        [Parameter(ParameterSetName = 'SizeInMB', Mandatory)]
        [ValidateRange(0, 2147483647)]
        [int]$SizeValueInMB,

        [Parameter()]
        [bool]$Check32BitOn64System = $false
    )

    $rule = @{
        '@odata.type' = '#microsoft.graph.win32LobAppFileSystemDetection'
        path = $Path
        fileOrFolderName = $FileOrFolderName
        check32BitOn64System = $Check32BitOn64System
    }

    switch ($PSCmdlet.ParameterSetName) {
        'Exists' {
            $rule.detectionType = 'exists'
            break
        }
        'DoesNotExist' {
            $rule.detectionType = 'doesNotExist'
            break
        }
        'ModifiedDate' {
            $rule.detectionType = 'modifiedDate'
            $rule.operator = $Operator
            $rule.detectionValue = $DateTimeValue.ToUniversalTime().ToString('o')
            break
        }
        'CreatedDate' {
            $rule.detectionType = 'createdDate'
            $rule.operator = $Operator
            $rule.detectionValue = $DateTimeValue.ToUniversalTime().ToString('o')
            break
        }
        'Version' {
            $rule.detectionType = 'version'
            $rule.operator = $Operator
            $rule.detectionValue = $VersionValue.ToString()
            break
        }
        'SizeInMB' {
            $rule.detectionType = 'sizeInMB'
            $rule.operator = $Operator
            $rule.detectionValue = [string]$SizeValueInMB
            break
        }
        default {
            throw "Unsupported parameter set '$($PSCmdlet.ParameterSetName)'."
        }
    }

    return $rule
}
