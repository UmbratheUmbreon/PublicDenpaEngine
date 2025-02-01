package options;

import Alphabet;
import AttachedSprite.NGAttachedSprite;
import Character;
import Controls;
import Shaders.ColorSwap;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import lime.utils.Assets;
import openfl.events.KeyboardEvent;
#if desktop
import Discord.DiscordClient;
#end

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
		add(bg);

		//??? why was this set to global antialiasing before ???
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
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

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var changingNote:Bool = false;
	var angleTween:FlxTween;
	var scaleTween:FlxTween;
	var lastSelected:Int = 99;
	override function update(elapsed:Float) {
		var rownum = 0;
		var lerpVal:Float = CoolUtil.clamp(elapsed * 9.6, 0, 1);
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

			if(FlxG.mouse.wheel != 0)
			{
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}

			if ((controls.ACCEPT) && nextAccept <= 0) {
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

		if ((controls.BACK) || (changingNote && (controls.ACCEPT))) {
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

		#if !html5
		//different res cant really be done on browser lol
		var option:Option = new Option('Resolution:',
			"What resolution do you want the game in?",
			'resolution',
			'string',
			'1280x720',
			//72p,     120p,      144p,      270p       360p,      540p,      720p,       1080p (HD),  1440p (FHD), 2160p (UHD)
			['128x72', '214x120', '256x144', '480x270', '640x360', '960x540', '1280x720', '1920x1080', '2560x1440', '3840x2160']);
		addOption(option);
		option.onChange = changeOption;

		//Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate:',
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(option);

		option.minValue = 1;
		option.maxValue = 1000;
		option.displayFormat = '%v FPS';
		option.onChange = changeOption;
		option.scrollSpeed = 120;
		#end

		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool',
			true);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('FPS Rainbow',
			'If checked, the FPS counter will cycle between different colors in the rainbow.',
			'rainbowFPS',
			'bool',
			false);
		addOption(option);
		option.onChange = changeOption;

		#if !html
		var option:Option = new Option('Auto Pause',
			'Turns on/off auto pausing when you click off the game window.',
			'autoPause',
			'bool',
			true);
		addOption(option);
		option.onChange = changeOption;
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

		var option:Option = new Option('Colorblind Mode:',
			"What type of colorblind are you?",
			'colorblindMode',
			'string',
			'None',
			['None', 'Deutranopia', 'Protanopia', 'Tritanopia']);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Colorblind Intensity:',
			'How intense should the colorblind filter be?',
			'colorblindIntensity',
			'percent',
			0);
		addOption(option);
		option.onChange = changeOption;
		option.scrollSpeed = 1.6;
		option.minValue = 0.1;
		option.maxValue = 1.0;
		option.changeValue = 0.1;
		option.decimals = 1;

		super();

		addScrollers();
	}

	function changeOption(name:String) {
		switch (name) {
			case 'Resolution:':
				var val = cast (ClientPrefs.settings.get("resolution"), String);
				var split = val.split("x");
				CoolUtil.resetResolutionScaling(Std.parseInt(split[0]), Std.parseInt(split[1]));
				FlxG.resizeGame(Std.parseInt(split[0]), Std.parseInt(split[1]));
				Application.current.window.width = Std.parseInt(split[0]);
				Application.current.window.height = Std.parseInt(split[1]);
				//OptionsState.reopen(this);
			case 'Framerate:':
				if(ClientPrefs.settings.get("framerate") > FlxG.drawFramerate) {
					FlxG.updateFramerate = ClientPrefs.settings.get("framerate");
					FlxG.drawFramerate = ClientPrefs.settings.get("framerate");
				} else {
					FlxG.drawFramerate = ClientPrefs.settings.get("framerate");
					FlxG.updateFramerate = ClientPrefs.settings.get("framerate");
				}
				FlxG.game.focusLostFramerate = Math.ceil(ClientPrefs.settings.get("framerate")/2);
			#if !mobile
			case 'FPS Counter':
				Main.toggleFPS(ClientPrefs.settings.get("showFPS"));
				if (Main.ramCount.visible || Main.ramPie.visible) {
					Main.toggleMEM(ClientPrefs.settings.get("showFPS"));
					Main.togglePIE(ClientPrefs.settings.get("showFPS"));
				}
			case 'FPS Rainbow':
				if (!ClientPrefs.settings.get('rainbowFPS'))
					Main.setDisplayColors(0xffFFFFFF);
			case 'Auto Pause':
				FlxG.autoPause = ClientPrefs.settings.get("autoPause");
			#end
			case 'Colorblind Mode:' | 'Colorblind Intensity:':
				var index = ['Deutranopia', 'Protanopia', 'Tritanopia'].indexOf(ClientPrefs.settings.get("colorblindMode"));
				Main.updateColorblindFilter(index, ClientPrefs.settings.get("colorblindIntensity"));
		}
	}
}

/**
* State used to adjust gameplay settings, such as Downscroll.
*/
class GameplaySettingsSubState extends BaseOptionsMenu
{
	var windowBar:FlxSprite;
	final windowDefaultMaxes:Array<Int> = [15, 45, 90, 135, 205];
	final windowDefaultMins:Array<Int> = [1, 16, 46, 91, 136];
	var windowOptions:Array<Option> = [];
	final windowColours = [0xbfffff00, 0xbf00ffff, 0xbf00ff00, 0xbfffaa00, 0xbfff0000, 0xbfff00ff];
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; //for Discord Rich Presence'

