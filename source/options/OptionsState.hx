package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

using StringTools;

/**
* State used to take the player to the different options substates.
*/
class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['General', 'Gameplay', 'Graphics', 'Misc', 'Notes', 'Keybinds', 'Offsets'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'General':
				openSubState(new options.OptionsSubState.GeneralSettingsSubState());
			case 'Gameplay':
				openSubState(new options.OptionsSubState.GameplaySettingsSubState());
			case 'Graphics':
				openSubState(new options.OptionsSubState.GraphicsSettingsSubState());
			case 'Misc':
				openSubState(new options.OptionsSubState.MiscSettingsSubState());
			case 'Notes':
				openSubState(new options.OptionsSubState.NotesSubState());
			case 'Keybinds':
				openSubState(new options.OptionsSubState.ControlsSubState());
			case 'Offsets':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var bg:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;
	var gradient:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		#if desktop
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		FreeplayState.destroyFreeplayVocals();
		FlxG.sound.playMusic(Paths.music('msm'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.6);

		Conductor.changeBPM(99);

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		if (!ClientPrefs.lowQuality) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		gradient.scrollFactor.set(0, 0);
		add(gradient);
		//gradient.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.lowQuality) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	
		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		var shiftMult:Int = 1;

		if(FlxG.mouse.wheel != 0 && ClientPrefs.mouseControls)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}

		if (controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls)) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (PauseSubState.transferPlayState) {
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.globeTrans = false;
				LoadingState.loadAndSwitchState(new PlayState());
			} else {
				MusicBeatState.switchState(new MainMenuState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				Conductor.changeBPM(100);		
			}
		}

		if (controls.ACCEPT || (FlxG.mouse.justPressed && ClientPrefs.mouseControls)) {
			openSelectedSubstate(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		//trace('beat hit' + curBeat);
	}
}