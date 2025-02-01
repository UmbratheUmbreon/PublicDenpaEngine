package editors;

#if desktop
import Discord.DiscordClient;
#end
import Conductor.BPMChangeEvent;
import Note.StrumNote;
import Song;
import flash.geom.Rectangle;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.media.AudioBuffer;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;
#if MODS_ALLOWED
import flash.media.Sound;
#end
import CoolUtil.convPathShit;

/**
 * State for creating `Song` charts.
 */
class ChartingState extends MusicBeatState
{
	public static var noteTypeList:Array<String> = //Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
	[
		'',
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation',
		'Cross Fade',
		'GF Cross Fade',
		'Third Strum'
	];
	private var noteTypeIntMap:Map<Int, String> = new Map<Int, String>();
	private var noteTypeMap:Map<String, Null<Int>> = new Map<String, Null<Int>>();
	public var ignoreWarnings = false;
	public var autoSave = true;
	public var autoSaveLength:Float = 60;
	//used for sustains, select box, etc
	//shit like this is by vidyagirl/ai186
	//sub 10 keys are used for normal colours, 10+ keys are used for pixel note colours
	final noteColors:Map<Int, Array<String>> = [
		0 => ["0xffcccccc"],
		1 => ["0xffc24b99", "0xfff9393f"],
		2 => ["0xffc24b99", "0xffcccccc", "0xfff9393f"],
		3 => ["0xffc24b99", "0xff00ffff", "0xff12fa05", "0xfff9393f"],
		4 => ["0xffc24b99", "0xff00ffff", "0xffcccccc", "0xff12fa05", "0xfff9393f"],
		5 => ["0xffc24b99", "0xff12fa05", "0xfff9393f", "0xffffff00", "0xff00ffff", "0xff0033ff"],
		6 => ["0xffc24b99", "0xff12fa05", "0xfff9393f", "0xffcccccc", "0xffffff00", "0xff00ffff", "0xff0033ff"],
		7 => ["0xffc24b99", "0xff00ffff", "0xff12fa05", "0xfff9393f", "0xffffff00", "0xff8b4aff", "0xffff0000", "0xff0033ff"],
		8 => ["0xffc24b99", "0xff00ffff", "0xff12fa05", "0xfff9393f", "0xffcccccc", "0xffffff00", "0xff8b4aff", "0xffff0000", "0xff0033ff"],
		10 => ["0xffcccccc"],
		11 => ["0xffe276ff", "0xffff884e"],
		12 => ["0xffe276ff", "0xffcccccc", "0xffff884e"],
		13 => ["0xffe276ff", "0xff3dcaff", "0xff71e300", "0xffff884e"],
		14 => ["0xffe276ff", "0xff3dcaff", "0xffcccccc", "0xff71e300", "0xffff884e"],
		15 => ["0xffe276ff", "0xff71e300", "0xffff884e", "0xffff76b5", "0xff3dcaff", "0xfff1fe4e"],
		16 => ["0xffe276ff", "0xff71e300", "0xffff884e", "0xffcccccc", "0xffff76b5", "0xff3dcaff", "0xfff1fe4e"],
		17 => ["0xffe276ff", "0xff3dcaff", "0xff71e300", "0xffff884e", "0xffff76b5", "0xff413dff", "0xff00e339", "0xfff1fe4e"],
		18 => ["0xffe276ff", "0xff3dcaff", "0xff71e300", "0xffff884e", "0xffcccccc", "0xffff76b5", "0xff413dff", "0xff00e339", "0xfff1fe4e"],
	];

	final mouse_listeners:Array<openfl.events.EventType<openfl.events.MouseEvent>> = [
		MouseEvent.MOUSE_DOWN, MouseEvent.RIGHT_MOUSE_DOWN, MouseEvent.MOUSE_MOVE
	];

	var eventStuff:Array<Array<String>> =
	[
		['', "No Event."],
		['Add Subtitle', "Adds a subtitle.\nValue 1: Text.\nValue 2: Color (write as 0xffffffff)\nValue 3: Duration before fadeout in STEPS.\n(Add to the end of value 2, with a comma to seperate.)"],
		['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Build Up Tint', "Slowly tints the stage as build up (As seen in MFM).\nValue 1: Duration (In seconds).\nValue 2: Colour.\n(Write as 0xffffffff)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Change Character', "Value 1: Character to change (Dad(1), BF(0), GF(2), Player4(3))\nValue 2: New character's name"],
		['Change Mania', "Value 1: The new mania value (min: 0; max: 9)\nValue 2: Fade, blank/0 to not fade, 1 to fade."],
		//['Change Modchart', "Value 1: The new modchart name.\nValue 2: Who's to swap.\nValue 3: Tween X and Y.\n(Add to the end of value 2, with a comma to seperate.)\n(Write as true or false)"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Change Zoom Interval', "Changes how often the camera zooms.\n\nValue 1: The Zoom Interval. (minimum 0, must be integer.)\nValue 2: The Zoom Delay. (minimum 0, must be integer.)\n\nLeave either value blank to change to default.\n\nDefaults:\nZoom Interval: 4\nZoom Delay: 0"],
		['Flash Camera', "Value 1: Duration to fade.\nValue 2: Colour. (Write as '0xffffff')"],
		['Flash Camera (HUD)', "Value 1: Duration to fade.\nValue 2: Colour. (Write as '0xffffff')"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Hide HUD', "Value 1: Duration to fade."],
		['Kill Henchmen', "Kills the Henchmen.\nFor Mom's songs, don't use this please, i love them :("],
		['Philly Glow', "\"Exclusive\" to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n\nWhen NOT on the week 3 stage:\nValue 1: 0 = OFF, 1 = ON/New Colour.\nShould behave like Blammed Lights.\n\nValue 2: Color. (write as 0xffffffff)"],
		['Play Animation', "Plays an animation on a Character,\nOnce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Set Cam Speed', "Sets Camera's Movement Speed,\nValue 1: Speed to set to."],
		['Stage Tint', "Tints the stage a certain colour.\nValue 1: Intensity (Write as '0.1').\nValue 2: Duration (In seconds).\nValue 3: Colour.\n(Add to the end of value 2, with a comma to seperate.)\n(Write as 0xffffffff)"],
		['Swap Hud', "Swaps the positions of the strums."],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		['Tween Camera Angle', "Tweens the Camera's angle.\nValue 1: The Angle to tween to.\nValue 2: The amount of time to tween.\nValue 3: Easing.\n(Add to the end of value 2, with a comma to seperate.)"],
		['Tween Camera Zoom', "Tweens the Camera's zoom.\nValue 1: The Zoom to tween to.\nValue 2: The amount of time to tween.\nValue 3: Easing.\n(Add to the end of value 2, with a comma to seperate.)"],
		['Tween Hud Angle', "Tweens the Hud's angle.\nValue 1: The Angle to tween to.\nValue 2: The amount of time to tween.\nValue 3: Easing.\n(Add to the end of value 2, with a comma to seperate.)"],
		['Tween Hud Zoom', "Tweens the Hud's zoom.\nValue 1: The Zoom to tween to.\nValue 2: The amount of time to tween.\nValue 3: Easing.\n(Add to the end of value 2, with a comma to seperate.)"],
		['Tween Note Direction', "Tweens the direction the notes scroll.\nValue 1: The Direction to tween to.\nValue 2: The amount of time to tween.\nValue 3: Easing.\n(Add to the end of value 2, with a comma to seperate.)"]
	];

	var _file:FileReference;

	var UI_box:FlxUITabMenu;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	public static var curSection:Int = 0;
	private static var lastSong:String = '';

	var bpmTxt:FlxText;

	var camPos:FlxObject;
	var strumLine:FlxSprite;
	var quant:AttachedSprite;
	var strumLineNotes:FlxTypedGroup<Note.StrumNote>;
	var eventIcon:FlxSprite;

	public static inline final GRID_SIZE:Int32 = 40; //one does not require large memory mhm mhm

	var selectionArrow:SelectionArrow;
	var selectionEvent:FlxSprite;

	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var renderedSustainsMap:Map<Note, FlxSprite> = new Map();
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<AttachedFlxText>;

	var nextRenderedSustains:FlxTypedGroup<FlxSprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var gridQuantOverlay:FlxSprite;
	final gridMult:Int32 = 2;

	var daquantspot = 0;
	var curEventSelected:Int = 0;
	/**
 	* Local song for Charting state.
	* Use for all functions related to the song file.
 	*/
	var _song:SwagSong;
	/**
 	* Currently selected note, used for many note functions.
	* WILL BE THE LAST PLACED NOTE!
 	*/
	var curSelectedNote:Array<Dynamic> = null;

	var playbackSpeed(default, set):Float = 1;

	var vocals:FlxSound = null;
	var secondaryVocals:FlxSound = null;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var currentSongName:String;
	
	var zoomTxt:FlxText;
	var curZoom:Int = 4;

	var bg:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;
	var gradient:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var bgScrollColorTween:FlxTween;
	var bgScroll2ColorTween:FlxTween;
	var gradientColorTween:FlxTween;

	//gets black over 1/24 snap
	final zoomList:Array<Float> =
	#if !html5
	[
		0.0625,
		0.125,
		0.25,
		0.5,
		1,
		2,
		4,
		8,
		12,
		16,
		20,
		24
	];
	#else //The grid gets all black when over 1/12 snap
	[
		0.5,
		1,
		2,
		4,
		8,
		12
	];
	#end

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenuCustom> = [];

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public final quants:Array<Float> = [
		4,// quarter
		2,//half
		4/3,
		1,
		4/8//eight
	];

	public static var curQuant = 0;
	public static var vortex:Bool = false;
	var autoSaveTimer:FlxTimer;
	var autoSaveTxt:FlxSprite;
	var difficultyString:String;

	/**
 	* Song to load when no song is found/empty song is loaded.
 	*/
	var failsafeSong:SwagSong = {
		header: {
			song: 'Test',
			bpm: 150.0,
			needsVoices: true,
			instVolume: 1,
			vocalsVolume: 1,
			secVocalsVolume: 1,
		},

		assets: {
			player1: 'bf',
			player2: 'dad',
			player3: null,
			gfVersion: 'gf',
			enablePlayer4: false,
			player4: 'placeman',
			arrowSkin: 'NOTE_assets',
			splashSkin: 'splashes/noteSplashes', //idk it would crash if i didn't
			stage: 'stage',
		},

		options: {
			speed: 1,
			mania: Note.defaultMania,
			dangerMiss: false,
			crits: false,
			allowBot: true,
			allowGhostTapping: true,
			beatDrain: false,
			tintRed: 255,
			tintGreen: 255,
			tintBlue: 255,
			modchart: 'none',
			dadModchart: 'none',
			p4Modchart: 'none',
			credits: null,
			remixCreds: null
		},
		notes: [],
		events: []
	};

	override function destroy() {
		for(listener in mouse_listeners) FlxG.stage.removeEventListener(listener, handleMouseInput);
		super.destroy();
	}

	override function create()
	{
		for(listener in mouse_listeners) FlxG.stage.addEventListener(listener, handleMouseInput);
		Paths.clearUnusedCache();
		Paths.refreshModsMaps(true, true, true);

		if (PlayState.SONG != null)
			_song = PlayState.SONG;
		else
		{
			_song = failsafeSong;
			addSection();
			PlayState.SONG = _song;
		}

		PlayState.mania = _song.options.mania;

		difficultyString = CoolUtil.toTitleCase(CoolUtil.difficultyString().toLowerCase());

		if (difficultyString == null || difficultyString == '') difficultyString = 'Null';

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('Chart Editor - ${StringTools.replace(_song.header.song, '-', ' ')} ($difficultyString)', null);
		#end

		if (FlxG.save.data.chart_vortex != null) vortex = FlxG.save.data.chart_vortex;
		if (FlxG.save.data.ignoreWarnings != null) ignoreWarnings = FlxG.save.data.ignoreWarnings;
		if (FlxG.save.data.autosave != null) autoSave = FlxG.save.data.autosave;
		if (FlxG.save.data.autosavelength != null) autoSaveLength = FlxG.save.data.autosavelength;
		if (!ClientPrefs.settings.get("lowQuality")) {
			bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
			bg.scrollFactor.set();
			bg.color = 0xFF222222;
			bg.active = false;
			add(bg);
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.scrollFactor.set(0,0);
			bgScroll.velocity.set(29, 30);
			bgScroll.color = bg.color;
			add(bgScroll);
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.scrollFactor.set(0,0);
			bgScroll2.velocity.set(-29, -30);
			bgScroll2.color = bg.color;
			add(bgScroll2);
			gradient = new FlxSprite(0,0).loadGraphic(Paths.image('gradient'));
			gradient.color = bg.color;
			gradient.scrollFactor.set();
			gradient.active = false;
			add(gradient);
			intendedColor = bg.color;
		}

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new FlxSprite(GRID_SIZE, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		waveformSprite.antialiasing = false;
		waveformSprite.active = false;
		add(waveformSprite);

		eventIcon = new FlxSprite(-GRID_SIZE - 5, -90).loadGraphic(Paths.image('eventArrow'));
		leftIcon = new HealthIcon('bf');
		rightIcon = new HealthIcon('dad');
		eventIcon.scrollFactor.set(1, 1);
		leftIcon.scrollFactor.set(1, 1);
		rightIcon.scrollFactor.set(1, 1);

		eventIcon.setGraphicSize(30, 30);
		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);
		leftIcon.active = rightIcon.active = eventIcon.active = false;

		add(eventIcon);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(GRID_SIZE + 10, -100);
		rightIcon.setPosition(GRID_SIZE * 5.2, -100);

		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<AttachedFlxText>();

		nextRenderedSustains = new FlxTypedGroup<FlxSprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		if(curSection >= _song.notes.length) curSection = _song.notes.length - 1;

		FlxG.mouse.visible = true;

		currentSongName = Paths.formatToSongPath(_song.header.song);
		loadAudioBuffer();
		reloadGridLayer();
		loadSong();
		Conductor.changeBPM(_song.header.bpm);
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1100, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		bpmTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.NONE, FlxColor.BLACK);
		bpmTxt.active = false;
		add(bpmTxt);

		quant = new AttachedSprite('chart_quant','chart_quant');
		quant.animation.addByPrefix('q','chart_quant',0,false);
		quant.animation.play('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);
		
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		for (i in 0...(Note.ammo[_song.options.mania] * 2)){
			var note:StrumNote = new StrumNote(GRID_SIZE * (i+1), strumLine.y, i % Note.ammo[_song.options.mania], 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
			note.active = vortex;
		}
		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + 360, strumLine.y);

		selectionArrow = new SelectionArrow(0, 0, 0);
		selectionArrow.visible = false;
		selectionArrow.mania = _song.options.mania;
		var skin:String = 'NOTE_assets';
		if(PlayState.SONG.assets.arrowSkin != null && PlayState.SONG.assets.arrowSkin.length > 1) skin = PlayState.SONG.assets.arrowSkin;
		selectionArrow.texture = skin; //Load texture and anims
		selectionArrow.playAnim('static0', true);
		selectionArrow.alpha = 0.75;
		add(selectionArrow);

		selectionEvent = new FlxSprite().loadGraphic(Paths.image('eventArrow'));
		selectionEvent.setGraphicSize(GRID_SIZE, GRID_SIZE);
		selectionEvent.updateHitbox();
		selectionEvent.active = selectionEvent.visible = false;
		selectionEvent.alpha = 0.5;
		add(selectionEvent);

		var tabs = [
			{name: "Options", label: 'Options'},
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Charting", label: 'Charting'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.resize(330, 400);
		UI_box.x = FlxG.width / 2 + 120;
		UI_box.y = 25;
		UI_box.scrollFactor.set();

		final text =
		"Left Click - Add/Delete Note
		\nRight Click - Select Note
		\nW/S/Mouse Wheel - Change Time
		\nA/Left | D/Right - Change Section
		\nZ/X - Change Zoom
		\nQ/E - Change Note Sustain Length
		\nSpace - Stop/Resume Song
		\nEnter - Play Song at Current Section
		\n(Hold) Shift + Enter - Play Song at Start
		\nBackspace/Escape - Exit to Freeplay
		\nL Bracket / R Bracket - Change Playback Rate
		\n(Hold) Alt + Bracket - Reset Playback Rate
		\nDel - Clear Section
		\n(Hold) Control + C - Copy Section
		\n(Hold) Control + X - Cut Section
		\n(Hold) Control + V - Paste Section
		\n(Hold) Control + S - Save to Autosave
		\n(Hold) Control + Left/Right - Shift Selected Note
		\n(Hold) Shift - Move 4x Faster";

		var tipTextArray:Array<String> = text.split('\n');
		for (i in 0...tipTextArray.length) {
			var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height, 0, tipTextArray[i], 16);
			tipText.y += i * 7.5;
			tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.NONE, FlxColor.BLACK);
			tipText.scrollFactor.set();
			tipText.active = false;
			add(tipText);
		}
		add(UI_box);

		addOptionsUI();
		addSongUI();
		addSectionUI();
		addNoteUI();
		addEventsUI();
		addChartingUI();
		updateHeads();
		#if desktop
		updateWaveform();
		#end
		UI_box.selected_tab_id = 'Song';

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		if(lastSong != currentSongName)
			changeSection();

		lastSong = currentSongName;

		zoomTxt = new FlxText(10, (ClientPrefs.settings.get("showFPS")) ? 20 : 10, 0, "Zoom: 1x", 16);
		zoomTxt.scrollFactor.set();
		zoomTxt.active = false;
		add(zoomTxt);
		
		updateGrid();

		autoSaveTxt = new FlxSprite(10, FlxG.height - 58).loadGraphic(Paths.image('saving'));
		autoSaveTxt.scale.set(0.5,0.5);
		autoSaveTxt.updateHitbox();
		autoSaveTxt.scrollFactor.set();
		autoSaveTxt.alpha = 0;
		autoSaveTxt.active = false;
		add(autoSaveTxt);
		if(autoSaveTimer != null) {
			autoSaveTimer.cancel();
			autoSaveTimer = null;
			autoSaveTxt.alpha = 0;
		}
		autoSaveTimer = new FlxTimer().start(autoSaveLength, function(tmr:FlxTimer) {
			FlxTween.tween(autoSaveTxt, {alpha: 1}, 1, {
				ease: FlxEase.quadInOut,
				onComplete: function (twn:FlxTween) {
					FlxTween.tween(autoSaveTxt, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.quadInOut
					});
				}
			});
			autosaveSong();
		}, 0);

		strumLineNotes.visible = quant.visible = vortex;
		var gWidth = GRID_SIZE * (Note.ammo[_song.options.mania] * 2);
		camPos.x = -80 + gWidth;
		strumLine.width = gWidth;

		FlxG.camera.follow(camPos);

		updateSongPos();
		recalculateSteps();
		updateBpmText();
		updateSelectArrow();

		super.create();
	}

	var UI_songTitle:FlxUIInputText;
	var creditsInputText:FlxUIInputText;
	var remixInputText:FlxUIInputText;
	var difficultyDropDown:FlxUIDropDownMenuCustom;
	var selectedDifficulty:String;
	var dropDownDiffs:Array<String> = ["Normal"];
	function addSongUI():Void
	{
		UI_songTitle = new FlxUIInputText(10, 10, 130, _song.header.song, 8);
		UI_songTitle.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(UI_songTitle);
		
		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.header.needsVoices;
		check_voices.callback = function()
		{
			_song.header.needsVoices = check_voices.checked;
		};

		var saveButton:FlxButton = new FlxButton(150, 8, "Save JSON", function()
		{
			saveLevel();
		});
		saveButton.color = FlxColor.LIME;
		saveButton.label.color = FlxColor.WHITE;

		var reloadSong:FlxButton = new FlxButton(saveButton.x + 90, saveButton.y, "Reload Audio", function()
		{
			currentSongName = Paths.formatToSongPath(UI_songTitle.text);
			loadSong();
			loadAudioBuffer();
			#if desktop
			updateWaveform();
			#end
		});
		reloadSong.color = FlxColor.YELLOW;
		reloadSong.label.color = FlxColor.WHITE;

		var reloadSongJson:FlxButton = new FlxButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', 0, function(){loadJson(_song.header.song.toLowerCase()); }, null,ignoreWarnings));
		});
		reloadSongJson.color = 0xffff7e00;
		reloadSongJson.label.color = FlxColor.WHITE;

