package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.input.keyboard.FlxKey;
import flixel.addons.transition.FlxTransitionableState;
import lime.app.Application;

using StringTools;

/**
* State used on boot to initialize the game.
*/
class InitState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	public static var updateVersion:String = '';

	override public function create():Void
	{
		localInit();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public static function init(?transfer:Bool = null) {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		FlxG.save.bind('funkin', 'ninjamuffin99');

		#if !html5
		if (FlxG.save.data.fullscreen != null) {
			FlxG.fullscreen = FlxG.save.data.fullscreen;
		} else {
			FlxG.fullscreen = false;
		}

		if (FlxG.save.data.autoPause != null) {
			FlxG.autoPause = FlxG.save.data.autoPause;
		} else {
			FlxG.autoPause = true;
		}
		#end
		
		ClientPrefs.loadPrefs();

		Highscore.load();

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;

		#if desktop
		Application.current.window.borderless = true;
		#end

		#if desktop
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add (function (exitCode) {
				DiscordClient.shutdown();
			});
			//trace('initialized discord client');
		}
		#end
		if(transfer == null) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new DenpaState());
		}
	}

	private function localInit(?transfer:Bool = null) {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		FlxG.save.bind('funkin', 'ninjamuffin99');
		
		ClientPrefs.loadPrefs();

		Highscore.load();

		#if !html5
		if (FlxG.save.data.fullscreen != null) {
			FlxG.fullscreen = FlxG.save.data.fullscreen;
		} else {
			FlxG.fullscreen = false;
		}

		if (FlxG.save.data.autoPause != null) {
			FlxG.autoPause = FlxG.save.data.autoPause;
		} else {
			FlxG.autoPause = true;
		}
		#end

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;

		#if desktop
		Application.current.window.borderless = true;
		#end

		#if desktop
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add (function (exitCode) {
				DiscordClient.shutdown();
			});
			//trace('initialized discord client');
		}
		#end
		if(transfer == null) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new DenpaState());
		}
	}
}
