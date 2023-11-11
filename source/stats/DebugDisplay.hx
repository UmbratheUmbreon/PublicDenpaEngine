package stats;

import lime.system.System as LimeSys;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.Capabilities;
import openfl.display3D.Context3D;
import sys.io.Process;

class DebugDisplay extends TextField
{
	private var storedPeak:Float = 0;
	private var memPeakDisplayStr:String = ' B';
	private var cachedMem:Float = 0;

	public var showConductor:Bool = false;
	public var showFlixel:Bool = false;
	public var showSystem:Bool = false;
	public var forceUpdate:Bool = false;

	//sys
	private var platform:String = '???';
	private var cpu:String = '???';
	private var gpu:String = '???';
	private var engVer:String = '???';

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();

		x = inX;
		y = inY;

		selectable = false;

		defaultTextFormat = new TextFormat("VCR OSD Mono", 12, inCol);

		text = 'MEM: 0 B\nMEM-PEAK: 0 B';

		width = 440;
		height = 290;

		resetMeta();
	}

	private function resetMeta()
	{
		platform = '${LimeSys.platformLabel} ${LimeSys.platformVersion}';
		#if windows
		var process = new Process('wmic', ['cpu', 'get', 'name']);
		if (process.exitCode() == 0) {
			cpu = process.stdout.readAll().toString().trim().split('\n')[1].trim();
			cpu += ' ${Capabilities.cpuArchitecture} ${Capabilities.supports64BitProcesses ? '64 Bit' : '32 Bit'}';
		}
		#end
		@:privateAccess gpu = Std.string(FlxG.stage.context3D.gl.getParameter(FlxG.stage.context3D.gl.RENDERER)).split("/")[0];
		engVer = Main.denpaEngineVersion.debugVersion;
	}

	var lastFT:Float = 0.0;
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!visible) return; //why would we calculate this if its not visible.

		if (!forceUpdate) {
			lastFT += deltaTime;
			lastFT -= (lastFT > 100 ? 100 : return); //Il s'agit d'une mémoire tampon pour éviter tout décalage!
		}

		//get the current used shit
		final arr:Array<Any> = CoolUtil.getMemUsage();
        var mem:Float = cast arr[0];
		#if debug
		final uObj = @:privateAccess flixel.FlxBasic.activeCount;
		final dObj = @:privateAccess flixel.FlxBasic.visibleCount;
		#end
		if (!forceUpdate && (!showConductor && mem == cachedMem))
			return;
		else
			cachedMem = mem;

		
		var memDisplayStr:String = cast arr[1];
		if (mem > storedPeak) storedPeak = mem; //set max
		var newArr = CoolUtil.truncateByteFormat(mem); //truncate
		mem = newArr[0]; //truncated
		memDisplayStr = newArr[1]; //format

		var memPeak = storedPeak;
		newArr = CoolUtil.truncateByteFormat(memPeak);
		memPeak = newArr[0];
		memPeakDisplayStr = newArr[1];

		text = 'MEM: ${Math.fround(mem * 100)/100} $memDisplayStr' + 
			'\nMEM-PEAK: ${Math.fround(memPeak * 100)/100} $memPeakDisplayStr';

		if (showSystem) {
			text += '\nVER: $engVer' +
			'\nSYS: $platform' +
			'\nCPU: $cpu';
			if (gpu != cpu)
				text += '\nGPU: $gpu';
		}

		if (showConductor) {
			text += '\nBPM: ${Conductor.bpm}' + 
				'\nTIME: ${Math.round(Conductor.songPosition)}';
			if (MusicBeatSubstate.curInstance != null)
				text += '\nSTEP: ${MusicBeatSubstate.curInstance.curStep}' +
					'\nBEAT: ${MusicBeatSubstate.curInstance.curBeat}';
			else if (MusicBeatState.curInstance != null)
				text += '\nSTEP: ${MusicBeatState.curInstance.curStep}' +
					'\nBEAT: ${MusicBeatState.curInstance.curBeat}';
		}

		if (showFlixel) {
			text += '\nCUR: ${Type.getClassName(Type.getClass(FlxG.state))}' +
				'${(flixel.FlxSubState.curInstance != null ? '\nSUB: ${Type.getClassName(Type.getClass(flixel.FlxSubState.curInstance))}' : '')}' +
				'\nMEMBS: ${FlxG.state.members.length}' +
				#if debug '\nACT-OBJ: $uObj | VIS-OBJ: $dObj' + #end
				'\nSNDS: ${FlxG.sound.list.length}' + 
				'\nBMPS: ${FlxG.bitmap.getTotalBitmaps()}';
		}

		forceUpdate = false;
	}
}