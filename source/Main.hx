package;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import stats.CustomFPS;
import stats.CustomFPS.CustomMEM;
//crash handler stuff
#if desktop
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import Discord.DiscordClient;
#end

using StringTools;

class Main extends Sprite
{
	//1280, 720
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = InitState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPS;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
	
		ClientPrefs.loadDefaultKeys();
		
		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));
		#if FLIXEL_STUDIO
		flixel.addons.studio.FlxStudio.create();
		#end

		fpsCounter = new CustomFPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);
		toggleFPS(ClientPrefs.showFPS);

		#if debug
		ramCount = new CustomMEM(10, 16, 0xffffff);
		addChild(ramCount);
		toggleMEM(ClientPrefs.showFPS);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end
		#if desktop
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
	}

	public static var fpsCounter:CustomFPS;
	public static var ramCount:CustomMEM;

	public static function toggleFPS(fpsEnabled:Bool):Void
		fpsCounter.visible = fpsEnabled;

	public static function toggleMEM(fpsEnabled:Bool):Void
		ramCount.visible = fpsEnabled;

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if desktop
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "DenpaEngine_" + dateNow + ".txt";

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

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/UmbratheUmbreon/PublicDenpaEngine\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		var randoms:Array<String> = ['Error!', 'Uh Oh!', 'Wipe Out!', 'Dangit!', 'Shit!', 'I Messed Up!', 'Oops!', 'Ouch!', 'Sorry!', 'God damnit!', 'Try Again!', 'Crash!', 'Ow!', 'That Stinks!', 'Help!', 'Oh Come On!', 'Really?!', 'Ugh!', 'That Was Stupid!'];
		Application.current.window.alert(errMsg, randoms[FlxG.random.int(0,randoms.length-1)]);
		DiscordClient.shutdown();
		Sys.exit(1);
	}
	#end
}
