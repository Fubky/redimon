param([string]$Godot = (Join-Path $PSScriptRoot '..\..\build_tools\godot\godot.exe'))
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$env:APPDATA = Join-Path $projectRoot 'diagnostics\appdata'
New-Item -ItemType Directory -Force $env:APPDATA | Out-Null
function Invoke-GameCheck([string]$Name, [string[]]$CheckArguments) {
    $outputPath = Join-Path $projectRoot "diagnostics\$Name.log"
    $errorPath = Join-Path $projectRoot "diagnostics\$Name.errors.log"
    $arguments = @('--headless', '--path', ('"' + $projectRoot + '"')) + $CheckArguments
    $process = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputPath -RedirectStandardError $errorPath
    if (-not $process.WaitForExit(45000)) { $process.Kill(); throw "$Name timed out; see $errorPath" }
    $process.Refresh()
    Get-Content -LiteralPath $outputPath
    if ($process.ExitCode -ne 0) { throw "$Name failed; see $errorPath" }
    if (Select-String -LiteralPath $errorPath -Pattern 'SCRIPT ERROR|Parse Error|FAIL:|Failed to load script' -Quiet) { throw "$Name has script errors; see $errorPath" }
}
Invoke-GameCheck 'import' @('--editor', '--import', '--quit')
Invoke-GameCheck 'rules' @('--script', 'res://tests/test_rules.gd')
Invoke-GameCheck 'ui' @('--script', 'res://tests/test_ui.gd', '--', '--integration')
Invoke-GameCheck 'controls' @('--script', 'res://tests/test_controls.gd', '--', '--integration')
Invoke-GameCheck 'genetic_skills' @('--script', 'res://tests/test_genetic_skills.gd', '--', '--integration')
Invoke-GameCheck 'battle_depth' @('--script', 'res://tests/test_battle_depth.gd')
Invoke-GameCheck 'runtime_ux' @('--script', 'res://tests/test_runtime_ux.gd', '--', '--integration')
Invoke-GameCheck 'art_v7' @('--script', 'res://tests/test_art_v7.gd', '--', '--integration')
Invoke-GameCheck 'creature_assembly' @('--script', 'res://tests/test_creature_assembly.gd', '--', '--integration')
Invoke-GameCheck 'mercenary' @('--script', 'res://tests/test_mercenary.gd')
Invoke-GameCheck 'bloodline' @('--script', 'res://tests/test_bloodline.gd')
Invoke-GameCheck 'creation_sliders' @('--script', 'res://tests/test_creation_sliders.gd', '--', '--integration')
Invoke-GameCheck 'expedition_tactics' @('--script', 'res://tests/test_expedition_tactics.gd')
Write-Output 'All checks passed. Test progress is isolated under diagnostics/appdata.'
