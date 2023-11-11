package stats;

import openfl.text.TextField;
import openfl.text.TextFormat;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
import openfl.events.Event;
#end
import flixel.util.FlxColor;

/**
    stolen and modified from hope engine, with permission (aka the one by skqure)
    go check it out lol
**/
class FramerateDisplay extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Float;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;
	@:noCompletion private var previousFPS:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("VCR OSD Mono", 12, color);
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];
		previousFPS = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	final colors = [0xffFF0000, 0xffFFA500, 0xffFFFF00, 0xff00FF00, 0xff0000FF, 0xffFF00FF];
	var curColor:Int = 0;
	var colorInterp:Float = 0;

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		if (!visible) return;

		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = (currentCount + cacheCount) / 2;

		if (ClientPrefs.settings.get('rainbowFPS')) {
			colorInterp += deltaTime / 328; //division is to normalize so it doesnt give you a seizure on lower fps
			Main.setDisplayColors(FlxColor.interpolate(colors[curColor], (curColor+1 == colors.length ? colors[0] : colors[curColor+1]), Math.min(Math.max(colorInterp, 0), 1)));
			if (textColor == (curColor+1 == colors.length ? colors[0] : colors[curColor+1])) {
				curColor = (curColor+1 == colors.length ? 0 : curColor+1);
				colorInterp = 0;
			}
		}

		if (currentCount != cacheCount)
		{
			text = "FPS: " + Math.round(currentFPS);
			//textColor = (currentFPS < ClientPrefs.settings.get('framerate')/3 ? 0xff0000 : 0xffffff);

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end
		}

		cacheCount = currentCount;
	}
}