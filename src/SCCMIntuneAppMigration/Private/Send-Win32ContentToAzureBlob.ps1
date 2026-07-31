function Send-Win32ContentToAzureBlob {
    <#
    .SYNOPSIS
    Uploads encrypted Win32 package content to Azure Blob using SAS URI.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AzureStorageUri,

        [Parameter()]
        [ValidateRange(1MB, 16MB)]
        [int]$BlockSizeInBytes = 4MB
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "Upload file not found: '$FilePath'."
    }

    $stream = [System.IO.File]::OpenRead($FilePath)
    $blockIds = New-Object System.Collections.Generic.List[string]

    try {
        $buffer = New-Object byte[] $BlockSizeInBytes
        $index = 0

        while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $rawBlockId = '{0:D8}' -f $index
            $blockId = [Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($rawBlockId))
            $blockIds.Add($blockId)

            $payload = if ($bytesRead -eq $buffer.Length) {
                $buffer
            }
            else {
                $chunk = New-Object byte[] $bytesRead
                [Array]::Copy($buffer, 0, $chunk, 0, $bytesRead)
                $chunk
            }

            $blockUri = "$AzureStorageUri&comp=block&blockid=$([uri]::EscapeDataString($blockId))"
            Invoke-WebRequest -Method Put -Uri $blockUri -Body $payload -UseBasicParsing | Out-Null

            $index++
        }

        if ($blockIds.Count -eq 0) {
            throw 'No upload blocks were generated.'
        }

        $blockListXml = New-Object System.Text.StringBuilder
        [void]$blockListXml.Append('<BlockList>')
        foreach ($id in $blockIds) {
            [void]$blockListXml.Append("<Latest>$id</Latest>")
        }
        [void]$blockListXml.Append('</BlockList>')

        $blockListUri = "$AzureStorageUri&comp=blocklist"
        Invoke-WebRequest -Method Put -Uri $blockListUri -Body $blockListXml.ToString() -ContentType 'application/xml' -UseBasicParsing | Out-Null
    }
    catch {
        throw "Azure blob upload failed. Error: $($_.Exception.Message)"
    }
    finally {
        $stream.Dispose()
    }
}
