package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

/**
* State containing connections to other states, serving as a hub for the menus.
*/
class MainMenuState extends MusicBeatState
{
	#if !debug
	public static var denpaEngineVersion:String = '0.7.0b'; //This is also used for Discord RPC
	#else
	public static var denpaEngineVersion:String = '0.7.0b Nightly'; //For declaring "HEY THIS ISNT FINAL"
	#end
	public static var baseVersion:String = '0.5.2h'; //For those wondering what this engine is based on
	public static var curSelected:Int = 0;
	public static var seenTween:Bool = false;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;

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
		optionShit = [
			'story_mode', 
			'freeplay', 
			'credits', 
			'options',
			'patch',
			'soundtest'
			];
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
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		WeekData.loadTheFirstEnabledMod();
		optionShit = [
			'story_mode', 
			'freeplay', 
			'credits', 
			'options',
			'patch',
			'soundtest'
			];
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("On the Main Menu", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		if (ClientPrefs.mouseControls) FlxG.mouse.visible = true;

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
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
		logo.frames = Paths.getSparrowAtlas('title/logoBumpin');
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

		bg.visible = true;
		logo.visible = true;
		if (!ClientPrefs.lowQuality) {
			bgScroll.visible = true;
			bgScroll2.visible = true;
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
			case 'freeplay':
				menuItem.x = 315;
				menuItem.y = 450;
			case 'credits':
				menuItem.x = 515;
				menuItem.y = 450;
			case 'options':
				menuItem.x = 715;
				menuItem.y = 450;
			case 'patch':
				menuItem.x = 915;
				menuItem.y = 450;
			case 'soundtest':
				menuItem.x = 0;
				menuItem.y = -30;
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

		var versionShit2:FlxText = new FlxText(12, FlxG.height - #if !html 64 #else 44 #end, 0, "Denpa Engine v" + denpaEngineVersion, 12);
		versionShit2.scrollFactor.set();
		versionShit2.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit2);
		var versionShit:FlxText = new FlxText(12, FlxG.height - #if !html 44 #else 24 #end, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		#if !html
		var prompt:FlxText = new FlxText(12, FlxG.height - 24, 0, "Press RESET to Clear Save Data", 12);
		prompt.scrollFactor.set();
		prompt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(prompt);
		#end

		versionShit.visible = true;
		versionShit2.visible = true;	

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

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

	var selectedSomethin:Bool = false;
	var canClick:Bool = true;
	var usingMouse:Bool = ClientPrefs.mouseControls;

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

		if (usingMouse) {
			menuItems.forEach(function(spr:FlxSprite)
				{
					if(!FlxG.mouse.overlaps(spr))
						spr.animation.play('idle');
						spr.updateHitbox();
			
					if (FlxG.mouse.overlaps(spr))
					{
						if(canClick)
						{
							//curSelected = spr.ID;
							//FlxG.sound.play(Paths.sound('scrollMenu'));
							changeItem(spr.ID, true);
						}
							
						if(FlxG.mouse.pressed && canClick)
						{
							doTheThingHouston();
						}
					}
			
					spr.updateHitbox();
				});
		}

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

			if (controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls))
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				doTheThingHouston();
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
			#if !html
			if (controls.RESET)
			{
				FlxG.save.erase();
				ClientPrefs.loadPrefs();
				ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
				trace ('erasing data');
				FlxG.sound.play(Paths.sound('invalidJSON'));
				var funnyText = new FlxText(12, FlxG.height - 24, 0, "Data Erased!");
				funnyText.scrollFactor.set();
				funnyText.screenCenter();
				funnyText.x = FlxG.width/2 - 250;
				funnyText.y = FlxG.height/2 - 64;
				funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(funnyText);
				FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
					onComplete: function(tween:FlxTween)
					{
						funnyText.destroy();
					}
				});
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			
		});
	}

	function doTheThingHouston() {
		if (optionShit[curSelected] == 'donate')
			{
				CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
			}
			else
			{
				selectedSomethin = true;
				canClick = false;
				FlxG.mouse.visible = false;
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
									MusicBeatState.switchState(new FreeplaySectionState());
								case 'credits':
									MusicBeatState.switchState(new CreditsState());
								case 'options':
									LoadingState.loadAndSwitchState(new options.OptionsState());
								case 'patch':
									MusicBeatState.switchState(new PatchState());
								case 'soundtest':
									MusicBeatState.switchState(new SoundTestState());
							}
						});
					}
				});
			}
	}

	function changeItem(huh:Int = 0, ?mouseInput:Bool = null)
	{
		if (mouseInput == null) {
			curSelected += huh;
		} else {
			curSelected = huh;
		}

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
		if(logo != null) 
			logo.animation.play('bump', true);
		//trace('beat hit' + curBeat);
	}
}