		var option:Option = new Option('Complex Accuracy',
			"If checked, the complex accuracy calculations will be used, and provide more accurate accuracy.",
			'complexAccuracy',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Sustains Behave as Notes',
			'If checked, holding sustains increases your health, and missing sustains will reduce your health and be counted as a miss.',
			'sustainsAreNotes',
			'bool',
			true);
		addOption(option);

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

		var option:Option = new Option('Hitsound Volume:',
			'How loud do you want the hit sounds?',
			'hitsoundVolume',
			'percent',
			0);
		addOption(option);
		option.onChange = changeOption;
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;

		var option:Option = new Option('Rating Offset:',
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int',
			0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Perfect Hit Window:',
			'Changes the amount of time you have\nfor hitting a "Perfect" in milliseconds.',
			'perfectWindow',
			'int',
			15);
		option.displayFormat = '%vms';
		option.scrollSpeed = 90;
		windowOptions.push(option);
		option.onChange = changeOption;
		addOption(option);

		var option:Option = new Option('Sick Hit Window:',
			'Changes the amount of time you have\nfor hitting a "Sick" in milliseconds.',
			'sickWindow',
			'int',
			45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 90;
		windowOptions.push(option);
		option.onChange = changeOption;
		addOption(option);

		var option:Option = new Option('Good Hit Window:',
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int',
			90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 90;
		windowOptions.push(option);
		option.onChange = changeOption;
		addOption(option);

		var option:Option = new Option('Bad Hit Window:',
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int',
			135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 90;
		windowOptions.push(option);
		option.onChange = changeOption;
		addOption(option);

		var option:Option = new Option('Shit Hit Window:',
			'Changes the amount of time you have\nfor hitting a "Shit" in milliseconds.',
			'shitWindow',
			'int',
			205);
		option.displayFormat = '%vms';
		option.scrollSpeed = 90;
		windowOptions.push(option);
		option.onChange = changeOption;
		addOption(option);

		var option:Option = new Option('Safe Frames:',
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

		addScrollers();

		windowBar = new FlxSprite((FlxG.width/4) * 3 - 40, FlxG.height/4 - 100).makeGraphic(80, 220, 0x00ffffff);
		windowBar.visible = false;
		windowBar.setGraphicSize(80, 440);
		windowBar.updateHitbox();
		windowBar.antialiasing = false;
		insert(members.indexOf(descBox) - 1, windowBar);

		changeOption('Perfect Hit Window:');
	}

	override function changeSelection(change:Int = 0) {
		super.changeSelection(change);

		if (windowBar != null) windowBar.visible = (optionsArray[curSelected].name.contains('Hit Window'));
	}

	function changeOption(name:String) {
		switch (name) {
			case 'Hitsound Volume:':
				if (ClientPrefs.settings.get("hitsoundVolume") > 0)
					FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.settings.get("hitsoundVolume"));
			case 'Perfect Hit Window:' | 'Sick Hit Window:' | 'Good Hit Window:' | 'Bad Hit Window:' | 'Shit Hit Window:':
				var prevLine:Float = 0;
				for (i=>option in windowOptions) {
					option.minValue = windowDefaultMins[i];
					option.maxValue = windowDefaultMaxes[i];
					//clamp the mins/maxes so you cant do weird shit
					if (windowOptions[i-1] != null) {
						if (windowOptions[i-1].maxValue > option.minValue) option.minValue = windowOptions[i-1].maxValue;
						//if (windowOptions[i-1].getValue() < option.minValue) option.minValue = windowOptions[i-1].getValue() + 1;
					}
					if (windowOptions[i+1] != null) {
						if (windowOptions[i+1].minValue < option.maxValue) option.maxValue = windowOptions[i+1].minValue;
						//if (windowOptions[i+1].getValue() > option.maxValue) option.maxValue = windowOptions[i+1].getValue() - 1;
					}
					//setGraphicSize makes me want to die so im gonna...
					var pixels = windowBar.pixels;
					for (y in 0...pixels.height) {
						if (y / pixels.height <= option.getValue() / pixels.height && y / pixels.height > prevLine)
							for (x in 0...pixels.width)
								pixels.setPixel32(x, y, windowColours[i]);
						else if (y / pixels.height > option.getValue() / pixels.height)
							for (x in 0...pixels.width)
								pixels.setPixel32(x, y, windowColours[windowColours.length-1]);
					}
					prevLine = option.getValue() / pixels.height;
				}
		}
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
	var iconAnim:String = 'Swing';
	var rating:FlxSprite;
    var skinArr:Array<String> = ['FNF', 'Denpa', 'Kade'];

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
		option.onChange = changeOption;

		var option:Option = new Option('Anti-Aliasing',
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.onChange = changeOption; //Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Watermarks',
			"If checked, Denpa Engine Watermarks will be enabled, as well as the Song Credits.",
			'watermarks',
			'bool',
			true);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool',
			true);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Note Splashes',
			"If unchecked, hitting \"Sick!\" notes won't show particles.",
			'noteSplashes',
			'bool',
			true);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Icon Animation:',
			"What animation should the healthbar icons do?",
			'iconAnim',
			'string',
			'Swing',
			['Swing', 'Snap', 'Stretch', 'Bop', 'Old', 'None']);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Animate Mouse',
		'If unchecked, mouse will not play any animations on clicking or scrolling.',
		'animateMouse',
		'bool',
		true);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Hide HUD',
			'If checked, hides most HUD elements.',
			'hideHud',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Hide Rating Pop-ups',
			'If checked, the rating pop-ups will no longer appear.',
			'hideRating',
			'bool',
			false);
		addOption(option);

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
							pushModSkinsToList(modSplit[0]);
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
			pushModSkinsToList(folder);
		}
		#end

		var option:Option = new Option('Rating Skin:',
			"What skin do you want?",
			'uiSkin',
			'string',
			'FNF',
			skinArr);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Score Display:',
			"What engine's score display do you want?",
			'scoreDisplay',
			'string',
			'Psych',
			['Psych', 'Kade', 'Sarvente', 'FPS+', 'FNF+', 'FNM', 'Vanilla', 'None']);
		addOption(option);
		
		var option:Option = new Option('Score Text Zoom',
			"If checked, the score text will zoom in when you hit a note.",
			'scoreZoom',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Ratings Display',
			"If checked, a display showing how many Perfects, Sicks, Etc. will be enabled.",
			'ratingsDisplay',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Time Bar Format:',
			"What format should the time bar be in?",
			'timeBarType',
			'string',
			'Time Left',
			['Time Left', 'Time Elapsed', 'Elapsed / Left', 'Song Name', 'Time Left (No Bar)', 'Time Elapsed (No Bar)', 'Elapsed / Left (No Bar)', 'Disabled']);
		addOption(option);

		super();

		addScrollers(true);

		shouldZoom = ClientPrefs.settings.get("camZooms");

		floatyTxt = new FlxText(FlxG.width, FlxG.height/2 - 100, 0, Main.denpaEngineVersion.formatted);
		floatyTxt.scrollFactor.set();
		floatyTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		floatyTxt.visible = false;
		floatyTxt.x = (descBox.x + descBox.width/2) - floatyTxt.width/2;
		add(floatyTxt);

		noteSplash = new FlxSprite(FlxG.width, FlxG.height/2 - 200);
		noteSplash.frames = Paths.getSparrowAtlas('splashes/noteSplashes');
		noteSplash.animation.addByPrefix('splash1', 'note splash A 1', 24, false);
		noteSplash.animation.addByPrefix('splash2', 'note splash B 1', 24, false);
		noteSplash.animation.addByPrefix('splash3', 'note splash C 1', 24, false);
		noteSplash.animation.addByPrefix('splash4', 'note splash D 1', 24, false);
		noteSplash.animation.play('splash1');
		noteSplash.visible = false;
		noteSplash.x -= noteSplash.width*1.5;
		add(noteSplash);

		icon = new HealthIcon('bf', true);
		icon.x = FlxG.width - 300;
		icon.y = FlxG.height/2 - 75;
		icon.visible = false;
		add(icon);

		rating = new FlxSprite(FlxG.width - 400, FlxG.height/2 - 60).loadGraphic(Paths.image('ratings/sick-' + ClientPrefs.settings.get("uiSkin").toLowerCase()));
		rating.visible = false;
		rating.scale.set(0.6,0.6);
		rating.updateHitbox();
		add(rating);

		bgScroll.visible = !ClientPrefs.settings.get("lowQuality");
		bgScroll2.visible = !ClientPrefs.settings.get("lowQuality");
	}

	var exiting = false;
	override function beatHit() {
		super.beatHit();
		if (exiting) return;
		if (canZoom && shouldZoom) {
			if (curBeat % 2 == 0) this.cameras[0].zoom += 0.015;
		}
		if (noteSplash != null && noteSplash.visible) {
			noteSplash.animation.play('splash${FlxG.random.int(1,4)}');
		}
		if (icon != null && icon.visible) icon.bop({curBeat: curBeat});
	}

	override function destroy() {
		FlxG.mouse.visible = false;
		exiting = true;
		super.destroy();
	}

	override function changeSelection(change:Int = 0) {
		super.changeSelection(change);
		if (floatyTxt != null) {
			floatyTxt.visible = false;
			if (optionsArray[curSelected].name == 'Watermarks') {
				floatyTxt.visible = ClientPrefs.settings.get("watermarks");
			}
		}

		if (noteSplash != null) {
			noteSplash.visible = false;
			if (optionsArray[curSelected].name == 'Note Splashes') {
				noteSplash.visible = ClientPrefs.settings.get("noteSplashes");
			}
		}

		if (icon != null) {
			icon.visible = false;
			if (optionsArray[curSelected].name == 'Icon Animation:') {
				icon.visible = true;
			}
		}

		if (rating != null) {
			rating.visible = false;
			if (optionsArray[curSelected].name == 'Rating Skin:') {
				rating.visible = true;
			}
		}
			
		canZoom = false;
		if (optionsArray[curSelected].name == 'Camera Zooms') {
			canZoom = true;
		}

		FlxG.mouse.visible = false;
		if (optionsArray[curSelected].name == 'Animate Mouse') {
			FlxG.mouse.visible = true;
		}
	}

	var elapsedtime:Float = 0;
	override function update(elapsed) {
		super.update(elapsed);
		elapsedtime += elapsed;
		this.cameras[0].zoom = FlxMath.lerp(1, this.cameras[0].zoom, CoolUtil.clamp(1 - (elapsed * 3.125), 0, 1));
		if (floatyTxt != null) {
			floatyTxt.y += FlxMath.fastSin(elapsedtime)/4;
		}
	}

	#if MODS_ALLOWED
	private var modsAdded:Array<String> = [];
	function pushModSkinsToList(folder:String)
	{
		if(modsAdded.contains(folder)) return;

		var skinFile:String = null;
		if(folder != null && folder.trim().length > 0) skinFile = Paths.mods(folder + '/data/skins.txt');
		else skinFile = Paths.mods('data/skins.txt');

		if (FileSystem.exists(skinFile))
		{
			var firstarray:Array<String> = File.getContent(skinFile).split('::');
			for (skin in firstarray)
				skinArr.push(skin);
		}
		modsAdded.push(folder);
	}
	#end

	function changeOption(name:String) {
		switch (name) {
			case 'Camera Zooms':
				shouldZoom = ClientPrefs.settings.get("camZooms");
			case 'Song Credits':
				if (floatyTxt != null)
					floatyTxt.visible = ClientPrefs.settings.get("watermarks");
			case 'Note Splashes':
				if (noteSplash != null) {
					noteSplash.visible = ClientPrefs.settings.get("noteSplashes");
					noteSplash.animation.play('splash${FlxG.random.int(1,4)}');
				}
			case 'Icon Animation:':
				iconAnim = ClientPrefs.settings.get("iconAnim");
			case 'Rating Skin:':
				if (rating != null)
					rating.loadGraphic(Paths.image('ratings/sick-' + ClientPrefs.settings.get("uiSkin").toLowerCase()));
			case 'Animate Mouse':
				//if it complains about this not being a real value, rest assured its just vsc being vsc
				flixel.input.mouse.FlxMouse.animated = ClientPrefs.settings.get("animateMouse");
			case 'Anti-Aliasing':
				for (sprite in members)
					if (sprite != null && sprite is FlxSprite && !(sprite is FlxText))
						cast (sprite, FlxSprite).antialiasing = ClientPrefs.settings.get("globalAntialiasing");

				FlxSprite.defaultAntialiasing = ClientPrefs.settings.get("globalAntialiasing");
				FlxG.mouse.unload();
				flixel.input.mouse.FlxMouse.antialiasing = ClientPrefs.settings.get("globalAntialiasing");
				FlxG.mouse.load();
			case 'Low Quality':
				bgScroll.visible = !ClientPrefs.settings.get("lowQuality");
				bgScroll2.visible = !ClientPrefs.settings.get("lowQuality");
		}
	}
}

