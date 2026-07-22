param(
  [Parameter(Mandatory=$true)][string]$ProjectRoot,
  [Parameter(Mandatory=$true)][string]$QemuExe,
  [Parameter(Mandatory=$true)][string]$OvmfCode,
  [Parameter(Mandatory=$true)][string]$FatDir,
  [Parameter(Mandatory=$true)][string]$ExpectedVersionFile,
  [string]$QemuArgs = '-machine q35 -m 256M -vga std -display sdl',
  [string]$ProcessName = 'qemu-system-x86_64',
  [int]$IntervalMs = 1000,
  [int]$MaxShots = 60
)
$ErrorActionPreference = 'Stop'
foreach ($path in @($QemuExe, $OvmfCode, $FatDir, $ExpectedVersionFile)) {
  if (!(Test-Path $path)) { throw "path not found: $path" }
}
if (!(Get-ChildItem -Path $FatDir -Filter *.efi -Recurse | Select-Object -First 1)) {
  throw "no .efi found in $FatDir"
}
$runLogs = Join-Path $ProjectRoot 'run_logs'
$snapshot = Join-Path $ProjectRoot 'snapshot'
New-Item -ItemType Directory -Force -Path $runLogs, $snapshot | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$serial = Join-Path $runLogs ($stamp + '_serial.log')
$args = "$QemuArgs -drive if=pflash,format=raw,readonly=on,file=`"$OvmfCode`" -drive format=raw,file=fat:rw:`"$FatDir`" -serial file:`"$serial`""
$proc = Start-Process -FilePath $QemuExe -ArgumentList $args -PassThru
Start-Sleep -Seconds 2
& (Join-Path $PSScriptRoot 'Watch-WindowSnapshots.ps1') -ProcessName $ProcessName -SnapshotDir $snapshot -IntervalMs $IntervalMs -MaxShots $MaxShots
if (!$proc.HasExited) {
  $proc.CloseMainWindow() | Out-Null
  $proc.WaitForExit(5000)
  if (!$proc.HasExited) { $proc.Kill() }
}
& (Join-Path $PSScriptRoot 'Test-AppVersion.ps1') -ExpectedVersionFile $ExpectedVersionFile -SerialLog $serial -SnapshotDir $snapshot
