param(
  [Parameter(Mandatory=$true)][string]$ProcessName,
  [Parameter(Mandatory=$true)][string]$SnapshotDir,
  [int]$IntervalMs = 1000,
  [int]$MaxShots = 60
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $SnapshotDir | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT lpRect);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
  public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
  public struct POINT { public int X; public int Y; }
}
'@
for ($i = 0; $i -lt $MaxShots; $i++) {
  $p = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if ($null -eq $p) { break }
  $rect = New-Object Win32+RECT
  $point = New-Object Win32+POINT
  [void][Win32]::GetClientRect($p.MainWindowHandle, [ref]$rect)
  [void][Win32]::ClientToScreen($p.MainWindowHandle, [ref]$point)
  $w = $rect.Right - $rect.Left
  $h = $rect.Bottom - $rect.Top
  if ($w -gt 0 -and $h -gt 0) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($point.X, $point.Y, 0, 0, $bmp.Size)
    $name = Join-Path $SnapshotDir ((Get-Date).ToString('yyyyMMdd_HHmmss_fff') + '.png')
    $bmp.Save($name, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
  }
  Start-Sleep -Milliseconds $IntervalMs
}
