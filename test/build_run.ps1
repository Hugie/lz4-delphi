# LZ4 include test suite (v1.10.0): struct layout guard + functional roundtrip
# Builds and runs pSizes + pRoundtrip for Win32 and Win64 (Delphi 13.1);
# with -D7 additionally cross-builds with Delphi 7 (oldest supported compiler).
# Exit code 0 = all green.
param(
  [string]$Dcc32 = 'C:\delphi\13.1\bin\dcc32.exe',
  [string]$Dcc64 = 'C:\delphi\13.1\bin\dcc64.exe',
  [string]$Lib32 = 'C:\delphi\13.1\lib\win32\release',
  [string]$Lib64 = 'C:\delphi\13.1\lib\win64\release',
  [switch]$D7,
  [string]$D7Root = 'C:\delphi\7'
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
$ns = 'System;Winapi;System.Win'
$fails = 0

foreach ($t in 'pSizes','pRoundtrip') {
  foreach ($p in '32','64') {
    $dcc = if ($p -eq '32') { $Dcc32 } else { $Dcc64 }
    $lib = if ($p -eq '32') { $Lib32 } else { $Lib64 }
    New-Item -ItemType Directory -Force "out$p","dcu$p" | Out-Null
    Write-Host "=== $t (Win$p) ===" -ForegroundColor Cyan
    & $dcc -B --no-config -NS"$ns" -U"$lib" -E"out$p" -NU"dcu$p" "$t.dpr" 2>&1 |
      Where-Object { $_ -match 'Error|Fatal|Warning' } | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    if (-not (Test-Path "out$p\$t.exe")) { Write-Host "BUILD FAILED $t Win$p" -ForegroundColor Red; $fails++; continue }
    & ".\out$p\$t.exe"
    if ($LASTEXITCODE -ne 0) { Write-Host "TEST FAILED $t Win$p (exit $LASTEXITCODE)" -ForegroundColor Red; $fails++ }
  }
}

if ($D7) {
  # D7's dcc32 blocks forever in headless environments if stdin stays open
  # -> ProcessStartInfo + StandardInput.Close()
  New-Item -ItemType Directory -Force "outD7","dcuD7" | Out-Null
  foreach ($t in 'pSizes','pRoundtrip') {
    Write-Host "=== $t (Delphi 7) ===" -ForegroundColor Cyan
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "$D7Root\bin\dcc32.exe"
    $psi.Arguments = "-B -U`"$D7Root\lib`" -N0`"$PSScriptRoot\dcuD7`" -E`"$PSScriptRoot\outD7`" `"$PSScriptRoot\$t.dpr`""
    $psi.UseShellExecute = $false; $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = $PSScriptRoot
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.StandardInput.Close()
    $so = $p.StandardOutput.ReadToEnd(); [void]$p.StandardError.ReadToEnd()
    $p.WaitForExit()
    ($so -split "`n") | Where-Object { $_ -match 'Error|Fatal' } | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    if ($p.ExitCode -ne 0 -or -not (Test-Path "outD7\$t.exe")) { Write-Host "BUILD FAILED $t D7" -ForegroundColor Red; $fails++; continue }
    & ".\outD7\$t.exe"
    if ($LASTEXITCODE -ne 0) { Write-Host "TEST FAILED $t D7 (exit $LASTEXITCODE)" -ForegroundColor Red; $fails++ }
  }
}

if ($fails -eq 0) { Write-Host "`nALL TESTS OK" -ForegroundColor Green } else { Write-Host "`n$fails FAILURES" -ForegroundColor Red }
exit $fails
