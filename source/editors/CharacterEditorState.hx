package editors;

import Character;
import StageData;
import VanillaBG;
import animateatlas.AtlasFrameMaker;
import flash.events.MouseEvent;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxe.Json;
import haxe.io.Path;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
#if desktop
import Discord.DiscordClient;
#end
import CoolUtil.convPathShit;

/**
* State used to create and edit `Character` jsons.
*/
class CharacterEditorState extends MusicBeatState
{
	var music:EditorMusic;
	var char:Character;
	var ghostChar:Character;
	var textAnim:FlxText;
	var bgLayer:FlxTypedGroup<FlxBasic>;
	var frontLayer:FlxTypedGroup<FlxBasic>;
	var fuckLayer:FlxTypedGroup<FlxBasic>;
	var charLayer:FlxTypedGroup<Character>;
	var offsetText:FlxText;
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var goToPlayState:Bool = true;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var prevCamFollow:FlxPoint;
	var prevCamFollowPos:FlxObject;
	var stageDropDown:FlxUIDropDownMenuCustom;
	var stages:Array<String> = [];
	var currentStage:String = 'stage';

	var xPositioningOffset:Float = 0;
	var yPositioningOffset:Float = 0;

	var cameraStageOffsets:Array<Single> = [0,0];

	var cameraCanvas:FlxSprite = null;
	var eyedropperPreview:FlxSprite = null;

	public function new(daAnim:String = 'spooky', goToPlayState:Bool = true)
	{
		super();
		this.daAnim = daAnim;
		this.goToPlayState = goToPlayState;
	}

	var UI_box:FlxUITabMenu;
	var UI_characterbox:FlxUITabMenu;

	private var camEditor:FlxCamera;
	private var camMenu:FlxCamera;
	private var camOther:FlxCamera;

	var changeBGbutton:FlxButton;
	var leHealthIcon:HealthIcon;
	var characterList:Array<String> = [];

	var cameraFollowPointer:FlxSprite;
	var healthBarBG:FlxSprite;
	var healthBarBGT:FlxSprite;
	var healthBarBGM:FlxSprite;
	var healthBarBGB:FlxSprite;

	var tipTexts:Array<FlxText> = [];
	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	//Set Mouse Listeners
	final mouse_listeners:Array<openfl.events.EventType<openfl.events.MouseEvent>> = [
		MouseEvent.MOUSE_DOWN, MouseEvent.RIGHT_MOUSE_DOWN, MouseEvent.MOUSE_UP, MouseEvent.RIGHT_MOUSE_UP, MouseEvent.MOUSE_MOVE
	];
	//Set Keyboard Listeners
	final keyboard_listener:Array<openfl.events.EventType<openfl.events.KeyboardEvent>> = [
		KeyboardEvent.KEY_DOWN, KeyboardEvent.KEY_UP
	];

	override function create()
	{
		Paths.clearUnusedCache();
		Paths.refreshModsMaps(true, true, true);
		if (PlayState.curStage != null && PlayState.curStage != '') currentStage = PlayState.curStage;
		music = new EditorMusic();

		for(listener in mouse_listeners) FlxG.stage.addEventListener(listener, handleMouseInput);
		for(listener in keyboard_listener) FlxG.stage.addEventListener(listener, handleKeyInput);

		camEditor = new FlxCamera();
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;
		camOther = new FlxCamera();
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camMenu, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		CustomFadeTransition.nextCamera = camOther;

		bgLayer = new FlxTypedGroup<FlxBasic>();
		add(bgLayer);
		fuckLayer = new FlxTypedGroup<FlxBasic>();
		add(fuckLayer);
		charLayer = new FlxTypedGroup<Character>();
		add(charLayer);
		frontLayer = new FlxTypedGroup<FlxBasic>();
		add(frontLayer);

		var pointer:FlxGraphic = FlxGraphic.fromClass(GraphicCursorCross);
		cameraFollowPointer = new FlxSprite().loadGraphic(pointer);
		cameraFollowPointer.setGraphicSize(40, 40);
		cameraFollowPointer.updateHitbox();
		cameraFollowPointer.color = FlxColor.WHITE;
		cameraFollowPointer.antialiasing = false;
		add(cameraFollowPointer);

		for (key in Paths.stageMap.keys()) {
			stages.push(key);
		}
		stages = CoolUtil.removeDuplicates(stages);
		for (s in ['philly', 'limo', 'mall', 'mallEvil', 'schoolEvil', 'tank'])
			stages.remove(s); //get rid of ones that arent supported (hard coded/hscript) (also school is kept because yea)
		stages.remove('stage');
		stages.insert(0, 'stage');

		stageDropDown = new FlxUIDropDownMenuCustom(FlxG.width - 400, 25, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true));
		stageDropDown.selectedLabel = currentStage;
		stageDropDown.cameras = [camMenu];
		changeBGbutton = new FlxButton(FlxG.width - 360, stageDropDown.y + 20, "Reload BG", function()
		{
			reloadBGs();
			char.setPosition(char.positionOffset.x + OFFSET_X + 100 + xPositioningOffset, char.positionOffset.y + yPositioningOffset); //we do it again so that it gets properly set lmao
			updatePointerPos();
		});
		changeBGbutton.cameras = [camMenu];
		blockPressWhileScrolling.push(stageDropDown);

		var json = getCharJson(daAnim);
		loadChar(daAnim, !json.player, false);

		healthBarBG = new FlxSprite(30, FlxG.height - 75).makeGraphic(601, 38, FlxColor.BLACK);
		healthBarBG.scrollFactor.set();
		healthBarBG.cameras = [camMenu];
		add(healthBarBG);

		healthBarBGT = new FlxSprite(37, FlxG.height - 65).makeGraphic(587, 6, FlxColor.WHITE);
		healthBarBGT.scrollFactor.set();
		healthBarBGT.cameras = [camMenu];

		healthBarBGM = new FlxSprite(37, FlxG.height - 59).makeGraphic(587, 6, FlxColor.WHITE);
		healthBarBGM.scrollFactor.set();
		healthBarBGM.cameras = [camMenu];

		healthBarBGB = new FlxSprite(37, FlxG.height - 53).makeGraphic(587, 6, FlxColor.WHITE);
		healthBarBGB.scrollFactor.set();
		healthBarBGB.cameras = [camMenu];

		//so we can resize
		add(healthBarBGB);
		add(healthBarBGM);
		add(healthBarBGT);

		leHealthIcon = new HealthIcon(char.iconProperties.name, false);
		leHealthIcon.x = char.iconProperties.offsets[0];
		leHealthIcon.y = (FlxG.height - 130) + char.iconProperties.offsets[1];
		leHealthIcon.antialiasing = char.iconProperties.antialiasing;
		add(leHealthIcon);
		leHealthIcon.cameras = [camMenu];

