package options;

import Controls;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
#if desktop
import Discord.DiscordClient;
#end

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
			case 'General': openSubState(new options.OptionsSubState.GeneralSettingsSubState());
			case 'Gameplay': openSubState(new options.OptionsSubState.GameplaySettingsSubState());
			case 'Graphics': openSubState(new options.OptionsSubState.GraphicsSettingsSubState());
			case 'Misc': openSubState(new options.OptionsSubState.MiscSettingsSubState());
			case 'Notes': openSubState(new options.OptionsSubState.NotesSubState());
			case 'Keybinds': openSubState(new options.OptionsSubState.ControlsSubState());
			case 'Offsets': MusicBeatState.switchState(new options.NoteOffsetState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	var bg:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;
	var gradient:FlxSprite;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var camMain:FlxCamera;
	var camSub:FlxCamera;

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		MusicBeatState.disableManual = true;
		FreeplayState.destroyFreeplayVocals();
		FlxG.sound.playMusic(Paths.music('msm'), 0);
		FlxG.sound.music.fadeIn(1, 0, 0.6);

		Conductor.changeBPM(99);

		camMain = new FlxCamera();
		camSub = new FlxCamera();
		camSub.bgColor.alpha = 0;

		FlxG.cameras.reset(camMain);
		FlxG.cameras.add(camSub, false);

		FlxG.cameras.setDefaultDrawTarget(camMain, true);
		CustomFadeTransition.nextCamera = camSub;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);
		FlxG.camera.follow(camFollowPos, null, 1);

		final yScroll:Float = Math.max(0.25 - (0.05 * (options.length - 4)), 0.1);
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.scale.set(1.07, 1.07);
		bg.updateHitbox();
		bg.scrollFactor.set(0, yScroll/3);
		bg.screenCenter();
		bg.y += 5;
		add(bg);

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			bgScroll.scrollFactor.set(0, 0);
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			bgScroll2.scrollFactor.set(0, 0);
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (110 * (i - (options.length / 2))) + 50;
			optionText.scrollFactor.set(0, yScroll);
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		selectorLeft.scrollFactor.set(0, yScroll);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true, false);
		selectorRight.scrollFactor.set(0, yScroll);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		super.create();
	}

	override function openSubState(subState:FlxSubState) {
		super.openSubState(subState);
		if (!(subState is CustomFadeTransition)) {
			persistentDraw = false;
			persistentUpdate = false;
		}
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		persistentDraw = true;
		persistentUpdate = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var lerpVal:Float = CoolUtil.clamp(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
	
		var mult:Float = FlxMath.lerp(1.07, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

		if (controls.UI_UP_P) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P) {
			changeSelection(1);
		}

		var shiftMult:Int = 1;

		if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (PauseSubState.transferPlayState) {
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.globeTrans = false;
				LoadingState.loadAndSwitchState(new PlayState());
			} else {
				MusicBeatState.switchState(new MainMenuState());
				FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
				Conductor.changeBPM(SoundTestState.playingTrackBPM);		
			}
		}

		if (controls.ACCEPT) {
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
				final add:Float = (grpOptions.members.length > 4 ? grpOptions.members.length * 8 : 0);
				camFollow.setPosition(item.getGraphicMidpoint().x, item.getGraphicMidpoint().y - add);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.11, 1.11);
		bg.updateHitbox();
		bg.offset.set();
	}
}