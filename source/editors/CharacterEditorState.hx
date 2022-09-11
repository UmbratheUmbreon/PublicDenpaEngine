package editors;

import flixel.math.FlxPoint;
#if desktop
import Discord.DiscordClient;
#end
import animateatlas.AtlasFrameMaker;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxRandom;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.Json;
import Character;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import lime.system.Clipboard;
import flixel.animation.FlxAnimation;

#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

/**
	*DEBUG MODE
 */
class CharacterEditorState extends MusicBeatState
{
	var char:Character;
	var gf:Character;
	var dad:Character;
	var ghostChar:Character;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var gfLayer:FlxTypedGroup<Character>;
	var fuckLayer:FlxTypedGroup<FlxSprite>;
	var dadLayer:FlxTypedGroup<Character>;
	var charLayer:FlxTypedGroup<Character>;
	var dumbTexts:FlxTypedGroup<FlxText>;
	//var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var prevCamFollow:FlxPoint;
	var prevCamFollowPos:FlxObject;
	var stageDropDown:FlxUIDropDownMenuCustom;
	var stages:Array<String> = ['stage', 'spooky', 'philly', 'limo', 'mall', 'mallEvil', 'school', 'schoolEvil', 'tank'];
	var currentStage:String = 'stage';

	var xPositioningOffset:Float = 0;
	var yPositioningOffset:Float = 0;

	var gfVersion:String;
	var gfXPositioningOffset:Float = 0;
	var gfYPositioningOffset:Float = 0;

	var dadVersion:String;
	var dadXPositioningOffset:Float = 0;
	var dadYPositioningOffset:Float = 0;

	var fastCar:BGSprite;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;

	var bgGirls:BackgroundGirls;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBGBG:FlxSprite;
	var healthBarBG:FlxSprite;
	var healthBarBGM:FlxSprite;
	var healthBarBGB:FlxSprite;

	override function create()
	{
		if (PlayState.curStage != null && PlayState.curStage != '') currentStage = PlayState.curStage;
		var musicID:Int = FlxG.random.int(0, 2);
		switch (musicID)
		{
			case 0:
				FlxG.sound.playMusic(Paths.music('shop'), 0.5);
				Conductor.changeBPM(143);
			case 1:
				FlxG.sound.playMusic(Paths.music('sneaky'), 0.5);
				Conductor.changeBPM(108);
			case 2:
				FlxG.sound.playMusic(Paths.music('mii'), 0.5);
				Conductor.changeBPM(118);
		}
		//FlxG.sound.playMusic(Paths.music('breakfast'), 0.5);

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true); //new EPIC code
		//FlxCamera.defaultCameras = [camEditor]; //old STUPID code

