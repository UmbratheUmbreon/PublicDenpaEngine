package;

import haxe.io.Path;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import openfl.utils.Assets;
#if cpp
import cpp.vm.Gc;
#end

/**
* Class containing useful functions to be reused across the different states.
*/
class CoolUtil
{
	public static final defaultDifficulties:Array<String> = ['Normal', 'Hard'];
	public static final defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode
	public static var difficulties:Array<String> = [];

	inline public static function quantize(f:Float, snap:Float):Float
		return Math.fround(f * snap) / snap;

	inline public static function curveNumber(input:Float = 1, ?curve:Float = 10):Float
		return Math.sqrt(input)*curve;
	
	/**
	 * Description: Returns the currently allocated memory in MB/GB depending on size.
	 * 
	 * Author: BlueVapor1234
	 * 
	 * @return `Array<Any>` containing the currently used bytes and the format.
	 */
	inline public static function getMemUsage():Array<Any> {
		//mem should be in Bytes.
		//abs is because mem can be negative sometimes for some reason
		return [Math.abs(#if cpp Gc.memInfo(0) #elseif sys cast(cast(System.totalMemory, UInt), Float) #else 0 #end), 'B'];
	}

	inline public static function convPathShit(path:String):String {
		path = Path.normalize(Sys.getCwd() + path);
		#if windows
		path = path.replace("/", "\\");
		#end
		return path;
	}

	/**
	 * Description: Returns the input amount of Bytes to the correct format.
	 * 
	 * Author: BlueVapor1234
	 * 
	 * @param bytes `Float` representing the amount of bytes to be truncated.
	 * @param format `String` representing the original formatting of the bytes.
	 * 
	 * @return `Array<Any>` containing the truncated bytes and the format.
	 */
	inline public static function truncateByteFormat(bytes:Float, format:String = 'B'):Array<Any>
	{
		final formats = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
		var i = formats.indexOf(format);
		i++; //offset
		while (bytes > 1024) {
			format = formats[i++];
            bytes /= 1024;
		}
		return [bytes, format];
	}

	/**
     * Converts the input `String` into the Title Case formatting. (Replace dashes with space, and captilize the first letter of every word).
     * @param input The `String` to be title cased.
     */
	inline public static function toTitleCase(input:String):String {
		var words:Array<String> = input.replace('-', ' ').trim().split(' ');
		return words.map(str -> '${str.charAt(0).toUpperCase()}${str.substr(1)}').join(' ');
	}

	/**
     * Removes duplicate instances from the input `Array<String>` and sorts alphabetically.
     * @param string The `Array<String>` to be used.
     */
	inline public static function removeDuplicates(string:Array<String>):Array<String> {
		var tempArray:Array<String> = new Array<String>();
		var lastSeen:String;
		string.sort(function(str1:String, str2:String) {
		    return (str1 == str2) ? 0 : (str1 > str2) ? 1 : -1; 
		});
		for (str in string) {
		    if (str != lastSeen) {
			    tempArray.push(str);
		    }
		    lastSeen = str;
		}
		return tempArray;
	}

	inline public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;
		return Paths.formatToSongPath((difficulties[num] != defaultDifficulty) ? '-' + difficulties[num] : '');
	}

	inline public static function difficultyString():String
		return difficulties[PlayState.storyDifficulty].toUpperCase();

	inline public static function clamp(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	inline public static function coolTextFile(path:String):Array<String>
	{
		#if sys
		if(FileSystem.exists(path)) return [for (i in File.getContent(path).trim().split('\n')) i.trim()];
		#else
        if(Assets.exists(path)) return [for (i in Assets.getText(path).trim().split('\n')) i.trim()];
		#end

		return [];
	}

	inline public static function listFromString(string:String):Array<String>
		return string.trim().split('\n').map(str -> str.trim());

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
    {
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			    var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			    if(colorOfThisPixel != 0){
				    if(countByColor.exists(colorOfThisPixel)){
				        countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				    } else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					    countByColor[colorOfThisPixel] = 1;
				    }
			    }
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
    	return [for (i in min...max) i];

	public static var resW:Float = 1;
	public static var resH:Float = 1;
	public static inline final baseW:Int = 1280;
	public static inline final baseH:Int = 720;
	//finds multiplier for positionings, zoom, etc
	inline public static function resetResolutionScaling(w:Int = 1280, h:Int = 720) {
		resW = w/baseW;
		resH = h/baseH;
	}

	public static function precacheSound(sound:String, ?library:String = null):Void
		precacheSoundFile(Paths.sound(sound, library));

	public static function precacheMusic(sound:String, ?library:String = null):Void
		precacheSoundFile(Paths.music(sound, library));

	inline private static function precacheSoundFile(file:Dynamic):Void
		if (Assets.exists(file, SOUND) || Assets.exists(file, MUSIC)) Assets.getSound(file, true);

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	/**
	 * Executes the function in a seperate thread (if one is available), keeping the game from stopping execution until the function finished loading.
	 * 
	 * Use with caution!
	 * @param func The function you want to execute
	 * @param funcTwo Function to be executed if no thread is available (Will be executed on the main thread)
	 * @param forceExecution If true, `func` will be executed even if no thread was available (however on the main thread).
	 * Will load `funcTwo` aswell if it is not set to `null`!
	 * @return True if a thread was available, False if no thread was available or on browser-targets
	 */
	public static function loadThreaded(func:Void -> Void, ?funcTwo:Void -> Void = null, forceExecution:Bool = false):Bool {
		#if (target.threaded && sys)
		Main.threadPool.run(() -> {
			func();
		});

		return true;
		#end
		if(forceExecution) func();
		if(funcTwo != null) funcTwo();

		return false;
	}

	// shit below is for Debug class, but I'm sure you can use it elsewhere
	/**
     * Gets any variable from Class defined by "daClass", can be used outside of Lua.
     * @param daClass The class to get the variable from
     * @param daField The variable inside that class as a string
     * @param returnString Whetever to force the output to be a string or not. If false will return value of its own class type.
     */
    public static function getObjectFromClass(daClass:Dynamic, daField:String, returnString:Bool = false):Dynamic {
        //for each property seperated by a "." (like object.innerBox.x) make different variables to "reflect"
        var variableSplit:Array<String> = daField.split('.');

        if(variableSplit.length > 1) {
            var mainVariable:Dynamic = Reflect.getProperty(daClass, variableSplit[0]);

            for (property in 1...variableSplit.length - 1) {
                mainVariable = Reflect.getProperty(mainVariable, variableSplit[property]);
            }
            if(returnString) return Std.string(Reflect.getProperty(mainVariable, variableSplit[variableSplit.length - 1]));
            return Reflect.getProperty(mainVariable, variableSplit[variableSplit.length - 1]);
        }
        if(returnString) return Std.string(Reflect.getProperty(daClass, daField)); //If there is only one property return the variable value
        return Reflect.getProperty(daClass, daField);
    }

    /**
     * Gets variable the same way "reflectObjectFromClass" does, then changes the variable property to "value" (can be any type)
     * @param daClass The class to get the variable from
     * @param daField The variable inside that class as a string
     * @param value The new value for that variable
     */
    public static function setObjectFromClass(daClass:Dynamic, daField:String, value:Dynamic) {
        var variableSplit:Array<String> = daField.split('.');

        if(variableSplit.length > 1) {
            var mainVariable:Dynamic = Reflect.getProperty(daClass, variableSplit[0]);

            for (property in 1...variableSplit.length -1 ) {
                mainVariable = Reflect.getProperty(mainVariable, variableSplit[property]);
            }
            return Reflect.setProperty(mainVariable, variableSplit[variableSplit.length - 1], value);
        }
        return Reflect.setProperty(daClass, daField, value);
    }

	/**
     * Returns an `FlxEase` type based on the input `String`.
     * @param ease The easing `String` to use.
     */
	 public static function easeFromString(?ease:String = '') {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	/**
     * Returns a `BlendMode` based on the input `String`.
     * @param blend The blend `String` to use.
     */
	 public static function blendFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	/**
     * Returns an `FlxColor` based on the input `String`.
     * @param color The color `String` to use.
     */
	 public static function colorFromString(color:String):FlxColor {
		switch(color.toLowerCase().trim()) {
			case 'black': return FlxColor.BLACK;
			case 'blue': return FlxColor.BLUE;
			case 'brown': return FlxColor.BROWN;
			case 'cyan': return FlxColor.CYAN;
			case 'gray' | 'grey': return FlxColor.GRAY;
			case 'green': return FlxColor.GREEN;
			case 'lime': return FlxColor.LIME;
			case 'magenta': return FlxColor.MAGENTA;
			case 'orange': return FlxColor.ORANGE;
			case 'pink': return FlxColor.PINK;
			case 'purple': return FlxColor.PURPLE;
			case 'red': return FlxColor.RED;
			case 'transparent': return FlxColor.TRANSPARENT;
			case 'yellow': return FlxColor.YELLOW;
		}
		return FlxColor.WHITE;
	}
}
