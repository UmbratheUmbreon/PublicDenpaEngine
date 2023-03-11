package stats;

import lime.system.System as LimeSys;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;

class DebugDisplay extends TextField
{
	private var storedPeak:Float = 0;
	private var memPeakDisplayStr:String = ' MB';
	private var cachedMem:Float = 0;
	private var cachedObjCounts:Array<Int> = [0, 0];
	private var cachedBPM:Float = 0;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();

		x = inX;
		y = inY;

		selectable = false;

		defaultTextFormat = new TextFormat("VCR OSD Mono", 12, inCol);

		text = "";

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 340;
		height = 90;
	}

	private function onEnter(_)
	{
		if (!visible) return; //why would we calculate this if its not visible.
		//get the current used shit
		final arr:Array<Any> = CoolUtil.getMemUsage();
        var mem:Float = cast arr[0];
		final uObj = #if debug @:privateAccess flixel.FlxBasic.activeCount #else 0 #end;
		final dObj = #if debug @:privateAccess flixel.FlxBasic.visibleCount #else 0 #end;
		if (mem == cachedMem && uObj == cachedObjCounts[0] && dObj == cachedObjCounts[1] && Conductor.bpm == cachedBPM)
			return;
		else {
			cachedMem = mem;
			cachedObjCounts = [uObj, dObj];
			cachedBPM = Conductor.bpm;
		}

		
		var memDisplayStr:String = cast arr[1];
		if (mem > storedPeak) storedPeak = mem; //set max
		var newArr = CoolUtil.truncateByteFormat(mem); //truncate
		mem = newArr[0]; //truncated
		memDisplayStr = newArr[1]; //format

		var memPeak = storedPeak;
		newArr = CoolUtil.truncateByteFormat(memPeak);
		memPeak = newArr[0];
		memPeakDisplayStr = newArr[1];
		
		//textColor = (((mem > 3 && memDisplayStr == ' GB') || (formats.indexOf(memDisplayStr) > 2)) ? 0xff0000 : 0xffffff);
		//i HATE how laggy the debugger is so im just gonna have the stats here
        //^ i said this before i made this an entire debug display
		text = 'MEM: ${FlxMath.roundDecimal(mem, 2)} $memDisplayStr | ${FlxMath.roundDecimal(memPeak, 2)} $memPeakDisplayStr' +
			#if debug '\nUPD-OBJ: $uObj | DRW-OBJ: $dObj' + #end
			'\nCUR: ${Type.getClassName(Type.getClass(FlxG.state))}' +
			'${(flixel.FlxSubState.curInstance != null ? '\nSUB: ${Type.getClassName(Type.getClass(flixel.FlxSubState.curInstance))}' : '')}' +
			'\nBPM: ${Conductor.bpm}' +
			'\nVER: ${Main.denpaEngineVersion.debugVersion}' +
			'\nSYS: ${LimeSys.platformLabel} ${LimeSys.platformVersion}';
	}
}