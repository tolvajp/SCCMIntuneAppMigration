function New-IntuneWin32Package {
    <#
    .SYNOPSIS
    Creates an .intunewin package by using IntuneWinAppUtil.exe.

    .DESCRIPTION
    Packages a setup file from a source folder into an Intune Win32 content file by calling the IntuneWinAppUtil.exe
    utility that ships in the module's Tools folder.

    .PARAMETER SourceFolder
    The folder that contains the installer and any supporting content.

    .PARAMETER SetupFileName
    The name of the setup file inside SourceFolder.

    .PARAMETER OutputLocation
    The folder where the generated .intunewin file should be written.

    .OUTPUTS
    System.IO.FileInfo

    .EXAMPLE
    New-IntuneWin32Package -SourceFolder 'C:\Apps\NotepadPlusPlus' -SetupFileName 'npp.8.9.7.Installer.x64.exe' -OutputLocation 'C:\Apps\Output'

    Creates the .intunewin package for the specified setup file and returns the generated file.
    #>
    [CmdletBinding()]
    param(
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
        [string]$OutputLocation
    )

    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $toolPath = Join-Path $moduleRoot 'Tools\IntuneWinAppUtil.exe'

    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "IntuneWinAppUtil.exe was not found at '$toolPath'."
    }

    $setupPath = Join-Path $SourceFolder $SetupFileName
    if (-not (Test-Path -LiteralPath $setupPath -PathType Leaf)) {
        throw "The setup file '$SetupFileName' was not found in '$SourceFolder'."
    }

    $startTime = Get-Date
    $arguments = @(
        '-c', $SourceFolder,
        '-s', $SetupFileName,
        '-o', $OutputLocation,
        '-q'
    )

    $process = Start-Process -FilePath $toolPath -ArgumentList $arguments -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "IntuneWinAppUtil.exe exited with code $($process.ExitCode)."
    }

    $generatedPackage = Get-ChildItem -LiteralPath $OutputLocation -Filter '*.intunewin' -File |
        Where-Object { $_.LastWriteTime -ge $startTime.AddSeconds(-2) } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $generatedPackage) {
        $generatedPackage = Get-ChildItem -LiteralPath $OutputLocation -Filter '*.intunewin' -File |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    }

    if (-not $generatedPackage) {
        throw "The package completed successfully, but no .intunewin file was found in '$OutputLocation'."
    }

    return $generatedPackage
}