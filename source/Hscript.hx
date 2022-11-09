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
import openfl.utils.Assets;
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

    public function get(Function:String):Dynamic
    {
        // if (interpreter == null || parser == null) return null;
        // if (!interpreter.variables.exists(Function)) return null;

        return interpreter.variables.get(Function);
    }

    public function set(Function:String, value:Dynamic):Void
    {
        // if (interpreter == null || parser == null) return;
        // if (!interpreter.variables.exists(Function)) return;

        return interpreter.variables.set(Function, value);
    }

    public function exists(Function:String){
        // if (interpreter == null || parser == null) return null;
        // if (!interpreter.variables.exists(Function)) return null;

        return interpreter.variables.exists(Function);
    }

    public function stop(){
        interpreter = null;
        parser = null;
    }

    public function parseString(daString:String, ?name:String = 'hscript')
    {
        // if (parser == null) return null;

        return parser.parseString(daString, name);
    }

    public function parseFile(daFile:String, ?name:String = 'hscript'){
        if (name == null)
			name = daFile;
        // if (parser == null) return null;

        return parser.parseString(Assets.getText(daFile), name);
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
        interpreter.variables.set("FlxColor", FlxColorCustom);
        interpreter.variables.set("Type", Type);
        interpreter.variables.set("Std", Std);
        interpreter.variables.set("Reflect", Reflect);
        interpreter.variables.set("StringTools", StringTools);
    }
}

//cant use an abstract as a value so made one with just the static functions

/**
 * @author Starmapo
 */
class FlxColorCustom
{
	public static inline var TRANSPARENT = 0x00000000;
	public static inline var WHITE = 0xFFFFFFFF;
	public static inline var GRAY = 0xFF808080;
	public static inline var BLACK = 0xFF000000;

	public static inline var GREEN = 0xFF008000;
	public static inline var LIME = 0xFF00FF00;
	public static inline var YELLOW = 0xFFFFFF00;
	public static inline var ORANGE = 0xFFFFA500;
	public static inline var RED = 0xFFFF0000;
	public static inline var PURPLE = 0xFF800080;
	public static inline var BLUE = 0xFF0000FF;
	public static inline var BROWN = 0xFF8B4513;
	public static inline var PINK = 0xFFFFC0CB;
	public static inline var MAGENTA = 0xFFFF00FF;
	public static inline var CYAN = 0xFF00FFFF;

	/**
	 * A `Map<String, Int>` whose values are the static colors of `FlxColor`.
	 * You can add more colors for `FlxColor.fromString(String)` if you need.
	 */
	public static var colorLookup(default, null):Map<String, Int> = FlxMacroUtil.buildMap("flixel.util.FlxColor");

	static var COLOR_REGEX = ~/^(0x|#)(([A-F0-9]{2}){3,4})$/i;

	/**
	 * Create a color from the least significant four bytes of an Int
	 *
	 * @param	Value And Int with bytes in the format 0xAARRGGBB
	 * @return	The color as a FlxColor
	 */
	public static inline function fromInt(Value:Int):FlxColor
	{
		return new FlxColor(Value);
	}

	/**
	 * Generate a color from integer RGB values (0 to 255)
	 *
	 * @param Red	The red value of the color from 0 to 255
	 * @param Green	The green value of the color from 0 to 255
	 * @param Blue	The green value of the color from 0 to 255
	 * @param Alpha	How opaque the color should be, from 0 to 255
	 * @return The color as a FlxColor
	 */
	public static inline function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):FlxColor
	{
		var color = new FlxColor();
		return color.setRGB(Red, Green, Blue, Alpha);
	}

