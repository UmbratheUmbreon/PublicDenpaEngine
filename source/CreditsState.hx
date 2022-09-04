package;

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
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;
	var gradient:FlxSprite;
	var descText:FlxText;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var bgScrollColorTween:FlxTween;
	var bgScroll2ColorTween:FlxTween;
	var gradientColorTween:FlxTween;
	var descBox:AttachedSprite;

	var offsetThing:Float = -75;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Spirit Shrine", null);
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

		var pisspoop:Array<Array<String>> = [ //Name - Icon name - Description - Link - BG Color
			["Denpa Engine Contributors"],
			['BlueVapor1234',		'at',				"Main Programmer of Denpa Engine",							'https://twitter.com/BlueVapor1234',	'34343C'],
			['Toadette8394',		'toadette',			"Extra Programmer of Denpa Engine",							'https://twitter.com/Toadette8394',		'A31161'],
			['ThriftySoles',		'thrift',			"Ideas Provider and Misc. Music/Assets Maker of Denpa Engine",'https://twitter.com/thriftysoles',	'335552'],
			['_Jorge',				'jorge',			"Cross Fade Code, Hscript Support for Denpa Engine",		'NON EXISTENT',							'EFDE7D'],
			['DanyG7',				'dany',				"Credits Icons Maker",										'https://twitter.com/DanyTheGamer7',	'1CE8FF'],
			['Megaverse',			'discord',			"Title Music for the Engine and Denpa Funkin'",				'NON EXISTENT',							'5C89BF'],
			['Adrian',				'adrian',			"Character Select Music for Denpa Engine",					'NON EXISTENT',							'6BBE30'],
			['Bethany Clone',		'egg',				"Extra Programmer and Advisor of Denpa Engine",				'NON EXISTENT',							'018B00'],
			['Electrophyll II',		'te',				"Extra Programmer and Ideas Provider of Denpa Engine",		'NON EXISTENT',							'EFE469'],
			['Beterperter',			'sneed',			"Composer for Denpa Engine",								'https://twitter.com/beterperter',		'000033'],
			['Box',					'box',				"Extra Programmer and Optimizer of Denpa Engine",			'NON EXISTENT',							'C09560'],
			['Ninteytwo',			'92',				"Ideas Provider for Denpa Engine",							'https://twitter.com/ninteytwo21',		'FFFFFF'],
			['Denpa Engine Discord','discord',			"Press Enter to Join",										'https://discord.gg/pUX2ZMm4Qt',		'5C89BF'],
			[''],
			["Misc. Credits"],
			['kuroao_anomal',		'discord',			"Sarvente Engine Programmer",								'https://twitter.com/kuroao_anomal?lang=en','5C89BF'],
			['Kade Developer',		'kade',				"Kade Engine Programmer",									'https://twitter.com/kade0912?lang=en',	'64A250'],
			['srPEREZ',				'perez',			"Multi Key Assets/Original Multi Key Code",					'https://twitter.com/newsrperez?lang=en','FFAE00'],
			['Grantare',			'discord',			"Golden Apple Programmer",									'https://twitter.com/grantarep?lang=en','5C89BF'],
			['MoldyGH',				'discord',			"Dave and Bambi Programmer",								'https://twitter.com/moldy_gh?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor','5C89BF'],
			['Rei the Goat',		'discord',			"Vs Cye Programmer",										'https://www.youtube.com/c/ReitheGoat',	'5C89BF'],
			['Rozebud',				'discord',			"FPS+ Programmer",											'https://twitter.com/helpme_thebigt?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor','5C89BF'],
			[''],
			["Denpa Funkin' Crew"],
			['DPadderz',			'dpadderz',			"Artist, Composer, and Ideas Man",							'https://twitter.com/MoldyPuff',		'A5BABA'],
			//['Shayz',				'shayz',			"Charter",													'NON EXISTENT',							'DF002F'],
			['Denpamoo',			'moo',				"Cool 2d artist",											'NON EXISTENT',							'63E7FF'],
			['ZebruhYes',			'zebruh',			"Cool 3d artist",											'https://www.youtube.com/channel/UCIpWCo8lgIxtkXEhRFA50lg','FFFFFF'],
			['Chuckles',			'chuckles',			"Composer and Ideas Man",									'https://twitter.com/Chuckle10511369',	'6B6B6B'],
			//['Satas',				'discord',			"Arist and Playtester",										'https://mobile.twitter.com/Void_satas','5C89BF'],
			['Denpa Men Discord',	'discord',			"Press Enter to Join",										'https://discord.gg/thedenpamen',		'5C89BF'],
			[''],
			["Funkin' Crew"],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",						'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",							'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",							'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",							'https://twitter.com/kawaisprite',		'D2D2D2'],
			[''],
			['Psych Team'],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',							'https://twitter.com/Shadow_Mario_',	'444444'],
			['RiverOaken',			'riveroaken',		'Main Artist/Animator of Psych Engine',						'https://twitter.com/RiverOaken',		'B42F71'],
			['shubs',				'shubs',			'Additional Programmer of Psych Engine',					'https://twitter.com/yoshubs',			'5E99DF'],
			['bb-panzu',			'bb-panzu',			'Ex-Programmer of Psych Engine',							'https://twitter.com/bbsub3',			'3E213A'],
			['iFlicky',				'iflicky',			'Composer of Psync and Tea Time\nMade the Dialogue Sounds',	'https://twitter.com/flicky_i',			'9E29CF'],
			['SqirraRNG',			'gedehari',			'Chart Editor\'s Sound Waveform base',						'https://twitter.com/gedehari',			'E1843A'],
			['PolybiusProxy',		'polybiusproxy',	'.MP4 Video Loader Extension',								'https://twitter.com/polybiusproxy',	'DCD294'],
			['Keoiki',				'keoiki',			'Note Splash Animations',									'https://twitter.com/Keoiki_',			'D2D2D2'],
			['Smokey',				'smokey',			'Spritemap Texture Support',								'https://twitter.com/Smokey_5_',		'483D92']
		];
		
		for(i in pisspoop){
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 70 * i, creditsStuff[i][0], !isSelectable, false);
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
				if(creditsStuff[i][5] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][5];
				}

				var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much fuss!
				iconArray.push(icon);
				add(icon);
				Paths.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}
		
		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER/*, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK*/);
		descText.scrollFactor.set();
		//descText.borderSize = 2.4;
		descBox.sprTracker = descText;
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
			if(creditsStuff.length > 1)
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
				CoolUtil.browserLoad(creditsStuff[curSelected][3]);
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
					var lastX:Float = item.x;
					item.screenCenter(X);
					item.x = FlxMath.lerp(lastX, item.x - 70, lerpVal);
					item.forceX = item.x;
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 200 + -40 * Math.abs(item.targetY), lerpVal);
					item.forceX = item.x;
				}
			}
		}
		super.update(elapsed);
	}

	var moveTween:FlxTween = null;
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

		descText.text = creditsStuff[curSelected][2];
		descText.y = FlxG.height - descText.height + offsetThing - 60;

		if(moveTween != null) moveTween.cancel();
		moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
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
				if(arr.length >= 5) arr.push(folder);
				creditsStuff.push(arr);
			}
			creditsStuff.push(['']);
		}
		modsAdded.push(folder);
	}
	#end

	function getCurrentBGColor() {
		var bgColor:String = creditsStuff[curSelected][4];
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
}