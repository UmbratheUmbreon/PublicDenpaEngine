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

class MiscSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc';
		rpcTitle = 'Misc Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Opponent CrossFade Limit',
			"Determines the maximium amount of frames of CrossFade the opponent can have.",
			'crossFadeLimit',
			'int',
			4);
		addOption(option);

		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('BF CrossFade Limit',
			"Determines the maximium amount of frames of CrossFade the player can have.",
			'boyfriendCrossFadeLimit',
			'int',
			1);
		addOption(option);

		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('CrossFade Mode:',
			"What mode should CrossFade be in?",
			'crossFadeMode',
			'string',
			'Mid-Fight Masses',
			['Mid-Fight Masses', 'Static', 'Eccentric', 'Off']);
		addOption(option);

		var option:Option = new Option('Cutscenes:',
			'When do you want cutscenes to play?',
			'cutscenes',
			'string',
			'Story Mode Only',
			['Story Mode Only', 'Freeplay Only', 'Always', 'Never']);
		addOption(option);

		var option:Option = new Option('Quartiz',
			'Quartiz',
			'quartiz',
			'bool',
			false);
		addOption(option);

		super();
	}
}