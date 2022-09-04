package;

import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;

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

		trace('cleared mem');
		
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		trace('set keys and framerate');

		PlayerSettings.init();

		trace('initialized playersettings');

		FlxG.save.bind('funkin', 'ninjamuffin99');

		trace('binded save');
		
		ClientPrefs.loadPrefs();
		
		trace('loaded prefs');

		Highscore.load();

		trace('loaded highscore');

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

		//FlxG.fullscreen = ClientPrefs.fullscreen;

		trace('LOADED FULLSCREEN SETTING!! (LIAR!!!)');

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
			trace('set weekdata');

		}

		FlxG.mouse.visible = false;

		trace('hid mouse');

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
			MusicBeatState.switchState(new DenpaState());
		}
	}

	private function localInit(?transfer:Bool = null) {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		trace('cleared mem');
		
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		trace('set keys and framerate');

		PlayerSettings.init();

		trace('initialized playersettings');

		FlxG.save.bind('funkin', 'ninjamuffin99');

		trace('binded save');
		
		ClientPrefs.loadPrefs();
		
		trace('loaded prefs');

		Highscore.load();

		trace('loaded highscore');

		FlxG.fullscreen = ClientPrefs.fullscreen;

		trace('LOADED FULLSCREEN SETTING!! (LIAR!!!)');

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
			trace('set weekdata');

		}

		FlxG.mouse.visible = false;

		trace('hid mouse');

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
			MusicBeatState.switchState(new DenpaState());
		}
	}
}
