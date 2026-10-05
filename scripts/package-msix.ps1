# Build an MSIX for the Microsoft Store from an existing `flutter build windows` output.
#
# Usage (from the Flutter project folder, khmer_calendar/):
#   ../scripts/package-msix.ps1 -IdentityName ... -Publisher "CN=..." -PublisherDisplayName ... -OutDir <dir>
#
# The three identity values come from Partner Center (Product > Product identity). The
# package is intentionally UNSIGNED (--store): the Store signs it with a Microsoft
# certificate after certification, which is what removes the SmartScreen warning.
# An unsigned .msix cannot be double-click installed locally - it is only for upload.
#
# Fails if the .msix is missing, or its manifest identity / version does not match.
param(
  [Parameter(Mandatory = $true)][string]$IdentityName,
  [Parameter(Mandatory = $true)][string]$Publisher,
  [Parameter(Mandatory = $true)][string]$PublisherDisplayName,
  [Parameter(Mandatory = $true)][string]$OutDir
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path pubspec.yaml)) { throw "run this from the Flutter project folder (pubspec.yaml not found)" }

# 1.0.3+4 -> 1.0.3.0  (Store rule: the 4th number must be 0)
$ver = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value -replace '\+.*$', ''
if ($ver -notmatch '^\d+\.\d+\.\d+$') { throw "unexpected app version '$ver' (want x.y.z)" }
$msixVer = "$ver.0"
Write-Host "app version $ver -> msix version $msixVer"

New-Item -ItemType Directory -Force $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path

# Only in this CI workspace - the repo's pubspec.yaml is not committed back.
flutter pub add --dev msix
if ($LASTEXITCODE -ne 0) { throw "flutter pub add msix failed" }

dart run msix:create --store --build-windows false `
  --display-name "Khmer Calendar" `
  --publisher-display-name $PublisherDisplayName `
  --identity-name $IdentityName `
  --publisher $Publisher `
  --version $msixVer `
  --logo-path assets/icons/icon-512.png `
  --capabilities "internetClient,location" `
  --output-path $OutDir --output-name KhmerCalendar
if ($LASTEXITCODE -ne 0) { throw "msix:create failed" }

$msix = Get-ChildItem $OutDir -Filter *.msix | Select-Object -First 1
if (-not $msix) { throw "no .msix produced in $OutDir" }
Write-Host ("produced {0} ({1:N1} MB)" -f $msix.Name, ($msix.Length / 1MB))

# Check what Partner Center will see.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead($msix.FullName)
try {
  $entry = $zip.Entries | Where-Object { $_.FullName -eq 'AppxManifest.xml' }
  if (-not $entry) { throw "AppxManifest.xml missing in the package" }
  $sr = New-Object IO.StreamReader($entry.Open()); $xml = [xml]$sr.ReadToEnd(); $sr.Close()
  $id = $xml.Package.Identity
  Write-Host "manifest: Name=$($id.Name) Publisher=$($id.Publisher) Version=$($id.Version)"
  $problems = @()
  if ($id.Name -ne $IdentityName) { $problems += "identity name '$($id.Name)' != '$IdentityName'" }
  if ($id.Publisher -ne $Publisher) { $problems += "publisher '$($id.Publisher)' != '$Publisher'" }
  if ($id.Version -ne $msixVer) { $problems += "version '$($id.Version)' != '$msixVer'" }
  if (-not ($zip.Entries | Where-Object { $_.FullName -eq 'khmer_calendar.exe' })) { $problems += "khmer_calendar.exe missing in package" }
  foreach ($need in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    if (-not ($zip.Entries | Where-Object { $_.FullName -eq $need })) { $problems += "$need missing in package" }
  }
  Write-Host "::notice title=MSIX manifest::Name=$($id.Name) Publisher=$($id.Publisher) Version=$($id.Version) files=$($zip.Entries.Count)"
} finally { $zip.Dispose() }
if ($problems) { throw ($problems -join "; ") }
Write-Host "OK: MSIX ready for Partner Center upload"
