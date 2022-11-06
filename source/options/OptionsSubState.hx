package options;

import flixel.group.FlxSpriteGroup;
#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import flixel.FlxCamera;
import openfl.Lib;
import Alphabet;
import Shaders.ColorSwap;
import Note.StrumNote;

using StringTools;

/**
* State used to adjust HSB of the notes.
*/
class NotesSubState extends MusicBeatSubstate
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var posX = 230;

	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;

	public function new() {
		super();
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		if (!ClientPrefs.lowQuality) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.lowQuality) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		
		blackBG = new FlxSprite(posX - 25).makeGraphic(1140, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		var titleText:FlxText = new FlxText(0, 20, 0, "Note HSB", 24);
		titleText.setFormat(Paths.font("calibri-regular.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xff59136d);
		titleText.x += 14;
		titleText.y -= 3;

		var titleBG:FlxSprite = new FlxSprite(0,30).loadGraphic(Paths.image('oscillators/optionsbg'));
		titleBG.setGraphicSize(Std.int(titleText.width*1.225), Std.int(titleText.height/1.26));
		titleBG.updateHitbox();
		add(titleBG);
		add(titleText);


		if (ClientPrefs.arrowHSV.length != 9) {
			ClientPrefs.arrowHSV = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
		}
		//trace (ClientPrefs.arrowHSV.length);
		for (i in 0...ClientPrefs.arrowHSV.length) {
			var yPos:Float = (80 * i) - 40;
			for (j in 0...3) {
				var optionText:Alphabet = new Alphabet(0, yPos + 60, Std.string(ClientPrefs.arrowHSV[i][j]), true, false, 0.05, 0.8);
				optionText.x = posX + (225 * j) + 250;
				optionText.ID = i;
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas('NOTE_assets');
			var animation = Note.gfxLetter[i];
			note.animation.addByPrefix('idle', animation + '0');
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.globalAntialiasing;
			note.ID = i;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.hue = ClientPrefs.arrowHSV[i][0] / 360;
			newShader.saturation = ClientPrefs.arrowHSV[i][1] / 100;
			newShader.brightness = ClientPrefs.arrowHSV[i][2] / 100;
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(0, 0, "Hue    Saturation  Brightness", false, false, 0, 0.65);
		hsbText.x = posX + 330;
		add(hsbText);

		changeSelection();
	}

	var changingNote:Bool = false;
	var angleTween:FlxTween;
	var scaleTween:FlxTween;
	var lastSelected:Int = 99;
	override function update(elapsed:Float) {
		var rownum = 0;
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 9.6, 0, 1);
		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			var scaledY = FlxMath.remapToRange(item.ID, 0, 1, 0, 1.3);
			item.y = FlxMath.lerp(item.y, (scaledY * 165) + 270 + 60, lerpVal);
			item.x = FlxMath.lerp(item.x, (item.ID * 20) + 90 + posX + (225 * rownum + 250), lerpVal);
			rownum++;
			if (rownum == 3) rownum = 0;
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			var scaledY = FlxMath.remapToRange(item.ID, 0, 1, 0, 1.3);
			item.y = FlxMath.lerp(item.y, (scaledY * 165) + 270, lerpVal);
			item.x = FlxMath.lerp(item.x, (item.ID * 20) + 90, lerpVal);
			if (i == curSelected) {
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;
				blackBG.x = item.x - 20;
				if (lastSelected != curSelected) {
					lastSelected = curSelected;
					if (angleTween != null) angleTween.cancel();
					angleTween = null;
					if (scaleTween != null) scaleTween.cancel();
					scaleTween = null;
					item.scale.set(0.78,0.78);
					angleTween = FlxTween.angle(item, -12, 12, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
					scaleTween = FlxTween.tween(item, {"scale.x": 0.92, "scale.y": 0.92}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
				}
			} else {
				item.scale.set(0.6,0.6);
				item.angle = 0;
			}
		}

		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				for (i in 0...3) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			var shiftMult:Int = 1;

			if(FlxG.mouse.wheel != 0 && ClientPrefs.mouseControls)
				{
					changeSelection(-shiftMult * FlxG.mouse.wheel);
				}
			if ((controls.ACCEPT || (FlxG.mouse.justPressed && ClientPrefs.mouseControls)) && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * 3) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		if ((controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls)) || (changingNote && (controls.ACCEPT || (FlxG.mouse.justPressed && ClientPrefs.mouseControls)))) {
			if(!changingNote) {
				close();
			} else {
				changeSelection();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	override function destroy() {
		if (angleTween != null) angleTween.cancel();
		angleTween = null;
		if (scaleTween != null) scaleTween.cancel();
		scaleTween = null;
		super.destroy();
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = ClientPrefs.arrowHSV.length-1;
		if (curSelected >= ClientPrefs.arrowHSV.length)
			curSelected = 0;

		curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		updateValue();

		var bullshit = 0;
		var rownum = 0;
		//var currow;
		var bullshit2 = 0;
		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
			item.ID = bullshit - curSelected;
			rownum++;
			if (rownum == 3) {
				rownum = 0;
				bullshit++;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.5, 0.5);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(0.6, 0.6);
				hsbText.y = item.y - 40;
				blackBG.y = item.y + 28;
			}
			item.ID = bullshit2 - curSelected;
			bullshit2++;
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = ClientPrefs.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		curValue = 0;
		ClientPrefs.arrowHSV[selected][type] = 0;
		switch(type) {
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}

		var item = grpNumbers.members[(selected * 3) + type];
		item.changeText('0');
		item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;
	}
	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;
		switch(typeSelected) {
			case 1 | 2: max = 100;
		}

		if(roundedValue < -max) {
			curValue = -max;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		ClientPrefs.arrowHSV[curSelected][typeSelected] = roundedValue;

		switch(typeSelected) {
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}

		var item = grpNumbers.members[(curSelected * 3) + typeSelected];
		item.changeText(Std.string(roundedValue));
		item.offset.x = (40 * (item.lettersArray.length - 1)) / 2;
		if(roundedValue < 0) item.offset.x += 10;
	}
}

/**
* State used to adjust general settings, such as FPS.
*/
class GeneralSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'General Settings';
		rpcTitle = 'General Settings Menu'; //for Discord Rich Presence

		#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(option);

		option.minValue = 24;
		option.maxValue = 999;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		#end

		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeFPSCounter;

		#if !html
		var option:Option = new Option('Fullscreen',
			'Makes the window fullscreen.',
			'fullscreen',
			'bool',
			false);
		addOption(option);
		option.onChange = onChangeFullscreen;
		
		var option:Option = new Option('Auto Pause',
			'Turns on/off auto pausing on focus lost.',
			'autoPause',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeAutoPause;
		#end

		#if !android
		var option:Option = new Option('Mouse Controls',
			'Turns on or off UI Mouse Controls',
			'mouseControls',
			'bool',
			true);
		addOption(option);
		#end

		var option:Option = new Option('Check For Updates',
			'Checks for updates on startup if enabled.',
			'checkForUpdates',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights!",
			'flashing',
			'bool',
			true);
		addOption(option);


		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			'OVERDOSE',
			['None', 'Breakfast', 'Tea Time', 'OVERDOSE']);
		addOption(option);
		option.onChange = onChangePauseMusic;

		super();
	}

	var changedMusic:Bool = false;
	function onChangePauseMusic()
	{
		if(ClientPrefs.pauseMusic == 'None')
			FlxG.sound.music.volume = 0;
		else
			FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic)));

		changedMusic = true;
	}

	function onChangeFramerate()
	{
		if(ClientPrefs.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.framerate;
			FlxG.drawFramerate = ClientPrefs.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.framerate;
			FlxG.updateFramerate = ClientPrefs.framerate;
		}
	}

	#if !mobile
	function onChangeFPSCounter()
	{
		if(Main.fpsCounter != null)
			Main.toggleFPS(ClientPrefs.showFPS);
		if(Main.ramCount != null)
			Main.toggleMEM(ClientPrefs.showFPS);
	}

	function onChangeFullscreen()
	{
		FlxG.fullscreen = ClientPrefs.fullscreen;
	}

	function onChangeAutoPause()
	{
		FlxG.autoPause = ClientPrefs.autoPause;
	}
	#end

	override function destroy()
		{
			if(changedMusic) FlxG.sound.playMusic(Paths.music('freakyMenu'));
			super.destroy();
		}
}

