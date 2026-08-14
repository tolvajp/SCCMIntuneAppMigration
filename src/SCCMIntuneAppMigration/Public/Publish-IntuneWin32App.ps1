function Publish-IntuneWin32App {
    <#
    .SYNOPSIS
    Creates, uploads, and publishes an Intune Win32 app in a fail-fast flow.

    .DESCRIPTION
    Orchestrates package creation, app draft creation, content upload, commit, and publish.
    Expects an existing Graph session; does not perform authentication.

    .PARAMETER DisplayName
    App display name.

    .PARAMETER Description
    App description.

    .PARAMETER Publisher
    App publisher.

    .PARAMETER SourceFolder
    Source folder for IntuneWinAppUtil packaging.

    .PARAMETER SetupFileName
    Setup file name in SourceFolder.

    .PARAMETER OutputLocation
    Output folder where .intunewin package will be created.

    .PARAMETER InstallCommandLine
    Install command line.

    .PARAMETER UninstallCommandLine
    Uninstall command line.

    .PARAMETER DetectionRules
    Detection rules collection as hashtable[].

    .PARAMETER RequirementRules
    Optional requirement rules collection.

    .PARAMETER ApplicableArchitecture
    App architecture constraint.

    .PARAMETER MinimumSupportedWindowsRelease
    Minimum supported Windows release.

    .PARAMETER InformationUrl
    Optional information URL.

    .PARAMETER PrivacyInformationUrl
    Optional privacy URL.

    .PARAMETER Developer
    Optional developer text.

    .PARAMETER Owner
    Optional owner text.

    .PARAMETER Notes
    Optional notes text.

    .PARAMETER LargeIcon
    Optional Graph mimeContent object for app icon.

    .PARAMETER Dependencies
    Optional dependencies collection as hashtable[].
    Each dependency item must contain:
    - targetDisplayName
    - dependencyType (detect or autoInstall)

    .OUTPUTS
    PSCustomObject
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
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
        [string]$SourceFolder,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SetupFileName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
        [string]$OutputLocation,

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
        [hashtable]$LargeIcon,

        [Parameter()]
        [hashtable[]]$Dependencies = @()
    )

    $ErrorActionPreference = 'Stop'

    Assert-GraphSessionForWin32App
    Assert-Win32AppDoesNotExist -DisplayName $DisplayName

    $package = New-IntuneWin32Package -SourceFolder $SourceFolder -SetupFileName $SetupFileName -OutputLocation $OutputLocation
    $metadata = $null

    try {
        $metadata = Get-IntuneWinPackageMetadata -IntuneWinFilePath $package.FullName

        $appBody = New-Win32LobAppBody -DisplayName $DisplayName -Description $Description -Publisher $Publisher -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -SetupFilePath $SetupFileName -DetectionRules $DetectionRules -RequirementRules $RequirementRules -ApplicableArchitecture $ApplicableArchitecture -MinimumSupportedWindowsRelease $MinimumSupportedWindowsRelease -InformationUrl $InformationUrl -PrivacyInformationUrl $PrivacyInformationUrl -Developer $Developer -Owner $Owner -Notes $Notes -LargeIcon $LargeIcon
        $app = New-Win32LobApp -Body $appBody

        $contentVersion = New-Win32ContentVersion -AppId $app.id
        $contentFile = New-Win32ContentFilePlaceholder -AppId $app.id -ContentVersionId $contentVersion.id -FileName $metadata.EncryptedFileName -UnencryptedSize $metadata.UnencryptedContentSize -EncryptedSize $metadata.EncryptedFileSize

        $contentFile = Wait-Win32ContentFileAzureStorageUri -AppId $app.id -ContentVersionId $contentVersion.id -FileId $contentFile.id
        Send-Win32ContentToAzureBlob -FilePath $metadata.EncryptedFilePath -AzureStorageUri $contentFile.azureStorageUri

        Complete-Win32ContentFileCommit -AppId $app.id -ContentVersionId $contentVersion.id -FileId $contentFile.id -EncryptionInfo $metadata.EncryptionInfo
        Wait-Win32ContentFileCommit -AppId $app.id -ContentVersionId $contentVersion.id -FileId $contentFile.id
        Set-Win32AppCommittedContentVersion -AppId $app.id -ContentVersionId $contentVersion.id

        if ($Dependencies.Count -gt 0) {
            Set-Win32AppDependencies -AppId $app.id -Dependencies $Dependencies
        }

        return [pscustomobject]@{
            AppId = $app.id
            DisplayName = $app.displayName
            ContentVersionId = $contentVersion.id
            ContentFileId = $contentFile.id
            DependencyCount = $Dependencies.Count
            IntuneWinFilePath = $package.FullName
        }
    }
    finally {
        if ($metadata) {
            Remove-TemporaryPackageExtraction -ExtractionPath $metadata.ExtractionPath
        }
    }
}
