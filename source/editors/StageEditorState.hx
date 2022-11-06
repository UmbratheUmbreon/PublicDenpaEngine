package editors;

#if desktop
import Discord.DiscordClient;
#end
import flixel.text.FlxText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;
import haxe.Json;
import StageData;
import haxe.io.Path;

using StringTools;

/**
* State used to create and edit `Stage` jsons.
*/
class StageEditorState extends MusicBeatState
{
	var stageFile:StageFile = null;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		var musicID:Int = FlxG.random.int(0, 2);
		switch (musicID)
		{
			case 0:
				FlxG.sound.playMusic(Paths.music('shop'), 0.5);
			case 1:
				FlxG.sound.playMusic(Paths.music('sneaky'), 0.5);
			case 2:
				FlxG.sound.playMusic(Paths.music('mii'), 0.5);
			case 3:
				FlxG.sound.playMusic(Paths.music('dsi'), 0.5);
		}
		stageFile = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				p4: [0, 0],
				hide_girlfriend: false,
			
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_p4: [0,0],
				camera_speed: 1,

				sprites: [
					{
						animated: false,
						front: false,
						glitch_shader: null,
					
						position: [-600,-200],
						scroll: [0.9,0.9],
						size: [1,1],
					
						alpha: null,
					
						angle: null,
						layer_pos: 0,
					
						glitch_speed: null,
						glitch_amplitude: null,
						glitch_frequency: null,
					
						animation_index: 0,
					
						antialiasing: true,
					
						tag: "bg",
						image: "stageback",

						flip_x: null,
						flip_y: null,

						gf_front: false,
						origin: null
					},
					{
						animated: false,
						front: false,
						glitch_shader: null,
					
						position: [-650,-600],
						scroll: [0.9,0.9],
						size: [1.1,1.1],
					
						alpha: null,
					
						angle: null,
						layer_pos: 1,
					
						glitch_speed: null,
						glitch_amplitude: null,
						glitch_frequency: null,
					
						animation_index: 0,
					
						antialiasing: true,
					
						tag: "stageFront",
						image: "stagefront",

						flip_x: null,
						flip_y: null,

						gf_front: false,
						origin: null
					}
				],
				animations: [[]]
		};
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Stage Editor", null);
		#end

		addEditorBox();
		FlxG.mouse.visible = true;

		super.create();
	}

	var UI_mainbox:FlxUITabMenu;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];
	function addEditorBox() {
		var tabs = [
			{name: 'Stage', label: 'Stage'},
			{name: 'Sprites', label: 'Sprites'}
		];
		UI_mainbox = new FlxUITabMenu(null, tabs, true);
		UI_mainbox.resize(300, 650);
		UI_mainbox.x = FlxG.width - UI_mainbox.width - 50;
		UI_mainbox.y = FlxG.height - UI_mainbox.height - 50;
		UI_mainbox.scrollFactor.set();
		addStageUI();
		addSpritesUI();
		add(UI_mainbox);

		var loadButton:FlxButton = new FlxButton(FlxG.width - 260, FlxG.height - 50, "Load Stage", function() {
			loadStage();
		});
		loadButton.x -= 60;
		add(loadButton);
	
		var saveButton:FlxButton = new FlxButton(loadButton.x + 100, loadButton.y, "Save Stage", function() {
			saveStage();
		});
		saveButton.x += 60;
		add(saveButton);
	}

	var stageInputText:FlxUIInputText;
	var directoryInputText:FlxUIInputText;
	var zoomStepper:FlxUINumericStepper;
	var pixelStageCheckbox:FlxUICheckBox;
	var hideGfCheckbox:FlxUICheckBox;
	var bfXStepper:FlxUINumericStepper;
	var bfYStepper:FlxUINumericStepper;
	var gfXStepper:FlxUINumericStepper;
	var gfYStepper:FlxUINumericStepper;
	var dadXStepper:FlxUINumericStepper;
	var dadYStepper:FlxUINumericStepper;
	var p4XStepper:FlxUINumericStepper;
	var p4YStepper:FlxUINumericStepper;
	var bfCamXStepper:FlxUINumericStepper;
	var bfCamYStepper:FlxUINumericStepper;
	var gfCamXStepper:FlxUINumericStepper;
	var gfCamYStepper:FlxUINumericStepper;
	var dadCamXStepper:FlxUINumericStepper;
	var dadCamYStepper:FlxUINumericStepper;
	var camSpeedStepper:FlxUINumericStepper;
	function addStageUI() {
		var tab_group = new FlxUI(null, UI_mainbox);
		tab_group.name = "Stage";
		
		stageInputText = new FlxUIInputText(10, 20, 80, '', 8);
		blockPressWhileTypingOn.push(stageInputText);
		directoryInputText = new FlxUIInputText(10, stageInputText.y + 60, 80, stageFile.directory, 8);
		blockPressWhileTypingOn.push(directoryInputText);

		zoomStepper = new FlxUINumericStepper(10, directoryInputText.y + 60, 0.05, 0.9, 0.05, 10, 2);
		blockPressWhileTypingOnStepper.push(zoomStepper);

		bfXStepper = new FlxUINumericStepper(110, stageInputText.y, 10, 770, -90000, 90000, 1);
		bfYStepper = new FlxUINumericStepper(110, bfXStepper.y + 50, 10, 110, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(bfXStepper);
		blockPressWhileTypingOnStepper.push(bfYStepper);

		gfXStepper = new FlxUINumericStepper(110, bfYStepper.y + 50, 10, 400, -90000, 90000, 1);
		gfYStepper = new FlxUINumericStepper(110, gfXStepper.y + 50, 10, 130, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(gfXStepper);
		blockPressWhileTypingOnStepper.push(gfYStepper);

		dadXStepper = new FlxUINumericStepper(110, gfYStepper.y + 50, 10, 100, -90000, 90000, 1);
		dadYStepper = new FlxUINumericStepper(110, dadXStepper.y + 50, 10, 100, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(dadXStepper);
		blockPressWhileTypingOnStepper.push(dadYStepper);

		p4XStepper = new FlxUINumericStepper(110, dadYStepper.y + 50, 10, 0, -90000, 90000, 1);
		p4YStepper = new FlxUINumericStepper(110, p4XStepper.y + 50, 10, 0, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(p4XStepper);
		blockPressWhileTypingOnStepper.push(p4YStepper);

		bfCamXStepper = new FlxUINumericStepper(210, stageInputText.y, 10, 0, -90000, 90000, 1);
		bfCamYStepper = new FlxUINumericStepper(210, bfCamXStepper.y + 50, 10, 0, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(bfCamXStepper);
		blockPressWhileTypingOnStepper.push(bfCamYStepper);

		gfCamXStepper = new FlxUINumericStepper(210, bfCamYStepper.y + 50, 10, 0, -90000, 90000, 1);
		gfCamYStepper = new FlxUINumericStepper(210, gfCamXStepper.y + 50, 10, 0, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(gfCamXStepper);
		blockPressWhileTypingOnStepper.push(gfCamYStepper);

		dadCamXStepper = new FlxUINumericStepper(210, gfCamYStepper.y + 50, 10, 0, -90000, 90000, 1);
		dadCamYStepper = new FlxUINumericStepper(210, dadCamXStepper.y + 50, 10, 0, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(dadCamXStepper);
		blockPressWhileTypingOnStepper.push(dadCamYStepper);

		camSpeedStepper = new FlxUINumericStepper(210, dadCamYStepper.y + 50, 0.05, 1, 0.05, 10, 2);
		blockPressWhileTypingOnStepper.push(camSpeedStepper);

		pixelStageCheckbox = new FlxUICheckBox(10, zoomStepper.y + 60, null, null, "Pixel Stage", 100);
		pixelStageCheckbox.checked = stageFile.isPixelStage;
		pixelStageCheckbox.callback = function()
		{
			stageFile.isPixelStage = pixelStageCheckbox.checked;
		};

		hideGfCheckbox = new FlxUICheckBox(10, pixelStageCheckbox.y + 60, null, null, "Hide Girlfriend", 100);
		hideGfCheckbox.checked = stageFile.hide_girlfriend;
		hideGfCheckbox.callback = function()
		{
			stageFile.hide_girlfriend = hideGfCheckbox.checked;
		};

		tab_group.add(new FlxText(10, stageInputText.y - 18, 0, 'Stage file name:'));
		tab_group.add(new FlxText(10, directoryInputText.y - 18, 0, 'Directory:'));
		tab_group.add(new FlxText(zoomStepper.x, zoomStepper.y - 18, 0, 'Zoom:'));
		tab_group.add(new FlxText(bfXStepper.x, bfXStepper.y - 18, 0, 'Boyfriend X:'));
		tab_group.add(new FlxText(bfYStepper.x, bfYStepper.y - 18, 0, 'Boyfriend Y:'));
		tab_group.add(new FlxText(gfXStepper.x, gfXStepper.y - 18, 0, 'Girlfriend X:'));
		tab_group.add(new FlxText(gfYStepper.x, gfYStepper.y - 18, 0, 'Girlfriend Y:'));
		tab_group.add(new FlxText(dadXStepper.x, dadXStepper.y - 18, 0, 'Dad X:'));
		tab_group.add(new FlxText(dadYStepper.x, dadYStepper.y - 18, 0, 'Dad Y:'));
		tab_group.add(new FlxText(p4XStepper.x, p4XStepper.y - 18, 0, 'Player 4 X:'));
		tab_group.add(new FlxText(p4YStepper.x, p4YStepper.y - 18, 0, 'Player 4 Y:'));
		tab_group.add(new FlxText(bfCamXStepper.x, bfCamXStepper.y - 18, 0, 'Bf Cam X:'));
		tab_group.add(new FlxText(bfCamYStepper.x, bfCamYStepper.y - 18, 0, 'Bf Cam Y:'));
		tab_group.add(new FlxText(gfCamXStepper.x, gfCamXStepper.y - 18, 0, 'Gf Cam X:'));
		tab_group.add(new FlxText(gfCamYStepper.x, gfCamYStepper.y - 18, 0, 'Gf Cam Y:'));
		tab_group.add(new FlxText(dadCamXStepper.x, dadCamXStepper.y - 18, 0, 'Dad Cam X:'));
		tab_group.add(new FlxText(dadCamYStepper.x, dadCamYStepper.y - 18, 0, 'Dad Cam Y:'));
		tab_group.add(new FlxText(camSpeedStepper.x, camSpeedStepper.y - 18, 0, 'Camera Speed:'));

		tab_group.add(pixelStageCheckbox);
		tab_group.add(hideGfCheckbox);
		tab_group.add(stageInputText);
		tab_group.add(directoryInputText);
		tab_group.add(zoomStepper);
		tab_group.add(bfXStepper);
		tab_group.add(bfYStepper);
		tab_group.add(gfXStepper);
		tab_group.add(gfYStepper);
		tab_group.add(dadXStepper);
		tab_group.add(dadYStepper);
		tab_group.add(p4XStepper);
		tab_group.add(p4YStepper);
		tab_group.add(bfCamXStepper);
		tab_group.add(bfCamYStepper);
		tab_group.add(gfCamXStepper);
		tab_group.add(gfCamYStepper);
		tab_group.add(dadCamXStepper);
		tab_group.add(dadCamYStepper);
		tab_group.add(camSpeedStepper);

		UI_mainbox.addGroup(tab_group);
	}

	var tagInputText:FlxUIInputText;
	var imageInputText:FlxUIInputText;
	var animatedCheckbox:FlxUICheckBox;
	var frontCheckbox:FlxUICheckBox;
	var glitchCheckbox:FlxUICheckBox;
	var xStepper:FlxUINumericStepper;
	var yStepper:FlxUINumericStepper;
	var scrollXStepper:FlxUINumericStepper;
	var scrollYStepper:FlxUINumericStepper;
	var sizeXStepper:FlxUINumericStepper;
	var sizeYStepper:FlxUINumericStepper;
	var alphaStepper:FlxUINumericStepper;
	var angleStepper:FlxUINumericStepper;
	var positionStepper:FlxUINumericStepper;
	var glitchSpeedStepper:FlxUINumericStepper;
	var glitchAmplitudeStepper:FlxUINumericStepper;
	var glitchFrequencyStepper:FlxUINumericStepper;
	var animIndexStepper:FlxUINumericStepper;
	var indexStepper:FlxUINumericStepper;
	var loadedIndex:Int = 0;
	var maxIndex:Int = 0;
	function addSpritesUI() {
		var tab_group = new FlxUI(null, UI_mainbox);
		tab_group.name = "Sprites";
		
		tagInputText = new FlxUIInputText(10, 20, 80, '', 8);
		blockPressWhileTypingOn.push(tagInputText);
		imageInputText = new FlxUIInputText(10, tagInputText.y + 60, 80, '', 8);
		blockPressWhileTypingOn.push(imageInputText);

		animatedCheckbox = new FlxUICheckBox(10, imageInputText.y + 60, null, null, "Animated", 100);
		animatedCheckbox.checked = stageFile.sprites[loadedIndex].animated;
		animatedCheckbox.callback = function()
		{
			stageFile.sprites[loadedIndex].animated = animatedCheckbox.checked;
		};

		frontCheckbox = new FlxUICheckBox(10, animatedCheckbox.y + 60, null, null, "Front", 100);
		frontCheckbox.checked = stageFile.sprites[loadedIndex].front;
		frontCheckbox.callback = function()
		{
			stageFile.sprites[loadedIndex].front = frontCheckbox.checked;
		};

		glitchCheckbox = new FlxUICheckBox(10, frontCheckbox.y + 60, null, null, "Glitch Shader", 100);
		glitchCheckbox.checked = stageFile.sprites[loadedIndex].glitch_shader;
		glitchCheckbox.callback = function()
		{
			stageFile.sprites[loadedIndex].glitch_shader = glitchCheckbox.checked;
		};

		xStepper = new FlxUINumericStepper(110, tagInputText.y, 10, 0, -90000, 90000, 1);
		yStepper = new FlxUINumericStepper(110, xStepper.y + 60, 10, 0, -90000, 90000, 1);
		blockPressWhileTypingOnStepper.push(xStepper);
		blockPressWhileTypingOnStepper.push(yStepper);

		scrollXStepper = new FlxUINumericStepper(110, yStepper.y + 60, 0.1, 1, 0, 10, 1);
		scrollYStepper = new FlxUINumericStepper(110, scrollXStepper.y + 60, 0.1, 1, 0, 10, 1);
		blockPressWhileTypingOnStepper.push(scrollXStepper);
		blockPressWhileTypingOnStepper.push(scrollYStepper);

		sizeXStepper = new FlxUINumericStepper(110, scrollYStepper.y + 60, 0.1, 1, 0.1, 10, 1);
		sizeYStepper = new FlxUINumericStepper(110, sizeXStepper.y + 60, 0.1, 1, 0.1, 10, 1);
		blockPressWhileTypingOnStepper.push(sizeXStepper);
		blockPressWhileTypingOnStepper.push(sizeYStepper);

		alphaStepper = new FlxUINumericStepper(110, sizeYStepper.y + 60, 0.05, 1, 0, 1, 2);
		angleStepper = new FlxUINumericStepper(110, alphaStepper.y + 60, 1, 0, 0, 359, 1);
		blockPressWhileTypingOnStepper.push(alphaStepper);
		blockPressWhileTypingOnStepper.push(angleStepper);

		positionStepper = new FlxUINumericStepper(110, angleStepper.y + 60, 1, 0, 0, 9999, 1);
		blockPressWhileTypingOnStepper.push(positionStepper);

		glitchSpeedStepper = new FlxUINumericStepper(210, tagInputText.y, 0.1, 1, 0, 10, 1);
		glitchAmplitudeStepper = new FlxUINumericStepper(210, glitchSpeedStepper.y + 60, 0.1, 1, 0, 10, 1);
		glitchFrequencyStepper = new FlxUINumericStepper(210, glitchAmplitudeStepper.y + 60, 0.1, 1, 0, 10, 1);
		blockPressWhileTypingOnStepper.push(glitchSpeedStepper);
		blockPressWhileTypingOnStepper.push(glitchAmplitudeStepper);
		blockPressWhileTypingOnStepper.push(glitchFrequencyStepper);

		animIndexStepper = new FlxUINumericStepper(210, glitchFrequencyStepper.y + 60, 1, 0, 0, 9999, 1);
		blockPressWhileTypingOnStepper.push(animIndexStepper);

		indexStepper = new FlxUINumericStepper(210, animIndexStepper.y + 60, 1, 0, 0, maxIndex-1, 1);
		blockPressWhileTypingOnStepper.push(indexStepper);

		tab_group.add(new FlxText(tagInputText.x, tagInputText.y - 18, 0, 'Tag:'));
		tab_group.add(new FlxText(imageInputText.x, imageInputText.y - 18, 0, 'Image:'));
		tab_group.add(new FlxText(xStepper.x, xStepper.y - 18, 0, 'X:'));
		tab_group.add(new FlxText(yStepper.x, yStepper.y - 18, 0, 'Y:'));
		tab_group.add(new FlxText(scrollXStepper.x, scrollXStepper.y - 18, 0, 'Scroll X:'));
		tab_group.add(new FlxText(scrollYStepper.x, scrollYStepper.y - 18, 0, 'Scroll Y:'));
		tab_group.add(new FlxText(sizeXStepper.x, sizeXStepper.y - 18, 0, 'Scale X:'));
		tab_group.add(new FlxText(sizeYStepper.x, sizeYStepper.y - 18, 0, 'Scale Y:'));
		tab_group.add(new FlxText(alphaStepper.x, alphaStepper.y - 18, 0, 'Alpha:'));
		tab_group.add(new FlxText(angleStepper.x, angleStepper.y - 18, 0, 'Angle:'));
		tab_group.add(new FlxText(positionStepper.x, positionStepper.y - 18, 0, 'Layer Position:'));
		tab_group.add(new FlxText(glitchSpeedStepper.x, glitchSpeedStepper.y - 18, 0, 'Glitch Speed:'));
		tab_group.add(new FlxText(glitchAmplitudeStepper.x, glitchAmplitudeStepper.y - 18, 0, 'Glitch Amplitude:'));
		tab_group.add(new FlxText(glitchFrequencyStepper.x, glitchFrequencyStepper.y - 18, 0, 'Glitch Frequency:'));
		tab_group.add(new FlxText(animIndexStepper.x, animIndexStepper.y - 18, 0, 'Animations Index:'));
		tab_group.add(new FlxText(indexStepper.x, indexStepper.y - 18, 0, 'Current Sprite:'));

		tab_group.add(tagInputText);
		tab_group.add(imageInputText);
		tab_group.add(animatedCheckbox);
		tab_group.add(frontCheckbox);
		tab_group.add(glitchCheckbox);
		tab_group.add(xStepper);
		tab_group.add(yStepper);
		tab_group.add(scrollXStepper);
		tab_group.add(scrollYStepper);
		tab_group.add(sizeXStepper);
		tab_group.add(sizeYStepper);
		tab_group.add(alphaStepper);
		tab_group.add(angleStepper);
		tab_group.add(positionStepper);
		tab_group.add(glitchSpeedStepper);
		tab_group.add(glitchAmplitudeStepper);
		tab_group.add(glitchFrequencyStepper);
		tab_group.add(animIndexStepper);
		tab_group.add(indexStepper);

		UI_mainbox.addGroup(tab_group);
	}


	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == stageInputText) {

			} else if(sender == directoryInputText) {
				stageFile.directory = sender.text;
			} else if(sender == tagInputText) {
				stageFile.sprites[loadedIndex].tag = sender.text;
			} else if(sender == imageInputText) {
				stageFile.sprites[loadedIndex].image = sender.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
			if (sender == zoomStepper) {
				stageFile.defaultZoom = sender.value;
			} else if (sender == bfXStepper) {
				stageFile.boyfriend[0] = sender.value;
			} else if (sender == bfYStepper) {
				stageFile.boyfriend[1] = sender.value;
			} else if (sender == gfXStepper) {
				stageFile.girlfriend[0] = sender.value;
			} else if (sender == gfYStepper) {
				stageFile.girlfriend[1] = sender.value;
			} else if (sender == dadXStepper) {
				stageFile.opponent[0] = sender.value;
			} else if (sender == dadYStepper) {
				stageFile.opponent[1] = sender.value;
			} else if (sender == p4XStepper) {
				stageFile.p4[0] = sender.value;
			} else if (sender == p4YStepper) {
				stageFile.p4[1] = sender.value;
			} else if (sender == bfCamXStepper) {
				stageFile.camera_boyfriend[0] = sender.value;
			} else if (sender == bfCamYStepper) {
				stageFile.camera_boyfriend[1] = sender.value;
			} else if (sender == gfCamXStepper) {
				stageFile.camera_girlfriend[0] = sender.value;
			} else if (sender == gfCamYStepper) {
				stageFile.camera_girlfriend[1] = sender.value;
			} else if (sender == dadCamXStepper) {
				stageFile.camera_opponent[0] = sender.value;
			} else if (sender == dadCamYStepper) {
				stageFile.camera_opponent[1] = sender.value;
			} else if (sender == camSpeedStepper) {
				stageFile.camera_speed = sender.value;
			} else if (sender == xStepper) {
				stageFile.sprites[loadedIndex].position[0] = sender.value;
			} else if (sender == yStepper) {
				stageFile.sprites[loadedIndex].position[1] = sender.value;
			} else if (sender == scrollXStepper) {
				stageFile.sprites[loadedIndex].scroll[0] = sender.value;
			} else if (sender == scrollYStepper) {
				stageFile.sprites[loadedIndex].scroll[1] = sender.value;
			} else if (sender == sizeXStepper) {
				stageFile.sprites[loadedIndex].size[0] = sender.value;
			} else if (sender == sizeYStepper) {
				stageFile.sprites[loadedIndex].size[1] = sender.value;
			} else if (sender == alphaStepper) {
				stageFile.sprites[loadedIndex].alpha = sender.value;
			} else if (sender == angleStepper) {
				stageFile.sprites[loadedIndex].angle = sender.value;
			} else if (sender == positionStepper) {
				stageFile.sprites[loadedIndex].layer_pos = sender.value;
			} else if (sender == glitchAmplitudeStepper) {
				stageFile.sprites[loadedIndex].glitch_amplitude = sender.value;
			} else if (sender == glitchFrequencyStepper) {
				stageFile.sprites[loadedIndex].glitch_frequency = sender.value;
			} else if (sender == glitchSpeedStepper) {
				stageFile.sprites[loadedIndex].glitch_speed = sender.value;
			} else if (sender == animIndexStepper) {
				stageFile.sprites[loadedIndex].animation_index = sender.value;
			} else if (sender == indexStepper) {
				loadedIndex = sender.value;
				trace (loadedIndex);
				updateSpritesUI();
			}
		}
	}

	override function update(elapsed:Float) {
		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;

				if(FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;
				break;
			}
		}

		if(!blockInput) {
			for (stepper in blockPressWhileTypingOnStepper) {
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;
				if(leText.hasFocus) {
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = InitState.muteKeys;
			FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;
			for (dropDownMenu in blockPressWhileScrolling) {
				if(dropDownMenu.dropPanel.visible) {
					blockInput = true;
					break;
				}
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = InitState.muteKeys;
			FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;
			if(FlxG.keys.justPressed.ESCAPE) {
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		}

		super.update(elapsed);
	}

	function updateSpritesUI() {
		if (stageFile.sprites != null) {
			maxIndex = stageFile.sprites.length;
			if (loadedIndex < 0) {
				loadedIndex = 0;
			}
			if (maxIndex > 0) {
				indexStepper.max = maxIndex-1;
			} else {
				indexStepper.max = 0;
			}
			indexStepper.value = loadedIndex;
			tagInputText.text = stageFile.sprites[loadedIndex].tag;
			imageInputText.text = stageFile.sprites[loadedIndex].image;
			animatedCheckbox.checked = stageFile.sprites[loadedIndex].animated;
			frontCheckbox.checked = stageFile.sprites[loadedIndex].front;
			glitchCheckbox.checked = stageFile.sprites[loadedIndex].glitch_shader;
			xStepper.value = stageFile.sprites[loadedIndex].position[0];
			yStepper.value = stageFile.sprites[loadedIndex].position[1];
			scrollXStepper.value = stageFile.sprites[loadedIndex].scroll[0];
			scrollYStepper.value = stageFile.sprites[loadedIndex].scroll[1];
			sizeXStepper.value = stageFile.sprites[loadedIndex].size[0];
			sizeYStepper.value = stageFile.sprites[loadedIndex].size[1];
			alphaStepper.value = stageFile.sprites[loadedIndex].alpha;
			angleStepper.value = stageFile.sprites[loadedIndex].angle;
			positionStepper.value = stageFile.sprites[loadedIndex].layer_pos;
			glitchSpeedStepper.value = stageFile.sprites[loadedIndex].glitch_speed;
			glitchAmplitudeStepper.value = stageFile.sprites[loadedIndex].glitch_amplitude;
			glitchFrequencyStepper.value = stageFile.sprites[loadedIndex].glitch_frequency;
			animIndexStepper.value = stageFile.sprites[loadedIndex].animation_index;
		} else {
			tagInputText.text = 'tag';
			imageInputText.text = 'image';
			animatedCheckbox.checked = false;
			frontCheckbox.checked = false;
			glitchCheckbox.checked = false;
			xStepper.value = 0;
			yStepper.value = 0;
			scrollXStepper.value = 0.9;
			scrollYStepper.value = 0.9;
			sizeXStepper.value = 1;
			sizeYStepper.value = 1;
			alphaStepper.value = 1;
			angleStepper.value = 0;
			positionStepper.value = 0;
			glitchSpeedStepper.value = 0;
			glitchAmplitudeStepper.value = 0;
			glitchFrequencyStepper.value = 0;
			animIndexStepper.value = 0;
			maxIndex = 0;
			loadedIndex = 0;
			return;
		}
	}

	function loadTheFuckingShit() {
		if (stageFile.boyfriend != null) {
			bfXStepper.value = stageFile.boyfriend[0];
			bfYStepper.value = stageFile.boyfriend[1];
		} else {
			bfXStepper.value = 0;
			bfYStepper.value = 0;
		}
		if (stageFile.girlfriend != null) {
			gfXStepper.value = stageFile.girlfriend[0];
			gfYStepper.value = stageFile.girlfriend[1];
		} else {
			gfXStepper.value = 0;
			gfYStepper.value = 0;
		}
		if (stageFile.opponent != null) {
			dadXStepper.value = stageFile.opponent[0];
			dadYStepper.value = stageFile.opponent[1];
		} else {
			dadXStepper.value = 0;
			dadYStepper.value = 0;
		}
		if (stageFile.p4 != null) {
			p4XStepper.value = stageFile.p4[0];
			p4YStepper.value = stageFile.p4[1];
		} else {
			p4XStepper.value = 0;
			p4YStepper.value = 0;
		}
		if (stageFile.camera_boyfriend != null) {
			bfCamXStepper.value = stageFile.camera_boyfriend[0];
			bfCamYStepper.value = stageFile.camera_boyfriend[1];
		} else {
			bfCamXStepper.value = 0;
			bfCamYStepper.value = 0;
		}
		if (stageFile.camera_girlfriend != null) {
			gfCamXStepper.value = stageFile.camera_girlfriend[0];
			gfCamYStepper.value = stageFile.camera_girlfriend[1];
		} else {
			gfCamXStepper.value = 0;
			gfCamYStepper.value = 0;
		}
		if (stageFile.camera_opponent != null) {
			dadCamXStepper.value = stageFile.camera_opponent[0];
			dadCamYStepper.value = stageFile.camera_opponent[1];
		} else {
			dadCamXStepper.value = 0;
			dadCamYStepper.value = 0;
		}
		if (stageFile.camera_speed != null) {
			camSpeedStepper.value = stageFile.camera_speed;
		} else {
			camSpeedStepper.value = 1;
		}
	}

	var _file:FileReference = null;
	function loadStage() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				var loadedStage:StageFile = cast Json.parse(rawJson);
				var cutName:String = _file.name.substr(0, _file.name.length - 5);
				trace("Successfully loaded file: " + cutName);
				stageFile = null;
				stageFile = loadedStage;
				stageInputText.text = cutName;
				loadTheFuckingShit();
				loadedIndex = 0;
				updateSpritesUI();
				_file = null;
				return;
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveStage() {
		var data:String = Json.stringify(stageFile, "\t");
		if (data.length > 0)
		{
			var splittedStage:Array<String> = stageInputText.text.trim().split('_');
			var stageName:String = splittedStage[splittedStage.length-1].toLowerCase().replace(' ', '');

			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, convPathShit(getCurrentDataPath(stageName)));
		}
	}

	function getCurrentDataPath(stageName:String = 'stage'):String {
		var stagePath:String = 'stages/' + stageName + '.json';

		var path:String;
		#if MODS_ALLOWED
		path = Paths.modFolders(stagePath);
		if (!FileSystem.exists(path))
		#end
			path = Paths.getPreloadPath(stagePath);

		return path;
	}

	function convPathShit(path:String):String {
		path = Path.normalize(Sys.getCwd() + path);
		#if windows
		path = path.replace("/", "\\");
		#end
		return path;
	}

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
}