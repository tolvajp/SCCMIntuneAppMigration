function New-ScriptDetectionRule {
    <#
    .SYNOPSIS
    Creates a Microsoft Graph Win32 PowerShell script detection rule object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptContent,

        [Parameter()]
        [bool]$EnforceSignatureCheck = $false,

        [Parameter()]
        [bool]$RunAs32Bit = $false
    )

    return @{
        '@odata.type' = '#microsoft.graph.win32LobAppPowerShellScriptDetection'
        scriptContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ScriptContent))
        enforceSignatureCheck = $EnforceSignatureCheck
        runAs32Bit = $RunAs32Bit
    }
}
