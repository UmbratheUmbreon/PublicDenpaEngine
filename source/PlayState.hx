package;

import animateatlas.AtlasFrameMaker;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import Shaders.PulseEffect;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxRandom;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
#if sys
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	//instance
	public static var instance:PlayState;

	//Strum positions??
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['How?', 0.2], //From 0% to 19%
		['F', 0.4], //From 20% to 39%
		['E', 0.5], //From 40% to 49%
		['D', 0.6], //From 50% to 59%
		['C', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['B', 0.8], //From 70% to 79%
		['A', 0.9], //From 80% to 89%
		['S', 1], //From 90% to 99%
		['X', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	//lua shits
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	//shader thing
	public static var screenshader:Shaders.PulseEffect = new PulseEffect();
	//for modcharts
	public var elapsedtime:Float = 0;
	public static var curModChart:String = '';
	//crossfade groups
	public var grpCrossFade:FlxTypedGroup<CrossFade>;
	public var grpP4CrossFade:FlxTypedGroup<CrossFade>;
	public var grpBFCrossFade:FlxTypedGroup<BFCrossFade>;
	public var grpIdiotFade:FlxTypedGroup<CrossFade>;
	//overrides
	//public static var formoverride:String = "none";
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var player4Map:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var player4Map:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	//stage positions
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var P4_X:Float = -300;
	public var P4_Y:Float = -1200;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	//stuff for gameplay settings (i think)
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	//character groups
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var player4Group:FlxSpriteGroup;
	public var dadMirrorGroup:FlxSpriteGroup;
	public var idiotGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	//stage shit
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;

	//data for the song and mode
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	private var curSong:String = "";
	var songPercent:Float = 0;
	public var spawnTime:Float = 2000;

	//vocals
	public var vocals:FlxSound;
	public var secondaryVocals:FlxSound;

	//characters
	public var dad:Character = null;
	public var dadmirror:Character = null;
	public var player4:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;
	public var littleIdiot:Character = null;

	//note shits
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	//strum lines
	private var strumLine:FlxSprite;
	private var altStrumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	public static var prevCamFollow:FlxPoint;
	public static var prevCamFollowPos:FlxObject;

	//strum lines but actually
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var thirdStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	//cameera shit
	public var camZooming:Bool = false;
	public var shakeCam:Bool = false;

	//icon swinging
	public var curIconSwing:String = ClientPrefs.iconSwing;
	public var swingDirection:Bool = true;

	//values for shit like health and combo
	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var lastHealth:Float = 1;
	public var maxHealth:Float = 2;
	public var combo:Int = 0;
	public var highestCombo:Int = 0;

	//healthbar shit
	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	public var healthBarMiddle:FlxBar;
	public var healthBarMiddleHalf:FlxBar;
	public var healthBarBottom:FlxBar;

	//timebar shit
	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	//this is for hard coded glitch shaders
	//also, ONLY 1 curbg CAN BE ACTIVE!!!
	public var curbg:FlxSprite;
	//and THIS is for lua glitch shaders
	public var luabg:ModchartSprite;

	//rating shit
	public var perfects:Int = 0;	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var wtfs:Int = 0;

	//MANIA THAT IS VERY EPIC
	public static var mania:Int = 0;

	//stuff for song again
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	//local storage of ghost tapping
	public var tappy:Bool = false;

	//botplay text shit
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	//icons
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconP4:HealthIcon;
	public var flinching:Bool = false;
	public var flinchTimer:FlxTimer = null;

	//cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	//timers
	public var discordUpdateTime:Float = 5;
	public var quartizTime:Float = 5;

	//dialogue
	public var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	public var dialogueJson:DialogueFile = null;

	//week 2 stage
	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	//week 3 stage
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;
	var phillyGlowGradient:PhillyGlow.PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlow.PhillyGlowParticle>;

	//week 4 stage
	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	//week 5 stage
	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	//week 6 stage
	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	//week 7 stage
	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;
	var gunsThing:FlxSprite;

	//week 7 extras
	public static var tankmanRainbow:Bool = false;
	var raiseTankman:Bool = false;
	//var raiseBF:Bool = false;
	var gunsColors:Array<FlxColor> = [0xBFFF0000, 0xBFFF5E00, 0xBFFFFB00, 0xBF00FF0D, 0xBF0011FF, 0xBFD400FF]; //WTF BOYFRIEND REFERENCE?!?!??!#11/1/1??!Q
	var gunsTween:FlxTween = null;

	//animations???
	var notestuffs:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singSPACE'];

	//this probably doesnt need to exist but whatever
	public var hudIsSwapped:Bool = false;

	//omg rating text
	public var ratingsTxt:FlxText;

	//ms timing popup shit
	public var msTxt:FlxText;
	public var msTimer:FlxTimer = null;

	//watermarks
	public var engineWatermark:FlxText;
	public var screwYou:FlxText;
	public var noBotplay:FlxText;
	public var songCreditsTxt:FlxText;
	public var remixCreditsTxt:FlxText;
	public var songCard:FlxSprite;
	public var mirrorSongCard:FlxSprite;
	public var grpSongNameTxt:FlxTypedGroup<FlxText>;

	//score stuff
	public var ratingIntensity:String = ClientPrefs.ratingIntensity;
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var deathTxt:FlxText;
	public var sarvRightTxt:FlxText;
	public var sarvAccuracyTxt:FlxText;
	public var scoreTxtBg:FlxSprite;
	public var sarvAccuracyBg:FlxSprite;
	public var timeTxt:FlxText;
	public var timeTxtTween:FlxTween;
	public var scoreTxtTween:FlxTween;
	public var deathTxtTween:FlxTween;
	public var sarvRightTxtTween:FlxTween;

	//stuff for story mode
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	//default zooms
	public var defaultCamZoom:Float = 1.05;
	public var defaultHudCamZoom:Float = 1;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singSPACE'];

	//cutscene shit
	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	//woah wtf camera offsets
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var ratingText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	//precaching that may or may not work (not sure tbh)
	var precacheList:Map<String, String> = new Map<String, String>();

	//cam panning
	var moveCamTo:Array<Float> = [0,0];

	//not finished debug display in game
	var debugDisplay:Bool = false;

	//darken bg thing
	/*var darkenBG:FlxSprite;
	var darkenTimer:FlxTimer = null;
	var darkenTween:FlxTween = null;*/

	override public function create()
	{
		Paths.clearStoredMemory(); //we clear the shit old memory

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = Keybinds.fill();

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray[mania].length)
			{
				keysPressed.push(false);
			}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		if(cpuControlled == true && !SONG.allowBot) {
			cpuControlled = false;
		}
		tappy = ClientPrefs.ghostTapping;
		if(tappy == true && !SONG.allowGhostTapping) {
			tappy = false;
		}

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false); //adding false fixes zooming
		FlxG.cameras.add(camOther, false); //ditto
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true); //new EPIC code
		//FlxCamera.defaultCameras = [camGame]; //old STUPID code
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true; //update other states iirc
		persistentDraw = true;

		//init mania
		mania = SONG.mania;
		if (mania < Note.minMania || mania > Note.maxMania)
			mania = Note.defaultMania;

		//failsafe
		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		//ooo scary bpm changes
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		//reset some shit
		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		//set some shit
		curStage = PlayState.SONG.stage;
		curModChart = PlayState.SONG.modchart;
		//trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
				default:
					curStage = 'stage';
			}
		}

		//get stage data
		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				p4: [-300, -1200],
				hide_girlfriend: false,
			
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		//set variables using stage data
		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		if (stageData.p4 != null) {
			P4_X = stageData.p4[0];
			P4_Y = stageData.p4[1];
		} else {
			P4_X = 0;
			P4_Y = 0;
		}

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];
		
		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		//make groups (wtf!!!)
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		player4Group = new FlxSpriteGroup(P4_X, P4_Y);
		dadMirrorGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		idiotGroup = new FlxSpriteGroup(DAD_X, DAD_Y);

		var sprites:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
		switch (curStage)
		{
			//I would do autoLayer for all the stages but that can wait
			case 'stage': //Week 1
				var layerArray:Array<FlxBasic> = [];
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				};

				autoLayer(layerArray);

			case 'modapps-disruption':
				{
					defaultCamZoom = 0.85;
					curStage = 'modapps-disruption';
					var bg:FlxSprite = new FlxSprite(-400, -200).loadGraphic(Paths.image('modappsd'));
					bg.antialiasing = true;
					bg.scrollFactor.set(0.3, 0.3);
					bg.active = true;
					
					add(bg);
					addGlitchShader(bg, 0.1, 50, 10);
				};
			case 'wind-help': //example glitch shader stage
				{
					defaultCamZoom = 0.85;
					curStage = 'wind-help';
					var bg:FlxSprite = new FlxSprite(-400, -200).loadGraphic(Paths.image('bgwind'));
					bg.antialiasing = true;
					bg.scrollFactor.set(0.6, 0.6);
					bg.active = true;
					
					add(bg);
					addGlitchShader(bg, 0.1, 1, 1);
				};

			case 'spooky': //Week 2
				var layerArray:Array<FlxBasic> = [];
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');

				autoLayer(layerArray);

			case 'philly': //Week 3
				var layerArray:Array<FlxBasic> = [];
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				add(phillyWindow);
				phillyWindow.alpha = 0;

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

				autoLayer(layerArray);

			case 'limo': //Week 4
				var layerArray:Array<FlxBasic> = [];
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					precacheList.set('dancerdeath', 'sound');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

				autoLayer(layerArray);

			case 'mall': //Week 5 - Cocoa, Eggnog
				var layerArray:Array<FlxBasic> = [];
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				precacheList.set('Lights_Shut_off', 'sound');

				autoLayer(layerArray);

			case 'mallEvil': //Week 5 - Winter Horrorland
				var layerArray:Array<FlxBasic> = [];
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

				autoLayer(layerArray);

			case 'school': //Week 6 - Senpai, Roses
				var layerArray:Array<FlxBasic> = [];
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

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

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

				autoLayer(layerArray);

			case 'schoolEvil': //Week 6 - Thorns
				var layerArray:Array<FlxBasic> = [];
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx-pixel';
				GameOverSubstate.loopSoundName = 'gameOver-pixel';
				GameOverSubstate.endSoundName = 'gameOverEnd-pixel';
				GameOverSubstate.characterName = 'bf-pixel-dead';

				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;

					layerArray = [bg, bgGhouls];
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					
					layerArray = [bg];
				}

				autoLayer(layerArray);

			case 'tank': //Week 7 - Ugh, Guns, Stress
				var layerArray:Array<FlxBasic> = [];
				
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);

				tankmanRun = new FlxTypedGroup<TankmenBG>();

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				moveTank();

				if(!ClientPrefs.lowQuality)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();

					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);

					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);

					layerArray = [sky, clouds, mountains, buildings, ruins, smokeLeft, smokeRight, tankWatchtower, tankGround, tankmanRun, ground];
				} else {
					layerArray = [sky, ruins, tankGround, tankmanRun, ground];
				}

				autoLayer(layerArray);

				gunsThing = new FlxSprite(-1000,-1000).makeGraphic(FlxG.width*6,FlxG.height*6,FlxColor.WHITE);
				gunsThing.color = 0xBFFF0000;
				gunsThing.alpha = 0;

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
		}

		switch(Paths.formatToSongPath(SONG.song))
		{
			case 'stress':
				GameOverSubstate.characterName = 'bf-holding-gf-dead';
		}

		//set pixel stage things
		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		//inside create(), crossfade
		grpIdiotFade = new FlxTypedGroup<CrossFade>(ClientPrefs.crossFadeLimit); // limit
		if (ClientPrefs.crossFadeLimit != null) {
			grpCrossFade = new FlxTypedGroup<CrossFade>(ClientPrefs.crossFadeLimit); // limit
		} else {
			grpCrossFade = new FlxTypedGroup<CrossFade>(4); // limit
		}
		if (ClientPrefs.crossFadeLimit != null) {
			grpP4CrossFade = new FlxTypedGroup<CrossFade>(ClientPrefs.crossFadeLimit); // limit
		} else {
			grpP4CrossFade = new FlxTypedGroup<CrossFade>(2); // limit
		}
		if (ClientPrefs.crossFadeLimit != null) {
			grpBFCrossFade = new FlxTypedGroup<BFCrossFade>(ClientPrefs.boyfriendCrossFadeLimit); // limit
		} else {
			grpBFCrossFade = new FlxTypedGroup<BFCrossFade>(1); // limit
		}
		//grpCrossFade = new FlxTypedGroup<CrossFade>(4); // limit
		//add(grpCrossFade);

		//grpBFCrossFade = new FlxTypedGroup<BFCrossFade>(1); // limit
		//add(grpBFCrossFade);

		add(grpIdiotFade);
		add(idiotGroup);
		add(gfGroup); //Needed for blammed lights

		// Shitty layering but whatev it works LOL
		switch(curStage) {
			case 'limo':
				add(limo);
			case 'tank':
				add(gunsThing);
		}

		add(grpP4CrossFade);
		add(player4Group);
		add(grpCrossFade);
		add(dadGroup);
		add(grpBFCrossFade);
		add(boyfriendGroup);
		add(dadMirrorGroup);
		
		//why can we just not use cam flash??? no like seriously
		switch(curStage) {
			case 'spooky':
				add(halloweenWhite);
			case 'tank':
				add(foregroundSprites);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush) 
			luaArray.push(new FunkinLua(luaFile));
		#end

		//gf shit
		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
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
			switch(Paths.formatToSongPath(SONG.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
			{
				gf = new Character(0, 0, gfVersion);
				startCharacterPos(gf);
				gf.scrollFactor.set(0.95, 0.95);
				gfGroup.add(gf);
				startCharacterLua(gf.curCharacter);
	
				if(gfVersion == 'pico-speaker')
				{
					if(!ClientPrefs.lowQuality)
					{
						var firstTank:TankmenBG = new TankmenBG(20, 500, true);
						firstTank.resetShit(20, 600, true);
						firstTank.strumTime = 10;
						tankmanRun.add(firstTank);
	
						for (i in 0...TankmenBG.animationNotes.length)
						{
							if(FlxG.random.bool(16)) {
								var tankBih = tankmanRun.recycle(TankmenBG);
								tankBih.strumTime = TankmenBG.animationNotes[i][0];
								tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
								tankmanRun.add(tankBih);
							}
						}
					}
				}
			}

		player4 = new Character(0, 0, SONG.player4);
		startCharacterPos(player4, true);
		if (SONG.enablePlayer4) player4Group.add(player4);
		startCharacterLua(player4.curCharacter);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		
		if (isStoryMode) {
			boyfriend = new Boyfriend(0, 0, SONG.player1);
			startCharacterPos(boyfriend);
			boyfriendGroup.add(boyfriend);
			startCharacterLua(boyfriend.curCharacter);
		} else {
			boyfriend = new Boyfriend(0, 0, SONG.player1);
			startCharacterPos(boyfriend);
			boyfriendGroup.add(boyfriend);
			startCharacterLua(boyfriend.curCharacter);	
		}

		//for orbit
		dadmirror = new Character(dad.x, dad.y, dad.curCharacter);
		startCharacterPos(dadmirror, true);
		dadmirror.y += 0;
		dadmirror.x += 150;
		dadmirror.visible = false;
		dadMirrorGroup.add(dadmirror);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			
			/*case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				insert(members.indexOf(dadGroup) - 1, evilTrail);*/
		}

		//flixel trails
		if (dad.flixelTrail && dad.trailLength != null && dad.trailDelay != null && dad.trailAlpha != null && dad.trailDiff != null) {
			var dadTrail = new FlxTrail(dad, null, dad.trailLength, dad.trailDelay, dad.trailAlpha, dad.trailDiff); //nice //target, graphic, length, delay, alpha, diff
			insert(members.indexOf(dadGroup) - 1, dadTrail);
		}

		if (player4.flixelTrail && player4.trailLength != null && player4.trailDelay != null && player4.trailAlpha != null && player4.trailDiff != null) {
			var p4Trail = new FlxTrail(player4, null, player4.trailLength, player4.trailDelay, player4.trailAlpha, player4.trailDiff); //nice
			insert(members.indexOf(player4Group) - 1, p4Trail);
		}

		if (boyfriend.flixelTrail && boyfriend.trailLength != null && boyfriend.trailDelay != null && boyfriend.trailAlpha != null && boyfriend.trailDiff != null) {
			var bfTrail = new FlxTrail(boyfriend, null, boyfriend.trailLength, boyfriend.trailDelay, boyfriend.trailAlpha, boyfriend.trailDiff); //nice
			insert(members.indexOf(boyfriendGroup) - 1, bfTrail);
		}

		//haha funny darken
		/*darkenBG = new FlxSprite(-100, -100).makeGraphic(FlxG.height*2,FlxG.height*2,FlxColor.BLACK);
		darkenBG.alpha = 0;
		darkenBG.cameras = [camHUD];
		darkenBG.scrollFactor.set();
		if (ClientPrefs.darkenBG) add(darkenBG);*/

		//dialogue shit
		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		//timebar shit
		var curTB:String = ClientPrefs.timeBarType;
		var showJustTimeText:Bool = false;
		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		switch (curTB) {
			case 'Disabled':
				showJustTimeText = false;
				showTime = false;
			case 'Song Name' | 'Time Elapsed' | 'Time Left':
				showJustTimeText = false;
				showTime = true;
			case 'Time Elapsed (No Bar)' | 'Time Left (No Bar)':
				showJustTimeText = true;
				showTime = true;
		}
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		if (timeBarBG.visible == true && showJustTimeText) {
			timeBarBG.visible = false;
		} 
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		if (!ClientPrefs.changeTBcolour)
		{
			timeBar.createFilledBar(0xFF000000, FlxColor.fromRGB(ClientPrefs.timeBarRed, ClientPrefs.timeBarGreen, ClientPrefs.timeBarBlue));
		}
		else
		{
			timeBar.createFilledBar(0xFF000000, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
		}
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		if (timeBar.visible == true && showJustTimeText) {
			timeBar.visible = false;
		} 
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		if(ClientPrefs.timeBarType == 'Time Left (No Bar)' || ClientPrefs.timeBarType == 'Time Elapsed (No Bar)')
			{
				timeTxt.size = 40;
				timeTxt.y -= 6;
			}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		//strum line settings
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		thirdStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
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

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		//healthbar shit
			healthBarBG = new AttachedSprite('healthBarSlim');
			healthBarBG.y = FlxG.height * 0.89 + ClientPrefs.comboOffset[4];
			if (ClientPrefs.scoreDisplay == 'Sarvente') {
				healthBarBG.y -= 20;
			}
			healthBarBG.x = FlxG.width/4 + ClientPrefs.comboOffset[5];
			healthBarBG.scrollFactor.set();
			healthBarBG.visible = !ClientPrefs.hideHud;
			healthBarBG.xAdd = -4;
			healthBarBG.yAdd = -4;
			add(healthBarBG);
			if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 10, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height / 3), this,
				'health', 0, 2);
			healthBar.scrollFactor.set();
			// healthBar
			healthBar.visible = !ClientPrefs.hideHud;
			healthBar.alpha = ClientPrefs.healthBarAlpha;
			add(healthBar);
			healthBarBG.sprTracker = healthBar;

			healthBarMiddle = new FlxBar(healthBar.x, healthBarBG.y + 14, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height / 3), this,
				'health', 0, 2);
			healthBarMiddle.scrollFactor.set();
			// healthBar
			healthBarMiddle.visible = !ClientPrefs.hideHud;
			healthBarMiddle.alpha = ClientPrefs.healthBarAlpha;
			add(healthBarMiddle);
			//healthBarBG.sprTracker = healthBar;

			healthBarMiddleHalf = new FlxBar(healthBar.x, healthBarBG.y + 16, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height / 3), this,
				'health', 0, 2);
			healthBarMiddleHalf.scrollFactor.set();
			// healthBar
			healthBarMiddleHalf.visible = !ClientPrefs.hideHud;
			healthBarMiddleHalf.alpha = ClientPrefs.healthBarAlpha;
			add(healthBarMiddleHalf);
			//healthBarBG.sprTracker = healthBar;

			healthBarBottom = new FlxBar(healthBar.x, healthBarBG.y + 18, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height / 3), this,
				'health', 0, 2);
			healthBarBottom.scrollFactor.set();
			// healthBar
			healthBarBottom.visible = !ClientPrefs.hideHud;
			healthBarBottom.alpha = ClientPrefs.healthBarAlpha;
			add(healthBarBottom);
			//healthBarBG.sprTracker = healthBar;
		
		//rating display shit
		if (ClientPrefs.ratingsDisplay) {
			ratingsTxt = new FlxText(12, (FlxG.height/2)-64, 0, "Perfects:"+perfects+"\nSicks:"+sicks+"\nGoods:"+goods+"\nBads:"+bads+"\nShits:"+shits+"\nWTFs:"+wtfs+"\nCombo Breaks:"+songMisses);
			ratingsTxt.scrollFactor.set();
			ratingsTxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ratingsTxt.cameras = [camHUD];
			add(ratingsTxt);
		}

		//watermark shit
		if (ClientPrefs.watermarks)
		{
			songCard = new FlxSprite(-601, FlxG.height - 234).loadGraphic(Paths.image('songCard'));
			songCard.scrollFactor.set();
			songCard.cameras = [camHUD];
			songCard.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			songCard.alpha = 0;
			add(songCard);

			mirrorSongCard = new FlxSprite(songCard.x -601, FlxG.height - 234).loadGraphic(Paths.image('songCard'));
			mirrorSongCard.scrollFactor.set();
			mirrorSongCard.cameras = [camHUD];
			mirrorSongCard.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			mirrorSongCard.alpha = 0;
			mirrorSongCard.flipX = true;
			add(mirrorSongCard);

			engineWatermark = new FlxText(12, FlxG.height - 24, 0, "Denpa Engine v" + MainMenuState.denpaEngineVersion);
			engineWatermark.scrollFactor.set();
			engineWatermark.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			engineWatermark.cameras = [camHUD];
			add(engineWatermark);
			screwYou = new FlxText(12, FlxG.height - 44, 0, "Ghost Tapping is forced off!");
			screwYou.scrollFactor.set();
			screwYou.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			screwYou.cameras = [camHUD];
			screwYou.visible = !SONG.allowGhostTapping;
			add(screwYou);
			noBotplay = new FlxText(12, FlxG.height - 64, 0, "Botplay is forced off!");
			noBotplay.scrollFactor.set();
			noBotplay.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noBotplay.cameras = [camHUD];
			noBotplay.visible = !SONG.allowBot;
			if (screwYou.visible == false) {
				noBotplay.y = FlxG.height - 44;
			} else {
				noBotplay.y = FlxG.height - 64;
			}
			add(noBotplay);
			songCreditsTxt = new FlxText(songCard.x, songCard.y + 20, 0, "");
			songCreditsTxt.scrollFactor.set();
			songCreditsTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			songCreditsTxt.cameras = [camHUD];
			add(songCreditsTxt);
			remixCreditsTxt = new FlxText(songCard.x, songCreditsTxt.y + 40, 0, "");
			remixCreditsTxt.scrollFactor.set();
			remixCreditsTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			remixCreditsTxt.cameras = [camHUD];
			add(remixCreditsTxt);

			grpSongNameTxt = new FlxTypedGroup<FlxText>();
			add(grpSongNameTxt);

			var fuck:Int = 0;
			for (i in 0...2)
			{
				var txt:FlxText = new FlxText(songCard.x + 2*i, (songCreditsTxt.y - 64) + 2*i, 0, "");
				txt.scrollFactor.set();
				txt.setFormat("VCR OSD Mono", 48, FlxColor.fromRGB(dad.healthColorArray[0] + fuck*2, dad.healthColorArray[1] + fuck*2, dad.healthColorArray[2] + fuck*2), LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
				txt.cameras = [camHUD];
				txt.text = SONG.song;
				grpSongNameTxt.add(txt);

				fuck++;
			}
			/*songNameTxt = new FlxText(songCard.x, songCreditsTxt.y - 64, 0, "");
			songNameTxt.scrollFactor.set();
			songNameTxt.setFormat("VCR OSD Mono", 64, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
			songNameTxt.cameras = [camHUD];
			songNameTxt.text = SONG.song;
			add(songNameTxt);*/
			switch (SONG.song.toLowerCase())
			{
				case 'tutorial' | 'bopeebo' | 'fresh' | 'dad battle' | 'spookeez' | 'south' | 'pico' | 'philly nice' | 'blammed' | 'satin panties' | 'high' | 'milf' | 'cocoa' | 'eggnog' | 'senpai' | 'roses' | 'thorns' | 'ugh' | 'guns' | 'stress':
					songCreditsTxt.text = "Song by Kawaisprite";
				case 'monster' | 'winter horrorland':
					songCreditsTxt.text = "Song by Bassetfilms";
				case 'gospel' | 'zavodila' | 'parish' | 'worship' | 'casanova':
					songCreditsTxt.text = "Song by Mike Geno";
				case 'lo fight' | 'overhead' | 'ballistic':
					songCreditsTxt.text = "Song by Sock.Clip";
				case 'wife forever' | 'sky' | 'manifest':
					songCreditsTxt.text = "Song by bbpanzu";
				case 'foolhardy' | 'hellclown' | 'madness' | 'improbable outset':
					songCreditsTxt.text = "Song by RozeBud";
				case 'disruption' | 'disability' | 'algebra' | 'ferocious' | 'applecore':
					songCreditsTxt.text = "Song by Grantare";
			}
			switch (SONG.song.toLowerCase())
			{
				case 'tutorial' | 'bopeebo' | 'fresh' | 'dad battle' | 'spookeez' | 'south' | 'monster' | 'pico' | 'philly nice' | 'blammed' | 'satin panties' | 'high' | 'milf' | 'cocoa' | 'eggnog' | 'winter horrorland' | 'senpai' | 'roses' | 'thorns' | 'ugh' | 'guns' | 'stress':
					remixCreditsTxt.text = "From: Friday Night Funkin'";
				case 'gospel' | 'zavodila' | 'parish' | 'worship' | 'casanova':
					remixCreditsTxt.text = "From: Mid-Fight Masses";
				case 'lo fight' | 'overhead' | 'ballistic':
					remixCreditsTxt.text = "From: Vs. Whitty";
				case 'wife forever' | 'sky' | 'manifest':
					remixCreditsTxt.text = "From: Vs. Sky";
				case 'hellclown' | 'madness' | 'improbable outset':
					remixCreditsTxt.text = "From: Vs. Tricky";
				case 'foolhardy':
					remixCreditsTxt.text = "From: Vs. Zardy";
				case 'disruption' | 'disability' | 'algebra' | 'ferocious' | 'applecore':
					remixCreditsTxt.text = "From: Golden Apple";
			}
		}

		//omg its that ms text from earlier
		msTxt = new FlxText(0, 0, 0, "");
		msTxt.scrollFactor.set();
		msTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		msTxt.cameras = [camHUD];
		msTxt.x += ClientPrefs.comboOffset[0];
		msTxt.y -= ClientPrefs.comboOffset[1];
		msTxt.visible = (!ClientPrefs.hideHud && ClientPrefs.msPopup);
		insert(members.indexOf(strumLineNotes), msTxt);

		//shit for score text
		scoreTxtBg = new FlxSprite(0, 0).makeGraphic(679, 30, FlxColor.WHITE);
		scoreTxtBg.x = (FlxG.width/4)-40;
		//scoreTxtBg.y = healthBarBG.y + 62; //42
		scoreTxtBg.y = 683;
		//trace('what is the y? it is: ' + scoreTxtBg.y);
		scoreTxtBg.width = scoreTxtBg.width*2;
		scoreTxtBg.height = scoreTxtBg.height*2;
		scoreTxtBg.scrollFactor.set();
		scoreTxtBg.alpha = 0;
		if (ClientPrefs.scoreDisplay == 'Sarvente') {
			scoreTxtBg.alpha = 0.5;
		}
		scoreTxtBg.color = FlxColor.BLACK;
		scoreTxtBg.visible = !ClientPrefs.hideHud;
		add(scoreTxtBg);

		sarvAccuracyBg = new FlxSprite(0, 0).makeGraphic(205, 30, FlxColor.WHITE);
		if(ClientPrefs.watermarks) {
			sarvAccuracyBg.x = (FlxG.width/4 + FlxG.width/4 + FlxG.width/4 + 80);
		} else {
			sarvAccuracyBg.x = 40;
		}
		sarvAccuracyBg.y = scoreTxtBg.y;
		sarvAccuracyBg.height = scoreTxtBg.height;
		sarvAccuracyBg.scrollFactor.set();
		sarvAccuracyBg.alpha = 0;
		if (ClientPrefs.scoreDisplay == 'Sarvente') {
			sarvAccuracyBg.alpha = 0.5;
		}
		sarvAccuracyBg.color = FlxColor.BLACK;
		sarvAccuracyBg.visible = !ClientPrefs.hideHud;
		if (sarvAccuracyBg.visible) sarvAccuracyBg.visible = ClientPrefs.sarvAccuracy;
		add(sarvAccuracyBg);

		//icons
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 70;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 70;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		
		iconP4 = new HealthIcon(player4.healthIcon, false);
		iconP4.y = healthBar.y - 130;
		iconP4.visible = !ClientPrefs.hideHud;
		if (iconP4.visible && !SONG.enablePlayer4) iconP4.visible = false; 
		iconP4.alpha = ClientPrefs.healthBarAlpha;
		iconP4.scale.set(0.75, 0.75);
		iconP4.updateHitbox();

		add(iconP4);
		add(iconP1);
		add(iconP2);
		reloadHealthBarColors(false);

		scoreTxt = new FlxText(0, 687, FlxG.width, "", 20); //46
		//if (ClientPrefs.scoreDisplay == 'Sarvente') scoreTxt.y += 20;
		//trace('what is the sex y? it is: ' + scoreTxt.y);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		if (ClientPrefs.scoreDisplay == 'Sarvente') {
			//scoreTxt.x = 30;
			scoreTxt.x = 0;
			scoreTxt.borderStyle = SHADOW;
		} else if (ClientPrefs.scoreDisplay == 'Kade') {
			scoreTxt.x = 10;
		}
		scoreTxt.visible = !ClientPrefs.hideHud;
		
		//sarvente score texts

			deathTxt = new FlxText(scoreTxtBg.x + 40, scoreTxt.y, FlxG.width, "", 20);
			deathTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			deathTxt.scrollFactor.set();
			deathTxt.borderSize = 1.25;
			if (ClientPrefs.scoreDisplay == 'Sarvente') {
				deathTxt.borderStyle = SHADOW;
				deathTxt.x = scoreTxtBg.x + 5;
			}
			deathTxt.visible = !ClientPrefs.hideHud;

			sarvRightTxt = new FlxText(-FlxG.width/2 + 280, scoreTxt.y, FlxG.width, "", 20);
			sarvRightTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			sarvRightTxt.scrollFactor.set();
			sarvRightTxt.borderSize = 1.25;
			if (ClientPrefs.scoreDisplay == 'Sarvente') {
				sarvRightTxt.borderStyle = SHADOW;
				sarvRightTxt.x = -FlxG.width/2 + 315;
			}
			sarvRightTxt.visible = !ClientPrefs.hideHud;

			sarvAccuracyTxt = new FlxText(sarvAccuracyBg.x + 5, scoreTxt.y, FlxG.width, "", 20);
			sarvAccuracyTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			sarvAccuracyTxt.scrollFactor.set();
			sarvAccuracyTxt.borderSize = 1.25;
			if (ClientPrefs.scoreDisplay == 'Sarvente') {
				sarvAccuracyTxt.borderStyle = SHADOW;
			}
			sarvAccuracyTxt.visible = !ClientPrefs.hideHud;
			if (sarvAccuracyTxt.visible) sarvAccuracyTxt.visible = ClientPrefs.sarvAccuracy;

			add(deathTxt);
		add(scoreTxt);
			add(sarvRightTxt);
			add(sarvAccuracyTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "AUTO", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		//lets set ALL the cameras at once
		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarMiddle.cameras = [camHUD];
		healthBarMiddleHalf.cameras = [camHUD];
		healthBarBottom.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		iconP4.cameras = [camHUD];
		scoreTxtBg.cameras = [camHUD];
		sarvAccuracyBg.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		deathTxt.cameras = [camHUD];
		sarvRightTxt.cameras = [camHUD];
		sarvAccuracyTxt.cameras = [camHUD];
		//scoreTxtBg.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		//in create(), this does the actual tinting
		if (SONG.tintRed != null && SONG.tintGreen != null && SONG.tintBlue != null) {
			if(SONG.tintRed != 255 && SONG.tintGreen != 255 && SONG.tintBlue != 255) {
				var tint:FlxSprite = new FlxSprite(-2000,-2000).makeGraphic(FlxG.width*6,FlxG.width*6,FlxColor.WHITE);
				tint.scrollFactor.set();
				tint.alpha = 0.5;
				tint.blend = BlendMode.MULTIPLY;
				tint.color = FlxColor.fromRGB(SONG.tintRed,SONG.tintGreen,SONG.tintBlue);
				add(tint);
			}
		}
		
		//cutscene shit
		var daSong:String = Paths.formatToSongPath(curSong);
		var shouldBeSeeingCutscene:Null<Bool> = null;
		var daCutsceneString:String = ClientPrefs.cutscenes;
		switch (daCutsceneString) {
			case 'Never':
				shouldBeSeeingCutscene = false;
			case 'Story Mode Only':
				if (isStoryMode) shouldBeSeeingCutscene = true;
			case 'Freeplay Only':
				if (!isStoryMode) shouldBeSeeingCutscene = true;
			case 'Always':
				shouldBeSeeingCutscene = true;
		}
		if (shouldBeSeeingCutscene && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				case 'ugh' | 'guns' | 'stress':
					tankIntro();

				//case 'control':
					//startVideo('week1control');

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();
		#if desktop
		ratingText = ratingName + " " + ratingFC;
		#end

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');
		precacheList.set('crit', 'sound');

		if (PauseSubState.songName != null) {
			precacheList.set(PauseSubState.songName, 'music');
		} else if(ClientPrefs.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(ClientPrefs.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		/*if(boyfriend.sarventeFloating) {
		FlxTween.tween(boyfriend, {y: 100}, 4, {type:FlxTween.PINGPONG, ease: FlxEase.quadInOut});
		}

		if(dad.sarventeFloating) {
		FlxTween.tween(dad, {y: 100}, 4, {type:FlxTween.PINGPONG, ease: FlxEase.quadInOut});
		}*/

		
		super.create();

		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
			{
				//trace('Key $key is type $type');
				switch(type)
				{
					case 'image':
						Paths.image(key);
					case 'sound':
						Paths.sound(key);
					case 'music':
						Paths.music(key);
				}
			}
		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}

	public function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	//this function might be a little confusing so ill explain (helpful comment man is here). the first variable is if its using p4 as the main icon or dad. the second is for if its gf or dad.
	//also this is probably very VERY badly written so lets rewrite this eventually, capiche?
	public function reloadHealthBarColors(p4:Bool, ?useGf:Bool = null) {

		if (!ClientPrefs.greenhp)
		{
			var who:Character = dad;
			var who2:Character = boyfriend;
			if (p4) {
				who = player4;
			}
			if (useGf) {
				who = gf;
			}
			/*if (hudIsSwapped) {
				var storage:Character = who2;
				who2 = who;
				who = storage;
			}*/
				if (who2.healthBarCount != null && who.healthBarCount != null) /*check for sexy hp bar counter*/ {
					var curHealthBarCombo:String = who2.healthBarCount + ',' + who.healthBarCount;
					switch (curHealthBarCombo)
					{
						case '1,1':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
						case '1,2':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
						case '2,1':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
						case '3,1':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArrayBottom[0], who2.healthColorArrayBottom[1], who2.healthColorArrayBottom[2]));
						case '1,3':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArrayBottom[0], who.healthColorArrayBottom[1], who.healthColorArrayBottom[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
						case '2,2':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
						case '2,3':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArrayBottom[0], who.healthColorArrayBottom[1], who.healthColorArrayBottom[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
						case '3,2':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
		
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArrayBottom[0], who2.healthColorArrayBottom[1], who2.healthColorArrayBottom[2]));
						case '3,3':
							healthBar.createFilledBar(FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]),
							FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]));
							
							healthBarMiddle.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarMiddleHalf.createFilledBar(FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]),
							FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]));
		
							healthBarBottom.createFilledBar(FlxColor.fromRGB(who.healthColorArrayBottom[0], who.healthColorArrayBottom[1], who.healthColorArrayBottom[2]),
							FlxColor.fromRGB(who2.healthColorArrayBottom[0], who2.healthColorArrayBottom[1], who2.healthColorArrayBottom[2]));
					}
				} else /*failsafe for null hp bar counts*/ {
					healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
	
					healthBarMiddle.createFilledBar(0xFFFF0000, 0xFF66FF33);
	
					healthBarMiddleHalf.createFilledBar(0xFFFF0000, 0xFF66FF33);
	
					healthBarBottom.createFilledBar(0xFFFF0000, 0xFF66FF33);
				}
		}
		else //og healthbar colours
		{
				healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);

				healthBarMiddle.createFilledBar(0xFFFF0000, 0xFF66FF33);

				healthBarMiddleHalf.createFilledBar(0xFFFF0000, 0xFF66FF33);

				healthBarBottom.createFilledBar(0xFFFF0000, 0xFF66FF33);
		}
		healthBar.updateBar();

		healthBarMiddle.updateBar();

		healthBarMiddleHalf.updateBar();

		healthBarBottom.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
			
			case 3:
				if(!player4Map.exists(newCharacter)) {
					var newP4:Character = new Character(0, 0, newCharacter);
					player4Map.set(newCharacter, newP4);
					player4Group.add(newP4);
					startCharacterPos(newP4, true);
					newP4.alpha = 0.00001;
					startCharacterLua(newP4.curCharacter);
				}
		}
	}

	public function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}
	
	public function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				startAndEnd();
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	public function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	public function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function tankIntro()
		{
			var cutsceneHandler:CutsceneHandler = new CutsceneHandler();
	
			var songName:String = Paths.formatToSongPath(SONG.song);
			dadGroup.alpha = 0.00001;
			camHUD.visible = false;
			//inCutscene = true; //this would stop the camera movement, oops
	
			var tankman:FlxSprite = new FlxSprite(-20, 320);
			tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
			tankman.antialiasing = ClientPrefs.globalAntialiasing;
			addBehindDad(tankman);
			cutsceneHandler.push(tankman);
	
			var tankman2:FlxSprite = new FlxSprite(16, 312);
			tankman2.antialiasing = ClientPrefs.globalAntialiasing;
			tankman2.alpha = 0.000001;
			cutsceneHandler.push(tankman2);
			var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
			gfDance.antialiasing = ClientPrefs.globalAntialiasing;
			cutsceneHandler.push(gfDance);
			var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
			gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
			cutsceneHandler.push(gfCutscene);
			var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
			picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
			cutsceneHandler.push(picoCutscene);
			var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
			boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
			cutsceneHandler.push(boyfriendCutscene);
	
			cutsceneHandler.finishCallback = function()
			{
				var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
				FlxG.sound.music.fadeOut(timeForStuff);
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
				moveCamera(true, false);
				startCountdown();
	
				dadGroup.alpha = 1;
				camHUD.visible = true;
				boyfriend.animation.finishCallback = null;
				gf.animation.finishCallback = null;
				gf.dance();
			};
	
			camFollow.set(dad.x + 280, dad.y + 170);
			switch(songName)
			{
				case 'ugh':
					cutsceneHandler.endTime = 12;
					cutsceneHandler.music = 'DISTORTO';
					precacheList.set('wellWellWell', 'sound');
					precacheList.set('killYou', 'sound');
					precacheList.set('bfBeep', 'sound');
	
					var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell'));
					FlxG.sound.list.add(wellWellWell);
	
					tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
					tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
					tankman.animation.play('wellWell', true);
					FlxG.camera.zoom *= 1.2;
	
					// Well well well, what do we got here?
					cutsceneHandler.timer(0.1, function()
					{
						wellWellWell.play(true);
					});
	
					// Move camera to BF
					cutsceneHandler.timer(3, function()
					{
						camFollow.x += 750;
						camFollow.y += 100;
					});
	
					// Beep!
					cutsceneHandler.timer(4.5, function()
					{
						boyfriend.playAnim('singUP', true);
						boyfriend.specialAnim = true;
						FlxG.sound.play(Paths.sound('bfBeep'));
					});
	
					// Move camera to Tankman
					cutsceneHandler.timer(6, function()
					{
						camFollow.x -= 750;
						camFollow.y -= 100;
	
						// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
						tankman.animation.play('killYou', true);
						FlxG.sound.play(Paths.sound('killYou'));
					});
	
				case 'guns':
					cutsceneHandler.endTime = 11.5;
					cutsceneHandler.music = 'DISTORTO';
					tankman.x += 40;
					tankman.y += 10;
					precacheList.set('tankSong2', 'sound');
	
					var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
					FlxG.sound.list.add(tightBars);
	
					tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
					tankman.animation.play('tightBars', true);
					boyfriend.animation.curAnim.finish();
	
					cutsceneHandler.onStart = function()
					{
						tightBars.play(true);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
					};
	
					cutsceneHandler.timer(4, function()
					{
						gf.playAnim('sad', true);
						gf.animation.finishCallback = function(name:String)
						{
							gf.playAnim('sad', true);
						};
					});
	
				case 'stress':
					cutsceneHandler.endTime = 35.5;
					tankman.x -= 54;
					tankman.y -= 14;
					gfGroup.alpha = 0.00001;
					boyfriendGroup.alpha = 0.00001;
					camFollow.set(dad.x + 400, dad.y + 170);
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
					foregroundSprites.forEach(function(spr:BGSprite)
					{
						spr.y += 100;
					});
					precacheList.set('stressCutscene', 'sound');
	
					tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
					addBehindDad(tankman2);
	
					if (!ClientPrefs.lowQuality)
					{
						gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
						gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
						gfDance.animation.play('dance', true);
						addBehindGF(gfDance);
					}
	
					gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
					gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
					gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.pause();
					addBehindGF(gfCutscene);
					if (!ClientPrefs.lowQuality)
					{
						gfCutscene.alpha = 0.00001;
					}
	
					picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
					picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
					addBehindGF(picoCutscene);
					picoCutscene.alpha = 0.00001;
	
					boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
					boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
					boyfriendCutscene.animation.play('idle', true);
					boyfriendCutscene.animation.curAnim.finish();
					addBehindBF(boyfriendCutscene);
	
					var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
					FlxG.sound.list.add(cutsceneSnd);
	
					tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
					tankman.animation.play('godEffingDamnIt', true);
	
					var calledTimes:Int = 0;
					var zoomBack:Void->Void = function()
					{
						var camPosX:Float = 630;
						var camPosY:Float = 425;
						camFollow.set(camPosX, camPosY);
						camFollowPos.setPosition(camPosX, camPosY);
						FlxG.camera.zoom = 0.8;
						cameraSpeed = 1;
	
						calledTimes++;
						if (calledTimes > 1)
						{
							foregroundSprites.forEach(function(spr:BGSprite)
							{
								spr.y -= 100;
							});
						}
					}
	
					cutsceneHandler.onStart = function()
					{
						cutsceneSnd.play(true);
					};
	
					cutsceneHandler.timer(15.2, function()
					{
						FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
						FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
	
						gfDance.visible = false;
						gfCutscene.alpha = 1;
						gfCutscene.animation.play('dieBitch', true);
						gfCutscene.animation.finishCallback = function(name:String)
						{
							if(name == 'dieBitch') //Next part
							{
								gfCutscene.animation.play('getRektLmao', true);
								gfCutscene.offset.set(224, 445);
							}
							else
							{
								gfCutscene.visible = false;
								picoCutscene.alpha = 1;
								picoCutscene.animation.play('anim', true);
	
								boyfriendGroup.alpha = 1;
								boyfriendCutscene.visible = false;
								boyfriend.playAnim('bfCatch', true);
								boyfriend.animation.finishCallback = function(name:String)
								{
									if(name != 'idle')
									{
										boyfriend.playAnim('idle', true);
										boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
									}
								};
	
								picoCutscene.animation.finishCallback = function(name:String)
								{
									picoCutscene.visible = false;
									gfGroup.alpha = 1;
									picoCutscene.animation.finishCallback = null;
								};
								gfCutscene.animation.finishCallback = null;
							}
						};
					});
	
					cutsceneHandler.timer(17.5, function()
					{
						zoomBack();
					});
	
					cutsceneHandler.timer(19.5, function()
					{
						tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
						tankman2.animation.play('lookWhoItIs', true);
						tankman2.alpha = 1;
						tankman.visible = false;
					});
	
					cutsceneHandler.timer(20, function()
					{
						camFollow.set(dad.x + 500, dad.y + 170);
					});
	
					cutsceneHandler.timer(31.2, function()
					{
						boyfriend.playAnim('singUPmiss', true);
						boyfriend.animation.finishCallback = function(name:String)
						{
							if (name == 'singUPmiss')
							{
								boyfriend.playAnim('idle', true);
								boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
							}
						};
	
						camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
						cameraSpeed = 12;
						FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
					});
	
					cutsceneHandler.timer(32.2, function()
					{
						zoomBack();
					});
			}
		}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	//WOO YEAH BABY
	//THATS WHAT IVE BEEN WAITING FOR
	public function cacheCountdown()
		{
			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', 'set', 'go']);
			introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);
	
			var introAlts:Array<String> = introAssets.get('default');
			if (isPixelStage) introAlts = introAssets.get('pixel');
			
			for (asset in introAlts)
				Paths.image(asset);
			
			Paths.sound('intro3' + introSoundsSuffix);
			Paths.sound('intro2' + introSoundsSuffix);
			Paths.sound('intro1' + introSoundsSuffix);
			Paths.sound('introGo' + introSoundsSuffix);
		}

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;

		if (songCreditsTxt != null) {
			if(songCreditsTxt.text != '')
				{
					FlxTween.tween(songCard, {x: 0, alpha: 1}, 0.7, {
						startDelay: 0.1,
						ease: FlxEase.elasticInOut,
						onComplete: function(twn:FlxTween)
						{
							new FlxTimer().start(2/(SONG.bpm/100), function(tmr:FlxTimer)
								{
									if(songCard != null){
										FlxTween.tween(songCard, {x: -601}, 0.7, {
											startDelay: 0.1,
											ease: FlxEase.elasticInOut,
											onComplete: function(twn:FlxTween)
											{
												FlxTween.tween(songCard, {alpha: 0}, 0.7, {
													onComplete: function(twn:FlxTween)
													{
														if (songCard != null) songCard.kill();
														if (songCard != null) songCard.destroy();
														if (songCreditsTxt != null) songCreditsTxt.kill();
														if (songCreditsTxt != null) songCreditsTxt.destroy();
														if (remixCreditsTxt != null) remixCreditsTxt.kill();
														if (remixCreditsTxt != null) remixCreditsTxt.destroy();
														if (grpSongNameTxt != null) {
															var i:Int = grpSongNameTxt.members.length-1;
															while(i >= 0) {
																var memb:FlxText = grpSongNameTxt.members[i];
																if(memb != null) {
																	memb.kill();
																	grpSongNameTxt.remove(memb);
																	memb.destroy();
																}
																--i;
															}
															grpSongNameTxt.clear();
														}
													}
												});
												FlxTween.tween(songCreditsTxt, {alpha: 0}, 0.7);
												FlxTween.tween(remixCreditsTxt, {alpha: 0}, 0.7);
												grpSongNameTxt.forEach(function(txt:FlxText)
													{
														FlxTween.tween(txt, {alpha: 0}, 0.7);
													});
											}
										});
									}
									if (songCreditsTxt != null){
										FlxTween.tween(songCreditsTxt, {x: -601}, 0.7, {
											startDelay: 0.1,
											ease: FlxEase.elasticInOut
										});		
									}
									if (remixCreditsTxt != null){
										FlxTween.tween(remixCreditsTxt, {x: -601}, 0.7, {
											startDelay: 0.1,
											ease: FlxEase.elasticInOut
										});
									}
									if (grpSongNameTxt != null){
										grpSongNameTxt.forEach(function(txt:FlxText)
											{
												FlxTween.tween(txt, {x: -601}, 0.7, {
													startDelay: 0.1,
													ease: FlxEase.quadInOut
												});
											});
									}
								});
						}
					});
					FlxTween.tween(mirrorSongCard, {x: -601, alpha: 1}, 0.7, {
						startDelay: 0.1,
						ease: FlxEase.elasticInOut,
						onComplete: function(twn:FlxTween)
						{
							new FlxTimer().start(2/(SONG.bpm/100), function(tmr:FlxTimer)
								{
									if(mirrorSongCard != null){
										FlxTween.tween(mirrorSongCard, {x: -1202}, 0.7, {
											startDelay: 0.1,
											ease: FlxEase.elasticInOut,
											onComplete: function(twn:FlxTween)
											{
												FlxTween.tween(mirrorSongCard, {alpha: 0}, 0.7, {
													onComplete: function(twn:FlxTween)
													{
														if (mirrorSongCard != null) mirrorSongCard.kill();
														if (mirrorSongCard != null) mirrorSongCard.destroy();
													}
												});
											}
										});
									}
								});
						}
					});
					FlxTween.tween(songCreditsTxt, {x: 0}, 0.7, {
						startDelay: 0.1,
						ease: FlxEase.elasticInOut
					});
					FlxTween.tween(remixCreditsTxt, {x: 0}, 0.7, {
						startDelay: 0.1,
						ease: FlxEase.elasticInOut
					});
					grpSongNameTxt.forEach(function(txt:FlxText)
						{
							FlxTween.tween(txt, {x: 0}, 0.7, {
								startDelay: 0.1,
								ease: FlxEase.quadInOut
							});
						});
				} else {
					songCard.kill();
					songCard.destroy();
					mirrorSongCard.kill();
					mirrorSongCard.destroy();
					songCreditsTxt.kill();
					songCreditsTxt.destroy();
					remixCreditsTxt.kill();
					remixCreditsTxt.destroy();
					var i:Int = grpSongNameTxt.members.length-1;
					while(i >= 0) {
						var memb:FlxText = grpSongNameTxt.members[i];
						if(memb != null) {
							memb.kill();
							grpSongNameTxt.remove(memb);
							memb.destroy();
						}
						--i;
					}
					grpSongNameTxt.clear();
					//songNameTxt.kill();
					//songNameTxt.destroy();
				}
		}
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			generateStaticArrows(2);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}
			for (i in 0...thirdStrums.length) {
				setOnLuas('defaultThirdStrumX' + i, thirdStrums.members[i].x);
				setOnLuas('defaultThirdStrumY' + i, thirdStrums.members[i].y);
				thirdStrums.members[i].cameras = [camGame];
				thirdStrums.members[i].scrollFactor.set(1,1);
				if(SONG.enablePlayer4) {
					thirdStrums.members[i].visible = true;
					//trace(['thirdStrums.visible = ' + thirdStrums.members[i].visible]);
				} else {
					thirdStrums.members[i].visible = false;
					//trace(['thirdStrums.visible = ' + thirdStrums.members[i].visible]);
				}
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (skipCountdown || startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 500);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if(SONG.autoIdles){
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
					
				}
				if (tmr.loopsLeft % player4.danceEveryNumBeats == 0 && player4.animation.curAnim != null && !player4.animation.curAnim.name.startsWith('sing') && !player4.stunned)
				{
					player4.dance();
				}
				}

				if (dad.orbit) {
					// SO THEIR ANIMATIONS DONT START OFF-SYNCED
					dad.playAnim('singUP');
					dadmirror.playAnim('singUP');
					dad.dance();
					dadmirror.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality && SONG.autoIdles)
						upperBoppers.dance(true);
					
					if(SONG.autoIdles){
						bottomBoppers.dance(true);
						santa.dance(true);
					}
				}

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						countdownReady.cameras = [camHUD];
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						countdownSet.cameras = [camHUD];
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						countdownGo.cameras = [camHUD];
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						if(boyfriend.animOffsets.exists('hey')) {
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = 0.6;
						}
						if(gf != null && gf.animOffsets.exists('cheer')) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = 0.6;
						}
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha = 0;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function addBehindGF(obj:FlxObject)
		{
			insert(members.indexOf(gfGroup), obj);
		}
	public function addBehindBF(obj:FlxObject)
		{
			insert(members.indexOf(boyfriendGroup), obj);
		}
	public function addBehindDad (obj:FlxObject)
		{
			insert(members.indexOf(dadGroup), obj);
		}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		secondaryVocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		vocals.time = time;
		secondaryVocals.time = time;
		vocals.play();
		secondaryVocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	public function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();
		secondaryVocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			secondaryVocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		switch(curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality) tankWatchtower.dance();
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
		}
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter(), true);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		secondaryVocals = new FlxSound().loadEmbedded(Paths.secVoices(PlayState.SONG.song));

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(secondaryVocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
			{
				for (songNotes in section.sectionNotes)
				{
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int;
					if(!ClientPrefs.randomMode){
						daNoteData = Std.int(songNotes[1] % Note.ammo[mania]);
					} else {
						daNoteData = FlxG.random.int(0, mania);
					}

	
					var gottaHitNote:Bool = section.mustHitSection;
	
					if (songNotes[1] > (Note.ammo[mania] - 1))
					{
						gottaHitNote = !section.mustHitSection;
					}
	
					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;
	
					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
					
					swagNote.scrollFactor.set();
	
					var susLength:Float = swagNote.sustainLength;
	
					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);
	
					var floorSus:Int = Math.floor(susLength);
	
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
	
							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);
	
							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
							else if(ClientPrefs.middleScroll)
							{
								sustainNote.x += 310;
								if(daNoteData > 1) //Up and Right
								{
									sustainNote.x += FlxG.width / 2 + 25;
								}
							}
						}
					}
	
					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else if(ClientPrefs.middleScroll)
					{
						swagNote.x += 310;
						if(daNoteData > 1) //Up and Right
						{
							swagNote.x += FlxG.width / 2 + 25;
						}
					}
	
					if(!noteTypeMap.exists(swagNote.noteType)) {
						noteTypeMap.set(swagNote.noteType, true);
					}
				}
				daBeats += 1;
			}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					case 'p4' | 'player4' | '3':
						charType = 3;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Philly Glow':
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);


				phillyGlowGradient = new PhillyGlow.PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlow.PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	var arrowJunks:Array<Array<Float>> = [];

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...Note.ammo[mania])
			{
				// FlxG.log.add(i);
				var targetAlpha:Float = 1;
				if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0;
	
				var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
				babyArrow.downScroll = ClientPrefs.downScroll;
				if (!isStoryMode && !skipArrowStartTween)
				{
					//babyArrow.y -= 10;
					babyArrow.alpha = 0;
					FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
				}
				else
				{
					babyArrow.alpha = targetAlpha;
				}
	
				if (player == 1)
				{
					playerStrums.add(babyArrow);
				}
				else if (player == 0)
				{
					if(ClientPrefs.middleScroll)
					{
						var separator:Int = Note.separator[mania];
	
						babyArrow.x += 310;
						if(i > separator) { //Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}
					opponentStrums.add(babyArrow);
				}
				else
				{
					babyArrow.y += 200;
					//trace('thirdStrums babyArrow.y = ' + babyArrow.y);
					//trace('thirdStrums babyArrow.x = ' + babyArrow.x);
					babyArrow.cameras = [camGame];
					babyArrow.scrollFactor.set(1,1);
					//babyArrow.scale.set(0.4, 0.4);
					thirdStrums.add(babyArrow);
				}
	
				strumLineNotes.add(babyArrow);
				babyArrow.postAddedToGroup();
			}
	}

	public function changeMania(newValue:Int)
		{
			//funny dissapear transitions
			//while new strums appear
			if (!isStoryMode)
			{
				for (i in 0...playerStrums.members.length) {
					var oldStrum:FlxSprite = playerStrums.members[i].clone();
					oldStrum.x = playerStrums.members[i].x;
					oldStrum.y = playerStrums.members[i].y;
					oldStrum.alpha = playerStrums.members[i].alpha;
					oldStrum.scrollFactor.set();
					oldStrum.cameras = [camHUD];
					oldStrum.setGraphicSize(Std.int(oldStrum.width * Note.scales[mania]));
					oldStrum.updateHitbox();
					add(oldStrum);
		
					FlxTween.tween(oldStrum, {alpha: 0}, 1, {onComplete: function(_) {
						remove(oldStrum);
					}});
				}
		
				for (i in 0...opponentStrums.members.length) {
					var oldStrum:FlxSprite = opponentStrums.members[i].clone();
					oldStrum.x = opponentStrums.members[i].x;
					oldStrum.y = opponentStrums.members[i].y;
					oldStrum.alpha = opponentStrums.members[i].alpha;
					oldStrum.scrollFactor.set();
					oldStrum.cameras = [camHUD];
					oldStrum.setGraphicSize(Std.int(oldStrum.width * Note.scales[mania]));
					oldStrum.updateHitbox();
					add(oldStrum);
		
					FlxTween.tween(oldStrum, {alpha: 0}, 1, {onComplete: function(_) {
						remove(oldStrum);
					}});
				}
			}
			
			mania = newValue;
	
			playerStrums.clear();
			opponentStrums.clear();
			strumLineNotes.clear();
	
			generateStaticArrows(0);
			generateStaticArrows(1);
		}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				secondaryVocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;
			
			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter(), true);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter(), true);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	public function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		secondaryVocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		secondaryVocals.time = Conductor.songPosition;
		vocals.play();
		secondaryVocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	//really dumb variables
	private var banduJunk:Float = 0;
	private var dadFront:Bool = false;
	private var hasJunked:Bool = false;
	private var wtfThing:Bool = false;
	private var orbit:Bool = false;
	private var orbitSet:Bool = false;
	private var sexBingo:Bool = SONG.enablePlayer4;
	private var setSex:Bool = false;

	override public function update(elapsed:Float)
	{

	//inside update(elapsed)
	grpCrossFade.update(elapsed);
	grpCrossFade.forEachDead(function(img:CrossFade) {
		grpCrossFade.remove(img, true);
	});

	grpP4CrossFade.update(elapsed);
	grpP4CrossFade.forEachDead(function(img:CrossFade) {
		grpP4CrossFade.remove(img, true);
	});

	grpBFCrossFade.update(elapsed);
	grpBFCrossFade.forEachDead(function(img:BFCrossFade) {
		grpBFCrossFade.remove(img, true);
	});

	grpIdiotFade.update(elapsed);
	grpIdiotFade.forEachDead(function(img:CrossFade) {
		grpIdiotFade.remove(img, true);
	});

	//Ghost mode shit -Umbra
	notes.forEachAlive(function(daNote:Note)
		{
			if(ClientPrefs.ghostMode){
				if(ClientPrefs.downScroll){
					if(daNote.y > (FlxG.height / 1.75)){
						//trace('tweeny, ' + 'alpha: ' + daNote.alpha + ' x value: ' + daNote.x);
						FlxTween.tween(daNote,{alpha: 0},0.1);
					} else {
						//trace('no tweeny, ' + 'alpha: ' + daNote.alpha + ' x value: ' + daNote.x);
						daNote.alpha = 1;
					}
				} else {
					if(daNote.y < (FlxG.height / 1.75)){
						//trace('tweeny, ' + 'alpha: ' + daNote.alpha + ' x value: ' + daNote.x);
						FlxTween.tween(daNote,{alpha: 0},0.1);
					} else {
						//trace('no tweeny, ' + 'alpha: ' + daNote.alpha + ' x value: ' + daNote.x);
						daNote.alpha = 1;
					}
				}
			} 
			/*else {
				if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
				else
					{
						daNote.visible = true;
						daNote.active = true;
					}
			}*/
		});

	if (discordUpdateTime > 0){
		discordUpdateTime -= 1;
	}

	//stupid guns shit
	if (SONG.song.toLowerCase() == 'guns' && raiseTankman && dad.y > dad.y - 15) {
		var fps:Float = Main.fpsVar.currentFPS;
		dad.y -= 0.05*240/fps;
	}
	/*if (SONG.song.toLowerCase() == 'guns' && raiseBF && boyfriend.y > boyfriend.y - 15) {
		var fps:Float = Main.fpsVar.currentFPS;
		boyfriend.y -= 0.025*240/fps;
	}*/

	//you cannot escape quartiz
	//if you know how to make this even worse, feel free to do so
	if (quartizTime > 0){
		quartizTime -= 1;
	} else if (ClientPrefs.quartiz) {
		var quartiz:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('quartiz'));
		quartiz.x = FlxG.random.int(0, FlxG.width);
		quartiz.y = FlxG.random.int(0, FlxG.height);
		quartiz.angle = FlxG.random.int(0, 359);
		quartiz.alpha = FlxG.random.float(0.01, 1);
		quartiz.setGraphicSize(Std.int(quartiz.width * FlxG.random.float(0.1, 10)));
		quartiz.color = FlxColor.fromRGB(FlxG.random.int(0, 255), FlxG.random.int(0, 255), FlxG.random.int(0, 255));
		quartiz.antialiasing = FlxG.random.bool(50);
		switch (FlxG.random.int(0,13)) {
			case 0:
				quartiz.blend = BlendMode.ADD;
			case 1:
				quartiz.blend = BlendMode.ALPHA;
			case 2:
				quartiz.blend = BlendMode.DARKEN;
			case 3:
				quartiz.blend = BlendMode.ERASE;
			case 4:
				quartiz.blend = BlendMode.HARDLIGHT;
			case 5:
				quartiz.blend = BlendMode.INVERT;
			case 6:
				quartiz.blend = BlendMode.LAYER;
			case 7:
				quartiz.blend = BlendMode.LIGHTEN;
			case 8:
				quartiz.blend = BlendMode.MULTIPLY;
			case 9:
				quartiz.blend = BlendMode.NORMAL;
			case 10:
				quartiz.blend = BlendMode.OVERLAY;
			case 11:
				quartiz.blend = BlendMode.SCREEN;
			case 12:
				quartiz.blend = BlendMode.SHADER;
			case 13:
				quartiz.blend = BlendMode.SUBTRACT;
		}
		switch (FlxG.random.bool(50)) {
			case true:
				quartiz.cameras = [camHUD];
				quartiz.scrollFactor.set();
			case false:
				quartiz.cameras = [camGame];
				quartiz.scrollFactor.set(FlxG.random.float(0,5), FlxG.random.float(0,5));
		}
		add(quartiz);
		var fps:Float = Main.fpsVar.currentFPS;
		quartizTime = fps * FlxG.random.float(1, 10);
	}

	if(!orbitSet) {
		orbit = dad.orbit;
		orbitSet = true;
	}

	if (discordUpdateTime <= 0)
		{
			#if desktop
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter(), true);
			discordUpdateTime = 100;
			#end
		}

	elapsedtime += elapsed;

	banduJunk += elapsed * 2.5;

	//kinda like genocide, it gradually drains your hp back to normal.
	if(maxHealth > 2) {
		maxHealth -= 0.0066666666666667;
		healthBar.x += 1;
		healthBarMiddle.x = healthBar.x;
		healthBarMiddleHalf.x = healthBar.x;
		healthBarBottom.x = healthBar.x;
	} else {
		if (healthBar.x != (FlxG.width/4) + 4) {
			FlxTween.tween(healthBar, {x: (FlxG.width/4) + 4}, 0.1);
			FlxTween.tween(healthBarMiddle, {x: (FlxG.width/4) + 4}, 0.1);
			FlxTween.tween(healthBarMiddleHalf, {x: (FlxG.width/4) + 4}, 0.1);
			FlxTween.tween(healthBarBottom, {x: (FlxG.width/4) + 4}, 0.1);
		}
		if (maxHealth != 2 && !SONG.dangerMiss) {
			maxHealth = 2;
		}
	}

	if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed' || ClientPrefs.timeBarType == 'Time Elapsed (No Bar)') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
	//hard coded shader cast
	if (curbg != null)
	{
		if (curbg.active)
		{
			var shad = cast(curbg.shader, Shaders.GlitchShader);
			shad.uTime.value[0] += elapsed;
		}
	}
	//lua shader cast
	if (luabg != null)
	{
		if (luabg.active)
		{
			var shad = cast(luabg.shader, Shaders.GlitchShader);
			shad.uTime.value[0] += elapsed;
		}
	}

		FlxG.camera.setFilters([new ShaderFilter(screenshader.shader)]); // this is very stupid but doesn't effect memory all that much so
		if (shakeCam)
		{
			//Help this shit wont work and I dont know why
			//var shad = cast(FlxG.camera.screen.shader, Shaders.PulseShader);
			var shad = cast(FlxG.camera.screen.shader, Shaders.PulseShader);
			FlxG.camera.shake(0.015, 0.015);
		}
		screenshader.shader.uTime.value[0] += elapsed;
		if (shakeCam)
		{
			screenshader.shader.uampmul.value[0] = 1;
		}
		else
		{
			screenshader.shader.uampmul.value[0] -= (elapsed / 2);
		}
		screenshader.Enabled = shakeCam;

		//ooo floating
		if (boyfriend.sarventeFloating && boyfriend.floatMagnitude != null) {
			boyfriend.y += (Math.sin(elapsedtime) * boyfriend.floatMagnitude);
		}

		if (dad.sarventeFloating && dad.floatMagnitude != null) {
			dad.y += (Math.sin(elapsedtime) * dad.floatMagnitude);
		}

		if (player4.sarventeFloating && player4.floatMagnitude != null) {
			player4.y += (Math.sin(elapsedtime) * player4.floatMagnitude);
		}
		//aww hell nah its golden apple code
		if(orbit) {
				dad.x = boyfriend.getMidpoint().x + Math.sin(banduJunk) * 500 - (dad.width / 2);
				dad.y += (Math.sin(elapsedtime) * 0.2);
				dadmirror.setPosition(dad.x, dad.y);

				if ((Math.sin(banduJunk) >= 0.95 || Math.sin(banduJunk) <= -0.95) && !hasJunked){
					dadFront = !dadFront;
					hasJunked = true;
				}
				if (hasJunked && !(Math.sin(banduJunk) >= 0.95 || Math.sin(banduJunk) <= -0.95)) hasJunked = false;

				dadmirror.visible = dadFront;
				dad.visible = !dadFront;
		}

		//actually, do this
			thirdStrums.forEach(function(spr:FlxSprite)
				{
					spr.x = spr.ID*120 + player4.x;
					//trace('spr x: ' + spr.x);
					spr.y = spr.ID - 150 + player4.y;
					//trace('spr y: ' + spr.y);
				});
			notes.forEachAlive(function(spr:Note){
					 if (spr.altNote) {
						spr.x = spr.noteData*120 + 125 + player4.x;
						spr.y = spr.noteData + 150 + player4.y;
					}
				});

		//mod charts do not work with third strum
		//fix this umbra
		switch (curModChart)
		{
			case 'none':
			//do nada
			case 'disruption':
				var krunkThing = 60;

				playerStrums.forEach(function(spr:FlxSprite)
				{
					spr.x = spr.ID*75 + 825 + (Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) * krunkThing;
					spr.y = spr.ID + 25 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing;

					spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1)) / 4;

					spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) / 2);

					spr.scale.x += 0.2;
					spr.scale.y += 0.2;

					spr.scale.x *= 1.5;
					spr.scale.y *= 1.5;
				});
				opponentStrums.forEach(function(spr:FlxSprite)
				{
					spr.x = spr.ID*75 + 125 + (Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) * krunkThing;
					spr.y = spr.ID + 25 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing;
			
					spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1)) / 4;

					spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) / 2);

					spr.scale.x += 0.2;
					spr.scale.y += 0.2;

					spr.scale.x *= 1.5;
					spr.scale.y *= 1.5;
				});
				thirdStrums.forEach(function(spr:FlxSprite)
				{
					spr.x = spr.ID*75 + 125 + (Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) * krunkThing;
					spr.y = spr.ID + 225 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing;
			
					spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1)) / 4;

					spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) / 2);

					spr.scale.x += 0.2;
					spr.scale.y += 0.2;

					spr.scale.x *= 1.5;
					spr.scale.y *= 1.5;
				});

				notes.forEachAlive(function(spr:Note){
					if (spr.mustPress) {
						spr.x = spr.noteData*75 + 825 + (Math.sin(elapsedtime) * ((spr.noteData % 2) == 0 ? 1 : -1)) * krunkThing;
						spr.y = spr.noteData + 25 + Math.sin(elapsedtime - 5) * ((spr.noteData % 2) == 0 ? 1 : -1) * krunkThing;

						spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.noteData % 2) == 0 ? 1 : -1)) / 4;

						spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.noteData % 2) == 0 ? 1 : -1)) / 2);

						spr.scale.x += 0.2;
						spr.scale.y += 0.2;

						spr.scale.x *= 1.5;
						spr.scale.y *= 1.5;
					}
					else if (!spr.altNote) {
						spr.x = spr.noteData*75 + 125 + (Math.sin(elapsedtime) * ((spr.noteData % 2) == 0 ? 1 : -1)) * krunkThing;
						spr.y = spr.noteData + 25 + Math.sin(elapsedtime - 5) * ((spr.noteData % 2) == 0 ? 1 : -1) * krunkThing;

						spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.noteData % 2) == 0 ? 1 : -1)) / 4;

						spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.noteData % 2) == 0 ? 1 : -1)) / 2);

						spr.scale.x += 0.2;
						spr.scale.y += 0.2;

						spr.scale.x *= 1.5;
						spr.scale.y *= 1.5;
					} else {
						spr.x = spr.noteData*75 + 125 + (Math.sin(elapsedtime) * ((spr.noteData % 2) == 0 ? 1 : -1)) * krunkThing;
						spr.y = spr.noteData + 225 + Math.sin(elapsedtime - 5) * ((spr.noteData % 2) == 0 ? 1 : -1) * krunkThing;

						spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.noteData % 2) == 0 ? 1 : -1)) / 4;

						spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.noteData % 2) == 0 ? 1 : -1)) / 2);

						spr.scale.x += 0.2;
						spr.scale.y += 0.2;

						spr.scale.x *= 1.5;
						spr.scale.y *= 1.5;
					}
				});
			//i fucking hate this one
			case 'unfairness':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = ((FlxG.width / 2) - (spr.width / 2)) + (Math.sin(elapsedtime + (spr.ID)) * 300);
						spr.y = ((FlxG.height / 2) - (spr.height / 2)) + (Math.cos(elapsedtime + (spr.ID)) * 300);
					});
					opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = ((FlxG.width / 2) - (spr.width / 2)) + (Math.sin((elapsedtime + (spr.ID )) * 2) * 300);
						spr.y = ((FlxG.height / 2) - (spr.height / 2)) + (Math.cos((elapsedtime + (spr.ID)) * 2) * 300);
					});
			//this one is kinda weird, sometimes it works and sometimes it just uhhh.... goes off screen
			case 'cheating':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x += Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1);
						spr.x -= Math.sin(elapsedtime) * 1.5;
					});
					opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x -= Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1);
						spr.x += Math.sin(elapsedtime) * 1.5;
					});
			//spin :O
			case 'disability':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.angle += (Math.sin(elapsedtime * 2.5) + 1) * 5;
					});
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.angle += (Math.sin(elapsedtime * 2.5) + 1) * 5;
					});
					for(note in notes)
					{
						if(note.mustPress)
						{
							if (!note.isSustainNote)
								note.angle = playerStrums.members[note.noteData].angle;
						}
						else
						{
							if (!note.isSustainNote)
								note.angle = opponentStrums.members[note.noteData].angle;
						}
					}
			//does not work how i want
			case 'wavy':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						if (spr.ID % 2 == 0) {
							spr.y += (Math.sin(elapsedtime) * 0.05);
						} else {
							spr.y -= (Math.sin(elapsedtime) * 0.05);
						}
					});
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						if (spr.ID % 2 == 0) {
							spr.y -= (Math.sin(elapsedtime) * 0.05);
						} else {
							spr.y += (Math.sin(elapsedtime) * 0.05);
						}
					});
				notes.forEachAlive(function(spr:Note){
					if (spr.mustPress) {
						if (spr.ID % 2 == 0) {
							spr.y += (Math.sin(elapsedtime) * 0.05);
						} else {
							spr.y -= (Math.sin(elapsedtime) * 0.05);
						}
					}
					else {
						if (spr.ID % 2 == 0) {
							spr.y -= (Math.sin(elapsedtime) * 0.05);
						} else {
							spr.y += (Math.sin(elapsedtime) * 0.05);
						}
					}
				});
		}

		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if(phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length-1;
					while (i > 0)
					{
						var particle = phillyGlowParticles.members[i];
						if(particle.alpha < 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}
						--i;
					}
				}
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						if(SONG.autoIdles) bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		//its a little broken, but its better than before
		if(!inCutscene) {
			if (moveCamTo[0] == 0 && moveCamTo[1] == 0) {
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			} else {
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x + moveCamTo[0]/100, camFollow.x + moveCamTo[0]/100, lerpVal), FlxMath.lerp(camFollowPos.y + moveCamTo[1]/100, camFollow.y + moveCamTo[1]/100, lerpVal));
				var fps:Float = Main.fpsVar.currentFPS;
				if (ClientPrefs.framerate >= 180) {
					if (moveCamTo[0] < 0) {
						moveCamTo[0] += 0.5*240/fps;
					}
					if (moveCamTo[0] > 0) {
						moveCamTo[0] -= 0.5*240/fps;
					}
					if (moveCamTo[1] < 0) {
						moveCamTo[1] += 0.5*240/fps;
					}
					if (moveCamTo[1] > 0) {
						moveCamTo[1] -= 0.5*240/fps;
					}
				}
				if (ClientPrefs.framerate < 180 && ClientPrefs.framerate >= 100) {
					if (moveCamTo[0] < 0) {
						moveCamTo[0] += 0.5*100/fps;
					}
					if (moveCamTo[0] > 0) {
						moveCamTo[0] -= 0.5*100/fps;
					}
					if (moveCamTo[1] < 0) {
						moveCamTo[1] += 0.5*100/fps;
					}
					if (moveCamTo[1] > 0) {
						moveCamTo[1] -= 0.5*100/fps;
					}
				}
				if (ClientPrefs.framerate < 100) {
					if (moveCamTo[0] < 0) {
						moveCamTo[0] += 0.5*50/fps;
					}
					if (moveCamTo[0] > 0) {
						moveCamTo[0] -= 0.5*50/fps;
					}
					if (moveCamTo[1] < 0) {
						moveCamTo[1] += 0.5*50/fps;
					}
					if (moveCamTo[1] > 0) {
						moveCamTo[1] -= 0.5*50/fps;
					}
				}
			}
			if(!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}
		
				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		//this is for the lerp swapping
		switch (curIconSwing)
		{
			case 'Old':
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));
				iconP4.setGraphicSize(Std.int(FlxMath.lerp(115, iconP4.width, 0.50)));

				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Stretch':
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.8)),Std.int(FlxMath.lerp(150, iconP1.height, 0.8)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.8)),Std.int(FlxMath.lerp(150, iconP2.height, 0.8)));
				iconP4.setGraphicSize(Std.int(FlxMath.lerp(115, iconP4.width, 0.8)),Std.int(FlxMath.lerp(115, iconP4.height, 0.8)));
		
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Squish' | 'Swing Mild' | 'Angle Snap':
				//sex
			default:
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
				iconP1.scale.set(mult, mult);
				iconP1.updateHitbox();
		
				var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
				iconP2.scale.set(mult, mult);
				iconP2.updateHitbox();

				var mult:Float = FlxMath.lerp(0.75, iconP4.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
				iconP4.scale.set(mult, mult);
				iconP4.updateHitbox();
		}

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		iconP4.x = healthBar.x + ((healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP4.scale.x) / 2 - iconOffset * 2) - 80;

		if (health > maxHealth)
			health = maxHealth;

		//optimization! hell yeah!
		if(lastHealth != health) {
			lastHealth = health;
			recalculateIconAnimations();
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(defaultHudCamZoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		//we dont need to watch most of these
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		//FlxG.watch.addQuick("flinchShit", flinching);
		//FlxG.watch.addQuick("elapsedShit", elapsedtime);
		//FlxG.watch.addQuick("DSupdateShit", discordUpdateTime);
		//FlxG.watch.addQuick("healthShit", health);
		//FlxG.watch.addQuick("maxHealthShit", maxHealth);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();
		if (curSong.toLowerCase() == 'furiosity')
			{
				screenshader.shader.uampmul.value[0] = 0;
				screenshader.Enabled = false;
			}
		switch (SONG.song.toLowerCase())
		{
			case 'polygonized':
				switch(curStep)
				{
					case 1024 | 1312 | 1424 | 1552 | 1664:
						shakeCam = true;
						camZooming = true;
					case 1152 | 1408 | 1472 | 1600 | 2048 | 2176:
						shakeCam = false;
						camZooming = false;
				}
		}
		if (shakeCam)
		{
			gf.playAnim('scared', true);
		}


		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss') && SONG.autoIdles) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;
				if(daNote.altNote) {
					strumGroup = thirdStrums;
					daNote.cameras = [camGame];
					daNote.scrollFactor.set(1,1);
				}

				
				if (mania != SONG.mania && !daNote.isSustainNote) {
					daNote.applyManiaChange();
				}

				if (strumGroup.members[daNote.noteData] == null) daNote.noteData = mania;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;
				var strumHeight:Float = strumGroup.members[daNote.noteData].height;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;
				
				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						} 
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1) * Note.scales[mania];
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote && !daNote.altNote)
				{
					opponentNoteHit(daNote);
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.altNote)
				{
					thirdNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}
				
				var center:Float = strumY + strumHeight / 2;
				if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
			if (FlxG.keys.justPressed.THREE) {
				debugDisplay = !debugDisplay;
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	public function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				secondaryVocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")" + " Rating " + ratingText, iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
			
			case 'Philly Glow':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlow.PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlow.PhillyGlowParticle = new PhillyGlow.PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					case 'p4' | 'player4':
						char = player4;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;
		
						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					case 'p4' | 'player4':
						char = player4;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
					if (char == dad) {
						dadmirror.idleSuffix = value2;
						dadmirror.recalculateDanceIdle();
					}
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Mania':
				var newMania:Int = 0;
	
				newMania = Std.parseInt(value1);
				if(Math.isNaN(newMania) && newMania < 0 && newMania > 9)
					newMania = 0;
	
				changeMania(newMania);

			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					case 'p4' | 'player4':
						charType = 3;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);
						reloadHealthBarColors(false);
						recalculateIconAnimations();

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);
						reloadHealthBarColors(false);
						recalculateIconAnimations();

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
							reloadHealthBarColors(false);
							recalculateIconAnimations();
						}
					
					case 3:
						if(player4.curCharacter != value2) {
							if(!player4Map.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = player4.curCharacter.startsWith('gf');
							var lastAlpha:Float = player4.alpha;
							player4.alpha = 0.00001;
							player4 = player4Map.get(value2);
							if(!player4.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							player4.alpha = lastAlpha;
							if (SONG.notes[Std.int(curStep / 16)].player4Section) {
								if (iconP2 != null && iconP4 != null) {
									iconP4.changeIcon(dad.healthIcon);
									iconP2.changeIcon(player4.healthIcon);
									reloadHealthBarColors(true);
									recalculateIconAnimations();
								}
							} else {
								if (iconP2 != null && iconP4 != null) {
									iconP2.changeIcon(dad.healthIcon);
									iconP4.changeIcon(player4.healthIcon);
									reloadHealthBarColors(false);
									recalculateIconAnimations();
								}
							}
						}
						setOnLuas('dadName', dad.curCharacter);
						reloadHealthBarColors(true);
				}
			
			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			//note to self: make this reset the values... properly *cough* x and y *cough*
			case 'Change Modchart':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.angle = 0;
						switch (SONG.mania)
						{
							case 0:
								spr.scale.x = 0.9;
								spr.scale.y = 0.9;
							case 1:
								spr.scale.x = 0.85;
								spr.scale.y = 0.85;
							case 2:
								spr.scale.x = 0.8;
								spr.scale.y = 0.8;
							case 3:
								spr.scale.x = 0.7;
								spr.scale.y = 0.7;
							case 4:
								spr.scale.x = 0.66;
								spr.scale.y = 0.66;
							case 5:
								spr.scale.x = 0.6;
								spr.scale.y = 0.6;
							case 6:
								spr.scale.x = 0.55;
								spr.scale.y = 0.55;
							case 7:
								spr.scale.x = 0.5;
								spr.scale.y = 0.5;
							case 8:
								spr.scale.x = 0.46;
								spr.scale.y = 0.46;
							case 9:
								spr.scale.x = 0.39;
								spr.scale.y = 0.39;
							case 10:
								spr.scale.x = 0.36;
								spr.scale.y = 0.36;
						}
					});
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.angle = 0;
						switch (SONG.mania)
						{
							case 0:
								spr.scale.x = 0.9;
								spr.scale.y = 0.9;
							case 1:
								spr.scale.x = 0.85;
								spr.scale.y = 0.85;
							case 2:
								spr.scale.x = 0.8;
								spr.scale.y = 0.8;
							case 3:
								spr.scale.x = 0.7;
								spr.scale.y = 0.7;
							case 4:
								spr.scale.x = 0.66;
								spr.scale.y = 0.66;
							case 5:
								spr.scale.x = 0.6;
								spr.scale.y = 0.6;
							case 6:
								spr.scale.x = 0.55;
								spr.scale.y = 0.55;
							case 7:
								spr.scale.x = 0.5;
								spr.scale.y = 0.5;
							case 8:
								spr.scale.x = 0.46;
								spr.scale.y = 0.46;
							case 9:
								spr.scale.x = 0.39;
								spr.scale.y = 0.39;
							case 10:
								spr.scale.x = 0.36;
								spr.scale.y = 0.36;
						}
					});
					for(note in notes)
					{
						if(note.mustPress)
						{
							if (!note.isSustainNote)
								note.angle = playerStrums.members[note.noteData].angle;
								note.scale.x = playerStrums.members[note.noteData].scale.x;
								note.scale.y = playerStrums.members[note.noteData].scale.y;
						}
						else
						{
							if (!note.isSustainNote)
								note.angle = opponentStrums.members[note.noteData].angle;
								note.scale.x = opponentStrums.members[note.noteData].scale.x;
								note.scale.y = opponentStrums.members[note.noteData].scale.y;
						}
					}
				curModChart = value1;

			case 'Toggle Botplay':
				switch (value1)
				{
					case '0':
						cpuControlled = !cpuControlled;
						botplayTxt.visible = cpuControlled;
						if(noBotplay != null) {
							if (screwYou.visible == false) {
								noBotplay.y = FlxG.height - 44;
								noBotplay.visible = !cpuControlled;
							} else {
								noBotplay.y = FlxG.height - 64;
								noBotplay.visible = !cpuControlled;
							}
						}
					case '1':
						cpuControlled = false;
						botplayTxt.visible = cpuControlled;
						if(noBotplay != null) {
							if (screwYou.visible == false) {
								noBotplay.y = FlxG.height - 44;
								noBotplay.visible = !cpuControlled;
							} else {
								noBotplay.y = FlxG.height - 64;
								noBotplay.visible = !cpuControlled;
							}
						}
					case '2':
						cpuControlled = true;
						botplayTxt.visible = cpuControlled;
						if(noBotplay != null) {
							if (screwYou.visible == false) {
								noBotplay.y = FlxG.height - 44;
								noBotplay.visible = !cpuControlled;
							} else {
								noBotplay.y = FlxG.height - 64;
								noBotplay.visible = !cpuControlled;
							}
						}
					default:
						cpuControlled = !cpuControlled;
						botplayTxt.visible = cpuControlled;
						if(noBotplay != null) {
							if (screwYou.visible == false) {
								noBotplay.y = FlxG.height - 44;
								noBotplay.visible = !cpuControlled;
							} else {
								noBotplay.y = FlxG.height - 64;
								noBotplay.visible = !cpuControlled;
							}
						}
				}

			
			case 'Toggle Ghost Tapping':
				switch (value1)
				{
					case '0':
						tappy = !tappy;
						if(screwYou != null) {
							screwYou.visible = !tappy;
						}
					case '1':
						tappy = false;
						if(screwYou != null) {
							screwYou.visible = !tappy;
						}
					case '2':
						tappy = true;
						if(screwYou != null) {
							screwYou.visible = !tappy;
						}
					default:
						tappy = !tappy;
						if(screwYou != null) {
							screwYou.visible = !tappy;
						}
				}


			case 'Stage Tint':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				var tint:FlxSprite = new FlxSprite(-500, -500).makeGraphic(FlxG.width*4, FlxG.height*4, FlxColor.BLACK);
				tint.alpha = 0;
				tint.scrollFactor.set();
				idiotGroup.add(tint);
				FlxTween.tween(tint, {alpha: val1}, 0.25);
				new FlxTimer().start(val2, function(tmr:FlxTimer) {
					FlxTween.tween(tint, {alpha: 0}, 0.25, {
						onComplete: 
						function (twn:FlxTween)
							{
								tint.kill();
								idiotGroup.remove(tint, true);
								tint.destroy();
							}
					});
				});
			
			
			case 'Swap Hud':
				if (!hudIsSwapped) {
					playerStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x - 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x + 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					//iconP1.changeIcon(dad.healthIcon);
					//iconP2.changeIcon(boyfriend.healthIcon);
					hudIsSwapped = true;
					//reloadHealthBarColors(false);
					//recalculateIconAnimations();
				} else {
					playerStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x + 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x - 650}, 0.1, {
							ease: FlxEase.circOut
						});
					});
					//iconP2.changeIcon(dad.healthIcon);
					//iconP1.changeIcon(boyfriend.healthIcon);
					hudIsSwapped = false;
					//reloadHealthBarColors(false);
					//recalculateIconAnimations();
				}


			/*case 'Spacebar Dodge':
				*/

			//i totally didnt need to do this but its here
			case 'Flash Camera':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				FlxG.camera.flash(val2, val1);

			case 'Flash Camera (HUD)':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				camHUD.flash(val2, val1);

			
			case 'Set Cam Speed':
				var val1:Null<Float> = Std.parseFloat(value1);
				cameraSpeed = val1;

			//this will be abused
			case 'Tween Hud Angle':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				var angleTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					angleTween = FlxTween.tween(camHUD, {angle: val1}, val2, {
						ease: FlxEase.circInOut
					});
				}
			
			case 'Tween Hud Zoom':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				var zoomTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					zoomTween = FlxTween.tween(camHUD, {zoom: val1}, val2, {
						ease: FlxEase.circInOut,
						onComplete: 
						function (twn:FlxTween)
							{
								defaultHudCamZoom = val1;
							}
					});
				}
			
			case 'Tween Camera Angle':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				var angleTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					angleTween = FlxTween.tween(camGame, {angle: val1}, val2, {
						ease: FlxEase.circInOut
					});
				}
			
			case 'Tween Camera Zoom':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				var zoomTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					zoomTween = FlxTween.tween(camGame, {zoom: val1}, val2, {
						ease: FlxEase.circInOut,
						onComplete: 
						function (twn:FlxTween)
							{
								defaultCamZoom = val1;
							}
					});
				}

			//rework beatmaps eventually to be actual beatmaps
			case 'BM:Camera Zoom':
				if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
			
			case 'BM:Character Dance':
				if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					if (ClientPrefs.opponentAlwaysDance) {
						dad.dance();
						dadmirror.dance();
					} else if (!ClientPrefs.opponentAlwaysDance && SONG.notes[Std.int(curStep / 16)].mustHitSection) {
						dad.dance();
						dadmirror.dance();
					}
				}
				if (curBeat % player4.danceEveryNumBeats == 0 && player4.animation.curAnim != null && !player4.animation.curAnim.name.startsWith('sing') && !player4.stunned)
				{
					player4.dance();
				}
				if (littleIdiot != null && littleIdiot.visible == true) {
					if (curBeat % littleIdiot.danceEveryNumBeats == 0 && littleIdiot.animation.curAnim != null && !littleIdiot.animation.curAnim.name.startsWith('sing') && !littleIdiot.stunned)
						{
							littleIdiot.dance();
						}
				}


				switch (curStage)
				{
					case 'school':
						if(!ClientPrefs.lowQuality) {
							bgGirls.dance();
						}

					case 'mall':
						if(!ClientPrefs.lowQuality) {
							upperBoppers.dance();
						}

						if(heyTimer <= 0) bottomBoppers.dance();
						santa.dance();

					case 'limo':
						if(!ClientPrefs.lowQuality) {
							grpLimoDancers.forEach(function(dancer:BackgroundDancer)
							{
								dancer.dance();
							});
						}
				}

			case 'BM:Icon Bop':
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
				iconP4.scale.set(1, 1);
		
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();

			case 'BM:Icon Snap':
				if (swingDirection) {
						iconP1.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);
						iconP4.scale.set(0.85, 1.1);
		
						iconP1.angle = -15;
						iconP2.angle = 15;
						iconP4.angle = 15;
						swingDirection = false;
					} else {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						iconP4.scale.set(0.85, 0.65);
		
						iconP2.angle = -15;
						iconP4.angle = -15;
						iconP1.angle = 15;
						swingDirection = true;
					}
		
					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		
					iconP1.updateHitbox();
					iconP2.updateHitbox();
					iconP4.updateHitbox();
			
			case 'BM:Icon Swing':
				if (swingDirection) {
						iconP1.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);
						iconP4.scale.set(0.85, 1.1);
		
						FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP4, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						swingDirection = false;
					} else {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						iconP4.scale.set(0.85, 0.65);
		
						FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP4, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
						swingDirection = true;
					}
		
					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		
					iconP1.updateHitbox();
					iconP2.updateHitbox();
					iconP4.updateHitbox();

			case 'BM:Stage':
			
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			if (iconP2 != null && iconP4 != null) {
				iconP2.changeIcon(gf.healthIcon);
				iconP4.changeIcon(dad.healthIcon);
				reloadHealthBarColors(false, true);
				recalculateIconAnimations();
			}
			/*if (hudIsSwapped) {
				if (iconP1 != null && iconP4 != null && iconP2 != null) {
					iconP1.changeIcon(gf.healthIcon);
					iconP2.changeIcon(boyfriend.healthIcon);
					iconP4.changeIcon(dad.healthIcon);
					reloadHealthBarColors(false, true);
					recalculateIconAnimations();
				}
			}*/
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			if (!SONG.notes[id].player4Section)
			{
				moveCamera(true, false);
				callOnLuas('onMoveCamera', ['dad']);
			} else {
				moveCamera(true, true);
				callOnLuas('onMoveCamera', ['p4']);
			}
		}
		else
		{
			moveCamera(false, false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
		//sex icons
		if (iconP2 != null && iconP4 != null) {
			iconP2.changeIcon(dad.healthIcon);
			iconP4.changeIcon(player4.healthIcon);
			reloadHealthBarColors(false);
			recalculateIconAnimations();
		}
		/*if (hudIsSwapped) {
			if (iconP1 != null && iconP4 != null && iconP2 != null) {
				iconP1.changeIcon(dad.healthIcon);
				iconP2.changeIcon(boyfriend.healthIcon);
				iconP4.changeIcon(player4.healthIcon);
				reloadHealthBarColors(false);
				recalculateIconAnimations();
			}
		}*/
		if (SONG.notes[id].player4Section) {
			/*switch (hudIsSwapped) {
				case true:*/
					if (iconP1 != null && iconP4 != null && iconP2 != null) {
						iconP4.changeIcon(dad.healthIcon);
						iconP1.changeIcon(player4.healthIcon);
						iconP2.changeIcon(boyfriend.healthIcon);
						reloadHealthBarColors(true);
						recalculateIconAnimations();
					}
				/*case false:
					if (iconP2 != null && iconP4 != null) {
						iconP4.changeIcon(dad.healthIcon);
						iconP2.changeIcon(player4.healthIcon);
						reloadHealthBarColors(true);
						recalculateIconAnimations();
					}
			}*/
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool, focusP4:Bool)
	{
			if (!focusP4) {
				if(isDad)
					{
						camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
						camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
						tweenCamIn();
					}
					else
					{
						camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
						camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			
						if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
						{
							cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
								function (twn:FlxTween)
								{
									cameraTwn = null;
								}
							});
						}
					}
			} else {
				if(isDad)
					{
						camFollow.set(player4.getMidpoint().x + 150, player4.getMidpoint().y - 100);
						camFollow.x += player4.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y += player4.cameraPosition[1] + opponentCameraOffset[1];
						tweenCamIn();
					}
					else
					{
						camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
						camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			
						if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
						{
							cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
								function (twn:FlxTween)
								{
									cameraTwn = null;
								}
							});
						}
					}
			}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	//^ maybe try doing some bullshit
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		PauseSubState.transferPlayState = false;

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		secondaryVocals.volume = 0;
		vocals.pause();
		secondaryVocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}
		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end
		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				var letter:String = ratingName;
				var intensity:String = ratingIntensity;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent, ratingName, ratingIntensity);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
					Conductor.changeBPM(100);

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var curDifficulty:Int = -1;
					var lastDifficultyName:String = '';
					if(lastDifficultyName == '')
						{
							lastDifficultyName = CoolUtil.defaultDifficulty;
						}
					curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

					var songLowercase:String = Paths.formatToSongPath(PlayState.storyPlaylist[0]);
					var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
					#if desktop
					if(sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))){
						var difficulty:String = CoolUtil.getDifficultyFilePath();

						trace('LOADING NEXT SONG');
						trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);
	
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;
	
						prevCamFollow = camFollow;
						prevCamFollowPos = camFollowPos;
	
						PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
						FlxG.sound.music.stop();
	
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
					else{
						trace('Failed to load next story song: incorrect .json!');
						cancelMusicFadeTween();
						if(FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}
						MusicBeatState.switchState(new StoryMenuState());
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
						Conductor.changeBPM(100);
						changedDifficulty = false;
					}
					#else
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
					#end

				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				WeekData.loadTheFirstEnabledMod();
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				Conductor.changeBPM(100);
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	public function cachePopUpScore()
		{
			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';
			var skinShit:String = '';
	
			if (PlayState.isPixelStage)
			{
				pixelShitPart1 = 'pixelUI/';
				pixelShitPart2 = '-pixel';
				var skinShit:String = '';
			} else {
				skinShit = '-' + ClientPrefs.uiSkin;
			}
	
			Paths.image(pixelShitPart1 + "perfect" + pixelShitPart2 + skinShit);
			Paths.image(pixelShitPart1 + "sick" + pixelShitPart2 + skinShit);
			Paths.image(pixelShitPart1 + "good" + pixelShitPart2 + skinShit);
			Paths.image(pixelShitPart1 + "bad" + pixelShitPart2 + skinShit);
			Paths.image(pixelShitPart1 + "shit" + pixelShitPart2 + skinShit);
			Paths.image(pixelShitPart1 + "wtf" + pixelShitPart2 + skinShit);
			Paths.image(pixelShitPart1 + "combo" + pixelShitPart2 + skinShit);
			
			for (i in 0...10) {
				Paths.image(pixelShitPart1 + 'num' + i + pixelShitPart2);
			}
		}

	public function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		var msTiming:Float = note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset;
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;
		secondaryVocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String;
		if(!cpuControlled){
		daRating = Conductor.judgeNote(note, noteDiff);
		}else{
		daRating = Conductor.botJudgeNote(note, noteDiff);
		}

		var epicsex:String = ClientPrefs.ratingIntensity;
		var scoreMulti:Float = 1;
		var scoreDivi:Float = 1;
		switch (epicsex) {
			case 'Default':
				scoreMulti = 1;
				scoreDivi = 1;
			case 'Harsh':
				scoreMulti = 1;
				scoreDivi = 1;
			case 'Generous':
				scoreMulti = 1;
				scoreDivi = 1;
		}
		switch (daRating)
		{
			case "wtf": // wtf
				totalNotesHit += 0;
				note.ratingMod = 0;
				score = Math.floor((-100 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) wtfs++;
			case "shit": // shit
				if (ClientPrefs.accuracyMode == 'Complex') {
					totalNotesHit += -(noteDiff/205 - 1);
				} else {
					totalNotesHit += 0.25;
				}
				note.ratingMod = 0.25;
				score = Math.floor((-50 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) shits++;
			case "bad": // bad
				if (ClientPrefs.accuracyMode == 'Complex') {
					totalNotesHit += -(noteDiff/205 - 1);
				} else {
					totalNotesHit += 0.5;
				}
				note.ratingMod = 0.5;
				score = Math.floor((50 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) bads++;
			case "good": // good
				if (ClientPrefs.accuracyMode == 'Complex') {
					totalNotesHit += -(noteDiff/205 - 1);
				} else {
					totalNotesHit += 0.75;
				}
				note.ratingMod = 0.75;
				score = Math.floor((200 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) goods++;
			case "sick": // sick
				if (ClientPrefs.accuracyMode == 'Complex') {
					totalNotesHit += -(noteDiff/205 - 1);
				} else {
					totalNotesHit += 0.95;
				}
				note.ratingMod = 0.95;
				score = Math.floor((350 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) sicks++;
			case "perfect": // perfect
				if (ClientPrefs.accuracyMode == 'Complex') {
					totalNotesHit += -(noteDiff/205 - 1);
				} else {
					totalNotesHit += 1;
				}
				note.ratingMod = 1;
				//so we do something with the mstimings, where we divide it by 100, so 100 ms would be 1, then we subtract 1 from it. BOOM, accurate accuracy
				//though, 100 is not enough, it should be more like 300 or smth
				//nvm, its 205
				score = Math.floor((600 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) perfects++;
		}
		note.rating = daRating;

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		} else if (daRating == 'perfect' && !note.noteSplashDisabled) {
			spawnNoteSplashOnNote(note);
		}
		switch (epicsex) {
			case 'Default':
				if(daRating == 'wtf' || daRating == 'shit') {
					if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
						{
							gf.playAnim('sad');
						}
						combo = 0;
						songMisses++;
				}
			case 'Harsh':
				if(daRating == 'wtf' || daRating == 'shit' || daRating == 'bad') {
					if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
						{
							gf.playAnim('sad');
						}
						combo = 0;
						songMisses++;
				}
		}


		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
				#if desktop
				ratingText = ratingName + " " + ratingFC;
				#end
			}

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
					deathTxtTween.cancel();
					sarvRightTxtTween.cancel();
				}
				switch(daRating)
				{
					case 'wtf':
						scoreTxt.scale.x = 0.875;
						scoreTxt.scale.y = 0.875;
						scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								scoreTxtTween = null;
							}
						});
						deathTxt.scale.x = 0.875;
						deathTxt.scale.y = 0.875;
						deathTxtTween = FlxTween.tween(deathTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								deathTxtTween = null;
							}
						});
						sarvRightTxt.scale.x = 0.875;
						sarvRightTxt.scale.y = 0.875;
						sarvRightTxtTween = FlxTween.tween(sarvRightTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								sarvRightTxtTween = null;
							}
						});
					case 'shit':
						scoreTxt.scale.x = 0.925;
						scoreTxt.scale.y = 0.925;
						scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								scoreTxtTween = null;
							}
						});
						deathTxt.scale.x = 0.925;
						deathTxt.scale.y = 0.925;
						deathTxtTween = FlxTween.tween(deathTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								deathTxtTween = null;
							}
						});
						sarvRightTxt.scale.x = 0.925;
						sarvRightTxt.scale.y = 0.925;
						sarvRightTxtTween = FlxTween.tween(sarvRightTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								sarvRightTxtTween = null;
							}
						});
					case 'bad':
						scoreTxt.scale.x = 0.975;
						scoreTxt.scale.y = 0.975;
						scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								scoreTxtTween = null;
							}
						});
						deathTxt.scale.x = 0.975;
						deathTxt.scale.y = 0.975;
						deathTxtTween = FlxTween.tween(deathTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								deathTxtTween = null;
							}
						});
						sarvRightTxt.scale.x = 0.975;
						sarvRightTxt.scale.y = 0.975;
						sarvRightTxtTween = FlxTween.tween(sarvRightTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								sarvRightTxtTween = null;
							}
						});
					case 'good':
						scoreTxt.scale.x = 1.025;
						scoreTxt.scale.y = 1.025;
						scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								scoreTxtTween = null;
							}
						});
						deathTxt.scale.x = 1.025;
						deathTxt.scale.y = 1.025;
						deathTxtTween = FlxTween.tween(deathTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								deathTxtTween = null;
							}
						});
						sarvRightTxt.scale.x = 1.025;
						sarvRightTxt.scale.y = 1.025;
						sarvRightTxtTween = FlxTween.tween(sarvRightTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								sarvRightTxtTween = null;
							}
						});
					case 'sick':
						scoreTxt.scale.x = 1.075;
						scoreTxt.scale.y = 1.075;
						scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								scoreTxtTween = null;
							}
						});
						deathTxt.scale.x = 1.075;
						deathTxt.scale.y = 1.075;
						deathTxtTween = FlxTween.tween(deathTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								deathTxtTween = null;
							}
						});
						sarvRightTxt.scale.x = 1.075;
						sarvRightTxt.scale.y = 1.075;
						sarvRightTxtTween = FlxTween.tween(sarvRightTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								sarvRightTxtTween = null;
							}
						});
					case 'perfect':
						scoreTxt.scale.x = 1.125;
						scoreTxt.scale.y = 1.125;
						scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								scoreTxtTween = null;
							}
						});
						deathTxt.scale.x = 1.125;
						deathTxt.scale.y = 1.125;
						deathTxtTween = FlxTween.tween(deathTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								deathTxtTween = null;
							}
						});
						sarvRightTxt.scale.x = 1.125;
						sarvRightTxt.scale.y = 1.125;
						sarvRightTxtTween = FlxTween.tween(sarvRightTxt.scale, {x: 1, y: 1}, 0.2, {
							onComplete: function(twn:FlxTween) {
								sarvRightTxtTween = null;
							}
						});
				}

			}
		}

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';
		var skinShit:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
			var skinShit:String = '';
		} else {
			skinShit = '-' + ClientPrefs.uiSkin;
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2 + skinShit));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2 + skinShit));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = FlxG.random.int(200, 300);
		comboSpr.velocity.y -= FlxG.random.int(140, 160);
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];

		comboSpr.y += 60;
		if (combo >= 100) comboSpr.x += 35;
		if (combo >= 1000) comboSpr.x += 70;
		if (combo >= 10000) comboSpr.x += 105;
		if (combo >= 100000) comboSpr.x += 140;
		comboSpr.velocity.x += FlxG.random.int(1, 10);

		msTxt.x = 408 + 250;
		msTxt.y = 290 - 25;
		if (PlayState.isPixelStage) {
			msTxt.x = 408 + 260;
			msTxt.y = 290 + 20;
		}
		msTxt.x += ClientPrefs.comboOffset[0];
		msTxt.y -= ClientPrefs.comboOffset[1];
		msTxt.text = FlxMath.roundDecimal(-msTiming, ClientPrefs.msPrecision) + " MS";
		if (msTimer != null) msTimer.cancel();
		msTimer = new FlxTimer().start(0.2 + (Conductor.crochet * 0.0005), function(tmr:FlxTimer) {
			msTxt.text = '';
		});
		switch (daRating) {
			case 'perfect':
				msTxt.setFormat("VCR OSD Mono", 20, FlxColor.YELLOW, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			case 'sick':
				msTxt.setFormat("VCR OSD Mono", 20, FlxColor.CYAN, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			case 'good':
				msTxt.setFormat("VCR OSD Mono", 20, FlxColor.LIME, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			case 'bad':
				msTxt.setFormat("VCR OSD Mono", 20, FlxColor.ORANGE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			case 'shit':
				msTxt.setFormat("VCR OSD Mono", 20, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			case 'wtf':
				msTxt.setFormat("VCR OSD Mono", 20, FlxColor.PURPLE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			default:
				msTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		}

		if(combo >= 10 && ClientPrefs.comboPopup) insert(members.indexOf(strumLineNotes), comboSpr);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var crit = FlxG.random.bool(1); //0.3
		if(crit && SONG.crits) {
			if(maxHealth < 3) {
				maxHealth += 0.2;
				health += 0.2;
				healthBar.x -= 30;
				FlxG.sound.play(Paths.sound('crit'), FlxG.random.float(0.1, 0.2));
			}

			var numBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'critBG' + pixelShitPart2 + skinShit));
			numBG.cameras = [camHUD];
			numBG.screenCenter();
			numBG.x = coolText.x - 150;
			numBG.y += 80;

			numBG.x += ClientPrefs.comboOffset[2];
			numBG.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
				{
					numBG.antialiasing = ClientPrefs.globalAntialiasing;
					numBG.setGraphicSize(Std.int(numBG.width * 0.6));
					if (combo >= 10) numBG.setGraphicSize(Std.int(numBG.width * 0.7));
					if (combo >= 100) numBG.setGraphicSize(Std.int(numBG.width * 0.8));
					if (combo >= 1000) numBG.setGraphicSize(Std.int(numBG.width * 0.9));
					if (combo >= 10000) numBG.setGraphicSize(Std.int(numBG.width * 1));
					if (combo >= 100000) numBG.setGraphicSize(Std.int(numBG.width * 1.1));
				}
				else
				{
					numBG.setGraphicSize(Std.int(numBG.width * daPixelZoom));
				}
				numBG.updateHitbox();
			
			numBG.acceleration.y = FlxG.random.int(200, 300);
			numBG.velocity.y -= FlxG.random.int(140, 160);
			numBG.velocity.x = FlxG.random.float(-5, 5);
			numBG.visible = !ClientPrefs.hideHud;

			insert(members.indexOf(strumLineNotes), numBG);
			
			FlxTween.tween(numBG, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numBG.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});
		}

		var seperatedScore:Array<Int> = [];

		if(combo >= 100000) {
			seperatedScore.push(Math.floor(combo / 100000) % 10);
		}
		if(combo >= 10000) {
			seperatedScore.push(Math.floor(combo / 10000) % 10);
		}
		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		if(combo >= 100) {
			seperatedScore.push(Math.floor(combo / 100) % 10);
		}
		if(combo >= 10) {
			seperatedScore.push(Math.floor(combo / 10) % 10);
		}
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var extraShit:String = "";
			var extraShit2:String = "";

			if (!PlayState.isPixelStage) extraShit = "nums/";
			if (skinShit == '-kade') {
				extraShit2 = '-fnf';
				//trace('swapped to -fnf to save resources');
			} else {
				extraShit2 = skinShit;
				//trace('did not swap to -fnf to save resources');
			}
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(extraShit + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2 + extraShit2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.002
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002
		});
	}

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !tappy;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						if (!ClientPrefs.noAntimash) {	//shut up
							canMiss = true;
						}
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}
				else if (!canMiss && ClientPrefs.gsmiss)
					{
						noteMissPress2(key);
					}
				else if (!canMiss && !ClientPrefs.gsmiss)
					{
						noteMissPress3(key);
					}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}
	
	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	public function getKeyFromEvent(key:FlxKey):Int
		{
			if(key != NONE)
			{
				for (i in 0...keysArray[mania].length)
				{
					for (j in 0...keysArray[mania][i].length)
					{
						if(key == keysArray[mania][i][j])
						{
							return i;
						}
					}
				}
			}
			return -1;
		}

		public function keysArePressed():Bool
			{
				for (i in 0...keysArray[mania].length) {
					for (j in 0...keysArray[mania][i].length) {
						if (FlxG.keys.checkStatus(keysArray[mania][i][j], PRESSED)) return true;
					}
				}
		
				return false;
			}
		
			public function dataKeyIsPressed(data:Int):Bool
			{
				for (i in 0...keysArray[mania][data].length) {
					if (FlxG.keys.checkStatus(keysArray[mania][data][i], PRESSED)) return true;
				}
		
				return false;
			}
		
				#if android
			public function hitboxKeysArePressed():Bool
			{
					if (_hitbox.array[mania].pressed) 
						{
					return true;
				}
				return false;
			}
		
			public function hitboxDataKeyIsPressed(data:Int):Bool
			{
				if (_hitbox.array[data].pressed) 
						{
								return true;
						}
				return false;
			}
				#end
		
	// Hold notes
	public function keyShit():Void
	{
		var curInputType:String = ClientPrefs.inputType;
		switch (curInputType)
		{
			case 'Psych':
				// HOLDING
				var up = controls.NOTE_UP;
				var right = controls.NOTE_RIGHT;
				var down = controls.NOTE_DOWN;
				var left = controls.NOTE_LEFT;
				var controlHoldArray:Array<Bool> = [left, down, up, right];
		
				// TO DO: Find a better way to handle controller inputs, this should work for now
				if(ClientPrefs.controllerMode)
				{
					var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
					if(controlArray.contains(true))
					{
						for (i in 0...controlArray.length)
						{
							if(controlArray[i])
								onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
						}
					}
				}

				// FlxG.watch.addQuick('asdfa', upP);
				if (!boyfriend.stunned && generatedMusic)
				{
					// rewritten inputs???
					notes.forEachAlive(function(daNote:Note)
					{
						// hold note functions
						if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
						&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
							goodNoteHit(daNote);
						}
					});

					if (controlHoldArray.contains(true) && !endingSong) {
						#if ACHIEVEMENTS_ALLOWED
						var achieve:String = checkForAchievement(['oversinging']);
						if (achieve != null) {
							startAchievement(achieve);
						}
						#end
					}
					else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss') && SONG.autoIdles)
					{
						boyfriend.dance();
						//boyfriend.animation.curAnim.finish();
					}
				}

				// TO DO: Find a better way to handle controller inputs, this should work for now
				if(ClientPrefs.controllerMode)
				{
					var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
					if(controlArray.contains(true))
					{
						for (i in 0...controlArray.length)
						{
							if(controlArray[i])
								onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
						}
					}
				}
			case 'FNF 0.2.7':
			/*	// HOLDING
				var up = controls.NOTE_UP;
				var right = controls.NOTE_RIGHT;
				var down = controls.NOTE_DOWN;
				var left = controls.NOTE_LEFT;
				var controlHoldArray:Array<Bool> = [left, down, up, right];

				// FlxG.watch.addQuick('asdfa', up);
				if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
				{
					boyfriend.holdTimer = 0;

					var possibleNotes:Array<Note> = [];

					var ignoreList:Array<Int> = [];

					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
						{
							// the sorting probably doesn't need to be in here? who cares lol
							possibleNotes.push(daNote);
							possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

							ignoreList.push(daNote.noteData);
						}
					});

					if (possibleNotes.length > 0)
					{
						var daNote = possibleNotes[0];

						// Jump notes
						if (possibleNotes.length >= 2)
						{
							if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
							{
								for (coolNote in possibleNotes)
								{
									if (controlHoldArray[coolNote.noteData])
										goodNoteHit(coolNote);
									else
									{
										var inIgnoreList:Bool = false;
										for (shit in 0...ignoreList.length)
										{
											if (controlHoldArray[ignoreList[shit]])
												inIgnoreList = true;
										}
										if (!inIgnoreList)
											badNoteCheck(coolNote);
									}
								}
							}
							else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
							{
								noteCheck(controlHoldArray[daNote.noteData], daNote);
							}
							else
							{
								for (coolNote in possibleNotes)
								{
									noteCheck(controlHoldArray[coolNote.noteData], coolNote);
								}
							}
						}
						else // regular notes?
						{
							noteCheck(controlHoldArray[daNote.noteData], daNote);
						}
					}
					else
					{
						var daNote = possibleNotes[0];
						badNoteCheck(daNote);
					}
				}

				if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
				{
					notes.forEachAlive(function(daNote:Note)
					{
						if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
						{
							switch (daNote.noteData)
							{
								// NOTES YOU ARE HOLDING
								case 0:
									if (left)
										goodNoteHit(daNote);
								case 1:
									if (down)
										goodNoteHit(daNote);
								case 2:
									if (up)
										goodNoteHit(daNote);
								case 3:
									if (right)
										goodNoteHit(daNote);
							}
						}
					});
				}

				 if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
					{
						boyfriend.dance();
						//boyfriend.animation.curAnim.finish();
					}*/
					//i literally hate this
			case 'FNF Week 7+':

			case 'Sarvente':

			case 'Kade':

			case 'Yoshicrafter':

		}
	}