/**
* State used to adjust misc settings, which do not fit in the other classifications.
*/
class MiscSettingsSubState extends BaseOptionsMenu
{
	public static var instance:MiscSettingsSubState;
	public function new()
	{
		title = 'Misc Settings';
		rpcTitle = 'Misc Settings Menu'; //for Discord Rich Presence

		var option:Option = new Option('Pause Screen Song:',
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			'OVERDOSE',
			['None', 'Breakfast', 'Property Surgery', 'OVERDOSE']);
		addOption(option);
		option.onChange = changeOption;

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

		var option:Option = new Option('Ghost Tapping Miss Animation',
			"If checked, the player will do miss animations when you press the arrows while Ghost Tapping is enabled. If unchecked, the player will do normal sing animations instead.",
			'gsMiss',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Icon Flinching',
			"If checked, Missing will cause the player's icon to show the dying animation temporarily.",
			'flinching',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Disable Botplay Icon',
			"If checked, The botplay icon will be disabled and not replace the normal icon on botplay.",
			'disableBotIcon',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('OG Healthbar',
			"If checked, the healthbar's colours will be set to Red/Green globally.",
			'ogHp',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Game Camera Ratings',
			'If checked, the rating popups will be in the game camera, instead of the HUD.',
			'wrongCamera',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Timing Popup',
			'If checked, text displaying your Millisecond timing will appear when hitting a note.',
			'msPopup',
			'bool',
			true);
		addOption(option);

		//! Unfinished (Still needs colour functionality fixed)
		var option:Option = new Option('CrossFade Options',
			"Open the CrossFade options submenu.",
			'crossFadeLink',
			'link',
			false);
		addOption(option);
		option.onChange = changeOption;

		var option:Option = new Option('Secret Options',
			"Open the secret options submenu.",
			'secretLink',
			'link',
			false);
		addOption(option);
		option.onChange = changeOption;

		super();

		addScrollers();

		instance = this;
	}

	var changedMusic:Bool = false;
	function changeOption(name:String) {
		switch (name) {
			case 'Pause Screen Song:':
				if(ClientPrefs.settings.get("pauseMusic") == 'None')
					FlxG.sound.music.volume = 0;
				else
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.settings.get("pauseMusic"))));
		