/**
* State used to adjust gameplay settings, such as Downscroll.
*/
class GameplaySettingsSubState extends BaseOptionsMenu
{
	var hitSound:String = 'hitsound';
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence'

		var option:Option = new Option('Rating Generosity:',
			"How generous do you want the ratings?",
			'ratingIntensity',
			'string',
			'Default',
			['Generous', 'Default', 'Harsh']);
		addOption(option);

		var option:Option = new Option('Accuracy Mode:',
			"How accurate do you want the accuracy?",
			'accuracyMode',
			'string',
			'Simple',
			['Simple', 'Complex']);
		addOption(option);

		/*var option:Option = new Option('Controller Mode',
			'Check this if you want to play with\na controller instead of using your Keyboard.',
			'controllerMode',
			'bool',
			false);
		addOption(option);*/

		var option:Option = new Option('Downscroll',
			'If checked, notes go Down instead of Up, simple enough.',
			'downScroll',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Disable Reset Button',
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Hitsound Volume',
			'How loud do you want the hit sounds?',
			'hitsoundVolume',
			'percent',
			0);
		addOption(option);
		option.onChange = onChangeHitsound;
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;

		var option:Option = new Option('Hitsound\'s Sound:',
			"What sound do you want to play when hitting a note?",
			'hitSound',
			'string',
			'Hit Sound',
			['Hit Sound', 'Crit', 'GF', 'Metronome', 'Coin', 'Bubble']);
		addOption(option);
		option.onChange = onChangeHitsound;

