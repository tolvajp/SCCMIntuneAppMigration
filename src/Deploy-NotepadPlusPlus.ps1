Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $PSScriptRoot 'SCCMIntuneAppMigration/SCCMIntuneAppMigration.psd1'
$detailsPath = Join-Path $repoRoot 'Data/Notepad++/details.json'
$outputLocation = Join-Path $repoRoot 'Data/Notepad++/Output'

if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "Module manifest not found at '$modulePath'."
}

if (-not (Test-Path -LiteralPath $detailsPath -PathType Leaf)) {
    throw "Details file not found at '$detailsPath'."
}

Import-Module -Name $modulePath -Force
New-Item -ItemType Directory -Force -Path $outputLocation | Out-Null

$requiredScopes = @(
    'DeviceManagementApps.ReadWrite.All',
    'DeviceManagementConfiguration.ReadWrite.All'
)

$graphContext = Get-MgContext -ErrorAction SilentlyContinue
if (-not $graphContext) {
    Connect-MgGraph -Scopes $requiredScopes -NoWelcome
}
else {
    $missingScopes = $requiredScopes | Where-Object { $graphContext.Scopes -notcontains $_ }
    if ($missingScopes) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Connect-MgGraph -Scopes $requiredScopes -NoWelcome
    }
}

$details = Get-Content -LiteralPath $detailsPath -Raw | ConvertFrom-Json

$operatorMap = @{
    'Equals' = 'equal'
    'NotEquals' = 'notEqual'
    'GreaterThan' = 'greaterThan'
    'GreaterThanOrEqual' = 'greaterThanOrEqual'
    'LessThan' = 'lessThan'
    'LessThanOrEqual' = 'lessThanOrEqual'
}

$ruleObjects = foreach ($rule in @($details.Detectionrules)) {
    switch ($rule.ruletype.ToString().ToLowerInvariant()) {
        'msi' {
            $operatorName = $operatorMap[$rule.Operator]
            if (-not $operatorName) {
                $operatorName = 'equal'
            }

            if ($rule.PSObject.Properties.Name -contains 'Value' -and -not [string]::IsNullOrWhiteSpace([string]$rule.Value)) {
                New-DetectionRule -RuleType Msi -Parameters @{
                    ProductCode = [string]$rule.productcode
                    ProductVersion = $true
                    ProductVersionOperator = $operatorName
                    VersionValue = [version][string]$rule.Value
                }
            }
            else {
                New-DetectionRule -RuleType Msi -Parameters @{
                    ProductCode = [string]$rule.productcode
                    ProductCodeExists = $true
                }
            }
        }
        'file' {
            $operatorName = $operatorMap[$rule.Operator]
            if (-not $operatorName) {
                $operatorName = 'equal'
            }

            $versionDetection = $rule.Detectionmethod -eq 'VersionComparison'
            if ($versionDetection) {
                New-DetectionRule -RuleType File -Parameters @{
                    Path = [string]$rule.path
                    FileOrFolderName = [string]$rule.filename
                    Version = $true
                    Operator = $operatorName
                    VersionValue = [version][string]$rule.Value
                }
            }
            else {
                New-DetectionRule -RuleType File -Parameters @{
                    Path = [string]$rule.path
                    FileOrFolderName = [string]$rule.filename
                    Exists = $true
                }
            }
        }
        'registry' {
            $operatorName = $operatorMap[$rule.Operator]
            if (-not $operatorName) {
                $operatorName = 'equal'
            }

            if ($rule.Detectionmethod -eq 'VersionComparison') {
                New-DetectionRule -RuleType Registry -Parameters @{
                    KeyPath = [string]$rule.keyPath
                    ValueName = [string]$rule.valueName
                    Version = $true
                    Operator = $operatorName
                    VersionValue = [version][string]$rule.Value
                }
            }
            else {
                New-DetectionRule -RuleType Registry -Parameters @{
                    KeyPath = [string]$rule.keyPath
                    ValueName = [string]$rule.valueName
                    String = $true
                    Operator = $operatorName
                    StringValue = [string]$rule.Value
                }
            }
        }
        default {
            throw "Unsupported detection rule type '$($rule.ruletype)'."
        }
    }
}

$publishArgs = @{
    DisplayName = [string]$details.Name
    Description = [string]$details.Description
    Publisher = if ([string]::IsNullOrWhiteSpace([string]$details.Owner)) { [string]$details.Name } else { [string]$details.Owner }
    SourceFolder = [string]$details.Path
    SetupFileName = [string]$details.Filename
    OutputLocation = $outputLocation
    InstallCommandLine = [string]$details.InstallCommand
    UninstallCommandLine = [string]$details.Uninstallcommand
    DetectionRules = @($ruleObjects)
}

$result = Publish-IntuneWin32App @publishArgs
$result | ConvertTo-Json -Depth 5
