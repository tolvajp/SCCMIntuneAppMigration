function Wait-Win32ContentFileAzureStorageUri {
    <#
    .SYNOPSIS
    Waits until Azure Storage URI is available for a Win32 content file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AppId,

        [Parameter(Mandatory)]
        [string]$ContentVersionId,

        [Parameter(Mandatory)]
        [string]$FileId,

        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 600,

        [Parameter()]
        [ValidateRange(1, 60)]
        [int]$PollIntervalSeconds = 5
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $file = Get-Win32ContentFile -AppId $AppId -ContentVersionId $ContentVersionId -FileId $FileId
        if (-not [string]::IsNullOrWhiteSpace($file.azureStorageUri)) {
            return $file
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }

    throw "Timed out while waiting for azureStorageUri for content file '$FileId'."
}
