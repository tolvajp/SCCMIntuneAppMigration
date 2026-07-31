function Invoke-IntuneGraphRequest {
    <#
    .SYNOPSIS
    Executes a Microsoft Graph request with fail-fast error handling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('GET', 'POST', 'PATCH')]
        [string]$Method,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter()]
        [AllowNull()]
        [object]$Body
    )

    try {
        if ($PSBoundParameters.ContainsKey('Body')) {
            $jsonBody = $Body | ConvertTo-Json -Depth 30
            return Invoke-MgGraphRequest -Method $Method -Uri $Uri -Body $jsonBody -ContentType 'application/json'
        }

        return Invoke-MgGraphRequest -Method $Method -Uri $Uri
    }
    catch {
        throw "Graph request failed. Method=$Method Uri=$Uri Error=$($_.Exception.Message)"
    }
}
