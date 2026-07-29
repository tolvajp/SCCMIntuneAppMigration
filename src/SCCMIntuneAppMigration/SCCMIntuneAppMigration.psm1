Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private\*.ps1') -File -ErrorAction SilentlyContinue | ForEach-Object {
	. $_.FullName
}

Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public\*.ps1') -File -ErrorAction SilentlyContinue | ForEach-Object {
	. $_.FullName
}

$publicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public\*.ps1') -File -ErrorAction SilentlyContinue |
	Select-Object -ExpandProperty BaseName

if ($publicFunctions) {
	Export-ModuleMember -Function $publicFunctions
}


