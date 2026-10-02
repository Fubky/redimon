param([string]$Godot = (Join-Path $PSScriptRoot '..\..\build_tools\godot\godot.exe'))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$output = Join-Path $projectRoot 'build\windows\GeneTrail.exe'
$env:APPDATA = Join-Path $projectRoot 'diagnostics\appdata'
New-Item -ItemType Directory -Force $env:APPDATA, (Split-Path $output) | Out-Null
$arguments = @('--headless', '--path', ('"' + $projectRoot + '"'), '--export-release', '"Windows Desktop"', ('"' + $output + '"'))
$process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $projectRoot 'diagnostics\export.log') -RedirectStandardError (Join-Path $projectRoot 'diagnostics\export_error.log')
if ($process.ExitCode -ne 0) { throw 'Export failed; see diagnostics/export_error.log' }
Write-Output "Built $output"
