package;

#if desktop
import Discord.DiscordClient;
#end
import editors.MasterEditorMenu;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxescript.Hscript;
import lime.app.Application;

typedef MainMenuOffsets =
{
	offsets:Array<Array<Float>>,
}

/**
* State containing connections to other states, serving as a hub for the menus.
*/
class MainMenuState extends MusicBeatState
{
	public static var instance:MainMenuState;
	
	public static var curSelected:Int = 0;
	public static var seenTween:Bool = false;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;

	var curDifficulty:Int = -1;
	
	final optionShit:Array<String> = ['story_mode', 'freeplay', 'credits', 'options', 'patch', 'soundtest'];
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var logo:FlxSprite;
	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;

	public var hscript:Hscript;

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		DiscordClient.changePresence("On the Main Menu", null);
		#end
		
		debugKeys = ClientPrefs.keyBinds.get('debug_1').copy();

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		instance = this;

		#if HSCRIPT_ALLOWED
		hscript = new Hscript(Paths.hscript('scripts/menus/MainMenu'));
		#end

		var JSON:MainMenuOffsets = Json.parse(Paths.getTextFromFile('data/mainmenu/offsets.json'));

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.screenCenter();
		add(bg);

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			bgScroll.scrollFactor.set(0,0);
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			bgScroll2.scrollFactor.set(0,0);
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		logo = new FlxSprite(270, FlxG.height/2);
		logo.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logo.animation.play('bump');
		logo.scrollFactor.set(0, 0);
		logo.setGraphicSize(Std.int(0.75));
		logo.updateHitbox();
		logo.alpha = 0;
		if(seenTween) {
			logo.y = 0;
			logo.alpha = 1;
		}
		add(logo);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.alpha = 0;
			if(seenTween) menuItem.alpha = 1;
			menuItem.ID = i;
			switch (optionShit[i])
			{case 'story_mode':
				menuItem.x = JSON.offsets[0][0];
				menuItem.y = JSON.offsets[0][1];
			case 'freeplay':
				menuItem.x = JSON.offsets[1][0];
				menuItem.y = JSON.offsets[1][1];
			case 'credits':
				menuItem.x = JSON.offsets[2][0];
				menuItem.y = JSON.offsets[2][1];
			case 'options':
				menuItem.x = JSON.offsets[3][0];
				menuItem.y = JSON.offsets[3][1];
			case 'patch':
				menuItem.x = JSON.offsets[4][0];
				menuItem.y = JSON.offsets[4][1];
			case 'soundtest':
				menuItem.x = JSON.offsets[5][0];
				menuItem.y = JSON.offsets[5][1];
			}
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, 0);
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit2:FlxText = new FlxText(6, FlxG.height - #if !html5 64 #else 44 #end, 0, Main.denpaEngineVersion.formatted, 12);
		versionShit2.scrollFactor.set();
		versionShit2.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit2.active = false;
		add(versionShit2);
		var versionShit:FlxText = new FlxText(6, FlxG.height - #if !html5 44 #else 24 #end, 0, 'Friday Night Funkin${"'"} v${Application.current.meta.get('version')}', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.active = false;
		add(versionShit);
		#if !html5
		var prompt:FlxText = new FlxText(6, FlxG.height - 24, 0, "Press RESET to Clear Save Data", 12);
		prompt.scrollFactor.set();
		prompt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		prompt.active = false;
		add(prompt);
		#end

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

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		hscript.call("onCreatePost", []);
		
		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		hscript.call('onUpdate', [elapsed]);

		if (FlxG.sound.music != null) {
			if (FlxG.sound.music.volume < 0.8)
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
	
			if (FlxG.sound.music != null)
				Conductor.songPosition = FlxG.sound.music.time;
		}

		var lerpVal:Float = CoolUtil.clamp(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

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
				doTheThingHouston();
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
			#if !html5
			if (controls.RESET)
			{
				FlxG.mouse.visible = true;
				openSubState(new Prompt('This will clear all save data.\n\nProceed?', 0, () -> {
					FlxG.save.erase();
					ClientPrefs.loadPrefs();
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					trace ('erasing data');
					FlxG.sound.play(Paths.sound('invalidJSON'));
					var funnyText = new FlxText(12, FlxG.height - 24, 0, "Data Erased!");
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
					FlxG.mouse.visible = false;
				}, () -> FlxG.mouse.visible = false));
			}
			#end
		}

		hscript.call("onUpdatePost", [elapsed]);

		super.update(elapsed);
	}

	function doTheThingHouston()
	{
		hscript.call('onSelect', []);

		if (optionShit[curSelected] == 'donate')
		{
			CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
		}
		else
		{
			selectedSomethin = true;
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('confirmMenu'));

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
						switch (optionShit[curSelected])
						{
							case 'story_mode': MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay': MusicBeatState.switchState(new FreeplayState());
							case 'credits': MusicBeatState.switchState(new CreditsState());
							case 'options': MusicBeatState.switchState(new options.OptionsState());
							case 'patch': MusicBeatState.switchState(new PatchState());
							case 'soundtest': MusicBeatState.switchState(new SoundTestState());
						}
					});
				}
			});
		}
	}

	function changeItem(huh:Int = 0)
	{
		hscript.call('onChangeItem', [huh]);

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

		hscript.call('onBeatHit', [curBeat]);

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		bg.offset.set();
		if(logo != null)  logo.animation.play('bump', true);
	}

	override function destroy(){
		super.destroy();
		instance = null;
	}
}