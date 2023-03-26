package;

import Controls;
import flash.system.System;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import openfl.display.BlendMode;

/**
* Substate used to create a pause menu for `PlayState`.
*/
class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Replay Cutscene', 'Change Difficulty', 'Change Modifiers', 'Options Menu', 'Tools', 'Exit'];
	var difficultyChoices = [];
	var exitChoices = ['Exit To Song Menu', 'Exit To Main Menu', 'Exit Game', 'BACK'];
	var devChoices = ['Skip Time', 'End Song', 'Toggle Practice Mode', 'Toggle Botplay', 'Leave Charting Mode', 'BACK'];
	var curSelected:Int = 0;
	public static var changedOptions:Bool = false;
	public static var transferPlayState:Bool = false;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	public static var songName:String = '';

	public function new(x:Float, y:Float)
	{
		super();
		if(CoolUtil.difficulties.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!
		if(!PlayState.hasCutscene || !PlayState.instance.canIUseTheCutsceneMother(true)) menuItemsOG.remove('Replay Cutscene');

		var devTools:Bool = PlayState.chartingMode;
		#if debug devTools = true; #end //always allow botplay etc on debug builds
		//sub menu le cool
		menuItemsOG.remove('Tools');
		if(devTools) {
			//why do you have to be weird?
			if (!PlayState.chartingMode) devChoices.remove('Leave Charting Mode');
			menuItemsOG.remove('Exit');
			menuItemsOG.push('Tools');
			menuItemsOG.push('Exit');
		}

		menuItems = menuItemsOG;

		for (i in 0...CoolUtil.difficulties.length) {
			var diff:String = '' + CoolUtil.difficulties[i];
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		//Not sure 'bout this one chief
		pauseMusic = new FlxSound();
		pauseMusic.loadEmbedded(Paths.music((songName != '' && songName != null) ? songName : Paths.formatToSongPath(ClientPrefs.settings.get("pauseMusic"))), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		bg.active = false;
		add(bg);

		if (!ClientPrefs.settings.get("lowQuality")) {
			var bgScroll:FlxBackdrop = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(19, 20);
			bgScroll.alpha = 0;
			add(bgScroll);
			FlxTween.tween(bgScroll, {alpha: 0.03}, 1, {
				ease: FlxEase.quadOut
			});
	
			var bgScroll2:FlxBackdrop = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-19, -20);
			bgScroll2.alpha = 0;
			add(bgScroll2);
			FlxTween.tween(bgScroll2, {alpha: 0.03}, 1, {
				ease: FlxEase.quadOut
			});
		}

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.header.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		levelInfo.active = false;
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.toTitleCase(CoolUtil.difficultyString().toLowerCase());
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.active = false;
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, "", 32);
		blueballedTxt.text = "Blueballed: " + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.font('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.active = false;
		add(blueballedTxt);

		practiceText = new FlxText(20, 15 + 96, 0, "Practice Mode", 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.font('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.alpha = 0;
		practiceText.visible = PlayState.instance.practiceMode;
		practiceText.active = false;
		add(practiceText);

		var chartingText:FlxText = new FlxText(20, 15 + 101, 0, "Charting Mode", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.font('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.y = FlxG.height - (chartingText.height + 25);
		chartingText.updateHitbox();
		chartingText.alpha = 0;
		chartingText.visible = PlayState.chartingMode;
		chartingText.active = false;
		add(chartingText);

		blueballedTxt.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.6, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
		FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
		FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
		FlxTween.tween(chartingText, {alpha: 1, y: chartingText.y - 5}, 0.4, {ease: FlxEase.quartInOut});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		if (menuItems == devChoices) {
			updateSkipTextStuff();
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		var shiftMult:Int = 1;

		if(FlxG.mouse.wheel != 0)
		{
			changeSelection(-shiftMult * FlxG.mouse.wheel);
		}

		var daSelected:String = menuItems[curSelected];
		switch (daSelected)
		{
			case 'Skip Time':
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime -= 1000;
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					curTime += 1000;
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if(holdTime > 0.5)
					{
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
					else if(curTime < 0) curTime += FlxG.sound.music.length;
					updateSkipTimeText();
				}
		}

		if (accepted)
		{
			if (menuItems == difficultyChoices)
			{
				if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
					var name:String = PlayState.SONG.header.song;
					var poop = Highscore.formatSong(name, curSelected);
					function evenMoreFittingName() {
						PlayState.SONG = Song.loadFromJson(poop, name);
						PlayState.storyDifficulty = curSelected;
						MusicBeatState.resetState();
						FlxG.sound.music.volume = 0;
						PlayState.changedDifficulty = true;
						PlayState.chartingMode = false;
					}
					function invalidJson() {
						trace(poop + '.json does not exist!');
						FlxG.sound.play(Paths.sound('invalidJSON'));
						FlxG.camera.shake(0.05, 0.05);
						var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!\n" + poop + ".json");
						funnyText.scrollFactor.set();
						funnyText.screenCenter();
						funnyText.x = 5;
						funnyText.y = FlxG.height/2 - 64;
						funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						add(funnyText);
						FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
							onComplete: _ -> {
								remove(funnyText, true);
								funnyText.destroy();
							}
						});
					}
					#if sys
					if(sys.FileSystem.exists(Paths.modsJson('charts/' + Paths.formatToSongPath(name) + '/' + poop)) || sys.FileSystem.exists(Paths.json('charts/' + Paths.formatToSongPath(name) + '/' + poop)))
						evenMoreFittingName();
					else
						invalidJson();
					#else
					if(OpenFlAssets.exists(Paths.json('charts/' + Paths.formatToSongPath(name) + '/' + poop)))
						evenMoreFittingName();
					else
						invalidJson();
					#end
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			function defaultExit() {
				transferPlayState = false;
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				MusicBeatState.switchState((PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState()));
				FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
				Conductor.changeBPM(SoundTestState.playingTrackBPM);
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
			}

			if (menuItems == exitChoices)
			{
				if(menuItems.length - 1 != curSelected && exitChoices.contains(daSelected)) {
					switch (daSelected)
					{
						case "Exit To Song Menu":
							defaultExit();
						case "Exit To Main Menu":
							transferPlayState = false;
							PlayState.deathCounter = 0;
							PlayState.seenCutscene = false;
							MusicBeatState.switchState(new MainMenuState());
							FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
							Conductor.changeBPM(SoundTestState.playingTrackBPM);
							PlayState.changedDifficulty = false;
							PlayState.chartingMode = false;
						case "Exit Game":
							System.exit(0);
						case "Exit To Your Mother":
							var aLittleCrashing:FlxSprite = null;
							aLittleCrashing.destroy();
					}
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			if (menuItems == devChoices)
			{
				//mfw i use the wrong variable
				if(menuItems.length - 1 != curSelected && devChoices.contains(daSelected)) {
					switch (daSelected)
					{
						case 'Skip Time':
							if(curTime < Conductor.songPosition)
							{
								PlayState.startOnTime = curTime;
								restartSong(true);
							}
							else
							{
								if (curTime != Conductor.songPosition)
								{
									PlayState.instance.clearNotesBefore(curTime);
									PlayState.instance.setSongTime(curTime);
								}
								close();
							}
						case "End Song":
							transferPlayState = false;
							close();
							PlayState.instance.finishSong(true);
						case 'Toggle Botplay':
							PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
							PlayState.changedDifficulty = true;
							PlayState.instance.hud.botplayTxt.visible = PlayState.instance.cpuControlled;
							PlayState.instance.hud.botplayTxt.alpha = 1;
							PlayState.instance.hud.botplaySine = 0;
						case 'Toggle Practice Mode':
							PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
							PlayState.changedDifficulty = true;
							practiceText.visible = PlayState.instance.practiceMode;
						case "Leave Charting Mode":
							restartSong();
							PlayState.chartingMode = false;
					}
					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case "Resume":
					close();
				case "Restart Song":
					restartSong();
				case "Replay Cutscene":
					PlayState.seenCutscene = false;
					restartSong();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					regenMenu();
				case 'Change Modifiers':
					persistentUpdate = false;
					openSubState(new GameplayChangersSubstate(this));
				case 'Tools':
					menuItems = devChoices;
					regenMenu();
				case "Options Menu":
					transferPlayState = true;
					LoadingState.silentLoading = true;
					LoadingState.loadAndSwitchState(new options.OptionsState());
				case 'Exit':
					if (FlxG.keys.pressed.SHIFT) defaultExit();
					else {
						menuItems = exitChoices;
						if (FlxG.random.bool(0.1)) exitChoices[1] = 'Exit To Your Mother';
						regenMenu();
					}
			}
		}
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.customTransition = false;
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		else
		{
			MusicBeatState.resetState();
		}
	}

	override function destroy()
	{
		pauseMusic.destroy();
		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;

				if(item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			var item = new Alphabet(0, FlxG.width/5 + (70 * i + 30), menuItems[i], true, false);
			item.x += 30;
			item.altRotation = true;
			item.targetY = i;
			grpMenuShit.add(item);

			if(menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = item;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}
		curSelected = 0;
		changeSelection();
	}
	
	function updateSkipTextStuff()
	{
		if(skipTimeText == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		if(skipTimeText == null) return;

		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
