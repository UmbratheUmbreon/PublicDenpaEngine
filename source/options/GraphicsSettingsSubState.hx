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

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Watermarks',
			"If checked, Denpa Engine Watermarks will be enabled, as well as the Song Credits.",
			'watermarks',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Camera Movement',
			"If unchecked, the camera won't move when you/your opponent hits a note.",
			'camPans',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Cam Move Mode:',
			"How do you want the camera movement to behave?",
			'camPanMode',
			'string',
			'Always',
			['Always', 'Camera Focus', 'BF Only', 'Oppt Only', 'Player 4 Only']);
		addOption(option);

		var option:Option = new Option('Ghost Tapping Miss Animation',
			"If checked, the player will do miss animations when you press the arrows while Ghost Tapping is enabled. If unchecked, the player will do normal sing animations instead.",
			'gsmiss',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Opponent Always Dance',
			"If unchecked, the opponent only dances when the camera is on BF.",
			'opponentAlwaysDance',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Note Splashes',
			"If unchecked, hitting \"Sick!\" notes won't show particles.",
			'noteSplashes',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Opponent Note Animations',
			"If unchecked, the opponent's strums will not light up.",
			'opponentNoteAnimations',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Icon Flinching',
			"If checked, Missing will cause the player's icon to show the dying animation temporarily.",
			'flinchy',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Icon Animation:',
			"What animation should the healthbar icons do?",
			'iconSwing',
			'string',
			'Swing Mild',
			['Swing Mild', 'Angle Snap', 'Bop Mild', 'Vanilla', 'Squish', 'Stretch', 'Old', 'None']);
		addOption(option);

		var option:Option = new Option('OG Healthbar',
			"If checked, the healthbar's colours will be set to Red/Green globally.",
			'greenhp',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Health Bar Transparency',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent',
			1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Combo and Rating Skin:',
			"What skin do you want?",
			'uiSkin',
			'string',
			'fnf',
			['fnf', 'denpa', 'kade']);
		addOption(option);

		var option:Option = new Option('Combo Pop Up',
			'If checked, the unused Combo Sprite will appear after getting a combo of 10 or more.',
			'comboPopup',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Use Wrong Camera',
			'If checked, the rating popups will be in the game camera, not the HUD.',
			'wrongCamera',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('MS Timing Text',
			'If checked, text displaying your MS timing will appear when hitting a note.',
			'msPopup',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('MS Display Precision:',
			"How precise the MS Timing display is. Lower numbers = less precise. 0 is only Integers.",
			'msPrecision',
			'int',
			2);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 9;

		var option:Option = new Option('Score Display:',
			"What engine's score display do you want?",
			'scoreDisplay',
			'string',
			'Psych',
			['Psych', 'Kade', 'Sarvente', 'FPS+', 'FNF+', 'FNM', 'Vanilla', 'None']);
		addOption(option);

		var option:Option = new Option('Sarvente Accuracy Display',
			'If checked, shows the accuracy in Sarvente Score Display.',
			'sarvAccuracy',
			'bool',
			false);
		addOption(option);
		
		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Ratings Display',
			"If checked, a display showing how many Perfects, Sicks, Etc. will be enabled.",
			'ratingsDisplay',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			'string',
			'Time Left',
			['Time Left', 'Time Elapsed', 'Song Name', 'Time Left (No Bar)', 'Time Elapsed (No Bar)', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Autoswap Time Bar Colour',
			"If checked, the Time Bar's colour will change to fit the opponent.",
			'changeTBcolour',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Time Bar Red:',
			"The Amount of Red in the Time Bar's Colour.",
			'timeBarRed',
			'int',
			255);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 255;

		var option:Option = new Option('Time Bar Green:',
			"The Amount of Green in the Time Bar's Colour.",
			'timeBarGreen',
			'int',
			255);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 255;

		var option:Option = new Option('Time Bar Blue:',
			"The Amount of Blue in the Time Bar's Colour.",
			'timeBarBlue',
			'int',
			255);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 255;

		super();
	}

	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; //Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; //Don't judge me ok
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}
}