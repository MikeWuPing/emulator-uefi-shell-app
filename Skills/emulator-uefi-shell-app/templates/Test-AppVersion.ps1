param(
  [Parameter(Mandatory=$true)][string]$ExpectedVersionFile,
  [Parameter(Mandatory=$true)][string]$SerialLog,
  [string]$SnapshotDir = ''
)
$ErrorActionPreference = 'Stop'
$expected = (Get-Content -Raw $ExpectedVersionFile).Trim()
$content = Get-Content -Raw $SerialLog
$regexMatches = [regex]::Matches($content, 'APP_VERSION=([^\r\n]+)')
if ($regexMatches.Count -eq 0) { throw "APP_VERSION not found in $SerialLog; expected $expected; snapshot=$SnapshotDir" }
$versions = @($regexMatches | ForEach-Object { $_.Groups[1].Value.Trim() } | Select-Object -Unique)
if ($versions.Count -gt 1) { throw "multiple APP_VERSION values found: $($versions -join ', '); log=$SerialLog; snapshot=$SnapshotDir" }
$actual = $versions[0]
if ($actual -ne $expected) { throw "version mismatch: expected=$expected actual=$actual log=$SerialLog snapshot=$SnapshotDir" }
$actual