		var option:Option = new Option('Miss Volume',
			'How loud do you want the miss sounds?',
			'missSoundVolume',
			'percent',
			0);
		addOption(option);
		option.onChange = onChangeMissVol;
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;

		var option:Option = new Option('Rating Offset',
			'Changes how late/early you have to hit for a "Crit!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int',
			0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Perfect Hit Window',
			'Changes the amount of time you have\nfor hitting a "Perfect" in milliseconds.',
			'perfectWindow',
			'int',
			10);
		option.displayFormat = '%vms';
		option.scrollSpeed = 1;
		option.minValue = 1;
		option.maxValue = 14;
		addOption(option);

		var option:Option = new Option('Sick Hit Window',
			'Changes the amount of time you have\nfor hitting a "Sick" in milliseconds.',
			'sickWindow',
			'int',
			45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int',
			90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int',
			135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Shit Hit Window',
			'Changes the amount of time you have\nfor hitting a "Shit" in milliseconds.',
			'shitWindow',
			'int',
			205);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 205;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float',
			10);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		addOption(option);

		super();

		switch (ClientPrefs.hitSound) {
			case 'Hit Sound':
				hitSound = 'hitsound';
			case 'Crit':
				hitSound = 'crit';
			case 'GF':
				hitSound = 'GF_1';
			case 'Metronome':
				hitSound = 'Metronome_Tick';
			case 'Coin':
				hitSound = 'smw_coin';
			case 'Bubble':
				hitSound = 'smw_bubble_pop';
		}
	}

	function onChangeMissVol() {
		if (ClientPrefs.missSoundVolume > 0)
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missSoundVolume);
	}

	function onChangeHitsound() {
		switch (ClientPrefs.hitSound) {
			case 'Hit Sound':
				hitSound = 'hitsound';
			case 'Crit':
				hitSound = 'crit';
			case 'GF':
				hitSound = 'GF_1';
			case 'Metronome':
				hitSound = 'Metronome_Tick';
			case 'Coin':
				hitSound = 'smw_coin';
			case 'Bubble':
				hitSound = 'smw_bubble_pop';
		}
		if (ClientPrefs.hitsoundVolume > 0)
			FlxG.sound.play(Paths.sound(hitSound), ClientPrefs.hitsoundVolume);
	}

	override function changeSelection(change:Int = 0) {
		super.changeSelection(change);
	}
}

/**
* State used to adjust graphics settings, such as Antialiasing.
*/
class GraphicsSettingsSubState extends BaseOptionsMenu
{
	var canZoom:Bool = false;
	var shouldZoom:Bool = false;
	var floatyTxt:FlxText;
	var noteSplash:FlxSprite;
	var icon:HealthIcon;
	var iconSwing:String = 'Swing';
	var healthBar:FlxSprite;
	var rating:FlxSprite;

	public function new()
	{
		title = 'Graphics Settings';
		rpcTitle = 'Graphics Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality', //Name
			'If checked, disables some background details,\ndecreases loading times and improves performance.', //Description
			'lowQuality', //Save data variable name
			'bool', //Variable type
			false); //Default value
		addOption(option);
		option.onChange = onChangeLowQual;

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Watermarks',
			"If checked, Denpa Engine Watermarks will be enabled, as well as the Song Credits.",
			'watermarks',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeWatermarks;

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeZoom;

		var option:Option = new Option('Note Splashes',
			"If unchecked, hitting \"Sick!\" notes won't show particles.",
			'noteSplashes',
			'bool',
			true);
		addOption(option);
		option.onChange = onChangeSplash;

		var option:Option = new Option('Icon Animation:',
			"What animation should the healthbar icons do?",
			'iconSwing',
			'string',
			'Swing',
			['Swing', 'Snap', 'Squish', 'Stretch', 'Bop', 'Old',/* 'Fluid',*/ 'None']);
		addOption(option);
		option.onChange = onChangeSwing;

