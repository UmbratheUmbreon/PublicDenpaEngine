@echo off
color 0a
cd ..
echo Installing and updating libraries.
haxelib install flixel-addons 3.0.2
haxelib install flixel-ui 2.5.0
haxelib install hscript
haxelib install flxanimate 3.0.4
haxelib install hxCodec 2.6.1
haxelib remove discord_rpc
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib remove linc_luajit
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit
echo Libraries installed and updated.
pause
echo Setting up Flixel.
haxelib install lime 8.0.1
haxelib install openfl 9.2.1
haxelib install flixel 5.2.2
haxelib run lime setup
echo Flixel setup complete.
echo Please install "MSVC v142 - VS 2019 C++ x64/x86 build tools Latest" and "Windows SDK (10.0.17763.0)" to complete the compile prerequisites.
pause
