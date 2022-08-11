package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var denpaEngineVersion:String = '0.4.0e Nightly'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;
	public static var seenTween:Bool = false;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var curDifficulty:Int = -1;
	
	var optionShit:Array<String> = ['story_mode', 
				'freeplay', 
				'credits', 
				'options',
				'patch',
				'soundtest'];
//This causes the screen to blank out, looks like the other stuff is going to the optionShit variable. -Beth
	function menuShit()
	{
		if(ClientPrefs.orbsScattered == false) {
		//trace('no true');
			optionShit = [
				'story_mode', 
				'freeplay', 
				'credits', 
				'options',
				'patch',
				'soundtest'
				];
				
		}	
		else {
		//trace('true');
			optionShit = [
				'optionstrue',
				'true'
			];
		}
	}
	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var logo:FlxSprite;
	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();
	if(ClientPrefs.orbsScattered == false) {
		//trace('test1');
			optionShit = [
				'story_mode', 
				'freeplay', 
				'credits', 
				'options',
				'patch',
				'soundtest'
				];
		}	
		else {
		//trace('test2');
			optionShit = [
				'optionstrue',
				'true'
			];
		}
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("On the Main Menu", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true); //new EPIC code
		//FlxCamera.defaultCameras = [camGame]; //old STUPID code

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var xScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		//bg.setGraphicSize(Std.int(bg.width * 1.175));
		//bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
		bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
		if (!ClientPrefs.lowQuality) {
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		gradient.scrollFactor.set(0, 0);
		add(gradient);
		//gradient.screenCenter();

		logo = new FlxSprite(270, FlxG.height/2);
		logo.frames = Paths.getSparrowAtlas('logoBumpin');
		logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logo.animation.play('bump');
		logo.scrollFactor.set(0, 0);
		logo.setGraphicSize(Std.int(0.75));
		logo.updateHitbox();
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		logo.alpha = 0;
		if(seenTween){
			logo.y = 0;
			logo.alpha = 1;
		}
		add(logo);

		var bg3:FlxSprite = new FlxSprite(270,0);
		bg3.frames = Paths.getSparrowAtlas('secret/logotrue');
		bg3.animation.addByPrefix('nameToCall','logotrue idle',24,true);
		bg3.animation.play('nameToCall');
		bg3.antialiasing = ClientPrefs.globalAntialiasing;
		bg3.scrollFactor.set(0, 0);
		bg3.setGraphicSize(Std.int(0.75));
		bg3.updateHitbox();
		add(bg3);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		// magenta.scrollFactor.set();

	if(ClientPrefs.orbsScattered == false) {
		bg3.visible = false;
		bg.visible = true;
		logo.visible = true;
		if (!ClientPrefs.lowQuality) {
			bgScroll.visible = true;
			bgScroll2.visible = true;
		}
		}	
		else {
		bg3.visible = true;
		bg.visible = false;
		logo.visible = false;
		if (!ClientPrefs.lowQuality) {
			bgScroll.visible = false;
			bgScroll2.visible = false;
		}
		}

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.alpha = 0;
			if(seenTween) menuItem.alpha = 1;
			menuItem.ID = i;
			switch (optionShit[i])
			{case 'story_mode':
				menuItem.x = 115;
				menuItem.y = 450;
				/*if(!seenTween){
					menuItem.x = -1385;
				}*/
			case 'freeplay':
				menuItem.x = 315;
				menuItem.y = 450;
				/*if(!seenTween){
					menuItem.x = -1185;
					menuItem.y = 1950;
				}*/
			case 'credits':
				menuItem.x = 515;
				menuItem.y = 450;
				/*if(!seenTween){
					menuItem.y = 1950;
				}*/
			case 'options':
				menuItem.x = 715;
				menuItem.y = 450;
				/*if(!seenTween){
					menuItem.x = 2215;
					menuItem.y = 1950;
				}*/
			case 'patch':
				menuItem.x = 915;
				menuItem.y = 450;
				/*if(!seenTween){
					menuItem.x = 2415;
				}*/
			case 'soundtest':
				menuItem.x = 0;
				menuItem.y = -30;
			case 'true':
				menuItem.x = 370;
				menuItem.y = -9999;
			case 'optionstrue':
				menuItem.x = 345;
				menuItem.y = 250;
			}
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, 0);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit2:FlxText = new FlxText(12, FlxG.height - 44, 0, "Denpa Engine v" + denpaEngineVersion, 12);
		versionShit2.scrollFactor.set();
		versionShit2.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit2);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

	if(ClientPrefs.orbsScattered == false) {
		versionShit.visible = true;
		versionShit2.visible = true;
		}	
		else {
		versionShit.visible = false;
		versionShit2.visible = false;
		}

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		if(!seenTween){
		FlxTween.tween(logo, {y: 0, alpha: 1}, 1, {ease: FlxEase.quadOut});
		menuItems.forEach(function(spr:FlxSprite)
			{
				FlxTween.tween(spr, {alpha: 1}, 1.4, {
					ease: FlxEase.quadOut,
				});
			});
		seenTween = true;
		}

		//Conductor.changeBPM(100);

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.lowQuality) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();
		
		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();

		if (!selectedSomethin)
		{
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(4);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-4);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					//if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
									case 'patch':
										MusicBeatState.switchState(new PatchState());
									case 'soundtest':
										MusicBeatState.switchState(new SoundTestState());
									case 'true':
										MusicBeatState.switchState(new FreeplayState());
									case 'optionstrue':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
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
		if(logo != null) 
			logo.animation.play('bump', true);
		//trace('beat hit' + curBeat);
	}
}
