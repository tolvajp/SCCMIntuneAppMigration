function New-Win32LobAppBody {
    <#
    .SYNOPSIS
    Builds the Graph request body for creating a Win32 LOB app.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Publisher,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallCommandLine,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UninstallCommandLine,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable[]]$DetectionRules,

        [Parameter()]
        [hashtable[]]$RequirementRules = @(),

        [Parameter()]
        [ValidateSet('x86', 'x64', 'arm64')]
        [string]$ApplicableArchitecture = 'x64',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$MinimumSupportedWindowsRelease = 'Windows10_1607',

        [Parameter()]
        [AllowEmptyString()]
        [string]$InformationUrl,

        [Parameter()]
        [AllowEmptyString()]
        [string]$PrivacyInformationUrl,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Developer,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Owner,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Notes,

        [Parameter()]
        [AllowNull()]
        [hashtable]$LargeIcon
    )

    if ($DetectionRules.Count -eq 0) {
        throw 'At least one detection rule is required.'
    }

    $body = @{
        '@odata.type' = '#microsoft.graph.win32LobApp'
        displayName = $DisplayName
        description = $Description
        publisher = $Publisher
        installCommandLine = $InstallCommandLine
        uninstallCommandLine = $UninstallCommandLine
        applicableArchitectures = $ApplicableArchitecture
        minimumSupportedWindowsRelease = $MinimumSupportedWindowsRelease
        informationUrl = $InformationUrl
        privacyInformationUrl = $PrivacyInformationUrl
        developer = $Developer
        owner = $Owner
        notes = $Notes
        detectionRules = $DetectionRules
        requirementRules = $RequirementRules
        returnCodes = @(
            @{ returnCode = 0; type = 'success' },
            @{ returnCode = 1707; type = 'success' },
            @{ returnCode = 3010; type = 'softReboot' },
            @{ returnCode = 1641; type = 'hardReboot' },
            @{ returnCode = 1618; type = 'retry' }
        )
        installExperience = @{
            runAsAccount = 'system'
            deviceRestartBehavior = 'basedOnReturnCode'
        }
    }

    if ($LargeIcon) {
        $body.largeIcon = $LargeIcon
    }

    return $body
}
