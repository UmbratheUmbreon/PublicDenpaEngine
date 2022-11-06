@echo off
color 0a
cd ..
echo Testing Release.
haxelib run lime test windows -release
echo.
echo done.
pause