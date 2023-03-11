@echo off
echo If you opened this manually, exit now! If this opened automatically, continue.
pause
echo Finalizing Update.. Make sure the game is closed!
pause
del /f %CD%\DenpaEngine.exe
echo If all went right, the exe should now be deleted, moving new one in!!
pause
move %CD%\assets\temp\updateRaw\DenpaEngine.exe %CD%\DenpaEngine.exe
echo Finished, restart your game now! :)
pause