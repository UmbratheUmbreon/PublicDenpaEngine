package;

import lime.app.Application;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class CrashState extends flixel.FlxState {
    public static var log:String;

    override function create() {
        super.create();

        function onClose() {
            FlxG.autoPause = false;
            openURL('https://github.com/UmbratheUmbreon/PublicDenpaEngine/issues');
            openURL('https://discord.gg/BFaMfmTNaa');
        }

        Application.current.window.focus();
        Application.current.window.onClose.add(onClose, false, 0);

        var bg:FlxSprite = new FlxSprite().loadGraphic(returnGraphic('crshbg'));
        bg.scrollFactor.set();
        bg.setGraphicSize(1280, 720);
        bg.updateHitbox();
        bg.setPosition(0, 0);
        add(bg);

        var logo:FlxSprite = new FlxSprite().loadGraphic(returnGraphic('crshlgo'));
        logo.scrollFactor.set();
        logo.scale.set(1.5,1.5);
        logo.updateHitbox();
        logo.setPosition((FlxG.width - logo.width) - 85, (FlxG.height - logo.height) - 50);
        logo.alpha = 0;
        add(logo);

        var extralines:Array<String> = ['\n'];
        for (i=>check in ['Character.hx', 'Song.hx', 'StageData.hx', 'WeekData.hx', 
            'HealthIcon.hx', 'CreditsState.hx', 'PatchState.hx', 'DialogueBox.hx', 'DialogueBoxDenpa.hx',
            'FreeplayState.hx', 'Hscript.hx', 'Modcharts.hx', 'SoundtestState.hx', 'FunkinLua.hx',
            'hscript/Parser.hx', 'HscriptSubstate.hx', 'HscriptState.hx', 'HscriptClass.hx',
            'hscript/Interp.hx', 'Note.hx'])
        {
            if (log.contains(check)) {
                switch (i) {
                    case 0:
                        if (!(extralines.contains('\nYour Character .json may be invalid!')))
                            extralines.push('\nYour Character .json may be invalid!');
                    case 1:
                        if (!(extralines.contains('\nYour Song .json may be invalid!')))
                            extralines.push('\nYour Song .json may be invalid!');
                    case 2:
                        if (!(extralines.contains('\nYour Stage .json may be invalid!')))
                            extralines.push('\nYour Stage .json may be invalid!');
                    case 3 | 9:
                        if (!(extralines.contains('\nYour Week .json may be invalid!')))
                            extralines.push('\nYour Week .json may be invalid!');
                    case 4:
                        if (!(extralines.contains('\nYour Icon size may be invalid!\nYour Icon name may be invalid!')))
                            extralines.push('\nYour Icon size may be invalid!\nYour Icon name may be invalid!');
                    case 5:
                        if (!(extralines.contains('\nYour Credits .txt may be invalid!')))
                            extralines.push('\nYour Credits .txt may be invalid!');
                    case 6:
                        if (!(extralines.contains('\nYour Patch .txt may be invalid!')))
                            extralines.push('\nYour Patch .txt may be invalid!');
                    case 7:
                        if (!(extralines.contains('\nYour Dialogue .txt may be invalid!')))
                            extralines.push('\nYour Dialogue .txt may be invalid!');
                    case 8:
                        if (!(extralines.contains('\nYour Dialogue .json may be invalid!')))
                            extralines.push('\nYour Dialogue .json may be invalid!');
                    case 10 | 14 | 18:
                        if (!(extralines.contains('\nYour .hscript may be invalid!')))
                            extralines.push('\nYour .hscript may be invalid!');
                    case 11:
                        if (!(extralines.contains('\nYour Modchart .hscript may be invalid!')))
                            extralines.push('\nYour Modchart .hscript may be invalid!');
                    case 15:
                        if (!(extralines.contains('\nYour SubState .hscript may be invalid!')))
                            extralines.push('\nYour SubState .hscript may be invalid!');
                    case 16:
                        if (!(extralines.contains('\nYour State .hscript may be invalid!')))
                            extralines.push('\nYour State .hscript may be invalid!');
                    case 17:
                        if (!(extralines.contains('\nYour Class .hscript may be invalid!')))
                            extralines.push('\nYour Class .hscript may be invalid!');
                    case 12:
                        if (!(extralines.contains('\nYour Album .json may be invalid!')))
                            extralines.push('\nYour Album .json may be invalid!');
                    case 13:
                        if (!(extralines.contains('\nYour .lua may be invalid!')))
                            extralines.push('\nYour .lua may be invalid!');
                    case 19:
                        if (!(extralines.contains('\nYour note skin may be invalid!')))
                            extralines.push('\nYour note skin may be invalid!');
                }
            }
        }
        if (log != null) for (line in extralines) log += line;

        var text:FlxText = new FlxText(5, 5, 450 * 1.75, (log != null ? log : "NO CRASH DETECTED"), 24).setFormat(null, 20, 0xffff0000, LEFT, OUTLINE, flixel.util.FlxColor.BLACK);
        text.alpha = 0;
        add(text);

        var black2:FlxSprite = new FlxSprite().makeGraphic(1280,720,0xff000000);
        add(black2);

        new FlxTimer().start(0.05, _ -> black2.y += black2.height/25, 25);
        new FlxTimer().start(1.5, _ -> new FlxTimer().start(0.15, _ -> logo.alpha = text.alpha += 0.1, 10));
        new FlxTimer().start(10, _ -> Sys.exit(1));
    }

    inline function returnGraphic(key:String) {
        final path = getPath('images', '$key.png');

		if (OpenFlAssets.exists(path, IMAGE)) return FlxG.bitmap.add(path, false, path);
        Application.current.window.alert('raw: \n$path\n\nfullpath: \n' + sys.FileSystem.absolutePath(path), 'Key doesnt exist!');
		return null;
	}

    //Makes sure to set assets path to proper export one if it tracks the base game assets folder instead of crashhanlder's export one
    function getPath(folder:String, key:String):String {
        final path = 'assets/$folder/$key';
        return sys.FileSystem.absolutePath(path).contains('crshhndlr/export') ? path : 'assets/$folder/crash/$key';

        return 'error'; //should never happen but it wants a final string return
    }

    //CoolUtil.browserLoad yes i know shh
    inline function openURL(url:String)
		#if linux Sys.command('/usr/bin/xdg-open', [url]); #else FlxG.openURL(url); #end
}