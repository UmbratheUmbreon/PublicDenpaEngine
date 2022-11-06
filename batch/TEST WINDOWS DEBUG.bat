@echo off
color 0a
cd ..
echo Testing Debug.
haxelib run lime test windows -debug
echo.
echo done.
pause