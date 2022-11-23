@echo off
color 0a
cd ..
echo Installing and updating libraries.
haxelib install flixel-addons 2.11.0
haxelib install flixel-ui 2.4.0
haxelib install hscript
haxelib install hxcodec
haxelib remove discord_rpc
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib remove linc_luajit
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit
echo Libraries installed and updated.
pause
echo Setting up Flixel.
haxelib install lime 8.0.0
haxelib install openfl 9.2.0
haxelib install flixel 4.11.0
haxelib run lime setup
echo Flixel setup complete.
echo Please install "MSVC v142 - VS 2019 C++ x64/x86 build tools" and "Windows SDK (10.0.17763.0)" to complete the compile prerequisites.
pause