		var loadAutosaveBtn:FlxButton = new FlxButton(reloadSong.x, reloadSongJson.y + 30, 'Load Autosave', function()
		{
			PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosavejson);
			MusicBeatState.resetState();
		});
		loadAutosaveBtn.color = FlxColor.GREEN;
		loadAutosaveBtn.label.color = FlxColor.WHITE;

		var loadEventJson:FlxButton = new FlxButton(saveButton.x, reloadSongJson.y + 30, 'Load Events', function()
		{
			var songName:String = Paths.formatToSongPath(_song.header.song);
			var file:String = Paths.json('charts/' + songName + '/events');
			#if sys
			if (FileSystem.exists(file) #if MODS_ALLOWED || FileSystem.exists(Paths.modsJson('charts/' + songName + '/events')) #end)
			#else
			if (OpenFlAssets.exists(file))
			#end
			{
				clearEvents();
				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;
				changeSection(curSection);
			}
		});
		loadEventJson.color = FlxColor.GREEN;
		loadEventJson.label.color = FlxColor.WHITE;

		var saveEvents:FlxButton = new FlxButton(saveButton.x, reloadSongJson.y, 'Save Events', function ()
		{
			saveEvents();
		});
		saveEvents.color = FlxColor.LIME;
		saveEvents.label.color = FlxColor.WHITE;

		var clear_events:FlxButton = new FlxButton(340, 310, 'Clear Events', function()
		{
			openSubState(new Prompt('This action will clear placed events.\n\nProceed?', 0, clearEvents, null,ignoreWarnings));
		});
		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(340, clear_events.y + 25, 'Clear Notes', function()
		{
			openSubState(new Prompt('This action will clear placed notes.\n\nProceed?', 0, function(){for (sec in 0..._song.notes.length) {
				_song.notes[sec].sectionNotes = [];
			}
			updateGrid();
		}, null,ignoreWarnings));
				
		});
		clear_notes.color = FlxColor.RED;
		clear_notes.label.color = FlxColor.WHITE;

		var load_empty:FlxButton = new FlxButton(340, clear_notes.y + 25, 'Load Empty', function()
		{
			openSubState(new Prompt('This action will clear ALL current progress.\n\nProceed?', 0, function(){
			_song = failsafeSong;
			PlayState.SONG = _song;
			MusicBeatState.resetState();
			addSection();
		}, null,ignoreWarnings));
				
		});
		load_empty.color = FlxColor.RED;
		load_empty.label.color = FlxColor.WHITE;

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 70, 1, 1, 1, 9999, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, stepperBPM.y + 35, 0.1, 1, 0.1, 10, 1);
		stepperSpeed.value = _song.options.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

		var randomPositionArray:Array<Float> = [10, stepperSpeed.y + 35];

		var stepperInstVolume:FlxUINumericStepper = new FlxUINumericStepper(100, stepperSpeed.y, 0.1, 1, 0, 1, 1);
		stepperInstVolume.value = _song.header.instVolume;
		stepperInstVolume.name = 'song_inst_volume';
		blockPressWhileTypingOnStepper.push(stepperInstVolume);

		var stepperVocalsVolume:FlxUINumericStepper = new FlxUINumericStepper(randomPositionArray[0], randomPositionArray[1], 0.1, 1, 0, 1, 1);
		stepperVocalsVolume.value = _song.header.vocalsVolume;
		stepperVocalsVolume.name = 'song_vocals_volume';
		blockPressWhileTypingOnStepper.push(stepperVocalsVolume);

		var stepperSecVocalsVolume:FlxUINumericStepper = new FlxUINumericStepper(stepperInstVolume.x, randomPositionArray[1], 0.1, 1, 0, 1, 1);
		stepperSecVocalsVolume.value = _song.header.secVocalsVolume;
		stepperSecVocalsVolume.name = 'song_sec_vocals_volume';
		blockPressWhileTypingOnStepper.push(stepperSecVocalsVolume);

		creditsInputText = new FlxUIInputText(randomPositionArray[0], randomPositionArray[1] + 50, 310, _song.options.credits, 8);
		creditsInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(creditsInputText);

		remixInputText = new FlxUIInputText(creditsInputText.x, creditsInputText.y + 20, 310, _song.options.remixCreds, 8);
		remixInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(remixInputText);

		if (CoolUtil.difficulties != null) {
			dropDownDiffs = CoolUtil.difficulties;
		}
		var difficultyDropDown = new FlxUIDropDownMenuCustom(180, randomPositionArray[1] - 35, FlxUIDropDownMenuCustom.makeStrIdLabelArray(dropDownDiffs, true), function(character:String)
		{
			selectedDifficulty = dropDownDiffs[Std.parseInt(character)];
			for (i in 0...dropDownDiffs.length) {
				if (selectedDifficulty == dropDownDiffs[i]) {
					PlayState.storyDifficulty = i;
					break;
				}
			}
		});
		difficultyDropDown.selectedLabel = dropDownDiffs[PlayState.storyDifficulty];
		blockPressWhileScrolling.push(difficultyDropDown);

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);

		tab_group_song.add(check_voices);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(load_empty);
		tab_group_song.add(saveButton);
		tab_group_song.add(saveEvents);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stepperInstVolume);
		tab_group_song.add(stepperVocalsVolume);
		tab_group_song.add(stepperSecVocalsVolume);
		tab_group_song.add(creditsInputText);
		tab_group_song.add(remixInputText);
		tab_group_song.add(new FlxText(stepperBPM.x, stepperBPM.y - 15, 0, 'Song BPM:'));
		tab_group_song.add(new FlxText(stepperSpeed.x, stepperSpeed.y - 15, 0, 'Song Speed:'));
		tab_group_song.add(new FlxText(stepperInstVolume.x, stepperInstVolume.y - 15, 0, 'Inst Volume:'));
		tab_group_song.add(new FlxText(stepperVocalsVolume.x, stepperVocalsVolume.y - 15, 0, 'Vocals Volume:'));
		tab_group_song.add(new FlxText(stepperSecVocalsVolume.x, stepperSecVocalsVolume.y - 15, 0, 'Sec-Vocals Volume:'));
		tab_group_song.add(new FlxText(creditsInputText.x, creditsInputText.y - 15, 0, 'Song Credits:'));
		tab_group_song.add(difficultyDropDown);
		tab_group_song.add(new FlxText(difficultyDropDown.x, difficultyDropDown.y - 15, 0, 'Difficulty:'));

		UI_box.addGroup(tab_group_song);
	}

	var stageDropDown:FlxUIDropDownMenuCustom;
	var modChartDropDown:FlxUIDropDownMenuCustom;
	var dadModChartDropDown:FlxUIDropDownMenuCustom;
	var p4ModChartDropDown:FlxUIDropDownMenuCustom;
	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;
	function addOptionsUI():Void
	{
		var check_dangerMiss = new FlxUICheckBox(10, 295, null, null, "Danger Miss", 100);
		check_dangerMiss.checked = _song.options.dangerMiss;
		check_dangerMiss.callback = function()
		{
			_song.options.dangerMiss = check_dangerMiss.checked;
		};

		var check_crits = new FlxUICheckBox(10, 325, null, null, "Critical Hits", 100);
		check_crits.checked = _song.options.crits;
		check_crits.callback = function()
		{
			_song.options.crits = check_crits.checked;
		};

		var check_beatDrain = new FlxUICheckBox(10, 355, null, null, "Beat Drain", 100);
		check_beatDrain.checked = _song.options.beatDrain;
		check_beatDrain.callback = function()
		{
			_song.options.beatDrain = check_beatDrain.checked;
		};

		var check_allowBot = new FlxUICheckBox(135, 295, null, null, "Allow Botplay", 100);
		check_allowBot.checked = _song.options.allowBot;
		check_allowBot.callback = function()
		{
			_song.options.allowBot = check_allowBot.checked;
		};
	
		var check_allowGhostTapping = new FlxUICheckBox(135, 325, null, null, "Allow Ghost Tapping", 100);
		check_allowGhostTapping.checked = _song.options.allowGhostTapping;
		check_allowGhostTapping.callback = function()
		{
			_song.options.allowGhostTapping = check_allowGhostTapping.checked;
		};

		var check_enablePlayer4 = new FlxUICheckBox(135, 355, null, null, "Player 4", 100);
		check_enablePlayer4.checked = _song.assets.enablePlayer4;
		check_enablePlayer4.callback = function()
		{
			_song.assets.enablePlayer4 = check_enablePlayer4.checked;
		};

		var characters:Array<String> = [];
		for (key in Paths.characterMap.keys()) {
			characters.push(key);
		}
		characters = CoolUtil.removeDuplicates(characters);
		characters.remove('placeman');
		characters.insert(0, 'placeman');
	
		var player1DropDown = new FlxUIDropDownMenuCustom(10, 20, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.assets.player1 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player1DropDown.selectedLabel = _song.assets.player1;
		blockPressWhileScrolling.push(player1DropDown);
	
		var player3DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player1DropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.assets.gfVersion = characters[Std.parseInt(character)];
			updateHeads();
		});
		player3DropDown.selectedLabel = _song.assets.gfVersion;
		blockPressWhileScrolling.push(player3DropDown);
	
		var player2DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player3DropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.assets.player2 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player2DropDown.selectedLabel = _song.assets.player2;
		blockPressWhileScrolling.push(player2DropDown);

		var player4DropDown = new FlxUIDropDownMenuCustom(player1DropDown.x, player2DropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.assets.player4 = characters[Std.parseInt(character)];
			updateHeads();
		});
		player4DropDown.selectedLabel = _song.assets.player4;
		blockPressWhileScrolling.push(player4DropDown);
	
		var stages:Array<String> = [];
		for (key in Paths.stageMap.keys()) {
			stages.push(key);
		}
		stages = CoolUtil.removeDuplicates(stages);
		stages.remove('stage');
		stages.insert(0, 'stage');
	
		stageDropDown = new FlxUIDropDownMenuCustom(player1DropDown.x + 155, player1DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(stages, true), function(character:String)
		{
			_song.assets.stage = stages[Std.parseInt(character)];
		});
		stageDropDown.selectedLabel = _song.assets.stage;
		blockPressWhileScrolling.push(stageDropDown);

		var tempMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [Paths.getPreloadPath('scripts/modcharts/')];
		#if MODS_ALLOWED
		directories.push(Paths.mods('scripts/modcharts/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/scripts/modcharts/'));
		#end
		var modcharts:Array<String> = ['none'];
		for (i in 0...directories.length) {
			var directory:String = directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.hscript')) {
						var modchartToCheck:String = file.split(".")[0];
						if(!tempMap.exists(modchartToCheck)) {
							tempMap.set(modchartToCheck, true);
							modcharts.push(modchartToCheck);
						}
					}
				}
			}
		}
	
		modChartDropDown = new FlxUIDropDownMenuCustom(stageDropDown.x, player3DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(modcharts, true), function(character:String)
		{
			_song.options.modchart = modcharts[Std.parseInt(character)];
		});
		modChartDropDown.selectedLabel = _song.options.modchart;
		blockPressWhileScrolling.push(modChartDropDown);

		dadModChartDropDown = new FlxUIDropDownMenuCustom(stageDropDown.x, player2DropDown.y, FlxUIDropDownMenuCustom.makeStrIdLabelArray(modcharts, true), function(character:String)
		{
			_song.options.dadModchart = modcharts[Std.parseInt(character)];
		});
		dadModChartDropDown.selectedLabel = _song.options.dadModchart;
		blockPressWhileScrolling.push(dadModChartDropDown);

		p4ModChartDropDown = new FlxUIDropDownMenuCustom(stageDropDown.x, player2DropDown.y + 40, FlxUIDropDownMenuCustom.makeStrIdLabelArray(modcharts, true), function(character:String)
		{
			_song.options.p4Modchart = modcharts[Std.parseInt(character)];
		});
		p4ModChartDropDown.selectedLabel = _song.options.p4Modchart;
		blockPressWhileScrolling.push(p4ModChartDropDown);
	
		var skin = PlayState.SONG.assets.arrowSkin;
		if(skin == null) skin = '';
		noteSkinInputText = new FlxUIInputText(player2DropDown.x, player2DropDown.y + 90, 150, skin, 8);
		noteSkinInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(noteSkinInputText);

		noteSplashesInputText = new FlxUIInputText(noteSkinInputText.x + 155, noteSkinInputText.y/* + 35*/, 150, _song.assets.splashSkin, 8);
		noteSplashesInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(noteSplashesInputText);
	
		var reloadNotesButton:FlxButton = new FlxButton(340, 360, 'Reload Notes', function() {
			selectionArrow.texture = _song.assets.arrowSkin = noteSkinInputText.text;
			updateGrid();
		});
		reloadNotesButton.color = FlxColor.RED;
		reloadNotesButton.label.color = FlxColor.WHITE;
		
		var stepperMania:FlxUINumericStepper = new FlxUINumericStepper(player2DropDown.x, 235, 1, 3, Note.minMania, Note.maxMania, 1);
		stepperMania.value = _song.options.mania;
		stepperMania.name = 'mania';
		blockPressWhileTypingOnStepper.push(stepperMania);

		var stepperTintRed:FlxUINumericStepper = new FlxUINumericStepper(stepperMania.x + 130, 235, 5, 255, 0, 255, 1);
		stepperTintRed.value = _song.options.tintRed;
		stepperTintRed.name = 'tintRed';
		blockPressWhileTypingOnStepper.push(stepperTintRed);

		var stepperTintGreen:FlxUINumericStepper = new FlxUINumericStepper(stepperTintRed.x + 60, 235, 5, 255, 0, 255, 1);
		stepperTintGreen.value = _song.options.tintGreen;
		stepperTintGreen.name = 'tintGreen';
		blockPressWhileTypingOnStepper.push(stepperTintGreen);

		var stepperTintBlue:FlxUINumericStepper = new FlxUINumericStepper(stepperTintGreen.x + 60, 235, 5, 255, 0, 255, 1);
		stepperTintBlue.value = _song.options.tintBlue;
		stepperTintBlue.name = 'tintBlue';
		blockPressWhileTypingOnStepper.push(stepperTintBlue);
	
		var tab_group_options = new FlxUI(null, UI_box);
		tab_group_options.name = "Options";

		tab_group_options.add(check_dangerMiss);
		tab_group_options.add(check_allowBot);
		tab_group_options.add(check_crits);
		tab_group_options.add(check_allowGhostTapping);
		tab_group_options.add(check_beatDrain);
		tab_group_options.add(check_enablePlayer4);
		tab_group_options.add(stepperMania);
		tab_group_options.add(stepperTintRed);
		tab_group_options.add(stepperTintGreen);
		tab_group_options.add(stepperTintBlue);
		tab_group_options.add(reloadNotesButton);
		tab_group_options.add(noteSkinInputText);
		tab_group_options.add(noteSplashesInputText);
		tab_group_options.add(new FlxText(stepperMania.x, stepperMania.y - 15, 0, 'Mania:'));
		tab_group_options.add(new FlxText(stepperTintRed.x, stepperTintRed.y - 15, 0, 'Tint RGB:'));
		tab_group_options.add(new FlxText(player2DropDown.x, player2DropDown.y - 15, 0, 'Opponent:'));
		tab_group_options.add(new FlxText(player4DropDown.x, player4DropDown.y - 15, 0, 'Player 4:'));
		tab_group_options.add(new FlxText(player3DropDown.x, player3DropDown.y - 15, 0, 'Girlfriend:'));
		tab_group_options.add(new FlxText(player1DropDown.x, player1DropDown.y - 15, 0, 'Boyfriend:'));
		tab_group_options.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 0, 'Stage:'));
		tab_group_options.add(new FlxText(modChartDropDown.x, modChartDropDown.y - 15, 0, 'Player Modchart:'));
		tab_group_options.add(new FlxText(dadModChartDropDown.x, dadModChartDropDown.y - 15, 0, 'Dad Modchart:'));
		tab_group_options.add(new FlxText(p4ModChartDropDown.x, p4ModChartDropDown.y - 15, 0, 'Player 4 Modchart:'));
		tab_group_options.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 15, 0, 'Note Texture:'));
		tab_group_options.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 0, 'Note Splashes Texture:'));
		tab_group_options.add(p4ModChartDropDown);
		tab_group_options.add(player4DropDown);
		tab_group_options.add(dadModChartDropDown);
		tab_group_options.add(player2DropDown);
		tab_group_options.add(player3DropDown);
		tab_group_options.add(modChartDropDown);
		tab_group_options.add(player1DropDown);
		tab_group_options.add(stageDropDown);
	
		UI_box.addGroup(tab_group_options);
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_player4Section:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;
	var check_crossFade:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		stepperLength = new FlxUINumericStepper(10, 10, 4, 0, 0, 999, 0);
		stepperLength.value = _song.notes[curSection].lengthInSteps;
		stepperLength.name = 'section_length';
		blockPressWhileTypingOnStepper.push(stepperLength);

		check_mustHitSection = new FlxUICheckBox(10, 40, null, null, "Must hit section\n(Focus on BF)", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSection].mustHitSection;

		check_gfSection = new FlxUICheckBox(10, 110, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSection].gfSection;

		check_player4Section = new FlxUICheckBox(10, 75, null, null, "Player 4 Section\n(Focus on P4)", 100);
		check_player4Section.name = 'check_player4section';
		check_player4Section.checked = _song.notes[curSection].player4Section;

		check_altAnim = new FlxUICheckBox(135, 40, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSection].altAnim;
		check_altAnim.name = 'check_altAnim';

		check_crossFade = new FlxUICheckBox(135, 75, null, null, "Cross Fade", 100);
		check_crossFade.checked = _song.notes[curSection].crossFade;
		check_crossFade.name = 'check_crossFade';

		check_changeBPM = new FlxUICheckBox(220, 10, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSection].changeBPM;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(155, 10, 1, Conductor.bpm, 0, 999, 1);
		if(check_changeBPM.checked) {
			stepperSectionBPM.value = _song.notes[curSection].bpm;
		} else {
			stepperSectionBPM.value = Conductor.bpm;
		}
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);


		var copyButton:FlxButton = new FlxButton(10, 160, "Copy Section", function()
		{
			copyNotes();
		});
		copyButton.color = FlxColor.CYAN;
		copyButton.label.color = FlxColor.WHITE;

		var pasteButton:FlxButton = new FlxButton(10, copyButton.y + 40, "Paste Section", function()
		{
			pasteNotes();
		});
		pasteButton.color = FlxColor.MAGENTA;
		pasteButton.label.color = FlxColor.WHITE;

		var cutButton:FlxButton = new FlxButton(10, pasteButton.y + 40, "Cut Section", function()
		{
			copyNotes();
			clearNotes();
		});
		cutButton.color = FlxColor.YELLOW;
		cutButton.label.color = FlxColor.WHITE;

		var clearSectionButton:FlxButton = new FlxButton(340, 360, "Clear Section", function()
		{
			_song.notes[curSection].sectionNotes = [];
			
			var i:Int = _song.events.length - 1;
			
			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
			while(i > -1) {
				var event:Array<Dynamic> = _song.events[i];
				if(event != null && endThing > event[0] && event[0] >= startThing)
				{
					_song.events.remove(event);
				}
				--i;
			}
			updateGrid(false);
			updateNoteUI();
		});
		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;

		var swapSection:FlxButton = new FlxButton(210, copyButton.y, "Swap section", function()
		{
			for (i in 0..._song.notes[curSection].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
				note[1] = (note[1] + Note.ammo[_song.options.mania]) % (Note.ammo[_song.options.mania] * 2);
				_song.notes[curSection].sectionNotes[i] = note;
			}
			updateGrid(false);
		});

		var stepperCopy:FlxUINumericStepper = new FlxUINumericStepper(130, copyButton.y + 23, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var copyLastButton:FlxButton = new FlxButton(110, copyButton.y, "Copy sections", function()
		{
			var value:Int = Std.int(stepperCopy.value);
			if(value == 0) return;

			var daSec = FlxMath.maxInt(curSection, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum = note[0] + Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * value);

				
				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
				if(endThing > event[0] && event[0] >= startThing)
				{
					strumTime += Conductor.stepCrochet * (_song.notes[daSec].lengthInSteps * value);
					var copiedEventArray:Array<Dynamic> = [];
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
					_song.events.push([strumTime, copiedEventArray]);
				}
			}
			updateGrid(false);
		});
		copyLastButton.color = FlxColor.CYAN;
		copyLastButton.label.color = FlxColor.WHITE;

		var duetButton:FlxButton = new FlxButton(210, copyButton.y + 40, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSection].sectionNotes)
			{
				var boob = note[1];
				if (boob > _song.options.mania){
					boob -= Note.ammo[_song.options.mania];
				}else{
					boob += Note.ammo[_song.options.mania];
				}
				
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}
			
			for (i in duetNotes)
				_song.notes[curSection].sectionNotes.push(i);
			
			updateGrid(false);
		});
		var mirrorButton:FlxButton = new FlxButton(210, duetButton.y + 40, "Mirror Notes", function()
		{
			for (note in _song.notes[curSection].sectionNotes)
			{
				var boob = note[1] % Note.ammo[_song.options.mania];
				boob = _song.options.mania - boob;
				if (note[1] > _song.options.mania) boob += Note.ammo[_song.options.mania];
					
				note[1] = boob;
			}
			
			updateGrid(false);
		});

		var stepperSectionJump:FlxUINumericStepper = new FlxUINumericStepper(130, copyButton.y + 63, 1, 0, 0, 9999, 0);
		blockPressWhileTypingOnStepper.push(stepperSectionJump);

		var jumpSection:FlxButton = new FlxButton(110, copyButton.y + 40, "Jump Section", function()
		{
			var value:Int = Std.int(stepperSectionJump.value);
			changeSection(value);
		});

		tab_group_section.add(stepperSectionJump);
		tab_group_section.add(stepperLength);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_crossFade);
		tab_group_section.add(check_player4Section);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(jumpSection);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(cutButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);
		tab_group_section.add(new FlxText(70, 10, 0, 'Step Length'));

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var strumTimeInputText:FlxUIInputText; //I wanted to use a stepper but we can't scale these as far as i know :(
	var noteTypeDropDown:FlxUIDropDownMenuCustom;
	var currentType:Int = 0;
	var stepperSpamCloseness:FlxUINumericStepper;
	var stepperSpamLength:FlxUINumericStepper;
	var spamLength:Float = 5;
	var spamCloseness:Float = 2;

	function addNoteUI():Void
	{
		var tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 25, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 32);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 310, "0");
		strumTimeInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;
		var displayNameList:Array<String> = [];
		while (key < noteTypeList.length) {
			displayNameList.push(noteTypeList[key]);
			noteTypeMap.set(noteTypeList[key], key);
			noteTypeIntMap.set(key, noteTypeList[key]);
			key++;
		}

		#if LUA_ALLOWED
		var directories:Array<String> = [Paths.mods('scripts/notetypes/'), Paths.mods(Paths.currentModDirectory + '/scripts/notetypes/')];
		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.lua')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!noteTypeMap.exists(fileToCheck)) {
							displayNameList.push(fileToCheck);
							noteTypeMap.set(fileToCheck, key);
							noteTypeIntMap.set(key, fileToCheck);
							key++;
						}
					}
				}
			}
		}
		#end
		#if HSCRIPT_ALLOWED
		var directories:Array<String> = [Paths.mods('scripts/notetypes/'), Paths.mods(Paths.currentModDirectory + '/scripts/notetypes/')];
		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.hscript')) {
						var fileToCheck:String = file.split(".")[0];
						if(!noteTypeMap.exists(fileToCheck)) {
							displayNameList.push(fileToCheck);
							noteTypeMap.set(fileToCheck, key);
							noteTypeIntMap.set(key, fileToCheck);
							key++;
						}
					}
				}
			}
		}
		#end

		for (i in 1...displayNameList.length) {
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new FlxUIDropDownMenuCustom(10, 105, FlxUIDropDownMenuCustom.makeStrIdLabelArray(displayNameList, true), function(character:String)
		{
			currentType = Std.parseInt(character);
			if(curSelectedNote != null && curSelectedNote[1] > -1) {
				curSelectedNote[3] = noteTypeIntMap.get(currentType);
				updateGrid(false);
			}
		});
		blockPressWhileScrolling.push(noteTypeDropDown);

		var spamButton:FlxButton = new FlxButton(noteTypeDropDown.x, noteTypeDropDown.y + 40, "Add Notes", function()
		{
			if (curSelectedNote != null) {
				for(i in 0...Std.int(spamLength)) {
					addNote(curSelectedNote[0] + (15000/_song.header.bpm)/spamCloseness, curSelectedNote[1], curSelectedNote[2], false);
				}
				updateGrid(false);
				updateNoteUI();
			}
		});
		
		stepperSpamCloseness = new FlxUINumericStepper(spamButton.x + 90, spamButton.y + 5, 2, 2, 2, 64);
		stepperSpamCloseness.value = spamCloseness;
		stepperSpamCloseness.name = 'note_spamthing';
		blockPressWhileTypingOnStepper.push(stepperSpamCloseness);

		stepperSpamLength = new FlxUINumericStepper(stepperSpamCloseness.x + 90, stepperSpamCloseness.y, 5, 5, 1, 8192);
		stepperSpamLength.value = spamLength;
		stepperSpamLength.name = 'note_spamamount';
		blockPressWhileTypingOnStepper.push(stepperSpamLength);

		tab_group_note.add(new FlxText(10, 10, 0, 'Sustain length:'));
		tab_group_note.add(new FlxText(stepperSpamCloseness.x, stepperSpamCloseness.y - 15, 0, 'Note Density:'));
		tab_group_note.add(new FlxText(stepperSpamLength.x, stepperSpamLength.y - 15, 0, 'Note Amount:'));
		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 90, 0, 'Note type:'));
		tab_group_note.add(spamButton);
		tab_group_note.add(stepperSpamCloseness);
		tab_group_note.add(stepperSpamLength);
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}

	var eventDropDown:FlxUIDropDownMenuCustom;
	var descText:FlxText;
	var selectedEventText:FlxText;
	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var leEvents:Array<String> = [];
	function addEventsUI():Void
	{
		var tab_group_event = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		#if LUA_ALLOWED
		var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
		var directories:Array<String> = [Paths.getPreloadPath('scripts/events/'), Paths.mods('scripts/events/'), Paths.mods(Paths.currentModDirectory + '/scripts/events/')];
		for (i in 0...directories.length) {
			var directory:String =  directories[i];
			if(FileSystem.exists(directory)) {
				for (file in FileSystem.readDirectory(directory)) {
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file != 'readME.txt' && file.endsWith('.txt')) {
						var fileToCheck:String = file.substr(0, file.length - 4);
						if(!eventPushedMap.exists(fileToCheck)) {
							eventPushedMap.set(fileToCheck, true);
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		eventPushedMap.clear();
		eventPushedMap = null;
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		for (i in 0...eventStuff.length) {
			leEvents.push(eventStuff[i][0]);
		}
		//leEvents = CoolUtil.removeDuplicates(leEvents);

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);
		eventDropDown = new FlxUIDropDownMenuCustom(20, 50, FlxUIDropDownMenuCustom.makeStrIdLabelArray(leEvents, true), function(pressed:String) {
			//allow for alphabetical ordering (not in use due to fucky shit)
			/*var eventName = leEvents[Std.parseInt(pressed)];
			var unOrderedEvents:Array<String> = [];
			for (event in eventStuff) unOrderedEvents.push(event[0]);
			var curEvent = unOrderedEvents.indexOf(eventName);
			descText.text = eventStuff[curEvent][1];
			if (curSelectedNote != null && eventStuff != null) {
				if (curSelectedNote != null && curSelectedNote[2] == null){
					curSelectedNote[1][curEventSelected][0] = eventStuff[curEvent][0];
				}
				updateGrid(false);
			}*/
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];
			if (curSelectedNote != null && eventStuff != null) {
				curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
			}
			updateGrid(false);
		});
		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);
		value1InputText = new FlxUIInputText(20, 110, 250, "");
		value1InputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);
		value2InputText = new FlxUIInputText(20, 150, 250, "");
		value2InputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(value2InputText);

		// New event buttons
		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				if(curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else
				{
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if(curEventSelected < 0) curEventSelected = 0;
				else if(curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length) curEventSelected = eventsGroup.length - 1;
				
				changeEventSelected();
				updateGrid(false);
			}
		});
		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;
		setAllLabelsOffset(removeButton, -30, 0);
		tab_group_event.add(removeButton);
			
		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function()
		{
			if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid(false);
			}
		});
		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;
		setAllLabelsOffset(addButton, -30, 0);
		tab_group_event.add(addButton);
			
		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function()
		{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;
		setAllLabelsOffset(moveLeftButton, -30, 0);
		tab_group_event.add(moveLeftButton);
			
		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function()
		{
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;
		setAllLabelsOffset(moveRightButton, -30, 0);
		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);

		UI_box.addGroup(tab_group_event);
	}

	function changeEventSelected(change:Int = 0)
	{
		if(curSelectedNote != null && curSelectedNote[2] == null) //Is event note
		{
			curEventSelected += change;
			if(curEventSelected < 0) curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if(curEventSelected >= curSelectedNote[1].length) curEventSelected = 0;
			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}
		updateNoteUI();
	}
	
	function setAllLabelsOffset(button:FlxButton, x:Float, y:Float)
	{
		for (point in button.labelOffsets)
		{
			point.set(x, y);
		}
	}

	var check_mute_inst:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var check_warnings:FlxUICheckBox = null;
	var check_autosave:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;
	var metronome:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	#if desktop
	var waveformEnabled:FlxUICheckBox;
	var waveformUseInstrumental:FlxUICheckBox;
	var waveformUseSec:FlxUICheckBox;
	#end
	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var sliderRate:FlxUISlider;
	function addChartingUI() {
		var tab_group_chart = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';
		
		#if desktop
		waveformEnabled = new FlxUICheckBox(10, 90, null, null, "Waveform", 100);
		if (FlxG.save.data.chart_waveform == null) FlxG.save.data.chart_waveform = false;
		waveformEnabled.checked = FlxG.save.data.chart_waveform;
		waveformEnabled.callback = function()
		{
			FlxG.save.data.chart_waveform = waveformEnabled.checked;
			waveformUseInstrumental.setClickable(waveformEnabled.checked, true);
			waveformUseSec.setClickable(waveformEnabled.checked, true);
			updateWaveform();
		};

		waveformUseInstrumental = new FlxUICheckBox(waveformEnabled.x + 120, waveformEnabled.y, null, null, "Waveform\n(Inst)", 100);
		waveformUseInstrumental.checked = false;
		waveformUseInstrumental.callback = function()
		{
			updateWaveform();
		};

		waveformUseSec = new FlxUICheckBox(waveformEnabled.x + 120, 120, null, null, "Waveform\n(Sec-Vocals)", 100);
		waveformUseSec.checked = false;
		waveformUseSec.callback = function()
		{
			updateWaveform();
		};
		waveformUseInstrumental.setClickable(waveformEnabled.checked, true);
		waveformUseSec.setClickable(waveformEnabled.checked, true);
		#end

		check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Inst", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			FlxG.sound.music.volume = vol;
		};
		check_vortex = new FlxUICheckBox(10, 160, null, null, "Show Strums\nAnd Quantization", 100);
		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.callback = function()
		{
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			strumLineNotes.visible = quant.visible = vortex;
			strumLineNotes.forEach(note -> note.active = vortex);
			reloadGridLayer();
			updateSongPos();
		};
		
		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Warnings", 100);
		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.callback = function()
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		};

		check_autosave = new FlxUICheckBox(130, 160, null, null, "Auto Save", 100);
		if (FlxG.save.data.autosave == null) FlxG.save.data.autosave = true;
		check_autosave.checked = FlxG.save.data.autosave;

		check_autosave.callback = function()
		{
			FlxG.save.data.autosave = check_autosave.checked;
			autoSave = FlxG.save.data.autosave;
			if (autoSaveTimer != null) {
				autoSaveTimer.cancel();
				autoSaveTimer = null;
				autoSaveTxt.alpha = 0;
			}
			if (autoSave) {
				autoSaveTimer = new FlxTimer().start(autoSaveLength, function(tmr:FlxTimer) {
					FlxTween.tween(autoSaveTxt, {alpha: 1}, 1, {
						ease: FlxEase.quadInOut,
						onComplete: function (twn:FlxTween) {
							FlxTween.tween(autoSaveTxt, {alpha: 0}, 1, {
								startDelay: 0.1,
								ease: FlxEase.quadInOut
							});
						}
					});
					autosaveSong();
				}, 0);
			}
		};

		var stepperAutoSave:FlxUINumericStepper = new FlxUINumericStepper(check_autosave.x + 120, check_autosave.y, 5, 10, 10, 600, 1);
		stepperAutoSave.value = autoSaveLength;
		stepperAutoSave.name = 'autosave_length';
		blockPressWhileTypingOnStepper.push(stepperAutoSave);

		var check_mute_vocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function()
		{
			if(vocals != null) {
				var vol:Float = 1;

				if (check_mute_vocals.checked)
					vol = 0;

				vocals.volume = vol;
				secondaryVocals.volume = vol;
			}
		};

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend)', 100,
			function() {
				FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent)', 100,
			function() {
				FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
			}
		);
		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome", 100,
			function() {
				FlxG.save.data.chart_metronome = metronome.checked;
			}
		);
		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.header.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);
		
		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll", 120,
			function() {
				FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
			}
		);
		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);

		sliderRate = new FlxUISlider(this, 'playbackSpeed', instVolume.x - 5, instVolume.y - 75, 0.1, 5, 300, null, 10, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Song Playback Rate';
		tab_group_chart.add(sliderRate);

		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'Metronome BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (MS):'));
		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 25, 0, 'Inst Volume\n(Editor):'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 25, 0, 'Voices Volume\n(Editor):'));
		tab_group_chart.add(new FlxText(stepperAutoSave.x, stepperAutoSave.y - 25, 0, 'Autosave Time\n(Seconds):'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);
		#if desktop
		tab_group_chart.add(waveformEnabled);
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseSec);
		#end
		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(check_autosave);
		tab_group_chart.add(stepperAutoSave);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);

		UI_box.addGroup(tab_group_chart);
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		var file:Dynamic = Paths.voices(currentSongName);
		vocals = new FlxSound();
		if (file != null && (Std.isOfType(file, Sound) || OpenFlAssets.exists(file))) {
			vocals.loadEmbedded(file);
		}
		FlxG.sound.list.add(vocals);
		file = Paths.secVoices(currentSongName);
		secondaryVocals = new FlxSound();
		if (file != null && (Std.isOfType(file, Sound) || OpenFlAssets.exists(file))) {
			secondaryVocals.loadEmbedded(file);
		}
		FlxG.sound.list.add(secondaryVocals);
		generateSong();
		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();
		FlxG.sound.music.time = Conductor.songPosition;
	}

	function generateSong() {
		FlxG.sound.playMusic(Paths.inst(currentSongName), 0.6/*, false*/);
		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function()
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;
			if(vocals != null) {
				vocals.pause();
				secondaryVocals.pause();
				vocals.time = 0;
				secondaryVocals.time = 0;
			}
			changeSection();
			curSection = 0;
			updateGrid();
			updateSectionUI();
			vocals.play();
			secondaryVocals.play();
		};
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case 'Must hit section\n(Focus on BF)':
					_song.notes[curSection].mustHitSection = check.checked;
					updateColors();
					updateHeads();
				case 'GF section':
					_song.notes[curSection].gfSection = check.checked;
					updateColors();
					updateHeads();
				case 'Change BPM':
					_song.notes[curSection].changeBPM = check.checked;
					FlxG.log.add('changed bpm shit');
				case "Alt Animation":
					_song.notes[curSection].altAnim = check.checked;
				case "Cross Fade":
					_song.notes[curSection].crossFade = check.checked;
				case "Player 4 Section\n(Focus on P4)":
					_song.notes[curSection].player4Section = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);
			if (wname == 'section_length')
			{
				_song.notes[curSection].lengthInSteps = Std.int(nums.value);
				updateGrid(false);
			}
			else if (wname == 'song_speed')
			{
				_song.options.speed = nums.value;
			}
			else if (wname == 'song_inst_volume')
			{
				_song.header.instVolume = nums.value;
			}
			else if (wname == 'song_vocals_volume')
			{
				_song.header.vocalsVolume = nums.value;
			}
			else if (wname == 'song_sec_vocals_volume')
			{
				_song.header.secVocalsVolume = nums.value;
			}
			else if (wname == 'song_bpm')
			{
				_song.header.bpm = nums.value;
				Conductor.mapBPMChanges(_song);
				Conductor.changeBPM(nums.value);
			}
			else if (wname == 'mania')
			{
				_song.options.mania = Std.int(nums.value);
				PlayState.mania = _song.options.mania;
				var gWidth = GRID_SIZE * (Note.ammo[_song.options.mania] * 2);
				camPos.x = -80 + gWidth;
				strumLine.width = gWidth;
				reloadGridLayer();
			}
			else if (wname == 'tintRed')
			{
				_song.options.tintRed = Std.int(nums.value);
			}
			else if (wname == 'tintGreen')
			{
				_song.options.tintGreen = Std.int(nums.value);
			}
			else if (wname == 'tintBlue')
			{
				_song.options.tintBlue = Std.int(nums.value);
			}
			else if (wname == 'note_susLength')
			{
				if(curSelectedNote != null && curSelectedNote[2] != null) {
					curSelectedNote[2] = nums.value;
					updateGrid(false);
				}
			}
			else if (wname == 'note_spamthing')
			{
				spamCloseness = nums.value;
			}
			else if (wname == 'note_spamamount')
			{
				spamLength = nums.value;
			}
			else if (wname == 'section_bpm')
			{
				_song.notes[curSection].bpm = nums.value;
				updateGrid();
			}
			else if (wname == 'inst_volume')
			{
				FlxG.sound.music.volume = nums.value;
			}
			else if (wname == 'voices_volume')
			{
				vocals.volume = nums.value;
				secondaryVocals.volume = nums.value;
			}
			else if (wname == 'autosave_length')
			{
				autoSaveLength = nums.value;
				FlxG.save.data.autosavelength = autoSaveLength;
				if (autoSaveTimer != null) {
					autoSaveTimer.cancel();
					autoSaveTimer = null;
					autoSaveTxt.alpha = 0;
				}
				if (autoSave) {
					autoSaveTimer = new FlxTimer().start(autoSaveLength, function(tmr:FlxTimer) {
						FlxTween.tween(autoSaveTxt, {alpha: 1}, 1, {
							ease: FlxEase.quadInOut,
							onComplete: function (twn:FlxTween) {
								FlxTween.tween(autoSaveTxt, {alpha: 0}, 1, {
									startDelay: 0.1,
									ease: FlxEase.quadInOut
								});
							}
						});
						autosaveSong();
					}, 0);
				}
			}
		}
		else if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == noteSplashesInputText) {
				_song.assets.splashSkin = noteSplashesInputText.text;
			}
			else if(sender == UI_songTitle) {
				_song.header.song = UI_songTitle.text;
			}
			else if(sender == creditsInputText) {
				_song.options.credits = creditsInputText.text;
			}
			else if(sender == remixInputText) {
				_song.options.remixCreds = remixInputText.text;
			}
			else if(curSelectedNote != null)
			{
				var keepYourselfSafe:Bool = curSelectedNote[1] != null && curSelectedNote[1][curEventSelected] != null;
				if (keepYourselfSafe && sender == value1InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
						{
							curSelectedNote[1][curEventSelected][1] = value1InputText.text;
							updateGrid(false);
						}
				}
				else if (keepYourselfSafe && sender == value2InputText) {
					if(curSelectedNote[1][curEventSelected] != null)
						{
							curSelectedNote[1][curEventSelected][2] = value2InputText.text;
							updateGrid(false);
						}
				}
				else if (sender == strumTimeInputText) {
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if(Math.isNaN(value)) value = 0;
					curSelectedNote[0] = value;
					updateGrid(false);
				}
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender)
			{
				case 'playbackSpeed':
					playbackSpeed = sliderRate.value;
			}
		}
	}

	var updatedSection:Bool = false;

	function set_playbackSpeed(speed:Float = 1) {
		playbackSpeed = speed;
		if (playbackSpeed <= 0.1)
			playbackSpeed = 0.1;
		if (playbackSpeed >= 5)
			playbackSpeed = 5;

		FlxG.sound.music.pitch = playbackSpeed;
		vocals.pitch = playbackSpeed;
		secondaryVocals.pitch = playbackSpeed;

		return playbackSpeed;
	}

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.header.bpm;
		var daPos:Float = 0;
		for (i in 0...curSection + add)
		{
			if(_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM)
				{
					daBPM = _song.notes[i].bpm;
				}
				daPos += 4 * (1000 * 60 / daBPM);
			}
		}
		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;
	var coolColor:FlxColor;
	var blockInput:Bool = false;
	var blockClick:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		blockInput = false;
		blockClick = Prompt.open; //was bothering me
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				if(FlxG.keys.justPressed.ENTER) {
					inputText.hasFocus = false;
				}
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;
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

		if (FlxG.sound.music.playing || vortex) {
			//kinda have to do this every frame
			updateSongPos();
			recalculateSteps();
			updateBpmText();
			updateSelectArrow();
		} 
		
		var playedSound:Array<Bool> = [false, false, false, false]; //Prevents ouchy GF sex sounds
		curRenderedNotes.forEachAlive(note -> {
			note.alpha = 1;
			note.color = 0xffffffff;
			if(curSelectedNote != null) {
				var noteDataToCheck:Int = note.noteData;
				if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection) noteDataToCheck += _song.options.mania+1;

				if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;
					var colorVal:Float = 0.7 + FlxMath.fastSin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if(note.strumTime <= Conductor.songPosition) {
				note.alpha = 0.4;
				if(note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1) {
					var data:Int = note.noteData % Note.ammo[_song.options.mania];
					var noteDataToCheck:Int = note.noteData;
					if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection) noteDataToCheck += Note.ammo[_song.options.mania];
						strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
						strumLineNotes.members[noteDataToCheck].resetAnim = ((note.sustainLength / 1810) + 0.12) / playbackSpeed;
					if(!playedSound[data]) {
						if((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress)){
							var soundToPlay = 'hitsound';
							
							FlxG.sound.play(Paths.sound(soundToPlay)).pan = note.noteData < Note.ammo[_song.options.mania]? -0.3 : 0.3; //would be coolio
							playedSound[data] = true;
						}
					
						data = note.noteData;
						if(note.mustPress != _song.notes[curSection].mustHitSection)
						{
							data += Note.ammo[_song.options.mania];
						}
					}
				}
			}
		});

		if (playbackSpeed != FlxG.sound.music.pitch) {
			set_playbackSpeed(playbackSpeed);
		}

		if(metronome.checked && lastConductorPos != Conductor.songPosition) {
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);
			if(metroStep != lastMetroStep) {
				FlxG.sound.play(Paths.sound('Metronome_Tick'));
			}
		}
		lastConductorPos = Conductor.songPosition;

		if (!blockInput) {
			inputPoll();
		} else if (FlxG.keys.justPressed.ENTER) {
			for (i in 0...blockPressWhileTypingOn.length) {
				if(blockPressWhileTypingOn[i].hasFocus) {
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}
	}

	function updateBpmText() {
		bpmTxt.text = 
		"Pos: " + Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + 
		"\n\n\nLength: " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
		"\n\n\nSection: " + curSection +
		"\n\n\nBeat: " + curBeat +
		"\n\n\nStep: " + curStep +
		//does not fit on screen
		//"\n\n\nQuant:" + quantOverlayData[curQuantOverlay][3] +
		"\n\n\nDifficulty: " + difficultyString +
		"\n\n\nKeys: " + Note.ammo[_song.options.mania];
	}

	function moveSection(decrease:Bool = false) {
		final shiftThing:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;
		if (decrease) {
			if(curSection <= 0) changeSection(_song.notes.length-1);
			else changeSection(curSection - shiftThing);
			updateSongPos();
			recalculateSteps();
			updateBpmText();
			return;
		}
		changeSection(curSection + shiftThing);
		updateSongPos();
		recalculateSteps();
		updateBpmText();
	}

	function updateSelectArrow() {
		selectionEvent.visible = false;
		selectionArrow.mania = _song.options.mania;
		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps) * zoomList[curZoom])
		{
			selectionArrow.visible = true;
			selectionArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			if (FlxG.keys.pressed.SHIFT) selectionArrow.y = FlxG.mouse.y;
			else selectionArrow.y = Math.floor(FlxG.mouse.y / GRID_SIZE) * GRID_SIZE;
			//trace(Math.floor(FlxG.mouse.x / GRID_SIZE) % Note.ammo[_song.options.mania]);
			selectionArrow.noteData = (Math.floor(FlxG.mouse.x / GRID_SIZE) - 1) % Note.ammo[_song.options.mania];
			if (selectionArrow.noteData < 0) {
				selectionArrow.noteData = 0;
				selectionArrow.visible = false;
				selectionEvent.visible = true;
				selectionEvent.setGraphicSize(GRID_SIZE, GRID_SIZE);
				selectionEvent.updateHitbox();
				selectionEvent.x = selectionArrow.x;
				selectionEvent.y = selectionArrow.y;
			}
			if(selectionArrow.animation.curAnim == null) selectionArrow.playAnim('static${selectionArrow.noteData}', false);
			else if(!selectionArrow.animation.curAnim.name.endsWith(Std.string(selectionArrow.noteData))) selectionArrow.playAnim('static${selectionArrow.noteData}', false);
		} else {
			selectionArrow.visible = false;
		}
	}

	function updateSongPos() {
		if(FlxG.sound.music.time < 0) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if(FlxG.sound.music.time > FlxG.sound.music.length) {
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps));
		camPos.y = strumLine.y;
		if (vortex) {
			quant.y = strumLine.y - 8;
			for (i in 0...strumLineNotes.members.length){
				strumLineNotes.members[i].y = strumLine.y;
				strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
			}
		}

		if(!disableAutoScrolling.checked) {
			if (Math.ceil(strumLine.y) >= (gridBG.height / 2))
			{
				if (_song.notes[curSection + 1] == null)
				{
					addSection();
				}

				changeSection(curSection + 1, false);
			} else if(strumLine.y < -10) {
				changeSection(curSection - 1, false);
			}
		}
	}

	function vortexSnap(up:Bool) {
		if (!vortex) return;
		var datimess = [];
		var daTime:Float = (Conductor.stepCrochet*quants[curQuant]);
		var cuquant = Std.int(32/quants[curQuant]);
		for (i in 0...cuquant){
			datimess.push(sectionStartTime() + daTime * i);
		}
		var time:Float;
		FlxG.sound.music.pause();

		if (up)
		{
			var foundaspot = false;
			var i = datimess.length-1;//backwards for loop 
			while (i > -1){
				if (Math.ceil(FlxG.sound.music.time) >= Math.ceil(datimess[i]) && !foundaspot){
					foundaspot = true;
					FlxG.sound.music.time = datimess[i];
				}
				--i;
			}
			time = FlxG.sound.music.time - daTime;
		}
		else
		{
			var foundaspot = false;
			for (i in datimess){
				if (Math.floor(FlxG.sound.music.time) <= Math.floor(i) && !foundaspot){
					foundaspot = true;
					FlxG.sound.music.time = i;
				}
			}
			time = FlxG.sound.music.time + daTime;
		}
		FlxTween.tween(FlxG.sound.music, {time: time}, 0.1, {ease:FlxEase.circOut});
		if(vocals != null) {
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}
		if(secondaryVocals != null) {
			secondaryVocals.pause();
			secondaryVocals.time = FlxG.sound.music.time;
		}
		updateSongPos();
		recalculateSteps();
		updateBpmText();
		updateSelectArrow();
	}

	function handleMouseInput(event:MouseEvent) {
		switch(event.type) {
			case MouseEvent.MOUSE_DOWN:
				if(blockClick) return;
				if (FlxG.mouse.overlaps(curRenderedNotes))
				{
					curRenderedNotes.forEachAlive(note -> {
						if (FlxG.mouse.overlaps(note)) {
							selectionArrow.resetAnim = 0.15;
							selectionArrow.playAnim('pressed${selectionArrow.noteData}', true);
							deleteNote(note);
						}
					});
				}
				else
				{
					if (FlxG.mouse.x > gridBG.x
						&& FlxG.mouse.x < gridBG.x + gridBG.width
						&& FlxG.mouse.y > gridBG.y
						&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * _song.notes[curSection].lengthInSteps) * zoomList[curZoom])
					{
						selectionArrow.resetAnim = 0.15;
						selectionArrow.playAnim('confirm${selectionArrow.noteData}', true);
						addNote();
					}
				}
			case MouseEvent.RIGHT_MOUSE_DOWN:
				if(blockClick) return;
				if (!FlxG.mouse.overlaps(curRenderedNotes)) return;
				curRenderedNotes.forEachAlive(note -> {
					if (FlxG.mouse.overlaps(note)) {
						selectNote(note);
						if (FlxG.keys.pressed.ALT)
						{
							curSelectedNote[3] = noteTypeIntMap.get(currentType);
							updateGrid(false);
						}
					}
				});
			case MouseEvent.MOUSE_MOVE:
				updateSelectArrow();
		}
	}

	override function keyPress(event:KeyboardEvent):Void
	{
		super.keyPress(event);
		var eventKey:FlxKey = event.keyCode;
		if (blockInput) return;

		switch (eventKey) {
			case ENTER:
				autosaveSong();
				FlxG.mouse.visible = false;
				PlayState.SONG = _song;
				FlxG.sound.music.stop();
				if(vocals != null) vocals.stop();
				if(secondaryVocals != null) secondaryVocals.stop();

				StageData.loadDirectory(_song);
				LoadingState.globeTrans = false;
				if (!FlxG.keys.pressed.SHIFT) {
					PlayState.startOnTime = sectionStartTime();
					PlayState.charterStart = true;
				}
				LoadingState.loadAndSwitchState(new PlayState());
			case DELETE:
				clearNotes();
			case E:
				if(curSelectedNote != null && curSelectedNote[1] > -1) changeNoteSustain(Conductor.stepCrochet);
			case Q:
				if (FlxG.keys.pressed.CONTROL)
					updateQuant();
				else
					if(curSelectedNote != null && curSelectedNote[1] > -1) changeNoteSustain(-Conductor.stepCrochet);
			case BACKSPACE | ESCAPE:
				if (FlxG.keys.pressed.CONTROL) {
					openSubState(new Prompt('This action will clear unsaved progress.\n\nProceed?', 0, function()
						{
							MusicBeatState.switchState(new editors.MasterEditorMenu());
							FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
							Conductor.changeBPM(SoundTestState.playingTrackBPM);
							FlxG.mouse.visible = false;
							return;
						}, function()
						{
							return;
						},ignoreWarnings));
				} else {
					openSubState(new Prompt('This action will clear unsaved progress.\n\nProceed?', 0, function()
						{
							MusicBeatState.switchState(new FreeplayState());
							FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
							Conductor.changeBPM(SoundTestState.playingTrackBPM);
							FlxG.mouse.visible = false;
							return;
						}, function()
						{
							return;
						},ignoreWarnings));
				}
			case Z:
				if (curZoom > 0) {
					--curZoom;
					updateZoom();
				}
			case X:
				if (FlxG.keys.pressed.CONTROL) {
					copyNotes();
					clearNotes();
				} else {
					if (curZoom < zoomList.length-1) {
						curZoom++;
						updateZoom();
					}
				}
			case SPACE:
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if(vocals != null) vocals.pause();
					if(secondaryVocals != null) secondaryVocals.pause();
				}
				else
				{
					if(vocals != null) {
						vocals.play();
						vocals.pause();
						vocals.time = FlxG.sound.music.time;
						vocals.play();
					}
					if(secondaryVocals != null) {
						secondaryVocals.play();
						secondaryVocals.pause();
						secondaryVocals.time = FlxG.sound.music.time;
						secondaryVocals.play();
					}
					FlxG.sound.music.play();
				}
			case R:
				FlxG.keys.pressed.SHIFT ? resetSection(true) : resetSection();
			case LBRACKET:
				FlxG.keys.pressed.ALT ? set_playbackSpeed(1) : set_playbackSpeed(playbackSpeed -= 0.25);
			case RBRACKET:
				FlxG.keys.pressed.ALT ? set_playbackSpeed(1) : set_playbackSpeed(playbackSpeed += 0.25);
			case RIGHT:
				if (FlxG.keys.pressed.CONTROL) {
					if (curSelectedNote != null && curSelectedNote[1] > -1 && curSelectedNote[2] != null) {
						if (curSelectedNote[1] < _song.options.mania*2 + 1) {
							curSelectedNote[1] += 1;
						} else if (curSelectedNote[1] == _song.options.mania*2 + 1) {
							curSelectedNote[1] = 0;
						}
						updateGrid();
					}
				} else {
					if (!vortex) moveSection(false);
					else {
						curQuant ++;
						if (curQuant > quants.length-1) curQuant = quants.length-1;
						daquantspot *=  Std.int(32/quants[curQuant]);
						quant.animation.play('q', true, false, curQuant);
					}
				}
			case LEFT:
				if (FlxG.keys.pressed.CONTROL) {
					if (curSelectedNote != null && curSelectedNote[1] > -1 && curSelectedNote[2] != null) {
						if (curSelectedNote[1] > 0) {
							curSelectedNote[1] -= 1;
						} else if (curSelectedNote[1] == 0) {
							curSelectedNote[1] = _song.options.mania*2 + 1;
						}
						updateGrid();
					}
				} else {
					if (!vortex) moveSection(true);
					else {
						--curQuant;
						if (curQuant < 0) curQuant = 0;	
						daquantspot *=  Std.int(32/quants[curQuant]);
						quant.animation.play('q', true, false, curQuant);
					}
				}
			case D:
				moveSection(false);
			case A:
				moveSection(true);
			case V:
				if (FlxG.keys.pressed.CONTROL) pasteNotes();
			case C:
				if (FlxG.keys.pressed.CONTROL) copyNotes();
			case S:
				if (FlxG.keys.pressed.CONTROL) {
					FlxTween.tween(autoSaveTxt, {alpha: 1}, 1, {
						ease: FlxEase.quadInOut,
						onComplete: function (twn:FlxTween) {
							FlxTween.tween(autoSaveTxt, {alpha: 0}, 1, {
								startDelay: 0.1,
								ease: FlxEase.quadInOut
							});
						}
					});
					autosaveSong();
				}
			case DOWN:
				vortexSnap(false);
			case UP:
				vortexSnap(true);
			default:
				//do NOTHING
		}
		if (!vortex) return;
		final style = (FlxG.keys.pressed.SHIFT ? 3 : currentType);
		final conductorTime = Conductor.songPosition;
		final controlArray:Array<Array<Bool>> = [
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO],
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR],
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX],
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT],
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT, FlxG.keys.justPressed.NINE, FlxG.keys.justPressed.ZERO],
			//ran out of keys lmao so just doing left half
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX],
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN],
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT],
			[FlxG.keys.justPressed.ONE, FlxG.keys.justPressed.TWO, FlxG.keys.justPressed.THREE, FlxG.keys.justPressed.FOUR, FlxG.keys.justPressed.FIVE, FlxG.keys.justPressed.SIX, FlxG.keys.justPressed.SEVEN, FlxG.keys.justPressed.EIGHT, FlxG.keys.justPressed.NINE]
		];

		if(controlArray[_song.options.mania].contains(true))
		{
			for (i in 0...controlArray[_song.options.mania].length)
			{
				if(controlArray[_song.options.mania][i])
					doANoteThing(conductorTime, i, style);
			}
		}
	}

	inline function inputPoll() {
		if (FlxG.mouse.wheel != 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet*0.8);
			if(vocals != null) {
				vocals.pause();
				vocals.time = FlxG.sound.music.time;
			}
			if(secondaryVocals != null) {
				secondaryVocals.pause();
				secondaryVocals.time = FlxG.sound.music.time;
			}
			updateSongPos();
			recalculateSteps();
			updateBpmText();
			updateSelectArrow();
		}

		//i want it to look smooth so this stays here
		if (!FlxG.keys.pressed.CONTROL && (FlxG.keys.pressed.W || FlxG.keys.pressed.S))
		{
			FlxG.sound.music.pause();

			var holdingShift:Float = 1;
			if (FlxG.keys.pressed.CONTROL) holdingShift = 0.25;
			else if (FlxG.keys.pressed.SHIFT) holdingShift = 4;

			var daTime:Float = 700 * FlxG.elapsed * holdingShift;

			if (FlxG.keys.pressed.W)
			{
				FlxG.sound.music.time -= daTime;
			}
			else
				FlxG.sound.music.time += daTime;

			if(vocals != null) {
				vocals.pause();
				vocals.time = FlxG.sound.music.time;
			}
			updateSongPos();
			recalculateSteps();
			updateBpmText();
			updateSelectArrow();
		}
	}

	function updateZoom() {
		if (curZoom == 0) {
			zoomTxt.text = 'Zoom: ' + zoomList[curZoom] + 'x (Min)';
		} else if (curZoom == #if !html5 11 #else 5 #end) {
			zoomTxt.text = 'Zoom: ' + zoomList[curZoom] + 'x (Max)';
		} else {
			zoomTxt.text = 'Zoom: ' + zoomList[curZoom] + 'x';
		}
		reloadGridLayer();
	}

	function updateQuant() {
		curQuantOverlay++;
		if (curQuantOverlay >= quantOverlayData.length) curQuantOverlay = 0;
		//updateBpmText();
		reloadGridLayer();
	}

	function loadAudioBuffer() {
		if(audioBuffers[0] != null) {
			audioBuffers[0].dispose();
		}
		audioBuffers[0] = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders('songs/' + currentSongName + '/Inst.ogg'))) {
			audioBuffers[0] = AudioBuffer.fromFile(Paths.modFolders('songs/' + currentSongName + '/Inst.ogg'));
		}
		else { #end
			var leVocals:String = Paths.getPath(currentSongName + '/Inst.' + Paths.SOUND_EXT, SOUND, 'songs');
			if (OpenFlAssets.exists(leVocals)) { //Vanilla inst
				audioBuffers[0] = AudioBuffer.fromFile('./' + leVocals.substr(6));
			}
		#if MODS_ALLOWED
		}
		#end

		if(audioBuffers[1] != null) {
			audioBuffers[1].dispose();
		}
		audioBuffers[1] = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders('songs/' + currentSongName + '/Voices.ogg'))) {
			audioBuffers[1] = AudioBuffer.fromFile(Paths.modFolders('songs/' + currentSongName + '/Voices.ogg'));
		} else { #end
		var leVocals:String = Paths.getPath(currentSongName + '/Voices.' + Paths.SOUND_EXT, SOUND, 'songs');
		if (OpenFlAssets.exists(leVocals)) { //Vanilla voices
			audioBuffers[1] = AudioBuffer.fromFile('./' + leVocals.substr(6));
		}
		#if MODS_ALLOWED
		}
		#end

		if(audioBuffers[2] != null) {
			audioBuffers[2].dispose();
		}
		audioBuffers[2] = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders('songs/' + currentSongName + '/SecVoices.ogg'))) {
			audioBuffers[2] = AudioBuffer.fromFile(Paths.modFolders('songs/' + currentSongName + '/SecVoices.ogg'));
		} else { #end
		var leVocals:String = Paths.getPath(currentSongName + '/SecVoices.' + Paths.SOUND_EXT, SOUND, 'songs');
		if (OpenFlAssets.exists(leVocals)) { //Vanilla voices
			audioBuffers[2] = AudioBuffer.fromFile('./' + leVocals.substr(6));
		}
		#if MODS_ALLOWED
		}
		#end
	}

	var curQuantOverlay:Int = 2;
	final quantOverlayData:Array<Array<Dynamic>> = [
		//0 is for the modulo by
		//1 is for the greater than
		//2 is for the color
		//3 is for the quant text display
		[16, 8, 0x33FF00CB, 2], //half notes (2)
		[12, 6, 0x33AE00FF, 3], //dotted half notes (3)
		[8, 4, 0x332600FF, 4], //quarter notes (4)
		[6, 3, 0x33003CFF, 6], //dotted quarter notes (6)
		[4, 2, 0x3300FFEA, 8], //eighth notes (8)
		[3, 1.5, 0x3300FF88, 12], //dotted eighth notes (12)
		[2, 1, 0x331BFF00, 16], //sixteenth notes (16)
		[1.5, 0.75, 0x339DFF00, 24], //dotted sixteenth notes (24)
		[1, 0.5, 0x33FFFA00, 32], //thirty-second notes (32)
		[0.75, 0.375, 0x33FF7400, 48], //dotted thirty-second notes (48)
		[0.5, 0.25, 0x33FF0000, 64] //sixty-fourth notes (64)
	];

	function reloadGridLayer() { //sex
		PlayState.mania = _song.options.mania;

		if (selectionArrow != null){
			selectionArrow.setGraphicSize(GRID_SIZE, GRID_SIZE);
			selectionArrow.updateHitbox();
			selectionArrow.mania = _song.options.mania;
			selectionArrow.reloadNote();
			selectionArrow.size = GRID_SIZE;
		}

		gridLayer.forEach(obj -> {
			gridLayer.remove(obj);
			obj.destroy();
		});
		gridLayer.clear();
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE + GRID_SIZE * Note.ammo[_song.options.mania] * 2, Std.int(GRID_SIZE * 32 * zoomList[curZoom]));
		gridBG.active = false;
		gridLayer.add(gridBG);

		#if desktop
		if(waveformEnabled != null)
			updateWaveform();
		#end

		final GRID_WIDTH = 1 + (1 * Note.ammo[_song.options.mania] * 2);
		
		gridQuantOverlay = new FlxSprite().makeGraphic(GRID_WIDTH, Std.int(32 * zoomList[curZoom]), 0x00FFFFFF, true);
		final curQuantData = quantOverlayData[curQuantOverlay];
		for (y in 0...gridQuantOverlay.pixels.height) {
			//i fixed the formula for this you better be grateful
			if ((y / zoomList[curZoom]) % curQuantData[0] < curQuantData[1]) continue;
			for (x in 0...gridQuantOverlay.pixels.width) {
				gridQuantOverlay.pixels.setPixel32(x, y, curQuantData[2]);
			}
		}
		gridQuantOverlay.scale.set(GRID_SIZE, GRID_SIZE);
		gridQuantOverlay.updateHitbox();
		gridQuantOverlay.active = false;
		gridQuantOverlay.antialiasing = false;
		gridLayer.add(gridQuantOverlay);

		var gridBlack:FlxSprite = new FlxSprite(0, gridBG.height / 2).makeGraphic(Std.int(GRID_SIZE + GRID_SIZE * Note.ammo[_song.options.mania] * 2), Std.int(gridBG.height / 2), FlxColor.BLACK);
		gridBlack.alpha = 0.4;
		gridBlack.antialiasing = false;
		gridBlack.active = false;
		gridLayer.add(gridBlack);

		var gridBlackLine:FlxSprite = new FlxSprite(gridBG.x + gridBG.width - (GRID_SIZE * Note.ammo[_song.options.mania])).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK);
		gridBlackLine.antialiasing = false;
		gridBlackLine.active = false;
		gridLayer.add(gridBlackLine);

		for (i in 1...4){
			var beatsep1:FlxSprite = new FlxSprite(gridBG.x,(GRID_SIZE * (4*curZoom))*i).makeGraphic(Std.int(gridBG.width), 1, 0x44FF0000);
			beatsep1.antialiasing = false;
			beatsep1.active = false;
			if(vortex) gridLayer.add(beatsep1);
		}

		var gridBlackLineEvent:FlxSprite = new FlxSprite(gridBG.x + GRID_SIZE).makeGraphic(2, Std.int(gridBG.height), FlxColor.BLACK); //changed for funny calc
		gridBlackLineEvent.antialiasing = false;
		gridBlackLineEvent.active = false;
		gridLayer.add(gridBlackLineEvent);

		remove(strumLine, true);
		strumLine = new FlxSprite(0, 50).makeGraphic(Std.int(GRID_SIZE + GRID_SIZE * Note.ammo[_song.options.mania] * 2), 4);
		strumLine.antialiasing = false;
		strumLine.active = false;
		add(strumLine);

		if (strumLineNotes != null)
		{
			strumLineNotes.forEach(note -> {
				strumLineNotes.remove(note);
				note.destroy();
			});
			strumLineNotes.clear();
			for (i in 0...(Note.ammo[_song.options.mania] * 2)){
				var note:Note.StrumNote = new Note.StrumNote(GRID_SIZE * (i+1), strumLine.y, i % Note.ammo[_song.options.mania], 0);
				note.setGraphicSize(GRID_SIZE, GRID_SIZE);
				note.updateHitbox();
				note.playAnim('static', true);
				strumLineNotes.add(note);
				note.scrollFactor.set(1, 1);
				note.active = vortex;
			}
		}

		updateGrid();

		chartSectionWidth = FlxMath.absInt(FlxMath.distanceBetween(gridBlackLine, gridBlackLineEvent));
		updateHeads();
	}

	var waveformPrinted:Bool = true;
	var audioBuffers:Array<AudioBuffer> = [null, null, null];
	#if desktop
	function updateWaveform() {
		if(waveformPrinted) {
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * (Note.ammo[_song.options.mania] * 2)), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}
		waveformPrinted = false;

		var checkForVoices:Int = 1;
		if(waveformUseInstrumental.checked) checkForVoices = 0;
		if(waveformUseSec.checked) checkForVoices = 2;

		if(!waveformEnabled.checked || audioBuffers[checkForVoices] == null) return;

		var sampleMult:Float = audioBuffers[checkForVoices].sampleRate / 44100;
		var index:Int = Std.int(sectionStartTime() * 44.0875 * sampleMult);
		var drawIndex:Int = 0;

		var steps:Int = _song.notes[curSection].lengthInSteps;
		if(Math.isNaN(steps) || steps < 1) steps = 16;
		var samplesPerRow:Int = Std.int(((Conductor.stepCrochet * steps * 1.1 * sampleMult) / 16) / zoomList[curZoom]);
		if(samplesPerRow < 1) samplesPerRow = 1;
		final waveBytes:Bytes = audioBuffers[checkForVoices].data.toBytes();
		
		var min:Float = 0;
		var max:Float = 0;
		while (index < (waveBytes.length - 1))
		{
			var byte:Int = waveBytes.getUInt16(index * 4);

			if (byte > 65535 / 2)
				byte -= 65535;

			final sample:Float = (byte / 65535);

			if (sample > 0)
			{
				if (sample > max)
					max = sample;
			}
			else if (sample < 0)
			{
				if (sample < min)
					min = sample;
			}

			if ((index % samplesPerRow) == 0)
			{
				final pixelsMin:Float = Math.abs(min * (GRID_SIZE * (Note.ammo[_song.options.mania] * 2)));
				final pixelsMax:Float = max * (GRID_SIZE * (Note.ammo[_song.options.mania] * 2));
				waveformSprite.pixels.fillRect(new Rectangle(Std.int((GRID_SIZE * Note.ammo[_song.options.mania]) - pixelsMin), drawIndex, pixelsMin + pixelsMax, 1), 0x85000000);
				drawIndex++;

				min = 0;
				max = 0;

				if(drawIndex > gridBG.height) break;
			}

			index++;
		}
		waveformPrinted = true;
	}
	#end

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote == null || curSelectedNote[2] == null) return;

		curSelectedNote[2] += value;
		curSelectedNote[2] = Math.max(curSelectedNote[2], 0);

		updateNoteUI();
		//make this not update grid
		updateGrid(false);
	}

	function recalculateSteps(add:Float = 0):Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime + add) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		FlxG.sound.music.pause();
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSection = 0;
		}

		if(vocals != null) {
			vocals.pause();
			secondaryVocals.pause();
			vocals.time = FlxG.sound.music.time;
			secondaryVocals.time = FlxG.sound.music.time;
		}
		updateSongPos();
		recalculateSteps();
		updateBpmText();
		updateGrid();
		updateSectionUI();
		#if desktop
		updateWaveform();
		#end
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSection = sec;

			if (updateMusic)
			{
				FlxG.sound.music.pause();

				FlxG.sound.music.time = sectionStartTime();
				if(vocals != null) {
					vocals.pause();
					secondaryVocals.pause();
					vocals.time = FlxG.sound.music.time;
					secondaryVocals.time = FlxG.sound.music.time;
				}
			}

			updateGrid();
			updateSectionUI();
		}
		else
		{
			changeSection();
		}
		Conductor.songPosition = FlxG.sound.music.time;
		updateSongPos();
		recalculateSteps();
		updateBpmText();
		#if desktop
		updateWaveform();
		#end
	}

	function updateSectionUI():Void
	{
		var sec = _song.notes[curSection];

		stepperLength.value = sec.lengthInSteps;
		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_crossFade.checked = sec.crossFade;
		check_player4Section.checked = sec.player4Section;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	var chartSectionWidth:Float = 0;
	function updateHeads():Void
	{
		var healthIconP1:String = loadHealthIconFromCharacter(_song.assets.player1);
		var healthIconP2:String = loadHealthIconFromCharacter(_song.assets.player2);

		if (_song.notes[curSection].mustHitSection)
		{
			Paths.setModsDirectoryFromType(ICON, healthIconP1, false);
			leftIcon.changeIcon(healthIconP1);
			Paths.setModsDirectoryFromType(NONE, '', true);
			Paths.setModsDirectoryFromType(ICON, healthIconP2, false);
			rightIcon.changeIcon(healthIconP2);
			Paths.setModsDirectoryFromType(NONE, '', true);
			if (_song.notes[curSection].gfSection) leftIcon.changeIcon('gf');
		}
		else
		{
			Paths.setModsDirectoryFromType(ICON, healthIconP2, false);
			leftIcon.changeIcon(healthIconP2);
			Paths.setModsDirectoryFromType(NONE, '', true);
			Paths.setModsDirectoryFromType(ICON, healthIconP1, false);
			rightIcon.changeIcon(healthIconP1);
			Paths.setModsDirectoryFromType(NONE, '', true);
			if (_song.notes[curSection].gfSection) leftIcon.changeIcon('gf');
		}
		if (!ClientPrefs.settings.get("lowQuality")) {
			coolColor = FlxColor.fromInt(CoolUtil.dominantColor(leftIcon));
			coolColor = FlxColor.subtract(coolColor, 0x00242424);
			updateColors();
		}

		leftIcon.x = eventIcon.x + (chartSectionWidth / 2) + 10;
		rightIcon.x = eventIcon.x + ((chartSectionWidth * 3) / 2) + 10;
	}

	function updateColors() {
		var newColor:Int = coolColor;
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
			colorTween = FlxTween.color(bg, Conductor.crochet / 500 / playbackSpeed, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
			bgScrollColorTween = FlxTween.color(bgScroll, Conductor.crochet / 500 / playbackSpeed, bgScroll.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					bgScrollColorTween = null;
				}
			});
			bgScroll2ColorTween = FlxTween.color(bgScroll2, Conductor.crochet / 500 / playbackSpeed, bgScroll2.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					bgScroll2ColorTween = null;
				}
			});
			gradientColorTween = FlxTween.color(gradient, Conductor.crochet / 500 / playbackSpeed, gradient.color, intendedColor, {
					onComplete: function(twn:FlxTween) {
					gradientColorTween = null;
				}
			});
		}
	}

	function loadHealthIconFromCharacter(char:String) {
		var characterPath:String = 'data/characters/' + char + '.json';
		#if MODS_ALLOWED
		Paths.setModsDirectoryFromType(CHARACTER, char, false);
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getPreloadPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getPreloadPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			path = Paths.getPreloadPath('data/characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end

		var json:Character.CharacterFile = cast Json.parse(rawJson);
		#if MODS_ALLOWED
		Paths.setModsDirectoryFromType(NONE, '', true);
		#end
		if (json.healthicon != null) return json.healthicon;
		return json.icon_props.name;
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null) {
			if(curSelectedNote[2] != null) {
				stepperSusLength.value = curSelectedNote[2];
				if(curSelectedNote[3] != null) {
					currentType = noteTypeMap.get(curSelectedNote[3]);
					if(currentType <= 0) {
						noteTypeDropDown.selectedLabel = '';
					} else {
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			} else {
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];
				var selected:Int = Std.parseInt(eventDropDown.selectedId);
				if(selected > 0 && selected < eventStuff.length) {
					descText.text = eventStuff[selected][1];
				}
				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}
			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function updateGrid(?updateNext:Bool = true):Void
	{
		renderedSustainsMap.clear();
		curRenderedNotes.forEach(note -> {
			curRenderedNotes.remove(note, true);
			note.destroy();
		});
		curRenderedNotes.clear();
		curRenderedSustains.forEach(sus -> {
			curRenderedSustains.remove(sus, true);
			sus.destroy();
		});
		curRenderedSustains.clear();
		curRenderedNoteType.forEach(txt -> {
			curRenderedNoteType.remove(txt, true);
			txt.destroy();
		});
		curRenderedNoteType.clear();
		if (updateNext) {
			nextRenderedNotes.forEach(note -> {
				nextRenderedNotes.remove(note, true);
				note.destroy();
			});
			nextRenderedNotes.clear();
			nextRenderedSustains.forEach(sus -> {
				nextRenderedSustains.remove(sus, true);
				sus.destroy();
			});
			nextRenderedSustains.clear();
		}

		if (_song.notes[curSection].changeBPM && _song.notes[curSection].bpm > 0)
		{
			Conductor.changeBPM(_song.notes[curSection].bpm);
		}
		else
		{
			// get last bpm
			var daBPM:Float = _song.header.bpm;
			for (i in 0...curSection)
				if (_song.notes[i].changeBPM)
					daBPM = _song.notes[i].bpm;
			Conductor.changeBPM(daBPM);
		}

		// CURRENT SECTION
		for (i in _song.notes[curSection].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);
			if (note.sustainLength > 0)
			{
				renderedSustainsMap.set(note, curRenderedSustains.add(setupSusNote(note)));
			}

			if(note.y < -150) note.y = -150;

			if(i[3] != null && note.noteType != null && note.noteType.length > 0) {
				var typeInt:Null<Int> = noteTypeMap.get(i[3]);
				var theType:String = '' + typeInt;
				if(typeInt == null) theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
			note.mustPress = _song.notes[curSection].mustHitSection;
			if(i[1] > Note.ammo[_song.options.mania] - 1) note.mustPress = !note.mustPress;
		}

		// CURRENT EVENTS
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (i in _song.events)
		{
			if(endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);
				
				if(note.y < -150) note.y = -150;

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if(note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
		}

		if (updateNext) {
			// NEXT SECTION
			if(curSection < _song.notes.length-1) {
				for (i in _song.notes[curSection+1].sectionNotes)
				{
					var note:Note = setupNoteData(i, true);
					note.alpha = 0.6;
					nextRenderedNotes.add(note);
					if (note.sustainLength > 0)
					{
						nextRenderedSustains.add(setupSusNote(note));
					}
				}
			}

			// NEXT EVENTS
			var startThing:Float = sectionStartTime(1);
			var endThing:Float = sectionStartTime(2);
			for (i in _song.events)
			{
				if(endThing > i[0] && i[0] >= startThing)
				{
					var note:Note = setupNoteData(i, true);
					note.alpha = 0.6;
					nextRenderedNotes.add(note);
				}
			}
		}

		if (!ClientPrefs.settings.get("lowQuality")) {
			updateColors();
		}
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence('Chart Editor - ${StringTools.replace(_song.header.song, '-', ' ')} ($difficultyString)', '${Song.getNoteCount(_song)} Notes');
		#end
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo = i[1];
		var daStrumTime = i[0];
		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % Note.ammo[_song.options.mania], null, null, true);
		note.active = false;
		if(daSus != null) { //Common note
			if(!Std.isOfType(i[3], String)) //Convert old note type to new note type format
			{
				i[3] = noteTypeIntMap.get(i[3]);
			}
			if(i.length > 3 && (i[3] == null || i[3].length < 1))
			{
				i.remove(i[3]);
			}
			note.sustainLength = daSus;
			note.noteType = i[3];
		} else { //Event note
			note.loadGraphic(Paths.image('eventArrow'));
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;
			if(i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}
			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;
		if(isNextSection && _song.notes[curSection].mustHitSection != _song.notes[curSection+1].mustHitSection) {
			if(daNoteInfo > Note.ammo[_song.options.mania] - 1) {
				note.x -= GRID_SIZE * Note.ammo[_song.options.mania];
			} else if(daSus != null) {
				note.x += GRID_SIZE * Note.ammo[_song.options.mania];
			}
		}

		note.y = (GRID_SIZE * (isNextSection ? 16 : 0)) * zoomList[curZoom] + Math.floor(getYfromStrum((daStrumTime - sectionStartTime(isNextSection ? 1 : 0)) % (Conductor.stepCrochet * _song.notes[curSection].lengthInSteps), false));
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;
		if (names == null) { //?????????
			return retStr;
		}
		for (i in 0...names.length)
		{
			if(addedOne) retStr += ', ';
			retStr += names[i][0];
			addedOne = true;
		}
		return retStr;
	}

	function setupSusNote(note:Note):FlxSprite {
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, (gridBG.height / gridMult)) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);
		if(height < minHeight) height = minHeight;
		if(height < 1) height = 1; //Prevents error of invalid height

		var spr:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2).makeGraphic(8, height);
		spr.color = Std.parseInt(noteColors.get(_song.options.mania + (PlayState.isPixelStage ? 10 : 0))[note.noteData % Note.ammo[_song.options.mania]]);
		spr.alpha = 0.6;
		spr.antialiasing = false;
		spr.active = false;
		return spr;
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: _song.header.bpm,
			changeBPM: false,
			mustHitSection: true,
			player4Section: false,
			gfSection: false,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			crossFade: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;

		if(noteDataToCheck > -1)
		{
			if(note.mustPress != _song.notes[curSection].mustHitSection) noteDataToCheck += Note.ammo[_song.options.mania];
			for (i in _song.notes[curSection].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in _song.events)
			{
				if(i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;
					break;
				}
			}
		}
		changeEventSelected();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if(noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection) noteDataToCheck += Note.ammo[_song.options.mania];

		if(note.noteData > -1) //Normal Notes
		{
			for (i in _song.notes[curSection].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if(i == curSelectedNote) curSelectedNote = null;
					//FlxG.log.add('FOUND EVIL NOTE');
					_song.notes[curSection].sectionNotes.remove(i);
					break;
				}
			}
		}
		else //Events
		{
			for (i in _song.events)
			{
				if(i[0] == note.strumTime)
				{
					if(i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}
					//FlxG.log.add('FOUND EVIL EVENT');
					_song.events.remove(i);
					break;
				}
			}
		}

		curRenderedNoteType.forEach(txt -> {
			if (txt.sprTracker == note) {
				curRenderedNoteType.remove(txt, true);
				txt.destroy();
			}
		});
		curRenderedNotes.remove(note, true);
		if (renderedSustainsMap.exists(note)) {
			var sus = renderedSustainsMap.get(note);
			curRenderedSustains.remove(sus, true);
			sus.destroy();
		}
		note.destroy();
	}

	public function doANoteThing(cs, d, style){
		var delnote = false;
		if(strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note)
			{
				if (note.overlapsPoint(FlxPoint.weak(strumLineNotes.members[d].x + 1,strumLine.y+1)) && note.noteData == d%Note.ammo[_song.options.mania])
				{
					if(!delnote) deleteNote(note);
					delnote = true;
				}
			});
		}
		
		if (!delnote){
			addNote(cs, d, style);
		}
	}
	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null, ?gridUpdate:Bool = true):Void
	{
		var noteStrum = getStrumTime(selectionArrow.y, false) + sectionStartTime();
		var noteData = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		//noteData -= 1;
		var noteSus = 0;
		var daType = currentType;

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;
		
		if(noteData > -1) {
			_song.notes[curSection].sectionNotes.push([noteStrum, noteData, noteSus, noteTypeIntMap.get(daType)]);
			curSelectedNote = _song.notes[curSection].sectionNotes[_song.notes[curSection].sectionNotes.length - 1];
		} else {
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
			_song.events.push([noteStrum, [[event, text1, text2]]]);
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}
		changeEventSelected();

		if (FlxG.keys.pressed.CONTROL && noteData > -1)
		{
			_song.notes[curSection].sectionNotes.push([noteStrum, (noteData + Note.ammo[_song.options.mania]) % (Note.ammo[_song.options.mania] * 2), noteSus, noteTypeIntMap.get(daType)]);
		}

		//wow its not laggy who wouldve guessed
		if (gridUpdate) {
			switch (noteData) {
				case -1:	
					var note:Note = setupNoteData(curSelectedNote, false);
					curRenderedNotes.add(note);
						
					if(note.y < -150) note.y = -150;
		
					var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
					if(note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;
		
					var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
					daText.setFormat(Paths.font("vcr.ttf"), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
					daText.xAdd = -410;
					daText.borderSize = 1;
					if(note.eventLength > 1) daText.yAdd += 8;
					curRenderedNoteType.add(daText);
					daText.sprTracker = note;
				default:
					var note:Note = setupNoteData(curSelectedNote, false);
					curRenderedNotes.add(note);
					if (note.sustainLength > 0)
					{
						renderedSustainsMap.set(note, curRenderedSustains.add(setupSusNote(note)));
					}
			
					if(note.y < -150) note.y = -150;
			
					if(curSelectedNote[3] != null && note.noteType != null && note.noteType.length > 0) {
						var typeInt:Null<Int> = noteTypeMap.get(curSelectedNote[3]);
						var theType:String = '' + typeInt;
						if(typeInt == null) theType = '?';
			
						var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
						daText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						daText.xAdd = -32;
						daText.yAdd = 6;
						daText.borderSize = 1;
						curRenderedNoteType.add(daText);
						daText.sprTracker = note;
					}
					note.mustPress = _song.notes[curSection].mustHitSection;
					if(curSelectedNote[1] > Note.ammo[_song.options.mania] - 1) note.mustPress = !note.mustPress;
			}
		}

		//trace(noteData + ', ' + noteStrum + ', ' + curSection);
		strumTimeInputText.text = '' + curSelectedNote[0];

		if (gridUpdate) {
			updateNoteUI();
		}
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + (gridBG.height / gridMult) * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = zoomList[curZoom];
		if(!doZoomCalc) leZoom = 1;
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + (gridBG.height / gridMult) * leZoom);
	}

	function copyNotes() {
		notesCopied = [];
		sectionToCopy = curSection;
		for (i in 0..._song.notes[curSection].sectionNotes.length)
		{
			var note:Array<Dynamic> = _song.notes[curSection].sectionNotes[i];
			notesCopied.push(note);
		}
	
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		for (event in _song.events)
		{
			var strumTime:Float = event[0];
			if(endThing > event[0] && event[0] >= startThing)
			{
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...event[1].length)
				{
					var eventToPush:Array<Dynamic> = event[1][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				notesCopied.push([strumTime, -1, copiedEventArray]);
			}
		}
	}

	function clearNotes() {
		_song.notes[curSection].sectionNotes = [];
			
		var i:Int = _song.events.length - 1;
		
		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);
		while(i > -1) {
			var event:Array<Dynamic> = _song.events[i];
			if(event != null && endThing > event[0] && event[0] >= startThing)
			{
				_song.events.remove(event);
			}
			--i;
		}
		updateGrid(false);
		updateNoteUI();
	}

	function pasteNotes() {
		if(notesCopied == null || notesCopied.length < 1)
		{
			return;
		}

		var addToTime:Float = Conductor.stepCrochet * (_song.notes[curSection].lengthInSteps * (curSection - sectionToCopy));

		for (note in notesCopied)
		{
			var copiedNote:Array<Dynamic> = [];
			var newStrumTime:Float = note[0] + addToTime;
			if(note[1] < 0)
			{
				var copiedEventArray:Array<Dynamic> = [];
				for (i in 0...note[2].length)
				{
					var eventToPush:Array<Dynamic> = note[2][i];
					copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
				}
				_song.events.push([newStrumTime, copiedEventArray]);
			}
			else
			{
				if(note[4] != null) {
					copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
				} else {
					copiedNote = [newStrumTime, note[1], note[2], note[3]];
				}	
				_song.notes[curSection].sectionNotes.push(copiedNote);
			}
		}
		updateGrid(false);
	}

	function loadJson(song:String):Void
	{
		var songLowercase:String = _song.header.song;
		var poop:String = Highscore.formatSong(songLowercase, PlayState.storyDifficulty);
		function theMostFittingNameEverConcieved() {
			if (CoolUtil.difficulties[PlayState.storyDifficulty] != "Normal"){
				if(CoolUtil.difficulties[PlayState.storyDifficulty] == null){
					PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
				} else {
					PlayState.SONG = Song.loadFromJson(song.toLowerCase()+"-"+CoolUtil.difficulties[PlayState.storyDifficulty], song.toLowerCase());
				}
			} else {
				PlayState.SONG = Song.loadFromJson(song.toLowerCase(), song.toLowerCase());
			}
			dropDownDiffs = CoolUtil.difficulties;
			Paths.clearUnusedCache();
			MusicBeatState.resetState();
		}
		function invalidJson() {
			trace(poop + '.json does not exist!');
			FlxG.sound.play(Paths.sound('invalidJSON'));
			FlxG.camera.shake(0.05, 0.05);
			var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!\n" + poop + ".json");
			funnyText.scrollFactor.set();
			funnyText.screenCenter();
			funnyText.x = 5;
			funnyText.y = FlxG.height/2 - 64;
			funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(funnyText);
			FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
				onComplete: _ -> {
					remove(funnyText, true);
					funnyText.destroy();
				}
			});
		}
		#if desktop
		if(sys.FileSystem.exists(Paths.modsJson('charts/' + songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.json('charts/' + songLowercase + '/' + poop)))
			theMostFittingNameEverConcieved();
		else
			invalidJson();
		#else
		if(OpenFlAssets.exists(Paths.json('charts/' + songLowercase + '/' + poop)))
			theMostFittingNameEverConcieved();
		else
			invalidJson();
		#end
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosavejson = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
		Paths.clearUnusedCache();
	}

	function clearEvents() {
		_song.events = [];
		updateGrid();
	}

	private function saveLevel()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), convPathShit(getCurrentDataPath()));
		}
	}

	function getCurrentDataPath():String {
		var diffSuffix:String = 
			CoolUtil.difficulties[PlayState.storyDifficulty] != null && 
			CoolUtil.difficulties[PlayState.storyDifficulty] != CoolUtil.defaultDifficulty
			? "-" + CoolUtil.difficulties[PlayState.storyDifficulty].toLowerCase() 
			: "";
			
		var path:String;
		#if MODS_ALLOWED
		path = Paths.modsJson('charts/' + currentSongName + "/" + currentSongName + diffSuffix);
		if (!FileSystem.exists(path))
		#end
			path = Paths.json('charts/' + currentSongName + "/" + currentSongName + diffSuffix);

		return path;
	}
	
	inline function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

	private function saveEvents()
	{
		if(_song.events != null && _song.events.length > 1) _song.events.sort(sortByTime);
		var eventsSong:SwagSong = {
			header: null,
			assets: null,
			options: null,
			notes: [],
			events: _song.events
		};
		var json = {
			"song": eventsSong
		}

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), convPathShit(Path.directory(getCurrentDataPath()) + "/events.json"));
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
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
		FlxG.log.error("Problem saving Level data");
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}