	/**
	 * Generate a color from float RGB values (0 to 1)
	 *
	 * @param Red	The red value of the color from 0 to 1
	 * @param Green	The green value of the color from 0 to 1
	 * @param Blue	The green value of the color from 0 to 1
	 * @param Alpha	How opaque the color should be, from 0 to 1
	 * @return The color as a FlxColor
	 */
	public static inline function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setRGBFloat(Red, Green, Blue, Alpha);
	}

	/**
	 * Generate a color from CMYK values (0 to 1)
	 *
	 * @param Cyan		The cyan value of the color from 0 to 1
	 * @param Magenta	The magenta value of the color from 0 to 1
	 * @param Yellow	The yellow value of the color from 0 to 1
	 * @param Black		The black value of the color from 0 to 1
	 * @param Alpha		How opaque the color should be, from 0 to 1
	 * @return The color as a FlxColor
	 */
	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

	/**
	 * Generate a color from HSB (aka HSV) components.
	 *
	 * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	Brightness	(aka Value) A number between 0 and 1, indicating how bright the color should be.  0 is black, 1 is full bright.
	 * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	The color as a FlxColor
	 */
	public static function fromHSB(Hue:Float, Saturation:Float, Brightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSB(Hue, Saturation, Brightness, Alpha);
	}

	/**
	 * Generate a color from HSL components.
	 *
	 * @param	Hue			A number between 0 and 360, indicating position on a color strip or wheel.
	 * @param	Saturation	A number between 0 and 1, indicating how colorful or gray the color should be.  0 is gray, 1 is vibrant.
	 * @param	Lightness	A number between 0 and 1, indicating the lightness of the color
	 * @param	Alpha		How opaque the color should be, either between 0 and 1 or 0 and 255.
	 * @return	The color as a FlxColor
	 */
	public static inline function fromHSL(Hue:Float, Saturation:Float, Lightness:Float, Alpha:Float = 1):FlxColor
	{
		var color = new FlxColor();
		return color.setHSL(Hue, Saturation, Lightness, Alpha);
	}

	/**
	 * Parses a `String` and returns a `FlxColor` or `null` if the `String` couldn't be parsed.
	 *
	 * Examples (input -> output in hex):
	 *
	 * - `0x00FF00`    -> `0xFF00FF00`
	 * - `0xAA4578C2`  -> `0xAA4578C2`
	 * - `#0000FF`     -> `0xFF0000FF`
	 * - `#3F000011`   -> `0x3F000011`
	 * - `GRAY`        -> `0xFF808080`
	 * - `blue`        -> `0xFF0000FF`
	 *
	 * @param	str 	The string to be parsed
	 * @return	A `FlxColor` or `null` if the `String` couldn't be parsed
	 */
	public static function fromString(str:String):Null<FlxColor>
	{
		var result:Null<FlxColor> = null;
		str = StringTools.trim(str);

		if (COLOR_REGEX.match(str))
		{
			var hexColor:String = "0x" + COLOR_REGEX.matched(2);
			result = new FlxColor(Std.parseInt(hexColor));
			if (hexColor.length == 8)
			{
				result.alphaFloat = 1;
			}
		}
		else
		{
			str = str.toUpperCase();
			for (key in colorLookup.keys())
			{
				if (key.toUpperCase() == str)
				{
					result = new FlxColor(colorLookup.get(key));
					break;
				}
			}
		}

		return result;
	}

	/**
	 * Get HSB color wheel values in an array which will be 360 elements in size
	 *
	 * @param	Alpha Alpha value for each color of the color wheel, between 0 (transparent) and 255 (opaque)
	 * @return	HSB color wheel as Array of FlxColors
	 */
	public static function getHSBColorWheel(Alpha:Int = 255):Array<FlxColor>
	{
		return [for (c in 0...360) fromHSB(c, 1.0, 1.0, Alpha)];
	}

	/**
	 * Get an interpolated color based on two different colors.
	 *
	 * @param 	Color1 The first color
	 * @param 	Color2 The second color
	 * @param 	Factor Value from 0 to 1 representing how much to shift Color1 toward Color2
	 * @return	The interpolated color
	 */
	public static inline function interpolate(Color1:FlxColor, Color2:FlxColor, Factor:Float = 0.5):FlxColor
	{
		var r:Int = Std.int((Color2.red - Color1.red) * Factor + Color1.red);
		var g:Int = Std.int((Color2.green - Color1.green) * Factor + Color1.green);
		var b:Int = Std.int((Color2.blue - Color1.blue) * Factor + Color1.blue);
		var a:Int = Std.int((Color2.alpha - Color1.alpha) * Factor + Color1.alpha);

		return fromRGB(r, g, b, a);
	}

	/**
	 * Create a gradient from one color to another
	 *
	 * @param Color1 The color to shift from
	 * @param Color2 The color to shift to
	 * @param Steps How many colors the gradient should have
	 * @param Ease An optional easing function, such as those provided in FlxEase
	 * @return An array of colors of length Steps, shifting from Color1 to Color2
	 */
	public static function gradient(Color1:FlxColor, Color2:FlxColor, Steps:Int, ?Ease:Float->Float):Array<FlxColor>
	{
		var output = new Array<FlxColor>();

		if (Ease == null)
		{
			Ease = function(t:Float):Float
			{
				return t;
			}
		}

		for (step in 0...Steps)
		{
			output[step] = interpolate(Color1, Color2, Ease(step / (Steps - 1)));
		}

		return output;
	}

	/**
	 * Multiply the RGB channels of two FlxColors
	 */
	@:op(A * B)
	public static inline function multiply(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.fromRGBFloat(lhs.redFloat * rhs.redFloat, lhs.greenFloat * rhs.greenFloat, lhs.blueFloat * rhs.blueFloat);
	}

	/**
	 * Add the RGB channels of two FlxColors
	 */
	@:op(A + B)
	public static inline function add(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.fromRGB(lhs.red + rhs.red, lhs.green + rhs.green, lhs.blue + rhs.blue);
	}

	/**
	 * Subtract the RGB channels of one FlxColor from another
	 */
	@:op(A - B)
	public static inline function subtract(lhs:FlxColor, rhs:FlxColor):FlxColor
	{
		return FlxColor.fromRGB(lhs.red - rhs.red, lhs.green - rhs.green, lhs.blue - rhs.blue);
	}
}