/*	function badNoteCheck(daNote:Note):Void
		{
			// just double pasting this shit cuz fuk u
			// REDO THIS SYSTEM!
			var up = controls.NOTE_UP;
			var right = controls.NOTE_RIGHT;
			var down = controls.NOTE_DOWN;
			var left = controls.NOTE_LEFT;
	
			if (left)
				noteMiss(daNote);
			if (down)
				noteMiss(daNote);
			if (up)
				noteMiss(daNote);
			if (right)
				noteMiss(daNote);
		}
	
		function noteCheck(keyP:Bool, note:Note):Void
		{
			if (keyP)
				goodNoteHit(note);
			else
			{
				badNoteCheck(note);
			}
		}*/

	public function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		var supasex:Bool = false;
		var sexyman:String = ClientPrefs.ratingIntensity;
		switch (sexyman){
			case 'Default':
				supasex = FlxG.random.bool(50);
			case 'Generous':
				supasex = false;
			case 'Harsh':
				supasex = true;
		}
		if(!daNote.isSustainNote) {
			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
				{
					gf.playAnim('sad');
				}
				combo = 0;
		
				if(ClientPrefs.flinchy) {
					flinching = true;
					recalculateIconAnimations();
					if (flinchTimer != null) {
						flinchTimer.cancel();
					}
					flinchTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						flinching = false;
						recalculateIconAnimations();	
					});
				}

				if (SONG.dangerMiss) {
					maxHealth -= 0.10;
				}
				health -= daNote.missHealth * healthLoss;
				if(instakillOnMiss)
				{
					vocals.volume = 0;
					doDeathCheck(true);
				}
		
				//For testing purposes
				//trace(daNote.missHealth);
				songMisses++;
				vocals.volume = 0;
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
				if(!practiceMode) songScore -= 10;
				
				totalPlayed++;
				RecalculateRating();
				#if desktop
				ratingText = ratingName + " " + ratingFC;
				#end
		
				var char:Character = boyfriend;
				if(daNote.gfNote) {
					char = gf;
				}
		
				if(char != null && char.hasMissAnimations)
				{
					var daAlt = '';
					if(daNote.noteType == 'Alt Animation') daAlt = '-alt';
		
					var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[daNote.noteData] + 'miss' + daAlt;
					var noAnimation:String = 'singUP' + 'miss' + daAlt;
					if (char.animOffsets.exists(animToPlay)) {
						char.playAnim(animToPlay, true);
					} else {
						char.playAnim(noAnimation, true);
					}
				}
		
				callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		} else if (daNote.isSustainNote && supasex) {
			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
				{
					gf.playAnim('sad');
				}
				combo = 0;
		
				if(ClientPrefs.flinchy) {
					flinching = true;
					recalculateIconAnimations();
					if (flinchTimer != null) {
						flinchTimer.cancel();
					}
					flinchTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						flinching = false;
						recalculateIconAnimations();	
					});
				}
				
				if (SONG.dangerMiss) {
					maxHealth -= 0.10;
				}
				health -= daNote.missHealth * healthLoss;
				if(instakillOnMiss)
				{
					vocals.volume = 0;
					doDeathCheck(true);
				}
		
				//For testing purposes
				//trace(daNote.missHealth);
				songMisses++;
				vocals.volume = 0;
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
				if(!practiceMode) songScore -= 10;
				
				totalPlayed++;
				RecalculateRating();
				#if desktop
				ratingText = ratingName + " " + ratingFC;
				#end
		
				var char:Character = boyfriend;
				if(daNote.gfNote) {
					char = gf;
				}
		
				if(char != null && char.hasMissAnimations)
				{
					var daAlt = '';
					if(daNote.noteType == 'Alt Animation') daAlt = '-alt';
		
					var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[daNote.noteData] + 'miss' + daAlt;
					var noAnimation:String = 'singUP' + 'miss' + daAlt;
					if (char.animOffsets.exists(animToPlay)) {
						char.playAnim(animToPlay, true);
					} else {
						char.playAnim(noAnimation, true);
					}
				}
		
				callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		}
	}

	public function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			if (SONG.dangerMiss) { //MAX HEALTH HERE
				maxHealth -= 0.10;
			}
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
			secondaryVocals.volume = 0;
				doDeathCheck(true);
			}

			if(tappy) return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(ClientPrefs.flinchy) {
				flinching = true;
				recalculateIconAnimations();
				if (flinchTimer != null) {
					flinchTimer.cancel();
				}
				flinchTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					flinching = false;
					recalculateIconAnimations();	
				});
			}

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();
			#if desktop
			ratingText = ratingName + " " + ratingFC;
			#end

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	public function noteMissPress2(direction:Int = 1):Void //GS Tap Miss
		{
			if(ClientPrefs.flinchy) {
				flinching = true;
				recalculateIconAnimations();
				if (flinchTimer != null) {
					flinchTimer.cancel();
				}
				flinchTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					flinching = false;
					recalculateIconAnimations();	
				});
			}
			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
			}
		}

	public function noteMissPress3(direction:Int = 1):Void //GS Tap
		{
			boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction], true);
		}

	public function opponentNoteHit(note:Note):Void
	{
		//if (SONG.notes[Math.floor(curStep / 16)] != null && SONG.notes[Math.floor(curStep / 16)].crossFade){
		//new CrossFade(dad, grpCrossFade, false);
		//}
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;
		
		if(dad.healthDrain){
			health -= FlxG.random.float(0.01, 0.05) * health;
		}

		if(dad.shakeScreen) {
			FlxG.camera.shake(0.0075, 0.1);
			camHUD.shake(0.0045, 0.1);
		}
		if(dad.scareBf && boyfriend != null && boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}
		if(dad.scareGf && gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
			dadmirror.playAnim('hey', true);
			dadmirror.specialAnim = true;
			dadmirror.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if ((SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}

				if (SONG.notes[curSection].crossFade) {
					if (ClientPrefs.crossFadeMode != 'Off') {
						new CrossFade(dad, grpCrossFade, false);
					}
					//trace('Made Dad CrossFade');
				}
			}

			if (note.noteType == 'Cross Fade') {
				if (ClientPrefs.crossFadeMode != 'Off') {
					new CrossFade(dad, grpCrossFade, false);
				}
				//trace('Made Dad CrossFade');
			}

			if (note.noteType == 'GF Cross Fade') {
				if (ClientPrefs.crossFadeMode != 'Off') {
					new CrossFade(gf, grpIdiotFade, false);
				}
				//trace('Made GF CrossFade');
			}

			var char:Character = dad;
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
			var noAnimation:String = 'singUP' + altAnim;
			var mode:String = ClientPrefs.camPanMode;

			if (ClientPrefs.camPans) {
				switch (mode) {
					case 'Always' | 'Oppt Only':
						switch (animToPlay) //FOLLOW NOTE
						{
							case 'singUP':
								moveCamTo[1] = -40;
							case 'singDOWN':
								moveCamTo[1] = 40;
							case 'singLEFT':
								if(dad.curCharacter.startsWith('monster'))
								{
									moveCamTo[0] = 40;
								} else {
									moveCamTo[0] = -40;
								}
							case 'singRIGHT':
								if(dad.curCharacter.startsWith('monster'))
								{
									moveCamTo[0] = -40;
								} else {
									moveCamTo[0] = 40;
								}
								case 'singUP-alt':
									moveCamTo[1] = -45;
								case 'singDOWN-alt':
									moveCamTo[1] = 45;
								case 'singLEFT-alt':
									moveCamTo[0] = -45;
								case 'singRIGHT-alt':
									moveCamTo[0] = 45;
						}
					case 'Camera Focus':
						if (!SONG.notes[Std.int(curStep / 16)].mustHitSection) {
							switch (animToPlay) //FOLLOW NOTE
							{
								case 'singUP':
									moveCamTo[1] = -40;
								case 'singDOWN':
									moveCamTo[1] = 40;
								case 'singLEFT':
									if(dad.curCharacter.startsWith('monster'))
									{
										moveCamTo[0] = 40;
									} else {
										moveCamTo[0] = -40;
									}
								case 'singRIGHT':
									if(dad.curCharacter.startsWith('monster'))
									{
										moveCamTo[0] = -40;
									} else {
										moveCamTo[0] = 40;
									}
									case 'singUP-alt':
										moveCamTo[1] = -45;
									case 'singDOWN-alt':
										moveCamTo[1] = 45;
									case 'singLEFT-alt':
										moveCamTo[0] = -45;
									case 'singRIGHT-alt':
										moveCamTo[0] = 45;
							}
						}
				}
			}

			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				if (char.animOffsets.exists(animToPlay)) {
					char.playAnim(animToPlay, true);
				} else {
					char.playAnim(noAnimation, true);
				}
				char.holdTimer = 0;
			}
			if (char != gf) {
				if (dadmirror.animOffsets.exists(animToPlay)) {
					dadmirror.playAnim(animToPlay, true);
				} else {
					dadmirror.playAnim(noAnimation, true);
				}
				dadmirror.holdTimer = 0;
			}
			if(littleIdiot != null && littleIdiot.visible == true) {
				littleIdiot.playAnim(animToPlay, true);
				FlxTween.tween(FlxG.camera, {zoom: 0.08}, 0.2, {ease: FlxEase.quadInOut});
				FlxTween.tween(camHUD, {zoom: 0.48}, 0.2, {ease: FlxEase.quadInOut});
				littleIdiot.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;
			secondaryVocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		if(ClientPrefs.opponentNoteAnimations) {
			StrumPlayAnim(0, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
		}
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	public function thirdNoteHit(note:Note):Void
		{
			if(player4.healthDrain){
				health -= FlxG.random.float(0.01, 0.05) * health;
			}
			if(player4.shakeScreen) {
				FlxG.camera.shake(0.0075, 0.1);
				camHUD.shake(0.0045, 0.1);
			}
			if(player4.scareBf && boyfriend != null && boyfriend.animOffsets.exists('scared')) {
				boyfriend.playAnim('scared', true);
			}
			if(player4.scareGf && gf != null && gf.animOffsets.exists('scared')) {
				gf.playAnim('scared', true);
			}
	
			if(note.noteType == 'Hey!' && player4.animOffsets.exists('hey')) {
				player4.playAnim('hey', true);
				player4.specialAnim = true;
				player4.heyTimer = 0.6;
			} else if(!note.noAnimation) {
				var altAnim:String = "";
	
				var curSection:Int = Math.floor(curStep / 16);
				if (SONG.notes[curSection] != null)
				{
					if ((SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') && !SONG.notes[curSection].gfSection) {
						altAnim = '-alt';
					}
					if (SONG.notes[curSection].crossFade) {
						if (ClientPrefs.crossFadeMode != 'Off') {
							new CrossFade(player4, grpP4CrossFade, false);
						}
						//trace('Made player4 CrossFade');
					}
				}
	
				var char:Character = player4;
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
				var noAnimation:String = 'singUP' + altAnim;
				var mode:String = ClientPrefs.camPanMode;
	
				if (ClientPrefs.camPans) {
					switch (mode) {
						case 'Always' | 'Player 4 Only':
							switch (animToPlay) //FOLLOW NOTE
							{
								case 'singUP':
									moveCamTo[1] = -40;
								case 'singDOWN':
									moveCamTo[1] = 40;
								case 'singLEFT':
									if(dad.curCharacter.startsWith('monster'))
									{
										moveCamTo[0] = 40;
									} else {
										moveCamTo[0] = -40;
									}
								case 'singRIGHT':
									if(dad.curCharacter.startsWith('monster'))
									{
										moveCamTo[0] = -40;
									} else {
										moveCamTo[0] = 40;
									}
									case 'singUP-alt':
										moveCamTo[1] = -45;
									case 'singDOWN-alt':
										moveCamTo[1] = 45;
									case 'singLEFT-alt':
										moveCamTo[0] = -45;
									case 'singRIGHT-alt':
										moveCamTo[0] = 45;
							}
						case 'Camera Focus':
							if (SONG.notes[Std.int(curStep / 16)].player4Section) {
								switch (animToPlay) //FOLLOW NOTE
								{
									case 'singUP':
										moveCamTo[1] = -40;
									case 'singDOWN':
										moveCamTo[1] = 40;
									case 'singLEFT':
										if(dad.curCharacter.startsWith('monster'))
										{
											moveCamTo[0] = 40;
										} else {
											moveCamTo[0] = -40;
										}
									case 'singRIGHT':
										if(dad.curCharacter.startsWith('monster'))
										{
											moveCamTo[0] = -40;
										} else {
											moveCamTo[0] = 40;
										}
										case 'singUP-alt':
											moveCamTo[1] = -45;
										case 'singDOWN-alt':
											moveCamTo[1] = 45;
										case 'singLEFT-alt':
											moveCamTo[0] = -45;
										case 'singRIGHT-alt':
											moveCamTo[0] = 45;
								}
							}
					}
				}
	
				if(char != null)
				{
					if (char.animOffsets.exists(animToPlay)) {
						char.playAnim(animToPlay, true);
					} else {
						char.playAnim(noAnimation, true);
					}
					char.holdTimer = 0;
				}
			}
	
			if (SONG.needsVoices)
				vocals.volume = 1;
				secondaryVocals.volume = 1;
	
			var time:Float = 0.15;
			if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
				time += 0.15;
			}
			if(ClientPrefs.opponentNoteAnimations) {
				StrumPlayAnim(2, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
			}
			note.hitByOpponent = true;
	
			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}

	public function goodNoteHit(note:Note):Void
	{
		//if (SONG.notes[Math.floor(curStep / 16)] != null && SONG.notes[Math.floor(curStep / 16)].crossFade){
		//new CrossFade(boyfriend, grpCrossFade, false);
		//}
		/*if (ClientPrefs.darkenBG) {
			if (darkenBG != null) {
				if (darkenTween != null) darkenTween.cancel();
				darkenTween = null;
				darkenTween = FlxTween.tween(darkenBG, {alpha: 0.75}, 0.2, {
					ease: FlxEase.quadInOut,
					onComplete: function(twn:FlxTween) {
						if (darkenTween != null) darkenTween.cancel();
						darkenTween = null;
						if (darkenTimer != null) darkenTimer.cancel();
						darkenTimer = null;
						darkenTimer = new FlxTimer().start(Conductor.crochet * 0.0025, function(tmr:FlxTimer) {
							if (darkenTween != null) darkenTween.cancel();
							darkenTween = null;
							darkenTween = FlxTween.tween(darkenBG, {alpha: 0}, 0.2, {
								ease: FlxEase.quadInOut
							});
						});
					}
				});
			}
		}*/ //work on this later
		if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(boyfriend.shakeScreen) {
				FlxG.camera.shake(0.0075, 0.1);
				camHUD.shake(0.0045, 0.1);
			}
			if(boyfriend.scareBf && dad != null && dad.animOffsets.exists('scared')) {
				dad.playAnim('scared', true);
			}
			if(boyfriend.scareGf && gf != null && gf.animOffsets.exists('scared')) {
				gf.playAnim('scared', true);
			}	

			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				if(combo > 999999) combo = 999999;
				if(highestCombo < combo) highestCombo = combo;
				popUpScore(note);
			}
			health += note.hitHealth * healthGain;

			if (flinching){
				flinching = false;
				if (flinchTimer != null) flinchTimer.cancel();
				recalculateIconAnimations();
			}

			if(!note.noAnimation) {
				var daAlt = '';
	
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
				var noAnimation:String = 'singUP';
				var mode:String = ClientPrefs.camPanMode;

				if (ClientPrefs.camPans) {
					switch (mode) {
						case 'Always' | 'BF Only':
							switch (animToPlay) //FOLLOW NOTE
							{
								case 'singUP':
									moveCamTo[1] = -40;
								case 'singDOWN':
									moveCamTo[1] = 40;
								case 'singLEFT':
									moveCamTo[0] = -40;
								case 'singRIGHT':
									moveCamTo[0] = 40;
									case 'singUP-alt':
										moveCamTo[1] = -45;
									case 'singDOWN-alt':
										moveCamTo[1] = 45;
									case 'singLEFT-alt':
										moveCamTo[0] = -45;
									case 'singRIGHT-alt':
										moveCamTo[0] = 45;
							}
						case 'Camera Focus':
							if (SONG.notes[Std.int(curStep / 16)].mustHitSection) {
								switch (animToPlay) //FOLLOW NOTE
								{
									case 'singUP':
										moveCamTo[1] = -40;
									case 'singDOWN':
										moveCamTo[1] = 40;
									case 'singLEFT':
										moveCamTo[0] = -40;
									case 'singRIGHT':
										moveCamTo[0] = 40;
										case 'singUP-alt':
											moveCamTo[1] = -45;
										case 'singDOWN-alt':
											moveCamTo[1] = 45;
										case 'singLEFT-alt':
											moveCamTo[0] = -45;
										case 'singRIGHT-alt':
											moveCamTo[0] = 45;
								}
							}
					}
				}

				if(note.noteType == 'Alt Animation'){
						daAlt = '-alt';
						if (boyfriend.animOffsets.exists(animToPlay)) {
							boyfriend.playAnim(animToPlay + daAlt, true);
						} else {
							boyfriend.playAnim(noAnimation, true);
						}
					}
				
				if(note.gfNote) 
				{
					if(gf != null)
					{
						if (gf.animOffsets.exists(animToPlay)) {
							gf.playAnim(animToPlay + daAlt, true);
						} else {
							gf.playAnim(noAnimation, true);
						}
						gf.holdTimer = 0;
					}
				}
				else
				{
					if (boyfriend.animOffsets.exists(animToPlay)) {
						boyfriend.playAnim(animToPlay + daAlt, true);
					} else {
						boyfriend.playAnim(noAnimation, true);
					}
					boyfriend.holdTimer = 0;
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
			//var altAnim:String = "";

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}
			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].crossFade) {
					if (ClientPrefs.crossFadeMode != 'Off') {
						new BFCrossFade(boyfriend, grpBFCrossFade, false);
					}
					//trace('Made BF CrossFade');
				}
			}
			//new BFCrossFade(boyfriend, grpBFCrossFade, true);
			//trace('Made BF CrossFade');

			switch(note.noteType) {
				case 'Cross Fade': //CF note
					if (ClientPrefs.crossFadeMode != 'Off') {
						new BFCrossFade(boyfriend, grpBFCrossFade, false);
					}
					//trace('Made BF CrossFade');
				case 'GF Cross Fade': //GFCF note
				if (ClientPrefs.crossFadeMode != 'Off') {
					new CrossFade(gf, grpIdiotFade, false);
				}
					//trace('Made GF CrossFade');
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(1, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;
			secondaryVocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[data] % Note.ammo[mania])][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	public function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	public function fastCarDrive()
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

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	public function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	public function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	public function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	public function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend != null && boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	public function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	public function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	private var preventLuaRemove:Bool = false;
	override public function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override public function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		switch (SONG.song.toLowerCase()) {
			case 'guns':
				switch (curStep) {
					//case 890:
						//addBehindDad(gunsThing);
					case 896:
						tankmanRainbow = true;
						raiseTankman = true;
						cameraSpeed = 2;
						FlxTween.tween(camGame, {zoom: 1.05}, 0.2, {
							ease: FlxEase.circInOut,
							onComplete: 
							function (twn:FlxTween)
								{
									defaultCamZoom = 1.05;
								}
						});
						FlxTween.tween(gunsThing, {alpha: 0.75}, 0.2, {
							ease: FlxEase.quadInOut
						});
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.2, {
								ease: FlxEase.quadInOut
							});
						});
						//trace('tankmans y is: ' + dad.y);
						//trace('bfs y is: ' + boyfriend.y);
					case 1024:
						raiseTankman = false;
						//raiseBF = true;
					case 1152:
						tankmanRainbow = false;
						//raiseBF = false;
						cameraSpeed = 1;
						if (gunsTween != null) gunsTween.cancel();
						gunsTween = null;
						FlxTween.tween(camGame, {zoom: 0.9}, 0.2, {
							ease: FlxEase.circInOut,
							onComplete: 
							function (twn:FlxTween)
								{
									defaultCamZoom = 0.9;
								}
						});
						FlxTween.tween(gunsThing, {alpha: 0}, 0.2, {
							ease: FlxEase.quadInOut
						});
						foregroundSprites.forEach(function(spr:BGSprite)
						{
							FlxTween.tween(spr, {alpha: 1}, 0.2, {
								ease: FlxEase.quadInOut
							});
						});
						FlxTween.tween(dad, {y: 340}, 0.2, {
							ease: FlxEase.circInOut
						});
						//FlxTween.tween(boyfriend, {y: 450}, 0.2, {
						//	ease: FlxEase.circInOut
						//});
						//sex idk
				}
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;

	var gunsColorIncrementor:Int = 0;
	
	override public function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0 && SONG.autoZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (SONG.beatDrain) {
			if (health > 0.10) {
				health -= 0.0475 * 0.5;
			}
		}

		if(SONG.autoIcons){
		switch (curIconSwing)
		{
			case 'Swing Mild':
			if (curBeat % gfSpeed == 0) {
				curBeat % (gfSpeed * 2) == 0 ? {
					iconP1.scale.set(1.1, 0.8);
					iconP2.scale.set(1.1, 1.3);
					iconP4.scale.set(0.85, 1.1);
	
					FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP4, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				} : {
					iconP1.scale.set(1.1, 1.3);
					iconP2.scale.set(1.1, 0.8);
					iconP4.scale.set(0.85, 0.65);
	
					FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP4, -15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 * gfSpeed, {ease: FlxEase.quadOut});
				}
	
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
	
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			}
			case 'Squish':
				if (curBeat % gfSpeed == 0) {
					curBeat % (gfSpeed * 2) == 0 ? {
						iconP1.scale.set(1.3, 0.3);
						iconP2.scale.set(0.3, 1.7);
						iconP4.scale.set(0.265, 1.4);
					} : {
						iconP1.scale.set(0.3, 1.3);
						iconP2.scale.set(1.3, 0.3);
						iconP4.scale.set(1.1, 0.265);
					}
		
					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		
					iconP1.updateHitbox();
					iconP2.updateHitbox();
					iconP4.updateHitbox();
				}
			case 'Bop Mild':
				iconP1.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
				iconP4.scale.set(1, 1);
		
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Vanilla':
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
				iconP4.setGraphicSize(Std.int(iconP4.width + 30));
		
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Grow':
			//var funny:Float = (healthBar.percent * 0.01) + 0.01;

			if (healthBar.percent > 80) {
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1.1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 0.2}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
			} else if (healthBar.percent < 20) {
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 0.2}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1.1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
			} else {
				FlxTween.tween(iconP1, {'scale.x': 1.1, 'scale.y': 1.1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1.1, 'scale.y': 1.1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
			}
			//health icon bounce but epic
			//iconP1.setGraphicSize(Std.int(iconP1.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
			//iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));
	
			iconP1.updateHitbox();
			iconP2.updateHitbox();
			case 'Angle Snap':
				if (curBeat % gfSpeed == 0) {
					curBeat % (gfSpeed * 2) == 0 ? {
						iconP1.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);
						iconP4.scale.set(0.85, 1.1);
		
						iconP1.angle = -15;
						iconP2.angle = 15;
						iconP4.angle = 15;
					} : {
						iconP1.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						iconP4.scale.set(0.85, 0.65);
		
						iconP2.angle = -15;
						iconP4.angle = -15;
						iconP1.angle = 15;
					}
		
					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 * gfSpeed, {ease: FlxEase.quadOut});
		
					iconP1.updateHitbox();
					iconP2.updateHitbox();
					iconP4.updateHitbox();
				}
			case 'Old':
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
				iconP4.setGraphicSize(Std.int(iconP4.width + 30));
		
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Stretch':
				var funny:Float = (healthBar.percent * 0.01) + 0.01;
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));
				iconP4.setGraphicSize(Std.int(iconP4.width + (25 * (2 - funny))),Std.int(iconP4.height - (12 * (2 - funny))));
		
				iconP1.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'None':
				//do nada
		}
		}

		if (SONG.autoIdles){
		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			if (ClientPrefs.opponentAlwaysDance) {
				dad.dance();
				dadmirror.dance();
			} else if (!ClientPrefs.opponentAlwaysDance && SONG.notes[Std.int(curStep / 16)].mustHitSection) {
				dad.dance();
				dadmirror.dance();
			}
		}
		if (curBeat % player4.danceEveryNumBeats == 0 && player4.animation.curAnim != null && !player4.animation.curAnim.name.startsWith('sing') && !player4.stunned)
		{
			player4.dance();
		}
		if (littleIdiot != null && littleIdiot.visible == true) {
			if (curBeat % littleIdiot.danceEveryNumBeats == 0 && littleIdiot.animation.curAnim != null && !littleIdiot.animation.curAnim.name.startsWith('sing') && !littleIdiot.stunned)
				{
					littleIdiot.dance();
				}
		}
		}

		switch (curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality && SONG.autoIdles) tankWatchtower.dance();
				if(SONG.autoIdles){
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
				}
				switch (SONG.song.toLowerCase()) {
					case 'guns':
						if (curBeat % 4 == 0 && tankmanRainbow) {
							if (gunsTween != null) gunsTween.cancel();
							gunsTween = null;
							gunsTween = FlxTween.color(gunsThing, 1, gunsThing.color, gunsColors[gunsColorIncrementor]);
							gunsColorIncrementor++;
							if (gunsColorIncrementor > 5) gunsColorIncrementor = 0;
						}
				}
			case 'school':
				if(!ClientPrefs.lowQuality && SONG.autoIdles) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality && SONG.autoIdles) {
					upperBoppers.dance(true);
				}

				if(SONG.autoIdles){
				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);
				}

			case 'limo':
				if(!ClientPrefs.lowQuality && SONG.autoIdles) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if(timeTxtTween != null) {
			timeTxtTween.cancel();
		}
		timeTxt.scale.x = 1.075;
		timeTxt.scale.y = 1.075;
		timeTxtTween = FlxTween.tween(timeTxt.scale, {x: 1, y: 1}, Conductor.crochet / 1250 * gfSpeed, {
			onComplete: function(twn:FlxTween) {
				timeTxtTween = null;
			}
		});

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	public function StrumPlayAnim(whichLine:Int, id:Int, time:Float) {
		var spr:StrumNote = null;
		switch (whichLine)
		{
			case 0:
				spr = strumLineNotes.members[id];
			case 1:
				spr = playerStrums.members[id];
			case 2:
				spr = thirdStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = 'Unrated';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var perfectMode:Bool = false;
		var fullComboMode:Bool = false;
		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = 'Unrated';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
				if (perfects > 0) ratingFC = "PFC";
				if (sicks > 0) ratingFC = "SFC";
				if (goods > 0) ratingFC = "GFC";
				if (bads > 0 || shits > 0 || wtfs > 0) ratingFC = "FC";
				if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
				else if (songMisses >= 10) ratingFC = "Clear";
			//trace(ratingIntensity);
			//trace(ratingFC);
			switch (ratingFC) {
				case "PFC":
					//trace('rating was pfc');
					perfectMode = true;
					fullComboMode = false;
				case "SFC" | "GFC" | "FC":
					//trace('rating was fc');
					perfectMode = false;
					fullComboMode = true;
				default:
					//trace('rating was not fc');
					perfectMode = false;
					fullComboMode = false;
			}
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);

		var curScoreDisplay:String = ClientPrefs.scoreDisplay;
		switch (curScoreDisplay)
		{
			case 'Psych':
				switch (ratingName)
				{
					case 'Unrated':
						scoreTxt.text = 'Score: ' + songScore + ' | Combo Breaks: ' + songMisses + ' | Rating: ' + ratingName;
						deathTxt.text = '';
						sarvRightTxt.text = '';
						sarvAccuracyTxt.text = '';
					default:
						scoreTxt.text = 'Score: ' + songScore + ' | Combo Breaks: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
						deathTxt.text = '';
						sarvRightTxt.text = '';
						sarvAccuracyTxt.text = '';
				}
			case 'Kade':
				scoreTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
				deathTxt.text = 'SCORE:' + songScore;
				sarvRightTxt.text = 'COMBO BREAKS:' + songMisses;
				sarvAccuracyTxt.text = '';
			case 'Sarvente':

				if (perfectMode) {
					scoreTxt.text = 'RATING: Perfect Combo';
					deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
					sarvRightTxt.text = 'SCORE:' + songScore;
					sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
					scoreTxtBg.color = FlxColor.YELLOW;
					sarvAccuracyBg.color = FlxColor.YELLOW;
				} else if (fullComboMode) {
					scoreTxt.text = 'RATING: Full Combo';
					deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
					sarvRightTxt.text = 'SCORE:' + songScore;
					sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
					scoreTxtBg.color = 0xffff9100;
					sarvAccuracyBg.color = 0xffff9100;
				} else {
					switch (ratingName)
					{
						case 'X':
							scoreTxt.text = 'RATING:' + ratingName;
							deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
							sarvRightTxt.text = 'SCORE:' + songScore;
							sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
							scoreTxtBg.color = FlxColor.YELLOW;
							sarvAccuracyBg.color = FlxColor.YELLOW;
						case 'S':
							scoreTxt.text = 'RATING:' + ratingName;
							deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
							sarvRightTxt.text = 'SCORE:' + songScore;
							sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
							scoreTxtBg.color = FlxColor.CYAN;
							sarvAccuracyBg.color = FlxColor.CYAN;
						case 'A':
							scoreTxt.text = 'RATING:' + ratingName;
							deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
							sarvRightTxt.text = 'SCORE:' + songScore;
							sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
							scoreTxtBg.color = FlxColor.RED;
							sarvAccuracyBg.color = FlxColor.RED;
						default: 
							scoreTxt.text = 'RATING:' + ratingName;
							deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
							sarvRightTxt.text = 'SCORE:' + songScore;
							sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
							scoreTxtBg.color = FlxColor.BLACK;
							sarvAccuracyBg.color = FlxColor.BLACK;
					}
				}
			case 'FPS+':
				scoreTxt.text = 'Score: ' + songScore + ' | Combo Breaks: ' + songMisses + ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';//peeps wanted no integer rating
				deathTxt.text = '';
				sarvRightTxt.text = '';
				sarvAccuracyTxt.text = '';
			case 'Vanilla':
				scoreTxt.text = '';
				deathTxt.text = '';
				sarvRightTxt.text = 'Score:' + songScore;
				sarvAccuracyTxt.text = '';
			case 'None':
				scoreTxt.text = '';
				deathTxt.text = '';
				sarvRightTxt.text = '';
				sarvAccuracyTxt.text = '';
		}

		if (ClientPrefs.ratingsDisplay) {
			ratingsTxt.text = "Max Combo:"+highestCombo+"\nCombo:"+combo+"\nPerfects:"+perfects+"\nSicks:"+sicks+"\nGoods:"+goods+"\nBads:"+bads+"\nShits:"+shits+"\nWTFs:"+wtfs+"\nMisses:"+songMisses;
		}
	}

	public function recalculateIconAnimations() {
		if (flinching){
			iconP1.animation.curAnim.curFrame = 1;
		}
		else
		{
			if (ClientPrefs.winningicons && iconP1.getFileName().endsWith('-winning'))
			{
				if (healthBar.percent < 20)
					iconP1.animation.curAnim.curFrame = 1; //Losing BF
				else if (healthBar.percent > 20 && healthBar.percent < 80)
					iconP1.animation.curAnim.curFrame = 0; //Neutral BF
				else if (healthBar.percent > 80)
					iconP1.animation.curAnim.curFrame = 2; //Winning BF
			}
			else
			{
				if (healthBar.percent < 20)
					iconP1.animation.curAnim.curFrame = 1; //Losing BF
				else if (healthBar.percent > 20)
					iconP1.animation.curAnim.curFrame = 0; //Neutral BF
			}
		}

		switch(SONG.player2)
		{
			default:
			if (ClientPrefs.winningicons && iconP2.getFileName().endsWith('-winning'))
			{
				if (healthBar.percent < 20) {
					iconP2.animation.curAnim.curFrame = 2; //Winning Oppt
					iconP4.animation.curAnim.curFrame = 2; //Winning p4
				} else if (healthBar.percent > 20 && healthBar.percent < 80) {
					iconP2.animation.curAnim.curFrame = 0; //Nuetral Oppt
					iconP4.animation.curAnim.curFrame = 0; //Nuetral p4
				} else if (healthBar.percent > 80) {
					iconP2.animation.curAnim.curFrame = 1; //Losing Oppt
					iconP4.animation.curAnim.curFrame = 1; //Losing p4
				}
			}
			else
			{
				if (healthBar.percent < 80) {
					iconP2.animation.curAnim.curFrame = 0; //Nuetral Oppt
					iconP4.animation.curAnim.curFrame = 0; //Nuetral p4
				} else if (healthBar.percent > 80) {
					iconP2.animation.curAnim.curFrame = 1; //Losing Oppt
					iconP4.animation.curAnim.curFrame = 1; //Losing p4
				}
			}
		} 
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	public function addLuaGlitchShader(sprite:ModchartSprite, amplitude:Float, frequency:Float, speed:Float) {
		var testshader:Shaders.GlitchEffect = new Shaders.GlitchEffect();
		testshader.waveAmplitude = amplitude;
		testshader.waveFrequency = frequency;
		testshader.waveSpeed = speed;
		sprite.shader = testshader.shader;
		luabg = sprite;
	}

	public function addGlitchShader(sprite:FlxSprite, amplitude:Float, frequency:Float, speed:Float) {
		var testshader:Shaders.GlitchEffect = new Shaders.GlitchEffect();
		testshader.waveAmplitude = amplitude;
		testshader.waveFrequency = frequency;
		testshader.waveSpeed = speed;
		sprite.shader = testshader.shader;
		curbg = sprite;
	}

	public function autoLayer(array:Array<FlxBasic>) {
		for (i in 0...array.length) {
			add(array[i]);
		}
	}

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}