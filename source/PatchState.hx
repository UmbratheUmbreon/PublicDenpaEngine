package;

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
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.utils.Assets;

using StringTools;

/**
* State used to give full explanations of updates.
*/
class PatchState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var patchStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;
	var gradient:FlxSprite;
	var nameText:FlxText;
	var roleText:FlxText;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var bgScrollColorTween:FlxTween;
	var bgScroll2ColorTween:FlxTween;
	var gradientColorTween:FlxTween;
	var descBox:FlxSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		Paths.clearUnusedMemory();
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Patch Notes", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

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

		gradient = new FlxSprite().loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		add(gradient);
		gradient.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		#if MODS_ALLOWED
		var path:String = 'modsList.txt';
		if(FileSystem.exists(path))
		{
			var leMods:Array<String> = CoolUtil.coolTextFile(path);
			for (i in 0...leMods.length)
			{
				if(leMods.length > 1 && leMods[0].length > 0) {
					var modSplit:Array<String> = leMods[i].split('|');
					if(!Paths.ignoreModFolders.contains(modSplit[0].toLowerCase()) && !modsAdded.contains(modSplit[0]))
					{
						if(modSplit[1] == '1')
							pushModPatchToList(modSplit[0]);
						else
							modsAdded.push(modSplit[0]);
					}
				}
			}
		}

		var arrayOfFolders:Array<String> = Paths.getModDirectories();
		arrayOfFolders.push('');
		for (folder in arrayOfFolders)
		{
			pushModPatchToList(folder);
		}
		#end

		var pisspoop:Array<Array<String>> = [ //Ver - Icon name - Update Ver - Update Name - Description - Link - BG Color
			['Denpa Engine'],
			['0.7.0b',		'iidol',		"0.7.0b", "", 'Press ' + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'))) + ' or ' + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'), 1)) + ' to view.',							'https://docs.google.com/document/d/1FYPeiyaO2OSlejfHyqvg8VlNH2PbRCJ2PTIDohbZmUI/edit?usp=sharing',	'6FD2D2'],
			['0.7.0',		'iidol',		"0.7.0", "", 'Press ' + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'))) + ' or ' + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'), 1)) + ' to view.',							'https://docs.google.com/document/d/1FYPeiyaO2OSlejfHyqvg8VlNH2PbRCJ2PTIDohbZmUI/edit?usp=sharing',	'6FD2D2'],
			['0.5.1',		'waidol',		"0.5.1", "", 'A-Freeplay Sections, A-Dynamic Icons, A-Volume Controllers per Song, A-Option to Toggle Old Score Popup, I-Modcharts, I-Chart Editor, I-Song Credits, I-Kade Engine Score Display, I-CrossFade Auto Colouring, I-Stage Layering, F-Duet Notes, F-Minor GF Section Icon Bug, O-Stepper Code In Chara Editor, R-Deprecated Pulse Shader Code, R-Winning Icons Option, RFV-0.5.1',			'',	'3B4CB7'],
			['0.5.0d',		'waidol',		"0.5.0d", "", 'A-NPS, A-Bopeebo and Fresh Insanity Charts, U-Credits, I-Modcharts, I-Kade Score Display, I-Title Screen, I-Chart Editor Position Display, F-Third Strum Bug, F-Multikey Input Bug, F-Crash Handler Not Showing Up, F-Null Bitmap Reference in Offset Editor, F-Invalid JSON Detector, F-Title Screen Sync, F-Invalid Song Detector, F-Incorrect BPMs When Changing Menus, RFV-0.5.0d',	'',	'3B4CB7'],
			['0.5.0c',		'waidol',		"0.5.0c", "", 'A-FNF+ Score Display, A-FNM Score Dispaly, A-Poison Modifier, A-Autopause Option, A-Gradient Time Bar, F-Main Menu Mouse Controls, F-Tankman Bugs, F-Healthbars, O-Healthbars, RFV-0.5.0c',							'wait till next update',	'3B4CB7'],
			['0.5.0',		'waidol',		"0.5.0", "", 'A-Week 7, A-Mouse Controls to Menus, A-That Psych Crash Handler, A-Hscript (By _jorge), A-Stretch Icon Bop, A-Psych Philly Glow, A-Animation for Singing with the Spacebar, A-Scare Options, A-MS Timing Indicator, A-Texture Packer XML Support, A-Anti Crash for Invalid JSONs (by Toadette), A-Option to Toggle Flinching Icons, F-Flinching Icons, O-Score Texts, O-Health Icons, I-Static CrossFade, I-Camera Movement, I-Quartiz, I-Icon Animations, R-Blammed Lights, R-Gospel X, R-Unused Assets, RFV-0.5.0',	 '',	'3B4CB7'],
			['0.4.0e',		'eidol',		"0.4.0e", "", 'A-Time Text Boppin, A-Cutscene Options, A-Replay Cutscene Option in Pause Menu, A-Bar-less Time Bar Options, A-Pause Options, F-Song Card Appearing During Cutscenes, F-Healthbar Offsets, F-Positionings for Score Displays, F-Pixel GF Being Flipped, RFV-0.4.0e',	'',	'998844'],
			['0.4.0d',		'eidol',		"0.4.0d", "", 'A-Increased Max and Min Zoom on Chara Editor, A-Increased Scale Max, F-Lag on Chart Editor, F-Tints, F-Chara Editor BPM, R-Skunked Pause Options, RFV-0.4.0d',	'',	'998844'],
			['0.4.0c',		'eidol',		"0.4.0c", "", 'A-Options to Customize Character Trail, A-Option to Disable Combo Pop-up, A-Cooler Looking BGScroll in Pause Menu, A-Tints, RFV-0.4.0c',	 '',	'998844'],
			['0.4.0b',		'eidol',		"0.4.0b", "", 'A-Sum Graphics, A-Fullscreen Toggle, A-Splash Screen, A-UI Skins, A-The Rest of Sound Test, A-Healthbar Offsets, A-Reset Settings Hotkey, A-New Events to Mess with the Cameras, A-Colour Tweens to Chart Editor, F-Countdown Sprite Sizings, F-Chara Editor Get Dom Colour, F-MOST setDefaultDrawTarget Warnings, F-Sound Test not Keeping Track of Yer Song and Album, RFV-0.4.0b', '',	'998844'],
			['0.4.0',		'eidol',		"0.4.0", "", 'Im not writing this, RFV-0.4.0',	'',	'998844'],
			['0.3.1',		'fidol',		"0.3.1", "", 'A-Beatmap (Ehhh...), A-Crit Mechanic, A-Song Credits Card, A-Rating Saving/Display in Freeplay, A-Cool First Time Opening Main Menu Intro, U-GF and Senpai Icons, U-Character Editor to Have Nearly Identical Stage Replications, U-Made Sarv Score Display More Accurate, U-Ratings Display, U-Max Combo to 999,999, F-Lacking Pixel Perfect and WTF Graphics, F-Combo Graphics, U-Sick Graphic, F-BPM on Title Screen, F-Title Screen Logo Placement, F-GF Not Crying When You MISS a Note, F-Botplay not Always Getting Perfects, R-Leftover Easy Difficulty Stuff, RFV-0.3.1', '',	'B60000'],
			['0.3.0b',		'almighty',		"0.3.0b", "", 'A-Music to The Editors, A-Stage Changer to Character Editor, O-More Stuff, F-Health Icon Cut Offs, U-Discord RPC, U-Sarvente Lucifer, U-Character Editor Layout, U-Chart Editor Layout, RFV-0.3.0b',	'',	'FFFFFF'],
			['0.3.0',		'almighty',		"0.3.0", "", 'A-Camera Movement on Note Hit, A-Cool Score Display Options, A-BM Showcase Song/Stage, A-Perfect and WTF Ratings, A-CrossFade Settings, A-Ratings Display, C-Ratings, F-CROSSFADE(FRFR)!!!, F-Pixel Notes, O-A Lot of Stuff, RFV-0.3.0',							'https://github.com/UmbratheUmbreon/DenpaFunkinSource-Denpa-Engine/commit/74167d07955d4e59fb3217e62bd6d8fc0556ed9b',	'FFFFFF'],
			['0.2.4b',		'amogus',		"0.2.4b", "", 'A-Dual/Triple Colour HP Bars, A-Angle Snap Icon Animation, R-Aggro Swing, F-Crossfade stuff, RFV-0.2.4b',							'https://github.com/UmbratheUmbreon/DenpaFunkinSource-Denpa-Engine/commit/379e7f8ff93db9ba46f9402b71dfc19c3bf9f72d',	'FFFFFF'],
			['0.2.4',		'amogus',		"0.2.4", "", 'A-A Boatload Of Options To Toggle, F-A Lot Of Multikey Related Errors, RFV-0.2.4',							'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/ecd982babbd4ab394426a22c67f58d8cb06fbcac',	'FFFFFF'],
			['0.2.3c',		'life',			"0.2.3c", "", 'A-Insanity Difficulty, A-Multikey Support, C-Botplay Text To "AUTO", U-Patch Note Menu To Be More Descriptive, F-Not Being Able To Enter In Text Boxes, RFV-0.2.3c',							'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/57eb62df518a79c051aabd8a6094bde39348a170',	'F499C2'],
			['0.2.3b',		'life',			"0.2.3b", "", 'U-Credits, U-Secret Song Functionality, RFV-0.2.3b',							'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/7a21260bca58f3a4f47cf23c2f88eaf1f695baa3',	'F499C2'],
			['0.2.3',		'life',			"0.2.3", "", 'A-This Menu, A-BG Scroll In Master Editor, F-BG Scroll Lag, F-BG Scroll Size, RFV-0.2.3',							'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/3ab55597186e0be2c002b08bbd10154237fb3d42',	'F499C2'],
			['0.2.2',		'stamina',		"0.2.2", "", 'U-Credits, U-Disruption, U-CF Color, F-CrossFade, A-CrossFade Notes, A-Icon Flinch, C-OutdatedState, RFV-0.2.2',						'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/1305277c8426c1cb43606fd183cb43413f3d854b',		'8DC642'],
			['0.2.1c',		'speed',		"0.2.1c", "", 'A-Random Mode, F-SecVoices in Chart, A-Chart Effects, M-FreePlay Scroll not C Colors, M-Options Menu Scroll, RFV-0.2.1c',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/a85c17c48328bc9ad619231a172ea0353537109d',			'FFDD66'],
			['0.2.1b',		'speed',		"0.2.1b", "", 'F-FreePlay Scroll, RFV-0.2.1b',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/07e45c5ae469462f344511ca5e5bb26afcd22b5b',			'FFDD66'],
			['0.2.1',		'speed',		"0.2.1", "", 'N-Combo Graphics, Cool Menu Stuff, RFV-0.2.1',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/07057074db7c93662eaf992cd2f224a4aec1f672',			'FFDD66'],
			['0.2.0c',		'power',		"0.2.0c", "", 'A-Character Select Song, A-Title Song, C-Title BPM, RFV-0.2.0c',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/583309cca153ab9fb55e60f5e0ce4cda58b1a3ab',			'DF6C21'],
			['0.2.0b',		'power',		"0.2.0b", "", 'U-Credits, M-RPC More Descriptive, RFV-0.2.0b',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/97101b422b7512d51cf38802a8167aed858ddff4',			'DF6C21'],
			['0.2.0',		'power',		"0.2.0", "", 'A-Crossfade, RFV-0.2.0',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/54e3f231b38e59a6c1537559cc7036de9491c1ed',			'DF6C21'],
			['0.1.3b',		'ap',			"0.1.3b", "", 'A-CrossFade (Broken), A-CrossFade Test Song, RFV-0.1.3b',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/2b436771dceaa00205d4ac2f563bfb401766e89d',			'0088A0'],
			['0.1.3',		'ap',			"0.1.3", "", 'R-Test Code, A-Modapps Disruption, U-MM Graphics/Layout, F-Credits Text, RFV-0.1.3',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/61273847c77579d227a2d6cbc35a9e28e56aee70',			'0088A0'],
			['0.1.2',		'torb',			"0.1.2", "", 'A-Test Song For SecVoices, A-Credits Text, A-SecVoices, RFV-0.1.2',					'https://github.com/UmbratheUmbreon/DenpaFunkinSource/commit/4cb67777c939f33f261ff715eeaec2d75931d1dc',			'99AA0D']
		];
		
		for(i in pisspoop){
			patchStuff.push(i);
		}
	
		for (i in 0...patchStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, patchStuff[i][0], !isSelectable, false);
			optionText.isMenuItem = true;
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if(isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			//optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(isSelectable) {
				if(patchStuff[i][7] != null)
				{
					Paths.currentModDirectory = patchStuff[i][7];
				}

				var icon:AttachedSprite = new AttachedSprite('patch/' + patchStuff[i][1]);
				icon.xAdd = -icon.width - 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Paths.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}
		
		descBox = new FlxSprite(-300, 0);
		descBox.makeGraphic(Std.int(FlxG.width/2 - 70), FlxG.height, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		nameText = new FlxText(-300, 25, 570, "", 32);
		nameText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		nameText.scrollFactor.set();
		add(nameText);

		roleText = new FlxText(-300, 100, 570, "", 24);
		roleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		roleText.scrollFactor.set();
		add(roleText);

		descText = new FlxText(-300, 200, 570, "", 16);
		descText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		add(descText);

		bg.color = getCurrentBGColor();
		if (!ClientPrefs.lowQuality) {
			bgScroll.color = getCurrentBGColor();
			bgScroll2.color = getCurrentBGColor();
		}
		gradient.color = getCurrentBGColor();
		intendedColor = bg.color;
		changeSelection();
		super.create();
	}

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();

		if(!quitting)
		{
			if(patchStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = controls.UI_UP_P;
				var downP = controls.UI_DOWN_P;

				if (upP)
				{
					changeSelection(-1 * shiftMult);
					holdTime = 0;
				}
				if (downP)
				{
					changeSelection(1 * shiftMult);
					holdTime = 0;
				}

				if(FlxG.mouse.wheel != 0 && ClientPrefs.mouseControls)
					{
						changeSelection(-shiftMult * FlxG.mouse.wheel);
					}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
			}

			if(controls.ACCEPT || (FlxG.mouse.justPressed && ClientPrefs.mouseControls)) {
				if (patchStuff[curSelected][5] != null && patchStuff[curSelected][5].length > 0) {
					CoolUtil.browserLoad(patchStuff[curSelected][5]);
				}
			}
			if (controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls))
			{
				if(colorTween != null) {
					colorTween.cancel();
				}
				if(bgScrollColorTween != null) {
					bgScrollColorTween.cancel();
				}
				if(bgScroll2ColorTween != null) {
					bgScroll2ColorTween.cancel();
				}
				if(gradientColorTween != null) {
					gradientColorTween.cancel();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				quitting = true;
			}
		}
		
		for (item in grpOptions.members)
		{
			if(!item.isBold)
			{
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 12, 0, 1);
				if(item.targetY == 0)
				{
					item.x = FlxMath.lerp(item.x, (FlxG.width - item.width) - 115, lerpVal);
					item.forceX = item.x;
				}
				else
				{
					item.x = FlxMath.lerp(item.x, (FlxG.width - item.width) - 15, lerpVal);
					item.forceX = item.x;
				}
			} else {
				item.x = FlxG.width - item.width - 25;
				item.forceX = item.x;
			}
		}
		super.update(elapsed);
	}

	var nameTextTwn:FlxTween = null;
	var roleTextTwn:FlxTween = null;
	var descTextTwn:FlxTween = null;
	var boxTween:FlxTween = null;
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = patchStuff.length - 1;
			if (curSelected >= patchStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var newColor:Int =  getCurrentBGColor();
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			if(bgScrollColorTween != null) {
				bgScrollColorTween.cancel();
			}
			if(bgScroll2ColorTween != null) {
				bgScroll2ColorTween.cancel();
			}
			if(gradientColorTween != null) {
				gradientColorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
			bgScrollColorTween = FlxTween.color(bgScroll, 1, bgScroll.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					bgScrollColorTween = null;
				}
			});
			bgScrollColorTween = FlxTween.color(bgScroll2, 1, bgScroll2.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					bgScrollColorTween = null;
				}
			});
			gradientColorTween = FlxTween.color(gradient, 1, gradient.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					gradientColorTween = null;
				}
			});
		}

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}

		if(nameTextTwn != null) nameTextTwn.cancel();
		nameText.text = patchStuff[curSelected][2];
		nameText.x = -200;
		nameTextTwn = FlxTween.tween(nameText, {x : 0}, 0.7, {ease: FlxEase.expoOut});

		if(roleTextTwn != null) roleTextTwn.cancel();
		roleText.text = patchStuff[curSelected][3];
		roleText.x = -200;
		roleTextTwn = FlxTween.tween(roleText, {x : 0}, 0.7, {ease: FlxEase.expoOut});

		if(descTextTwn != null) descTextTwn.cancel();
		descText.text = patchStuff[curSelected][4];
		descText.x = -200;
		descTextTwn = FlxTween.tween(descText, {x : 0}, 0.7, {ease: FlxEase.expoOut});

		if(boxTween != null) boxTween.cancel();
		descBox.x = -200;
		boxTween = FlxTween.tween(descBox, {x: 0}, 0.7, {ease: FlxEase.expoOut});
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	function pushModPatchToList(folder:String)
	{
		if(modsAdded.contains(folder)) return;

		var patchFile:String = null;
		if(folder != null && folder.trim().length > 0) patchFile = Paths.mods(folder + '/data/patch.txt');
		else patchFile = Paths.mods('data/patch.txt');

		if (FileSystem.exists(patchFile))
		{
			var firstarray:Array<String> = File.getContent(patchFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 7) arr.push(folder);
				patchStuff.push(arr);
			}
			patchStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor() {
		var bgColor:String = patchStuff[curSelected][6];
		if(!bgColor.startsWith('0x')) {
			bgColor = '0xFF' + bgColor;
		}
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool {
		return patchStuff[num].length <= 1;
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		//trace('beat hit' + curBeat);
	}
}