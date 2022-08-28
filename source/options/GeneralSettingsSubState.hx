package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import openfl.Lib;

using StringTools;

class GeneralSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'General';
		rpcTitle = 'General Settings Menu'; //for Discord Rich Presence

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(option);

		option.minValue = 24;
		option.maxValue = 999;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeFPSCounter;

		var option:Option = new Option('Fullscreen',
			'Makes the window fullscreen.',
			'fullscreen',
			'bool',
			false);
		addOption(option);
		option.onChange = onChangeFullscreen;

		#if !html
		var option:Option = new Option('Auto Pause',
			'Turns on/off auto pausing on focus lost.',
			'autoPause',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeAutoPause;
		#end

		/*var option:Option = new Option('Preloading',
			'Preloads the game upon startup.',
			'preloading',
			'bool',
			false);
		addOption(option);*/

		var option:Option = new Option('Mouse Controls',
			'Turns on or off UI Mouse Controls',
			'mouseControls',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Check For Updates',
			'Checks for updates on startup if enabled.',
			'checkForUpdates',
			'bool',
			true);
		addOption(option);
		#end

		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			'Tea Time',
			['None', 'Breakfast', 'Tea Time']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)));

		changedMusic = true;
	}

	function onChangeFramerate()
	{
		if(ClientPrefs.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.framerate;
			FlxG.drawFramerate = ClientPrefs.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.framerate;
			FlxG.updateFramerate = ClientPrefs.framerate;
		}
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.showFPS;
	}

	function onChangeFullscreen()
		{
			FlxG.fullscreen = ClientPrefs.fullscreen;
		}

	function onChangeAutoPause()
		{
			FlxG.autoPause = ClientPrefs.autoPause;
		}
	#end

	override function destroy()
		{
			if(changedMusic) FlxG.sound.playMusic(Paths.music('freakyMenu'));
			super.destroy();
		}
}