		offsetText = new FlxText(10, 20, 0, "ERROR! No animations found.", 15).setFormat(null, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetText.scrollFactor.set();
		offsetText.borderSize = 1;
		offsetText.cameras = [camMenu];
		add(offsetText);

		textAnim = new FlxText(300, 16);
		textAnim.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textAnim.borderSize = 1;
		textAnim.size = 32;
		textAnim.scrollFactor.set();
		textAnim.cameras = [camMenu];
		add(textAnim);

		genOffsetTexts();

		camFollow = FlxPoint.get();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		if (char != null) {
			snapCamFollowToPos(char.getMidpoint().x + 150, char.getMidpoint().y - 100);
		} else {
			snapCamFollowToPos(0, 0);
		}
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow.put();
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
		\nP - Play All Animations
		\nArrow Keys - Move Animation Offset
		\nT - Reset Current Offset
		\nHold Shift to Move 10x faster
		\nLeft Mouse - Drag Animation Offset
		\nRight Mouse - Drag Character Cam Offset\n".split('\n');

		for (i in 0...tipTextArray.length-1)
		{
			if(i % 2 == 1) continue; //would you believe me that making it not duplicate by writing this simple line took me 3 hours and half my brain mass? yeah it did, fuck you fellow psych dev responsible for this absolute dogwater of a tooltip
			var tipText:FlxText = new FlxText(FlxG.width - 320, (FlxG.height - 115 - 12 * (tipTextArray.length - i)) + (6 * (tipTextArray.length - 9)), 300, tipTextArray[i], 16);
			tipText.cameras = [camMenu];
			tipText.setFormat(null, 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.borderSize = 1;
			add(tipText);
			tipTexts.push(tipText);
		}

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.focusOn(camFollow);

		var tabs = [
			{name: 'Json', label: 'JSON'},
			{name: 'Controls', label: 'Controls'}
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
			{name: 'Gameover', label: 'Gameover'},
			{name: 'Misc', label: 'Misc'},
			{name: 'Animations', label: 'Animations'},
			{name: 'Icon', label: 'Icon'}
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

		addControlsUI();
		addJsonUI();

		addCharacterUI();
		addHealthbarUI();
		addGameoverUI();
		addMiscUI();
		addAnimationsUI();
		addIconsUI();
		UI_characterbox.selected_tab_id = 'Character';
		UI_box.selected_tab_id = 'Json';

		FlxG.mouse.visible = true;
		reloadCharacterOptions();

		super.create();
	}

	var OFFSET_X:Float = 300;
	function reloadBGs() {
		var i:Int = bgLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxBasic = bgLayer.members[i];
			if(memb != null) {
				bgLayer.remove(memb, true);
				memb.destroy();
			}
			--i;
		}
		bgLayer.clear();

		var i:Int = frontLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxBasic = frontLayer.members[i];
			if(memb != null) {
				frontLayer.remove(memb, true);
				memb.destroy();
			}
			--i;
		}
		frontLayer.clear();

		var i:Int = fuckLayer.members.length-1;
		while(i >= 0) {
			var memb:FlxBasic = fuckLayer.members[i];
			if(memb != null) {
				fuckLayer.remove(memb, true);
				memb.destroy();
			}
			--i;
		}
		fuckLayer.clear();

		var playerXDifference = 0;
		if(char != null){if(char.isPlayer) playerXDifference = 670;}

		var playerYDifference:Float = 0;
		cameraStageOffsets = [0,0];
		switch (currentStage)
		{
			case 'school':
				if(char.isPlayer) {
					playerXDifference += 200;
					playerYDifference = 0;
				}
	
				var bgSky:BGSprite = new BGSprite('vanilla/week6/weeb/weebSky', OFFSET_X - 400, -120, 0.1, 0.1);
				bgLayer.add(bgSky);
				bgSky.antialiasing = false;
	
				var repositionShit = -200 + OFFSET_X;
	
				var bgSchool:BGSprite = new BGSprite('vanilla/week6/weeb/weebSchool', repositionShit - 80, 106, 0.6, 0.90);
				bgLayer.add(bgSchool);
				bgSchool.antialiasing = false;
	
				var bgStreet:BGSprite = new BGSprite('vanilla/week6/weeb/weebStreet', repositionShit, 100, 0.95, 0.95);
				bgLayer.add(bgStreet);
				bgStreet.antialiasing = false;
	
				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.settings.get("lowQuality")) {
					var fgTrees:BGSprite = new BGSprite('vanilla/week6/weeb/weebTreesBack', repositionShit + 90, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					bgLayer.add(fgTrees);
					fgTrees.antialiasing = false;
				}
				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -700 - playerYDifference);
				bgTrees.frames = Paths.getPackerAtlas('vanilla/week6/weeb/weebTrees');
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

				if(char != null){
					if(char.isPlayer) {
						xPositioningOffset = 970;
						yPositioningOffset = 320;
					} else {
						xPositioningOffset = 100;
						yPositioningOffset = 100;
					}
				}
			default:
				Paths.setModsDirectoryFromType(STAGE, currentStage, false);
				var stageData:StageFile = StageData.getStageFile(currentStage) ?? StageData.getStageFile('stage'); //failsafe to prevent broken stages lol, if its still null then idk
				if (stageData.sprites == null) {
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
				} else {
					generateJSONSprites(stageData);
					if(char != null){
						if(char.isPlayer) {
							xPositioningOffset = stageData.boyfriend[0] - OFFSET_X;
							yPositioningOffset = stageData.boyfriend[1];
							cameraStageOffsets = stageData.camera_boyfriend;
						} else {
							xPositioningOffset = stageData.opponent[0] - OFFSET_X;
							yPositioningOffset = stageData.opponent[1];
							cameraStageOffsets = stageData.camera_opponent;
						}
					}
				}
				Paths.setModsDirectoryFromType(NONE, '', true);
		}
		if (char != null) {
			snapCamFollowToPos(char.getMidpoint().x + (char.isPlayer ? -100 : 150) + cameraStageOffsets[0], char.getMidpoint().y - 100 + cameraStageOffsets[1]);
		}
	}

	var TemplateCharacter:CharacterFile = 
	{
		"image": "characters/BOYFRIEND",
		"icon_props": {
			"name": "bf",
			"offsets": [0,0],
			"antialiasing": true
		},
		"flip_x": true,
		"no_antialiasing": false,
		"scale": 1,
		"position": [0,350],
		"camera_position": [0,0],
		"sing_duration": 4,
		"healthbar_count": 3,
		"healthbar_colors": [
			{
				red: 49,
				green: 176,
				blue: 209
			},
			{
				red: 29,
				green: 156,
				blue: 189
			},
			{
				red: 9,
				green: 136,
				blue: 169
			}
		],
		"sarvente_floating": false,
		"float_magnitude": 0.6,
		"float_speed": 1,
		"trail_data": {
			"enabled": false,
			"length": 4,
			"delay": 24,
			"diff": 0.069,
			"alpha": 0.3
		},
		"player": true,
		"health_drain": false,
		"drain_floor": 0.1,
		"drain_amount": 0.01,
		"shake_screen": false,
		"scare_bf": false,
		"scare_gf": false,
		"orbit": false,
		"death_props": {
			"character": "bf-dead",
			"startSfx": "fnf_loss_sfx",
			"loopSfx": "gameOver",
			"endSfx": "gameOverEnd",
			"bpm": 100
		},
		"animations": [
			{"anim": "idle","name": "BF idle dance","fps": 24,"loop": false,"loop_point": 0,"offsets": [-5,0],"indices": []},
			{"anim": "singLEFT","name": "BF NOTE LEFT0","fps": 24,"loop": false,"loop_point": 0,"offsets": [4,-6],"indices": []},
			{"offsets": [-20,-51],"loop": false,"fps": 24,"anim": "singDOWN","indices": [],"name": "BF NOTE DOWN0","loop_point": 0},
			{"offsets": [-48,27],"loop": false,"fps": 24,"anim": "singUP","indices": [],"name": "BF NOTE UP0","loop_point": 0},
			{"offsets": [-48,-7],"loop": false,"fps": 24,"anim": "singRIGHT","indices": [],"name": "BF NOTE RIGHT0","loop_point": 0},
			{"offsets": [-3,5],"loop": false,"fps": 24,"anim": "singSPACE","indices": [],"name": "BF HEY","loop_point": 0},
			{"offsets": [3,17],"loop": false,"fps": 24,"anim": "singLEFTmiss","indices": [],"name": "BF NOTE LEFT MISS","loop_point": 0},
			{"offsets": [-18,-22],"loop": false,"fps": 24,"anim": "singDOWNmiss","indices": [],"name": "BF NOTE DOWN MISS","loop_point": 0},
			{"offsets": [-43,27],"loop": false,"fps": 24,"anim": "singUPmiss","indices": [],"name": "BF NOTE UP MISS","loop_point": 0},
			{"offsets": [-44,19],"loop": false,"fps": 24,"anim": "singRIGHTmiss","indices": [],"name": "BF NOTE RIGHT MISS","loop_point": 0},
			{"loop": false,"offsets": [14,18],"anim": "singSPACEmiss","fps": 24,"name": "BF hit","indices": [3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18],"loop_point": 0}
		]
	};

	var disableMouseDragCheckbox:FlxUICheckBox;
	var disableWarningsCheckbox:FlxUICheckBox;
	var disableCamMovementCheckbox:FlxUICheckBox;
	inline function addControlsUI():Void {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Controls";

		disableMouseDragCheckbox = new FlxUICheckBox(10, 20, null, null, "Disable Mouse Dragging", 200);
		disableMouseDragCheckbox.checked = false;

		/*disableWarningsCheckbox = new FlxUICheckBox(10, 40, null, null, "Disable Warnings", 200);
		disableWarningsCheckbox.checked = false;*/

		//valid haxe i swear -AT
		var updateMouseDisabled:Void->Void = function()
		{
			final changeTexts:Array<FlxText> = [tipTexts[9], tipTexts[10]];
			for(i => tipText in changeTexts) {
				tipText.alpha = disableMouseDragCheckbox.checked ? 0.5 : 1;
				tipText.text = disableMouseDragCheckbox.checked ? tipText.text + ' [Disabled]' : tipText.text.replace(' [Disabled]', '');
				if(i == 1) tipText.y += disableMouseDragCheckbox.checked ? 14 : -14; 
			}
		}
		disableMouseDragCheckbox.callback = updateMouseDisabled;

		//Using updatePointerPos instead because it already checks our shit
		disableCamMovementCheckbox = new FlxUICheckBox(10, disableMouseDragCheckbox.y + 40, null, null, "Disable Auto Cam-align", 200, null, ()-> updatePointerPos());
		disableCamMovementCheckbox.checked = false;

		tab_group.add(disableMouseDragCheckbox);
		//tab_group.add(disableWarningsCheckbox);
		tab_group.add(disableCamMovementCheckbox);
		UI_box.addGroup(tab_group);
	}

	var charDropDown:FlxUIDropDownMenuCustom;
	inline function addJsonUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Json";

		charDropDown = new FlxUIDropDownMenuCustom(60, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(character:String)
		{
			daAnim = characterList[Std.parseInt(character)];
			var json = getCharJson(daAnim);
			check_player.checked = json.player;
			loadChar(daAnim, !check_player.checked);
			updatePresence();
			reloadCharacterDropDown();
		});
		charDropDown.selectedLabel = daAnim;
		reloadCharacterDropDown();
		blockPressWhileScrolling.push(charDropDown);

		var reloadCharacter:FlxButton = new FlxButton(20, 65, "Reload JSON", function()
		{
			loadChar(daAnim, !check_player.checked);
			reloadCharacterDropDown();
		});
		reloadCharacter.color = 0xffff7e00;
		reloadCharacter.label.color = FlxColor.WHITE;

		var templateCharacter:FlxButton = new FlxButton(135, 65, "Load Template", function()
		{
			var parsedJson:CharacterFile = TemplateCharacter;
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
				character.positionOffset.set(parsedJson.position[0], parsedJson.position[1]);
				character.cameraPosition.set(parsedJson.camera_position[0], parsedJson.camera_position[1]);
				
				character.imageFile = parsedJson.image;
				character.jsonScale = parsedJson.scale;
				character.noAntialiasing = parsedJson.no_antialiasing;
				character.originalFlipX = parsedJson.flip_x;
				character.sarventeFloating = parsedJson.sarvente_floating;
				character.orbit = parsedJson.orbit;
				character.trailData = parsedJson.trail_data;
				character.shakeScreen = parsedJson.shake_screen;
				character.scareBf = parsedJson.scare_bf;
				character.scareGf = parsedJson.scare_gf;
				character.healthDrain = parsedJson.health_drain;
				character.iconProperties.name = parsedJson.icon_props.name;
				character.iconProperties.offsets = parsedJson.icon_props.offsets;
				character.iconProperties.antialiasing = parsedJson.icon_props.antialiasing;
				character.healthColorArray = parsedJson.healthbar_colors;
				character.setPosition(character.positionOffset.x + OFFSET_X + 100, character.positionOffset.y);
			}

			reloadCharacterImage();
			reloadCharacterDropDown();
			reloadCharacterOptions();
			resetHealthBarColor();
			resetHealthBarCount();
			updatePointerPos();
			genOffsetTexts();
		});
		templateCharacter.color = FlxColor.CYAN;
		templateCharacter.label.color = FlxColor.WHITE;
		
		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 0, 'Character:'));
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
		UI_box.addGroup(tab_group);
	}
	
	var imageInputText:FlxUIInputText;
	var singDurationStepper:FlxUINumericStepper;
	var scaleStepper:FlxUINumericStepper;
	var positionXStepper:FlxUINumericStepper;
	var positionYStepper:FlxUINumericStepper;
	var positionCameraXStepper:FlxUINumericStepper;
	var positionCameraYStepper:FlxUINumericStepper;
	var flipXCheckBox:FlxUICheckBox;
	var noAntialiasingCheckBox:FlxUICheckBox;
	var check_player:FlxUICheckBox;

	inline function addCharacterUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(15, 30, 200, 'characters/BOYFRIEND', 8);
		imageInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(imageInputText);

		var reloadImage:FlxButton = new FlxButton(imageInputText.x + 210, imageInputText.y - 13, "Reload Image", function()
		{
			char.imageFile = imageInputText.text;
			reloadCharacterImage();
			if(char.animation.curAnim != null) {
				char.playAnim(char.animation.curAnim.name, true);
			}
		});
		reloadImage.color = 0xffff7e00;
		reloadImage.label.color = FlxColor.WHITE;

		singDurationStepper = new FlxUINumericStepper(15, imageInputText.y + 55, 0.1, 4, 0, 999, 1);
		singDurationStepper.name = 'singDurationStepper';
		blockPressWhileTypingOnStepper.push(singDurationStepper);

		scaleStepper = new FlxUINumericStepper(15, singDurationStepper.y + 60, 0.1, 1, 0.05, 20, 1);
		scaleStepper.name = 'scaleStepper';
		blockPressWhileTypingOnStepper.push(scaleStepper);

		flipXCheckBox = new FlxUICheckBox(singDurationStepper.x + 80, singDurationStepper.y, null, null, "Flip X", 50);
		flipXCheckBox.checked = char.flipX;
		if(char.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.callback = function() {
			char.originalFlipX = !char.originalFlipX;
			char.flipX = char.originalFlipX;
			if(char.isPlayer) char.flipX = !char.flipX;
			
			ghostChar.flipX = char.flipX;
		};

		noAntialiasingCheckBox = new FlxUICheckBox(flipXCheckBox.x, flipXCheckBox.y + 30, null, null, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = char.noAntialiasing;
		noAntialiasingCheckBox.callback = function() {
			char.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.settings.get("globalAntialiasing")) {
				char.antialiasing = true;
			}
			char.noAntialiasing = noAntialiasingCheckBox.checked;
			ghostChar.antialiasing = char.antialiasing;
		};

		check_player = new FlxUICheckBox(noAntialiasingCheckBox.x, noAntialiasingCheckBox.y + 30, null, null, "Player", 100);
		var json = getCharJson(daAnim);
		check_player.checked = json.player;
		check_player.callback = function()
		{
			char.isPlayer = !char.isPlayer;
			char.cameraPosition.set(char.cameraPosition.x * -1, char.cameraPosition.y);
			positionCameraXStepper.value = char.cameraPosition.x;
			positionCameraYStepper.value = char.cameraPosition.y;
			char.positionOffset.set(char.positionOffset.x * -1, char.positionOffset.y);
			positionXStepper.value = char.positionOffset.x;
			positionYStepper.value = char.positionOffset.y;
			char.flipX = !char.flipX;
			reloadBGs();
			char.setPosition(char.positionOffset.x + OFFSET_X + 100 + xPositioningOffset, char.positionOffset.y + yPositioningOffset); //we do it again so that it gets properly set lmao
			snapCamFollowToPos(char.getMidpoint().x + (char.isPlayer ? -100 : 150) + cameraStageOffsets[0], char.getMidpoint().y - 100 + cameraStageOffsets[1]);
			ghostChar.flipX = char.flipX;
			updatePointerPos();
		};

		positionXStepper = new FlxUINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, char.positionOffset.x, -9000, 9000, 0);
		positionXStepper.name = 'positionXStepper';
		positionYStepper = new FlxUINumericStepper(positionXStepper.x + 60, positionXStepper.y, 10, char.positionOffset.y, -9000, 9000, 0);
		positionYStepper.name = 'positionYStepper';
		blockPressWhileTypingOnStepper.push(positionXStepper);
		blockPressWhileTypingOnStepper.push(positionYStepper);
		
		positionCameraXStepper = new FlxUINumericStepper(positionXStepper.x, positionXStepper.y + 60, 10, char.cameraPosition.x, -9000, 9000, 0);
		positionCameraXStepper.name = 'positionCameraXStepper';
		positionCameraYStepper = new FlxUINumericStepper(positionYStepper.x, positionYStepper.y + 60, 10, char.cameraPosition.y, -9000, 9000, 0);
		positionCameraYStepper.name = 'positionCameraYStepper';
		blockPressWhileTypingOnStepper.push(positionCameraXStepper);
		blockPressWhileTypingOnStepper.push(positionCameraYStepper);

		var saveCharacterButton:FlxButton = new FlxButton(reloadImage.x, reloadImage.y + 20, "Save Character", function() {
			saveCharacter();
		});
		saveCharacterButton.color = FlxColor.LIME;
		saveCharacterButton.label.color = FlxColor.WHITE;

		var jumpCameraButton:FlxButton = new FlxButton(reloadImage.x, noAntialiasingCheckBox.y + 60, "Align Cam", tweenCameraToPlayStatePos);

		tab_group.add(new FlxText(15, imageInputText.y - 18, 0, 'Image:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 0, 'Sing Length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 0, 'X/Y Offset:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 0, 'Camera X/Y:'));
		tab_group.add(check_player);
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
		tab_group.add(jumpCameraButton);
		UI_characterbox.addGroup(tab_group);
	}

	var healthIconInputText:FlxUIInputText;

	var hpBarCountStepper:FlxUINumericStepper = null;
	var healthColorStepperR:FlxUINumericStepper = null;
	var healthColorStepperG:FlxUINumericStepper = null;
	var healthColorStepperB:FlxUINumericStepper = null;
	var healthColorStepperRM:FlxUINumericStepper = null;
	var healthColorStepperGM:FlxUINumericStepper = null;
	var healthColorStepperBM:FlxUINumericStepper = null;
	var healthColorStepperRB:FlxUINumericStepper = null;
	var healthColorStepperGB:FlxUINumericStepper = null;
	var healthColorStepperBB:FlxUINumericStepper = null;

	var allSteppers:HaxeVector<FlxUINumericStepper> = null;
	function getAllSteppers(forceReload:Bool = false):HaxeVector<FlxUINumericStepper> { //Seperated function because reinitializing vector and all that each time isnt very nice
		if(allSteppers != null && !forceReload) return allSteppers;
		allSteppers = null; //Reset!!!

		allSteppers = new HaxeVector(9); //Initialize length first
		allSteppers = HaxeVector.fromArrayCopy([
			healthColorStepperR, healthColorStepperG, healthColorStepperB,
			healthColorStepperRM, healthColorStepperGM, healthColorStepperBM,
			healthColorStepperRB, healthColorStepperGB, healthColorStepperBB
		]);
		return allSteppers;
	}

	//Written by YanniZ06 guhh yes im gonna put my credit on this shit stay MAD im proud of this!!!
	function toggleEyedropping() {
		// draw clip of temp sprite's pixels to my `target` sprite
		//target.pixels.draw(tempSprite.pixels, null, null, null, new Rectangle(2, 2, 16, 16));
		if (eyedropperPreview == null) {
			eyedropperPreview = new FlxSprite(FlxG.mouse.screenX, FlxG.mouse.screenY).makeGraphic(100, 100, FlxColor.WHITE);
			eyedropperPreview.cameras = [camMenu];
			add(eyedropperPreview);
	
			initZoom = FlxG.camera.zoom;
			if(tweensMap.exists("zoomNormal")) tweensMap["zoomNormal"].cancel();
			tweensMap.set("zoomForce", FlxTween.tween(FlxG.camera, {zoom: 1}, 0.15, {ease: FlxEase.sineOut, onComplete: function(_) {
				var mousePos:FlxPoint = FlxPoint.get(FlxG.mouse.screenX, FlxG.mouse.screenY);
				FlxTween.tween(eyedropperPreview, {x: mousePos.x, y: mousePos.y}, FlxG.mouse.TIME_BUFFER, {ease: FlxEase.circOut});
				FlxTween.color(eyedropperPreview, FlxG.mouse.TIME_BUFFER, eyedropperPreview.color, FlxColor.fromInt(FlxG.camera.getPixel(mousePos)));
				mousePos.put();
			}}));
			eyedropping = true;
			return;
		}
		eyedropping = false;
		eyedropperPreview.destroy();
	
		if(tweensMap.exists("zoomForce")) tweensMap["zoomForce"].cancel();
		tweensMap.set("zoomNormal", FlxTween.tween(FlxG.camera, {zoom: initZoom}, 0.15, {ease: FlxEase.sineOut}));
		eyedropperPreview = null;
	}

	var eyedropperButton:FlxButton;
	inline function addHealthbarUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Healthbar";

		var decideIconColor:FlxButton = new FlxButton(225, 17 /*27*/, "Dmnt. Color", function()
		{
			var coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leHealthIcon));

			var colorInfo:HaxeVector<Int> = new HaxeVector(3);
			colorInfo[0] = coolColor.red; 
			colorInfo[1] = coolColor.green; 
			colorInfo[2] = coolColor.blue;

			var steppers = getAllSteppers();
			var barIterations:Int = -1;
			for(i in 0...9) {
				if(i % 3 == 0) barIterations++;

				steppers[i].value = colorInfo[i % 3] - (20 * barIterations);
				getEvent(FlxUINumericStepper.CHANGE_EVENT, steppers[i], null);
			}
		});

		healthIconInputText = new FlxUIInputText(15, 30, 200, leHealthIcon.char, 8);
		healthIconInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(healthIconInputText);

		hpBarCountStepper = new FlxUINumericStepper(decideIconColor.x, healthIconInputText.y + 65, 1, 1, 1, 3, 0);
		hpBarCountStepper.name = 'hpBarCountStepper';
		blockPressWhileTypingOnStepper.push(hpBarCountStepper);

		function getColorFromArray(rgbObject:HealthBarRBG, colorType:Int = 0):Int {
			switch(colorType) {
				case 0: return rgbObject.red;
				case 1:	return rgbObject.green;
				case 2: return rgbObject.blue;
			}
			return FlxColor.BLACK;
		}

		var stepperNameCodes:HaxeVector<HaxeVector<String>> = new HaxeVector(3);
		stepperNameCodes[0] = HaxeVector.fromArrayCopy(['R', '']); 
		stepperNameCodes[1] = HaxeVector.fromArrayCopy(['G', 'M']);
		stepperNameCodes[2] = HaxeVector.fromArrayCopy(['B', 'B']);
		
		var steppers_ = getAllSteppers();
		var typeCounter:Int = -1; //? determines if its '' 'M' or 'B', ask AT he did the original naming
		for(i in 0...9) { 
			if(i % 3 == 0) typeCounter++;
			final stepperName:String = 'healthColorStepper${stepperNameCodes[i % 3][0]}${stepperNameCodes[typeCounter][1]}';

			steppers_[i] = new FlxUINumericStepper(15 + (65 * (i % 3)), (healthIconInputText.y + 65) + (22 * typeCounter), 20,
			 getColorFromArray(char.healthColorArray[typeCounter], i % 3), 0, 255, 0);
			steppers_[i].name = stepperName;

			Reflect.setField(this, stepperName, steppers_[i]); //We hopefully avoid a null ref
			blockPressWhileTypingOnStepper.push(steppers_[i]); 
		}
		
		eyedropperButton = new FlxButton(225, 37, "Eyedropper", toggleEyedropping);

		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 0, 'Icon Name:'));
		tab_group.add(new FlxText(hpBarCountStepper.x, hpBarCountStepper.y - 18, 0, 'Bars:'));
		tab_group.add(new FlxText(healthColorStepperR.x, healthColorStepperR.y - 18, 0, 'Health Bar R/G/B:'));
		tab_group.add(decideIconColor);
		tab_group.add(eyedropperButton);
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

	var deathNameText:FlxUIInputText;
	var deathStartText:FlxUIInputText;
	var deathEndText:FlxUIInputText;
	var deathMusicText:FlxUIInputText;
	var deathBpmStepper:FlxUINumericStepper;

	inline function addGameoverUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Gameover";

		deathNameText = new FlxUIInputText(15, 30, 150, 'bf-dead', 8);
		deathNameText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		deathStartText = new FlxUIInputText(deathNameText.x + 170, deathNameText.y, 150, 'fnf_loss_sfx', 8);
		deathStartText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		deathEndText = new FlxUIInputText(deathStartText.x, deathStartText.y + 45, 150, 'gameOverEnd', 8);
		deathEndText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		deathMusicText = new FlxUIInputText(deathNameText.x, deathNameText.y + 45, 150, 'gameOver', 8);
		deathMusicText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;

		blockPressWhileTypingOn.push(deathNameText);
		blockPressWhileTypingOn.push(deathStartText);
		blockPressWhileTypingOn.push(deathEndText);
		blockPressWhileTypingOn.push(deathMusicText);

		deathBpmStepper = new FlxUINumericStepper(deathMusicText.x, deathMusicText.y + 45, 1, 100, 1, 9999, 0);
		deathBpmStepper.name = 'deathBpmStepper';
		blockPressWhileTypingOnStepper.push(deathBpmStepper);

		tab_group.add(new FlxText(deathNameText.x, deathNameText.y - 18, 0, 'Character:'));
		tab_group.add(new FlxText(deathStartText.x, deathStartText.y - 18, 0, 'Start Sound:'));
		tab_group.add(new FlxText(deathEndText.x, deathEndText.y - 18, 0, 'End Sound:'));
		tab_group.add(new FlxText(deathMusicText.x, deathMusicText.y - 18, 0, 'Music:'));
		tab_group.add(new FlxText(deathBpmStepper.x, deathBpmStepper.y - 18, 0, 'BPM:'));

		tab_group.add(deathNameText);
		tab_group.add(deathStartText);
		tab_group.add(deathEndText);
		tab_group.add(deathMusicText);
		tab_group.add(deathBpmStepper);

		UI_characterbox.addGroup(tab_group);
	}

	var floatMagnitudeStepper:FlxUINumericStepper;
	var floatSpeedStepper:FlxUINumericStepper;
	var trailLengthStepper:FlxUINumericStepper;
	var trailDelayStepper:FlxUINumericStepper;
	var trailAlphaStepper:FlxUINumericStepper;
	var trailDiffStepper:FlxUINumericStepper;
	var drainFloorStepper:FlxUINumericStepper;
	var drainAmountStepper:FlxUINumericStepper;

	var sarventeFloatingCheckBox:FlxUICheckBox;
	var orbitCheckBox:FlxUICheckBox;
	var flixelTrailCheckBox:FlxUICheckBox;
	var screenShakeCheckBox:FlxUICheckBox;
	var scareBfCheckBox:FlxUICheckBox;
	var scareGfCheckBox:FlxUICheckBox;
	var healthDrainCheckBox:FlxUICheckBox;
	inline function addMiscUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Misc";

		sarventeFloatingCheckBox = new FlxUICheckBox(15, 20, null, null, "Floating", 50);
		sarventeFloatingCheckBox.checked = char.sarventeFloating;
		sarventeFloatingCheckBox.callback = function() {
			char.sarventeFloating = false;
			if(sarventeFloatingCheckBox.checked) {
				char.sarventeFloating = true;
			}
			char.sarventeFloating = sarventeFloatingCheckBox.checked;
			ghostChar.sarventeFloating = char.sarventeFloating;
		};

		floatMagnitudeStepper = new FlxUINumericStepper(sarventeFloatingCheckBox.x + 80, sarventeFloatingCheckBox.y, 0.05, 0.05, 0.05, 10, 2);
		floatMagnitudeStepper.name = 'floatMagnitudeStepper';

		floatSpeedStepper = new FlxUINumericStepper(sarventeFloatingCheckBox.x + 180, sarventeFloatingCheckBox.y, 0.1, 1, 0.1, 10, 1);
		floatSpeedStepper.name = 'floatSpeedStepper';
		blockPressWhileTypingOnStepper.push(floatMagnitudeStepper);
		blockPressWhileTypingOnStepper.push(floatSpeedStepper);

		flixelTrailCheckBox = new FlxUICheckBox(sarventeFloatingCheckBox.x, sarventeFloatingCheckBox.y + 40, null, null, "Trail", 50);
		flixelTrailCheckBox.checked = char.trailData.enabled;
		flixelTrailCheckBox.callback = function() {
			char.trailData.enabled = false;
			if(flixelTrailCheckBox.checked) {
				char.trailData.enabled = true;
			}
			char.trailData.enabled = flixelTrailCheckBox.checked;
			ghostChar.trailData.enabled = char.trailData.enabled;
		};

		trailLengthStepper = new FlxUINumericStepper(flixelTrailCheckBox.x + 60, flixelTrailCheckBox.y, 1, 4, 1, 24, 1);
		trailLengthStepper.name = 'trailLengthStepper';
		trailDelayStepper = new FlxUINumericStepper(trailLengthStepper.x + 70, flixelTrailCheckBox.y, 1, 24, 0, 90, 1);
		trailDelayStepper.name = 'trailDelayStepper';
		trailAlphaStepper = new FlxUINumericStepper(trailDelayStepper.x + 70, flixelTrailCheckBox.y, 0.1, 0.3, 0, 1, 3);
		trailAlphaStepper.name = 'trailAlphaStepper';
		trailDiffStepper = new FlxUINumericStepper(trailAlphaStepper.x + 70, flixelTrailCheckBox.y, 0.05, 0.069, 0, 1, 4);
		trailDiffStepper.name = 'trailDiffStepper';
		blockPressWhileTypingOnStepper.push(trailLengthStepper);
		blockPressWhileTypingOnStepper.push(trailDelayStepper);
		blockPressWhileTypingOnStepper.push(trailAlphaStepper);
		blockPressWhileTypingOnStepper.push(trailDiffStepper);

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

		drainFloorStepper = new FlxUINumericStepper(healthDrainCheckBox.x + 80, healthDrainCheckBox.y, 0.05, 0.1, -1, 2, 3);
		drainFloorStepper.name = 'drainFloorStepper';
		blockPressWhileTypingOnStepper.push(drainFloorStepper);

		drainAmountStepper = new FlxUINumericStepper(drainFloorStepper.x + 90, healthDrainCheckBox.y, 0.05, 0.01, 0, 2, 3);
		drainAmountStepper.name = 'drainAmountStepper';
		blockPressWhileTypingOnStepper.push(drainAmountStepper);

		tab_group.add(new FlxText(floatMagnitudeStepper.x, floatMagnitudeStepper.y - 18, 0, 'Float Magnitude:'));
		tab_group.add(new FlxText(floatSpeedStepper.x, floatSpeedStepper.y - 18, 0, 'Float Speed:'));
		tab_group.add(new FlxText(trailLengthStepper.x, trailLengthStepper.y - 18, 0, 'Trail Length:'));
		tab_group.add(new FlxText(trailDelayStepper.x, trailDelayStepper.y - 18, 0, 'Trail Delay:'));
		tab_group.add(new FlxText(trailAlphaStepper.x, trailAlphaStepper.y - 18, 0, 'Trail Alpha:'));
		tab_group.add(new FlxText(trailDiffStepper.x, trailDiffStepper.y - 18, 0, 'Trail Diff:'));
		tab_group.add(new FlxText(drainFloorStepper.x, drainFloorStepper.y - 18, 0, 'Minimum Health:'));
		tab_group.add(new FlxText(drainAmountStepper.x, drainAmountStepper.y - 18, 0, 'Drain Amount:'));
		tab_group.add(floatMagnitudeStepper);
		tab_group.add(floatSpeedStepper);
		tab_group.add(trailLengthStepper);
		tab_group.add(trailDelayStepper);
		tab_group.add(trailAlphaStepper);
		tab_group.add(trailDiffStepper);
		tab_group.add(drainFloorStepper);
		tab_group.add(drainAmountStepper);
		tab_group.add(sarventeFloatingCheckBox);
		tab_group.add(flixelTrailCheckBox);
		tab_group.add(orbitCheckBox);
		tab_group.add(screenShakeCheckBox);
		tab_group.add(scareBfCheckBox);
		tab_group.add(scareGfCheckBox);
		tab_group.add(healthDrainCheckBox);
		UI_characterbox.addGroup(tab_group);
	}

	//please add what it is after so its easier to search for please and thank you (i mean the checkboxes and shit)
	var editOffsetsCheckbox:FlxUICheckBox;
	var iconOffsets:Array<Float> = [0, 0];
	var iconAntialiasingCheckbox:FlxUICheckBox;
	var iconOffsetXStepper:FlxUINumericStepper;
	var iconOffsetYStepper:FlxUINumericStepper;
	var iconFrameStepper:FlxUINumericStepper;
	inline function addIconsUI() { //if an entire function for this is truly necessary? probably not, but i might add onto it and its better to stick to the codebase
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Icon";

		editOffsetsCheckbox = new FlxUICheckBox(15, 30, null, null, "Edit Icon Offsets", 100);
		iconAntialiasingCheckbox = new FlxUICheckBox(editOffsetsCheckbox.x, 65, null, null, "Icon Antialiasing", 100);
		iconAntialiasingCheckbox.checked = char.iconProperties.antialiasing;

		function setProperties(text:FlxText, scalus:Int = 12) {
			text.size = scalus;
			text.borderStyle = OUTLINE;
			text.borderColor = FlxColor.BLACK;
		}

		//going to just make these steppers since its easier
		iconOffsetXStepper = new FlxUINumericStepper(iconAntialiasingCheckbox.x, iconAntialiasingCheckbox.y + 60, 5, 0, -9999, 9999, 0);
		iconOffsetXStepper.name = 'iconOffsetXStepper';
		iconOffsetYStepper = new FlxUINumericStepper(iconAntialiasingCheckbox.x + 60, iconAntialiasingCheckbox.y + 60, 5, 0, -9999, 9999, 0);
		iconOffsetYStepper.name = 'iconOffsetYStepper';
		blockPressWhileTypingOnStepper.push(iconOffsetXStepper);
		blockPressWhileTypingOnStepper.push(iconOffsetYStepper);

		iconFrameStepper = new FlxUINumericStepper(iconAntialiasingCheckbox.x, iconAntialiasingCheckbox.y + 100, 1, 0, 0, 2, 0);
		iconFrameStepper.name = 'iconFrameStepper';
		blockPressWhileTypingOnStepper.push(iconFrameStepper);

		tab_group.add(editOffsetsCheckbox);
		tab_group.add(iconAntialiasingCheckbox);
		tab_group.add(iconOffsetXStepper);
		tab_group.add(iconOffsetYStepper);
		tab_group.add(iconFrameStepper);
		tab_group.add(new FlxText(iconOffsetXStepper.x, iconOffsetXStepper.y - 18, 0, 'Icon Offset X/Y:'));
		tab_group.add(new FlxText(iconFrameStepper.x, iconFrameStepper.y - 18, 0, 'Icon Frame:'));
		UI_characterbox.addGroup(tab_group);
	}

	var ghostDropDown:FlxUIDropDownMenuCustom;
	var animationDropDown:FlxUIDropDownMenuCustom;
	var xmlAnimDropDown:FlxUIDropDownMenuCustom;
	var xmlAnims:Array<String> = [];
	var animationInputText:FlxUIInputText;
	var animationNameInputText:FlxUIInputText;
	var animationIndicesInputText:FlxUIInputText;
	var animationNameFramerate:FlxUINumericStepper;
	var animationLoopCheckBox:FlxUICheckBox;
	var loopPointStepper:FlxUINumericStepper;
	inline function addAnimationsUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Animations";
		
		animationInputText = new FlxUIInputText(15, 85, 150, '', 8);
		animationInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationNameInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 130, '', 8);
		animationNameInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationIndicesInputText = new FlxUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationIndicesInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		animationNameFramerate = new FlxUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new FlxUICheckBox(animationNameInputText.x + 270, animationNameInputText.y - 1, null, null, "Loop", 100);

		blockPressWhileTypingOnStepper.push(animationNameFramerate);
		blockPressWhileTypingOn.push(animationInputText);
		blockPressWhileTypingOn.push(animationNameInputText);
		blockPressWhileTypingOn.push(animationIndicesInputText);

		animationDropDown = new FlxUIDropDownMenuCustom(15, animationInputText.y - 55, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			var anim:AnimArray = char.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationNameFramerate.value = anim.fps;
			loopPointStepper.value = anim.loop_point;

			var indicesStr:String = (anim.indices == null ? '' : anim.indices.toString());
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});
		blockPressWhileScrolling.push(animationDropDown);

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
		blockPressWhileScrolling.push(ghostDropDown);

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
				offsets: lastOffsets,
				loop_point: Math.round(loopPointStepper.value),
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
			reloadXmlAnimDropDown();
			animationDropDown.changeSelection(animationInputText.text);
			genOffsetTexts();
			trace('Added/Updated animation: ' + animationInputText.text);
		});
		addUpdateButton.color = FlxColor.LIME;
		addUpdateButton.label.color = FlxColor.WHITE;

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
					reloadXmlAnimDropDown();
					genOffsetTexts();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
			}
		});
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;

		loopPointStepper = new FlxUINumericStepper(animationNameFramerate.x + 60, animationNameFramerate.y, 1, 0, 0, 9999, 1);
		loopPointStepper.name = 'loopPointStepper';
		tab_group.add(new FlxText(loopPointStepper.x, loopPointStepper.y - 18, 0, 'Loop Frame:'));
		blockPressWhileTypingOnStepper.push(loopPointStepper);

		Paths.setModsDirectoryFromType(CHARACTER, char.curCharacter, false);
		xmlAnims = char.getAnimationsFromXml();
		if(xmlAnims.length < 1) xmlAnims.push('NONE / NOT SUPPORTED');
		xmlAnimDropDown = new FlxUIDropDownMenuCustom(animationNameInputText.x + animationNameInputText.width + 10, animationNameInputText.y - 3, FlxUIDropDownMenuCustom.makeStrIdLabelArray(xmlAnims, true), function(pressed:String) {
			var selectedAnimation:Int = Std.parseInt(pressed);
			animationNameInputText.text = xmlAnims[selectedAnimation];
		});
		blockPressWhileScrolling.push(xmlAnimDropDown);
		Paths.setModsDirectoryFromType(NONE, '', true);

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(ghostDropDown.x, ghostDropDown.y - 18, 0, 'Offset Ghost:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation Tag:'));
		tab_group.add(new FlxText(animationNameFramerate.x, animationNameFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation Prefix:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'Animation Indices:'));
		tab_group.add(new FlxText(xmlAnimDropDown.x, xmlAnimDropDown.y - 15, 0, 'Loaded Prefixes:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationNameFramerate);
		tab_group.add(loopPointStepper);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(xmlAnimDropDown);
		tab_group.add(ghostDropDown);
		tab_group.add(animationDropDown);
		UI_characterbox.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == healthIconInputText) {
				Paths.setModsDirectoryFromType(ICON, healthIconInputText.text, false);
				leHealthIcon.changeIcon(healthIconInputText.text);
				char.iconProperties.name = healthIconInputText.text;
				updatePresence();
				Paths.setModsDirectoryFromType(NONE, '', true);
			}
			else if(sender == imageInputText) {
				char.imageFile = imageInputText.text;
			}
			else if(sender == deathNameText) {
				char.deathProperties.character = deathNameText.text;
			}
			else if(sender == deathStartText) {
				char.deathProperties.startSfx = deathStartText.text;
			}
			else if(sender == deathMusicText) {
				char.deathProperties.loopSfx = deathMusicText.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			switch(cast(sender, FlxUINumericStepper).name) {
				case 'scaleStepper':
					reloadCharacterImage();
					char.jsonScale = scaleStepper.value;
					char.scale.set(char.jsonScale, char.jsonScale);
					char.updateHitbox();
					ghostChar.scale.set(char.jsonScale, char.jsonScale);
					ghostChar.updateHitbox();
					reloadGhost();
					updatePointerPos();
	
					if(char.animation.curAnim != null) {
						char.playAnim(char.animation.curAnim.name, true);
					}
				case 'positionXStepper':
					char.positionOffset.x = positionXStepper.value;
					char.x = xPositioningOffset + char.positionOffset.x + OFFSET_X + 100;
					updatePointerPos();
				case 'positionYStepper':
					char.positionOffset.y = positionYStepper.value;
					char.y = yPositioningOffset + char.positionOffset.y;
					updatePointerPos();
				case 'singDurationStepper':
					char.singDuration = singDurationStepper.value;
				case 'positionCameraXStepper':
					char.cameraPosition.x = positionCameraXStepper.value;
					updatePointerPos();
				case 'positionCameraYStepper':
					char.cameraPosition.y = positionCameraYStepper.value;
					updatePointerPos();
				case 'healthColorStepperR':
					char.healthColorArray[0].red = Math.round(healthColorStepperR.value);
					healthBarBGT.color = FlxColor.fromRGB(char.healthColorArray[0].red, char.healthColorArray[0].green, char.healthColorArray[0].blue);
				case 'healthColorStepperG':
					char.healthColorArray[0].green = Math.round(healthColorStepperG.value);
					healthBarBGT.color = FlxColor.fromRGB(char.healthColorArray[0].red, char.healthColorArray[0].green, char.healthColorArray[0].blue);
				case 'healthColorStepperB':
					char.healthColorArray[0].blue = Math.round(healthColorStepperB.value);
					healthBarBGT.color = FlxColor.fromRGB(char.healthColorArray[0].red, char.healthColorArray[0].green, char.healthColorArray[0].blue);
				case 'healthColorStepperRM':
					char.healthColorArray[1].red = Math.round(healthColorStepperRM.value);
					healthBarBGM.color = FlxColor.fromRGB(char.healthColorArray[1].red, char.healthColorArray[1].green, char.healthColorArray[1].blue);
				case 'healthColorStepperGM':
					char.healthColorArray[1].green = Math.round(healthColorStepperGM.value);
					healthBarBGM.color = FlxColor.fromRGB(char.healthColorArray[1].red, char.healthColorArray[1].green, char.healthColorArray[1].blue);
				case 'healthColorStepperBM':
					char.healthColorArray[1].blue = Math.round(healthColorStepperBM.value);
					healthBarBGM.color = FlxColor.fromRGB(char.healthColorArray[1].red, char.healthColorArray[1].green, char.healthColorArray[1].blue);
				case 'healthColorStepperRB':
					char.healthColorArray[2].red = Math.round(healthColorStepperRB.value);
					healthBarBGB.color = FlxColor.fromRGB(char.healthColorArray[2].red, char.healthColorArray[2].green, char.healthColorArray[2].blue);
				case 'healthColorStepperGB':
					char.healthColorArray[2].green = Math.round(healthColorStepperGB.value);
					healthBarBGB.color = FlxColor.fromRGB(char.healthColorArray[2].red, char.healthColorArray[2].green, char.healthColorArray[2].blue);
				case 'healthColorStepperBB':
					char.healthColorArray[2].blue = Math.round(healthColorStepperBB.value);
					healthBarBGB.color = FlxColor.fromRGB(char.healthColorArray[2].red, char.healthColorArray[2].green, char.healthColorArray[2].blue);
				case 'hpBarCountStepper':
					char.healthBarCount = Math.round(hpBarCountStepper.value);
					resetHealthBarCount();
				case 'floatMagnitudeStepper':
					char.floatMagnitude = floatMagnitudeStepper.value;
				case 'floatSpeedStepper':
					char.floatSpeed = floatSpeedStepper.value;
				case 'trailLengthStepper':
					char.trailData.length = Math.round(trailLengthStepper.value);
				case 'trailDelayStepper':
					char.trailData.delay = Math.round(trailDelayStepper.value);
				case 'trailAlphaStepper':
					char.trailData.alpha = trailAlphaStepper.value;
				case 'trailDiffStepper':
					char.trailData.diff = trailDiffStepper.value;
				case 'drainFloorStepper':
					char.drainFloor = drainFloorStepper.value;
				case 'drainAmountStepper':
					char.drainAmount = drainAmountStepper.value;
				case 'deathBpmStepper':
					char.deathProperties.bpm = Math.round(deathBpmStepper.value);
				case 'iconFrameStepper':
					leHealthIcon.animation.curAnim.curFrame = Math.round(iconFrameStepper.value);
				case 'iconOffsetXStepper':
					leHealthIcon.x = char.iconProperties.offsets[0] = iconOffsets[0] = Math.round(iconOffsetXStepper.value);
				case 'iconOffsetYStepper':
					char.iconProperties.offsets[1] = iconOffsets[1] = Math.round(iconOffsetYStepper.value);
					leHealthIcon.y = (FlxG.height - 130) + char.iconProperties.offsets[1];
			}
		}
		else if(id == FlxUICheckBox.CLICK_EVENT) {
			var senderBox:FlxUICheckBox = cast (sender, FlxUICheckBox); //safe casts are better than unsafe casts //me when the casts become exposed (click here for explicit casts in your area!)
			var senderName = senderBox.getLabel().text;
			switch(senderName) {
				case 'Edit Icon Offsets' | 'Stop Editing':
					final lowerAlphaTxts:Array<FlxText> = [tipTexts[4], tipTexts[5], tipTexts[10]];
					final changeAnimTxts:Array<FlxText> = [tipTexts[3], tipTexts[6], tipTexts[9]];
					final alphaSet:Float = editOffsetsCheckbox.checked ? 0.5 : 1;
					final replaceBy:Array<String> = editOffsetsCheckbox.checked ? ["Animation", "Icon"] : ["Icon", "Animation"];
					editOffsetsCheckbox.getLabel().text = editOffsetsCheckbox.checked ? 'Stop Editing' : 'Edit Icon Offsets';
		
					for(tipText in tipTexts) {
						if(lowerAlphaTxts.contains(tipText) && !tipText.text.endsWith('[Disabled]')) tipText.alpha = alphaSet;
						if(changeAnimTxts.contains(tipText)) tipText.text = tipText.text.replace(replaceBy[0], replaceBy[1]);
					}

					genOffsetTexts();
				case 'Icon Antialiasing':
					char.iconProperties.antialiasing = iconAntialiasingCheckbox.checked;
					leHealthIcon.antialiasing = char.iconProperties.antialiasing;
			}
		}
	}

	function reloadCharacterImage() {
		Paths.setModsDirectoryFromType(CHARACTER, char.curCharacter, false);
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
				var loopPoint:Null<Int> = anim.loop_point;
				if (loopPoint == null) loopPoint = 0;
				if(animIndices != null && animIndices.length > 0) {
					char.animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, false, false, loopPoint);
				} else {
					char.animation.addByPrefix(animAnim, animName, animFps, animLoop, false, false, loopPoint);
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
		reloadXmlAnimDropDown();
		Paths.setModsDirectoryFromType(NONE, '', true);
	}

	// dear Psych dev who wrote "genBoyOffsets"...
	// please do not write code that is shit
	// sincerely, AT <3
	function genOffsetTexts():Void
	{
		final iconEdit:Bool = (editOffsetsCheckbox != null && editOffsetsCheckbox.checked);

		offsetText.text = iconEdit ? "Editing Icon Offsets!\n\n" : "";
		for (anim => offsets in char.animOffsets)
			offsetText.text += '$anim: $offsets\n';

		if (offsetText.text == "")
			offsetText.text = "ERROR! No animations found.";
	}

	function getCharJson(char:String) {
		var characterPath:String = 'data/characters/$char.json';
		Paths.setModsDirectoryFromType(CHARACTER, char, false);
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('data/characters/bf.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = sys.io.File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		var json:Character.CharacterFile = cast Json.parse(rawJson);
		Paths.setModsDirectoryFromType(NONE, '', true);
		return json;
	}

	function loadChar(character:String, isDad:Bool, regenTexts:Bool = true) {
		var i:Int = charLayer.members.length-1;
		while(i >= 0) {
			var memb:Character = charLayer.members[i];
			if(memb != null) {
				charLayer.remove(memb);
				memb.destroy();
			}
			--i;
		}
		charLayer.clear();
		Paths.clearUnusedCache();
		Paths.setModsDirectoryFromType(CHARACTER, character, false);
		ghostChar = new Character(0, 0, character, !isDad);
		ghostChar.debugMode = true;
		ghostChar.alpha = 0.6;

		char = new Character(0, 0, character, !isDad);
		if(char.animationsArray[0] != null) {
			char.playAnim(char.animationsArray[0].anim, true);
		}
		char.debugMode = true;

		charLayer.add(ghostChar);
		charLayer.add(char);

		char.setPosition(char.positionOffset.x + OFFSET_X + 100, char.positionOffset.y);

		Paths.setModsDirectoryFromType(NONE, '', true);
		if(regenTexts) {
			genOffsetTexts();
		}
		reloadCharacterOptions();
		reloadBGs();
		char.setPosition(char.positionOffset.x + OFFSET_X + 100 + xPositioningOffset, char.positionOffset.y + yPositioningOffset); //we do it again so that it gets properly set lmao
		snapCamFollowToPos(char.getMidpoint().x + (char.isPlayer ? -100 : 150) + cameraStageOffsets[0], char.getMidpoint().y - 100 + cameraStageOffsets[1]);
		updatePointerPos();
	}

	function resetHealthBarCount() {
		for (i=>bar in [healthBarBGT, healthBarBGM, healthBarBGB]) {
			bar.setGraphicSize(587, 6);
			bar.updateHitbox();
			switch (i) {
				case 0: bar.y = FlxG.height - 65;
				case 1: bar.y = FlxG.height - 59;
				case 2: bar.y = FlxG.height - 53;
			}
		}
		//do not change for 3 because it resets above
		switch (char.healthBarCount) {
			case 1:
				healthBarBGT.setGraphicSize(587, 18);
				healthBarBGT.updateHitbox();
			case 2:
				healthBarBGT.setGraphicSize(587, 9);
				healthBarBGT.updateHitbox();
				healthBarBGM.setGraphicSize(587, 9);
				healthBarBGM.updateHitbox();
				healthBarBGM.y += 3;
		}
	}

	function updatePointerPos(dragging:Bool = false) {
		var x:Float = char.getMidpoint().x;
		var y:Float = char.getMidpoint().y;
		x += (char.isPlayer ? -100 : 150);
		x += char.cameraPosition.x;
		y -= 100 - char.cameraPosition.y;
		x += cameraStageOffsets[0];
		y += cameraStageOffsets[1];

		x -= cameraFollowPointer.width / 2;
		y -= cameraFollowPointer.height / 2;
		cameraFollowPointer.setPosition(x, y);
		if (disableCamMovementCheckbox != null && disableCamMovementCheckbox.checked || dragging) return;
		tweenCameraToPlayStatePos();
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
			healthIconInputText.text = char.iconProperties.name;
			singDurationStepper.value = char.singDuration;
			scaleStepper.value = char.jsonScale;
			hpBarCountStepper.value = char.healthBarCount;
			floatMagnitudeStepper.value = char.floatMagnitude;
			floatSpeedStepper.value = char.floatSpeed;
			trailLengthStepper.value = char.trailData.length;
			trailDelayStepper.value = char.trailData.delay;
			trailAlphaStepper.value = char.trailData.alpha;
			trailDiffStepper.value = char.trailData.diff;
			drainFloorStepper.value = char.drainFloor;
			drainAmountStepper.value = char.drainAmount;
			flipXCheckBox.checked = char.originalFlipX;
			noAntialiasingCheckBox.checked = char.noAntialiasing;
			sarventeFloatingCheckBox.checked = char.sarventeFloating;
			orbitCheckBox.checked = char.orbit;
			flixelTrailCheckBox.checked = char.trailData.enabled;
			screenShakeCheckBox.checked = char.shakeScreen;
			scareBfCheckBox.checked = char.scareBf;
			scareGfCheckBox.checked = char.scareGf;
			healthDrainCheckBox.checked = char.healthDrain;
			resetHealthBarColor();
			resetHealthBarCount();
			Paths.setModsDirectoryFromType(ICON, healthIconInputText.text, false);
			leHealthIcon.changeIcon(healthIconInputText.text);
			Paths.setModsDirectoryFromType(NONE, '', true);
			positionXStepper.value = char.positionOffset.x;
			positionYStepper.value = char.positionOffset.y;
			positionCameraXStepper.value = char.cameraPosition.x;
			positionCameraYStepper.value = char.cameraPosition.y;
			if (char.deathProperties != null) {
				deathNameText.text = char.deathProperties.character;
				deathStartText.text = char.deathProperties.startSfx;
				deathEndText.text = char.deathProperties.endSfx;
				deathMusicText.text = char.deathProperties.loopSfx;
				deathBpmStepper.value = char.deathProperties.bpm;
			} else {
				char.deathProperties = {
					character: "bf-dead",
					startSfx: "fnf_loss_sfx",
					loopSfx: "gameOver",
					endSfx: "gameOverEnd",
					bpm: 100
				}
			}
			iconFrameStepper.value = leHealthIcon.animation.curAnim.curFrame;
			iconFrameStepper.max = leHealthIcon.type;
			iconAntialiasingCheckbox.checked = leHealthIcon.antialiasing;
			iconOffsetXStepper.value = char.iconProperties.offsets[0];
			iconOffsetYStepper.value = char.iconProperties.offsets[1];
			leHealthIcon.x = char.iconProperties.offsets[0];
			leHealthIcon.y = (FlxG.height - 130) + char.iconProperties.offsets[1];
			reloadAnimationDropDown();
			reloadXmlAnimDropDown();
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

	function reloadXmlAnimDropDown() {
		Paths.setModsDirectoryFromType(CHARACTER, char.curCharacter, false);
		xmlAnims = char.getAnimationsFromXml();
		if(xmlAnims.length < 1) xmlAnims.push('NONE / NOT SUPPORTED'); //Prevents crash
		xmlAnimDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(xmlAnims, true));
		Paths.setModsDirectoryFromType(NONE, '', true);
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
		for (key in Paths.characterMap.keys()) {
			characterList.push(key);
		}
		characterList = CoolUtil.removeDuplicates(characterList);
		characterList.remove('placeman');
		characterList.insert(0, 'placeman');
		#else
		characterList = CoolUtil.coolTextFile(Paths.txt('characters/characterList'));
		#end

		charDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(characterList, true));
		charDropDown.selectedLabel = daAnim;
	}

	//this is horrible, i'll rewrite it soon -yanni
	function resetHealthBarColor() {
		healthColorStepperR.value = char.healthColorArray[0].red;
		healthColorStepperG.value = char.healthColorArray[0].green;
		healthColorStepperB.value = char.healthColorArray[0].blue;
		healthColorStepperRM.value = char.healthColorArray[1].red;
		healthColorStepperGM.value = char.healthColorArray[1].green;
		healthColorStepperBM.value = char.healthColorArray[1].blue;
		healthColorStepperRB.value = char.healthColorArray[2].red;
		healthColorStepperGB.value = char.healthColorArray[2].green;
		healthColorStepperBB.value = char.healthColorArray[2].blue;
		healthBarBGT.color = FlxColor.fromRGB(char.healthColorArray[0].red, char.healthColorArray[0].green, char.healthColorArray[0].blue);
		healthBarBGM.color = FlxColor.fromRGB(char.healthColorArray[1].red, char.healthColorArray[1].green, char.healthColorArray[1].blue);
		healthBarBGB.color = FlxColor.fromRGB(char.healthColorArray[2].red, char.healthColorArray[2].green, char.healthColorArray[2].blue);
	}

	function updatePresence() {
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Character Editor", "Character: " + daAnim, leHealthIcon.char);
		#end
	}

	var leaving:Bool = false;
	var tweensMap:Map<String, FlxTween> = [];
	var updateFunctions:Map<String, Float -> Void> = []; //Put all the stuff you want to be updated into this and put it out once you dont want it to do that anymore
	function handleKeyInput(event:KeyboardEvent) { //Handles all the controls that were before handled in update
		final pressed:FlxKey = event.keyCode;
		inline function checkKey(key:FlxKey):Bool
			return (pressed == key);

		final cancelInput:Bool = blockInput();
		if(cancelInput) return;

		FlxG.sound.muteKeys = InitState.muteKeys;
		FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;

		switch(event.type) {
		case KeyboardEvent.KEY_DOWN:
			switch(pressed) 
			{
				case P:
					curAnim = 0;
					char.playAnim(char.animationsArray[curAnim].anim, true);
					genOffsetTexts();
					char.animation.finishCallback = function(name:String)
					{
						if (curAnim < char.animationsArray.length-1) {
							curAnim++;
							char.playAnim(char.animationsArray[curAnim].anim, true);
							genOffsetTexts();
						} else {
							char.animation.finishCallback = null;
						}
					};
				#if debug //just in case
				case N:
					if (cameraCanvas == null) {
						cameraCanvas = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
						cameraCanvas.cameras = [camMenu];
						cameraCanvas.screenCenter();
						add(cameraCanvas);
		
						cameraCanvas.pixels.draw(FlxG.camera.getCanvasBitmap(null), null, null, null, new Rectangle(2, 2, 16, 16)); //clipRect does nothing for some reason lol
						return;
					}
					cameraCanvas.visible = !cameraCanvas.visible;
				#end
				case ESCAPE:
					if(goToPlayState) {
						CustomFadeTransition.nextCamera = camOther;
						PlayState.customTransition = false;
						MusicBeatState.switchState(new PlayState());
					} else {
						Paths.setCurrentLevel('shared');
						CustomFadeTransition.nextCamera = camOther;
						MusicBeatState.switchState(new editors.MasterEditorMenu());
						FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
						Conductor.changeBPM(SoundTestState.playingTrackBPM);
					}
					updateFunctions = [];
					FlxG.mouse.visible = false;
					for(listener in mouse_listeners) FlxG.stage.removeEventListener(listener, handleMouseInput);
					for(listener in keyboard_listener) FlxG.stage.removeEventListener(listener, handleKeyInput);
					leaving = true;
				case R: 
					FlxG.camera.zoom = 1;
				case E | Q:
					final zoomControls:Array<FlxKey> = eyedropping ? [] : [E, Q]; //I love rewriting Psych code!!! -yanni
					for(keyPressed in 0...zoomControls.length) {
						if(checkKey(zoomControls[keyPressed])) {
							updateFunctions.set('zoomControls${zoomControls[keyPressed]}', function(elapsed:Float) {
								final negateNum:Int = (keyPressed == 1) ? -1 : 1;
								FlxG.camera.zoom = FlxMath.bound((FlxG.camera.zoom + (elapsed * FlxG.camera.zoom) * negateNum), 0.05, 3);
							});
						}
					}
				case I | J | K | L:
					final camHoldArray:Array<FlxKey> = [I, J, K, L];
					for(keyPressed in 0...4) {
						if(checkKey(camHoldArray[keyPressed])) {
							updateFunctions.set('camMovement${camHoldArray[keyPressed]}', function(elapsed:Float) {
								var addToCam:Float = FlxG.keys.pressed.SHIFT ? (500 * elapsed) * 4 : 500 * elapsed;
								if(keyPressed < 2) addToCam = -addToCam;
			
								if(keyPressed % 2 == 0) camFollow.y = camFollowPos.y += addToCam;
								else camFollow.x = camFollowPos.x += addToCam;
							});
						}
					}
				default:
					if(char.animationsArray.length < 1) return; //Anything beyond this point is only executed if any animations exist
	
					switch(pressed) {
						case W | S | SPACE:
							final animChangeKeys:Array<FlxKey> = [W, S];
							if (FlxG.keys.anyJustPressed(animChangeKeys) && !checkKey(SPACE)) 
							{ 	
								final pressedUp:Bool = checkKey(W); 
					
								switch(editOffsetsCheckbox.checked) {
									case true:
										final animBoundsMap:Map<Int, Int> = [ //make sure it doesnt play a not existing animation based on the healthIcon type (made it an abstract int)
											-1 => leHealthIcon.type,
											leHealthIcon.type + 1 => 0
										];
										final value_:Int = Std.int(FlxMath.bound(leHealthIcon.animation.curAnim.curFrame + (pressedUp ? -1 : 1), -1, leHealthIcon.type +1));
					
										leHealthIcon.animation.curAnim.curFrame = animBoundsMap.exists(value_) ? animBoundsMap[value_] : value_;
										iconFrameStepper.value = leHealthIcon.animation.curAnim.curFrame;
									case false:
										final animBoundsMap:Map<Int, Int> = [ //Might force these into ifs and whatnot later, will need to compare performance
											-1 => char.animationsArray.length - 1,
											char.animationsArray.length => 0
										];
										final value_:Int = Std.int(FlxMath.bound(curAnim + (pressedUp ? -1 : 1), -1, char.animationsArray.length));
					
										curAnim = animBoundsMap.exists(value_) ? animBoundsMap[value_] : value_;
								}
							}
							if (!editOffsetsCheckbox.checked)
							{
								char.animation.finishCallback = null;
								char.playAnim(char.animationsArray[curAnim].anim, true);
								
								//Had to go through the mess that is the DropDownMenu to make this function a thing gahh
								animationDropDown.changeSelection(char.animationsArray[curAnim].anim, !checkKey(SPACE));
								genOffsetTexts();
								return;
							}
						case T:
							switch(editOffsetsCheckbox.checked) {
								case true:
									iconOffsets = [0,0];
									char.iconProperties.offsets = [0, 0];
									leHealthIcon.x = char.iconProperties.offsets[0];
									leHealthIcon.y = (FlxG.height - 130) + char.iconProperties.offsets[1];
									iconOffsetXStepper.value = 0;
									iconOffsetYStepper.value = 0;
								case false:
									char.animationsArray[curAnim].offsets = [0, 0];
							
									char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
									ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
									char.playAnim(char.animationsArray[curAnim].anim);
									ghostChar.playAnim(char.animationsArray[curAnim].anim);
							}
							genOffsetTexts();
						case LEFT | RIGHT | UP | DOWN:
							var controlArray:Array<FlxKey> = [LEFT, RIGHT, UP, DOWN];
							for (i in 0...controlArray.length) {
								if(!checkKey(controlArray[i])) continue;

								var holdShift = FlxG.keys.pressed.SHIFT;
								var multiplier = holdShift ? 10 : 1;		
								var arrayVal = (i > 1) ? 1 : 0;				
								var negaMult:Int = (i % 2 == 1) ? -1 : 1;
								switch(editOffsetsCheckbox.checked) {
									case true:
										iconOffsets[arrayVal] += -negaMult * multiplier;
				
										char.iconProperties.offsets = iconOffsets;
										leHealthIcon.x = char.iconProperties.offsets[0];
										leHealthIcon.y = (FlxG.height - 130) + char.iconProperties.offsets[1];
										iconOffsetXStepper.value = char.iconProperties.offsets[0];
										iconOffsetYStepper.value = char.iconProperties.offsets[1];
									case false:
										char.animationsArray[curAnim].offsets[arrayVal] += negaMult * multiplier;
								
										char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
										ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
										
										char.playAnim(char.animationsArray[curAnim].anim, false);
										if(ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.animation.curAnim.name == ghostChar.animation.curAnim.name) {
											ghostChar.playAnim(char.animation.curAnim.name, false);
										}
								}
								genOffsetTexts();
							}
						default: //prevent unmatched patterns bs
					}
			}
		case KeyboardEvent.KEY_UP:
			switch(pressed) {
				case E | Q:
					final zoomControls:Array<FlxKey> = eyedropping ? [] : [E, Q];
					//We do this instead of having it all tied to one function so letting go of one key doesnt force you to repress
					//the other key if you were holding it!!
					for(keyReleased in 0...zoomControls.length) 
					{
						if(checkKey(zoomControls[keyReleased])) updateFunctions.remove('zoomControls${zoomControls[keyReleased]}');
					}
				case I | J | K | L:
					final camHoldArray:Array<FlxKey> = [I, J, K, L];
					for(keyReleased in 0...4) //Same deal here
					{
						if(checkKey(camHoldArray[keyReleased])) updateFunctions.remove('camMovement${camHoldArray[keyReleased]}');
					}
				default: //again prevent unmatched patterns bs!!
			}
		}
	}

	//drag start offsets
	var initialXY:Array<Int> = [];
	var camXY:Array<Float> = [];
    var mouseXY:Array<Int> = [];
	var dragging:Array<Bool> = [false, false];
	function handleMouseInput(event:MouseEvent) { //Increase Dragging Performance by not constantly updating all of this
		if(disableMouseDragCheckbox.checked) return;

		switch(event.type) {
			case MouseEvent.MOUSE_DOWN | MouseEvent.RIGHT_MOUSE_DOWN:
				if (char == null || char.iconProperties == null || char.animationsArray == null || editOffsetsCheckbox == null || char.animationsArray[curAnim] == null) return;
				initialXY = editOffsetsCheckbox.checked ? [Std.int(char.iconProperties.offsets[0]), Std.int(char.iconProperties.offsets[1])] : char.animationsArray[curAnim].offsets;
				camXY = [char.cameraPosition.x, char.cameraPosition.y];
				mouseXY = [FlxG.mouse.x, FlxG.mouse.y];

				dragging = [FlxG.mouse.pressed, FlxG.mouse.pressedRight];

				//copies eyedropper  color to steppers and turns off eyedropper!
				//the "status == 1" basically just checks if the button is highlighted.
				if(!eyedropping || eyedropperButton.status == 1) return;
				healthColorStepperR.value = char.healthColorArray[0].red = eyedropperPreview.color.red;
				healthColorStepperG.value = char.healthColorArray[0].green = eyedropperPreview.color.green;
				healthColorStepperB.value = char.healthColorArray[0].blue = eyedropperPreview.color.blue;
				healthColorStepperRM.value = char.healthColorArray[1].red = eyedropperPreview.color.red;
				healthColorStepperGM.value = char.healthColorArray[1].green = eyedropperPreview.color.green;
				healthColorStepperBM.value = char.healthColorArray[1].blue = eyedropperPreview.color.blue;
				healthColorStepperRB.value = char.healthColorArray[2].red = eyedropperPreview.color.red;
				healthColorStepperGB.value = char.healthColorArray[2].green = eyedropperPreview.color.green;
				healthColorStepperBB.value = char.healthColorArray[2].blue = eyedropperPreview.color.blue;
				healthBarBGT.color = FlxColor.fromRGB(char.healthColorArray[0].red, char.healthColorArray[0].green, char.healthColorArray[0].blue);
				healthBarBGM.color = FlxColor.fromRGB(char.healthColorArray[1].red, char.healthColorArray[1].green, char.healthColorArray[1].blue);
				healthBarBGB.color = FlxColor.fromRGB(char.healthColorArray[2].red, char.healthColorArray[2].green, char.healthColorArray[2].blue);
				toggleEyedropping();
			case MouseEvent.MOUSE_MOVE: //Event better, only updates when the mouse is moved at all!!
				if(dragging[0]) { //Left Drag, Character
					final iconXCalc = initialXY[0] - -(FlxG.mouse.x - mouseXY[0]);
					final iconYCalc = initialXY[1] - -(FlxG.mouse.y - mouseXY[1]);
					final xCalc = initialXY[0] - (FlxG.mouse.x - mouseXY[0]);
					final yCalc = initialXY[1] - (FlxG.mouse.y - mouseXY[1]);
			
					switch(editOffsetsCheckbox.checked) {
						case true:
							iconOffsets = [iconXCalc, iconYCalc]; //i see why you wanted to make this backwards. HOWEVER, you can just double negative that bitch -AT
			
							char.iconProperties.offsets = iconOffsets;
							leHealthIcon.x = char.iconProperties.offsets[0];
							leHealthIcon.y = (FlxG.height - 130) + char.iconProperties.offsets[1];
							iconOffsetXStepper.value = char.iconProperties.offsets[0];
							iconOffsetYStepper.value = char.iconProperties.offsets[1];
						case false:
							char.animationsArray[curAnim].offsets = [xCalc, yCalc];
			
							char.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
							ghostChar.addOffset(char.animationsArray[curAnim].anim, char.animationsArray[curAnim].offsets[0], char.animationsArray[curAnim].offsets[1]);
								
							char.playAnim(char.animationsArray[curAnim].anim, false);
							if(ghostChar.animation.curAnim != null && char.animation.curAnim != null && char.animation.curAnim.name == ghostChar.animation.curAnim.name) {
								ghostChar.playAnim(char.animation.curAnim.name, false);
							}
					}
					genOffsetTexts();
				}
				if(dragging[1]) { //Right Drag, Camera
					char.cameraPosition.x = (camXY[0] + (FlxG.mouse.x - mouseXY[0])); //no longer need to reverse it since i fixed the root cause!
					char.cameraPosition.y = camXY[1] + (FlxG.mouse.y - mouseXY[1]);

					positionCameraXStepper.value = char.cameraPosition.x;
					positionCameraYStepper.value = char.cameraPosition.y;
					updatePointerPos(true); //prevent tweening camera while updating pointer
				}

				if(!eyedropping || !FlxG.mouse.canEyedrop()) return;

				final time = FlxG.mouse.TIME_BUFFER;
				FlxTween.tween(eyedropperPreview, {x: FlxG.mouse.screenX, y: FlxG.mouse.screenY}, time, {ease: FlxEase.circOut});
				FlxTween.color(eyedropperPreview, time, eyedropperPreview.color, FlxG.mouse.eyedropper_Color);

			case MouseEvent.MOUSE_UP | MouseEvent.RIGHT_MOUSE_UP:
				dragging = [FlxG.mouse.pressed, FlxG.mouse.pressedRight];
				if(FlxG.mouse.justReleasedRight && (disableCamMovementCheckbox != null && !disableCamMovementCheckbox.checked)) tweenCameraToPlayStatePos();
		}
	}
	//shit for eyedropper
	var eyedropping:Bool = false;
	var initZoom:Float = 1;
	function blockInput():Bool {
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				if(FlxG.keys.justPressed.ENTER) {
					inputText.hasFocus = false;
				}
				FlxG.sound.muteKeys = FlxG.sound.volumeDownKeys = FlxG.sound.volumeUpKeys = [];
				return true;
			}
		}

		for (stepper in blockPressWhileTypingOnStepper) {
			@:privateAccess
			if(cast(stepper.text_field, FlxUIInputText).hasFocus) {
				FlxG.sound.muteKeys = FlxG.sound.volumeDownKeys = FlxG.sound.volumeUpKeys = [];
				return true;
			}
		}

		FlxG.sound.muteKeys = InitState.muteKeys;
		FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;
		for (dropDownMenu in blockPressWhileScrolling) { if(dropDownMenu.dropPanel.visible) return true; }

		return false;
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

		if (FlxG.sound.music.volume < 0.7) FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		if(stageDropDown.selectedLabel != currentStage) currentStage = stageDropDown.selectedLabel;

		for(function_ in updateFunctions) function_(elapsed);
		//camMenu.zoom = FlxG.camera.zoom;
		ghostChar.setPosition(char.x, char.y);
		super.update(elapsed);
	}

	var cameraTwn1:FlxTween = null;
	var cameraTwn2:FlxTween = null;
	//canIUseTheCutsceneMother got some competition now huh?
	function tweenCameraToPlayStatePos() {
		if (camFollow == null || camFollowPos == null) return;
		if (cameraTwn1 != null) {
			cameraTwn1.cancel();
			cameraTwn1 = null;
		}
		if (cameraTwn2 != null) {
			cameraTwn2.cancel();
			cameraTwn2 = null;
		}
		cameraTwn1 = FlxTween.tween(camFollow, {x: char.getMidpoint().x + (char.isPlayer ? -100 : 150) + char.cameraPosition.x + cameraStageOffsets[0], y: char.getMidpoint().y - 100 + char.cameraPosition.y + cameraStageOffsets[1]}, 0.45, {
			ease: FlxEase.cubeOut
		});
		cameraTwn2 = FlxTween.tween(camFollowPos, {x: char.getMidpoint().x + (char.isPlayer ? -100 : 150) + char.cameraPosition.x + cameraStageOffsets[0], y: char.getMidpoint().y - 100 + char.cameraPosition.y + cameraStageOffsets[1]}, 0.45, {
			ease: FlxEase.cubeOut
		});
	}

	var _file:FileReference;

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
			"image": char.imageFile,
			"icon_props": char.iconProperties,
			"flip_x": char.originalFlipX,
			"player": check_player.checked,
			"no_antialiasing": char.noAntialiasing,
			"scale": char.jsonScale,
			"position":	[char.positionOffset.x, char.positionOffset.y],
			"camera_position": [char.cameraPosition.x, char.cameraPosition.y],
			"sing_duration": char.singDuration,
			"healthbar_count": char.healthBarCount,
			"healthbar_colors": char.healthColorArray,
			"death_props": char.deathProperties,
			"sarvente_floating": char.sarventeFloating,
			"float_magnitude": char.floatMagnitude,
			"float_speed": char.floatSpeed,
			"trail_data": char.trailData,
			"health_drain": char.healthDrain,
			"drain_floor": char.drainFloor,
			"drain_amount": char.drainAmount,
			"shake_screen": char.shakeScreen,
			"scare_bf": char.scareBf,
			"scare_gf": char.scareGf,
			"orbit": char.orbit,
			"animations": char.animationsArray,
			"selector_offsets": [char.selectorOffsets.x, char.selectorOffsets.y]
		};

		var data:String = Json.stringify(json, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, convPathShit(getCurrentDataPath()));
		}
	}

	function getCurrentDataPath():String {
		var characterPath:String = 'data/characters/' + daAnim + '.json';

		var path:String;
		#if MODS_ALLOWED
		path = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
		#end
			path = Paths.getPreloadPath(characterPath);

		return path;
	}

	override function beatHit()
	{
		super.beatHit();
	}

	public function snapCamFollowToPos(x:Float, y:Float) {
		if (camFollow != null && camFollowPos != null) {
			camFollow.set(x, y);
			camFollowPos.setPosition(x, y);
		}
	}

	inline private function generateJSONSprites(stageData:StageFile) {
		var layerArray:Array<FlxBasic> = [];
		var middleLayerArray:Array<FlxBasic> = [];
		var topLayerArray:Array<FlxBasic> = [];
		for (spriteData in stageData.sprites) {
			if (spriteData.hide_lq && ClientPrefs.settings.get("lowQuality")) continue;
			var leSprite:FlxSprite = new FlxSprite(spriteData.position[0],spriteData.position[1]);
				if (!spriteData.animated) {
					try {
						leSprite.loadGraphic(Paths.image(spriteData.image));
					} catch (e) {
						leSprite.makeGraphic(12,12,FlxColor.WHITE);
						trace('exception: ' + e);
					}
				} else {
					try {
						leSprite.frames = Paths.getSparrowAtlas(spriteData.image);
						for (animationData in stageData.animations[spriteData.animation_index]) {
							leSprite.animation.addByPrefix(animationData.name, animationData.xml_prefix, animationData.framerate, animationData.looped, animationData.flip_x, animationData.flip_y);
						}
						var animation:String = stageData.animations[spriteData.animation_index][0].name;
						leSprite.animation.play(animation, true);
					} catch (e) {
						leSprite.makeGraphic(12,12,FlxColor.WHITE);
						trace('exception: ' + e);
					}
				}
			leSprite.scrollFactor.set(spriteData.scroll[0],spriteData.scroll[1]);
			if (spriteData.size != null) {
				leSprite.scale.set(spriteData.size[0],spriteData.size[1]);
				if (spriteData.size[2] == null) {
					leSprite.updateHitbox();
				}
			}
			if(spriteData.alpha != null && spriteData.alpha != 1)
				leSprite.alpha = spriteData.alpha;
			if(spriteData.angle != null && spriteData.angle != 0)
				leSprite.angle = spriteData.angle;
			if(spriteData.flip_x != null && spriteData.flip_x != false)
				leSprite.flipX = spriteData.flip_x;
			if(spriteData.flip_y != null && spriteData.flip_y != false)
				leSprite.flipY = spriteData.flip_y;
			leSprite.antialiasing = spriteData.antialiasing ? ClientPrefs.settings.get("globalAntialiasing") : false;
			if (!spriteData.front && !spriteData.gf_front) {
				layerArray.insert(spriteData.layer_pos, leSprite);
			}
			if (spriteData.gf_front) {
				middleLayerArray.insert(spriteData.layer_pos, leSprite);
			}
			if (spriteData.front && !spriteData.gf_front) {
				topLayerArray.insert(spriteData.layer_pos, leSprite);
			}
			if (spriteData.origin != null) leSprite.origin.set(spriteData.origin[0], spriteData.origin[1]);
		}
		autoLayer(layerArray, bgLayer);
		autoLayer(middleLayerArray, fuckLayer);
		autoLayer(topLayerArray, frontLayer);
	}

	/**
	* Function to automatically `add()` `FlxBasic` objects, either to a group or without.
	* 
	* @param array They `Array` of `FlxBasic`s to be used.
	* @param group The `FlxBasic` group for the `FlxBasic`s to be added into.
	*/
	public function autoLayer(array:Array<FlxBasic>, ?group:FlxTypedGroup<FlxBasic>):Void {
		try {
			if (group != null) {
				for (object in array) {
					group.add(object);
				}
			} else {
				for (object in array) {
					add(object);
				}
			}
		} catch (e) {
			trace('exception: ' + e);
			return;
		}
	}

	override function destroy() {
		camFollow = FlxDestroyUtil.put(camFollow);
		music.reset();
		super.destroy();
	}
}