				changedMusic = true;
			case 'CrossFade Options':
				stopLerping = true;
				for (option in grpOptions) {
					if (option.text != 'CrossFade Options') {
						option.align = 'none';
						FlxTween.tween(option, {x: option.x - 1280}, 0.48, {ease: FlxEase.expoIn});
					} else {
						option.align = 'center';
						FlxTween.tween(option, {y: option.y - 720}, 0.66, {
							startDelay: 0.15,
							ease: FlxEase.expoIn,
							onComplete: _ -> {
								persistentUpdate = false;
								openSubState(new CrossFadeSettingsSubState());
							}
						});
					}
				}
			case 'Secret Options':
				/*var possibleSounds = ['bfBeep', 'cancelMenu', 'scrollMenu', 'confirmMenu', 'invalidJSON'];
				FlxG.sound.play(Paths.sound(possibleSounds[FlxG.random.int(0, possibleSounds.length-1)]));*/
				Main.updateColorblindFilter(FlxG.random.bool(45) ? 8 : FlxG.random.int(0, 7));
		}
	}

	override function destroy()
	{
		if(changedMusic) FlxG.sound.playMusic(Paths.music('msm'));
		instance = null;
		super.destroy();
	}
}

/**
* State used to adjust misc settings, which do not fit in the other classifications.
*/
class CrossFadeSettingsSubState extends MusicBeatSubstate
{
	var boyfriend:Boyfriend;
	var crossfade:Boyfriend;
	var selectedOption:Int = 0;
	var selectedVertical:Int = 0;
	var lastOption:Int = 0; //we use this one so you can scroll inside the suboptions without scrolling the entire thing
	var crossfadeTween:FlxTween = null;
	var split:Bool = false;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpAttached:FlxTypedGroup<AttachedText>;
	final optionsShit:Map<String, Array<String>> = [
		'Mode' => ['Default', 'Static', 'Subtle', 'Eccentric', 'Off'],
		'Color' => ['Healthbar', 'RGB', 'HSB']
	];
	public function new()
	{
		super();

		var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.screenCenter();
		add(bg);

		var bgScroll:FlxBackdrop = null;
		var bgScroll2:FlxBackdrop = null;
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll2);
		}

		var gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		boyfriend = new Boyfriend(0, 0);
		add(boyfriend);
		resetBoyfriend();

		crossfade = new Boyfriend(boyfriend.x, boyfriend.y);
		insert(members.indexOf(boyfriend) - 1, crossfade);
		resetCrossfade();

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpAttached = new FlxTypedGroup<AttachedText>();
		add(grpAttached);
		for (i=>name in ['Mode', /*'Color',*/ 'Alpha', 'Fade Time'])
		{
			var alphabet = new Alphabet(0, 500, name, true, false, 0.05, 1);
			alphabet.x = FlxG.width/2 - alphabet.width/2;
			alphabet.ID = i;
			alphabet.align = 'none';
			alphabet.targetY = 1.15;
			grpOptions.add(alphabet);
			switch (name) {
				case 'Mode':
					var attached = new AttachedText(ClientPrefs.settings.get('crossFadeData')[0], 0, 30, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);
				/*case 'Color':
					var attached = new AttachedText(ClientPrefs.settings.get('crossFadeData')[1], 0, 20, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);

					var attached = new AttachedText('Red: ' + ClientPrefs.settings.get('crossFadeData')[2][0], 0, 70, false, 0.7);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.alignAdd = -350;
					attached.targetY = 2;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);

					var attached = new AttachedText('Green: ' + ClientPrefs.settings.get('crossFadeData')[2][1], 0, 70, false, 0.7);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 2;
					attached.ID = 1;
					attached.yMult = i;
					grpAttached.add(attached);

					var attached = new AttachedText('Blue: ' + ClientPrefs.settings.get('crossFadeData')[2][2], 0, 70, false, 0.7);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.alignAdd = 350;
					attached.targetY = 2;
					attached.ID = 2;
					attached.yMult = i;
					grpAttached.add(attached);*/
				case 'Alpha':
					var attached = new AttachedText(ClientPrefs.settings.get('crossFadeData')[3], 0, 30, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);
				case 'Fade Time':
					var attached = new AttachedText(ClientPrefs.settings.get('crossFadeData')[4], 0, 30, false, 0.9);
					attached.copyAlpha = false;
					attached.sprTracker = alphabet;
					attached.targetY = 1;
					attached.ID = 0;
					attached.yMult = i;
					grpAttached.add(attached);
			}
		}
		updateRGBTexts();

		var titleText:FlxText = new FlxText(0, 20, 0, "Crossfade", 24);
		titleText.setFormat(Paths.font("calibri-regular.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xff59136d);
		titleText.x += 14;
		titleText.y -= 3;

		var titleBG:FlxSprite = new FlxSprite(0,30).loadGraphic(Paths.image('oscillators/optionsbg'));
		titleBG.setGraphicSize(Std.int(titleText.width*1.225), Std.int(titleText.height/1.26));
		titleBG.updateHitbox();
		add(titleBG);
		add(titleText);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
	}

	override function update(elapsed:Float) {
		Conductor.songPosition = FlxG.sound.music.time;
		final lerpVal:Float = CoolUtil.clamp(elapsed * 9.6, 0, 1);
		grpOptions.forEach(alphabet -> {
			alphabet.x = FlxMath.lerp(alphabet.x, (FlxG.width/2 * ((alphabet.ID - lastOption)+1)) - alphabet.width/2, lerpVal);
			alphabet.alpha = (lastOption == alphabet.ID ? 1 : 0.6);
		});
		grpAttached.forEach(attached -> {
			attached.offsetX = FlxMath.lerp(attached.offsetX, attached.alignAdd + (attached.sprTracker.width/2 - attached.width/2), lerpVal);
			attached.alpha = ((selectedVertical == attached.targetY && selectedOption == attached.ID && attached.yMult == lastOption) ? 1 : 0.6);
		});
		super.update(elapsed);
		//if (ClientPrefs.controllerEnabled) checkInputs();
	}

	override function beatHit() {
		super.beatHit();
		if (boyfriend == null || boyfriend.animation == null || boyfriend.animation.curAnim.name.startsWith('sing')) return;
		boyfriend.dance();
	}

	function keyDown(event:KeyboardEvent) {
		var eventKey:FlxKey = event.keyCode;
		if (eventKey == NONE) return;
		switch (eventKey) {
			case SPACE:
				split = !split;
				resetBoyfriend();
				resetCrossfade();
				return;
			default:
				//kys
		}
		checkInputs();
	}

	function checkInputs() {
		if (control('back')) close();
		if (control('ui_left_p')) changeOption(-1);
		if (control('ui_right_p')) changeOption(1);
		if (control('ui_up_p')) changeVertical(-1);
		if (control('ui_down_p')) changeVertical(1);
		if (control('reset') && selectedVertical > 0) reset();
		/*if (control('accept') && selectedVertical == 2) {
			changingRGB = !changingRGB;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}*/
		final pressedArrows:Array<Bool> = [control('note_41_p'), control('note_42_p'), control('note_43_p'), control('note_44_p')];
		final dirs:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
		for (i=>pressed in pressedArrows) if (pressed) playCrossfade('sing${dirs[i]}');
	}

	var changingRGB:Bool = false;
	function changeOption(change:Int = 0) {
		if (selectedVertical != 1 && !changingRGB) {
			selectedOption += change;
			final max = (selectedVertical == 0 ? /*3*/2 : (selectedVertical == 1 ? 0 : 2));
			if (selectedOption > max) selectedOption = 0;
			if (selectedOption < 0) selectedOption = max;
			if (selectedVertical < 1) lastOption = selectedOption;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		} else {
			changeData(change);
		}
	}

	function changeData(change:Int) {
		//! THIS IS A MESS
		switch (lastOption) {
			case 0:
				grpAttached.forEach(attached -> {
					if (attached.yMult == 0) {
						var arr = optionsShit.get('Mode');
						var index = arr.indexOf(attached.text);
						index += change;
						if (index > arr.length-1) index = 0;
						if (index < 0) index = arr.length-1;
						attached.changeText(arr[index]);
						var curDat = ClientPrefs.settings.get('crossFadeData');
						curDat[0] = arr[index];
						ClientPrefs.settings.set('crossFadeData', curDat);
					}
				});
			/*case 1:
				if (selectedVertical == 1) {
					grpAttached.forEach(attached -> {
						if (attached.yMult == 1 && attached.targetY == 1) {
							var arr = optionsShit.get('Color');
							var index = arr.indexOf(attached.text);
							index += change;
							if (index > arr.length-1) index = 0;
							if (index < 0) index = arr.length-1;
							attached.changeText(arr[index]);
							var curDat = ClientPrefs.settings.get('crossFadeData');
							curDat[1] = arr[index];
							ClientPrefs.settings.set('crossFadeData', curDat);
						}
					});
					updateRGBMax();
					updateRGBTexts();
				} else {
					var curDat = ClientPrefs.settings.get('crossFadeData');
					curDat[2][selectedOption] += change;
					ClientPrefs.settings.set('crossFadeData', curDat);
					updateRGBMax();
					updateRGBTexts();
				}*/
			case /*2*/1:
				grpAttached.forEach(attached -> {
					if (attached.yMult == /*2*/1) {
						var curDat = ClientPrefs.settings.get('crossFadeData');
						curDat[3] += 0.05 * change;
						curDat[3] = FlxMath.bound(curDat[3], 0.05, 1);
						ClientPrefs.settings.set('crossFadeData', curDat);
						attached.changeText(Std.string(curDat[3]));
					}
				});
			case /*3*/2:
				grpAttached.forEach(attached -> {
					if (attached.yMult == /*3*/2) {
						var curDat = ClientPrefs.settings.get('crossFadeData');
						curDat[4] += 0.05 * change;
						curDat[4] = FlxMath.bound(curDat[4], 0.05, 2);
						ClientPrefs.settings.set('crossFadeData', curDat);
						attached.changeText(Std.string(curDat[4]));
					}
				});
		}
		resetCrossfade();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
	}

	function reset() {
		switch (lastOption) {
			case 0:
				grpAttached.forEach(attached -> {
					if (attached.yMult == 0) {
						var curDat = ClientPrefs.settings.get('crossFadeData');
						curDat[0] = 'Default';
						attached.changeText(curDat[0]);
						ClientPrefs.settings.set('crossFadeData', curDat);
					}
				});
			/*case 1:
				if (selectedVertical == 1) {
					grpAttached.forEach(attached -> {
						if (attached.yMult == 1 && attached.targetY == 1) {
							var curDat = ClientPrefs.settings.get('crossFadeData');
							curDat[1] = 'Healthbar';
							attached.changeText(curDat[1]);
							ClientPrefs.settings.set('crossFadeData', curDat);
						}
					});
					updateRGBMax();
					updateRGBTexts();
				} else {
					var curDat = ClientPrefs.settings.get('crossFadeData');
					curDat[2][selectedOption] = 255;
					ClientPrefs.settings.set('crossFadeData', curDat);
					updateRGBMax();
					updateRGBTexts();
				}*/
			case /*2*/1:
				grpAttached.forEach(attached -> {
					if (attached.yMult == /*2*/1) {
						var curDat = ClientPrefs.settings.get('crossFadeData');
						curDat[3] = 0.3;
						ClientPrefs.settings.set('crossFadeData', curDat);
						attached.changeText(Std.string(curDat[3]));
					}
				});
			case /*3*/2:
				grpAttached.forEach(attached -> {
					if (attached.yMult == /*3*/2) {
						var curDat = ClientPrefs.settings.get('crossFadeData');
						curDat[4] = 0.35;
						ClientPrefs.settings.set('crossFadeData', curDat);
						attached.changeText(Std.string(curDat[4]));
					}
				});
		}
		resetCrossfade();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.3);
	}

	function updateRGBMax() {
		/*var curDat = ClientPrefs.settings.get('crossFadeData');
		final max = (curDat[1] == 'HSB' ? 360 : 255);
		if (curDat[2][0] > max) curDat[2][0] = 0;
		if (curDat[2][0] < 0) curDat[2][0] = max;
		final max = (curDat[1] == 'HSB' ? 100 : 255);
		if (curDat[2][1] > max) curDat[2][1] = 0;
		if (curDat[2][1] < 0) curDat[2][1] = max;
		final max = (curDat[1] == 'HSB' ? 100 : 255);
		if (curDat[2][2] > max) curDat[2][2] = 0;
		if (curDat[2][2] < 0) curDat[2][2] = max;
		ClientPrefs.settings.set('crossFadeData', curDat);*/
	}

	function updateRGBTexts() {
		/*grpAttached.forEach(attached -> {
			if (attached.targetY == 2) {
				switch (attached.ID) {
					case 0:
						switch (ClientPrefs.settings.get('crossFadeData')[1]) {
							case 'Healthbar':
								attached.changeText('N/A');
							case 'RGB':
								attached.changeText('Red: ${ClientPrefs.settings.get('crossFadeData')[2][0]}');
							case 'HSB':
								attached.changeText('Hue: ${ClientPrefs.settings.get('crossFadeData')[2][0]}');
						}
					case 1:
						switch (ClientPrefs.settings.get('crossFadeData')[1]) {
							case 'Healthbar':
								attached.changeText('N/A');
							case 'RGB':
								attached.changeText('Green: ${ClientPrefs.settings.get('crossFadeData')[2][1]}');
							case 'HSB':
								attached.changeText('Saturation: ${ClientPrefs.settings.get('crossFadeData')[2][1]}');
						}
					case 2:
						switch (ClientPrefs.settings.get('crossFadeData')[1]) {
							case 'Healthbar':
								attached.changeText('N/A');
							case 'RGB':
								attached.changeText('Blue: ${ClientPrefs.settings.get('crossFadeData')[2][2]}');
							case 'HSB':
								attached.changeText('Brightness: ${ClientPrefs.settings.get('crossFadeData')[2][2]}');
						}
				}
			}
		});*/
	}

	function changeVertical(change:Int = 0) {
		selectedVertical += change;
		var max = (lastOption == 1 ? 2 : 1);
		if (selectedVertical < 0) selectedVertical = 0;
		if (selectedVertical > max) selectedVertical = max;
		if (selectedVertical > 0) selectedOption = 0;
		else selectedOption = lastOption;
		changingRGB = false;
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
	}

	function playCrossfade(anim:String = 'singRIGHT') {
		resetCrossfade();
		if (boyfriend == null || boyfriend.animation == null || crossfade == null || crossfade.animation == null) return;

		boyfriend.playAnim(anim, true);
		crossfade.playAnim(anim, true);
		switch (ClientPrefs.settings.get('crossFadeData')[0])
		{
			case 'Static':
				crossfade.x = boyfriend.x + -60;
				crossfade.y = boyfriend.y - 48;
			case 'Subtle':
				crossfade.x = boyfriend.x;
				crossfade.y = boyfriend.y;
			case 'Eccentric':
				crossfade.x = boyfriend.x + FlxG.random.float(-20,90);
				crossfade.y = boyfriend.y + FlxG.random.float(-80, 80);
			default:
				crossfade.x = boyfriend.x + FlxG.random.float(0,60);
				crossfade.y = boyfriend.y + FlxG.random.float(-50, 50);
		}
		if (split) crossfade.x += FlxG.width * 0.6;

		final fuck = FlxG.random.bool(70);
		final velo = 12 * (ClientPrefs.settings.get('crossFadeData')[0] == 'Eccentric' ? 8 : 5);
		switch (ClientPrefs.settings.get('crossFadeData')[0])
		{
			case 'Static' | 'Subtle':
				crossfade.velocity.x = 0;
			case 'Eccentric':
				crossfade.velocity.x = (fuck ? velo : -velo);
				crossfade.acceleration.x = (crossfade.velocity.x > 0 ? FlxG.random.int(25,75) : FlxG.random.int(-25,-75));
			default:
				crossfade.velocity.x = (fuck ? velo : -velo);
				crossfade.acceleration.x = (crossfade.velocity.x > 0 ? FlxG.random.int(4,12) : FlxG.random.int(-4,-12));
		}
		crossfadeTween = FlxTween.tween(crossfade, {alpha: 0}, ClientPrefs.settings.get('crossFadeData')[4], {
			onComplete: _ -> {
				resetBoyfriend();
				resetCrossfade();
			}
		});
	}

	function resetCrossfade() {
		if (crossfadeTween != null) {
			crossfadeTween.cancel();
			crossfadeTween = null;
		}
		if (crossfade == null || crossfade.animation == null) return;
		crossfade.velocity.set(0, 0);
		crossfade.acceleration.set(0, 0);
		crossfade.setPosition((split ? boyfriend.x + FlxG.width * 0.6 : boyfriend.x), boyfriend.y);
		crossfade.alpha = ClientPrefs.settings.get('crossFadeData')[3];
		crossfade.visible = !(ClientPrefs.settings.get('crossFadeData')[0] == 'Off');
		crossfade.color = 0xFF1b008c;
		//?? does not work ??
		var curDat:Array<Dynamic> = cast ClientPrefs.settings.get('crossFadeData');
		if (curDat[1] == 'RGB')
			crossfade.color = FlxColor.fromRGB(curDat[1][0], curDat[1][1], curDat[1][2]);
		if (curDat[1] == 'HSB')
			crossfade.color = FlxColor.fromHSB(curDat[1][0], curDat[1][1]/100, curDat[1][2]/100);
		/*crossfade.color = (ClientPrefs.settings.get('crossFadeData')[1] == 'Healthbar' ?0xFF1b008c : 
		ClientPrefs.settings.get('crossFadeData')[1] == 'RGB' ? 
			FlxColor.fromRGB(ClientPrefs.settings.get('crossFadeData')[1][0], ClientPrefs.settings.get('crossFadeData')[1][1], ClientPrefs.settings.get('crossFadeData')[1][2]) : 
			FlxColor.fromHSB(ClientPrefs.settings.get('crossFadeData')[1][0], ClientPrefs.settings.get('crossFadeData')[1][1]/100, ClientPrefs.settings.get('crossFadeData')[1][2]/100));*/
		crossfade.dance();
	}

	function resetBoyfriend() {
		if (boyfriend == null || boyfriend.animation == null) return;
		boyfriend.screenCenter(X);
		boyfriend.y = FlxG.height * 0.13;
		boyfriend.dance();
		if (split) boyfriend.x -= FlxG.width * 0.3;
	}

	override function close() {
		if (crossfadeTween != null) {
			crossfadeTween.cancel();
			crossfadeTween = null;
		}
		crossfade.destroy();
		boyfriend.destroy();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		ClientPrefs.saveSettings();
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		super.close();
		if (MiscSettingsSubState.instance == null) return;
		MiscSettingsSubState.instance.persistentUpdate = true;
		for (option in MiscSettingsSubState.instance.grpOptions) {
			option.align = 'left';
		}
	}
}

