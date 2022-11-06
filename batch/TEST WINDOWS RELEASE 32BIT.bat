@echo off
color 0a
cd ..
echo Testing Release 32bit.
haxelib run lime test windows -32 -release -D 32bits -D HXCPP_M32
echo.
echo done.
pause