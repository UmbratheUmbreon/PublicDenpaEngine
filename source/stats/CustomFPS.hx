package stats;

import haxe.Timer;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/

/**
    stolen from hope engine, with permission
    go check it out lol
**/
class CustomFPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

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

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);

		if (currentCount != cacheCount /*&& visible*/)
		{
			text = "FPS: " + currentFPS;

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end
		}

		cacheCount = currentCount;
	}
}

class CustomMEM extends TextField
{
	private var memPeak:Float = 0;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();

		x = inX;
		y = inY;

		selectable = false;

		defaultTextFormat = new TextFormat("VCR OSD Mono", 12, inCol);

		text = "";

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 150;
		height = 70;
	}

	private function onEnter(_)
	{
		var mem:Float = Math.abs(Math.round(System.totalMemory / 1024 / 1024 * 100) / 100);
		var memDisplayStr:String = ' MB';
		var memPeakDisplayStr:String = ' MB';
		//mempeak being annoying:
		/*if (mem > 1024 && memDisplayStr == ' MB'){
			mem = Math.abs(Math.round(System.totalMemory / 1024 / 1024 / 1024 * 100) / 100);
			memDisplayStr = ' GB';
		}
		if (mem > 1024 && memDisplayStr == ' GB'){
			mem = Math.abs(Math.round(System.totalMemory / 1024 / 1024 / 1024 / 1024 * 100) / 100);
			memDisplayStr = ' TB';
		}
		if (mem < 1 && memDisplayStr == ' MB'){
			mem = Math.abs(Math.round(System.totalMemory / 1024 * 100) / 100);
			memDisplayStr = ' KB';
		}
		if (mem < 1 && memDisplayStr == ' KB'){
			mem = Math.abs(Math.round(System.totalMemory * 100) / 100);
			memDisplayStr = ' B';
		}*/

		if (mem > memPeak) {
			memPeak = mem;
			memPeakDisplayStr = memDisplayStr;
		}

		if (visible) {
			text = "MEM: " + mem + memDisplayStr + "\nMEM peak: " + memPeak + memPeakDisplayStr;
		}
	}
}