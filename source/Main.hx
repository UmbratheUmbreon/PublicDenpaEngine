package;

import compiletime.GameVersion;
import flixel.FlxGame;
import flixel.FlxState;
import lime.app.Application;
import openfl.Assets;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.AssetCache;
import openfl.filters.ColorMatrixFilter;
import stats.DebugDisplay;
import stats.DebugPie;
import stats.FramerateDisplay;
#if (target.threaded && sys)
import sys.thread.ElasticThreadPool;
#end
#if CRASH_HANDLER
import haxe.CallStack;
import haxe.io.Path;
import openfl.events.UncaughtErrorEvent;
import sys.io.Process;
#end
#if desktop
import Discord.DiscordClient;
#end
#if cpp
import cpp.vm.Gc;
#end

class Main extends Sprite
{
	public static function main():Void
		Lib.current.addChild(new Main());

	public function new()
	{
		super();
		#if windows
		@:functionCode('
		#include <Windows.h>
		SetProcessDPIAware()
		')
		#end

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	/**
	 * Current engine version.
	 * 
	 * Use `version` to get the raw version.
	 * 
	 * Use `formatted` to get the formatted version.
	 * 
	 * Use `debugVersion` to get the version with build date.
	 */
	public static final denpaEngineVersion:GameVersion = new GameVersion(0, 8, 2, 'b');

	public static var fpsCounter:FramerateDisplay;
	public static var ramCount:DebugDisplay;
	public static var ramPie:DebugPie;

	inline public static function toggleFPS(fpsEnabled:Bool):Void
		if(fpsCounter != null) fpsCounter.visible = fpsEnabled;
 
	inline public static function toggleMEM(memEnabled:Bool):Void
		if(ramCount != null) ramCount.visible = memEnabled;

	inline public static function togglePIE(pieEnabled:Bool):Void
		if(ramPie != null) ramPie.visible = pieEnabled;

	#if (target.threaded && sys)
	public static var threadPool:ElasticThreadPool;
	#end
	
	private function setupGame():Void
	{
		#if cpp 
		Gc.enable(true);
		#end

		final gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
		final gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
		final initialState:Class<FlxState> = InitState; // The FlxState the game starts with.
		final framerate:Int = 60; // How many frames per second the game should run at.
		final skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
		final startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

		//do not "funkingame" me, it is slower
		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));

		fpsCounter = new FramerateDisplay(6, 3, 0xFFFFFF);
		FlxG.addChildBelowMouse(fpsCounter, 1);
		addChild(fpsCounter);

		//me on my way to perfectly position this fucking debug display so it doesnt piss me off:
		ramCount = new DebugDisplay(6, 13, 0xffffff);
		addChild(ramCount);
		toggleMEM(false);

		ramPie = new DebugPie(1080, 3, 0xffffff);
		addChild(ramPie);
		togglePIE(false);

		#if (target.threaded && sys)
		threadPool = new ElasticThreadPool(12, 30);
		#end

		inline function gc(?minor:Bool = false) {
			#if cpp
			Gc.run(!minor);
			if (!minor) Gc.compact();
			//trace('${Gc.memInfo(0) / 1024 / 1024} MB NEEDED\n${Gc.memInfo(1) / 1024 / 1024} MB RESERVED\n${Gc.memInfo(2) / 1024 / 1024} MB IN USE');
			#else
			openfl.system.System.gc();
			#end
		}

		ClientPrefs.controllerEnabled = (FlxG.gamepads.getActiveGamepads() != null);
		FlxG.gamepads.deviceConnected.add(gamepad -> ClientPrefs.controllerEnabled = true);
		FlxG.gamepads.deviceDisconnected.add(gamepad -> ClientPrefs.controllerEnabled = false);

		//negates need for constant clearStored etc
		FlxG.signals.preStateSwitch.add(() -> {
			Paths.clearStoredCache(true);
			FlxG.sound.destroy(false);

			var cache = cast(Assets.cache, AssetCache);
			for (key=>font in cache.font)
				cache.removeFont(key);
			for (key=>sound in cache.sound)
				cache.removeSound(key);
			cache = null;

			gc(true);
		});
		FlxG.signals.postStateSwitch.add(() -> {
			Paths.clearUnusedCache();
			gc();
		});

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		#if desktop
		if (!DiscordClient.isInitialized) {
			DiscordClient.initialize();
			Application.current.window.onClose.add(function() {
				DiscordClient.shutdown();
			});
		}
		#end
	}