class ControlsSubState extends MusicBeatSubstate {
	private static var curSelected:Int = -1;
	private static var curAlt:Bool = false;

	private static var defaultKey:String = 'Reset to Default Keys';
	private var bindLength:Int = 0;

	var optionShit:Array<Dynamic> = [
		['NOTES'],
		['Left', 'note_41'],
		['Down', 'note_42'],
		['Up', 'note_43'],
		['Right', 'note_44'],
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
		['Manual', 'manual'],
		[''],
		['VOLUME'],
		['Mute', 'volume_mute'],
		['Up', 'volume_up'],
		['Down', 'volume_down'],
		[''],
		['DEBUG'],
		['Editor 1', 'debug_1'],
		['Editor 2', 'debug_2'],
		[''],
		['MULTIKEY'],
		[''],
		['1K'],
		['Center', 'note_11'],
		[''],
		['2K'],
		['Left', 'note_21'],
		['Right', 'note_22'],
		[''],
		['3K'],
		['Left', 'note_31'],
		['Center', 'note_32'],
		['Right', 'note_33'],
		[''],
		['5K'],
		['Left', 'note_51'],
		['Down', 'note_52'],
		['Center', 'note_53'],
		['Up', 'note_54'],
		['Right', 'note_55'],
		[''],
		['6K'],
		['Left 1', 'note_61'],
		['Up', 'note_62'],
		['Right 1', 'note_63'],
		['Left 2', 'note_64'],
		['Down', 'note_65'],
		['Right 2', 'note_66'],
		[''],
		['7K'],
		['Left 1', 'note_71'],
		['Up', 'note_72'],
		['Right 1', 'note_73'],
		['Center', 'note_74'],
		['Left 2', 'note_75'],
		['Down', 'note_76'],
		['Right 2', 'note_77'],
		[''],
		['8K'],
		['Left 1', 'note_81'],
		['Down 1', 'note_82'],
		['Up 1', 'note_83'],
		['Right 1', 'note_84'],
		['Left 2', 'note_85'],
		['Down 2', 'note_86'],
		['Up 2', 'note_87'],
		['Right 2', 'note_88'],
		[''],
		['9K'],
		['Left 1', 'note_91'],
		['Down 1', 'note_92'],
		['Up 1', 'note_93'],
		['Right 1', 'note_94'],
		['Center', 'note_95'],
		['Left 2', 'note_96'],
		['Down 2', 'note_97'],
		['Up 2', 'note_98'],
		['Right 2', 'note_99']
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
	var tipBox:AttachedSprite.NGAttachedSprite;
	var tipTxt:FlxText;
	var tipTxtTween:FlxTween = null;

	public function new() {
		super();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.screenCenter();
		add(bg);

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll2);
		}

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
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

