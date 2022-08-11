package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
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

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['General', 'Gameplay', 'Graphics', 'Misc', 'Notes', 'Controls', 'Offsets'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'General':
				openSubState(new options.GeneralSettingsSubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Misc':
				openSubState(new options.MiscSettingsSubState());
			case 'Notes':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
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

	override function create() {
		#if desktop
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.updateHitbox();

		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgScroll);

		bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgScroll2);

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

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (PauseSubState.transferPlayState) {
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
			} else {
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if (controls.ACCEPT) {
			openSelectedSubstate(options[curSelected]);
		}

		if (controls.RESET) {
			FlxG.mouse.visible = true;
			openSubState(new Prompt('This action will clear all settings.\n\nProceed?', 0, function(){resetSettings(); }, null,FlxG.save.data.ignoreWarnings));
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
		if (PlayState.SONG != null) {
			if (PlayState.SONG.song == 'Zavodila')  {
				FlxG.camera.shake(0.0075, 0.2);
				bg.scale.set(1.16,1.16);
				bg.updateHitbox();
			}
		}
		//trace('beat hit' + curBeat);
	}

	function resetSettings() 
	{
		ClientPrefs.downScroll = false;
		ClientPrefs.middleScroll = false;
		ClientPrefs.showFPS = true;
		ClientPrefs.flashing = true;
		ClientPrefs.globalAntialiasing = true;
		ClientPrefs.noteSplashes = true;
		ClientPrefs.lowQuality = false;
		ClientPrefs.framerate = 60;
		ClientPrefs.crossFadeLimit = 4;
		ClientPrefs.boyfriendCrossFadeLimit = 1;
		ClientPrefs.opponentNoteAnimations = true;
		ClientPrefs.opponentAlwaysDance = true;
		ClientPrefs.cursing = true;
		ClientPrefs.violence = true;
		ClientPrefs.camZooms = true;
		ClientPrefs.camPans = true;
		ClientPrefs.hideHud = false;
		ClientPrefs.noteOffset = 0;
		ClientPrefs.arrowHSV = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
		ClientPrefs.timeBarRed = 255;
		ClientPrefs.timeBarGreen = 255;
		ClientPrefs.timeBarBlue = 255;
		ClientPrefs.uiSkin = 'fnf';
		ClientPrefs.iconSwing = 'Swing Mild';
		ClientPrefs.scoreDisplay = 'Psych';
		ClientPrefs.crossFadeMode = 'Mid-Fight Masses';
		ClientPrefs.imagesPersist = false;
		ClientPrefs.ghostTapping = true;
		ClientPrefs.timeBarType = 'Time Left';
		ClientPrefs.scoreZoom = true;
		ClientPrefs.noReset = false;
		ClientPrefs.healthBarAlpha = 1;
		ClientPrefs.controllerMode = false;
		ClientPrefs.hitsoundVolume = 0;
		ClientPrefs.pauseMusic = 'Tea Time';
		ClientPrefs.inputType = 'Psych';
		ClientPrefs.ratingIntensity = 'Default';
		ClientPrefs.orbsScattered = false;
		ClientPrefs.randomMode = false;
		ClientPrefs.quartiz = false;
		ClientPrefs.ghostMode = false;
		ClientPrefs.watermarks = true;
		ClientPrefs.ratingsDisplay = true;
		ClientPrefs.gsmiss = true;
		ClientPrefs.winningicons = true;
		ClientPrefs.changeTBcolour = true;
		ClientPrefs.greenhp = false;
		ClientPrefs.newHP = true;
		ClientPrefs.sarvAccuracy = false;
		ClientPrefs.comboOffset = [0, 0, 0, 0, 0, 0];
		ClientPrefs.noAntimash = false;
		ClientPrefs.ratingOffset = 0;
		ClientPrefs.perfectWindow = 10;
		ClientPrefs.sickWindow = 45;
		ClientPrefs.goodWindow = 90;
		ClientPrefs.badWindow = 135;
		ClientPrefs.shitWindow = 205;
		ClientPrefs.safeFrames = 10;
		FlxG.mouse.visible = false;
	}
}