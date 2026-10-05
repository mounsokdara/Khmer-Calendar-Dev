# Check the finished Windows zip the way a clean PC would see it, and report it as
# GitHub annotations (::notice::) + the job summary.
#
# Usage: ./verify-windows.ps1 -Zip KhmerCalendar-windows.zip -Exe khmer_calendar.exe
#
# Fails if: a Visual C++ runtime DLL is missing, or the exe still shows the default
# Flutter icon (blue) instead of the app icon.
param(
  [Parameter(Mandatory = $true)][string]$Zip,
  [string]$Exe = 'khmer_calendar.exe'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("verify-" + [guid]::NewGuid())
Expand-Archive -Path $Zip -DestinationPath $tmp -Force
$files = Get-ChildItem $tmp -Recurse -File
$names = ($files | ForEach-Object { $_.FullName.Substring($tmp.Length + 1) } | Sort-Object)
Write-Host "zip contains $($names.Count) files"
$names | ForEach-Object { Write-Host "  $_" }
Write-Host "::notice title=Windows zip files::$($names -join ', ')"

$problems = @()
foreach ($need in $Exe, 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'flutter_windows.dll') {
  if ($names -notcontains $need) { $problems += "missing in zip: $need" }
}

# Icon: render the exe's icon and look at its colours. App icon = red/green calendar,
# Flutter default = light-blue. Compare average red vs blue of the opaque pixels.
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Join-Path $tmp $Exe))
$bmp = $icon.ToBitmap()
$r = 0; $b = 0; $n = 0
for ($x = 0; $x -lt $bmp.Width; $x++) {
  for ($y = 0; $y -lt $bmp.Height; $y++) {
    $p = $bmp.GetPixel($x, $y)
    if ($p.A -gt 200) { $r += $p.R; $b += $p.B; $n++ }
  }
}
if ($n -eq 0) { $problems += "exe icon is empty" }
else {
  $avgR = [int]($r / $n); $avgB = [int]($b / $n)
  Write-Host "exe icon $($bmp.Width)px: avg R=$avgR B=$avgB over $n px"
  Write-Host "::notice title=Windows exe icon::avg R=$avgR B=$avgB (app icon is red-ish, Flutter default is blue)"
  if ($avgB -gt $avgR) { $problems += "exe still has the blue default Flutter icon (R=$avgR B=$avgB)" }
}

$summary = "### Windows package`n- files: $($names.Count)`n- runtime DLLs: " +
  (($names | Where-Object { $_ -match '^(msvcp|vcruntime|concrt)' }) -join ', ')
if ($env:GITHUB_STEP_SUMMARY) { Add-Content $env:GITHUB_STEP_SUMMARY $summary }
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
if ($problems) { throw ($problems -join "; ") }
Write-Host "OK: package verified"