		bgLayer = new FlxTypedGroup<FlxSprite>();
		add(bgLayer);
		grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
		add(grpLimoDancers);
		gfLayer = new FlxTypedGroup<Character>();
		add(gfLayer);
		fuckLayer = new FlxTypedGroup<FlxSprite>();
		add(fuckLayer);
		dadLayer = new FlxTypedGroup<Character>();
		add(dadLayer);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);
		foregroundSprites = new FlxTypedGroup<BGSprite>();
		add(foregroundSprites);

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		add(cameraFollowPointer);

		stageDropDown = new FlxUIDropDownMenuCustom(FlxG.width - 400, 25, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true));
			stageDropDown.selectedLabel = currentStage;
		stageDropDown.cameras = [camMenu];
		changeBGbutton = new FlxButton(FlxG.width - 360, stageDropDown.y + 20, "Reload BG", function()
		{
			reloadBGs();
			char.setPosition(char.positionArray[0] + OFFSET_X + 100 + xPositioningOffset, char.positionArray[1] + yPositioningOffset); //we do it again so that it gets properly set lmao
		});
		changeBGbutton.cameras = [camMenu];

		loadChar(!daAnim.startsWith('bf'), false);

		healthBarBGBG = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBar'));
		healthBarBGBG.scrollFactor.set();
		add(healthBarBGBG);
		healthBarBGBG.cameras = [camHUD];

		healthBarBG = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBarTop'));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);
		healthBarBG.cameras = [camHUD];

		healthBarBGM = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBarMiddle'));
		healthBarBGM.scrollFactor.set();
		add(healthBarBGM);
		healthBarBGM.cameras = [camHUD];

		healthBarBGB = new FlxSprite(30, FlxG.height - 75).loadGraphic(Paths.image('healthBarBottom'));
		healthBarBGB.scrollFactor.set();
		add(healthBarBGB);
		healthBarBGB.cameras = [camHUD];

		leHealthIcon = new HealthIcon(char.healthIcon, false);
		leHealthIcon.y = FlxG.height - 130;
		add(leHealthIcon);
		leHealthIcon.cameras = [camHUD];

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);
		dumbTexts.cameras = [camHUD];

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camHUD];
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		if (char != null) {
			snapCamFollowToPos(char.getMidpoint().x + 150, char.getMidpoint().y - 100);
		} else {
			snapCamFollowToPos(0, 0);
		}
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		var tipTextArray:Array<String> = "E/Q - Camera Zoom In/Out
		\nR - Reset Camera Zoom
		\nJKLI - Move Camera
		\nW/S - Previous/Next Animation
		\nSpace - Play Animation
		\nArrow Keys - Move Character Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster\n".split('\n');

		for (i in 0...tipTextArray.length-1)
		{
			var tipText:FlxText = new FlxText(FlxG.width - 320, FlxG.height - 15 - 16 * (tipTextArray.length - i), 300, tipTextArray[i], 12);
			tipText.cameras = [camHUD];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
		}

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.focusOn(camFollow);

		var tabs = [
			//{name: 'Offsets', label: 'Offsets'},
			{name: 'Settings', label: 'Settings'},
		];

		//Chara Selector box (why isnt this labled???)
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.cameras = [camMenu];

		UI_box.resize(250, 120);
		UI_box.x = FlxG.width - 275;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		var tabs = [
			{name: 'Character', label: 'Character'},
			{name: 'Healthbar', label: 'Healthbar'},
			{name: 'Misc', label: 'Misc'},
			{name: 'Animations', label: 'Animations'},
		];
		UI_characterbox = new FlxUITabMenu(null, tabs, true);
		UI_characterbox.cameras = [camMenu];

		UI_characterbox.resize(350, 250);
		UI_characterbox.x = UI_box.x - 100;
		UI_characterbox.y = UI_box.y + UI_box.height;
		UI_characterbox.scrollFactor.set();
		add(UI_characterbox);
		add(UI_box);
		add(changeBGbutton);
		add(stageDropDown);
		
		//addOffsetsUI();
		addSettingsUI();

		addCharacterUI();
		addHealthbarUI();
		addMiscUI();
		addAnimationsUI();
		UI_characterbox.selected_tab_id = 'Character';

		FlxG.mouse.visible = true;
		reloadCharacterOptions();

		super.create();
	}

	var OFFSET_X:Float = 300;
	function reloadBGs() {
		var i:Int = bgLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxSprite = bgLayer.members[i];
			if(memb != null) {
				memb.kill();
				bgLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();

		var i:Int = foregroundSprites.members.length-1;
		while(i >= 0) {
			var memb:BGSprite = foregroundSprites.members[i];
			if(memb != null) {
				memb.kill();
				foregroundSprites.remove(memb);
				memb.destroy();
			}
			--i;
		}
		foregroundSprites.clear();

		var i:Int = grpLimoDancers.members.length-1;
		while(i >= 0) {
			var memb:BackgroundDancer = grpLimoDancers.members[i];
			if(memb != null) {
				memb.kill();
				grpLimoDancers.remove(memb);
				memb.destroy();
			}
			--i;
		}
		grpLimoDancers.clear();

		var i:Int = gfLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = gfLayer.members[i];
			if(memb != null) {
				memb.kill();
				gfLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		gfLayer.clear();

		var i:Int = fuckLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxSprite = fuckLayer.members[i];
			if(memb != null) {
				memb.kill();
				fuckLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		fuckLayer.clear();

		var i:Int = dadLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = dadLayer.members[i];
			if(memb != null) {
				memb.kill();
				dadLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dadLayer.clear();

		switch (currentStage)
		{
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school' | 'schoolEvil':
				gfVersion = 'gf-pixel';
			case 'tank':
				gfVersion = 'gf-tankmen';
			default:
				gfVersion = 'gf';
		}

		switch (currentStage)
		{
			case 'stage':
				dadVersion = 'dad';
			case 'spooky':
				dadVersion = 'spooky';
			case 'philly':
				dadVersion = 'pico';
			case 'limo':
				dadVersion = 'mom-car';
			case 'mall':
				dadVersion = 'parents-christmas';
			case 'mallEvil':
				dadVersion = 'monster-christmas';
			case 'school':
				dadVersion = 'senpai';
			case 'schoolEvil':
				dadVersion = 'spirit';
			case 'tank':
				dadVersion = 'tankman';
			default:
				dadVersion = 'dad';
		}

		var playerXDifference = 0;
		if(char != null){if(char.isPlayer) playerXDifference = 670;}

		var playerYDifference:Float = 0;
		switch (currentStage)
		{
			case 'stage':
				var directory:String = 'shared';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var bg:BGSprite = new BGSprite('stageback', -600 + OFFSET_X, -200, 0.9, 0.9);
				bgLayer.add(bg);
	
				var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				bgLayer.add(stageFront);
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 770;
						yPositioningOffset = 100;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality) {
				gfXPositioningOffset = 400 + OFFSET_X;
				gfYPositioningOffset = 130;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);
				
				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 100 + OFFSET_X;
						dadYPositioningOffset = 100;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
			case 'spooky':
				var directory:String = 'week2';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var halloweenBG:BGSprite = new BGSprite('halloween_bg_low', -200 + OFFSET_X, -25);
				bgLayer.add(halloweenBG);
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 770;
						yPositioningOffset = 100;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 400 + OFFSET_X;
				gfYPositioningOffset = 130;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 100 + OFFSET_X;
						dadYPositioningOffset = 300;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
			case 'philly':
				var directory:String = 'week3';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var bg:BGSprite = new BGSprite('philly/sky', -300 + OFFSET_X, -100, 0.1, 0.1);
				bgLayer.add(bg);
				
				var city:BGSprite = new BGSprite('philly/city', -210 + OFFSET_X, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				bgLayer.add(city);

				var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -90 + OFFSET_X, 150);
				bgLayer.add(streetBehind);

				var street:BGSprite = new BGSprite('philly/street', -40 + OFFSET_X, 100);
				bgLayer.add(street);
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 770;
						yPositioningOffset = 100;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 400 + OFFSET_X;
				gfYPositioningOffset = 130;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 100 + OFFSET_X;
						dadYPositioningOffset = 380;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
			case 'limo':
				var directory:String = 'week4';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -420 + OFFSET_X, -50, 0.1, 0.1);
				bgLayer.add(skyBG);

				var bgLimo:BGSprite = new BGSprite('limo/bgLimo', -150 + OFFSET_X, 480, 0.4, 0.4, ['background limo pink'], true);
				bgLayer.add(bgLimo);
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 1030;
						yPositioningOffset = -120;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){

				for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 430, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

				gfXPositioningOffset = 400 + OFFSET_X;
				gfYPositioningOffset = 130;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 100 + OFFSET_X;
						dadYPositioningOffset = 100;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}

				var limo:BGSprite = new BGSprite('limo/limoDrive', -120 + OFFSET_X, 550, 1, 1, ['Limo stage'], true);
				fuckLayer.add(limo);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				resetFastCar();
				insert(members.indexOf(fuckLayer) - 1, fastCar);
			case 'mall':
				var directory:String = 'week5';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1200 + OFFSET_X, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				bgLayer.add(bg);

				if(!ClientPrefs.lowQuality){
				upperBoppers = new BGSprite('christmas/upperBop', -440 + OFFSET_X, -90, 0.33, 0.33, ['Upper Crowd Bob']);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				bgLayer.add(upperBoppers);
				}

				var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1300 + OFFSET_X, -600, 0.3, 0.3);
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				bgLayer.add(bgEscalator);

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 170 + OFFSET_X, -250, 0.40, 0.40);
				bgLayer.add(tree);

				if(!ClientPrefs.lowQuality){
				bottomBoppers = new BGSprite('christmas/bottomBop', -400 + OFFSET_X, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				bgLayer.add(bottomBoppers);
				}

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -800 + OFFSET_X, 700);
				bgLayer.add(fgSnow);

				if(!ClientPrefs.lowQuality){
				santa = new BGSprite('christmas/santa', -840 + OFFSET_X, 150, 1, 1, ['santa idle in fear']);
				bgLayer.add(santa);
				}

				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 970;
						yPositioningOffset = 100;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 400 + OFFSET_X;
				gfYPositioningOffset = 130;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = -300 + OFFSET_X;
						dadYPositioningOffset = 100;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
			case 'mallEvil':
				var directory:String = 'week5';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var bg:BGSprite = new BGSprite('christmas/evilBG', -600 + OFFSET_X, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				bgLayer.add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 100 + OFFSET_X, -300, 0.2, 0.2);
				bgLayer.add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -300 + OFFSET_X, 700);
				bgLayer.add(evilSnow);
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 1090;
						yPositioningOffset = 100;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 20;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 400 + OFFSET_X;
				gfYPositioningOffset = 130;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 100 + OFFSET_X;
						dadYPositioningOffset = 150;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
			case 'school':
				var directory:String = 'week6';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				if(char.isPlayer) {
					playerXDifference += 200;
					playerYDifference = 0;
				}
	
				var bgSky:BGSprite = new BGSprite('weeb/weebSky', OFFSET_X - 400, -120, 0.1, 0.1);
				bgLayer.add(bgSky);
				bgSky.antialiasing = false;
	
				var repositionShit = -200 + OFFSET_X;
	
				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit - 80, 106, 0.6, 0.90);
				bgLayer.add(bgSchool);
				bgSchool.antialiasing = false;
	
				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 100, 0.95, 0.95);
				bgLayer.add(bgStreet);
				bgStreet.antialiasing = false;
	
				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 90, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					bgLayer.add(fgTrees);
					fgTrees.antialiasing = false;
				}
				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -700 - playerYDifference);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				bgLayer.add(bgTrees);
				bgTrees.antialiasing = false;
	
				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
	
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * 6));
					bgGirls.updateHitbox();
					bgLayer.add(bgGirls);
				}

				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 970;
						yPositioningOffset = 320;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 580 + OFFSET_X;
				gfYPositioningOffset = 430;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 180 + OFFSET_X;
						dadYPositioningOffset = 450;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
			case 'schoolEvil':
				var directory:String = 'week6';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				if(char.isPlayer) {
					playerXDifference += 200;
					playerYDifference = 0;
				}

				var repositionShit = -200 + OFFSET_X;
				
				var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', 500 + repositionShit, 300, 0.8, 0.9, ['background 2'], true);
				bg.scale.set(6, 6);
				bg.antialiasing = false;
				bgLayer.add(bg);
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 970;
						yPositioningOffset = 320;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 580 + OFFSET_X;
				gfYPositioningOffset = 430;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 0 + OFFSET_X;
						dadYPositioningOffset = 230;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}			
			case 'tank':
				var directory:String = 'week7';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var sky:BGSprite = new BGSprite('tankSky', -600 + OFFSET_X, -400, 0, 0);
				bgLayer.add(sky);

				if(!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100) + OFFSET_X, FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					bgLayer.add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -500 + OFFSET_X, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					bgLayer.add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -300 + OFFSET_X, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					bgLayer.add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-400 + OFFSET_X,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				bgLayer.add(ruins);

				if(!ClientPrefs.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -400 + OFFSET_X, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					bgLayer.add(smokeLeft);
					var smokeRight:BGSprite = new BGSprite('smokeRight', 900 + OFFSET_X, -100, 0.4, 0.4, ['SmokeRight'], true);
					bgLayer.add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', -100 + OFFSET_X, 50, 0.5, 0.5, ['watchtower gradient color']);
					bgLayer.add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300 + OFFSET_X, 300, 0.5, 0.5,['BG tank w lighting'], true);
				bgLayer.add(tankGround);

				var ground:BGSprite = new BGSprite('tankGround', -420 + OFFSET_X, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				bgLayer.add(ground);
				moveTank();

				foregroundSprites.add(new BGSprite('tank0', -500 + OFFSET_X, 650, 1.7, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450 + OFFSET_X, 940, 1.5, 1.5, ['foreground']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620 + OFFSET_X, 700, 1.5, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 810;
						yPositioningOffset = 100;
					} else {
						xPositioningOffset = 20;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 200 + OFFSET_X;
				gfYPositioningOffset = 65;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 20 + OFFSET_X;
						dadYPositioningOffset = 300;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
			default:
				var directory:String = 'shared';
				var weekDir:String = StageData.forceNextDirectory;
				StageData.forceNextDirectory = null;
		
				if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;
		
				Paths.setCurrentLevel(directory);
				trace('Setting asset folder to ' + directory);
				var bg:BGSprite = new BGSprite('stageback', -600 + OFFSET_X, -300, 0.9, 0.9);
				bgLayer.add(bg);
	
				var stageFront:BGSprite = new BGSprite('stagefront', -650 + OFFSET_X, 500, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				bgLayer.add(stageFront);
				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 770;
						yPositioningOffset = 100;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
				if(!ClientPrefs.lowQuality){
				gfXPositioningOffset = 400 + OFFSET_X;
				gfYPositioningOffset = 130;
				gf = new Character(gfXPositioningOffset, gfYPositioningOffset, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
				gfLayer.add(gf);

				if(char != null){
					if(char.isPlayer) {
						dadXPositioningOffset = 100 + OFFSET_X;
						dadYPositioningOffset = 100;
						dad = new Character(dadXPositioningOffset, dadYPositioningOffset, dadVersion);
						dad.scrollFactor.set(1, 1);
						dadLayer.add(dad);
						}
					}
				}
		}
		if (char != null) {
			if (char.isPlayer) {
				snapCamFollowToPos(char.getMidpoint().x - 100, char.getMidpoint().y - 100);
			} else {
				snapCamFollowToPos(char.getMidpoint().x + 100, char.getMidpoint().y - 100);
			}
		}
		trace ('reloaded bg with stage:' + currentStage);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var TemplateCharacter:String = '{
		"animations": [
			{
				"offsets": [
					-5,
					0
				],
				"loop": false,
				"fps": 24,
				"anim": "idle",
				"indices": [],
				"name": "BF idle dance"
			},
			{
				"offsets": [
					5,
					-6
				],
				"loop": false,
				"fps": 24,
				"anim": "singLEFT",
				"indices": [],
				"name": "BF NOTE LEFT0"
			},
			{
				"offsets": [
					-20,
					-51
				],
				"loop": false,
				"fps": 24,
				"anim": "singDOWN",
				"indices": [],
				"name": "BF NOTE DOWN0"
			},
			{
				"offsets": [
					-46,
					27
				],
				"loop": false,
				"fps": 24,
				"anim": "singUP",
				"indices": [],
				"name": "BF NOTE UP0"
			},
			{
				"offsets": [
					-48,
					-7
				],
				"loop": false,
				"fps": 24,
				"anim": "singRIGHT",
				"indices": [],
				"name": "BF NOTE RIGHT0"
			},
			{
				"offsets": [
					-3,
					5
				],
				"loop": false,
				"fps": 24,
				"anim": "singSPACE",
				"indices": [],
				"name": "BF HEY"
			}
		],
		"sarvente_floating": false,
		"healthbar_colors_middle": [
			9,
			136,
			169
		],
		"no_antialiasing": false,
		"healthbar_colors_bottom": [
			0,
			96,
			129
		],
		"image": "characters/BOYFRIEND",
		"trail_length": null,
		"trail_delay": null,
		"position": [
			0,
			350
		],
		"trail_diff": null,
		"trail_alpha": null,
		"health_drain": false,
		"healthicon": "bf",
		"shake_screen": false,
		"orbit": false,
		"healthbar_count": 3,
		"flip_x": true,
		"healthbar_colors": [
			49,
			176,
			209
		],
		"camera_position": [
			0,
			0
		],
		"float_magnitude": 0,
		"sing_duration": 4,
		"scare_bf": false,
		"scare_gf": false,
		"scale": 1,
		"flixel_trail": false,
		"drain_kill": false,
		"drain_floor": 0.1
		}';

	var charDropDown:FlxUIDropDownMenuCustom;
	function addSettingsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Settings";

		var check_player = new FlxUICheckBox(10, 60, null, null, "Playable Character", 100);
		check_player.checked = daAnim.startsWith('bf');
		check_player.callback = function()
		{
			char.isPlayer = !char.isPlayer;
			char.flipX = !char.flipX;
			updatePointerPos();
			reloadBGs();
			char.setPosition(char.positionArray[0] + OFFSET_X + 100 + xPositioningOffset, char.positionArray[1] + yPositioningOffset); //we do it again so that it gets properly set lmao
			if (char.isPlayer) {
				snapCamFollowToPos(char.getMidpoint().x - 100, char.getMidpoint().y - 100);
			} else {
				snapCamFollowToPos(char.getMidpoint().x + 100, char.getMidpoint().y - 100);
			}
			ghostChar.flipX = char.flipX;
		};

		charDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			check_player.checked = daAnim.startsWith('bf');
			loadChar(!check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();

		var reloadCharacter:FlxButton = new FlxButton(140, 20, "Reload Char", function()
		{
			loadChar(!check_player.checked);
			reloadCharacterDropDown();
		});

		var templateCharacter:FlxButton = new FlxButton(140, 50, "Load Template", function()
		{
			var parsedJson:CharacterFile = cast Json.parse(TemplateCharacter);
			var characters:Array<Character> = [char, ghostChar];
			for (character in characters)
			{
				character.animOffsets.clear();
				character.animationsArray = parsedJson.animations;
				for (anim in character.animationsArray)
				{
					character.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				if(character.animationsArray[0] != null) {
					character.playAnim(character.animationsArray[0].anim, true);
				}

				character.singDuration = parsedJson.sing_duration;
				character.positionArray = parsedJson.position;
				character.cameraPosition = parsedJson.camera_position;
				
				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.sarventeFloating = parsedJson.sarvente_floating;
				character.orbit = parsedJson.orbit;
				character.flixelTrail = parsedJson.flixel_trail;
				character.shakeScreen = parsedJson.shake_screen;
				character.scareBf = parsedJson.scare_bf;
				character.scareGf = parsedJson.scare_gf;
				character.healthDrain = parsedJson.health_drain;
				character.healthIcon = parsedJson.healthicon;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.healthColorArrayMiddle = parsedJson.healthbar_colors_middle;
				character.healthColorArrayBottom = parsedJson.healthbar_colors_bottom;
				character.setPosition(character.positionArray[0] + OFFSET_X + 100, character.positionArray[1]);
			}

			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			updatePointerPos();
			genBoyOffsets();
		});
		templateCharacter.color = FlxColor.RED;
		templateCharacter.label.color = FlxColor.WHITE;
		
		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(charDropDown);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		UI_box.addGroup(tab_group);
	}
	
	var imageInputText:FlxUIInputText;
	var healthIconInputText:FlxUIInputText;

	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var hpBarCountStepper:FlxUINumericStepper;
	var floatMagnitudeStepper:FlxUINumericStepper;
	var trailLengthStepper:FlxUINumericStepper;
	var trailDelayStepper:FlxUINumericStepper;
	var trailAlphaStepper:FlxUINumericStepper;
	var trailDiffStepper:FlxUINumericStepper;
	var drainFloorStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;

	var flipXCheckBox:FlxUICheckBox;
	var sarventeFloatingCheckBox:FlxUICheckBox;
	var orbitCheckBox:FlxUICheckBox;
	var flixelTrailCheckBox:FlxUICheckBox;
	var screenShakeCheckBox:FlxUICheckBox;
	var scareBfCheckBox:FlxUICheckBox;
	var scareGfCheckBox:FlxUICheckBox;
	var healthDrainCheckBox:FlxUICheckBox;
	var drainKillCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;

	var healthColorStepperR:FlxUINumericStepper;
	var healthColorStepperG:FlxUINumericStepper;
	var healthColorStepperB:FlxUINumericStepper;

	var healthColorStepperRM:FlxUINumericStepper;
	var healthColorStepperGM:FlxUINumericStepper;
	var healthColorStepperBM:FlxUINumericStepper;

	var healthColorStepperRB:FlxUINumericStepper;
	var healthColorStepperGB:FlxUINumericStepper;
	var healthColorStepperBB:FlxUINumericStepper;

	function addCharacterUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		imageInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(char.animation.curAnim != null) {
				char.playAnim(char.animation.curAnim.name, true);
			}
		});

		singDurationStepper = new FlxUINumericStepper(15, imageInputText.y + 45, 0.1, 4, 0, 999, 1);
		if (Reflect.getProperty(singDurationStepper, 'name') == null) Reflect.setProperty(singDurationStepper, 'name', 'singDurationStepper');

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 20, 1);
		if (Reflect.getProperty(scaleStepper, 'name') == null) Reflect.setProperty(scaleStepper, 'name', 'scaleStepper');

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if(char.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if(char.isPlayer) char.flipX = !char.flipX;
			
			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 20, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			char.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.globalAntialiasing) {
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			ghostChar.antialiasing = char.antialiasing;
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionArray[0], -9000, 9000, 0);
		if (Reflect.getProperty(positionXStepper, 'name') == null) Reflect.setProperty(positionXStepper, 'name', 'positionXStepper');
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionArray[1], -9000, 9000, 0);
		if (Reflect.getProperty(positionYStepper, 'name') == null) Reflect.setProperty(positionYStepper, 'name', 'positionYStepper');
		
		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, char.cameraPosition[0], -9000, 9000, 0);
		if (Reflect.getProperty(positionCameraXStepper, 'name') == null) Reflect.setProperty(positionCameraXStepper, 'name', 'positionCameraXStepper');
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, char.cameraPosition[1], -9000, 9000, 0);
		if (Reflect.getProperty(positionCameraYStepper, 'name') == null) Reflect.setProperty(positionCameraYStepper, 'name', 'positionCameraYStepper');

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			saveCharacter();
		});

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(saveCharacterButton);
		UI_characterbox.addGroup(tab_group);
	}

	function addHealthbarUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Healthbar";

		var decideIconColor:FlxButton = new FlxButton(225, 27, "Get Icon Color", function()
			{
				var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));
				healthColorStepperR.value = coolColor.red;
				healthColorStepperG.value = coolColor.green;
				healthColorStepperB.value = coolColor.blue;

				healthColorStepperRM.value = coolColor.red - 20;
				healthColorStepperGM.value = coolColor.green - 20;
				healthColorStepperBM.value = coolColor.blue - 20;

				healthColorStepperRB.value = coolColor.red - 40;
				healthColorStepperGB.value = coolColor.green - 40;
				healthColorStepperBB.value = coolColor.blue - 40;
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperR, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperG, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperB, null); 

				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperRM, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperGM, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperBM, null); 

				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperRB, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperGB, null);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, healthColorStepperBB, null); 
			});

		healthIconInputText = new FlxUIInputText(15, 30, 200, leHealthIcon.getCharacter(), 8);
		healthIconInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		hpBarCountStepper = new FlxUINumericStepper(decideIconColor.x, healthIconInputText.y + 45, 1, 1, 1, 3, 0);
		if (Reflect.getProperty(hpBarCountStepper, 'name') == null) Reflect.setProperty(hpBarCountStepper, 'name', 'hpBarCountStepper');

		healthColorStepperR = new FlxUINumericStepper(15, healthIconInputText.y + 45, 20, char.healthColorArray[0], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperR, 'name') == null) Reflect.setProperty(healthColorStepperR, 'name', 'healthColorStepperR');
		healthColorStepperG = new FlxUINumericStepper(80, healthIconInputText.y + 45, 20, char.healthColorArray[1], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperG, 'name') == null) Reflect.setProperty(healthColorStepperG, 'name', 'healthColorStepperG');
		healthColorStepperB = new FlxUINumericStepper(145, healthIconInputText.y + 45, 20, char.healthColorArray[2], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperB, 'name') == null) Reflect.setProperty(healthColorStepperB, 'name', 'healthColorStepperB');

		healthColorStepperRM = new FlxUINumericStepper(15, healthColorStepperR.y + 20, 20, char.healthColorArrayMiddle[0], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperRM, 'name') == null) Reflect.setProperty(healthColorStepperRM, 'name', 'healthColorStepperRM');
		healthColorStepperGM = new FlxUINumericStepper(80, healthColorStepperR.y + 20, 20, char.healthColorArrayMiddle[1], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperGM, 'name') == null) Reflect.setProperty(healthColorStepperGM, 'name', 'healthColorStepperGM');
		healthColorStepperBM = new FlxUINumericStepper(145, healthColorStepperR.y + 20, 20, char.healthColorArrayMiddle[2], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperBM, 'name') == null) Reflect.setProperty(healthColorStepperBM, 'name', 'healthColorStepperBM');

		healthColorStepperRB = new FlxUINumericStepper(15, healthColorStepperRM.y + 20, 20, char.healthColorArrayBottom[0], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperRB, 'name') == null) Reflect.setProperty(healthColorStepperRB, 'name', 'healthColorStepperRB');
		healthColorStepperGB = new FlxUINumericStepper(80, healthColorStepperRM.y + 20, 20, char.healthColorArrayBottom[1], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperGB, 'name') == null) Reflect.setProperty(healthColorStepperGB, 'name', 'healthColorStepperGB');
		healthColorStepperBB = new FlxUINumericStepper(145, healthColorStepperRM.y + 20, 20, char.healthColorArrayBottom[2], 0, 255, 0);
		if (Reflect.getProperty(healthColorStepperBB, 'name') == null) Reflect.setProperty(healthColorStepperBB, 'name', 'healthColorStepperBB');

		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Health icon name:'));
		tab_group.add(new FlxText(hpBarCountStepper.x, hpBarCountStepper.y - 18, 0, 'HP Bars:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health bar R/G/B:'));
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(hpBarCountStepper);
		tab_group.add(healthColorStepperR);
		tab_group.add(healthColorStepperG);
		tab_group.add(healthColorStepperB);
		tab_group.add(healthColorStepperRM);
		tab_group.add(healthColorStepperGM);
		tab_group.add(healthColorStepperBM);
		tab_group.add(healthColorStepperRB);
		tab_group.add(healthColorStepperGB);
		tab_group.add(healthColorStepperBB);
		UI_characterbox.addGroup(tab_group);
	}

	function addMiscUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Misc";

		sarventeFloatingCheckBox = new FlxUICheckBox(15, 20, null, null, "Sarvente Floating", 50);
		sarventeFloatingCheckBox.checked = char.sarventeFloating;
		sarventeFloatingCheckBox.callback = function() {
			char.sarventeFloating = false;
			if(sarventeFloatingCheckBox.checked) {
				char.sarventeFloating = true;
			}
			char.sarventeFloating = sarventeFloatingCheckBox.checked;
			ghostChar.sarventeFloating = char.sarventeFloating;
		};

		floatMagnitudeStepper = new FlxUINumericStepper(255, sarventeFloatingCheckBox.y, 0.05, 0.05, 0.05, 10, 2);
		if (Reflect.getProperty(floatMagnitudeStepper, 'name') == null) Reflect.setProperty(floatMagnitudeStepper, 'name', 'floatMagnitudeStepper');

		flixelTrailCheckBox = new FlxUICheckBox(sarventeFloatingCheckBox.x, sarventeFloatingCheckBox.y + 40, null, null, "Flixel Trail", 50);
		flixelTrailCheckBox.checked = char.flixelTrail;
		flixelTrailCheckBox.callback = function() {
			char.flixelTrail = false;
			if(flixelTrailCheckBox.checked) {
				char.flixelTrail = true;
			}
			char.flixelTrail = flixelTrailCheckBox.checked;
			ghostChar.flixelTrail = char.flixelTrail;
		};

		trailLengthStepper = new FlxUINumericStepper(flixelTrailCheckBox.x + 60, flixelTrailCheckBox.y, 1, 4, 1, 24, 1);
		if (Reflect.getProperty(trailLengthStepper, 'name') == null) Reflect.setProperty(trailLengthStepper, 'name', 'trailLengthStepper');
		trailDelayStepper = new FlxUINumericStepper(trailLengthStepper.x + 70, flixelTrailCheckBox.y, 1, 24, 0, 90, 1);
		if (Reflect.getProperty(trailDelayStepper, 'name') == null) Reflect.setProperty(trailDelayStepper, 'name', 'trailDelayStepper');
		trailAlphaStepper = new FlxUINumericStepper(trailDelayStepper.x + 70, flixelTrailCheckBox.y, 0.1, 0.3, 0, 1, 3);
		if (Reflect.getProperty(trailAlphaStepper, 'name') == null) Reflect.setProperty(trailAlphaStepper, 'name', 'trailAlphaStepper');
		trailDiffStepper = new FlxUINumericStepper(trailAlphaStepper.x + 70, flixelTrailCheckBox.y, 0.05, 0.069, 0, 1, 4);
		if (Reflect.getProperty(trailDiffStepper, 'name') == null) Reflect.setProperty(trailDiffStepper, 'name', 'trailDiffStepper');

		orbitCheckBox = new FlxUICheckBox(sarventeFloatingCheckBox.x, flixelTrailCheckBox.y + 40, null, null, "Orbit BF", 50);
		orbitCheckBox.checked = char.orbit;
		orbitCheckBox.callback = function() {
			char.orbit = false;
			if(orbitCheckBox.checked) {
				char.orbit = true;
			}
			char.orbit = orbitCheckBox.checked;
			ghostChar.orbit = char.orbit;
		};

		screenShakeCheckBox = new FlxUICheckBox(sarventeFloatingCheckBox.x, orbitCheckBox.y + 40, null, null, "Shake Screen", 50);
		screenShakeCheckBox.checked = char.shakeScreen;
		screenShakeCheckBox.callback = function() {
			char.shakeScreen = false;
			if(screenShakeCheckBox.checked) {
				char.shakeScreen = true;
			}
			char.shakeScreen = screenShakeCheckBox.checked;
			ghostChar.shakeScreen = char.shakeScreen;
		};

		scareBfCheckBox = new FlxUICheckBox(screenShakeCheckBox.x + 80, orbitCheckBox.y + 40, null, null, "Scare BF", 50);
		scareBfCheckBox.checked = char.scareBf;
		scareBfCheckBox.callback = function() {
			char.scareBf = false;
			if(scareBfCheckBox.checked) {
				char.scareBf = true;
			}
			char.scareBf = scareBfCheckBox.checked;
			ghostChar.scareBf = char.scareBf;
		};

		scareGfCheckBox = new FlxUICheckBox(scareBfCheckBox.x + 80, orbitCheckBox.y + 40, null, null, "Scare GF", 50);
		scareGfCheckBox.checked = char.scareGf;
		scareGfCheckBox.callback = function() {
			char.scareGf = false;
			if(scareGfCheckBox.checked) {
				char.scareGf = true;
			}
			char.scareGf = scareGfCheckBox.checked;
			ghostChar.scareGf = char.scareGf;
		};

		healthDrainCheckBox = new FlxUICheckBox(sarventeFloatingCheckBox.x, screenShakeCheckBox.y + 40, null, null, "Health Drain", 50);
		healthDrainCheckBox.checked = char.healthDrain;
		healthDrainCheckBox.callback = function() {
			char.healthDrain = false;
			if(healthDrainCheckBox.checked) {
				char.healthDrain = true;
			}
			char.healthDrain = healthDrainCheckBox.checked;
			ghostChar.healthDrain = char.healthDrain;
		};

		drainKillCheckBox = new FlxUICheckBox(healthDrainCheckBox.x + 80, healthDrainCheckBox.y, null, null, "Can Kill", 50);
		drainKillCheckBox.checked = char.drainKill;
		drainKillCheckBox.callback = function() {
			char.drainKill = false;
			if(drainKillCheckBox.checked) {
				char.drainKill = true;
			}
			char.drainKill = drainKillCheckBox.checked;
			ghostChar.drainKill = char.drainKill;
		};

		drainFloorStepper = new FlxUINumericStepper(drainKillCheckBox.x + 80, healthDrainCheckBox.y, 0.05, 0.1, 0, 2, 3);
		if (Reflect.getProperty(drainFloorStepper, 'name') == null) Reflect.setProperty(drainFloorStepper, 'name', 'drainFloorStepper');

		tab_group.add(new FlxText(floatMagnitudeStepper.x, floatMagnitudeStepper.y - 18, 0, 'Float Magnitude:'));
		tab_group.add(new FlxText(trailLengthStepper.x, trailLengthStepper.y - 18, 0, 'Trail Length:'));
		tab_group.add(new FlxText(trailDelayStepper.x, trailDelayStepper.y - 18, 0, 'Trail Delay:'));
		tab_group.add(new FlxText(trailAlphaStepper.x, trailAlphaStepper.y - 18, 0, 'Trail Alpha:'));
		tab_group.add(new FlxText(trailDiffStepper.x, trailDiffStepper.y - 18, 0, 'Trail Diff:'));
		tab_group.add(new FlxText(drainFloorStepper.x, drainFloorStepper.y - 18, 0, 'Minimum Health:'));
		tab_group.add(floatMagnitudeStepper);
		tab_group.add(trailLengthStepper);
		tab_group.add(trailDelayStepper);
		tab_group.add(trailAlphaStepper);
		tab_group.add(trailDiffStepper);
		tab_group.add(drainFloorStepper);
		tab_group.add(sarventeFloatingCheckBox);
		tab_group.add(flixelTrailCheckBox);
		tab_group.add(orbitCheckBox);
		tab_group.add(screenShakeCheckBox);
		tab_group.add(scareBfCheckBox);
		tab_group.add(scareGfCheckBox);
		tab_group.add(healthDrainCheckBox);
		tab_group.add(drainKillCheckBox);
		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenuCustom;
	var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	function addAnimationsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";
		
		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		animationInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationNameInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationIndicesInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, null, null, "Should it Loop?", 100);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = char.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		ghostDropDown = new FlxUIDropDownMenuCustom(animationDropDown.x + 150, animationDropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			ghostChar.visible = false;
			char.alpha = 1;
			if(selectedAnimation > 0) {
				ghostChar.visible = true;
				ghostChar.playAnim(ghostChar.animationsArray[selectedAnimation-1].anim, true);
				char.alpha = 0.85;
			}
		});

		var addUpdateButton:FlxButton = new FlxButton(70, animationIndicesInputText.y + 30, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if(indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastAnim:String = '';
			if(char.animationsArray[curAnim] != null) {
				lastAnim = char.animationsArray[curAnim].anim;
			}

			var lastOffsets:Array<Int> = [0, 0];
			for (anim in char.animationsArray) {
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(char.animation.getByName(animationInputText.text) != null) {
						char.animation.remove(animationInputText.text);
					}
					char.animationsArray.remove(anim);
				}
			}

			var newAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationNameFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};
			if(indices != null && indices.length > 0) {
				char.animation.addByIndices(newAnim.anim, newAnim.name, newAnim.indices, "", newAnim.fps, newAnim.loop);
			} else {
				char.animation.addByPrefix(newAnim.anim, newAnim.name, newAnim.fps, newAnim.loop);
			}
			
			if(!char.animOffsets.exists(newAnim.anim)) {
				char.addOffset(newAnim.anim, 0, 0);
			}
			char.animationsArray.push(newAnim);

			if(lastAnim == animationInputText.text) {
				var leAnim:FlxAnimation = char.animation.getByName(lastAnim);
				if(leAnim != null && leAnim.frames.length > 0) {
					char.playAnim(lastAnim, true);
				} else {
					for(i in 0...char.animationsArray.length) {
						if(char.animationsArray[i] != null) {
							leAnim = char.animation.getByName(char.animationsArray[i].anim);
							if(leAnim != null && leAnim.frames.length > 0) {
								char.playAnim(char.animationsArray[i].anim, true);
								curAnim = i;
								break;
							}
						}
					}
				}
			}

			reloadAnimationDropDown();
			genBoyOffsets();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:FlxButton = new FlxButton(180, animationIndicesInputText.y + 30, "Remove", function() {
			for (anim in char.animationsArray) {
				if(animationInputText.text == anim.anim) {
					var resetAnim:Bool = false;
					if(char.animation.curAnim != null && anim.anim == char.animation.curAnim.name) resetAnim = true;

					if(char.animation.getByName(anim.anim) != null) {
						char.animation.remove(anim.anim);
					}
					if(char.animOffsets.exists(anim.anim)) {
						char.animOffsets.remove(anim.anim);
					}
					char.animationsArray.remove(anim);

					if(resetAnim && char.animationsArray.length > 0) {
						char.playAnim(char.animationsArray[0].anim, true);
					}
					reloadAnimationDropDown();
					genBoyOffsets();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Animation Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation on .XML/.TXT file:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == healthIconInputText) {
				leHealthIcon.changeIcon(healthIconInputText.text);
				char.healthIcon = healthIconInputText.text;
				updatePresence();
			}
			else if(sender == imageInputText) {
				char.imageFile = imageInputText.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			//fuck you lmao we doin reflects
			//else ifs can eat my ass
			//trace (Reflect.getProperty(sender, 'name'));
			//do note that fps doesnt give a shit about this specific function so it can be null
			var idkSex:String = Reflect.getProperty(sender, 'name');
			switch(idkSex) {
				case 'scaleStepper':
					reloadCharacterImage();
					char.jsonScale = scaleStepper.value;
					char.setGraphicSize(Std.int(char.width * char.jsonScale));
					char.updateHitbox();
					reloadGhost();
					updatePointerPos();
	
					if(char.animation.curAnim != null) {
						char.playAnim(char.animation.curAnim.name, true);
					}
				case 'positionXStepper':
					char.positionArray[0] = positionXStepper.value;
					char.x = xPositioningOffset + char.positionArray[0] + OFFSET_X + 100;
					updatePointerPos();
				case 'positionYStepper':
					char.positionArray[1] = positionYStepper.value;
					char.y = yPositioningOffset + char.positionArray[1];
					updatePointerPos();
				case 'singDurationStepper':
					char.singDuration = singDurationStepper.value;//ermm you forgot this??
				case 'positionCameraXStepper':
					char.cameraPosition[0] = positionCameraXStepper.value;
					updatePointerPos();
				case 'positionCameraYStepper':
					char.cameraPosition[1] = positionCameraYStepper.value;
					updatePointerPos();
				case 'healthColorStepperR':
					char.healthColorArray[0] = Math.round(healthColorStepperR.value);
					healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				case 'healthColorStepperG':
					char.healthColorArray[1] = Math.round(healthColorStepperG.value);
					healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				case 'healthColorStepperB':
					char.healthColorArray[2] = Math.round(healthColorStepperB.value);
					healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
				case 'healthColorStepperRM':
					char.healthColorArrayMiddle[0] = Math.round(healthColorStepperRM.value);
					healthBarBGM.color = FlxColor.fromRGB(char.healthColorArrayMiddle[0], char.healthColorArrayMiddle[1], char.healthColorArrayMiddle[2]);
				case 'healthColorStepperGM':
					char.healthColorArrayMiddle[1] = Math.round(healthColorStepperGM.value);
					healthBarBGM.color = FlxColor.fromRGB(char.healthColorArrayMiddle[0], char.healthColorArrayMiddle[1], char.healthColorArrayMiddle[2]);
				case 'healthColorStepperBM':
					char.healthColorArrayMiddle[2] = Math.round(healthColorStepperBM.value);
					healthBarBGM.color = FlxColor.fromRGB(char.healthColorArrayMiddle[0], char.healthColorArrayMiddle[1], char.healthColorArrayMiddle[2]);
				case 'healthColorStepperRB':
					char.healthColorArrayBottom[0] = Math.round(healthColorStepperRB.value);
					healthBarBGB.color = FlxColor.fromRGB(char.healthColorArrayBottom[0], char.healthColorArrayBottom[1], char.healthColorArrayBottom[2]);
				case 'healthColorStepperGB':
					char.healthColorArrayBottom[1] = Math.round(healthColorStepperGB.value);
					healthBarBGB.color = FlxColor.fromRGB(char.healthColorArrayMiddle[0], char.healthColorArrayBottom[1], char.healthColorArrayBottom[2]);
				case 'healthColorStepperBB':
					char.healthColorArrayBottom[2] = Math.round(healthColorStepperBB.value);
					healthBarBGB.color = FlxColor.fromRGB(char.healthColorArrayBottom[0], char.healthColorArrayBottom[1], char.healthColorArrayBottom[2]);
				case 'hpBarCountStepper':
					char.healthBarCount = Math.round(hpBarCountStepper.value);
				case 'floatMagnitudeStepper':
					char.floatMagnitude = floatMagnitudeStepper.value;
				case 'trailLengthStepper':
					char.trailLength = Math.round(trailLengthStepper.value);
				case 'trailDelayStepper':
					char.trailDelay = Math.round(trailDelayStepper.value);
				case 'trailAlphaStepper':
					char.trailAlpha = trailAlphaStepper.value;
				case 'trailDiffStepper':
					char.trailDiff = trailDiffStepper.value;
				case 'drainFloorStepper':
					char.drainFloor = drainFloorStepper.value;
					
			}
		}
	}

	function reloadCharacterImage() {
		var lastAnim:String = '';
		if(char.animation.curAnim != null) {
			lastAnim = char.animation.curAnim.name;
		}
		var anims:Array<AnimArray> = char.animationsArray.copy();
		if(Paths.fileExists('images/' + char.imageFile + '/Animation.json', TEXT)) {
			char.frames = AtlasFrameMaker.construct(char.imageFile);
		} else if(Paths.fileExists('images/' + char.imageFile + '.txt', TEXT)) {
			char.frames = Paths.getPackerAtlas(char.imageFile);
		} else {
			char.frames = Paths.getSparrowAtlas(char.imageFile);
		}

		if(char.animationsArray != null && char.animationsArray.length > 0) {
			for (anim in char.animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;
				if(animIndices != null && animIndices.length > 0) {
					char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
				} else {
					char.animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
			}
		} else {
			char.quickAnimAdd('idle', 'BF idle dance');
		}
		
		if(lastAnim != '') {
			char.playAnim(lastAnim, true);
		} else {
			char.dance();
		}
		ghostDropDown.selectedLabel = '';
		reloadGhost();
	}

	function genBoyOffsets():Void
	{
		var daLoop:Int = 0;

		var i:Int = dumbTexts.members.length-1;
		while(i >= 0) {
			var memb:FlxText = dumbTexts.members[i];
			if(memb != null) {
				memb.kill();
				dumbTexts.remove(memb);
				memb.destroy();
			}
			--i;
		}
		dumbTexts.clear();

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.setFormat(null, 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			text.cameras = [camHUD];

			daLoop++;
		}

		textAnim.visible = true;
		if(dumbTexts.length < 1) {
			var text:FlxText = new FlxText(10, 38, 0, "ERROR! No animations found.", 15);
			text.scrollFactor.set();
			text.borderSize = 1;
			dumbTexts.add(text);
			textAnim.visible = false;
		}
	}

	function loadChar(isDad:Bool, blahBlahBlah:Bool = true) {
		var i:Int = charLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = charLayer.members[i];
			if(memb != null) {
				memb.kill();
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();
		ghostChar = new Character(0, 0, daAnim, !isDad);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;

		char = new Character(0, 0, daAnim, !isDad);
		if(char.animationsArray[0] != null) {
			char.playAnim(char.animationsArray[0].anim, true);
		}
		char.debugMode = true;

		charLayer.add(ghostChar);
		charLayer.add(char);

		char.setPosition(char.positionArray[0] + OFFSET_X + 100, char.positionArray[1]);

		/* THIS FUNCTION WAS USED TO PUT THE .TXT OFFSETS INTO THE .JSON

		for (anim => offset in char.animOffsets) {
			var leAnim:AnimArray = findAnimationByName(anim);
			if(leAnim != null) {
				leAnim.offsets = [offset[0], offset[1]];
			}
		}*/

		if(blahBlahBlah) {
			genBoyOffsets();
		}
		reloadCharacterOptions();
		reloadBGs();
		char.setPosition(char.positionArray[0] + OFFSET_X + 100 + xPositioningOffset, char.positionArray[1] + yPositioningOffset); //we do it again so that it gets properly set lmao
		if (char.isPlayer) {
			snapCamFollowToPos(char.getMidpoint().x - 100, char.getMidpoint().y - 100);
		} else {
			snapCamFollowToPos(char.getMidpoint().x + 100, char.getMidpoint().y - 100);
		}
		updatePointerPos();
	}

	function updatePointerPos() {
		var x:Float = char.getMidpoint().x;
		var y:Float = char.getMidpoint().y;
		if(!char.isPlayer) {
			x += 150 + char.cameraPosition[0];
		} else {
			x -= 100 + char.cameraPosition[0];
		}
		y -= 100 - char.cameraPosition[1];

		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
	}

	function findAnimationByName(name:String):AnimArray {
		for (anim in char.animationsArray) {
			if(anim.anim == name) {
				return anim;
			}
		}
		return null;
	}

	function reloadCharacterOptions() {
		if(UI_characterbox != null) {
			imageInputText.text = char.imageFile;
			healthIconInputText.text = char.healthIcon;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			hpBarCountStepper.value = char.healthBarCount;
			floatMagnitudeStepper.value = char.floatMagnitude;
			trailLengthStepper.value = char.trailLength;
			trailDelayStepper.value = char.trailDelay;
			trailAlphaStepper.value = char.trailAlpha;
			trailDiffStepper.value = char.trailDiff;
			drainFloorStepper.value = char.drainFloor;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			sarventeFloatingCheckBox.checked = char.sarventeFloating;
			orbitCheckBox.checked = char.orbit;
			flixelTrailCheckBox.checked = char.flixelTrail;
			screenShakeCheckBox.checked = char.shakeScreen;
			scareBfCheckBox.checked = char.scareBf;
			scareGfCheckBox.checked = char.scareGf;
			healthDrainCheckBox.checked = char.healthDrain;
			drainKillCheckBox.checked = char.drainKill;
			resetHealthBarColor();
			leHealthIcon.changeIcon(healthIconInputText.text);
			positionXStepper.value = char.positionArray[0];
			positionYStepper.value = char.positionArray[1];
			positionCameraXStepper.value = char.cameraPosition[0];
			positionCameraYStepper.value = char.cameraPosition[1];
			reloadAnimationDropDown();
			updatePresence();
		}
	}

	function reloadAnimationDropDown() {
		var anims:Array<String> = [];
		var ghostAnims:Array<String> = [''];
		for (anim in char.animationsArray) {
			anims.push(anim.anim);
			ghostAnims.push(anim.anim);
		}
		if(anims.length < 1) anims.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(anims, true));
		ghostDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(ghostAnims, true));
		reloadGhost();
	}

	function reloadGhost() {
		ghostChar.frames = char.frames;
		for (anim in char.animationsArray) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			if(animIndices != null && animIndices.length > 0) {
				ghostChar.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
			} else {
				ghostChar.animation.addByPrefix(animAnim, animName, animFps, animLoop);
			}

			if(anim.offsets != null && anim.offsets.length > 1) {
				ghostChar.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}

		char.alpha = 0.85;
		ghostChar.visible = true;
		if(ghostDropDown.selectedLabel == '') {
			ghostChar.visible = false;
			char.alpha = 1;
		}
		ghostChar.color = 0xFF666688;
		ghostChar.antialiasing = char.antialiasing;
		
		ghostChar.setGraphicSize(Std.int(ghostChar.width * char.jsonScale));
		ghostChar.updateHitbox();
	}

	function reloadCharacterDropDown() {
		var charsLoaded:Map<String, Bool> = new Map();

		#if MODS_ALLOWED
		characterList = [];
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json')) {
						var charToCheck:String = file.substr(0, file.length - 5);
						if(!charsLoaded.exists(charToCheck)) {
							characterList.push(charToCheck);
							charsLoaded.set(charToCheck, true);
						}
					}
				}
			}
		}
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characterList'));
		#end

		charDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	function resetHealthBarColor() {
		healthColorStepperR.value = char.healthColorArray[0];
		healthColorStepperG.value = char.healthColorArray[1];
		healthColorStepperB.value = char.healthColorArray[2];
		healthColorStepperRM.value = char.healthColorArrayMiddle[0];
		healthColorStepperGM.value = char.healthColorArrayMiddle[1];
		healthColorStepperBM.value = char.healthColorArrayMiddle[2];
		healthColorStepperRB.value = char.healthColorArrayBottom[0];
		healthColorStepperGB.value = char.healthColorArrayBottom[1];
		healthColorStepperBB.value = char.healthColorArrayBottom[2];
		healthBarBG.color = FlxColor.fromRGB(char.healthColorArray[0], char.healthColorArray[1], char.healthColorArray[2]);
		healthBarBGM.color = FlxColor.fromRGB(char.healthColorArrayMiddle[0], char.healthColorArrayMiddle[1], char.healthColorArrayMiddle[2]);
		healthBarBGB.color = FlxColor.fromRGB(char.healthColorArrayBottom[0], char.healthColorArrayBottom[1], char.healthColorArrayBottom[2]);
	}

	function updatePresence() {
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.getCharacter());
		#end
	}

	override function update(elapsed:Float)
	{
		MusicBeatState.camBeat = FlxG.camera;
		if(char.animationsArray[curAnim] != null) {
			textAnim.text = char.animationsArray[curAnim].anim;

			var curAnim:FlxAnimation = char.animation.getByName(char.animationsArray[curAnim].anim);
			if(curAnim == null || curAnim.frames.length < 1) {
				textAnim.text += ' (ERROR!)';
			}
		} else {
			textAnim.text = '';
		}

		if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			}
	
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if(stageDropDown.selectedLabel != currentStage) {
			currentStage = stageDropDown.selectedLabel;
		}

		switch (currentStage) {
			case 'tank':
				moveTank(elapsed);
		}
		/*if(char.sarventeFloating) {
			FlxTween.tween(char, {y: 100}, 4, {type:FlxTween.PINGPONG, ease: FlxEase.quadInOut});
		}

		if(ghostChar.sarventeFloating) {
			FlxTween.tween(ghostChar, {y: 100}, 4, {type:FlxTween.PINGPONG, ease: FlxEase.quadInOut});
		}*/

		var inputTexts:Array<FlxUIInputText> = [animationInputText, imageInputText, healthIconInputText, animationNameInputText, animationIndicesInputText];
		for (i in 0...inputTexts.length) {
			if(inputTexts[i].hasFocus) {
				if(FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && Clipboard.text != null) { //Copy paste
					inputTexts[i].text = ClipboardAdd(inputTexts[i].text);
					inputTexts[i].caretIndex = inputTexts[i].text.length;
					getEvent(FlxUIInputText.CHANGE_EVENT, inputTexts[i], null, []);
				}
				if(FlxG.keys.justPressed.ENTER) {
					inputTexts[i].hasFocus = false;
				}
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				super.update(elapsed);
				return;
			}
		}
		FlxG.sound.muteKeys = InitState.muteKeys;
		FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;

		if(!charDropDown.dropPanel.visible) {
			if (FlxG.keys.justPressed.ESCAPE) {
				if(goToPlayState) {
					MusicBeatState.switchState(new PlayState());
				} else {
					MusicBeatState.switchState(new editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					Conductor.changeBPM(100);
				}
				FlxG.mouse.visible = false;
				return;
			}
			
			if (FlxG.keys.justPressed.R) {
				FlxG.camera.zoom = 1;
			}

			if (FlxG.keys.pressed.E && FlxG.camera.zoom < 6) {
				FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom > 6) FlxG.camera.zoom = 6;
			}
			if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.01) {
				FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
				if(FlxG.camera.zoom < 0.01) FlxG.camera.zoom = 0.01;
			}

			if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.SHIFT)
					addToCam *= 4;

				if (FlxG.keys.pressed.I) {
					camFollow.y -= addToCam;
					camFollowPos.y -= addToCam;
				} else if (FlxG.keys.pressed.K) {
					camFollow.y += addToCam;
					camFollowPos.y += addToCam;
				}

				if (FlxG.keys.pressed.J) {
					camFollow.x -= addToCam;
					camFollowPos.x -= addToCam;
				} else if (FlxG.keys.pressed.L) {
					camFollow.x += addToCam;
					camFollowPos.x += addToCam;
				}
			}

			if(char.animationsArray.length > 0) {
				if (FlxG.keys.justPressed.W)
				{
					curAnim -= 1;
				}

				if (FlxG.keys.justPressed.S)
				{
					curAnim += 1;
				}

				if (curAnim < 0)
					curAnim = char.animationsArray.length - 1;

				if (curAnim >= char.animationsArray.length)
					curAnim = 0;

				if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
				{
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genBoyOffsets();
				}
				if (FlxG.keys.justPressed.T)
				{
					char.animationsArray[curAnim].offsets = [0, 0];
					
					char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
					ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
					genBoyOffsets();
				}

				var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
				
				
				
				for (i in 0...controlArray.length) {
					if(controlArray[i]) {
						var holdShift = FlxG.keys.pressed.SHIFT;
						var multiplier = 1;
						if (holdShift)
							multiplier = 10;

						var arrayVal = 0;
						if(i > 1) arrayVal = 1;

						var negaMult:Int = 1;
						if(i % 2 == 1) negaMult = -1;
						char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
						
						char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
						
						char.playAnim(char.animationsArray[curAnim].anim, false);
						if(ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.animation.curAnim.name == ghostChar.animation.curAnim.name) {
							ghostChar.playAnim(char.animation.curAnim.name, false);
						}
						genBoyOffsets();
					}
				}
			}
		}
		//camMenu.zoom = FlxG.camera.zoom;
		ghostChar.setPosition(char.x, char.y);
		super.update(elapsed);
	}

	var _file:FileReference;
	/*private function saveOffsets()
	{
		var data:String = '';
		for (anim => offsets in char.animOffsets) {
			data += anim + ' ' + offsets[0] + ' ' + offsets[1] + '\n';
		}

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + "Offsets.txt");
		}
	}*/

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveCharacter() {
		var json = {
			"animations": char.animationsArray,
			"image": char.imageFile,
			"scale": char.jsonScale,
			"sing_duration": char.singDuration,
			"healthbar_count": char.healthBarCount,
			"float_magnitude": char.floatMagnitude,
			"trail_length": char.trailLength,
			"trail_delay": char.trailDelay,
			"trail_alpha": char.trailAlpha,
			"trail_diff": char.trailDiff,
			"drain_floor": char.drainFloor,
			"drain_kill": char.drainKill,
			"healthicon": char.healthIcon,
		
			"position":	char.positionArray,
			"camera_position": char.cameraPosition,
		
			"flip_x": char.originalFlipX,
			"sarvente_floating": char.sarventeFloating,
			"orbit": char.orbit,
			"flixel_trail": char.flixelTrail,
			"shake_screen": char.shakeScreen,
			"scare_bf": char.scareBf,
			"scare_gf": char.scareGf,
			"health_drain": char.healthDrain,
			"no_antialiasing": char.noAntialiasing,
			"healthbar_colors": char.healthColorArray,
			"healthbar_colors_middle": char.healthColorArrayMiddle,
			"healthbar_colors_bottom": char.healthColorArrayBottom
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, daAnim + ".json");
		}
	}

	function ClipboardAdd(prefix:String = ''):String {
		if(prefix.toLowerCase().endsWith('v')) //probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length-1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}

	override function beatHit()
		{
			super.beatHit();

			if(!ClientPrefs.lowQuality){
				gf.dance();
				if(char != null && char.isPlayer) dad.dance();
				switch(currentStage)
				{
					case 'limo':
						if(grpLimoDancers != null){
							grpLimoDancers.forEach(function(dancer:BackgroundDancer)
								{
									dancer.dance();
								});
						}
						if(fastCar != null){
							if (FlxG.random.bool(10) && fastCarCanDrive)
								fastCarDrive();
						}
					case 'mall':
						if(upperBoppers != null) upperBoppers.dance();

						if(bottomBoppers != null) bottomBoppers.dance();
							
						if(santa != null) santa.dance();
					case 'school':
						if(bgGirls != null) bgGirls.dance();
					case 'tank':
						if(!ClientPrefs.lowQuality && tankWatchtower != null) tankWatchtower.dance();
						foregroundSprites.forEach(function(spr:BGSprite)
							{
								if (spr != null) {
									spr.dance();
								}
							});
				}
			}
		}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);
	
	function moveTank(?elapsed:Float = 0):Void
	{
		if (tankGround != null) {
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	public function snapCamFollowToPos(x:Float, y:Float) {
		if (camFollow != null && camFollowPos != null) {
			camFollow.set(x, y);
			camFollowPos.setPosition(x, y);
		}
	}
}
