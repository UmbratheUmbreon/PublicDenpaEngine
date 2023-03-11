package options;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;

/**
* State used in the options menu to adjust offsets, both audio and visual wise.
*/
class NoteOffsetState extends MusicBeatState
{
	var boyfriend:Character;
	var gf:Character;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var coolText:FlxText;
	var rating:FlxSprite;
	var healthBar:FlxSprite;
	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;
	var comboNums:FlxSpriteGroup;
	var dumbTexts:FlxTypedGroup<FlxText>;

	var barPercent:Float = 0;
	var delayMin:Int = -500;
	var delayMax:Int = 500;
	var timeBarBG:FlxSprite;
	var timeBar:FlxBar;
	var timeTxt:FlxText;
	var beatText:Alphabet;
	var beatTween:FlxTween;

	var changeModeText:FlxText;

	override public function create()
	{
		SoundTestState.isPlaying = false;
		// Cameras
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true); //new EPIC code
		//FlxCamera.defaultCameras = [camGame]; //old STUPID code
		CustomFadeTransition.nextCamera = camOther;
		FlxG.camera.scroll.set(120, 130);

		persistentUpdate = true;
		FlxG.sound.pause();
		// Stage
		var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);

		// Characters
		gf = new Character(400, 130, 'gf');
		gf.x += gf.positionOffset.x;
		gf.y += gf.positionOffset.y;
		gf.scrollFactor.set(0.95, 0.95);
		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionOffset.x;
		boyfriend.y += boyfriend.positionOffset.y;
		add(gf);
		add(boyfriend);

		// Combo stuff

		healthBar = new FlxSprite().makeGraphic(601, 19, FlxColor.BLACK);
		healthBar.cameras = [camHUD];
		var healthBarRed = new AttachedSprite.NGAttachedSprite(Std.int(healthBar.width/2)-3, 13, 0xFFFF0000);
		healthBarRed.cameras = [camHUD];
		healthBarRed.xAdd = 3;
		healthBarRed.yAdd = 3;
		healthBarRed.sprTracker = healthBar;
		healthBarRed.copyVisible = true;
		var healthBarGreen = new AttachedSprite.NGAttachedSprite(Std.int(healthBar.width/2)-3, 13, 0xFF54FF00);
		healthBarGreen.cameras = [camHUD];
		healthBarGreen.xAdd = 301;
		healthBarGreen.yAdd = 3;
		healthBarGreen.sprTracker = healthBar;
		healthBarGreen.copyVisible = true;

		leftIcon = new HealthIcon('dad');
		rightIcon = new HealthIcon('bf');
		rightIcon.flipX = true;
		leftIcon.cameras = [camHUD];
		rightIcon.cameras = [camHUD];
		
		add(healthBar);
		add(healthBarRed);
		add(healthBarGreen);
		add(rightIcon);
		add(leftIcon);

		coolText = new FlxText(0, 0, 0, '', 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;

		rating = new FlxSprite().loadGraphic(Paths.image('ratings/sick-fnf'));
		rating.cameras = [camHUD];
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		
		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.cameras = [camHUD];
		add(comboNums);

		var seperatedScore:Array<Int> = [];
		for (i in 0...3)
		{
			seperatedScore.push(FlxG.random.int(0, 9));
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite(43 * daLoop).loadGraphic(Paths.image('nums/num' + i + '-fnf'));
			numScore.cameras = [camHUD];
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			comboNums.add(numScore);
			daLoop++;
		}

		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.cameras = [camHUD];
		add(dumbTexts);
		createTexts();

		repositionCombo();

		// Note delay stuff
		
		beatText = new Alphabet(0, 0, 'Beat Hit!', true, false, 0.05, 0.6);
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		beatText.visible = false;
		add(beatText);
		
		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;
		timeTxt.visible = false;
		timeTxt.cameras = [camHUD];

		barPercent = ClientPrefs.settings.get("noteOffset");
		updateNoteDelay();
		
		timeBarBG = new FlxSprite(0, timeTxt.y + 48).makeGraphic(400, 20, FlxColor.BLACK);
		timeBarBG.setGraphicSize(Std.int(timeBarBG.width * 1.2));
		timeBarBG.updateHitbox();
		timeBarBG.cameras = [camHUD];
		timeBarBG.screenCenter(X);
		timeBarBG.visible = false;

		timeBar = new FlxBar(0, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'barPercent', delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.createFilledBar(0xFF000000, 0xFF82A17B);
			if (ClientPrefs.settings.get("lowQuality")) {
				timeBar.numDivisions = Std.int((timeBar.width)/4);
			} else {
				timeBar.numDivisions = Std.int(timeBar.width); //what if it was 1280 :flushed:
			}
		timeBar.visible = false;
		timeBar.cameras = [camHUD];

		add(timeBarBG);
		add(timeBar);
		add(timeTxt);

		var blackBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		blackBox.scrollFactor.set();
		blackBox.alpha = 0.6;
		blackBox.cameras = [camHUD];
		add(blackBox);

		changeModeText = new FlxText(0, 4, FlxG.width, "", 32);
		changeModeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		changeModeText.scrollFactor.set();
		changeModeText.cameras = [camHUD];
		add(changeModeText);
		updateMode();

		Conductor.changeBPM(128.0);
		FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);

		super.create();
	}

	var holdTime:Float = 0;
	var onComboMenu:Bool = true;
	var holdingObjectType:Null<Bool> = null;

	var startMousePos:FlxPoint = FlxPoint.get();
	var startComboOffset:FlxPoint = FlxPoint.get();

	override public function update(elapsed:Float)
	{
		var iconOffset:Int = 26;
		rightIcon.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(50, 0, 100, 100, 0) * 0.01)) + (150 * rightIcon.scale.x - 150) / 2 - iconOffset;
		leftIcon.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(50, 0, 100, 100, 0) * 0.01)) - (150 * leftIcon.scale.x) / 2 - iconOffset * 2;
		leftIcon.y = rightIcon.y = healthBar.y - 70;

		var addNum:Int = 1;
		if(FlxG.keys.pressed.SHIFT) addNum = 10;

		if(onComboMenu)
		{
			var controlArray:Array<Bool> = [
				FlxG.keys.justPressed.LEFT,
				FlxG.keys.justPressed.RIGHT,
				FlxG.keys.justPressed.UP,
				FlxG.keys.justPressed.DOWN,
			
				FlxG.keys.justPressed.A,
				FlxG.keys.justPressed.D,
				FlxG.keys.justPressed.W,
				FlxG.keys.justPressed.S,

				FlxG.keys.justPressed.I,
				FlxG.keys.justPressed.K,
				FlxG.keys.justPressed.L,
				FlxG.keys.justPressed.J
			];

			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
					{
						switch(i)
						{
							case 0:
								ClientPrefs.comboOffset[0] -= addNum;
							case 1:
								ClientPrefs.comboOffset[0] += addNum;
							case 2:
								ClientPrefs.comboOffset[1] += addNum;
							case 3:
								ClientPrefs.comboOffset[1] -= addNum;
							case 4:
								ClientPrefs.comboOffset[2] -= addNum;
							case 5:
								ClientPrefs.comboOffset[2] += addNum;
							case 6:
								ClientPrefs.comboOffset[3] += addNum;
							case 7:
								ClientPrefs.comboOffset[3] -= addNum;
							case 8:
								ClientPrefs.comboOffset[4] -= addNum; //x
							case 9:
								ClientPrefs.comboOffset[4] += addNum;
							case 10:
								ClientPrefs.comboOffset[5] += addNum; //y
							case 11:
								ClientPrefs.comboOffset[5] -= addNum;
						}
					}
				}
				repositionCombo();
			}

			// probably there's a better way to do this but, oh well.
			if (FlxG.mouse.justPressed)
			{
				holdingObjectType = null;
				FlxG.mouse.getScreenPosition(camHUD, startMousePos);
				if (startMousePos.x - comboNums.x >= 0 && startMousePos.x - comboNums.x <= comboNums.width &&
					startMousePos.y - comboNums.y >= 0 && startMousePos.y - comboNums.y <= comboNums.height)
				{
					holdingObjectType = true;
					startComboOffset.x = ClientPrefs.comboOffset[2];
					startComboOffset.y = ClientPrefs.comboOffset[3];
					trace('combo nums sex');
				}
				else if (startMousePos.x - rating.x >= 0 && startMousePos.x - rating.x <= rating.width &&
						 startMousePos.y - rating.y >= 0 && startMousePos.y - rating.y <= rating.height)
				{
					holdingObjectType = false;
					startComboOffset.x = ClientPrefs.comboOffset[0];
					startComboOffset.y = ClientPrefs.comboOffset[1];
					trace('rating sex');
				}
			}
			if(FlxG.mouse.justReleased) {
				holdingObjectType = null;
				trace('dead');
			}

			if(holdingObjectType != null)
			{
				if(FlxG.mouse.justMoved)
				{
					var mousePos:FlxPoint = FlxG.mouse.getScreenPosition(camHUD);
					var addNum:Int = holdingObjectType ? 2 : 0;
					ClientPrefs.comboOffset[addNum + 0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
					ClientPrefs.comboOffset[addNum + 1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
					mousePos.put();
					repositionCombo();
				}
			}

			if(controls.RESET)
			{
				for (i in 0...ClientPrefs.comboOffset.length)
				{
					ClientPrefs.comboOffset[i] = 0;
				}
				repositionCombo();
			}
		}
		else
		{
			if(controls.UI_LEFT_P)
			{
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.settings.get("noteOffset") - 1, delayMax));
				updateNoteDelay();
			}
			else if(controls.UI_RIGHT_P)
			{
				barPercent = Math.max(delayMin, Math.min(ClientPrefs.settings.get("noteOffset") + 1, delayMax));
				updateNoteDelay();
			}

			var mult:Int = 1;
			if(controls.UI_LEFT || controls.UI_RIGHT)
			{
				holdTime += elapsed;
				if(controls.UI_LEFT) mult = -1;
			}

			if(controls.UI_LEFT_R || controls.UI_RIGHT_R) holdTime = 0;

			if(holdTime > 0.5)
			{
				barPercent += 100 * elapsed * mult;
				barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
				updateNoteDelay();
			}

			if(controls.RESET)
			{
				holdTime = 0;
				barPercent = 0;
				updateNoteDelay();
			}
		}

		if(controls.ACCEPT)
		{
			onComboMenu = !onComboMenu;
			updateMode();
		}

		if(controls.BACK)
		{
			if(zoomTween != null) zoomTween.cancel();
			if(beatTween != null) beatTween.cancel();

			persistentUpdate = false;
			CustomFadeTransition.nextCamera = camOther;
			MusicBeatState.switchState(new options.OptionsState());
			FlxG.sound.playMusic(Paths.music('msm'), 0);
			FlxG.sound.music.fadeIn(1, 0, 0.6);
	
			Conductor.changeBPM(99);	
			FlxG.mouse.visible = false;
		}

		Conductor.songPosition = FlxG.sound.music.time;
		super.update(elapsed);
	}

	var zoomTween:FlxTween;
	var lastBeatHit:Int = -1;
	override public function beatHit()
	{
		super.beatHit();

		if(lastBeatHit == curBeat)
		{
			return;
		}

		if(curBeat % 2 == 0)
		{
			boyfriend.dance();
			gf.dance();
		}
		
		if(curBeat % 4 == 2)
		{
			FlxG.camera.zoom = 1.15;

			if(zoomTween != null) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween)
				{
					zoomTween = null;
				}
			});

			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
			if(beatTween != null) beatTween.cancel();
			beatTween = FlxTween.tween(beatText, {alpha: 0}, 1, {ease: FlxEase.sineIn, onComplete: function(twn:FlxTween)
				{
					beatTween = null;
				}
			});
		}

		lastBeatHit = curBeat;
	}

	function repositionCombo()
	{
		rating.screenCenter();
		rating.x = coolText.x - 40 + ClientPrefs.comboOffset[0];
		rating.y -= 60 + ClientPrefs.comboOffset[1];

		healthBar.screenCenter();
		healthBar.y = FlxG.height * 0.89 + ClientPrefs.comboOffset[4];
		healthBar.x = FlxG.width/4 + ClientPrefs.comboOffset[5];

		comboNums.screenCenter();
		comboNums.x = coolText.x - 90 + ClientPrefs.comboOffset[2];
		comboNums.y += 80 - ClientPrefs.comboOffset[3];
		reloadTexts();
	}

	function createTexts()
	{
		for (i in 0...13)
		{
			var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
			text.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 2;
			dumbTexts.add(text);
			text.cameras = [camHUD];

			if(i > 1)
			{
				text.y += 24;
			}
		}
	}

	function reloadTexts()
	{
		for (i in 0...dumbTexts.length)
		{
			switch(i)
			{
				case 0: dumbTexts.members[i].text = 'Rating Offset:';
				case 1: dumbTexts.members[i].text = '[' + ClientPrefs.comboOffset[0] + ', ' + ClientPrefs.comboOffset[1] + ']';
				case 2: dumbTexts.members[i].text = 'Numbers Offset:';
				case 3: dumbTexts.members[i].text = '[' + ClientPrefs.comboOffset[2] + ', ' + ClientPrefs.comboOffset[3] + ']';
				case 4: dumbTexts.members[i].text = 'Healthbar Offset:';
				case 5: dumbTexts.members[i].text = '[' + ClientPrefs.comboOffset[4] + ', ' + ClientPrefs.comboOffset[5] + ']';
				case 6: dumbTexts.members[i].text = 'Controls:';
				case 7: dumbTexts.members[i].text = 'LEFT RIGHT UP DOWN:';
				case 8: dumbTexts.members[i].text = 'Move Rating Offset';
				case 9: dumbTexts.members[i].text = 'A D W S:';
				case 10: dumbTexts.members[i].text = 'Move Combo Offset';
				case 11: dumbTexts.members[i].text = 'J L I K:';
				case 12: dumbTexts.members[i].text = 'Move Healthbar Offset';
			}
		}
	}

	function updateNoteDelay()
	{
		ClientPrefs.settings.set("noteOffset", Math.round(barPercent));
		timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
	}

	function updateMode()
	{
		rating.visible = onComboMenu;
		healthBar.visible = onComboMenu;
		leftIcon.visible = onComboMenu;
		rightIcon.visible = onComboMenu;
		comboNums.visible = onComboMenu;
		dumbTexts.visible = onComboMenu;
		
		timeBarBG.visible = !onComboMenu;
		timeBar.visible = !onComboMenu;
		timeTxt.visible = !onComboMenu;
		beatText.visible = !onComboMenu;

		if(onComboMenu)
			changeModeText.text = '< Combo Offset (Press Accept to Switch) >';
		else
			changeModeText.text = '< Note/Beat Delay (Press Accept to Switch) >';

		changeModeText.text = changeModeText.text.toUpperCase();
		FlxG.mouse.visible = onComboMenu;
	}

	override function destroy() {
		startMousePos = FlxDestroyUtil.put(startMousePos);
		startComboOffset = FlxDestroyUtil.put(startComboOffset);
		super.destroy();
	}
}
