@echo off
color 0a
cd ..
echo Testing Debug Clean.
haxelib run lime test windows -debug -clean
echo.
echo done.
pause