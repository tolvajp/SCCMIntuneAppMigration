function New-DetectionRule {
    <#
    .SYNOPSIS
    Dispatches detection rule creation to the appropriate helper.

    .DESCRIPTION
    Calls one of the dedicated detection helpers based on RuleType:
    - New-FileDetectionRule
    - New-RegistryDetectionRule
    - New-MsiDetectionRule

    Parameters for the selected helper are passed via the Parameters hashtable.
    The function is fail-fast and throws if RuleType is unsupported, the target helper is missing,
    or the forwarded parameters are invalid.

    .PARAMETER RuleType
    Detection rule category to create.

    .PARAMETER Parameters
    Hashtable of parameters forwarded to the selected helper.

    .OUTPUTS
    hashtable

    .EXAMPLE
    New-DetectionRule -RuleType File -Parameters @{
        Path = 'C:\Program Files\Notepad++'
        FileOrFolderName = 'notepad++.exe'
        Exists = $true
    }

    .EXAMPLE
    New-DetectionRule -RuleType Msi -Parameters @{
        ProductCode = '{11111111-2222-3333-4444-555555555555}'
        ProductCodeExists = $true
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('File', 'Registry', 'Msi')]
        [string]$RuleType,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [hashtable]$Parameters
    )

    $helperName = switch ($RuleType) {
        'File' { 'New-FileDetectionRule' }
        'Registry' { 'New-RegistryDetectionRule' }
        'Msi' { 'New-MsiDetectionRule' }
        default { throw "Unsupported RuleType '$RuleType'." }
    }

    $command = Get-Command -Name $helperName -CommandType Function -ErrorAction SilentlyContinue
    if (-not $command) {
        throw "Required helper '$helperName' was not found."
    }

    try {
        return & $helperName @Parameters
    }
    catch {
        throw "Failed to build '$RuleType' detection rule by '$helperName'. Error: $($_.Exception.Message)"
    }
}
