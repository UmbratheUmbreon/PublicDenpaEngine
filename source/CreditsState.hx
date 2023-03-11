package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
* State to showcase the credits of the engine and or mod.
*/
class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	var lerpList:Array<Bool> = [];
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

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
	var customImage:FlxSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		#if desktop
		DiscordClient.changePresence("In the Spirit Shrine", null);
		#end

		persistentUpdate = true;
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite().loadGraphic(Paths.image('gradient'));
		add(gradient);
		gradient.screenCenter();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		customImage = new FlxSprite();

		//precache
		Paths.image("credits/gifs/panache");
		Paths.image("credits/gifs/pillow");
		Paths.image("credits/gifs/lolmoment");
		Paths.image("credits/gifs/tsan");
		Paths.image("credits/gifs/devilish");
		Paths.image("credits/gifs/de");
		Paths.image("credits/gifs/denpaserver");

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
							pushModCreditsToList(modSplit[0]);
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
			pushModCreditsToList(folder);
		}
		#end

		//? note to self: add having multiple links and having indicators for link domains in the bottom right
		creditsStuff = [ //Username - Icon name - Name - Role - Description - Link - BG Color
			["Denpa Team"],
			['BlueVapor1234',	'at',			"AT", 		"Main Programmer & Creator", 		"\"What am i doing with my life\"",																	'https://twitter.com/BlueVapor1234', 								'34343C'],
			['Toadette8394',	'toadette',		"Toadette", "Co Programmer", 					"\"Play All Star Funkin': VS Yoshikage Kira\"",														'https://twitter.com/Toadette8394',									'E2009B'],
			['YanniZ06',		'yanniz06',		"Yanni", 	"Based Programmer", 				"\"Never open psych dialoguebox.hx file and look into update function, worst mistake of my life\"",	'https://twitter.com/YanniZ06',										'5C89BF'],
			['ThriftySoles',	'thrift',		"Thrify", 	"Composer & Artist", 				"\"i spent 2 fuqin howas, fixing my qode, too, fakin, aowas\"",										'https://twitter.com/thriftysoles',									'FF0000'],
			['Kn1ghtNight',		'kn1ght',		"Kn1ght", 	"Programmer & Artist", 				"\"I want to physically murder the shit out of windows 11\"",										'https://twitter.com/FNCDCreator',									'FFFFFF'],
			['T-San',			'tsan',			"T-San", 	"Artist", 							"\"Always forgets about himself\"",																	'https://www.youtube.com/channel/UC86K4wrmW3YZ5xcOgZXTQPg',			'00CC33'],
			['_jorge',			'jorge',		"jorge", 	"Cross Fade Code, Hscript Support", "\"mmmmm pan ache\"",																				'https://twitter.com/TheGamingCat9?t=70BuQY6wOsbNrV2SVx-T8w&s=09',	'EFDE7D'],
			['Ziad',			'ziad',			"Ziad", 	"Multiplayer Support", 				"\"Children\"",																						'https://twitter.com/croneriel?t=70BuQY6wOsbNrV2SVx-T8w&s=09',		'NA'],
			['Shygee',			'shygee',		"Shygee", 	"Extra Programmer", 				"\"I love my girlfriend go follow her on everything @Ahirukukkiii\"",								'https://twitter.com/Shygeeofficial',								'C275F7'],
			[''],
			["Contributors"],
			['Tsuwukiz',		'tsuwukiz',		"Tsu", 			"Ex Main Artist", 							"\"should i make a baldi mod\"",									'https://twitter.com/tsuwuki666',	'715BD7'],
			['atpx8',			'atpx',			"atpx8", 		"Infinite Combo, Array Duplicate Removal", 	"\"<insert unfunny joke here that people will laugh at anyway>\"",	'',									'NA'],
			['Gizzy',			'gizzy',		"Gizzy",	 	"Title Music",								"\"Norman\"",														'',									'NA'],
			['Denpamoo',		'moo',			"Moo", 			"Main Menu Assets", 						"",																	'',									'63E7FF'],
			['Bethany Clone',	'beth',			"Beth", 		"Ex Programmer", 							"\"I left my oven on\"",											'',									'018B00'],
			['MythsList',		'mythslist',	"52", 			"GameBanana Game Manager", 					"\"put me in it\"",													'https://twitter.com/MythsList',	'29211F'],
			['MemeHoovy',		'memehoovy',	"MemeHoovy", 	"General Improvements",						"\"i am the storm that is approaching\"",							"https://twitter.com/meme_hoovy",	'E1E1E1'],
			['Raltyro',			'raltyro',		"Raltyro", 		"Sound Backend Fixes",						"",																	"https://twitter.com/raltyro",		'NA'],
			['lunar client',	'lunar',		"lunar", 		"Misc Memory Fixes",						"",																	"https://twitter.com/lunarcleint",	'NA'],
			[''],
			["Misc."],
			['EliteMasterEric', 'eric',			"Eric",			"Swag Programmer",				"Credited for: Runtime .frag/.vert shader code",								"https://twitter.com/EliteMasterEric", 'NA'],
			['kuroao_anomal',	'kuro',			"Kuro", 		"Sarv Engine Programmer", 		"Credited for: Crossfades Idea, Sarv Engine UI",														'https://twitter.com/kuroao_anomal?lang=en',												'NA'],
			['Rifxii',			'rifxii',		"Rifxii", 		"FNF+ Programmer & Artist", 	"Credited for: FNF+ UI, FNF+ Original Mechanics, 'Streetlight' Monster BG",						'https://gamebanana.com/members/1773116',													'NA'],
			['Kade Developer',	'kade',			"Kade", 		"Kade Engine Programmer",       "Credited for: Kade Engine UI",																	'https://twitter.com/kade0912?lang=en',														'64A250'],
			['srPEREZ',			'perez',		"Perez", 		"Vs Shaggy Programmer", 		"Credited for: Multikey Assets and Original Code",												'https://twitter.com/newsrperez?lang=en',													'FFAE00'],
			['Sky!',			'sky',			"Sky!", 		"D&B: Golden Apple Programmer", "Credited for: Swing Icon Bop, Orbit Original Code, and Disruption, and Disability Modcharts",	'https://twitter.com/grantarep?lang=en',													'NA'],
			['MoldyGH',			'moldygh',		"Moldy", 		"D&B Programmer", 				"Credited for: Cheating and Unfairness Modcharts",												'https://twitter.com/moldy_gh?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor',		'NA'],
			['Rei the Goat',	'rei',			"Rei", 			"Vs Cye Programmer",			"Credited for: Ghost and Random mode Original Code",											'https://www.youtube.com/c/ReitheGoat',														'NA'],
			['Rozebud',			'rozebud',		"Rozebud", 		"FPS+ Programmer", 				"Credited for: FPS+ UI",																		'https://twitter.com/helpme_thebigt?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor','NA'],
			['Shadow Mario',	'shadowmario',	"Shadow Mario", 'Psych Engine Programmer', 		"Credited for: Original Psych Engine code",														'https://twitter.com/Shadow_Mario_',														'444444'],
			[''],
			["FNF Crew"],
			['ninjamuffin99',	'ninjamuffin99',	"Ninjamuffin", 		"Programmer", 			"\"fuk it, im naming my iterable nests alphabetically starting from a instead of i\"",		'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',	'phantomarcade',	"PhantomArcade", 	"Animator & Artist", 	"\"Goku would rip his fucking skin off\"",													'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',		'evilsk8r',			"Evilsk8r", 		"Artist", 				"\"my fishsona\"",																			'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',		'kawaisprite',		"Kawaisprite", 		"Composer", 			"\"staying offline for 2 months made my dick huge.\"",										'https://twitter.com/kawaisprite',		'D2D2D2'],
			[''],
			["Links"],
			['D.E. Discord',		'discord',	"Denpa Engine Discord", "Press " + InputFormatter.getKeyName(ClientPrefs.keyBinds.get('accept')[0]) + ' or ' + InputFormatter.getKeyName(ClientPrefs.keyBinds.get('accept')[1]) + " to Join", 	"What you will find in this server:\nOther Fans\nSupport\nTeasers\nRelease Notifications\nPolls\nScripts\nNews",					'https://discord.gg/pUX2ZMm4Qt', 	'5C89BF'],
			['T.D.M. Discord',		'discord',	"Denpa Men Discord", 	"Press " + InputFormatter.getKeyName(ClientPrefs.keyBinds.get('accept')[0]) + ' or ' + InputFormatter.getKeyName(ClientPrefs.keyBinds.get('accept')[1]) + " to Join", 	"What you will find in this server:\nDenpa Men Fans\nPolls\nDenpa Men Content\nDenpa Men QR Codes\nDenpa Men Fan Creations",		'https://discord.gg/thedenpamen',	'5C89BF']
		];
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
			optionText.screenCenter(X);
			optionText.yAdd -= 70;
			if(isSelectable) {
				optionText.x -= 70;
			}
			optionText.forceX = optionText.x;
			optionText.targetY = i;
			lerpList.push(true);
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][7] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][7];
				}

				final name = (Paths.fileExists('images/credits/${creditsStuff[i][1]}.png', IMAGE) ? creditsStuff[i][1] : 'placeholder');
				if (name == 'placeholder') creditsStuff[i][6] = 'FFFFFF';
				var icon:AttachedSprite = new AttachedSprite('credits/$name');
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				iconArray.push(icon);
				add(icon);
				icon.copyState = true;
				Paths.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}
		
		descBox = new FlxSprite(FlxG.width, 0);
		descBox.makeGraphic(Std.int(FlxG.width/2 - 70), FlxG.height, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		nameText = new FlxText(FlxG.width, 25, 570, "", 32);
		nameText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		nameText.scrollFactor.set();
		add(nameText);

		roleText = new FlxText(FlxG.width, 100, 570, "", 24);
		roleText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER);
		roleText.scrollFactor.set();
		add(roleText);

		descText = new FlxText(FlxG.width, 200, 570, "", 16);
		descText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		descText.scrollFactor.set();
		add(descText);

		bg.color = getCurrentBGColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
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

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

		//make sure frame 13 doesnt play if flashing is off because it could potentially be flashy??? idk if this makes a huge difference
		if(!ClientPrefs.settings.get("flashing") && curImage == "pillow" && customImage.animation.curAnim.curFrame < 11) customImage.animation.curAnim.restart();

		if(!quitting)
		{
			if(creditsStuff.length > 1)
			{
				var shiftMult:Int = 1;
				if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				var upP = control('ui_up_p');
				var downP = control('ui_down_p');

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

				if(FlxG.mouse.wheel != 0)
					{
						changeSelection(-shiftMult * FlxG.mouse.wheel);
					}

				if(control('ui_down') || control('ui_up'))
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (control('ui_up') ? -shiftMult : shiftMult));
					}
				}
			}

			if(control('accept')) {
				if (creditsStuff[curSelected][5] != null && creditsStuff[curSelected][5].length > 0) {
					CoolUtil.browserLoad(creditsStuff[curSelected][5]);
				}
			}
			if (control('back'))
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
		
		final lerpVal:Float = CoolUtil.clamp(elapsed * 12, 0, 1);
		for (i=>item in grpOptions.members)
		{
			item.visible = item.active = lerpList[i] = true;
			if (Math.abs(item.targetY) > 7 && !(curSelected == 1 || curSelected == grpOptions.length - 1))
				item.visible = item.active = lerpList[i] = false;

			if(!item.isBold)
			{
				@:privateAccess {
					if (lerpList[i]) {
						item.y = FlxMath.lerp(item.y, (item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd, lerpVal);
						if(item.targetY == 0)
							item.x = FlxMath.lerp(item.x, 100 + -40 * Math.abs(item.targetY), lerpVal);
						else
							item.x = FlxMath.lerp(item.x, 15, lerpVal);
					} else {
						item.y = ((item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd);
						if(item.targetY == 0)
							item.x = (100 + -40 * Math.abs(item.targetY));
						else
							item.x = 15;
					}
				}
			} else {
				@:privateAccess {
					if (lerpList[i])
						item.y = FlxMath.lerp(item.y, (item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd, lerpVal);
					else
						item.y = ((item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd);
				}
				item.x = 25;
			}
		}

		for (icon in iconArray) {
			icon.active = true;
			icon.visible = true;
		}

		customImage.x = descBox.x + (descBox.width / 2) - (customImage.width / 2);
		customImage.y = descText.y + (descBox.height / 2) - (customImage.height / 2) - 150;
		super.update(elapsed);
	}

	var nameTextTwn:FlxTween = null;
	var roleTextTwn:FlxTween = null;
	var descTextTwn:FlxTween = null;
	var boxTween:FlxTween = null;
	var curImage:String = "NONE";
	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
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
			if (!ClientPrefs.settings.get("lowQuality")) {
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
			}
			gradientColorTween = FlxTween.color(gradient, 1, gradient.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					gradientColorTween = null;
				}
			});
		}

		//dont know if this will be planned to be softcoded but yea
		switch(creditsStuff[curSelected][0]) {
			case 'BlueVapor1234':
				customImage.frames = Paths.getSparrowAtlas("credits/gifs/lolmoment");
				customImage.animation.addByPrefix("idle", "lol", ClientPrefs.settings.get("flashing") ? 20 : 14, true);
				customImage.animation.play("idle");
				customImage.scale.set(1,1);
				customImage.offset.y = -45;
				curImage = "lolmoment";
				add(customImage);
			case 'T-San':
				customImage.frames = Paths.getSparrowAtlas("credits/gifs/tsan");
				customImage.animation.addByPrefix("idle", "T-San", 24, true);
				customImage.animation.play("idle");
				customImage.scale.set(1,1);
				customImage.offset.y = -25;
				curImage = "tsan";
				add(customImage);
			case '_jorge':
				customImage.frames = Paths.getSparrowAtlas("credits/gifs/panache");
				customImage.animation.addByPrefix("idle", "mm", 12, false);
				customImage.scale.set(2,2);
				curImage = "pan ache";
				add(customImage);
			case 'YanniZ06':
				customImage.frames = Paths.getSparrowAtlas('credits/gifs/pillow');
				customImage.animation.addByPrefix("idle", "explode", ClientPrefs.settings.get("flashing") ? 12 : 8, true);
				customImage.animation.play("idle");
				customImage.setGraphicSize(Std.int(customImage.width));
				customImage.scale.set(0.845,0.845);
				customImage.offset.y = -90;
				curImage = "pillow";
				add(customImage);
			case 'Ziad':
				customImage.frames = Paths.getSparrowAtlas("credits/gifs/devilish");
				customImage.animation.addByPrefix("idle", "devilish", 24, true);
				customImage.animation.play("idle");
				customImage.scale.set(1.6, 1.6);
				customImage.offset.y = -90;
				curImage = "devilish";
				add(customImage);
			case 'D.E. Discord':
				customImage.loadGraphic(Paths.image('credits/gifs/de'));
				customImage.scale.set(2,2);
				customImage.offset.y = -90;
				curImage = "de";
				add(customImage);
			case 'T.D.M. Discord':
				customImage.frames = Paths.getSparrowAtlas('credits/gifs/denpaserver');
				customImage.animation.addByPrefix("idle", "spin", 5, true);
				customImage.animation.play("idle");
				customImage.scale.set(1, 1);
				customImage.offset.y = -90;
				curImage = "spin";
				add(customImage);
			default:
				remove(customImage);
				curImage = "NONE";
				customImage = new FlxSprite();
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
		nameText.text = creditsStuff[curSelected][2];
		nameText.x = FlxG.width-400;
		nameTextTwn = FlxTween.tween(nameText, {x : FlxG.width - descBox.width}, 0.7, {ease: FlxEase.expoOut});

		if(roleTextTwn != null) roleTextTwn.cancel();
		roleText.text = creditsStuff[curSelected][3];
		roleText.x = FlxG.width-400;
		roleTextTwn = FlxTween.tween(roleText, {x : FlxG.width - descBox.width}, 0.7, {ease: FlxEase.expoOut});

		if(descTextTwn != null) descTextTwn.cancel();
		descText.text = creditsStuff[curSelected][4];
		descText.x = FlxG.width-400;
		descTextTwn = FlxTween.tween(descText, {x : FlxG.width - descBox.width}, 0.7, {ease: FlxEase.expoOut});

		if(boxTween != null) boxTween.cancel();
		descBox.x = FlxG.width-400;
		boxTween = FlxTween.tween(descBox, {x: FlxG.width - descBox.width}, 0.7, {ease: FlxEase.expoOut});
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	function pushModCreditsToList(folder:String)
	{
		if(modsAdded.contains(folder)) return;

		var creditsFile:String = null;
		if(folder != null && folder.trim().length > 0) creditsFile = Paths.mods(folder + '/data/credits.txt');
		else creditsFile = Paths.mods('data/credits.txt');

		if (FileSystem.exists(creditsFile))
		{
			var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
			for(i in firstarray)
			{
				var arr:Array<String> = i.replace('\\n', '\n').split("::");
				if(arr.length >= 7) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor() {
		var bgColor:String = creditsStuff[curSelected][6];
		if(!bgColor.startsWith('0x')) {
			bgColor = '0xFF' + bgColor;
		}
		return Std.parseInt(bgColor);
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}

	override function beatHit() {
		super.beatHit();

		if (customImage.animation.exists("idle") && curImage == 'pan ache')
			customImage.animation.play("idle", true);

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		bg.offset.set();
	}
}
