param(
  [Parameter(Mandatory=$true)][string]$ProjectRoot,
  [Parameter(Mandatory=$true)][string]$OutputHeader
)
$ErrorActionPreference = 'Stop'
$versionFile = Join-Path $ProjectRoot 'VERSION.txt'
if (!(Test-Path $versionFile)) {
  Set-Content -Path $versionFile -Value "VERSION=0.1.0`nBUILD=0"
}
$lines = Get-Content $versionFile
$version = ($lines | Where-Object { $_ -match '^VERSION=' } | Select-Object -First 1).Substring(8)
$build = [int](($lines | Where-Object { $_ -match '^BUILD=' } | Select-Object -First 1).Substring(6)) + 1
Set-Content -Path $versionFile -Value ("VERSION=$version`nBUILD=$build")
$parts = $version.Split('.')
if ($parts.Count -ne 3) { throw "VERSION must be major.minor.patch: $version" }
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$versionString = "$version+$build.$timestamp"
$template = Get-Content -Raw (Join-Path $PSScriptRoot 'Version.h.template')
$header = $template.Replace('@APP_VERSION_MAJOR@', $parts[0]).Replace('@APP_VERSION_MINOR@', $parts[1]).Replace('@APP_VERSION_PATCH@', $parts[2]).Replace('@APP_BUILD_NUMBER@', [string]$build).Replace('@APP_BUILD_TIMESTAMP@', $timestamp).Replace('@APP_VERSION_STRING@', $versionString)
Set-Content -Path $OutputHeader -Value $header
[pscustomobject]@{ Version = $version; Build = $build; Timestamp = $timestamp; VersionString = $versionString; Header = $OutputHeader }
