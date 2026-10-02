@echo off
setlocal
cd /d "%~dp0"
if not exist "%~dp0..\build_tools\godot\godot.exe" goto missing
start "" /D "%~dp0." "%~dp0..\build_tools\godot\godot.exe" --editor --path "%~dp0." %*
if errorlevel 1 goto failed
exit /b 0

:missing
echo Godot 4.7 could not be found. Import project.godot in Godot 4.7.
pause
exit /b 1

:failed
echo Unable to start the Godot editor. Please check the executable path.
pause
exit /b 1
