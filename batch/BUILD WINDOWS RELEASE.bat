@echo off
color 0a
cd ..
echo Building Release.
haxelib run lime build windows
echo.
echo done.
pause
pwd
explorer.exe export\release\windows\bin
