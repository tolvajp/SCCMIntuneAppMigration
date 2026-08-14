function New-DetectionRule {
    <#
    .SYNOPSIS
    Creates a Win32 detection rule object for use with Publish-IntuneWin32App.

    .DESCRIPTION
    Public wrapper for the internal detection rule factory. Users can call this function directly
    to build a rule object that can be passed into the DetectionRules parameter of Publish-IntuneWin32App.

    .PARAMETER RuleType
    Detection rule category to create.

    .PARAMETER Parameters
    Hashtable of parameters forwarded to the selected detection rule helper.

    .OUTPUTS
    hashtable
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('File', 'Registry', 'Msi', 'Script')]
        [string]$RuleType,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]$Parameters
    )

    return New-IntuneDetectionRule -RuleType $RuleType -Parameters $Parameters
}
