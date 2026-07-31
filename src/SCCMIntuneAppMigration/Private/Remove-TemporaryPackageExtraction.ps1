function Remove-TemporaryPackageExtraction {
    <#
    .SYNOPSIS
    Removes the extracted package folder used during metadata read/upload.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$ExtractionPath
    )

    if ([string]::IsNullOrWhiteSpace($ExtractionPath)) {
        return
    }

    if (Test-Path -LiteralPath $ExtractionPath -PathType Container) {
        Remove-Item -LiteralPath $ExtractionPath -Recurse -Force -ErrorAction Stop
    }
}
