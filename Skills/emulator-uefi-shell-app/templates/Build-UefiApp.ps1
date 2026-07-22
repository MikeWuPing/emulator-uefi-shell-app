param(
  [Parameter(Mandatory=$true)][string]$ProjectRoot,
  [Parameter(Mandatory=$true)][string]$Edk2Workspace,
  [Parameter(Mandatory=$true)][string]$BuildCommand,
  [Parameter(Mandatory=$true)][string]$OutputHeader,
  [Parameter(Mandatory=$true)][string]$ExpectedVersionFile
)
$ErrorActionPreference = 'Stop'
$v = & (Join-Path $PSScriptRoot 'New-BuildVersion.ps1') -ProjectRoot $ProjectRoot -OutputHeader $OutputHeader
Push-Location $Edk2Workspace
try {
  cmd /c $BuildCommand
  if ($LASTEXITCODE -ne 0) { throw "build failed with exit code $LASTEXITCODE" }
} finally {
  Pop-Location
}
Set-Content -Path $ExpectedVersionFile -Value $v.VersionString
$v
