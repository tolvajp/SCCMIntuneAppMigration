function Wait-Win32ContentFileCommit {
    <#
    .SYNOPSIS
    Waits for Win32 content file commit to complete successfully.
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
        $state = [string]$file.uploadState

        if ($state -eq 'commitFileSuccess') {
            return
        }

        if ($state -match 'error|failed') {
            throw "Content file commit failed. uploadState='$state'."
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }

    throw "Timed out while waiting for content file commit. FileId='$FileId'."
}
