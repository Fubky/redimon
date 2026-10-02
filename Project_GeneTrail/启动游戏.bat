@echo off
setlocal
cd /d "%~dp0"
if exist "%~dp0build\windows\GeneTrail.exe" goto packaged
if exist "%~dp0..\build_tools\godot\godot.exe" goto source
echo Godot 4.7 or the packaged game could not be found.
echo Import project.godot in Godot 4.7 and press F5.
pause
exit /b 1

:packaged
start "" /D "%~dp0build\windows" "%~dp0build\windows\GeneTrail.exe" %*
if errorlevel 1 goto failed
exit /b 0

:source
start "" /D "%~dp0." "%~dp0..\build_tools\godot\godot.exe" --path "%~dp0." %*
if errorlevel 1 goto failed
exit /b 0

:failed
echo Unable to start Gene Trail. Please check the executable path.
pause
exit /b 1
