package;

import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import lime.utils.Assets;
#if HSCRIPT_ALLOWED
import haxescript.HClassComps;
import haxescript.Hscript;
import haxescript.HscriptClass;
import sys.FileTools;

@:structInit class StaticVarContents {
	public var name:String;
	public var path:String; //full class-path
	public var isPublic:Bool;
	public var content:Dynamic;

	public function toString():String {
		return 'StaticVarContents(name: $name, path: $path, public: $isPublic, content: $content)';
	}
}
#end

/**
* State used on boot to initialize the game.
*/
class InitState extends FlxState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	#if HSCRIPT_ALLOWED
	public static var scriptClassPool:Map<String, HscriptClass> = [];
	public static var scriptStaticVars:Map<String, StaticVarContents> = [];
	#end

	override public function create():Void
	{
		//DO NOT THREAD THIS.
		localInit();
		swapState();
	}

	function localInit() {
		Paths.clearStoredCache(true);

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		ClientPrefs.loadDefaultKeys();

		PlayerSettings.init();

		FlxG.save.bind('funkin');
		
		ClientPrefs.loadPrefs();

		Highscore.load();

		if (FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;

		//Prevent crash on charter -AT
		CoolUtil.difficulties = CoolUtil.defaultDifficulties;
		PlayState.storyDifficulty = 0; //aka "Normal"
		
		FlxG.fixedTimestep = false;

		//why does the fps shit fail to work
		Main.toggleFPS(ClientPrefs.settings.get("showFPS"));

		Paths.refreshModsMaps(true, true, true);

		#if HSCRIPT_ALLOWED
		final foldersToCheck:Array<String> = ["classes", "states", "substates"];
		final folderType:Array<HscriptType> = [H_CLASS, H_STATE, H_SUBSTATE];
		function parseClasses(foldersToCheck:Array<String>, folderType:Array<HscriptType>) {
			for(i => folder in foldersToCheck) {
				final presentFilesRaw = sys.FileTools.readDirectoryFull('assets/scripts/$folder', true);
				for(file in presentFilesRaw) 
				{
					if(FileSystem.isDirectory('assets/scripts/$folder/$file') || !file.endsWith('.hscript')) continue; //Not a Valid file
					if(folderType[i] == H_CLASS) {
						var loader:HscriptClass = new HscriptClass(file);
						scriptClassPool.set(file, loader);
						continue;
					} 
					var varLoader:Hscript = new Hscript('assets/scripts/$folder/$file', true, folderType[i], true);
					@:privateAccess {
						for(var_ in varLoader.interpreter.trackedVars) {
							if(!var_.access.contains(AStatic)) continue; //We can ignore
							
						}
					}
				}
			}
		}
		parseClasses(["classes", "states", "substates"], [H_CLASS, H_STATE, H_SUBSTATE]);

		//For now we dont need to init twice to get our desired results
		/*hInit = true;
		parseClasses(["classes"], [H_CLASS]);*/ //Reparse classes with hInit on to do any stuff that needs to be done after all classes have been parsed once!!
		#end

		#if (HSCRIPT_ALLOWED && HSCRIPT_DEBUG)
		trace(InitState.scriptStaticVars);
		#end
	}
	public static var hInit:Bool = false;

	inline function swapState() {
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		MusicBeatState.switchState(new DenpaState());
	}
}