	public static var colorblindMode:Int = -1;
	public static function updateColorblindFilter(type:Int = -1, intensity:Float = 1) {
		FlxG.game.setFilters([]);
		
		colorblindMode = type;
		if (type == -1) return; //early return to avoid unnecessary calcs

		var matrixShit:Array<Float> = [];
		switch (type) {
			//4x5 colour matrix
			//1st in each row is red mult
			//2nd in each row is green mult
			//3rd in each row is blue mult
			//4th in each row is alpha mult
			//5th in each row is offset
			//each row corresponds to rgba
			//the value for each row is (matrixR * pixelR) + (matrixG * pixelG) + (matrixB * pixelB) + (matrixA * pixelA) + matrixO
			case -1: //unchanged
				matrixShit = [
					1, 0, 0, 0, 0,
					0, 1, 0, 0, 0,
					0, 0, 1, 0, 0,
					0, 0, 0, 1, 0];
			case 0: //deutranopia
				matrixShit = [
					0.43, 0.72, -0.15, 0, 0,
					0.34, 0.57, 0.09, 0, 0,
					-0.02, 0.03, 1, 0, 0,
					0, 0, 0, 1, 0];
			case 1: //protanopia
				matrixShit = [
					0.2, 0.99, -0.19, 0, 0,
					0.16, 0.79, 0.04, 0, 0,
					0.01, -0.01, 1, 0, 0,
					0, 0, 0, 1, 0];
			case 2: //tritanopia
				matrixShit = [
					0.97, 0.11, -0.08, 0, 0,
					0.02, 0.82, 0.16, 0, 0,
					0.06, 0.88, 0.18, 0, 0,
					0, 0, 0, 1, 0];
			case 3: //gameboy mode
				matrixShit = [
					0, 0, 0, 0, 0,
					0.33, 0.34, 0.33, 0, 0,
					0, 0, 0, 0, 0,
					0, 0, 0, 1, 0];
			case 4: //virtual boy mode
				matrixShit = [
					0.34, 0.33, 0.33, 0, 0,
					0, 0, 0, 0, 0,
					0, 0, 0, 0, 0,
					0, 0, 0, 1, 0];
			case 5: //b/w mode
				matrixShit = [
					0.33, 0.34, 0.33, 0, 0,
					0.33, 0.34, 0.33, 0, 0,
					0.33, 0.34, 0.33, 0, 0,
					0, 0, 0, 1, 0];
			case 6: //inverted mode
				matrixShit = [
					0, 0.5, 0.5, 0, 0,
					0.5, 0, 0.5, 0, 0,
					0.5, 0.5, 0, 0, 0,
					0, 0, 0, 1, 0];
			case 7: //idfk mode
				matrixShit = [
					0.07, 0.9, 0.03, 0, 0,
					0.25, 0, 0.75, 0, 0,
					0, 0.33, 0.67, 0, 0,
					0, 0, 0, 1, 0];
			case 8: //random mode
				matrixShit = [
					FlxG.random.float(0, 1), FlxG.random.float(0, 1), FlxG.random.float(0, 1), 0, 0,
					FlxG.random.float(0, 1), FlxG.random.float(0, 1), FlxG.random.float(0, 1), 0, 0,
					FlxG.random.float(0, 1), FlxG.random.float(0, 1), FlxG.random.float(0, 1), 0, 0,
					0, 0, 0, 1, 0];
		}
		inline function checkRange(val:Int, low:Int, high:Int)
			return (val >= low && val <= high);

		for (i in 0...matrixShit.length) {
			if (i % 5 == 4) continue; //dont fuck with the colour offsets
			if (i > 14) break; //dont fuck with the alpha
			if (matrixShit[i] == 0) matrixShit[i] = 0.00001;
			if ((i % 5 == 0 && checkRange(i, 0, 4)) || (i % 5 == 1 && checkRange(i, 5, 9)) || (i % 5 == 2 && checkRange(i, 10, 14))) { //is color, we are on color.
				matrixShit[i] = FlxMath.lerp(matrixShit[i], 1, CoolUtil.clamp(1 - intensity, 0, 1));
				continue;
			}
			matrixShit[i] = FlxMath.lerp(matrixShit[i], 0, CoolUtil.clamp(1 - intensity, 0, 1));
		}

		var filter = new ColorMatrixFilter(matrixShit);
		if (filter == null) return;

		FlxG.game.setFilters([filter]);
	}

	public static function setDisplayColors(color:Int) {
		ramPie.textColor = ramCount.textColor = fpsCounter.textColor = color;
	}

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		final callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_").replace(":", "'");

		final path = "./crshhndlr/logs/" + "DenpaEngine_" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		final errorLinesSorted:Array<String> = [
			'\nUncaught Error: ${e.error}!',
			'\nPlease report this error to the GitHub page\n(Will automatically open when exiting!)',
			'\nAlternatively, report it in the official server\n(Will also be opened automatically!)',
			'\n\nOriginal CrashHandler code written by squirra-rng (https://github.com/gedehari)'
		];
		for(line in errorLinesSorted) { errMsg += line; }

		if (!FileSystem.exists("./crshhndlr/logs/")) FileSystem.createDirectory("./crshhndlr/logs/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		DiscordClient.shutdown();
		new Process("./crshhndlr/DENPACRASHHANDLER.exe", [errMsg]);
		Sys.exit(1);
	}
	#end
}