		var option:Option = new Option('Health Bar Transparency',
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent',
			1);
		option.onChange = onChangeHPTrans;
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Combo and Rating Skin:',
			"What skin do you want?",
			'uiSkin',
			'string',
			'FNF',
			['FNF', 'Denpa', 'Kade']);
		addOption(option);
		option.onChange = onChangeSkin;

		var option:Option = new Option('Score Display:',
			"What engine's score display do you want?",
			'scoreDisplay',
			'string',
			'Psych',
			['Psych', 'Kade', 'Sarvente', 'FPS+', 'FNF+', 'FNM', 'Vanilla', 'None']);
		addOption(option);

		var option:Option = new Option('Sarvente Accuracy Display',
			'If checked, shows the accuracy in Sarvente Score Display.',
			'sarvAccuracy',
			'bool',
			false);
		addOption(option);
		
		var option:Option = new Option('Score Text Zoom on Hit',
			"If unchecked, disables the Score text zooming\neverytime you hit a note.",
			'scoreZoom',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Ratings Display',
			"If checked, a display showing how many Perfects, Sicks, Etc. will be enabled.",
			'ratingsDisplay',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Time Bar:',
			"What should the Time Bar display?",
			'timeBarType',
			'string',
			'Time Left',
			['Time Left', 'Time Elapsed', 'Song Name', 'Time Left (No Bar)', 'Time Elapsed (No Bar)', 'Disabled']);
		addOption(option);

		var option:Option = new Option('Autoswap Time Bar Colour',
			"If checked, the Time Bar's colour will change to fit the opponent.",
			'changeTBcolour',
			'bool',
			true);
		addOption(option);

		/*var option:Option = new Option('Time Bar Red:',
			"The Amount of Red in the Time Bar's Colour.",
			'timeBarRed',
			'int',
			255);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 255;

		var option:Option = new Option('Time Bar Green:',
			"The Amount of Green in the Time Bar's Colour.",
			'timeBarGreen',
			'int',
			255);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 255;

		var option:Option = new Option('Time Bar Blue:',
			"The Amount of Blue in the Time Bar's Colour.",
			'timeBarBlue',
			'int',
			255);
		addOption(option);*/

		option.minValue = 0;
		option.maxValue = 255;

		super();

		shouldZoom = ClientPrefs.camZooms;

		floatyTxt = new FlxText(FlxG.width, FlxG.height/2 - 100, 0, "Denpa Engine v" + MainMenuState.denpaEngineVersion);
		floatyTxt.scrollFactor.set();
		floatyTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		floatyTxt.visible = false;
		floatyTxt.x -= floatyTxt.width*1.1;
		add(floatyTxt);

		noteSplash = new FlxSprite(FlxG.width, FlxG.height/2 - 200);
		noteSplash.frames = Paths.getSparrowAtlas('splashes/noteSplashes');
		noteSplash.animation.addByPrefix('splash', 'note splash A 1', 24, false);
		noteSplash.animation.play('splash');
		noteSplash.antialiasing = ClientPrefs.globalAntialiasing;
		noteSplash.visible = false;
		noteSplash.x -= noteSplash.width*1.5;
		add(noteSplash);

		icon = new HealthIcon('bf', true);
		icon.x = FlxG.width - icon.width*1.5;
		icon.y = FlxG.height/2 - 75;
		icon.antialiasing = ClientPrefs.globalAntialiasing;
		icon.visible = false;
		add(icon);

		healthBar = new FlxSprite().makeGraphic(601, 19, FlxColor.BLACK);
		healthBar.antialiasing = ClientPrefs.globalAntialiasing;
		healthBar.visible = false;
		var healthBarRed = new AttachedSprite.NGAttachedSprite(Std.int(healthBar.width/2)-3, 13, 0xFFFF0000);
		healthBarRed.antialiasing = ClientPrefs.globalAntialiasing;
		healthBarRed.xAdd = 3;
		healthBarRed.yAdd = 3;
		healthBarRed.sprTracker = healthBar;
		healthBarRed.copyVisible = true;
		healthBarRed.copyAlpha = true;
		var healthBarGreen = new AttachedSprite.NGAttachedSprite(Std.int(healthBar.width/2)-3, 13, 0xFF54FF00);
		healthBarGreen.antialiasing = ClientPrefs.globalAntialiasing;
		healthBarGreen.xAdd = 301;
		healthBarGreen.yAdd = 3;
		healthBarGreen.sprTracker = healthBar;
		healthBarGreen.copyVisible = true;
		healthBarGreen.copyAlpha = true;
		healthBar.x = FlxG.width - 620;
		healthBar.y = FlxG.height/2 + 150;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		add(healthBarRed);
		add(healthBarGreen);

		rating = new FlxSprite(FlxG.width, FlxG.height/2 - 60).loadGraphic(Paths.image('ratings/sick-' + ClientPrefs.uiSkin.toLowerCase()));
		rating.visible = false;
		rating.antialiasing = ClientPrefs.globalAntialiasing;
		rating.scale.set(0.6,0.6);
		rating.updateHitbox();
		rating.x -= rating.width*1.2;
		add(rating);
	}

	override function beatHit() {
		super.beatHit();
		if (canZoom && shouldZoom) {
			if (curBeat % 2 == 0) FlxG.camera.zoom += 0.015;
		}
		if (noteSplash != null && noteSplash.visible) {
			noteSplash.animation.play('splash');
		}
		if (icon != null && icon.visible) {
			switch (iconSwing)
			{
				case 'Swing':
				if (curBeat % 1 == 0) {
					curBeat % (1 * 2) == 0 ? {
						icon.scale.set(1.1, 0.8);
		
						FlxTween.angle(icon, -15, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
					} : {
						icon.scale.set(1.1, 1.3);

						FlxTween.angle(icon, 15, 0, Conductor.crochet / 1300, {ease: FlxEase.quadOut});
					}
		
					FlxTween.tween(icon, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250, {ease: FlxEase.quadOut});
		
					icon.updateHitbox();
				}
				case 'Squish':
					if (curBeat % 1 == 0) {
						curBeat % (1 * 2) == 0 ? {
							icon.scale.set(1.3, 0.3);
						} : {
							icon.scale.set(0.3, 1.3);
						}
			
						FlxTween.tween(icon, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250, {ease: FlxEase.quadOut});
			
						icon.updateHitbox();
					}
				case 'Bop':
					icon.scale.set(1.2, 1.2);
			
					icon.updateHitbox();
				case 'Old':
					icon.setGraphicSize(Std.int(icon.width + 30));
			
					icon.updateHitbox();
				case 'Snap':
					if (curBeat % 1 == 0) {
						curBeat % (1 * 2) == 0 ? {
							icon.scale.set(1.1, 0.8);
			
							icon.angle = -15;
						} : {
							icon.scale.set(1.1, 1.3);

							icon.angle = 15;
						}
			
						FlxTween.tween(icon, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250, {ease: FlxEase.quadOut});
			
						icon.updateHitbox();
					}
				case 'Stretch':
					var funny:Float = (100 * 0.01) + 0.01;
					icon.setGraphicSize(Std.int(icon.width + (50 * funny)),Std.int(150 - (25 * funny)));
			
					icon.updateHitbox();
			}
		}
	}

	override function changeSelection(change:Int = 0) {
		super.changeSelection(change);
		if (floatyTxt != null) {
			floatyTxt.visible = false;
			if (optionsArray[curSelected].name == 'Watermarks') {
				floatyTxt.visible = ClientPrefs.watermarks;
			}
		}

		if (noteSplash != null) {
			noteSplash.visible = false;
			if (optionsArray[curSelected].name == 'Note Splashes') {
				noteSplash.visible = ClientPrefs.noteSplashes;
			}
		}

		if (icon != null) {
			icon.visible = false;
			if (optionsArray[curSelected].name == 'Icon Animation:') {
				icon.visible = true;
			}
		}

		if (healthBar != null) {
			healthBar.visible = false;
			if (optionsArray[curSelected].name == 'Health Bar Transparency') {
				healthBar.visible = true;
			}
		}

		if (rating != null) {
			rating.visible = false;
			if (optionsArray[curSelected].name == 'Combo and Rating Skin:') {
				rating.visible = true;
			}
		}
			
		canZoom = false;
		if (optionsArray[curSelected].name == 'Camera Zooms') {
			canZoom = true;
		}
	}

	var elapsedtime:Float = 0;
	override function update(elapsed) {
		super.update(elapsed);
		elapsedtime += elapsed;
		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		if (floatyTxt != null) {
			floatyTxt.y += FlxMath.fastSin(elapsedtime)/4;
		}
		if (icon != null) {
			switch (iconSwing)
			{
				case 'Old':
					icon.angle = 0;
					icon.setGraphicSize(Std.int(FlxMath.lerp(150, icon.width, 0.50)));
	
					icon.updateHitbox();
				case 'Stretch':
					icon.angle = 0;
					icon.setGraphicSize(Std.int(FlxMath.lerp(150, icon.width, 0.8)),Std.int(FlxMath.lerp(150, icon.height, 0.8)));
			
					icon.updateHitbox();
				case 'Swing' | 'Snap':
					//sex
				case 'Squish':
					icon.angle = 0;
				default:
					icon.angle = 0;
					var mult:Float = FlxMath.lerp(1, icon.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
					icon.scale.set(mult, mult);
					icon.updateHitbox();
			}
		}
	}

	function onChangeZoom()
	{
		shouldZoom = ClientPrefs.camZooms;
	}

	function onChangeWatermarks()
	{
		if (floatyTxt != null)
			floatyTxt.visible = ClientPrefs.watermarks;
	}

	function onChangeSplash()
	{
		if (noteSplash != null) {
			noteSplash.visible = ClientPrefs.noteSplashes;
			noteSplash.animation.play('splash');
		}
	}

	function onChangeSwing()
	{
		iconSwing = ClientPrefs.iconSwing;
	}

	function onChangeHPTrans()
	{
		if (healthBar != null) {
			healthBar.alpha = ClientPrefs.healthBarAlpha;
		}
	}

	function onChangeSkin()
	{
		if (rating != null)
			rating.loadGraphic(Paths.image('ratings/sick-' + ClientPrefs.uiSkin.toLowerCase()));
	}


	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; //Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; //Don't judge me ok
			if(sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}

	function onChangeLowQual()
	{
		if (bgScroll != null) {
			bgScroll.visible = !ClientPrefs.lowQuality;
			bgScroll2.visible = !ClientPrefs.lowQuality;
		}
	}
}

/**
* State used to adjust misc settings, which do not fit in the other classifications.
*/
class MiscSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc Settings';
		rpcTitle = 'Misc Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Opponent CrossFade Limit',
			"Determines the maximium amount of frames of CrossFade the opponent can have.",
			'crossFadeLimit',
			'int',
			4);
		addOption(option);

		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('BF CrossFade Limit',
			"Determines the maximium amount of frames of CrossFade the player can have.",
			'boyfriendCrossFadeLimit',
			'int',
			1);
		addOption(option);

		option.minValue = 1;
		option.maxValue = 10;

		var option:Option = new Option('CrossFade Mode:',
			"What mode should CrossFade be in?",
			'crossFadeMode',
			'string',
			'Mid-Fight Masses',
			['Mid-Fight Masses', 'Static', 'Eccentric', 'Off']);
		addOption(option);

		var option:Option = new Option('Cutscenes:',
			'When do you want cutscenes to play?',
			'cutscenes',
			'string',
			'Story Mode Only',
			['Story Mode Only', 'Freeplay Only', 'Always', 'Never']);
		addOption(option);

		var option:Option = new Option('Subtitles',
			"If unchecked, subtitles will not appear.",
			'subtitles',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Camera Movement',
			"If unchecked, the camera won't move when you/your opponent hits a note.",
			'camPans',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Cam Move Mode:',
			"How do you want the camera movement to behave?",
			'camPanMode',
			'string',
			'Always',
			['Always', 'Camera Focus', 'BF Only', 'Oppt Only', 'Player 4 Only']);
		addOption(option);

		var option:Option = new Option('Ghost Tapping Miss Animation',
			"If checked, the player will do miss animations when you press the arrows while Ghost Tapping is enabled. If unchecked, the player will do normal sing animations instead.",
			'gsmiss',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Opponent Always Dance',
			"If unchecked, the opponent only dances when the camera is on BF.",
			'opponentAlwaysDance',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Opponent Note Animations',
			"If unchecked, the opponent's strums will not light up.",
			'opponentNoteAnimations',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Icon Flinching',
			"If checked, Missing will cause the player's icon to show the dying animation temporarily.",
			'flinchy',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('OG Healthbar',
			"If checked, the healthbar's colours will be set to Red/Green globally.",
			'greenhp',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Use Wrong Camera',
			'If checked, the rating popups will be in the game camera, not the HUD.',
			'wrongCamera',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Combo Pop Up',
			'If checked, the unused Combo Sprite will appear after getting a combo of 10 or more.',
			'comboPopup',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Combo Stacking',
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('MS Timing Text',
			'If checked, text displaying your MS timing will appear when hitting a note.',
			'msPopup',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('MS Display Precision:',
			"How precise the MS Timing display is. Lower numbers = less precise. 0 is only Integers.",
			'msPrecision',
			'int',
			2);
		addOption(option);

		option.minValue = 0;
		option.maxValue = 9;

		super();
	}
}

class ControlsSubState extends MusicBeatSubstate {
	private static var curSelected:Int = -1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';
	private var bindLength:Int = 0;

	var optionShit:Array<Dynamic> = [
		['NOTES'],
		['Left', 'note_four1'],
		['Down', 'note_four2'],
		['Up', 'note_four3'],
		['Right', 'note_four4'],
		[''],
		['UI'],
		['Left', 'ui_left'],
		['Down', 'ui_down'],
		['Up', 'ui_up'],
		['Right', 'ui_right'],
		[''],
		['Reset', 'reset'],
		['Accept', 'accept'],
		['Back', 'back'],
		['Pause', 'pause'],
		[''],
		['VOLUME'],
		['Mute', 'volume_mute'],
		['Up', 'volume_up'],
		['Down', 'volume_down'],
		[''],
		['DEBUG'],
		['Key 1', 'debug_1'],
		['Key 2', 'debug_2'],
		[''],
		['MULTIKEY'],
		[''],
		['1K'],
		['Center', 'note_one1'],
		[''],
		['2K'],
		['Left', 'note_two1'],
		['Right', 'note_two2'],
		[''],
		['3K'],
		['Left', 'note_three1'],
		['Center', 'note_three2'],
		['Right', 'note_three3'],
		[''],
		['5K'],
		['Left', 'note_five1'],
		['Down', 'note_five2'],
		['Center', 'note_five3'],
		['Up', 'note_five4'],
		['Right', 'note_five5'],
		[''],
		['6K'],
		['Left 1', 'note_six1'],
		['Up', 'note_six2'],
		['Right 1', 'note_six3'],
		['Left 2', 'note_six4'],
		['Down', 'note_six5'],
		['Right 2', 'note_six6'],
		[''],
		['7K'],
		['Left 1', 'note_seven1'],
		['Up', 'note_seven2'],
		['Right 1', 'note_seven3'],
		['Center', 'note_seven4'],
		['Left 2', 'note_seven5'],
		['Down', 'note_seven6'],
		['Right 2', 'note_seven7'],
		[''],
		['8K'],
		['Left 1', 'note_eight1'],
		['Down 1', 'note_eight2'],
		['Up 1', 'note_eight3'],
		['Right 1', 'note_eight4'],
		['Left 2', 'note_eight5'],
		['Down 2', 'note_eight6'],
		['Up 2', 'note_eight7'],
		['Right 2', 'note_eight8'],
		[''],
		['9K'],
		['Left 1', 'note_nine1'],
		['Down 1', 'note_nine2'],
		['Up 1', 'note_nine3'],
		['Right 1', 'note_nine4'],
		['Center', 'note_nine5'],
		['Left 2', 'note_nine6'],
		['Down 2', 'note_nine7'],
		['Up 2', 'note_nine8'],
		['Right 2', 'note_nine9']
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var grpInputs:Array<AttachedText> = [];
	private var grpInputsAlt:Array<AttachedText> = [];
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;

	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;

	public function new() {
		super();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		if (!ClientPrefs.lowQuality) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.lowQuality) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		var titleText:FlxText = new FlxText(0, 20, 0, "Keybinds", 24);
		titleText.setFormat(Paths.font("calibri-regular.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xff59136d);
		titleText.x += 14;
		titleText.y -= 3;

		var titleBG:FlxSprite = new FlxSprite(0,30).loadGraphic(Paths.image('oscillators/optionsbg'));
		titleBG.setGraphicSize(Std.int(titleText.width*1.225), Std.int(titleText.height/1.26));
		titleBG.updateHitbox();
		add(titleBG);
		add(titleText);

		optionShit.push(['']);
		optionShit.push([defaultKey]);

		for (i in 0...optionShit.length) {
			var isCentered:Bool = false;
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);
			if(unselectableCheck(i, true)) {
				isCentered = true;
			}

			var optionText:Alphabet = new Alphabet(0, (10 * i), optionShit[i][0], (!isCentered || isDefaultKey), false);
			optionText.altRotation = true;
			if(isCentered) {
				optionText.screenCenter(X);
				optionText.forceX = optionText.x;
				optionText.yAdd = -55;
			} else {
				optionText.forceX = 200;
			}
			optionText.yMult = 60;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(!isCentered) {
				addBindTexts(optionText, i);
				bindLength++;
				if(curSelected < 0) curSelected = i;
			}
		}
		changeSelection();
	}

	var leaving:Bool = false;
	var bindingTime:Float = 0;
	override function update(elapsed:Float) {
		if(!rebindingKey) {
			var shiftMult:Int = 1;
			if (FlxG.keys.pressed.SHIFT) {
				shiftMult = 4;
			}
			if (controls.UI_UP_P) {
				changeSelection(-shiftMult);
			}
			if (controls.UI_DOWN_P) {
				changeSelection(shiftMult);
			}
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
				changeAlt();
			}

			if(FlxG.mouse.wheel != 0 && ClientPrefs.mouseControls)
				{
					changeSelection(-shiftMult * FlxG.mouse.wheel);
				}

			if (controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls)) {
				ClientPrefs.reloadControls();
				close();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}

			if(controls.ACCEPT && nextAccept <= 0) {
				if(optionShit[curSelected][0] == defaultKey) {
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					reloadKeys();
					changeSelection();
					FlxG.sound.play(Paths.sound('confirmMenu'));
				} else if(!unselectableCheck(curSelected)) {
					bindingTime = 0;
					rebindingKey = true;
					if (curAlt) {
						grpInputsAlt[getInputTextNum()].alpha = 0;
					} else {
						grpInputs[getInputTextNum()].alpha = 0;
					}
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
		} else {
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1) {
				var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionShit[curSelected][1]);
				keysArray[curAlt ? 1 : 0] = keyPressed;

				var opposite:Int = (curAlt ? 0 : 1);
				if(keysArray[opposite] == keysArray[1 - opposite]) {
					keysArray[opposite] = NONE;
				}
				ClientPrefs.keyBinds.set(optionShit[curSelected][1], keysArray);

				reloadKeys();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				rebindingKey = false;
			}

			bindingTime += elapsed;
			if(bindingTime > 5) {
				if (curAlt) {
					grpInputsAlt[curSelected].alpha = 1;
				} else {
					grpInputs[curSelected].alpha = 1;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
				rebindingKey = false;
				bindingTime = 0;
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function getInputTextNum() {
		var num:Int = 0;
		for (i in 0...curSelected) {
			if(optionShit[i].length > 1) {
				num++;
			}
		}
		return num;
	}
	
	function changeSelection(change:Int = 0) {
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if(curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if(grpInputsAlt[i].sprTracker == item) {
								grpInputsAlt[i].alpha = 1;
								break;
							}
						}
					} else {
						for (i in 0...grpInputs.length) {
							if(grpInputs[i].sprTracker == item) {
								grpInputs[i].alpha = 1;
								break;
							}
						}
					}
				}
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeAlt() {
		curAlt = !curAlt;
		for (i in 0...grpInputs.length) {
			if(grpInputs[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputs[i].alpha = 0.6;
				if(!curAlt) {
					grpInputs[i].alpha = 1;
				}
				break;
			}
		}
		for (i in 0...grpInputsAlt.length) {
			if(grpInputsAlt[i].sprTracker == grpOptions.members[curSelected]) {
				grpInputsAlt[i].alpha = 0.6;
				if(curAlt) {
					grpInputsAlt[i].alpha = 1;
				}
				break;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	private function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool {
		if(optionShit[num][0] == defaultKey) {
			return checkDefaultKey;
		}
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}

	private function addBindTexts(optionText:Alphabet, num:Int) {
		var keys:Array<Dynamic> = ClientPrefs.keyBinds.get(optionShit[num][1]);
		var text1 = new AttachedText(InputFormatter.getKeyName(keys[0]), 400, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;
		grpInputs.push(text1);
		add(text1);

		var text2 = new AttachedText(InputFormatter.getKeyName(keys[1]), 650, -55);
		text2.setPosition(optionText.x + 650, optionText.y - 55);
		text2.sprTracker = optionText;
		grpInputsAlt.push(text2);
		add(text2);
	}

	function reloadKeys() {
		while(grpInputs.length > 0) {
			var item:AttachedText = grpInputs[0];
			item.kill();
			grpInputs.remove(item);
			item.destroy();
		}
		while(grpInputsAlt.length > 0) {
			var item:AttachedText = grpInputsAlt[0];
			item.kill();
			grpInputsAlt.remove(item);
			item.destroy();
		}

		trace('Reloaded keys: ' + ClientPrefs.keyBinds);

		for (i in 0...grpOptions.length) {
			if(!unselectableCheck(i, true)) {
				addBindTexts(grpOptions.members[i], i);
			}
		}


		var bullShit:Int = 0;
		for (i in 0...grpInputs.length) {
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length) {
			grpInputsAlt[i].alpha = 0.6;
		}

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
					if(curAlt) {
						for (i in 0...grpInputsAlt.length) {
							if(grpInputsAlt[i].sprTracker == item) {
								grpInputsAlt[i].alpha = 1;
							}
						}
					} else {
						for (i in 0...grpInputs.length) {
							if(grpInputs[i].sprTracker == item) {
								grpInputs[i].alpha = 1;
							}
						}
					}
				}
			}
		}
	}
}