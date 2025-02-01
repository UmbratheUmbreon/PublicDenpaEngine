package options;

#if desktop
import Discord.DiscordClient;
#end
import Alphabet;
import Controls;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
* Base substate for all options substates.
*/
class BaseOptionsMenu extends MusicBeatSubstate
{
	private var curOption:Option = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Option>;

	public var grpOptions:FlxTypedGroup<Alphabet>;
	var lerpList:Array<Bool> = [];
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var boyfriend:Character = null;
	private var descBox:FlxSprite;
	private var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;

	public function new()
	{
		super();

		if(title == null) title = 'Options';
		if(rpcTitle == null) rpcTitle = 'Options Menu';
		
		#if desktop
		DiscordClient.changePresence(rpcTitle, null);
		#end
		
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF98f0f8;
		bg.screenCenter();
		add(bg);

		gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
		gradient.scrollFactor.set(0, 0);
		add(gradient);

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		var titleText:FlxText = new FlxText(0, 20, 0, title, 24);
		titleText.setFormat(Paths.font("calibri-regular.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0xff59136d);
		titleText.x += 22;
		titleText.y -= 3;

		var titleBG:FlxSprite = new FlxSprite(0,30).loadGraphic(Paths.image('oscillators/optionsbg'));
		titleBG.setGraphicSize(Std.int(titleText.width*1.225), Std.int(titleText.height/1.26));
		titleBG.updateHitbox();
		add(titleBG);
		add(titleText);

		descText = new FlxText(FlxG.width - 600, 600, 550, "", 24);
		descText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		descText.scrollFactor.set();
		//descText.borderSize = 2.4;

		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.9;
		add(descBox);
		add(descText);

		for (i in 0...optionsArray.length)
		{
			var optionText:Alphabet = new Alphabet(0, 70, optionsArray[i].name, optionsArray[i].type == 'link', false);
			optionText.x += 15;
			optionText.xAdd = 200;
			optionText.targetY = i;
			optionText.yMult = 100;
			optionText.yAdd = (optionText.isBold ? -35 : -90);
			lerpList.push(true);
			grpOptions.add(optionText);

			if(optionsArray[i].type == 'bool') {
				var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, optionsArray[i].getValue() == true);
				checkbox.sprTracker = optionText;
				checkbox.ID = i;
				checkbox.align = 'right';
				checkbox.offsetX = 12;
				checkbox.offsetY = 6;
				checkboxGroup.add(checkbox);
			} else if (optionsArray[i].type != 'link') {
				optionText.x -= 80;
				optionText.xAdd -= 80;
				var valueText:AttachedText = new AttachedText('' + optionsArray[i].getValue(), optionText.width + 80);
				valueText.sprTracker = optionText;
				valueText.copyAlpha = true;
				valueText.ID = i;
				grpTexts.add(valueText);
				optionsArray[i].setChild(valueText);
			}

			if(optionsArray[i].showBoyfriend && boyfriend == null)
			{
				reloadBoyfriend();
			}
			updateTextFrom(optionsArray[i]);
		}

		changeSelection();
		reloadCheckboxes();

		bg.color = SoundTestState.getDaColor();
		gradient.color = SoundTestState.getDaColor();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	public function addScrollers(bypass:Bool = false)
	{
		if (ClientPrefs.settings.get("lowQuality") && !bypass) {
			return;
		}

		bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
		bgScroll.velocity.set(29, 30);
		insert(members.indexOf(gradient), bgScroll);

		bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
		bgScroll2.velocity.set(-29, -30);
		insert(members.indexOf(gradient), bgScroll2);

		bgScroll.color = SoundTestState.getDaColor();
		bgScroll2.color = SoundTestState.getDaColor();
	}

	public function addOption(option:Option) {
		if(optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;
	var stopLerping:Bool = false;
	override function update(elapsed:Float)
	{
		final lerpVal:Float = CoolUtil.clamp(elapsed * 9.6, 0, 1);
		if (!stopLerping) {
			for (i=>item in grpOptions.members) {
				@:privateAccess {
					if (lerpList[i]) {
						item.y = FlxMath.lerp(item.y, (item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd, lerpVal);
						if(item.forceX != Math.NEGATIVE_INFINITY) {
							item.x = item.forceX;
						} else {
							item.x = FlxMath.lerp(item.x, (item.isBold ? 30 : 15) + item.alignAdd, lerpVal);
						}
					} else {
						item.y = ((item.scaledY * item.yMult) + (FlxG.height * 0.48) + item.yAdd);
						if(item.forceX != Math.NEGATIVE_INFINITY) {
							item.x = item.forceX;
						} else {
							item.x = ((item.isBold ? 30 : 15) + item.alignAdd);
						}
					}
				}
			}
		}

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		var shiftMult:Int = 1;

		if(FlxG.mouse.wheel != 0)
		{
			changeSelection(-shiftMult * FlxG.mouse.wheel);
		}

		if (controls.BACK) {
			close();
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		var lerpVal:Float = CoolUtil.clamp(elapsed * 12, 0, 1);
		descText.x = FlxMath.lerp(descText.x, FlxG.width - 600, lerpVal);
		descBox.x = FlxMath.lerp(descBox.x, FlxG.width - 610, lerpVal);

		if(nextAccept <= 0)
		{
			var usesCheckbox = true;
			if(curOption.type != 'bool' && curOption.type != 'link')
			{
				usesCheckbox = false;
			}

			if(usesCheckbox)
			{
				if(controls.ACCEPT)
				{
					FlxG.sound.play(Paths.sound((curOption.type == 'link' ? 'confirmMenu' : 'scrollMenu')));
					if (curOption.type == 'bool') curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			} else {
				if(controls.UI_LEFT || controls.UI_RIGHT) {
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);
					if(holdTime > 0.5 || pressed) {
						if(pressed) {
							var add:Dynamic = null;
							if(curOption.type != 'string') {
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch(curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if(holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch(curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}

								case 'string':
									var num:Int = curOption.curOption; //lol
									if(controls.UI_LEFT_P) --num;
									else num++;

									if(num < 0) {
										num = curOption.options.length - 1;
									} else if(num >= curOption.options.length) {
										num = 0;
									}

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); //lol
									//trace(curOption.options[num]);
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						} else if(curOption.type != 'string') {
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);
							if(holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

							switch(curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));
								
								case 'float' | 'percent':
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if(curOption.type != 'string') {
						holdTime += elapsed;
					}
				} else if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					clearHold();
				}
			}

			if(controls.RESET)
			{
				if (FlxG.keys.pressed.SHIFT) {
					for (i in 0...optionsArray.length)
					{
						var leOption:Option = optionsArray[i];
						leOption.setValue(leOption.defaultValue);
						if(leOption.type != 'bool')
						{
							if(leOption.type == 'string')
							{
								leOption.curOption = leOption.options.indexOf(leOption.getValue());
							}
							updateTextFrom(leOption);
						}
						leOption.change();
					}
				} else {
					curOption.setValue(curOption.defaultValue);
					if(curOption.type != 'bool')
					{
						if(curOption.type == 'string')
						{
							curOption.curOption = curOption.options.indexOf(curOption.getValue());
						}
						updateTextFrom(curOption);
					}
					curOption.change();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	function updateTextFrom(option:Option) {
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if(option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if(holdTime > 0.5) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		holdTime = 0;
	}
	
	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		descText.text = optionsArray[curSelected].description;
		descText.screenCenter(Y);
		descText.y += 270;
		descText.x = FlxG.width - 550;

		var bullShit:Int = 0;

		for (i=>item in grpOptions.members) {
			item.active = item.visible = lerpList[i] = true;
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
			}
			if (Math.abs(item.targetY) > 6 && !(curSelected == 0 || curSelected == optionsArray.length - 1)) {
				item.active = item.visible = lerpList[i] = false;
			}
		}
		for (checkbox in checkboxGroup) {
			checkbox.active = checkbox.visible = true;
			if (checkbox.sprTracker.visible == false) {
				checkbox.active = checkbox.visible = false;
			}
		}
		for (text in grpTexts) {
			text.alpha = 0.6;
			if(text.ID == curSelected) {
				text.alpha = 1;
			}
		}

		descBox.setPosition(FlxG.width - 560, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		if(boyfriend != null)
		{
			boyfriend.visible = optionsArray[curSelected].showBoyfriend;
		}
		curOption = optionsArray[curSelected]; //shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public function reloadBoyfriend()
	{
		var wasVisible:Bool = false;
		if(boyfriend != null) {
			wasVisible = boyfriend.visible;
			boyfriend.kill();
			remove(boyfriend);
			boyfriend.destroy();
		}

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		insert(3, boyfriend);
		boyfriend.visible = wasVisible;
	}

	override function beatHit() {
		super.beatHit();
		if (boyfriend != null)
			boyfriend.dance();
	} 

	function reloadCheckboxes() {
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}