		tipTxt = new FlxText(FlxG.width + 10, 0, 0, 'Press any key to rebind...', 32).setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.NONE, FlxColor.BLACK);
		tipTxt.screenCenter(Y);
		tipTxt.scrollFactor.set();
		tipTxt.active = false;

		tipBox = new NGAttachedSprite(Std.int(tipTxt.width + 10), Std.int(tipTxt.height + 10), 0xff000000);
		tipBox.alpha = 0.6;
		tipBox.xAdd = tipBox.yAdd = -5;
		tipBox.sprTracker = tipTxt;
		add(tipBox);
		add(tipTxt);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
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

			if(FlxG.mouse.wheel != 0)
			{
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}

			if (controls.BACK) {
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
						grpInputsAlt[getInputTextNum()].alpha = 0.06;
					} else {
						grpInputs[getInputTextNum()].alpha = 0.06;
					}
					tipTxt.screenCenter(Y);
					tipTxt.y -= 220;
					tipTxt.x = FlxG.width + 10;
					if (tipTxtTween != null) tipTxtTween.cancel();
					tipTxtTween = FlxTween.tween(tipTxt, {x: tipTxt.x - (tipTxt.width + 20)}, 0.4, {ease: FlxEase.sineInOut});
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
				keysArray.remove(NONE); //lazy yes but i dont know how to do this without doing = null which is dumb
				ClientPrefs.keyBinds.set(optionShit[curSelected][1], keysArray);

				reloadKeys();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				tipTxt.screenCenter(Y);
				tipTxt.y -= 220;
				if (tipTxtTween != null) tipTxtTween.cancel();
				tipTxt.x = FlxG.width + 10;
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
		var name1 = InputFormatter.getKeyName(keys[0]);
		if (name1 == null || name1.length < 1) name1 = '---';
		var text1 = new AttachedText(name1, 400, -55);
		text1.setPosition(optionText.x + 400, optionText.y - 55);
		text1.sprTracker = optionText;
		grpInputs.push(text1);
		add(text1);

		var name2 = InputFormatter.getKeyName(keys[1]);
		if (name2 == null || name2.length < 1) name2 = '---';
		var text2 = new AttachedText(name2, 650, -55);
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