class SelectionArrow extends FlxSprite
{
	public var colorSwap:Shaders.ColorSwap;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var mania:Int = 3;
	public var size:Int = 40;
	public var texture(default, set):String = null;
	inline private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int) {
		colorSwap = new Shaders.ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		super(x, y);

		scrollFactor.set(1, 1);
		moves = false;
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/$texture'), true, 17, 17);
			var daFrames:Array<Int> = Note.keysShit.get(PlayState.mania).get('pixelAnimIndex');

			setGraphicSize(size, size);
			updateHitbox();
			antialiasing = false;
			for (i in 0...daFrames.length) {
				animation.add('static$i', [daFrames[i]]);
				animation.add('pressed$i', [daFrames[i] + 9, daFrames[i] + 18], 12, false);
				animation.add('confirm$i', [daFrames[i] + 27, daFrames[i] + 36], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);

			setGraphicSize(size, size);
			antialiasing = ClientPrefs.settings.get("globalAntialiasing");
		
			for (i in 0...mania+1) {
				animation.addByPrefix('static$i', 'arrow' + Note.keysShit.get(PlayState.mania).get('strumAnims')[i]);
				animation.addByPrefix('pressed$i', Note.keysShit.get(PlayState.mania).get('letters')[i] + ' press', 24, false);
				animation.addByPrefix('confirm$i', Note.keysShit.get(PlayState.mania).get('letters')[i] + ' confirm', 24, false);
			}
		}

		updateHitbox();

		if(lastAnim != null) playAnim(lastAnim, true);
		animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
			if (name != 'confirm$noteData') return;
			centerOrigin();
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (resetAnim <= 0) return;

		resetAnim -= elapsed;
		if(resetAnim <= 0) {
			playAnim('static$noteData');
			resetAnim = 0;
		}
	}

	override function destroy() {
		shader = null;
		colorSwap = null;
		super.destroy();
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();

		if(animation.curAnim == null || animation.curAnim.name == 'static$noteData') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			colorSwap.hue = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][2] / 100;

			if (PlayState.isPixelStage) return;
			if(animation.curAnim.name == 'confirm$noteData')
				centerOrigin();
		}
	}
}