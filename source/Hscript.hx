package;
//i forgot i was doing this LOL
//ill work on it.. later
import lime.system.System;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxObject;
import flixel.FlxSprite;
#if desktop
import cpp.Lib;
#end
import lime.app.Application;
import flixel.tweens.FlxEase;
import Discord.DiscordClient;
import openfl.Assets;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;

/**
* Class used to control `HScript`.
* Written by _jorge.
*/
class HScript 
{
    public var interpreter:Interp;
    public var variables:Map<String, Dynamic>;
    public var parser:Parser;

    //hope this works
    public function new(path:String)
    {
        var file:String = 'trace("No script found");';
        #if sys
        if (FileSystem.exists(path))
        #else
        if (OpenFlAssets.exists(path))
        #end
            file = Assets.getText(path);

        interpreter = new Interp();
        parser = new Parser();
        
        interpreter.execute(parser.parseString(file));

        setVars();
    }

    public function call(Function:String, Arguments:Array<Dynamic>)
    {
        if (interpreter == null || parser == null) return;
        if (!interpreter.variables.exists(Function)) return;

        var shit = interpreter.variables.get(Function);
        Reflect.callMethod(interpreter, shit, Arguments);
    }

    function setVars()
    {
        //HELP

        //classes
        interpreter.variables.set("CoolUtil", CoolUtil); //?
        interpreter.variables.set("PlayState", PlayState);
        interpreter.variables.set("Paths", Paths);
        interpreter.variables.set("Alphabet", Alphabet);
        interpreter.variables.set("Character", Character);
        interpreter.variables.set("Conductor", Conductor);
        interpreter.variables.set("Discord", DiscordClient);
        interpreter.variables.set("Note", Note);
        interpreter.variables.set("Song", Song);
        interpreter.variables.set("Math", Math);
        interpreter.variables.set("Application", Application);
        #if cpp interpreter.variables.set("Lib", Lib); #end
        #if sys 
        interpreter.variables.set("FileSystem", FileSystem);
        interpreter.variables.set("System", System); 
        #end
        interpreter.variables.set("Assets", Assets);

        //flx
        interpreter.variables.set("FlxG", FlxG);
        interpreter.variables.set("FlxSprite", FlxSprite);
        interpreter.variables.set("FlxObject", FlxObject);
        interpreter.variables.set("FlxTypedGroup", FlxTypedGroup);
        interpreter.variables.set("FlxMath", FlxMath);
        interpreter.variables.set("FlxText", FlxText);
        interpreter.variables.set("FlxSound", FlxSound);
        interpreter.variables.set("FlxTween", FlxTween);
        interpreter.variables.set("FlxEase", FlxEase);
        interpreter.variables.set("FlxTimer", FlxTimer);
        //interpreter.variables.set("FlxColor", FlxColor);
    }
}