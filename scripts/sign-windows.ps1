# Authenticode-sign every .exe and .dll in a Windows build folder.
#
# Usage: $env:PFX_B64=...; $env:PFX_PASS=...; ./sign-windows.ps1 -Dir <Release folder>
#
# The .pfx is written to a temp file and deleted afterwards.
# Fails if the secret is missing or any file cannot be signed.
param([Parameter(Mandatory = $true)][string]$Dir)
$ErrorActionPreference = 'Stop'

if (-not $env:PFX_B64) { throw "DESKTOP_SIGN_PFX_BASE64 secret is missing" }
if (-not (Test-Path $Dir)) { throw "build folder not found: $Dir" }

$tmp = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
$pfx = Join-Path $tmp "codesign.pfx"
try {
  [IO.File]::WriteAllBytes($pfx, [Convert]::FromBase64String($env:PFX_B64))
  $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($pfx, $env:PFX_PASS)
  $files = Get-ChildItem $Dir -Recurse -Include *.exe, *.dll
  if (-not $files) { throw "no .exe / .dll found under $Dir" }
  foreach ($f in $files) {
    $r = Set-AuthenticodeSignature -FilePath $f.FullName -Certificate $cert -HashAlgorithm SHA256 -TimestampServer http://timestamp.digicert.com
    if (-not $r.SignerCertificate) { throw "Signing failed: $($f.Name) $($r.StatusMessage)" }
    Write-Host "signed $($f.Name)"
  }
  Write-Host "OK: signed $($files.Count) files"
}
finally {
  Remove-Item $pfx -Force -ErrorAction SilentlyContinue
}
