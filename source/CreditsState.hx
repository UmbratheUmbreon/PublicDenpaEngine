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
* State to showcase the credits of the engine and or mod.
*/
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

		var pisspoop:Array<Array<String>> = [ //Username - Icon name - Name - Role - Description - Link - BG Color
			["Denpa Engine"],
			['BlueVapor1234',		'at',				"AT", "Main Programmer & Creator", "\"What am i doing with my life\"",		'https://twitter.com/BlueVapor1234', '34343C'],
			['Toadette8394',		'toadette',			"Toadette", "Co Programmer", "\"Play All Star Funkin': VS Yoshikage Kira\"",	'https://twitter.com/Toadette8394',	'E2009B'],
			['ThriftySoles',		'thrift',			"Thrify", "Misc. Music/Assets", "\"i spent 2 fuqin howas, fixing my qode, too, fakin, aowas\"",		'https://twitter.com/thriftysoles',	'335552'],
			['_Jorge',				'jorge',			"Jorge", "Cross Fade Code, Hscript Support", "\"mmmmm pan ache\"",		'',							'EFDE7D'],
			['Ziad',				'discord',			"Ziad", "Multiplayer Support", "\"Children\"",		'',					'5C89BF'],
			['atpx8',				'discord',			"atpx8", "Infinite Combo, Array Duplicate Removal", "\"<insert unfunny joke here that people will laugh at anyway>\"",		'',					'5C89BF'],
			['YanniZ06',			'discord',			"Yanni", "Bug Fixings", "\"Sex 2, the long awaited sequel Sex is coming to your local cinema RIGHT NOW!!!!\"",		'',					'5C89BF'],
			['Shygee',				'shygee',			"Shygee", "Extra Programmer", "",				'',							'C275F7'],
			['Tsuwukiz',			'tsuwukiz',			"Tsu", "Artist", "\"should i make a baldi mod\"",		'https://twitter.com/tsuwuki666','715BD7'],
			['Boushuu',				'discord',			"Boushuu", "Artist", "\"play fFUBNKIN IN TERIAOR\"",	'',					'5C89BF'],
			['DanyG7',				'dany',				"Dany", "Credits Icons", "",					'https://twitter.com/DanyTheGamer7',	'1CE8FF'],
			['Megaverse',			'discord',			"Megaverse", "Title Music",	"\"Norman\"",		'',							'5C89BF'],
			['Adrian',				'adrian',			"Adrian", "Character Select Music",	"",			'',							'6BBE30'],
			['Bethany Clone',		'egg',				"Beth", "Advisor", "\"I left my oven on\"",		'',							'018B00'],
			['Electrophyll II',		'te',				"Electro", "Ideas Provider", "\"In the end, we all... DIE.\nWhy should I, even try.\nGun in hand, my life shall end\nMY SUFFERING SHALL BE KNOWN, FRIEND!\"",	'',	'EFE469'],
			['MythsList',			'mythslist',		"52", "GameBanana Game Manager", "\"put me in it\"",		'https://twitter.com/MythsList',	'29211F'],
			//['Beterperter',		'sneed',			"Sneed", "Composer", "",						'https://twitter.com/beterperter',		'000033'],
			//['Box',				'box',				"Box", "Optimizer", "",							'',							'C09560'],
			//['Ninteytwo',			'92',				"92", "Ideas Provider",	"",						'https://twitter.com/ninteytwo21',		'FFFFFF'],
			['Discord',				'discord',			"Denpa Discord", "Press " + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'))) + ' or ' + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'), 1)) + " to Join", "",	'https://discord.gg/pUX2ZMm4Qt', '5C89BF'],
			[''],
			["Extra"],
			['kuroao_anomal',		'discord',			"Kuro", "Sarv Engine Programmer", "",				'https://twitter.com/kuroao_anomal?lang=en','5C89BF'],
			['Kade Developer',		'kade',				"Kade", "Kade Engine Programmer", "",				'https://twitter.com/kade0912?lang=en',	'64A250'],
			['srPEREZ',				'perez',			"Perez", "Multi Key Assets", "",					'https://twitter.com/newsrperez?lang=en','FFAE00'],
			['Sky!',				'discord',			"Sky!", "D&B: Golden Apple Programmer", "",			'https://twitter.com/grantarep?lang=en','5C89BF'],
			['MoldyGH',				'discord',			"Moldy", "D&B Programmer", "",						'https://twitter.com/moldy_gh?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor','5C89BF'],
			['Rei the Goat',		'discord',			"Rei", "Vs Cye Programmer",	"",						'https://www.youtube.com/c/ReitheGoat',	'5C89BF'],
			['Rozebud',				'discord',			"Rozebud", "FPS+ Programmer", "",					'https://twitter.com/helpme_thebigt?ref_src=twsrc%5Egoogle%7Ctwcamp%5Eserp%7Ctwgr%5Eauthor','5C89BF'],
			['Shadow Mario',		'shadowmario',		"Shadow Mario", 'Psych Engine Programmer', "\"Cover me in piss\"",	'https://twitter.com/Shadow_Mario_',	'444444'],
			[''],
			/*["Denpa Funkin'"],
			['DPadderz',			'dpadderz',			"Moldy", "Artist, Composer", "",	'https://twitter.com/MoldyPuff',		'A5BABA'],
			['Denpamoo',			'moo',				"Moo", "2d Artist", "",				'',							'63E7FF'],
			['ZebruhYes',			'zebruh',			"Zebruh", "3d Artist", "",			'https://www.youtube.com/channel/UCIpWCo8lgIxtkXEhRFA50lg','FFFFFF'],
			['Chuckles',			'chuckles',			"Chuckles", "Composer", "",			'https://twitter.com/Chuckle10511369',	'6B6B6B'],
			['Denpa Men Discord',	'discord',			"Denpa Men Discord", "Press " + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'))) + ' or ' + InputFormatter.getKeyName(ClientPrefs.getKeyThing(ClientPrefs.keyBinds.get('accept'), 1)) + " to Join", "",		'https://discord.gg/thedenpamen',	'5C89BF'],
			[''],*/
			["FNF"],
			['ninjamuffin99',		'ninjamuffin99',	"Ninjamuffin", "Programmer", "",				'https://twitter.com/ninja_muffin99',	'CF2D2D'],
			['PhantomArcade',		'phantomarcade',	"PhantomArcade", "Animator & Artist", "",		'https://twitter.com/PhantomArcade3K',	'FADC45'],
			['evilsk8r',			'evilsk8r',			"Evilsk8r", "Artist", "",						'https://twitter.com/evilsk8r',			'5ABD4B'],
			['kawaisprite',			'kawaisprite',		"Kawaisprite", "Composer", "",					'https://twitter.com/kawaisprite',		'D2D2D2']
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
				if(creditsStuff[i][7] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][7];
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
				if (creditsStuff[curSelected][5] != null && creditsStuff[curSelected][5].length > 0) {
					CoolUtil.browserLoad(creditsStuff[curSelected][5]);
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
					item.x = FlxMath.lerp(item.x, 100 + -40 * Math.abs(item.targetY), lerpVal);
					item.forceX = item.x;
				}
				else
				{
					item.x = FlxMath.lerp(item.x, 15, lerpVal);
					item.forceX = item.x;
				}
			} else {
				item.x = 25;
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

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		//trace('beat hit' + curBeat);
	}
}
