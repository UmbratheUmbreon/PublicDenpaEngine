package;

#if desktop
import Discord.DiscordClient;
#end
import animateatlas.AtlasFrameMaker;
import flash.geom.ColorTransform;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
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
import lime.app.Application;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import openfl.geom.Rectangle;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import flixel.animation.FlxAnimationController;
import flixel.util.FlxSave;
//I swear theres a reason for this
import StageData;
import FunkinLua;
import DialogueBoxDenpa;
import Hscript.HScript;
import Note;
import Song;
import VanillaBG;
import Shaders;
import CrossFades;
import Character;
import ClientPrefs;
#if VIDEOS_ALLOWED
import vlc.MP4Handler;
#end

using StringTools;

/**
* State containing all gameplay.
*/
class PlayState extends MusicBeatState
{
	//instance
	public static var instance:PlayState;

	//h
	public static var publicSection:Int;

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
	public var modchartBackdrops:Map<String, FlxBackdrop> = new Map<String, FlxBackdrop>();
	//what the fuuuuuckkkkk
	public var jsonSprites:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	public var jsonSprGrp:FlxTypedGroup<FlxBasic>;
	public var jsonSprGrpMiddle:FlxTypedGroup<FlxBasic>;
	//for modcharts
	public var elapsedtime:Float = 0;
	public static var curModChart:String = '';
	public static var curDadModChart:String = '';
	public static var curP4ModChart:String = '';
	//crossfade groups
	public var grpCrossFade:FlxTypedGroup<CrossFade>;
	public var grpP4CrossFade:FlxTypedGroup<CrossFade>;
	public var grpBFCrossFade:FlxTypedGroup<BFCrossFade>;
	public var gfCrossFade:FlxTypedGroup<CrossFade>;
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

	//important character switcher (for character select when that happens)
	public static var characterVersion = 'bf';

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
	public var gfGroup:FlxSpriteGroup;
	public var behindGfGroup:FlxTypedGroup<FlxSprite>;

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
	final spawnTime:Float = 2000;

	//vocals
	public var vocals:FlxSound;
	public var secondaryVocals:FlxSound;

	//characters
	public var dad:Character = null;
	public var dadmirror:Character = null;
	public var player4:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

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

	//camera shit
	public var camZooming:Bool = false;

	//icon swinging
	public var curIconSwing:String = ClientPrefs.iconSwing;
	public var swingDirection:Bool = true;

	//values for shit like health and combo
	public var gfSpeed:Int = 1;
	public var intendedHealth:Float = 1;
	public var health:Float = 1;
	public var lastHealth:Float = 1;
	public var maxHealth:Float = 2;
	public var combo:Int = 0;
	public var highestCombo:Int = 0;

	//healthbar shit
	private var healthBarBG:AttachedSprite.NGAttachedSprite;
	public var healthBar:FlxBar;
	public var healthBarMiddle:FlxBar;
	public var healthBarMiddleHalf:FlxBar;
	public var healthBarBottom:FlxBar;

	//timebar shit
	private var timeBarBG:AttachedSprite.NGAttachedSprite;
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
	public var playbackRate(default, set):Float = 1;
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var poison:Bool = false;
	public var poisonMult:Float = 0;
	var poisonTimer:FlxTimer = null;
	var poisonSpriteGrp:FlxTypedGroup<FlxSprite> = null;
	public var sickOnly:Bool = false;
	var scoreMulti:Float = 1;
	var scoreDivi:Float = 1;
	var freeze:Bool = false;
	var freezeTimer:FlxTimer = null;
	var freezeCooldownTimer:FlxTimer = null;
	var freezeSpriteGrp:FlxTypedGroup<FlxSprite> = null;
	var flashLight:Bool = false;
	var flashLightSprite:FlxSprite = null;
	var quartiz:Bool = false;
	public var quartizTime:Float = 5;
	var ghostMode:Bool = false;
	var randomMode:Bool = false;

	//local storage of ghost tapping
	public var tappy:Bool = false;

	//hitsound thing
	public var hitSound:String = 'hitsound';

	//botplay text shit
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	//icons
	public var iconP1:HealthIcon;
	public var iconP1Poison:HealthIcon;
	public var iconP2:HealthIcon;
	public var iconP4:HealthIcon;
	public var flinching:Bool = false;
	public var flinchTimer:FlxTimer = null;

	//cameras
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camTint:FlxCamera;
	public var cameraSpeed:Float = 1;

	//timers
	#if desktop
	var discordUpdateTimer:FlxTimer;
	#end

	//dialogue
	public var dialogue:Array<String> = null;
	public var dialogueJson:DialogueFile = null;

	//week 2 stage
	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	//week 3 stage
	final phillyLightsColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
	var phillyGroupThing:FlxTypedGroup<FlxBasic>;

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
	var billBoard:FlxSprite;
	var billBoardWho:String = 'limo/fastBfLol';

	//week 5 stage
	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	//week 6 stage
	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var waveEffectBG:FlxWaveEffect;
	var waveEffectFG:FlxWaveEffect;
	var bgGhouls:BGSprite;
	var rosesLightningGrp:FlxTypedGroup<BGSprite>;
	var schoolCloudsGrp:FlxTypedGroup<BGSprite>;

	//week 7 stage
	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;
	var gunsThing:FlxSprite;

	//week 7 extras
	public static var tankmanRainbow:Bool = false;
	var raiseTankman:Bool = false;
	final gunsColors:Array<FlxColor> = [0xBFFF0000, 0xBFFF5E00, 0xBFFFFB00, 0xBF00FF0D, 0xBF0011FF, 0xBFD400FF]; //WTF BOYFRIEND REFERENCE?!?!??!#11/1/1??!Q
	var gunsTween:FlxTween = null;

	//animations???
	final notestuffs:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singSPACE'];

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
	private final singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singSPACE'];

	//cutscene shit
	public var inCutscene:Bool = false;
	public var cutsceneHandlerCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	//woah wtf camera offsets
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	public var player4CameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var ratingText:String = "";
	#end

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

	// stores the last judgement object
	public static var lastRating:FlxSprite;
	// stores the last combo sprite object
	public static var lastCombo:FlxSprite;
	// stores the last crit bg sprite object
	public static var lastNumbg:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	//cam panning
	var moveCamTo:Array<Float> = [0,0];

	//not finished debug display in game
	var debugDisplay:Bool = false;
	var debugTxt:FlxText;
	var loadedDebugVarName:String = '';
	var loadedDebugVar:Dynamic;
	var curDebugVar:Int = 0;
	var debugVars:Array<Dynamic> = [];

	//nps
	var notesPerSecond:Int = 0;
	var npsArray:Array<Date> = [];
	var maxNps:Int = 0;

	//darken bg thing
	/*var darkenBG:FlxSprite;
	var darkenTimer:FlxTimer = null;
	var darkenTween:FlxTween = null;*/

	//subtitles
	//var spawnedSubtitles:Array<FlxSprite> = [];
	//var howLongIsTheFuckingSubtitlesErm:Int = 0;
	//var subtitleMap:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	//tinter
	var tintMap:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	//makes the loading screen peace out if restarting
	public static var loadLoading:Bool = true;

	//hscript thing
	public var hscript:HScript;

	var usingAlt:Bool = false;

	//orbit
	var orbit:Bool = false;

	override public function create()
	{
		Paths.clearStoredMemory(); //we clear the shit old memory

		hscript = new HScript(Paths.hscript('data/${SONG.header.song.toLowerCase()}/script'));

		hscript.call("onCreate", []);

		SoundTestState.isPlaying = false;

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = Keybinds.fill();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		initModifiers();

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camTint = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camTint.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camTint, false);
		FlxG.cameras.add(camHUD, false); //adding false fixes zooming
		FlxG.cameras.add(camOther, false); //ditto
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxG.cameras.setDefaultDrawTarget(camGame, true); //new EPIC code
		//FlxCamera.defaultCameras = [camGame]; //old STUPID code
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true; //update other states iirc
		persistentDraw = true;

		var loading:FlxSprite = null;
		if (loadLoading) {
			loading = new FlxSprite(0, 0).loadGraphic(Paths.image('loadingscreen'));
			loading.cameras = [camOther];
			add(loading);
		}

		//init mania
		mania = SONG.options.mania;
		if (mania < Note.minMania || mania > Note.maxMania)
				mania = Note.defaultMania;

		//failsafe
		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		//ooo scary bpm changes
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.header.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? "Story Mode: " + WeekData.getCurrentWeek().weekName : "Freeplay";
		#end

		//reset some shit
		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.header.song);

		//set some shit
		curStage = PlayState.SONG.assets.stage;
		curModChart = PlayState.SONG.options.modchart;
		curDadModChart = PlayState.SONG.options.dadModchart;
		curP4ModChart = PlayState.SONG.options.p4Modchart;
		if(PlayState.SONG.assets.stage == null || PlayState.SONG.assets.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south':
					curStage = 'spooky';
				case 'monster':
					curStage = FlxG.random.bool(33) ? curStage = 'streetlight' : curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'satin-panties' | 'high':
					curStage = 'limo';
				case 'milf':
					curStage = FlxG.random.bool(33) ? curStage = 'limoNight' : curStage = 'limo';
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
			SONG.assets.stage = curStage; //fix for chart editor lolll
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
				camera_p4: [0,0],
				camera_speed: 1,

				sprites: [],
				animations: []
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

		if (stageData.camera_speed != null) {
			cameraSpeed = stageData.camera_speed;
		}

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if (boyfriendCameraOffset == null) {
			boyfriendCameraOffset = [0, 0];
		}

		opponentCameraOffset = stageData.camera_opponent;
		if (opponentCameraOffset == null) {
			opponentCameraOffset = [0, 0];
		}

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if (girlfriendCameraOffset == null) {
			girlfriendCameraOffset = [0, 0];
		}

		player4CameraOffset = stageData.camera_p4;
		if (player4CameraOffset == null) {
			player4CameraOffset = [0, 0];
		}

		//make groups (wtf!!!)
		phillyGroupThing = new FlxTypedGroup();
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		player4Group = new FlxSpriteGroup(P4_X, P4_Y);
		dadMirrorGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		jsonSprGrp = new FlxTypedGroup();
		jsonSprGrpMiddle = new FlxTypedGroup();
		behindGfGroup = new FlxTypedGroup();

		var useJsonStage:Bool = false;
		if (stageData.sprites != null && stageData.sprites.length > 0) useJsonStage = true;

		//var sprites:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();
		if (!useJsonStage) {
			switch (curStage)
			{
				case 'stage': //Week 1
					var layerArray:Array<FlxBasic> = [];
					var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
	
					var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					if(!ClientPrefs.lowQuality) {
						var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
						stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
						stageLight.updateHitbox();
	
						var stageLightMirror:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
						stageLightMirror.setGraphicSize(Std.int(stageLight.width * 1.1));
						stageLightMirror.updateHitbox();
						stageLightMirror.flipX = true;
	
						var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
						stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
						stageCurtains.updateHitbox();
	
						layerArray = [bg, stageFront, stageLight, stageLightMirror, stageCurtains];
					} else {
						layerArray = [bg, stageFront];
					}
	
					autoLayer(layerArray);
	
				case 'spooky': //Week 2
					//var layerArray:Array<FlxBasic> = [];
					if(!ClientPrefs.lowQuality) {
						halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
					} else {
						halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
					}
					add(halloweenBG);
	
					halloweenWhite = new BGSprite(null, 0, 0, 0, 0);
					halloweenWhite.makeGraphic(Std.int(FlxG.width*2), Std.int(FlxG.height*2), FlxColor.WHITE);
					halloweenWhite.alpha = 0.001;
					halloweenWhite.blend = ADD;
					halloweenWhite.screenCenter();
					halloweenWhite.visible = false;
	
					//PRECACHE SOUNDS
					precacheList.set('thunder_1', 'sound');
					precacheList.set('thunder_2', 'sound');
	
					//autoLayer(layerArray);
	
				case 'streetlight': //Week 2 Alt
					usingAlt = true;

					halloweenBG = new BGSprite('monster_bg_2', -200, -100);
					halloweenBG.scale.set(1.3,1.3);
					halloweenBG.updateHitbox();
					add(halloweenBG);
	
					halloweenWhite = new BGSprite(null, 0, 0, 0, 0);
					halloweenWhite.makeGraphic(Std.int(FlxG.width*2), Std.int(FlxG.height*2), FlxColor.WHITE);
					halloweenWhite.alpha = 0.001;
					halloweenWhite.blend = ADD;
					halloweenWhite.screenCenter();
					halloweenWhite.visible = false;
	
					//PRECACHE SOUNDS
					precacheList.set('thunder_1', 'sound');
					precacheList.set('thunder_2', 'sound');
	
				case 'philly': //Week 3
					var layerArray:Array<FlxBasic> = [];
	
					var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
					city.setGraphicSize(Std.int(city.width * 0.85));
					city.updateHitbox();
	
					phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
					phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
					phillyWindow.updateHitbox();
	
					phillyTrain = new BGSprite('philly/train', 2000, 360);
	
					trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
					FlxG.sound.list.add(trainSound);
	
					phillyStreet = new BGSprite('philly/street', -40, 50);
	
					if(!ClientPrefs.lowQuality) { 
						var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
						var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
						layerArray = [bg, city, phillyWindow, streetBehind, phillyTrain, phillyStreet];
					} else {
						layerArray = [city, phillyWindow, phillyTrain, phillyStreet];
					}
	
					autoLayer(layerArray);
					phillyWindow.alpha = 0.001;
	
				case 'limo': //Week 4
					//var layerArray:Array<FlxBasic> = [];
					var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
					add(skyBG);

					billBoard = new FlxSprite(1000, -500).loadGraphic(Paths.image(billBoardWho));
					billBoard.scrollFactor.set(0.36,0.36);
					billBoard.scale.set(1.9,1.9);
					billBoard.updateHitbox();
					add(billBoard);
					billBoard.active = true;
	
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
	
					//autoLayer(layerArray);

				case 'limoNight': //Week 4 Alt
					usingAlt = true;
					var skyBG:BGSprite = new BGSprite('limoNight/limoNight', -120, -50, 0.1, 0.1);
					add(skyBG);
	
					if(!ClientPrefs.lowQuality) {
						limoMetalPole = new BGSprite('goreNight/metalPole', -500, 220, 0.4, 0.4);
						add(limoMetalPole);
	
						bgLimo = new BGSprite('limoNight/bgLimoNight', -150, 480, 0.4, 0.4, ['background limo pink'], true);
						add(bgLimo);
	
						limoCorpse = new BGSprite('goreNight/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
						add(limoCorpse);
	
						limoCorpseTwo = new BGSprite('goreNight/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
						add(limoCorpseTwo);
	
						grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
						add(grpLimoDancers);
	
						for (i in 0...5)
						{
							var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400, true);
							dancer.scrollFactor.set(0.4, 0.4);
							grpLimoDancers.add(dancer);
						}
	
						limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
						add(limoLight);
	
						grpLimoParticles = new FlxTypedGroup<BGSprite>();
						add(grpLimoParticles);
	
						//PRECACHE BLOOD
						var particle:BGSprite = new BGSprite('goreNight/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
						particle.alpha = 0.01;
						grpLimoParticles.add(particle);
						resetLimoKill();
	
						//PRECACHE SOUND
						precacheList.set('dancerdeath', 'sound');
					}
	
					limo = new BGSprite('limoNight/limoDriveNight', -120, 550, 1, 1, ['Limo stage'], true);
	
					fastCar = new BGSprite('limoNight/fastCarLolNight', -300, 160);
					fastCar.active = true;
					limoKillingState = 0;
	
				case 'mall': //Week 5 - Cocoa, Eggnog
					var layerArray:Array<FlxBasic> = [];
					var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
	
					var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);

					var treeSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 590, 0.6, 0.6);
					treeSnow.color = 0xfff0f0ff;

					var boppersSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 640, 0.8, 0.8);
					boppersSnow.color = 0xfff9f9ff;
	
					bottomBoppers = new BGSprite('christmas/bottomBop', -270, 140, 0.9, 0.9, ['Bottom Level Boppers Idle'], false, false);
					bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
					bottomBoppers.addOffset('Bottom Level Boppers Idle', 0, 0);
					bottomBoppers.addOffset('hey', -16, 26);
					bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					bottomBoppers.updateHitbox();
	
					var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
	
					santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
					precacheList.set('Lights_Shut_off', 'sound');
	
					if(!ClientPrefs.lowQuality) {
						upperBoppers = new BGSprite((SONG.header.song.toLowerCase() == 'eggnog') ? 'christmas/heIsGone' : 'christmas/upperBop', -290, -65, 0.3, 0.33, ['Upper Crowd Bob']);
						upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
						upperBoppers.updateHitbox();
	
						var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -575, 0.3, 0.3);
						bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
						bgEscalator.updateHitbox();
						layerArray = [bg, upperBoppers, bgEscalator, tree, treeSnow, boppersSnow, bottomBoppers, fgSnow, santa];
					} else {
						layerArray = [bg, tree, treeSnow, boppersSnow, bottomBoppers, fgSnow, santa];
					}
	
					autoLayer(layerArray);
	
				case 'mallEvil': //Week 5 - Winter Horrorland
					var layerArray:Array<FlxBasic> = [];
					var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -250, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
	
					var evilTree:BGSprite = new BGSprite('christmas/evilTree', 400, -100, 0.36, 0.33);
					evilTree.setGraphicSize(Std.int(evilTree.width * 1.1));
					evilTree.updateHitbox();
	
					var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
	
					layerArray = [bg, evilTree, evilSnow];
	
					autoLayer(layerArray);
	
				case 'school': //Week 6 - Senpai, Roses
					var layerArray:Array<FlxBasic> = [];
	
					var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
	
					var repositionShit = -200;
	
					var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90); //0.6, 0.9
	
					var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
	
					var widShit = Std.int(bgSky.width * 6);
	
					var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
					bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
					bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
					bgTrees.animation.play('treeLoop');
					bgTrees.scrollFactor.set(0.85, 0.85);

					halloweenWhite = new BGSprite(null, 0, 0, 0, 0);
					halloweenWhite.makeGraphic(Std.int(FlxG.width*2), Std.int(FlxG.height*2), FlxColor.WHITE);
					halloweenWhite.alpha = 0.001;
					halloweenWhite.blend = ADD;
					halloweenWhite.screenCenter();
					halloweenWhite.visible = false;
	
					if(!ClientPrefs.lowQuality) {
						var howMany:Int = SONG.header.song.toLowerCase() == 'roses' ? 3 : 1;
						schoolCloudsGrp = new FlxTypedGroup<BGSprite>();
						for (i in 0...howMany) {
							var schoolClouds = new BGSprite('weeb/weebClouds', FlxG.random.int(SONG.header.song.toLowerCase() == 'roses' ? -400 : -50, 50), FlxG.random.int(SONG.header.song.toLowerCase() == 'roses' ? -200 : -20, 20), 0.15+0.05*i, 0.2+0.01*i);
							schoolClouds.ID = i;
							schoolClouds.active = true;
							schoolClouds.velocity.x = FlxG.random.float(-5, SONG.header.song.toLowerCase() == 'roses' ? 8 : 5);
							schoolClouds.antialiasing = false;
							schoolClouds.setGraphicSize(widShit);
							schoolClouds.updateHitbox();
							if (SONG.header.song.toLowerCase() == 'roses') schoolClouds.color = 0xffdadada;
							schoolCloudsGrp.add(schoolClouds);
						}

						if (SONG.header.song.toLowerCase() == 'roses') {
							rosesLightningGrp = new FlxTypedGroup<BGSprite>();
							for (i in 0...howMany) {
								var rosesLightning = new BGSprite('weeb/weebLightning', schoolCloudsGrp.members[i].x, schoolCloudsGrp.members[i].y, 0.15+0.05*i, 0.2+0.01*i);
								rosesLightning.ID = i;
								rosesLightning.active = true;
								rosesLightning.velocity.x = schoolCloudsGrp.members[i].velocity.x;
								rosesLightning.antialiasing = false;
								rosesLightning.setGraphicSize(widShit);
								rosesLightning.updateHitbox();
								rosesLightning.alpha = 0.001;
								rosesLightning.visible = false;
								rosesLightningGrp.add(rosesLightning);
							}
						}

						var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
						fgTrees.setGraphicSize(Std.int(widShit * 0.8));
						fgTrees.updateHitbox();
						fgTrees.antialiasing = false;
	
						var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
						treeLeaves.setGraphicSize(widShit);
						treeLeaves.updateHitbox();
						treeLeaves.antialiasing = false;
	
						bgGirls = new BackgroundGirls(-100, 190);
						bgGirls.scrollFactor.set(0.9, 0.9);
	
						bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
						bgGirls.updateHitbox();
	
						if (SONG.header.song.toLowerCase() == 'roses') {
							layerArray = [bgSky, rosesLightningGrp, schoolCloudsGrp, bgSchool, bgStreet, fgTrees, bgTrees, treeLeaves, bgGirls];
						} else {
							layerArray = [bgSky, schoolCloudsGrp, bgSchool, bgStreet, fgTrees, bgTrees, treeLeaves, bgGirls];
						}
					} else {
						layerArray = [bgSky, bgSchool, bgStreet, bgTrees];
					}

					if (SONG.header.song.toLowerCase() == 'roses') {
						precacheList.set('thunder_1', 'sound');
						precacheList.set('thunder_2', 'sound');
					}
	
					autoLayer(layerArray);
	
					bgSky.antialiasing = false;
					bgSchool.antialiasing = false;
					bgStreet.antialiasing = false;
					bgTrees.antialiasing = false;
	
					bgSky.setGraphicSize(widShit);
					bgSchool.setGraphicSize(widShit);
					bgStreet.setGraphicSize(widShit);
					bgTrees.setGraphicSize(Std.int(widShit * 1.4));
	
					bgSky.updateHitbox();
					bgSchool.updateHitbox();
					bgStreet.updateHitbox();
					bgTrees.updateHitbox();
	
				case 'schoolEvil': //Week 6 - Thorns
					var layerArray:Array<FlxBasic> = [];
	
					var posX = 400;
					var posY = 200;
					if(!ClientPrefs.lowQuality) {
						/*var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
						bg.scale.set(6, 6);
						bg.antialiasing = false;*/

						waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 6); //2 -1 3 2
						waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2); //2 -1 5 2

						var school:BGSprite = new BGSprite('weeb/evilSchoolBG', posX, posY, 0.8, 0.9);
						school.scale.set(6, 6);
						school.antialiasing = false;

						var ground:BGSprite = new BGSprite('weeb/evilSchoolFG', posX, posY, 0.8, 0.9);
						ground.scale.set(6, 6);
						ground.antialiasing = false;

						wiggleShit.effectType = WiggleEffectType.DREAMY;
						wiggleShit.waveAmplitude = 0.01;
						wiggleShit.waveFrequency = 60;
						wiggleShit.waveSpeed = 0.8;

						school.shader = wiggleShit.shader;
						ground.shader = wiggleShit.shader;

						var waveSprite = new FlxEffectSprite(school, [waveEffectBG]);
						var waveSpriteFG = new FlxEffectSprite(ground, [waveEffectFG]);
						waveSprite.scale.set(6, 6);
						waveSpriteFG.scale.set(6, 6);
						waveSprite.setPosition(posX + 80, posY + 230);
						waveSpriteFG.setPosition(posX + 80, posY + 230);
						waveSprite.scrollFactor.set(1, 1);
						waveSpriteFG.scrollFactor.set(1, 1);
						add(waveSprite);
						add(waveSpriteFG);
	
						bgGhouls = new BGSprite('weeb/bgGhouls', -150, 250, 1, 1, ['BG freaks glitch instance'], false);
						bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
						bgGhouls.updateHitbox();
						bgGhouls.visible = false;
						bgGhouls.antialiasing = false;
	
						layerArray = [bgGhouls];
					} else {
						var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
						bg.scale.set(6, 6);
						bg.antialiasing = false;
						
						layerArray = [bg];
					}
	
					autoLayer(layerArray);
	
				case 'tank': //Week 7 - Ugh, Guns, Stress
					tankmanRainbow = false;
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

					if (SONG.header.song.toLowerCase() == 'guns') {
						gunsThing = new FlxSprite(-100,-100).makeGraphic(Std.int(FlxG.width*1.5),Std.int(FlxG.height*1.5),FlxColor.WHITE);
						gunsThing.color = 0xBFFF0000;
						gunsThing.alpha = 0.001;
						gunsThing.visible = false;
						gunsThing.scrollFactor.set();
						gunsThing.screenCenter();
					}
	
					foregroundSprites = new FlxTypedGroup<BGSprite>();
					foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
					if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
					foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
					if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
					foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
					if(!ClientPrefs.lowQuality) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
			}
		} else {
			var layerArray:Array<FlxBasic> = [];
			var middleLayerArray:Array<FlxBasic> = [];
			var topLayerArray:Array<FlxBasic> = [];
			for (spriteData in stageData.sprites) {
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
				leSprite.antialiasing = spriteData.antialiasing ? ClientPrefs.globalAntialiasing : false;
				if (!spriteData.front && !spriteData.gf_front) {
					layerArray.insert(spriteData.layer_pos, leSprite);
				}
				if (spriteData.gf_front) {
					middleLayerArray.insert(spriteData.layer_pos, leSprite);
				}
				if (spriteData.front && !spriteData.gf_front) {
					topLayerArray.insert(spriteData.layer_pos, leSprite);
				}
				if (spriteData.glitch_shader != null && spriteData.glitch_shader) addGlitchShader(leSprite, (spriteData.glitch_amplitude == null) ? 1 : spriteData.glitch_amplitude, (spriteData.glitch_frequency == null) ? 1 : spriteData.glitch_frequency, (spriteData.glitch_speed == null) ? 1 : spriteData.glitch_speed);
				if (spriteData.origin != null) leSprite.origin.set(spriteData.origin[0], spriteData.origin[1]);
				jsonSprites.set(spriteData.tag, leSprite);
			}
			autoLayer(layerArray);
			autoLayer(middleLayerArray, jsonSprGrpMiddle);
			autoLayer(topLayerArray, jsonSprGrp);
		}
		
		//set pixel stage things
		introSoundsSuffix = isPixelStage ? '-pixel' : '';

		//inside create(), crossfade
		if (ClientPrefs.crossFadeLimit != null) {
			grpCrossFade = new FlxTypedGroup<CrossFade>(ClientPrefs.crossFadeLimit); // limit
			grpP4CrossFade = new FlxTypedGroup<CrossFade>(ClientPrefs.crossFadeLimit); // limit
			gfCrossFade = new FlxTypedGroup<CrossFade>(ClientPrefs.crossFadeLimit); // limit
		} else {
			grpCrossFade = new FlxTypedGroup<CrossFade>(4); // limit
			grpP4CrossFade = new FlxTypedGroup<CrossFade>(2); // limit
			gfCrossFade = new FlxTypedGroup<CrossFade>(2); // limit
		}
		if (ClientPrefs.crossFadeLimit != null) {
			grpBFCrossFade = new FlxTypedGroup<BFCrossFade>(ClientPrefs.boyfriendCrossFadeLimit); // limit
		} else {
			grpBFCrossFade = new FlxTypedGroup<BFCrossFade>(1); // limit
		}

		add(phillyGroupThing); //Needed for philly lights
		add(behindGfGroup);
		add(gfCrossFade);
		add(gfGroup);

		// Shitty layering but whatev it works LOL
		switch(curStage) {
			case 'limo' | 'limoNight':
				add(limo);
			case 'tank':
				if (SONG.header.song.toLowerCase() == 'guns')
					add(gunsThing);
		}

		add(jsonSprGrpMiddle);
		add(grpP4CrossFade);
		add(player4Group);
		add(grpCrossFade);
		add(dadGroup);
		add(grpBFCrossFade);
		add(boyfriendGroup);
		add(dadMirrorGroup);
		add(jsonSprGrp);
		
		switch(curStage) {
			case 'spooky' | 'streetlight' | 'school':
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

		//in case of null
		var gfVersion:String = SONG.assets.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo' | 'limoNight':
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
			switch(Paths.formatToSongPath(SONG.header.song))
			{
				case 'stress':
					gfVersion = 'pico-speaker';
				case 'tutorial':
					gfVersion = 'gf-tutorial';
			}
			SONG.assets.gfVersion = gfVersion; //Fix for the Chart Editor
			SONG.assets.player3 = gfVersion; //your mother
		}
		var bfVersion:String = SONG.assets.player1;
		if (characterVersion != 'bf') {
			bfVersion = characterVersion;
		}
		if(bfVersion == null || bfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo' | 'limoNight':
					bfVersion = 'bf-car';
				case 'mall' | 'mallEvil':
					bfVersion = 'bf-christmas';
				case 'school' | 'schoolEvil':
					bfVersion = 'bf-pixel';
				case 'streetlight':
					bfVersion = 'bf-streetlight';
				default:
					bfVersion = 'bf';
			}
			switch(Paths.formatToSongPath(SONG.header.song))
			{
				case 'stress':
					bfVersion = 'bf-holding-gf';
			}
			SONG.assets.player1 = bfVersion; //Fix for the Chart Editor
		}
		var dadVersion:String = SONG.assets.player2;
		if(dadVersion == null || dadVersion.length < 1) {
			switch (curStage)
			{
				case 'limo' | 'limoNight':
					dadVersion = 'mom-car';
				case 'mall':
					dadVersion = 'parents-christmas';
				case 'mallEvil':
					dadVersion = 'monster-christmas';
				case 'school':
					dadVersion = 'senpai';
				case 'schoolEvil':
					dadVersion = 'spirit';
				case 'streetlight':
					dadVersion = 'monster-streetlight';
				case 'spooky':
					dadVersion = 'spooky';
				case 'philly':
					dadVersion = 'pico';
				case 'tank':
					dadVersion = 'tankman';
				default:
					dadVersion = 'dad';
			}
			switch(Paths.formatToSongPath(SONG.header.song))
			{
				case 'tutorial':
					gfVersion = 'gf-tutorial';
			}
			SONG.assets.player2 = dadVersion; //Fix for the Chart Editor
		}
		var p4Version:String = SONG.assets.player4;
		if(p4Version == null || p4Version.length < 1) {
			p4Version = 'dad';
			SONG.assets.player4 = p4Version; //Fix for the Chart Editor
		}

		//thing for da alts
		if (usingAlt) {
			if (bfVersion.toLowerCase() == 'bf') {
				bfVersion = 'bf-streetlight';
				SONG.assets.player1 = bfVersion;
			}
			if (dadVersion.toLowerCase() == 'monster') {
				dadVersion = 'monster-streetlight';
				SONG.assets.player2 = dadVersion;
			}
		}

		if (!stageData.hide_girlfriend)
			{
				gf = new Character(0, 0, gfVersion);
				startCharacterPos(gf);
				gf.scrollFactor.set(0.95, 0.95);
				gfGroup.add(gf);
				startCharacterLua(gf.curCharacter);

				if (curStage == 'limoNight')
					gf.setColorTransform(0.4,0.5,0.55,1,0,0,0,0);
	
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

		player4 = new Character(0, 0, p4Version);
		startCharacterPos(player4, true);
		if (SONG.assets.enablePlayer4) player4Group.add(player4);
		startCharacterLua(player4.curCharacter);
		if (curStage == 'limoNight')
			player4.setColorTransform(0.4,0.5,0.55,1,0,0,0,0);

		dad = new Character(0, 0, dadVersion);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		if (curStage == 'limoNight')
			dad.setColorTransform(0.4,0.5,0.55,1,0,0,0,0);
		
		boyfriend = new Boyfriend(0, 0, bfVersion);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);	
		if (curStage == 'limoNight')
			boyfriend.setColorTransform(0.4,0.5,0.55,1,0,0,0,0);

		if (boyfriend != null && boyfriend.deathProperties != null) {
			GameOverSubstate.characterName = boyfriend.deathProperties.character;
			GameOverSubstate.deathSoundName = boyfriend.deathProperties.startSfx;
			GameOverSubstate.loopSoundName = boyfriend.deathProperties.loopSfx;
			GameOverSubstate.endSoundName = boyfriend.deathProperties.endSfx;
			GameOverSubstate.loopBPM = boyfriend.deathProperties.bpm;
		}

		//for orbit
		dadmirror = new Character(dad.x, dad.y, dad.curCharacter);
		startCharacterPos(dadmirror, true);
		dadmirror.y += 0;
		dadmirror.x += 150;
		dadmirror.visible = false;
		dadMirrorGroup.add(dadmirror);
		
		var camPos:FlxPoint = new FlxPoint(boyfriendCameraOffset[0], boyfriendCameraOffset[1]);
		if(boyfriend != null && stageData.hide_girlfriend)
		{
			camPos.x += boyfriend.getGraphicMidpoint().x + boyfriend.cameraPosition[0];
			camPos.y += boyfriend.getGraphicMidpoint().y + boyfriend.cameraPosition[1];
		}
		else if(gf != null)
		{
			camPos.x = girlfriendCameraOffset[0];
			camPos.y = girlfriendCameraOffset[1];
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
				resetBillBoard();
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			case 'limoNight':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
		}

		//flixel trails
		if (dad.flixelTrail && dad.trailLength != null && dad.trailDelay != null && dad.trailAlpha != null && dad.trailDiff != null) {
			var dadTrail = new FlxTrail(dad, null, dad.trailLength, dad.trailDelay, dad.trailAlpha, dad.trailDiff); //nice
			insert(members.indexOf(dadGroup) - 1, dadTrail);
		}

		if (SONG.assets.enablePlayer4 && player4.flixelTrail && player4.trailLength != null && player4.trailDelay != null && player4.trailAlpha != null && player4.trailDiff != null) {
			var p4Trail = new FlxTrail(player4, null, player4.trailLength, player4.trailDelay, player4.trailAlpha, player4.trailDiff); //nice
			insert(members.indexOf(player4Group) - 1, p4Trail);
		}

		if (boyfriend.flixelTrail && boyfriend.trailLength != null && boyfriend.trailDelay != null && boyfriend.trailAlpha != null && boyfriend.trailDiff != null) {
			var bfTrail = new FlxTrail(boyfriend, null, boyfriend.trailLength, boyfriend.trailDelay, boyfriend.trailAlpha, boyfriend.trailDiff); //nice
			insert(members.indexOf(boyfriendGroup) - 1, bfTrail);
		}

		if (gf != null && gf.flixelTrail && gf.trailLength != null && gf.trailDelay != null && gf.trailAlpha != null && gf.trailDiff != null) {
			var gfTrail = new FlxTrail(gf, null, gf.trailLength, gf.trailDelay, gf.trailAlpha, gf.trailDiff); //nice
			insert(members.indexOf(gfGroup) - 1, gfTrail);
		}

		//orbit
		orbit = dad.orbit;

		callOnLuas('onCharacterCreation', []);
		hscript.call("onCharacterCreation", []);

		//in create(), this does the actual tinting
		if (SONG.options.tintRed != null && SONG.options.tintGreen != null && SONG.options.tintBlue != null) {
			if(SONG.options.tintRed != 255 && SONG.options.tintGreen != 255 && SONG.options.tintBlue != 255) {
				tintMap.set('stage', addATint(0.5, FlxColor.fromRGB(SONG.options.tintRed,SONG.options.tintGreen,SONG.options.tintBlue)));
			}
		}
		switch (SONG.header.song.toLowerCase()) {
			case 'south':
				defaultCamZoom = 1.075;
				tintMap.set('south', addATint(0.3, FlxColor.fromRGB(10,20,90)));
			case 'monster':
				if (!usingAlt){
					defaultCamZoom = 1.1;
				}
				tintMap.set('monster', addATint(usingAlt ? 1 : 0.6, FlxColor.fromRGB(10,20,90))); 
			case 'roses':
				defaultCamZoom += 0.05;
				tintMap.set('roses', addATint(0.15, FlxColor.fromRGB(90,20,10))); 
		}

		//dialogue shit
		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Denpa Engine dialogue
		if (#if sys sys.FileSystem.exists(file) #else OpenFlAssets.exists(file) #end) {
			dialogueJson = DialogueBoxDenpa.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (#if sys sys.FileSystem.exists(file) #else OpenFlAssets.exists(file) #end) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, ClientPrefs.downScroll ? FlxG.height - 150 : 50).makeGraphic(FlxG.width, 10);
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
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, ClientPrefs.downScroll ? FlxG.height - 44 : 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0.001;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.header.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite.NGAttachedSprite(400, 20, FlxColor.BLACK);
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0.001;
		timeBarBG.visible = showTime;
		if (timeBarBG.visible == true && showJustTimeText) {
			timeBarBG.visible = false;
		} 
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		var color:FlxColor;
		var blockyness:Int = 1;
		if(isPixelStage) blockyness = 5;
		if (ClientPrefs.changeTBcolour) {
			try {
				timeBar.createGradientBar([0xFF000000], [color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.subtract(color, 0x00333333)], blockyness, 90);
			} catch(e) {
				timeBar.createGradientBar([0xFF000000], [color = FlxColor.fromRGB(ClientPrefs.timeBarRGB[0], ClientPrefs.timeBarRGB[1], ClientPrefs.timeBarRGB[2]), FlxColor.subtract(color, 0x00333333)], blockyness, 90);
				trace('exception: ' + e);
			}
		} else {
			timeBar.createGradientBar([0xFF000000], [color = FlxColor.fromRGB(ClientPrefs.timeBarRGB[0], ClientPrefs.timeBarRGB[1], ClientPrefs.timeBarRGB[2]), FlxColor.subtract(color, 0x00333333)], blockyness, 90);
		}
		#if (haxe >= "4.1.0")
			if (ClientPrefs.lowQuality || isPixelStage) {
				timeBar.numDivisions = Std.int((timeBar.width)/4);
			} else {
				timeBar.numDivisions = Std.int(timeBar.width); //what if it was 1280 :flushed:
			}
		#end
		timeBar.alpha = 0.001;
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

		switch (ClientPrefs.timeBarType.toLowerCase().replace(' ', '').trim()) {
			case 'songname':
				timeTxt.size = 24;
				timeTxt.y += 3;
			case 'timeleft(nobar)' | 'timeelapsed(nobar)':
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

		generateSong(SONG.header.song);

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
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		//healthbar shit
			healthBarBG = new AttachedSprite.NGAttachedSprite(601, 20, FlxColor.BLACK);
			healthBarBG.y = (ClientPrefs.downScroll ? 0.11 * FlxG.height : FlxG.height * 0.89) + ClientPrefs.comboOffset[4];
			if (ClientPrefs.scoreDisplay == 'Sarvente') {
				healthBarBG.y += ClientPrefs.downScroll ? 20 : -20;
			}
			healthBarBG.x = FlxG.width/4 + ClientPrefs.comboOffset[5];
			healthBarBG.scrollFactor.set();
			healthBarBG.visible = !ClientPrefs.hideHud;
			healthBarBG.xAdd = -4;
			healthBarBG.yAdd = -4;
			add(healthBarBG);

			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 10, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), 6, this,
				'health', 0, maxHealth);
			healthBar.scrollFactor.set();
			// healthBar
			healthBar.visible = !ClientPrefs.hideHud;
			healthBar.alpha = ClientPrefs.healthBarAlpha;
			#if (haxe >= "4.1.0")
			if (ClientPrefs.lowQuality) {
				healthBar.numDivisions = Std.int((healthBar.width)/4);
			} else {
				healthBar.numDivisions = Std.int(healthBar.width);
			}
			#end
			add(healthBar);
			healthBarBG.sprTracker = healthBar;

			healthBarMiddle = new FlxBar(healthBar.x, healthBarBG.y + 13, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), 6, this,
				'health', 0, maxHealth);
			healthBarMiddle.scrollFactor.set();
			// healthBar
			healthBarMiddle.visible = !ClientPrefs.hideHud;
			healthBarMiddle.alpha = ClientPrefs.healthBarAlpha;
			#if (haxe >= "4.1.0")
			if (ClientPrefs.lowQuality) {
				healthBarMiddle.numDivisions = Std.int((healthBar.width)/4);
			} else {
				healthBarMiddle.numDivisions = Std.int(healthBar.width);
			}
			#end
			add(healthBarMiddle);
			//healthBarBG.sprTracker = healthBar;

			healthBarMiddleHalf = new FlxBar(healthBar.x, healthBarBG.y + 15, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), 6 - 2, this,
				'health', 0, maxHealth);
			healthBarMiddleHalf.scrollFactor.set();
			// healthBar
			healthBarMiddleHalf.visible = !ClientPrefs.hideHud;
			healthBarMiddleHalf.alpha = ClientPrefs.healthBarAlpha;
			#if (haxe >= "4.1.0")
			if (ClientPrefs.lowQuality) {
				healthBarMiddleHalf.numDivisions = Std.int((healthBar.width)/4);
			} else {
				healthBarMiddleHalf.numDivisions = Std.int(healthBar.width);
			}
			#end
			add(healthBarMiddleHalf);
			//healthBarBG.sprTracker = healthBar;

			healthBarBottom = new FlxBar(healthBar.x, healthBarBG.y + 18, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), 6 - 2, this,
				'health', 0, maxHealth);
			healthBarBottom.scrollFactor.set();
			// healthBar
			healthBarBottom.visible = !ClientPrefs.hideHud;
			healthBarBottom.alpha = ClientPrefs.healthBarAlpha;
			#if (haxe >= "4.1.0")
			if (ClientPrefs.lowQuality) {
				healthBarBottom.numDivisions = Std.int((healthBar.width)/4);
			} else {
				healthBarBottom.numDivisions = Std.int(healthBar.width);
			}
			#end
			add(healthBarBottom);
			//healthBarBG.sprTracker = healthBar;
		
		//rating display shit
		if (ClientPrefs.ratingsDisplay) {
			ratingsTxt = new FlxText(12, (FlxG.height/2)-84, 0, "Perfects:"+perfects+"\nSicks:"+sicks+"\nGoods:"+goods+"\nBads:"+bads+"\nShits:"+shits+"\nWTFs:"+wtfs+"\nCombo Breaks:"+songMisses);
			ratingsTxt.scrollFactor.set();
			ratingsTxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			ratingsTxt.cameras = [camHUD];
			add(ratingsTxt);
		}

		//watermark shit
		if (ClientPrefs.watermarks)
		{
			var pixelShit:String = isPixelStage ? 'pixelUI/' : '';
			var scale:Float = isPixelStage ? 6 : 1;
			songCard = new FlxSprite(-601, ClientPrefs.downScroll ? 134 : FlxG.height - 264).loadGraphic(Paths.image(pixelShit + 'songCard'));
			songCard.scrollFactor.set();
			songCard.cameras = [camHUD];
			songCard.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			songCard.scale.set(scale,scale);
			songCard.updateHitbox();
			songCard.antialiasing = false;
			add(songCard);

			mirrorSongCard = new FlxSprite(songCard.x -601, songCard.y).loadGraphic(Paths.image(pixelShit + 'songCard'));
			mirrorSongCard.scrollFactor.set();
			mirrorSongCard.cameras = [camHUD];
			mirrorSongCard.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
			mirrorSongCard.flipX = true;
			mirrorSongCard.scale.set(scale,scale);
			mirrorSongCard.updateHitbox();
			mirrorSongCard.antialiasing = false;
			add(mirrorSongCard);

			engineWatermark = new FlxText(12, ClientPrefs.downScroll ? 4 : FlxG.height - 24, 0, "Denpa Engine v" + MainMenuState.denpaEngineVersion);
			engineWatermark.scrollFactor.set();
			engineWatermark.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			engineWatermark.cameras = [camHUD];
			add(engineWatermark);
			screwYou = new FlxText(12, ClientPrefs.downScroll ? 24 : FlxG.height - 44, 0, "Ghost Tapping is forced off!");
			screwYou.scrollFactor.set();
			screwYou.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			screwYou.cameras = [camHUD];
			screwYou.visible = !SONG.options.allowGhostTapping;
			add(screwYou);
			noBotplay = new FlxText(12, ClientPrefs.downScroll ? 44 : FlxG.height - 64, 0, "Botplay is forced off!");
			noBotplay.scrollFactor.set();
			noBotplay.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			noBotplay.cameras = [camHUD];
			noBotplay.visible = !SONG.options.allowBot;
			if (screwYou.visible == false) {
				noBotplay.y = ClientPrefs.downScroll ? 24 : FlxG.height - 44;
			} else {
				noBotplay.y = ClientPrefs.downScroll ? 44 : FlxG.height - 64;
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
				txt.text = SONG.header.song;
				grpSongNameTxt.add(txt);

				fuck++;
			}
			switch (SONG.header.song.toLowerCase())
			{
				case 'tutorial' | 'bopeebo' | 'fresh' | 'dad battle' | 'spookeez' | 'south' | 'pico' | 'philly nice' | 'blammed' | 'satin panties' | 'high' | 'milf' | 'cocoa' | 'eggnog' | 'senpai' | 'roses' | 'thorns' | 'ugh' | 'guns' | 'stress':
					songCreditsTxt.text = "Song by Kawaisprite";
					remixCreditsTxt.text = "From: Friday Night Funkin'";
				case 'monster' | 'winter horrorland':
					songCreditsTxt.text = "Song by Bassetfilms";
					remixCreditsTxt.text = "From: Friday Night Funkin'";
				case 'gospel' | 'zavodila' | 'parish' | 'worship' | 'casanova':
					songCreditsTxt.text = "Song by Mike Geno";
					remixCreditsTxt.text = "From: Mid-Fight Masses";
				case 'lo fight' | 'overhead' | 'ballistic':
					songCreditsTxt.text = "Song by Sock.Clip";
					remixCreditsTxt.text = "From: Vs. Whitty";
				case 'wife forever' | 'sky' | 'manifest':
					songCreditsTxt.text = "Song by bbpanzu";
					remixCreditsTxt.text = "From: Vs. Sky";
				case 'hellclown' | 'madness' | 'improbable outset':
					songCreditsTxt.text = "Song by RozeBud";
					remixCreditsTxt.text = "From: Vs. Tricky";
				case 'expurgation':
					songCreditsTxt.text = "Song by JADS";
					remixCreditsTxt.text = "From: Vs. Tricky";
				case 'foolhardy' | 'bushwhack':
					songCreditsTxt.text = "Song by RozeBud";
					remixCreditsTxt.text = "From: Vs. Zardy";
				case 'disruption' | 'disability' | 'algebra' | 'ferocious' | 'applecore':
					songCreditsTxt.text = "Song by Grantare";
					remixCreditsTxt.text = "From: Golden Apple";
			}
			if (SONG.options.credits != null && SONG.options.remixCreds != null) {
				songCreditsTxt.text = SONG.options.credits;
				remixCreditsTxt.text = SONG.options.remixCreds;
			}
		}

		//omg its that ms text from earlier
		msTxt = new FlxText(0, 0, 0, "");
		msTxt.cameras = [camHUD];
		msTxt.scrollFactor.set();
		msTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		msTxt.visible = (!ClientPrefs.hideHud && ClientPrefs.msPopup);
		msTxt.x = 408 + 250;
		msTxt.y = 290 - 25;
		if (PlayState.isPixelStage) {
			msTxt.x = 408 + 260;
			msTxt.y = 290 + 20;
		}
		msTxt.x += ClientPrefs.comboOffset[0];
		msTxt.y -= ClientPrefs.comboOffset[1];
		insert(members.indexOf(strumLineNotes), msTxt);

		//shit for score text
		scoreTxtBg = new FlxSprite(0, 0).makeGraphic(679, 30, FlxColor.WHITE);
		scoreTxtBg.x = (FlxG.width/4)-40;
		scoreTxtBg.y = ClientPrefs.downScroll ? 13 : 683;
		scoreTxtBg.width = scoreTxtBg.width*2;
		scoreTxtBg.height = scoreTxtBg.height*2;
		scoreTxtBg.scrollFactor.set();
		scoreTxtBg.alpha = 0.001;
		if (ClientPrefs.scoreDisplay == 'Sarvente') {
			scoreTxtBg.alpha = 0.5;
		}
		scoreTxtBg.color = FlxColor.BLACK;
		scoreTxtBg.visible = !ClientPrefs.hideHud;
		add(scoreTxtBg);

		sarvAccuracyBg = new FlxSprite(0, 0).makeGraphic(205, 30, FlxColor.WHITE);
		sarvAccuracyBg.x = ClientPrefs.watermarks ? FlxG.width/4 + FlxG.width/4 + FlxG.width/4 + 80 : 40;
		sarvAccuracyBg.y = scoreTxtBg.y;
		sarvAccuracyBg.height = scoreTxtBg.height;
		sarvAccuracyBg.scrollFactor.set();
		sarvAccuracyBg.alpha = 0.001;
		if (ClientPrefs.scoreDisplay == 'Sarvente') {
			sarvAccuracyBg.alpha = 0.5;
		}
		sarvAccuracyBg.color = FlxColor.BLACK;
		sarvAccuracyBg.visible = !ClientPrefs.hideHud;
		if (sarvAccuracyBg.visible) sarvAccuracyBg.visible = ClientPrefs.sarvAccuracy;
		add(sarvAccuracyBg);

		//icons
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.alpha = ClientPrefs.healthBarAlpha;

		iconP1Poison = new HealthIcon(boyfriend.healthIcon, true);
		iconP1Poison.y = healthBar.y - 70;
		iconP1Poison.visible = false;
		iconP1Poison.alpha = ClientPrefs.healthBarAlpha;
		iconP1Poison.setColorTransform(1,0,1,1,255,-231,255,0);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.alpha = ClientPrefs.healthBarAlpha;

		iconP4 = new HealthIcon(player4.healthIcon, false);
		iconP4.y = healthBar.y - 135;
		iconP4.alpha = ClientPrefs.healthBarAlpha;
		iconP4.scale.set(0.75, 0.75);
		iconP4.updateHitbox();

		iconP2.y = iconP1.y = healthBar.y - 75;

		iconP4.visible = iconP1.visible = iconP2.visible = !ClientPrefs.hideHud;
		if (iconP4.visible && !SONG.assets.enablePlayer4) iconP4.visible = false; 

		scoreTxt = new FlxText(0, 687, FlxG.width, "", 20); //46
		scoreTxt.y = ClientPrefs.downScroll ? 17 : 687;
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		if (ClientPrefs.scoreDisplay == 'Sarvente') {
			scoreTxt.x = 0;
			scoreTxt.borderStyle = SHADOW;
		} else if (ClientPrefs.scoreDisplay == 'Kade') {
			scoreTxt.x = 160;
		}
		scoreTxt.visible = !ClientPrefs.hideHud;
		
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
		switch (ClientPrefs.scoreDisplay.toLowerCase()) {
			case 'sarvente':
				sarvRightTxt.borderStyle = SHADOW;
				sarvRightTxt.x = -FlxG.width/2 + 315;
			case 'fnf+':
				sarvRightTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				sarvRightTxt.x = -15;
				sarvRightTxt.y = FlxG.height/2 - 100;
			case 'fnm':
				sarvRightTxt.setFormat(Paths.font("helvetica.ttf"), 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				sarvRightTxt.y += ClientPrefs.downScroll ? 40 : -20;
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

		//idk which looks better
		//do we want readability or not having the text weirdly ontop of the iocns
		add(deathTxt);
		add(scoreTxt);
		add(sarvRightTxt);
		add(sarvAccuracyTxt);

		add(iconP4);
		add(iconP1Poison);
		add(iconP1);
		add(iconP2);
		recalculateIconAnimations(true);
		reloadHealthBarColors(false);

		botplayTxt = new FlxText(400, ClientPrefs.downScroll ? timeBarBG.y - 78 : timeBarBG.y + 55, FlxG.width - 800, "AUTO", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);

		flashLightSprite = new FlxSprite().loadGraphic(Paths.image('effectSprites/flashlightEffect'));
		flashLightSprite.scrollFactor.set();
		flashLightSprite.visible = flashLight;
		flashLightSprite.cameras = [camHUD];
		flashLightSprite.scale.set(1.5,1.5);
		flashLightSprite.updateHitbox();
		flashLightSprite.x = FlxG.width - flashLightSprite.width;
		flashLightSprite.x += 180;
		flashLightSprite.flipY = ClientPrefs.downScroll ? true : false;
		flashLightSprite.y = ClientPrefs.downScroll ? FlxG.height - flashLightSprite.height : 0;
		if (flashLight) {
			var black:FlxSprite = new FlxSprite(0,ClientPrefs.downScroll ? flashLightSprite.y : 0).makeGraphic(Math.floor(flashLightSprite.x), Math.floor(flashLightSprite.height), FlxColor.BLACK);
			black.scrollFactor.set();
			black.cameras = [camHUD];
			add(black);
			var black2:FlxSprite = new FlxSprite(0,ClientPrefs.downScroll ? 0 : black.height).makeGraphic(FlxG.width, Math.floor(FlxG.height-black.height), FlxColor.BLACK);
			black2.scrollFactor.set();
			black2.cameras = [camHUD];
			add(black2);
			add(flashLightSprite);
		} else {
			flashLightSprite = null;
		}

		var modifierArray:Array<FlxSprite> = [];

		var botspr:ModifierSprite = new ModifierSprite('botplay', camHUD, 0, 0);
		botspr.visible = cpuControlled;
		add(botspr);
		modifierArray.insert(0, botspr);

		var hpgainspr:ModifierSprite = new ModifierSprite('healthgain', camHUD, 0, 1);
		if (healthGain != 1) {
			hpgainspr.visible = true;
		} else {
			hpgainspr.visible = false;
		}
		add(hpgainspr);
		modifierArray.insert(0, hpgainspr);

		var hplossspr:ModifierSprite = new ModifierSprite('healthloss', camHUD, 0, 2);
		if (healthLoss != 1) {
			hplossspr.visible = true;
		} else {
			hplossspr.visible = false;
		}
		add(hplossspr);
		modifierArray.insert(0, hplossspr);
		
		var instakillspr:ModifierSprite = new ModifierSprite('instakill', camHUD, 0, 3);
		instakillspr.visible = instakillOnMiss;
		add(instakillspr);
		modifierArray.insert(0, instakillspr);

		var poisonspr:ModifierSprite = new ModifierSprite('poison', camHUD, 1, 0);
		poisonspr.visible = poison;
		add(poisonspr);
		modifierArray.insert(0, poisonspr);

		var practicespr:ModifierSprite = new ModifierSprite('practice', camHUD, 1, 1);
		practicespr.visible = practiceMode;
		add(practicespr);
		modifierArray.insert(0, practicespr);

		var sicksspr:ModifierSprite = new ModifierSprite('sickonly', camHUD, 1, 2);
		sicksspr.visible = sickOnly;
		add(sicksspr);
		modifierArray.insert(0, sicksspr);

		var toVisible:Bool = false;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');
		switch(songSpeedType)
		{
			case "multiplicative":
				var scrollspr:ModifierSprite = new ModifierSprite('scrolltypemultiplicative', camHUD, 1, 3);
				toVisible = (ClientPrefs.getGameplaySetting('scrollspeed', 1) != 1) ? true : false;
				scrollspr.visible = toVisible;
				add(scrollspr);
				modifierArray.insert(0, scrollspr);
			case "constant":
				var scrollspr:ModifierSprite = new ModifierSprite('scrolltypeconstant', camHUD, 1, 3);
				toVisible = true;
				scrollspr.visible = toVisible;
				add(scrollspr);
				modifierArray.insert(0, scrollspr);
		}

		var freezespr:ModifierSprite = new ModifierSprite('freeze', camHUD, 2, 0);
		freezespr.visible = freeze;
		add(freezespr);
		modifierArray.insert(0, freezespr);

		var flashlightspr:ModifierSprite = new ModifierSprite('flashlight', camHUD, 2, 1);
		flashlightspr.visible = flashLight;
		add(flashlightspr);
		modifierArray.insert(0, flashlightspr);

		var randomspr:ModifierSprite = new ModifierSprite('randommode', camHUD, 2, 2);
		randomspr.visible = randomMode;
		add(randomspr);
		modifierArray.insert(0, randomspr);

		var ghostspr:ModifierSprite = new ModifierSprite('ghostmode', camHUD, 2, 3);
		ghostspr.visible = ghostMode;
		add(ghostspr);
		modifierArray.insert(0, ghostspr);

		var quartizspr:ModifierSprite = new ModifierSprite('quartiz', camHUD, 3, 0);
		quartizspr.visible = quartiz;
		add(quartizspr);
		modifierArray.insert(0, quartizspr);

		for (sprite in modifierArray) {
			FlxTween.tween(sprite, {alpha: 0}, 0.5, {
				ease: FlxEase.quadInOut,
				startDelay: 2.5/(Conductor.bpm/100),
				onComplete: function(twn:FlxTween) {
					sprite.kill();
					modifierArray.remove(sprite);
					sprite.destroy();
				}
			});
		}

		if (poison) {
			poisonSpriteGrp = new FlxTypedGroup();
			var fuck:Int = 0;
			for (i in 0...4) {
				var poisonSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image('effectSprites/poisonEffect'));
				poisonSprite.alpha = 0.001;
				poisonSprite.visible = false;
				poisonSprite.scrollFactor.set();
				poisonSprite.cameras = [camHUD];
				switch (fuck) {
					case 0:
						poisonSprite.x = FlxG.width - poisonSprite.width;
					case 1:
						poisonSprite.flipY = true;
						poisonSprite.x = FlxG.width - poisonSprite.width;
						poisonSprite.y = FlxG.height - poisonSprite.height;
					case 2:
						poisonSprite.flipX = true;
					case 3:
						poisonSprite.flipX = true;
						poisonSprite.flipY = true;
						poisonSprite.y = FlxG.height - poisonSprite.height;
				}
				fuck++;
				poisonSpriteGrp.add(poisonSprite);
			}
			add(poisonSpriteGrp);
		}

		if (freeze) {
			freezeSpriteGrp = new FlxTypedGroup();
			var fuck:Int = 0;
			for (i in 0...4) {
				var freezeSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image('effectSprites/freezeEffect'));
				freezeSprite.alpha = 0.001;
				freezeSprite.visible = false;
				freezeSprite.scrollFactor.set();
				freezeSprite.cameras = [camHUD];
				switch (fuck) {
					case 0:
						freezeSprite.y = FlxG.height - freezeSprite.height;
					case 1:
						freezeSprite.flipY = true;
					case 2:
						freezeSprite.flipX = true;
						freezeSprite.flipY = true;
						freezeSprite.x = FlxG.width - freezeSprite.width;
					case 3:
						freezeSprite.flipX = true;
						freezeSprite.y = FlxG.height - freezeSprite.height;
						freezeSprite.x = FlxG.width - freezeSprite.width;
				}
				fuck++;
				freezeSpriteGrp.add(freezeSprite);
			}
			add(freezeSpriteGrp);
		}

		//lets set ALL the cameras at once
		//this was NOT what i meant, plese dont do this again
		iconP1Poison.cameras = iconP1.cameras = iconP2.cameras = iconP4.cameras = scoreTxtBg.cameras = sarvAccuracyBg.cameras = scoreTxt.cameras = deathTxt.cameras = sarvRightTxt.cameras = sarvAccuracyTxt.cameras = botplayTxt.cameras = timeBar.cameras = timeBarBG.cameras = timeTxt.cameras = doof.cameras = healthBarBG.cameras = healthBarBottom.cameras = healthBarMiddleHalf.cameras = healthBarMiddle.cameras = healthBar.cameras = notes.cameras = grpNoteSplashes.cameras = strumLineNotes.cameras = [camHUD];

		debugTxt = new FlxText(0,0,0,'',16);
		debugTxt.scrollFactor.set();
		debugTxt.cameras = [camOther];
		debugTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		debugTxt.visible = debugDisplay;
		add(debugTxt);

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

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

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.header.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.header.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.header.song) + '/'));
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

		switch (SONG.header.song.toLowerCase()) {
			case 'south':
				defaultCamZoom = 1.075;
			case 'monster':
				if (!usingAlt){
					defaultCamZoom = 1.1;
				}
			case 'roses':
				defaultCamZoom += 0.05;
		}
		
		//cutscene shit
		var daSong:String = Paths.formatToSongPath(curSong);
		if (canIUseTheCutsceneMother() && !seenCutscene)
		{
			recalculateIconAnimations(true); //ok yanni
			switch (daSong)
			{
				//case 'south':
					//southIntro();
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
					whiteScreen.scrollFactor.set();
					whiteScreen.screenCenter();
					add(whiteScreen);	
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
							whiteScreen.kill();
							remove(whiteScreen);
							whiteScreen.destroy();
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case 'pico':
					phillyIntro();

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					blackScreen.screenCenter();
					camHUD.visible = false;
					inCutscene = true;

					new FlxTimer().start(1.2, function(_) {
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						blackScreen.alpha = 0;
					});
					snapCamFollowToPos(930, -450);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.6;

					new FlxTimer().start(2.2, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						camHUD.alpha = 0;
						blackScreen.kill();
						remove(blackScreen);
						blackScreen.destroy();
						FlxTween.tween(camHUD, {alpha: 1}, 2.5, {
							ease: FlxEase.quadInOut
						});
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
		switch (ClientPrefs.hitSound) {
			case 'Hit Sound':
				hitSound = 'hitsound';
			case 'Crit':
				hitSound = 'crit';
			case 'GF':
				hitSound = 'GF_';
			case 'Metronome':
				hitSound = 'Metronome_Tick';
			case 'Coin':
				hitSound = 'smw_coin';
			case 'Bubble':
				hitSound = 'smw_bubble_pop';
		}
		if (hitSound == 'GF_') {
			if(ClientPrefs.hitsoundVolume > 0) {
				for (i in 0...4) {
					var number = i;
					number++;
					//trace(hitSound + number);
					precacheList.set(hitSound + number, 'sound');
				}
			}
		} else {
			if(ClientPrefs.hitsoundVolume > 0) precacheList.set(hitSound, 'sound');
		}
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

		//if(!ClientPrefs.controllerMode)
		//{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		//}

		callOnLuas('onCreatePost', []);
		hscript.call("onCreatePost", []);

		if (loadLoading && loading != null) {
			FlxTween.tween(loading, {alpha: 0}, 0.45, {
				onComplete: function(twn:FlxTween) {
					loading.kill();
					loading.destroy();
				}
			});
		}
		loadLoading = true;

		publicSection = 0;

		#if desktop
		var updaterThing:Float = 0.1;
		discordUpdateTimer = new FlxTimer().start(updaterThing, function(tmr:FlxTimer){
			if (updaterThing < 1)
				updaterThing = 1;
			if (!inCutscene && !cutsceneHandlerCutscene) {
				var player:String = CoolUtil.formatStringProper(iconP1.getCharacter());
				DiscordClient.changePresence(paused ? 'Paused - ' + detailsText : detailsText + ' - Playing as ' + player, SONG.header.song + " (" + storyDifficultyText + ")" + " -" + ((ratingText.toLowerCase().trim() == 'unrated') ? " " + ratingText : " Rating " + ratingText), iconP2.getCharacter(), false);
			} else if (inCutscene || cutsceneHandlerCutscene) {
				DiscordClient.changePresence(detailsText, SONG.header.song + " - In a Cutscene", iconP2.getCharacter(), false);
			}
		}, 0);
		#end
		
		super.create();

		cacheDeath();
		cacheCountdown();
		cachePopUpScore();
		for (key => type in precacheList)
			{
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

	//WOO YEAH BABY
	//THATS WHAT IVE BEEN WAITING FOR
	public function cacheDeath()
	{
		var characterPath:String = 'characters/' + GameOverSubstate.characterName + '.json';
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
			path = Paths.getPreloadPath('characters/bf-dead.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = sys.io.File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		var json:Character.CharacterFile = cast Json.parse(rawJson);

		Paths.image(json.image);

		json = null;
		rawJson = null;
		path = null;
		characterPath = null;

		Paths.sound(GameOverSubstate.deathSoundName);
		Paths.music(GameOverSubstate.loopSoundName);
		Paths.sound(GameOverSubstate.endSoundName);
	}

	public function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			try {
				if(vocals != null) vocals.pitch = value;
				FlxG.sound.music.pitch = value;
			} catch (e) {
				if(vocals != null) vocals.pitch = 1;
				FlxG.sound.music.pitch = 1;
				trace('exception: ' + e);
			}
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
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

	public function addTextToDebug(text:String)
	{
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
	public function reloadHealthBarColors(p4:Bool, ?useGf:Bool = null, ?usePoison:Bool = null, ?otherGfVariable:Bool = null)
	{
		var healthBars:Array<FlxBar> = [healthBar, healthBarMiddle, healthBarMiddleHalf, healthBarBottom];
		if (!ClientPrefs.greenhp)
		{
			var who:Character = dad;
			var who2:Character = boyfriend;
			if (p4) {
				who = player4;
			}
			if (useGf && otherGfVariable == null) {
				who = gf;
			}
			if (useGf && otherGfVariable != null) {
				who2 = gf;
			}
			var whoColors1:FlxColor = FlxColor.fromRGB(who.healthColorArray[0], who.healthColorArray[1], who.healthColorArray[2]);
			var whoColors2:FlxColor = FlxColor.fromRGB(who.healthColorArrayMiddle[0], who.healthColorArrayMiddle[1], who.healthColorArrayMiddle[2]);
			var whoColors3:FlxColor = FlxColor.fromRGB(who.healthColorArrayBottom[0], who.healthColorArrayBottom[1], who.healthColorArrayBottom[2]);
			var who2Colors1:FlxColor = FlxColor.fromRGB(who2.healthColorArray[0], who2.healthColorArray[1], who2.healthColorArray[2]);
			var who2Colors2:FlxColor = FlxColor.fromRGB(who2.healthColorArrayMiddle[0], who2.healthColorArrayMiddle[1], who2.healthColorArrayMiddle[2]);
			var who2Colors3:FlxColor = FlxColor.fromRGB(who2.healthColorArrayBottom[0], who2.healthColorArrayBottom[1], who2.healthColorArrayBottom[2]);
			if (cpuControlled) {
				who2Colors1 = FlxColor.fromRGB(214,214,214);
				who2Colors2 = FlxColor.subtract(who2Colors1, 0x00141414);
				who2Colors3 = FlxColor.subtract(who2Colors2, 0x00141414);
			}
			if (usePoison != null) {
				who2Colors1 = FlxColor.fromRGB(171,24,233);
				who2Colors2 = FlxColor.subtract(who2Colors1, 0x00141414);
				who2Colors3 = FlxColor.subtract(who2Colors2, 0x00141414);
			}
			var whoColors:Array<FlxColor> = [];
			var who2Colors:Array<FlxColor> = [];
			var curHealthBarCombo:String = who2.healthBarCount + ',' + who.healthBarCount; //dad, THEN bf
			switch (curHealthBarCombo)
			{
				case '1,2':
					who2Colors = [who2Colors1, who2Colors1, who2Colors1, who2Colors1];
					whoColors = [whoColors1, whoColors1, whoColors2, whoColors2]; //split
				case '2,1':
					who2Colors = [who2Colors1, who2Colors1, who2Colors2, who2Colors2];
					whoColors = [whoColors1, whoColors1, whoColors1, whoColors1];
				case '3,1':
					who2Colors = [who2Colors1, who2Colors2, who2Colors2, who2Colors3]; //thirds
					whoColors = [whoColors1, whoColors1, whoColors1, whoColors1];
				case '1,3':
					who2Colors = [who2Colors1, who2Colors1, who2Colors1, who2Colors1];
					whoColors = [whoColors1, whoColors2, whoColors2, whoColors3];
				case '2,2':
					who2Colors = [who2Colors1, who2Colors1, who2Colors2, who2Colors2];
					whoColors = [whoColors1, whoColors1, whoColors2, whoColors2];
				case '2,3':
					who2Colors = [who2Colors1, who2Colors1, who2Colors2, who2Colors2];
					whoColors = [whoColors1, whoColors2, whoColors2, whoColors3];
				case '3,2':
					who2Colors = [who2Colors1, who2Colors2, who2Colors2, who2Colors3];
					whoColors = [whoColors1, whoColors1, whoColors2, whoColors2];
				case '3,3':
					who2Colors = [who2Colors1, who2Colors2, who2Colors2, who2Colors3];
					whoColors = [whoColors1, whoColors2, whoColors2, whoColors3];
				default:
					who2Colors = [who2Colors1, who2Colors1, who2Colors1, who2Colors1];
					whoColors = [whoColors1, whoColors1, whoColors1, whoColors1];
			}
			/*if (hudIsSwapped) {
				var storage:Character = who2;
				who2 = who;
				who = storage;
			}*/
			try {
				var loopCounter:Int = 0;
				for (bar in healthBars) {
					bar.createFilledBar(whoColors[loopCounter], who2Colors[loopCounter]);
					loopCounter++;
				}
			} catch(e) {
				for (bar in healthBars) {
					bar.createFilledBar(0xFFFF0000, 0xFF66FF33);
				}
				trace('exception: ' + e);
			}
		}
		else //og healthbar colours
		{
			for (bar in healthBars) {
				bar.createFilledBar(0xFFFF0000, 0xFF66FF33);
			}
		}
		healthBar.updateBar();
		healthBarMiddle.updateBar();
		healthBarMiddleHalf.updateBar();
		healthBarBottom.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
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
	
	public function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:MP4Handler = new MP4Handler();
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	public inline function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var denpaDialogue:DialogueBoxDenpa;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(denpaDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			recalculateIconAnimations(true);
			inCutscene = true;
			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');
			denpaDialogue = new DialogueBoxDenpa(dialogueFile, song);
			denpaDialogue.scrollFactor.set();
			if(endingSong) {
				denpaDialogue.finishThing = function() {
					denpaDialogue = null;
					endSong();
				}
			} else {
				denpaDialogue.finishThing = function() {
					denpaDialogue = null;
					startCountdown();
				}
			}
			denpaDialogue.nextDialogueThing = startNextDialogue;
			denpaDialogue.skipDialogueThing = skipDialogue;
			denpaDialogue.cameras = [camHUD];
			add(denpaDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.options.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.header.bpm);
		
		curSong = songData.header.song;

		if (SONG.header.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.header.song));
		else
			vocals = new FlxSound();

		secondaryVocals = new FlxSound().loadEmbedded(Paths.secVoices(PlayState.SONG.header.song));

		vocals.pitch = playbackRate;
		secondaryVocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(secondaryVocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.header.song)));

		if (SONG.header.vocalsVolume == null) SONG.header.vocalsVolume = 1;
		if (SONG.header.secVocalsVolume == null) SONG.header.secVocalsVolume = 1;
		if (SONG.header.instVolume == null) SONG.header.instVolume = 1;

		FlxG.sound.music.volume = SONG.header.instVolume;
		vocals.volume = SONG.header.vocalsVolume;
		secondaryVocals.volume = SONG.header.secVocalsVolume;

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.header.song);
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
				if(!randomMode){
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
				swagNote.sustainLength = Math.round(songNotes[2] / Conductor.stepCrochet) * Conductor.stepCrochet;
				swagNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
	
				var susLength:Float = swagNote.sustainLength;
	
				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
	
				var floorSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
	
				if(floorSus > 0) {
					if(floorSus == 1) floorSus++;
					for (susNote in 0...floorSus)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);
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

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;

		hscript.call("onSongGenerated", []);
	}

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

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			hscript.call("onStartCountDown", []);
			return;
		}

		inCutscene = false;
		recalculateIconAnimations(true);
		set_playbackRate(ClientPrefs.getGameplaySetting('songspeed', 1));

		if (songCreditsTxt != null && songCreditsTxt.text.length > 0) {
			FlxTween.tween(songCard, {x: 0}, 0.7, {
				startDelay: 0.1,
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween)
				{
					new FlxTimer().start(1.3/(Conductor.bpm/100)/playbackRate, function(tmr:FlxTimer)
						{
							if(songCard != null){
								FlxTween.tween(songCard, {x: -601}, 0.7, {
									startDelay: 0.1,
									ease: FlxEase.elasticInOut,
									onComplete: function(twn:FlxTween)
									{
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
							if(mirrorSongCard != null){
								FlxTween.tween(mirrorSongCard, {x: -1202}, 0.7, {
								startDelay: 0.1,
								ease: FlxEase.elasticInOut
								});
							}
						});
				}
			});
			FlxTween.tween(mirrorSongCard, {x: -601}, 0.7, {
				startDelay: 0.1,
				ease: FlxEase.elasticInOut
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
			if (songCard != null) {
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
				if(SONG.assets.enablePlayer4) {
					thirdStrums.members[i].visible = true;
				} else {
					thirdStrums.members[i].visible = false;
				}
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);
			hscript.call("onCountdownStarted", []);

			var swagCounter:Int = 0;

			if (skipCountdown || startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 500);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if(SONG.options.autoIdles){
					if (gf != null &&tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
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
					if (tmr.loopsLeft % dadmirror.danceEveryNumBeats == 0 && dadmirror.animation.curAnim != null && !dadmirror.animation.curAnim.name.startsWith('sing') && !dadmirror.stunned)
					{
						dadmirror.dance();	
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
					if(!ClientPrefs.lowQuality && SONG.options.autoIdles)
						upperBoppers.dance(true);
					
					if(SONG.options.autoIdles){
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
						FlxTween.tween(countdownReady, {'scale.x': countdownReady.scale.x*1.0228991278, 'scale.y': countdownReady.scale.y*1.0428991278, alpha: 0}, Conductor.crochet / 1000 / playbackRate, {
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
						FlxTween.tween(countdownSet, {'scale.x': countdownSet.scale.x*1.0428991278, 'scale.y': countdownSet.scale.y*1.0828991278, alpha: 0}, Conductor.crochet / 1000 / playbackRate, {
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
						FlxTween.tween(countdownGo, {'scale.x': countdownGo.scale.x*1.0828991278, 'scale.y': countdownGo.scale.y*1.1228991278, alpha: 0}, Conductor.crochet / 1000 / playbackRate, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						if(dad != null && dad.animOffsets.exists('hey')) {
							dad.playAnim('hey', true);
							dad.specialAnim = true;
							dad.heyTimer = 0.6;
						}
						if(dadmirror != null && dadmirror.animOffsets.exists('hey')) {
							dadmirror.playAnim('hey', true);
							dadmirror.specialAnim = true;
							dadmirror.heyTimer = 0.6;
						}
						if(boyfriend != null && boyfriend.animOffsets.exists('hey')) {
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
						note.alpha = 0.001;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);
				hscript.call("onCountdownTick", [swagCounter]);

				swagCounter++;
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

		//500
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
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.pitch = playbackRate;
		secondaryVocals.time = time;
		secondaryVocals.pitch = playbackRate;
		vocals.play();
		secondaryVocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
		hscript.call('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
		hscript.call('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	public function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.header.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();
		secondaryVocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
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
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
		hscript.call('onSongStart', []);
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
				blammedLightsBlack = new FlxSprite().makeGraphic(Std.int(FlxG.width/defaultCamZoom*1.1), Std.int(FlxG.height/defaultCamZoom*1.1), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				blammedLightsBlack.scrollFactor.set();
				blammedLightsBlack.screenCenter();
				if (phillyStreet != null) {
					insert(members.indexOf(phillyStreet), blammedLightsBlack);
				} else {
					phillyGroupThing.insert(0, blammedLightsBlack);
				}

				if (curStage == 'philly') {
					phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);
				}


				phillyGlowGradient = new PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				if (phillyStreet != null) {
					insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				} else {
					phillyGroupThing.insert(1, phillyGlowGradient);
				}
				if(!ClientPrefs.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('philly/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				if (phillyStreet != null) {
					insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
				} else {
					phillyGroupThing.insert(2, phillyGlowParticles);
				}
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
	private function generateStaticArrows(player:Int, ?changingMania:Bool = null):Void
	{
		for (i in 0...Note.ammo[mania])
			{
				// FlxG.log.add(i);
				var targetAlpha:Float = 1;
				if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.001;
	
				var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
				babyArrow.downScroll = ClientPrefs.downScroll;
				if (!isStoryMode && !skipArrowStartTween)
				{
					babyArrow.y -= 40;
					babyArrow.alpha = 0.001;
					if (changingMania == null) {
						//FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
						FlxTween.tween(babyArrow, {y: babyArrow.y + 40, alpha: targetAlpha}, Conductor.crochet/333.333333333333 / playbackRate, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)/(mania/2)});
					} else {
						babyArrow.alpha = 1;
					}
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
					babyArrow.cameras = [camGame];
					babyArrow.scrollFactor.set(1,1);
					//babyArrow.scale.set(0.4, 0.4);
					thirdStrums.add(babyArrow);
				}
	
				strumLineNotes.add(babyArrow);
				babyArrow.postAddedToGroup();
			}
	}

	public function changeMania(newValue:Int, fade:Int = 0)
		{
			//funny dissapear transitions
			//while new strums appear
			var daOldMania = mania;
			mania = newValue;
			if (!isStoryMode)
			{
				for (i in 0...playerStrums.members.length) {
					var oldStrum:FlxSprite = playerStrums.members[i].clone();
					oldStrum.x = playerStrums.members[i].x;
					oldStrum.y = playerStrums.members[i].y;
					oldStrum.alpha = playerStrums.members[i].alpha;
					oldStrum.scrollFactor.set();
					oldStrum.cameras = [camHUD];
					oldStrum.setGraphicSize(Std.int(oldStrum.width * Note.scales[daOldMania]));
					oldStrum.updateHitbox();
					add(oldStrum);
		
					if(fade != 0) {
						FlxTween.tween(oldStrum, {alpha: 0}, 1, {onComplete: function(_) {
							remove(oldStrum);
						}});
					} else {
						remove(oldStrum);
					}
				}
		
				for (i in 0...opponentStrums.members.length) {
					var oldStrum:FlxSprite = opponentStrums.members[i].clone();
					oldStrum.x = opponentStrums.members[i].x;
					oldStrum.y = opponentStrums.members[i].y;
					oldStrum.alpha = opponentStrums.members[i].alpha;
					oldStrum.scrollFactor.set();
					oldStrum.cameras = [camHUD];
					oldStrum.setGraphicSize(Std.int(oldStrum.width * Note.scales[daOldMania]));
					oldStrum.updateHitbox();
					add(oldStrum);
		
					if(fade != 0) {
						FlxTween.tween(oldStrum, {alpha: 0}, 1, {onComplete: function(_) {
							remove(oldStrum);
						}});
					} else {
						remove(oldStrum);
					}
				}
			}
	
			playerStrums.clear();
			opponentStrums.clear();
			thirdStrums.clear();
			strumLineNotes.clear();
	
			if(fade != 0) {
				generateStaticArrows(0);
				generateStaticArrows(1);
			} else {
				generateStaticArrows(0, true);
				generateStaticArrows(1, true);
			}

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
			hscript.call('onResume', []);
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		hscript.call("onFocus", []);

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		hscript.call("onFocusLost", []);

		super.onFocusLost();
	}

	public function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		secondaryVocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.pitch = playbackRate;
		secondaryVocals.time = Conductor.songPosition;
		secondaryVocals.pitch = playbackRate;
		vocals.play();
		secondaryVocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	//really dumb variables
	private var orbitJunk:Float = 0;
	private var dadFront:Bool = false;
	private var hasJunked:Bool = false;

	override public function update(elapsed:Float)
	{
		if (debugDisplay) {
			if (debugTxt.visible = false)
				debugTxt.visible = true;
			debugTxt.text = loadedDebugVarName + ' (' + curDebugVar + '/' + debugVars.length + ')\n' + Std.string(loadedDebugVar).replace(',', '\n');
		} else {
			if (debugTxt.visible = true)
				debugTxt.visible = false;
			if (debugTxt.text != '')
				debugTxt.text = '';
		}

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

	gfCrossFade.update(elapsed);
	gfCrossFade.forEachDead(function(img:CrossFade) {
		gfCrossFade.remove(img, true);
	});

	//Ghost mode shit -Umbra
	notes.forEach(function(daNote:Note)
		{
			if(ghostMode){
				ghostModeRoutine(daNote);
			} 
		});

	//stupid guns shit
	if (SONG.header.song.toLowerCase() == 'guns' && raiseTankman && dad.y > dad.y - 15) {
		dad.y -= 0.05*FlxG.elapsed*244;
	}
	if (SONG.header.song.toLowerCase() == 'guns' && tankmanRainbow && !raiseTankman) {
		dad.y += (Math.sin(elapsedtime) * 0.2)*FlxG.elapsed*244;
	}

	//you cannot escape quartiz
	//if you know how to make this even worse, feel free to do so
	if (quartizTime > 0){
		quartizTime -= 1;
	} else if (quartiz) {
		if (FlxG.random.bool(1)) {
			for (i in 0...FlxG.random.int(2,5)) {
				quartizRoutine();
			}
		} else {
			quartizRoutine();
		}
		quartizTime = FlxG.elapsed*40000 * FlxG.random.float(1, 10);
	}

	elapsedtime += elapsed;

	orbitJunk += elapsed * 2.5;

	//kinda like genocide, it gradually drains your hp back to normal.
	if (SONG.options.crits) {
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
			if (maxHealth != 2 && !SONG.options.dangerMiss) {
				maxHealth = 2;
			}
		}
	}

	if (poison) {
		if (poisonMult == 0) {
			iconP1Poison.visible = false;
		}
		intendedHealth -= (0.0066666666666667 * poisonMult)*FlxG.elapsed*244; //lose 0.06 per second
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
			var shad = cast(curbg.shader, GlitchShader);
			shad.uTime.value[0] += elapsed;
		}
	}
	//lua shader cast
	if (luabg != null)
	{
		if (luabg.active)
		{
			var shad = cast(luabg.shader, GlitchShader);
			shad.uTime.value[0] += elapsed;
		}
	}

		//ooo floating
		if (boyfriend != null && boyfriend.sarventeFloating && boyfriend.floatMagnitude != null) {
			boyfriend.y += (Math.sin(elapsedtime*boyfriend.floatSpeed) * boyfriend.floatMagnitude)*FlxG.elapsed*244;
		}

		if (dad != null && dad.sarventeFloating && dad.floatMagnitude != null) {
			dad.y += (Math.sin(elapsedtime*dad.floatSpeed) * dad.floatMagnitude)*FlxG.elapsed*244;
		}

		if (player4 != null && player4.sarventeFloating && player4.floatMagnitude != null) {
			player4.y += (Math.sin(elapsedtime*player4.floatSpeed) * player4.floatMagnitude)*FlxG.elapsed*244;
		}

		if (gf != null && gf.sarventeFloating && gf.floatMagnitude != null) {
			gf.y += (Math.sin(elapsedtime*gf.floatSpeed) * gf.floatMagnitude)*FlxG.elapsed*244;
		}

		//aww hell nah its golden apple code
		if(orbit) {
				dad.x = boyfriend.getMidpoint().x + Math.sin(orbitJunk) * 500 - (dad.width / 2);
				dad.y += (Math.sin(elapsedtime) * 0.2);
				dadmirror.setPosition(dad.x, dad.y);

				if ((Math.sin(orbitJunk) >= 0.95 || Math.sin(orbitJunk) <= -0.95) && !hasJunked){
					dadFront = !dadFront;
					hasJunked = true;
				}
				if (hasJunked && !(Math.sin(orbitJunk) >= 0.95 || Math.sin(orbitJunk) <= -0.95)) hasJunked = false;

				dadmirror.visible = dadFront;
				dad.visible = !dadFront;
		}

		switch (curModChart) {
			case 'disruption':
				var krunkThing = 60;
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = (spr.ID*spr.width*1.05 + 750) + (Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) * krunkThing;
						spr.y = ClientPrefs.downScroll ? FlxG.height - 150 - (spr.ID + 50 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing) : spr.ID + 50 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing;
	
						spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1)) / 4;
	
						spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) / 2);
	
						spr.scale.x += 0.2;
						spr.scale.y += 0.2;
	
						spr.scale.x *= 1.5;
						spr.scale.y *= 1.5;
					});
				notes.forEachAlive(function(spr:Note){
					if (spr.mustPress) {
						spr.scaleHackHitbox = true;
						spr.copyScale = true;
					}
				});
			case 'unfairness':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = ((FlxG.width / 2) - (spr.width / 2)) + (Math.sin(elapsedtime + (spr.ID)) * 300)/2;
						spr.y = ((FlxG.height / 2) - (spr.height / 2)) + (Math.cos(elapsedtime + (spr.ID)) * 300)/2;
					});
			case 'cheating':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x += Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1);
						spr.x -= Math.sin(elapsedtime) * 1.5;
					});
			case 'disability':
				playerStrums.forEach(function(spr:StrumNote)
					{
						//spr.direction += (Math.sin(elapsedtime * 2.5*Conductor.bpm/300) + 1) * 5;
						spr.angle += (Math.sin(elapsedtime * 2.5*Conductor.bpm/300) + 1) * 5;
					});
			case 'sway':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + 750 + (72 * Math.sin(elapsedtime*2*Conductor.bpm/300/* + spr.ID*75*/));
					});
			case 'sway2':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + 750 + (72 * Math.sin(elapsedtime*2*Conductor.bpm/300 + spr.ID*75));
					});
			case 'swing':
				playerStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = (spr.ID*spr.width*1.05 + 750) - 300 * Math.sin(elapsedtime*2.5*Conductor.bpm/300 + spr.ID*0) - 275;
						spr.y = (ClientPrefs.downScroll ? FlxG.height - 150 : 50) - 64 * Math.cos((elapsedtime*2 + spr.ID*5) * Math.PI);
					});
		}
		switch (curDadModChart) {
			case 'disruption':
				var krunkThing = 60;
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + 85 + (Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) * krunkThing;
						spr.y = ClientPrefs.downScroll ? FlxG.height - 150 - (spr.ID + 50 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing) : spr.ID + 50 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing;
				
						spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1)) / 4;
	
						spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) / 2);
	
						spr.scale.x += 0.2;
						spr.scale.y += 0.2;
	
						spr.scale.x *= 1.5;
						spr.scale.y *= 1.5;
					});
				notes.forEachAlive(function(spr:Note){
					if (!spr.altNote && !spr.mustPress) {
						spr.scaleHackHitbox = true;
						spr.copyScale = true;
					}
				});
			case 'unfairness':
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = ((FlxG.width / 2) - (spr.width / 2)) + (Math.sin((elapsedtime + (spr.ID)) * 2) * 300);
						spr.y = ((FlxG.height / 2) - (spr.height / 2)) + (Math.cos((elapsedtime + (spr.ID)) * 2) * 300);
					});
			case 'cheating':
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x -= Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1);
						spr.x += Math.sin(elapsedtime) * 1.5;
					});
			case 'disability':
				opponentStrums.forEach(function(spr:StrumNote)
					{
						//spr.direction += (Math.sin(elapsedtime * 2.5*Conductor.bpm/300) + 1) * 5; //lmao no
						spr.angle += (Math.sin(elapsedtime * 2.5*Conductor.bpm/300) + 1) * 5;
					});
			case 'sway':
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + 85 + (72 * Math.sin(elapsedtime*2*Conductor.bpm/300/* + spr.ID*75*/));
					});
			case 'sway2':
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + 85 + (72 * Math.sin(elapsedtime*2*Conductor.bpm/300 + spr.ID*75));
					});
			case 'swing':
				opponentStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = (spr.ID*spr.width*1.05 + 600) + 300 * Math.sin(elapsedtime*2.5*Conductor.bpm/300 + spr.ID*0) - 275;
						spr.y = (ClientPrefs.downScroll ? FlxG.height - 150 : 50) + 64 * Math.cos((elapsedtime*2 + spr.ID*5) * Math.PI);
					});
		}
		switch (curP4ModChart) {
			case 'none':
				thirdStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + player4.x;
						spr.y = spr.ID - 150 + player4.y;
					});
			case 'disruption':
				var krunkThing = 60;
				thirdStrums.forEach(function(spr:FlxSprite)
				{
					spr.x = (spr.ID*spr.width*1.05 + 85 + (Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) * krunkThing) + player4.x;
					spr.y = (spr.ID + 50 + Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1) * krunkThing) + player4.y;
				
					spr.scale.x = Math.abs(Math.sin(elapsedtime - 5) * ((spr.ID % 2) == 0 ? 1 : -1)) / 4;
	
					spr.scale.y = Math.abs((Math.sin(elapsedtime) * ((spr.ID % 2) == 0 ? 1 : -1)) / 2);
	
					spr.scale.x += 0.2;
					spr.scale.y += 0.2;
	
					spr.scale.x *= 1.5;
					spr.scale.y *= 1.5;
				});
				notes.forEachAlive(function(spr:Note){
					if (spr.altNote) {
						spr.scaleHackHitbox = true;
						spr.copyScale = true;
					}
				});
			case 'unfairness':
				thirdStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = ((FlxG.width / 2) - (spr.width / 2)) + (Math.sin((elapsedtime + (spr.ID )) * 2) * 300) + player4.x;
						spr.y = ((FlxG.height / 2) - (spr.height / 2)) + (Math.cos((elapsedtime + (spr.ID)) * 2) * 300) + player4.y;
					});
			case 'disability':
				thirdStrums.forEach(function(spr:FlxSprite)
					{
						spr.angle += (Math.sin(elapsedtime * 2.5*Conductor.bpm/300) + 1) * 5;
					});
			case 'sway':
				thirdStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + 85 + (72 * Math.sin(elapsedtime*2*Conductor.bpm/300/* + spr.ID*75*/));
					});
			case 'sway2':
				thirdStrums.forEach(function(spr:FlxSprite)
					{
						spr.x = spr.ID*spr.width*1.05 + 85 + (72 * Math.sin(elapsedtime*2*Conductor.bpm/300 + spr.ID*75)) + player4.x;
					});
		}

		/*if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}*/

		callOnLuas('onUpdate', [elapsed]);
		hscript.call('onUpdate', [elapsed]);

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
				phillyWindow.alpha -= (Conductor.crochet / 1000 / playbackRate) * FlxG.elapsed * 1.5;
			case 'limo' | 'limoNight':
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
											switch (curStage) {
												case 'limo':
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
												case 'limoNight':
													var particle:BGSprite = new BGSprite('goreNight/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
													grpLimoParticles.add(particle);
													var particle:BGSprite = new BGSprite('goreNight/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
													grpLimoParticles.add(particle);
													var particle:BGSprite = new BGSprite('goreNight/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
													grpLimoParticles.add(particle);

													var particle:BGSprite = new BGSprite('goreNight/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
													particle.flipX = true;
													particle.angle = -57.5;
													grpLimoParticles.add(particle);
											}
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
						if(SONG.options.autoIdles) bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		//way better than before :muscle:
		if(!inCutscene) {
				var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
				//math.floor(x / 6) * 6
				var snap = /*isPixelStage ? 6 : */1;
				if (snap > 1) {
					moveCamTo[0] = 0;
					moveCamTo[1] = 0;
				}
				camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x + moveCamTo[0]/102, camFollow.x + moveCamTo[0]/102, lerpVal), FlxMath.lerp(camFollowPos.y + moveCamTo[1]/102, camFollow.y + moveCamTo[1]/102, lerpVal));
				if (snap > 1) {
					camFollowPos.x = Math.floor((camFollowPos.x / snap) * snap);
					camFollowPos.y = Math.floor((camFollowPos.y / snap) * snap);
				}
				var panLerpVal:Float = CoolUtil.boundTo(elapsed * 4.4 * cameraSpeed, 0, 1);
				moveCamTo[0] = FlxMath.lerp(moveCamTo[0], 0, panLerpVal);
				moveCamTo[1] = FlxMath.lerp(moveCamTo[1], 0, panLerpVal);
				if (moveCamTo[0] < 0.001 && moveCamTo[0] > -0.001) {
					moveCamTo[0] = 0;
				}
				if (moveCamTo[1] < 0.001 && moveCamTo[1] > -0.001) {
					moveCamTo[1] = 0;
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

				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
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
				iconP1Poison.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));
				iconP4.setGraphicSize(Std.int(FlxMath.lerp(115, iconP4.width, 0.50)));

				iconP1.updateHitbox();
				iconP1Poison.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Stretch':
				iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.8)),Std.int(FlxMath.lerp(150, iconP1.height, 0.8)));
				iconP1Poison.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.8)),Std.int(FlxMath.lerp(150, iconP1.height, 0.8)));
				iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.8)),Std.int(FlxMath.lerp(150, iconP2.height, 0.8)));
				iconP4.setGraphicSize(Std.int(FlxMath.lerp(115, iconP4.width, 0.8)),Std.int(FlxMath.lerp(115, iconP4.height, 0.8)));
		
				iconP1.updateHitbox();
				iconP1Poison.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Squish' | 'Swing' | 'Snap':
				//sex
			default:
				var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP1.scale.set(mult, mult);
				iconP1.updateHitbox();

				iconP1Poison.scale.x = iconP2.scale.x = iconP1.scale.x;
				iconP1Poison.scale.y = iconP2.scale.y = iconP1.scale.y;
				iconP1Poison.updateHitbox();
				iconP2.updateHitbox();

				var mult:Float = FlxMath.lerp(0.75, iconP4.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
				iconP4.scale.set(mult, mult);
				iconP4.updateHitbox();
		}

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(health*50, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP1Poison.x = iconP1.x;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(health*50, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		iconP4.x = iconP2.x - 80;

		if (intendedHealth > maxHealth)
			intendedHealth = maxHealth;

		var lerpVal:Float = CoolUtil.boundTo(elapsed*75, 0, 1);
		health = FlxMath.lerp(health, intendedHealth, lerpVal);

		/*var lerpVal:Float = CoolUtil.boundTo(elapsed*8, 0, 1);
		for (i in 0...howLongIsTheFuckingSubtitlesErm) {
			if (subtitleMap.exists('sub' + i)) {
				var subtitle = subtitleMap.get('sub' + i); 
				subtitle.y = FlxMath.lerp(subtitle.y, ClientPrefs.downScroll ? healthBar.y + 85 + (41*i) : healthBar.y - 85 - (41*i), lerpVal);
				subtitle.ID = (spawnedSubtitles.length - subtitle.ID != 0 && i+1 < 2) ? 1 : ((subtitle.ID > spawnedSubtitles.length) ? spawnedSubtitles.length : subtitle.ID);
			}
			if (subtitleMap.exists('subBG' + i)) {
				var subtitleBG = subtitleMap.get('subBG' + i); 
				subtitleBG.y = FlxMath.lerp(subtitleBG.y, ClientPrefs.downScroll ? healthBar.y + 90 + (41*i) : healthBar.y - 90 - (41*i), lerpVal);
				subtitleBG.ID = (spawnedSubtitles.length - subtitleBG.ID != 0 && i+1 < 2) ? 1 : ((subtitleBG.ID > spawnedSubtitles.length) ? spawnedSubtitles.length : subtitleBG.ID);
			}
		}
		if (howLongIsTheFuckingSubtitlesErm > 10) {
			howLongIsTheFuckingSubtitlesErm = 0;
		}*/

		//optimization! hell yeah!
		if(lastHealth != intendedHealth) {
			lastHealth = intendedHealth;
			recalculateIconAnimations();
		}

		//not optimized! hell yeah!
		if (ClientPrefs.scoreDisplay == 'FNF+') sarvRightTxt.text = 'HP\n' + healthBar.percent + '%\n\nACCURACY\n' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%\n\nSCORE\n' + songScore;
		if (ClientPrefs.scoreDisplay == 'Kade') {
			if (ratingFC != "") {
				scoreTxt.text = 'NPS/MAX: ' + notesPerSecond + '/' + maxNps + ' | SCORE:' + songScore + ' | BREAKS:' + songMisses + ' | ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' | (' + ratingFC + ') ' + ratingName;
			} else {
				scoreTxt.text = 'NPS/MAX: ' + notesPerSecond + '/' + maxNps + ' | SCORE:' + songScore + ' | BREAKS:' + songMisses + ' | ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' | ' + ratingName;
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			#if desktop
			discordUpdateTimer.cancel();
			#end
			MusicBeatState.switchState(new CharacterEditorState(SONG.assets.player2));
		}

		if (startedCountdown)
		{
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
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
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(defaultHudCamZoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * playbackRate), 0, 1));
		}

		//we dont need to watch most of these
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		FlxG.watch.addQuick("sectionShit", publicSection);
		//FlxG.watch.addQuick("elapsedShit", elapsedtime);

		if (ClientPrefs.scoreDisplay == 'Kade') {
			var balls = npsArray.length - 1;
			while (balls >= 0)
			{
				var cock:Date = npsArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					npsArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
			notesPerSecond = npsArray.length;
			if (notesPerSecond > maxNps)
				maxNps = notesPerSecond;
		}

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
		}
		doDeathCheck();


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

		checkEventNote();

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss') && SONG.options.autoIdles) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			var fakeCrochet:Float = (60 / SONG.header.bpm) * 1000;
			//fuck off man
			if (!inCutscene && !cutsceneHandlerCutscene) {
				notes.forEachAlive(function(daNote:Note)
					{
						var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
						if(!daNote.mustPress) strumGroup = opponentStrums;
						if(daNote.altNote) {
							strumGroup = thirdStrums;
							daNote.cameras = [camGame];
							daNote.scrollFactor.set(1,1);
						}
		
						if (mania != SONG.options.mania) {
							if (daNote.mania != mania) daNote.mania = mania;
							daNote.applyManiaChange();
						}
		
						if (strumGroup.members[daNote.noteData] == null) daNote.noteData = mania;
		
						var strumX:Float = 0;
						var strumY:Float = 0;
						var strumAngle:Float = 0;
						var strumDirection:Float = 90;
						var strumAlpha:Float = 1;
						var strumScroll:Bool = false;
						var strumHeight:Float = 1;
						var strumScaleX:Float = 1;
						var strumScaleY:Float = 1;
						if (SONG != null && strumGroup != null && daNote != null)
						{
							strumX = strumGroup.members[daNote.noteData].x;
							strumY = strumGroup.members[daNote.noteData].y;
							strumAngle = strumGroup.members[daNote.noteData].angle;
							strumDirection = strumGroup.members[daNote.noteData].direction;
							strumAlpha = strumGroup.members[daNote.noteData].alpha;
							strumScroll = strumGroup.members[daNote.noteData].downScroll;
							strumHeight = strumGroup.members[daNote.noteData].height;
							strumScaleX = strumGroup.members[daNote.noteData].scale.x;
							strumScaleY = strumGroup.members[daNote.noteData].scale.y;
						}
		
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

						if (daNote.copyScale) {
							daNote.scale.set(strumScaleX, strumScaleY);
							if (!daNote.scaleHackHitbox)
								daNote.updateHitbox();
						}
		
						var angleDir = strumDirection * Math.PI / 180;

					        if(daNote.isSustainNote)
						    daNote.angle = strumDirection - 90;

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
								daNote.y += 27.5 * ((SONG.header.bpm / 100) - 1) * (songSpeed - 1) * Note.scales[mania];
							}
						}
		
						if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote && !daNote.altNote)
						{
							opponentNoteHit(daNote, false);
						}
		
						if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote && daNote.altNote)
						{
							opponentNoteHit(daNote, true);
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
		}
		
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
				trace(debugDisplay);
			}
		}
		#end

		instance = this;

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		hscript.call("onUpdatePost", [elapsed]);
	}

	public function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		discordUpdateTimer.cancel();
		DiscordClient.changePresence("Chart Editor", null, null, false);
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
				FlxAnimationController.globalSpeed = 1;
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				discordUpdateTimer.cancel();
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over", SONG.header.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
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

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
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
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad!
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.playAnim('hey', true); //was gonna use offsets but erm, it kinda breaks the idle so
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
				var colorInt:Int = Std.parseInt(value2);
				trace (colorInt); //??
				if(Math.isNaN(lightId)) lightId = 0;
				if(Math.isNaN(colorInt) || colorInt == 0) colorInt = 1;

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.flashing) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15 / playbackRate, null, true);
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
							if (curStage == 'philly') phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							if (curStage == 'philly') phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];
						if (colorInt != 1) color = FlxColor.fromInt(colorInt);

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
							if (curStage == 'philly') phillyWindowEvent.visible = true;
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
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						if (curStage == 'philly') phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						if (curStage == 'philly') phillyStreet.color = color;

					case 2: // spawn particles
						if (curStage == 'philly') {
							var color:FlxColor = phillyLightsColors[curLightEvent];
							if(!ClientPrefs.lowQuality)
							{
								var particlesNum:Int = FlxG.random.int(8, 12);
								var width:Float = (2000 / particlesNum);
								for (j in 0...3)
								{
									for (i in 0...particlesNum)
									{
										var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
										phillyGlowParticles.add(particle);
									}
								}
								phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
								{
									particle.color = color;
								});
							}
							phillyGlowGradient.bop();
						}
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
				if (camFollow != null) {
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
						targetsArray[i].shake(intensity, duration / playbackRate);
					}
				}

			case 'Change Mania':
				var newMania:Int = 0;
				var useFade:Int = 0;
	
				newMania = Std.parseInt(value1);
				useFade = Std.parseInt(value2);
				if(Math.isNaN(newMania) && newMania < 0 && newMania > 8)
					newMania = 0;
	
				changeMania(newMania, useFade);

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
							iconP1Poison.changeIcon(boyfriend.healthIcon);
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
							if (SONG.notes[publicSection].player4Section) {
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

				var newValue:Float = SONG.options.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			//note to self: make this reset the values... properly *cough* x and y *cough*
			case 'Change Modchart':
				var split:Array<String> = value2.split(',');
				switch (split[0].toLowerCase()) {
					case 'bf' | 'boyfriend' | 'player':
						playerStrums.forEach(function(spr:FlxSprite)
							{
								if (split[1].toLowerCase() == 'true') {
									FlxTween.tween(spr, {x: spr.ID*spr.width*1.05 + 730, y: (ClientPrefs.downScroll ? FlxG.height - 150 : 50)}, 0.25 / playbackRate);
								} else {
									spr.x = spr.ID*spr.width*1.05 + 730;
									spr.y = (ClientPrefs.downScroll ? FlxG.height - 150 : 50);
								}
								spr.angle = 0;
								switch (mania)
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
								}
							});
							for(note in notes)
								{
									if(note.mustPress && !note.altNote)
									{
										if (!note.isSustainNote)
											note.angle = playerStrums.members[note.noteData].angle;
											note.scale.x = playerStrums.members[note.noteData].scale.x;
											note.scale.y = playerStrums.members[note.noteData].scale.y;
									}
								}
						curModChart = value1;
					case 'dad' | 'opponent' | 'oppt':
						opponentStrums.forEach(function(spr:FlxSprite)
							{
								if (split[1].toLowerCase() == 'true') {
									FlxTween.tween(spr, {x: spr.ID*spr.width*1.05 + 85, y: (ClientPrefs.downScroll ? FlxG.height - 150 : 50)}, 0.25 / playbackRate);
								} else {
									spr.x = spr.ID*spr.width*1.05 + 85;
									spr.y = (ClientPrefs.downScroll ? FlxG.height - 150 : 50);
								}
								spr.angle = 0;
								switch (mania)
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
								}
							});
							for(note in notes)
								{
									if(!note.mustPress && !note.altNote)
									{
										if (!note.isSustainNote)
											note.angle = opponentStrums.members[note.noteData].angle;
											note.scale.x = opponentStrums.members[note.noteData].scale.x;
											note.scale.y = opponentStrums.members[note.noteData].scale.y;
									}
								}
						curDadModChart = value1;
					case 'player 4' | 'player4' | 'p4':
						thirdStrums.forEach(function(spr:FlxSprite)
							{
								if (split[1].toLowerCase() == 'true') {
									FlxTween.tween(spr, {x: player4.x, y: player4.y}, 0.25 / playbackRate);
								} else {
									spr.x = player4.x;
									spr.y = player4.y;
								}
								spr.angle = 0;
								switch (mania)
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
								}
							});
							for(note in notes)
								{
									if(!note.mustPress && note.altNote)
									{
										if (!note.isSustainNote)
											note.angle = thirdStrums.members[note.noteData].angle;
											note.scale.x = thirdStrums.members[note.noteData].scale.x;
											note.scale.y = thirdStrums.members[note.noteData].scale.y;
									}
								}
						curP4ModChart = value1;
				}

			case 'Toggle Botplay':
				switch (value1)
				{
					case '1':
						cpuControlled = false;
						botplayTxt.visible = cpuControlled;
						if(noBotplay != null) {
							if (screwYou.visible == false) {
								noBotplay.y = ClientPrefs.downScroll ? 24 : FlxG.height - 44;
								noBotplay.visible = !cpuControlled;
							} else {
								noBotplay.y = ClientPrefs.downScroll ? 44 : FlxG.height - 64;
								noBotplay.visible = !cpuControlled;
							}
						}
					case '2':
						cpuControlled = true;
						botplayTxt.visible = cpuControlled;
						if(noBotplay != null) {
							if (screwYou.visible == false) {
								noBotplay.y = ClientPrefs.downScroll ? 24 : FlxG.height - 44;
								noBotplay.visible = !cpuControlled;
							} else {
								noBotplay.y = ClientPrefs.downScroll ? 44 : FlxG.height - 64;
								noBotplay.visible = !cpuControlled;
							}
						}
					default:
						cpuControlled = !cpuControlled;
						botplayTxt.visible = cpuControlled;
						if(noBotplay != null) {
							if (screwYou.visible == false) {
								noBotplay.y = ClientPrefs.downScroll ? 24 : FlxG.height - 44;
								noBotplay.visible = !cpuControlled;
							} else {
								noBotplay.y = ClientPrefs.downScroll ? 44 : FlxG.height - 64;
								noBotplay.visible = !cpuControlled;
							}
						}
				}
				recalculateIconAnimations();
			
			case 'Toggle Ghost Tapping':
				switch (value1)
				{
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
				var split:Array<String> = value2.split(',');
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(split[0]);
				var val3:Int = Std.parseInt(split[1]);
				var tint:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, val3);
				tint.alpha = 0.001;
				tint.scrollFactor.set(0,0);
				tint.screenCenter();
				behindGfGroup.add(tint);
				FlxTween.tween(tint, {alpha: val1}, 0.25 / playbackRate);
				new FlxTimer().start(val2 / playbackRate, function(tmr:FlxTimer) {
					FlxTween.tween(tint, {alpha: 0}, 0.25 / playbackRate, {
						onComplete: 
						function (twn:FlxTween)
							{
								tint.kill();
								behindGfGroup.remove(tint, true);
								tint.destroy();
							}
					});
				});

			case 'Build Up Tint':
				var val1:Float = Std.parseFloat(value1);
				var val2:Int = Std.parseInt(value2);
				var tint:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, val2);
				tint.alpha = 0.001;
				tint.scrollFactor.set(0,0);
				tint.screenCenter();
				addBehindDad(tint);
				FlxTween.tween(tint, {alpha: 0.95}, val1 / playbackRate, {
					onComplete: function(twn:FlxTween) {
						FlxTween.tween(tint, {alpha: 0}, 0.1);
					}
				});

			case 'Change Zoom Interval':
				var val1:Null<Int> = Std.parseInt(value1);
				if (val1 != null && val1 > -1)
					beatZoomingInterval = val1;
			
			case 'Swap Hud':
				if (!hudIsSwapped) {
					playerStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x - 650}, 0.1 / playbackRate, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x + 650}, 0.1 / playbackRate, {
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
						FlxTween.tween(spr, {x: spr.x + 650}, 0.1 / playbackRate, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x - 650}, 0.1 / playbackRate, {
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
				if (ClientPrefs.flashing)
					camGame.flash(val2, val1 / playbackRate, null, true);

			case 'Flash Camera (HUD)':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				if (ClientPrefs.flashing)
					camHUD.flash(val2, val1 / playbackRate, null, true);

			
			case 'Set Cam Speed':
				var val1:Null<Float> = Std.parseFloat(value1);
				cameraSpeed = val1;

			case 'Hide HUD':
				var val1:Null<Float> = Std.parseFloat(value1);
				var alph:Float = 0;
				if (camHUD.alpha < 0.5) alph = 1;
				FlxTween.tween(camHUD, {alpha: alph}, val1, {ease: FlxEase.quadInOut});

			//this will be abused
			case 'Tween Note Direction':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				if (val1 != null && val2 != null) {
					playerStrums.forEach(function(spr:StrumNote) {
						FlxTween.tween(spr, {direction: val1}, val2 / playbackRate);
					});
					opponentStrums.forEach(function(spr:StrumNote) {
						FlxTween.tween(spr, {direction: val1}, val2 / playbackRate);
					});
					thirdStrums.forEach(function(spr:StrumNote) {
						FlxTween.tween(spr, {direction: val1}, val2 / playbackRate);
					});
				}

			case 'Tween Hud Angle':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				var angleTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					angleTween = FlxTween.tween(camHUD, {angle: val1}, val2 / playbackRate, {
						ease: FlxEase.circInOut
					});
				}
			
			case 'Tween Hud Zoom':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				var zoomTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					zoomTween = FlxTween.tween(camHUD, {zoom: val1}, val2 / playbackRate, {
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
					angleTween = FlxTween.tween(camGame, {angle: val1}, val2 / playbackRate, {
						ease: FlxEase.circInOut
					});
				}
			
			case 'Tween Camera Zoom':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Float> = Std.parseFloat(value2);
				var zoomTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					zoomTween = FlxTween.tween(camGame, {zoom: val1}, val2 / playbackRate, {
						ease: FlxEase.circInOut,
						onComplete: 
						function (twn:FlxTween)
							{
								defaultCamZoom = val1;
							}
					});
				}

			case 'Add Subtitle':
				if (ClientPrefs.subtitles) {
					var split:Array<String> = value2.split(',');
					var val2:Null<Int> = Std.parseInt(split[0]);
					var funnyColor:FlxColor = FlxColor.WHITE;
					var useIco:Bool = false;
					switch (split[0].toLowerCase()) {
						case 'dadicon' | 'dad' | 'oppt' | 'oppticon' | 'opponent':
							funnyColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
							useIco = true;
						case 'bficon' | 'bf' | 'boyfriend' | 'boyfriendicon':
							funnyColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
							useIco = true;
						case 'p4icon' | 'p4' | 'player4' | 'player 4' | 'player4icon' | 'player 4icon':
							funnyColor = FlxColor.fromRGB(player4.healthColorArray[0], player4.healthColorArray[1], player4.healthColorArray[2]);
							useIco = true;
						case 'gficon' | 'gf' | 'girlfriend' | 'girlfriendicon':
							funnyColor = FlxColor.fromRGB(gf.healthColorArray[0], gf.healthColorArray[1], gf.healthColorArray[2]);
							useIco = true;
					}
					var val3:Null<Float> = Std.parseFloat(split[1]);
					var sub:FlxText = new FlxText(0, ClientPrefs.downScroll ? healthBar.y + 90 : healthBar.y - 90, 0, value1, 32);
					sub.scrollFactor.set();
					sub.cameras = [camHUD];
					sub.setFormat(Paths.font("vcr.ttf"), 32, useIco ? funnyColor : val2, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
					var subBG:FlxSprite = new FlxSprite(0, ClientPrefs.downScroll ? healthBar.y + 90 : healthBar.y - 90).makeGraphic(Std.int(sub.width+10), Std.int(sub.height+10), FlxColor.BLACK);
					subBG.scrollFactor.set();
					subBG.cameras = [camHUD];
					subBG.alpha = 0.5;
					subBG.screenCenter(X);
					sub.screenCenter(X);
					sub.y += 5;
					add(subBG);
					add(sub);
					//spawnedSubtitles.push(subBG);
					//howLongIsTheFuckingSubtitlesErm++;
					//subBG.ID = spawnedSubtitles.length;
					//sub.ID = spawnedSubtitles.length;
					//subtitleMap.set('subBG' + subBG.ID, subBG);
					//subtitleMap.set('sub' + sub.ID, sub);
					var tmr:FlxTimer = new FlxTimer().start(val3 / playbackRate, function(timer:FlxTimer) {
						FlxTween.tween(sub, {alpha: 0}, 0.25 / playbackRate, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {
							sub.kill();
							//subtitleMap.remove('sub' + sub.ID);
							sub.destroy();
						}});
						FlxTween.tween(subBG, {alpha: 0}, 0.25 / playbackRate, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {
							subBG.kill();
							//subtitleMap.remove('subBG' + subBG.ID);
							//spawnedSubtitles.remove(subBG);
							subBG.destroy();
						}});
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
		hscript.call('onEvent', [eventName, value1, value2]);
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
			hscript.call('onMoveCamera', ['gf']);
			if (SONG.notes[id].mustHitSection) {
				if (iconP1 != null) {
					iconP1.changeIcon(gf.healthIcon);
					reloadHealthBarColors(false, true, null, true);
					recalculateIconAnimations();
				}
			} else {
				if (iconP2 != null && iconP4 != null && iconP1 != null) {
					iconP1.changeIcon(boyfriend.healthIcon);
					iconP2.changeIcon(gf.healthIcon);
					iconP4.changeIcon(dad.healthIcon);
					reloadHealthBarColors(false, true);
					recalculateIconAnimations();
				}
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
				hscript.call('onMoveCamera', ['dad']);
			} else {
				moveCamera(true, true);
				callOnLuas('onMoveCamera', ['p4']);
				hscript.call('onMoveCamera', ['p4']);
			}
		}
		else
		{
			moveCamera(false, false);
			callOnLuas('onMoveCamera', ['boyfriend']);
			hscript.call('onMoveCamera', ['boyfriend']);
		}
		//sex icons
		if (iconP2 != null && iconP4 != null && iconP1 != null) {
			iconP1.changeIcon(boyfriend.healthIcon);
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
				case true:
					if (iconP1 != null && iconP4 != null && iconP2 != null) {
						iconP4.changeIcon(dad.healthIcon);
						iconP1.changeIcon(player4.healthIcon);
						iconP2.changeIcon(boyfriend.healthIcon);
						reloadHealthBarColors(true);
						recalculateIconAnimations();
					}*/
				//case false:
					if (iconP2 != null && iconP4 != null && iconP1 != null) {
						iconP1.changeIcon(boyfriend.healthIcon);
						iconP4.changeIcon(dad.healthIcon);
						iconP2.changeIcon(player4.healthIcon);
						reloadHealthBarColors(true);
						recalculateIconAnimations();
					}
			//}
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
						//funny mom thing
						if (dad != null && dad.curCharacter != null && SONG != null && SONG.notes != null) {
							if (dad.curCharacter.toLowerCase() == 'parents-christmas' && SONG.notes[publicSection].altAnim) {
								camFollow.x += 180;
								camFollow.y += 10;
							}
						}
						tweenCamIn();
					}
					else
					{
						camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
						camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			
						if (Paths.formatToSongPath(SONG.header.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
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
						camFollow.x += player4.cameraPosition[0] + player4CameraOffset[0];
						camFollow.y += player4.cameraPosition[1] + player4CameraOffset[1];
						tweenCamIn();
					}
					else
					{
						camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
						camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			
						if (Paths.formatToSongPath(SONG.header.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
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
		if (Paths.formatToSongPath(SONG.header.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
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
		hscript.call("onEndSong", []);

		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					intendedHealth -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					intendedHealth -= 0.05 * healthLoss;
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
		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.header.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				var letter:String = ratingName;
				var intensity:String = ratingIntensity;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.header.song, songScore, storyDifficulty, percent, ratingName, ratingIntensity);
				#end
			}
			playbackRate = 1;

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
					#if desktop
					discordUpdateTimer.cancel();
					#end
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.header.validScore)
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
					#if sys
					if(sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))){
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
						LoadingState.globeTrans = false;
						LoadingState.loadAndSwitchState(new PlayState());
					}
					else
					{
						trace('Failed to load next story song: incorrect .json!');
						cancelMusicFadeTween();
						if(FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}
						discordUpdateTimer.cancel();
						MusicBeatState.switchState(new StoryMenuState());
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
						Conductor.changeBPM(100);
						changedDifficulty = false;
					}
					#else
					if(OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))){
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
						LoadingState.globeTrans = false;
						LoadingState.loadAndSwitchState(new PlayState());
					}
					else
					{
						trace('Failed to load next story song: incorrect .json!');
						cancelMusicFadeTween();
						if(FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}
						#if desktop
						discordUpdateTimer.cancel();
						#end
						MusicBeatState.switchState(new StoryMenuState());
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
						Conductor.changeBPM(100);
						changedDifficulty = false;
					}
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
				#if desktop
				discordUpdateTimer.cancel();
				#end
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				Conductor.changeBPM(100);
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

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
			var extraPath:String = '';
			var extraShit:String = "";
			var extraShit2:String = "";
	
			if (PlayState.isPixelStage)
			{
				pixelShitPart1 = 'pixelUI/';
				pixelShitPart2 = '-pixel';
				skinShit = '';
			} else {
				extraPath = 'ratings/';
				skinShit = '-' + ClientPrefs.uiSkin.toLowerCase();
			}
	
			Paths.image(extraPath + pixelShitPart1 + "perfect" + pixelShitPart2 + skinShit);
			Paths.image(extraPath + pixelShitPart1 + "sick" + pixelShitPart2 + skinShit);
			Paths.image(extraPath + pixelShitPart1 + "good" + pixelShitPart2 + skinShit);
			Paths.image(extraPath + pixelShitPart1 + "bad" + pixelShitPart2 + skinShit);
			Paths.image(extraPath + pixelShitPart1 + "shit" + pixelShitPart2 + skinShit);
			Paths.image(extraPath + pixelShitPart1 + "wtf" + pixelShitPart2 + skinShit);
			if (ClientPrefs.comboPopup) {
				Paths.image(extraPath + pixelShitPart1 + "combo" + pixelShitPart2 + skinShit);
			}
			if (SONG.options.crits) {
				Paths.image(extraPath + pixelShitPart1 + "critBG" + pixelShitPart2 + skinShit);
			}
			
			if (!PlayState.isPixelStage) extraShit = "nums/";
			if (skinShit == '-kade') {
				extraShit2 = '-fnf';
			} else {
				extraShit2 = skinShit;
			}

			for (i in 0...10) {
				Paths.image(extraShit + pixelShitPart1 + 'num' + i + pixelShitPart2 + extraShit2);
			}
		}

	public function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		var msTiming:Float = note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset;

		// boyfriend.playAnim('hey');
		if (SONG.header.needsVoices) {
			vocals.volume = SONG.header.vocalsVolume;
			secondaryVocals.volume = SONG.header.secVocalsVolume; }

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
			daRating = Conductor.judgeNote(note, noteDiff / playbackRate);
		} else {
			daRating = Conductor.judgeNote(note, noteDiff / playbackRate, true);
		}

		scoreMulti = 1;
		scoreDivi = 1;
		/*switch (ratingIntensity) {
			case 'Default':
				scoreMulti = 1;
				scoreDivi = 1;
			case 'Harsh':
				scoreMulti = 1;
				scoreDivi = 1;
			case 'Generous':
				scoreMulti = 1;
				scoreDivi = 1;
		}*/
		switch (daRating)
		{
			case "wtf": // wtf
				if (sickOnly) health -= 5;
				if (noteDiff > 205) {
					totalNotesHit += 0;
				} else {
					if (ClientPrefs.accuracyMode == 'Complex') {
						totalNotesHit += -(noteDiff/205 - 1);
					} else {
						totalNotesHit += 0;
					}
				}
				note.ratingMod = 0;
				score = Math.floor((-100 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) wtfs++;
			case "shit": // shit
				if (sickOnly) health -= 5;
				if (ClientPrefs.accuracyMode == 'Complex') {
					totalNotesHit += -(noteDiff/205 - 1);
				} else {
					totalNotesHit += 0.25;
				}
				note.ratingMod = 0.25;
				score = Math.floor((-50 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) shits++;
			case "bad": // bad
				if (sickOnly) health -= 5;
				if (ClientPrefs.accuracyMode == 'Complex') {
					totalNotesHit += -(noteDiff/205 - 1);
				} else {
					totalNotesHit += 0.5;
				}
				note.ratingMod = 0.5;
				score = Math.floor((50 * scoreMulti)/scoreDivi);
				if(!note.ratingDisabled) bads++;
			case "good": // good
				if (sickOnly) health -= 5;
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
		switch (ratingIntensity) {
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
		var extraPath:String = "";

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
			skinShit = '';
		} else {
			extraPath = 'ratings/';
			skinShit = '-' + ClientPrefs.uiSkin.toLowerCase();
		}

		rating.loadGraphic(Paths.image(extraPath + pixelShitPart1 + daRating + pixelShitPart2 + skinShit));
		if (!ClientPrefs.wrongCamera) {
			rating.cameras = [camHUD];
		} else {
			rating.cameras = [camGame];
		}
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];
		if (ClientPrefs.wrongCamera) { 
			rating.y += boyfriend.y;
			rating.x += boyfriend.x;
			rating.y -= isPixelStage ? 400 : 250;
			rating.x -= isPixelStage ? 800 : 600;
			switch(curStage) {
				case 'limo' | 'limoNight':
					rating.acceleration.x = 750 * playbackRate * playbackRate;
			}
		}

		var comboSpr:FlxSprite = new FlxSprite();
		if (ClientPrefs.comboPopup) {
			comboSpr.loadGraphic(Paths.image(extraPath + pixelShitPart1 + 'combo' + pixelShitPart2 + skinShit));
			if (!ClientPrefs.wrongCamera) {
				comboSpr.cameras = [camHUD];
			} else {
				comboSpr.cameras = [camGame];
			}
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
			comboSpr.x += ClientPrefs.comboOffset[0];
			comboSpr.y -= ClientPrefs.comboOffset[1];
			if (ClientPrefs.wrongCamera) { 
				comboSpr.y += boyfriend.y;
				comboSpr.x += boyfriend.x;
				comboSpr.y -= isPixelStage ? 400 : 250;
				comboSpr.x -= isPixelStage ? 800 : 600;
				switch(curStage) {
					case 'limo' | 'limoNight':
						comboSpr.acceleration.x = 750 * playbackRate * playbackRate;
				}
			}
	
			comboSpr.y += 60;
			comboSpr.x += (Math.floor(Math.log(combo) / Math.log(10)) - 1) * 43;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
	
			if(combo >= 10) insert(members.indexOf(strumLineNotes), comboSpr);
		}
		insert(members.indexOf(strumLineNotes), rating);

		if (!ClientPrefs.comboStacking)
		{
			if (lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			if (ClientPrefs.comboPopup) {
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
				comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			if (ClientPrefs.comboPopup) {
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
			}
		}

		if (ClientPrefs.comboPopup) {
			comboSpr.updateHitbox();
		}
		rating.updateHitbox();

		if (ClientPrefs.msPopup) {
			msTxt.visible = ClientPrefs.hideHud ? false : true;
			msTxt.text = FlxMath.roundDecimal(-msTiming, ClientPrefs.msPrecision) + " MS";
			if (msTimer != null) msTimer.cancel();
			msTimer = new FlxTimer().start(0.2 + (Conductor.crochet * 0.0005 / playbackRate), function(tmr:FlxTimer) {
				msTxt.text = '';
				msTxt.visible = false;
			});
			switch (daRating) {
				case 'perfect':
					msTxt.color = FlxColor.YELLOW;
				case 'sick':
					msTxt.color = FlxColor.CYAN;
				case 'good':
					msTxt.color = FlxColor.LIME;
				case 'bad':
					msTxt.color = FlxColor.ORANGE;
				case 'shit':
					msTxt.color = FlxColor.RED;
				case 'wtf':
					msTxt.color = FlxColor.PURPLE;
				default:
					msTxt.color = FlxColor.WHITE;
			}
		}

		var crit = FlxG.random.bool(1); //0.3
		if (daRating == 'perfect') crit = FlxG.random.bool(10);
		if(crit && SONG.options.crits) {
			if(maxHealth < 3) {
				maxHealth += 0.2;
				intendedHealth += 0.2;
				healthBar.x -= 30;
				FlxG.sound.play(Paths.sound('crit'), FlxG.random.float(0.1, 0.2));
			}

			var numBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image(extraPath + pixelShitPart1 + 'critBG' + pixelShitPart2 + skinShit));
			if (!ClientPrefs.wrongCamera) {
				numBG.cameras = [camHUD];
			} else {
				numBG.cameras = [camGame];
			}
			numBG.screenCenter();
			numBG.x = coolText.x - 150;
			if (ClientPrefs.wrongCamera) { 
				numBG.y += boyfriend.y;
				numBG.x += boyfriend.x;
				numBG.y -= isPixelStage ? 400 : 250;
				numBG.x -= isPixelStage ? 800 : 600;
				switch(curStage) {
					case 'limo' | 'limoNight':
						numBG.acceleration.x = 750 * playbackRate * playbackRate;
				}
			}
			numBG.y += 80;

			numBG.x += ClientPrefs.comboOffset[2];
			numBG.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
				{
					numBG.antialiasing = ClientPrefs.globalAntialiasing;
					var floater:Float = 0.6;
					floater += (Math.floor(Math.log(combo) / Math.log(10))) * 0.1;
					numBG.setGraphicSize(Std.int(numBG.width * floater));
				}
				else
				{
					numBG.setGraphicSize(Std.int(numBG.width * daPixelZoom));
				}
				numBG.updateHitbox();
			
			numBG.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numBG.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numBG.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numBG.visible = !ClientPrefs.hideHud;

			insert(members.indexOf(strumLineNotes), numBG);

			if (!ClientPrefs.comboStacking)
			{
				if (lastNumbg != null) lastNumbg.kill();
				lastNumbg = numBG;
			}
			
			FlxTween.tween(numBG, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numBG.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}

		//atpx being clever
		var seperatedScore:Array<Int> = Std.string(combo).split("").map(str -> Std.parseInt(str));

		if (!ClientPrefs.comboStacking && ClientPrefs.comboPopup)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var extraShit:String = "";
			var extraShit2:String = "";

			if (!PlayState.isPixelStage) extraShit = "nums/";
			if (skinShit == '-kade') {
				extraShit2 = '-fnf';
			} else {
				extraShit2 = skinShit;
			}
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(extraShit + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2 + extraShit2));
			if (!ClientPrefs.wrongCamera) {
				numScore.cameras = [camHUD];
			} else {
				numScore.cameras = [camGame];
			}
			numScore.screenCenter();
			numScore.x = ClientPrefs.comboPopup ? coolText.x + (43 * daLoop) - 90 : coolText.x + (43 * daLoop);
			if (!ClientPrefs.comboPopup) {
				if (combo < 10) numScore.x += 13;
				if (combo >= 10) numScore.x += 22;
				numScore.x -= (Math.floor(Math.log(combo) / Math.log(10)) - 1) * 22;
			}
			if (ClientPrefs.wrongCamera) { 
				numScore.y += boyfriend.y;
				numScore.x += boyfriend.x;
				numScore.y -= isPixelStage ? 400 : 250;
				numScore.x -= isPixelStage ? 800 : 600;
				switch(curStage) {
					case 'limo' | 'limoNight':
						numScore.acceleration.x = 750 * playbackRate * playbackRate;
				}
			}
			numScore.y += ClientPrefs.comboPopup ? 80 : 40;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];
			
			if (!ClientPrefs.comboStacking)
				lastScore.push(numScore);

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

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});

		if (ClientPrefs.comboPopup) {
			FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					coolText.destroy();
					comboSpr.destroy();
	
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}
	}

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (key == -1 || cpuControlled || paused) return;
		//trace('Pressed: ' + eventKey);

		if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)/* || ClientPrefs.controllerMode*/)
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !tappy;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				//dont do useless checks, it just adds lag
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
						}

						if (ratingIntensity == 'Harsh')
							canMiss = true;
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
					hscript.call('noteMissPress', [key]);
				}
				else if (!canMiss)
				{
					gsTap(key, ClientPrefs.gsmiss ? true : false);
				}

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
			hscript.call("onKeyPressed", [key]);
		}
		//trace('pressed: ' + key);
	}
	
	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (key == -1 || cpuControlled || paused) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnLuas('onKeyRelease', [key]);
		hscript.call("onKeyReleased", [key]);
		//trace('released: ' + key);
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
		
	// Hold notes
	public function keyShit():Void
	{
		// TO DO: Find a better way to handle controller inputs, this should work for now
		/*if(ClientPrefs.controllerMode)
		{
			//var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			var controlArray:Array<Bool> = [];
			var man:String = 'note_';
			for (i in 0...mania) {
				trace (i);
				switch (mania) {
					case 0: man += 'one';
					case 1: man += 'two';
					case 2: man += 'three';
					case 4: man += 'five';
					case 5: man += 'six';
					case 6: man += 'seven';
					case 7: man += 'eight';
					case 8: man += 'nine';
					default: man += 'four';
				}
				man += (i+1);
				var key1:FlxKey = (ClientPrefs.keyBinds.get(man)[0]);
				var key2:FlxKey = (ClientPrefs.keyBinds.get(man)[1]);
				if(FlxG.keys.anyPressed([key1, key2])) {
					controlArray.push(true);
				} else {
					controlArray.push(false);
				}
				man = 'note_';
			}
			
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}*/

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && dataKeyIsPressed(daNote.noteData % Note.ammo[mania]) && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss') && SONG.options.autoIdles)
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		/*if(ClientPrefs.controllerMode)
		{
			//var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			var controlArray:Array<Bool> = [];
			var man:String = 'note_';
			for (i in 0...mania) {
				trace (i);
				switch (mania) {
					case 0: man += 'one';
					case 1: man += 'two';
					case 2: man += 'three';
					case 4: man += 'five';
					case 5: man += 'six';
					case 6: man += 'seven';
					case 7: man += 'eight';
					case 8: man += 'nine';
					default: man += 'four';
				}
				man += (i+1);
				var key1:FlxKey = (ClientPrefs.keyBinds.get(man)[0]);
				var key2:FlxKey = (ClientPrefs.keyBinds.get(man)[1]);
				if(FlxG.keys.anyPressed([key1, key2])) {
					controlArray.push(true);
				} else {
					controlArray.push(false);
				}
				man = 'note_';
			}

			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}*/
	}

	public function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		if (sickOnly) health -= 5;
		var sustainMisser:Bool = false;
		switch (ratingIntensity){
			case 'Default':
				sustainMisser = FlxG.random.bool(50);
			case 'Generous':
				sustainMisser = false;
			case 'Harsh':
				sustainMisser = true;
		}
		var doReturn = false;
		if (daNote.isSustainNote && !sustainMisser) {
			doReturn = true;
		}
		if (doReturn) return;
		if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;
	
			if(ClientPrefs.flinchy) {
				var time:Float = 0.5;
				flinching = true;
				recalculateIconAnimations();
				if (flinchTimer != null) {
					flinchTimer.cancel();
				}
				if (poison) {
					time = 3;
				}
				flinchTimer = new FlxTimer().start(time, function(tmr:FlxTimer)
				{
					flinching = false;
					recalculateIconAnimations();	
				});
			}
			
			if (SONG.options.dangerMiss) {
				maxHealth -= 0.10;
			}
			intendedHealth -= daNote.missHealth * healthLoss;
			if (poison) {
				poisonRoutine();
			}
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}
			if(freeze) {
				freezeRoutine();
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
			callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
			hscript.call("noteMiss", [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	
			var char:Character = boyfriend;
			if(daNote.gfNote) {
				char = gf;
			}
	
			if(char != null && char.hasMissAnimations)
			{
				if (freeze && char.stunned) return;

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
	}

	public function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (boyfriend.stunned) return;
		if (tappy) return;

		if (SONG.options.dangerMiss) { //MAX HEALTH HERE
			maxHealth -= 0.10;
		}
		intendedHealth -= 0.05 * healthLoss;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			secondaryVocals.volume = 0;
			doDeathCheck(true);
		}

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

		if (ClientPrefs.missSoundVolume > 0)
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missSoundVolume);

		if(boyfriend.hasMissAnimations) {
			boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + 'miss', true);
		}
		vocals.volume = 0;
	}

	public function gsTap(direction:Int = 1, ?miss:Bool = false):Void //GS Tap Miss
	{
		var missStr:String = '';
		var freezeCheck:Bool = false;
		if (miss) missStr = 'miss';
		if (freeze) freezeCheck = true;
		if (freezeCheck && boyfriend.stunned) return;

		if(ClientPrefs.flinchy && miss) {
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

		if (!boyfriend.hasMissAnimations)
			missStr = '';

		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[direction] + missStr;
		var noAnimation:String = 'singUP' + missStr;
		if (boyfriend.animOffsets.exists(animToPlay)) {
			boyfriend.playAnim(animToPlay, true);
		} else {
			boyfriend.playAnim(noAnimation, true);
		}
	}

	public function opponentNoteHit(note:Note, ?p4:Bool = false):Void
	{
		if (Paths.formatToSongPath(SONG.header.song) != 'tutorial')
			camZooming = true;

		var char:Character = dad;
		var cfgrp:FlxTypedGroup<CrossFade> = grpCrossFade;
		if (p4) {
			char = player4;
			cfgrp = grpP4CrossFade;
		} 
		if(note.gfNote)
			char = gf;

		if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
			char.playAnim('hey', true);
			char.specialAnim = true;
			char.heyTimer = 0.6;
			if (char != gf) {
				dadmirror.playAnim('hey', true);
				dadmirror.specialAnim = true;
				dadmirror.heyTimer = 0.6;
			}
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			if (SONG.notes[publicSection] != null)
			{
				if ((SONG.notes[publicSection].altAnim || note.noteType == 'Alt Animation') && !SONG.notes[publicSection].gfSection)
					altAnim = '-alt';
			}

			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData] + altAnim;
			var noAnimation:String = 'singUP' + altAnim;

			if(char != null)
			{
				if (char.animOffsets.exists(animToPlay))
					char.playAnim(animToPlay, true);
				else
					char.playAnim(noAnimation, true);
				
				char.holdTimer = 0;
				if (ClientPrefs.camPans)
					camPanRoutine(animToPlay, 'oppt', char.curCharacter);

				if (char != gf) {
					if (dadmirror.animOffsets.exists(animToPlay))
						dadmirror.playAnim(animToPlay, true);
					else
						dadmirror.playAnim(noAnimation, true);

					dadmirror.holdTimer = 0;
				}
			}
			if (SONG.notes[publicSection] != null)
				{
					if (SONG.notes[publicSection].crossFade) {
						var charstore = char;
						if (SONG.notes[publicSection].gfSection && !SONG.notes[publicSection].player4Section) {
							char = gf;
							cfgrp = gfCrossFade;
						}
						if (ClientPrefs.crossFadeMode != 'Off' && !note.isSustainNote)
							new CrossFade(char, cfgrp, true);
						char = charstore;
					}
				}
			switch (note.noteType) {
				case 'Cross Fade':
					if (ClientPrefs.crossFadeMode != 'Off' && !note.isSustainNote)
						new CrossFade(char, cfgrp, true);
				case 'GF Cross Fade':
					if (ClientPrefs.crossFadeMode != 'Off' && !note.isSustainNote)
						new CrossFade(gf, gfCrossFade, true);
			}
		}

		if (SONG.header.needsVoices) {
			if (freeze) {
				if (!boyfriend.stunned) vocals.volume = SONG.header.vocalsVolume;
			} else {
				vocals.volume = SONG.header.vocalsVolume;
			}
			secondaryVocals.volume = SONG.header.secVocalsVolume;
		}

		if(char.healthDrain){
			if (intendedHealth > char.drainFloor)
				intendedHealth -= 0.01;
		}

		if(char.shakeScreen) {
			FlxG.camera.shake(0.0075, 0.1/playbackRate);
			camHUD.shake(0.0045, 0.1/playbackRate);
		}
		if(char.scareBf && boyfriend != null && boyfriend.animOffsets.exists('scared'))
			boyfriend.playAnim('scared', true);

		if(char.scareGf && gf != null && gf.animOffsets.exists('scared'))
			gf.playAnim('scared', true);

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
			time += 0.15;

		if(ClientPrefs.opponentNoteAnimations)
			StrumPlayAnim(0, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);

		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, char.curCharacter]);
		hscript.call('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, char.curCharacter]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	public function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (ClientPrefs.scoreDisplay == 'Kade') {
				if (!note.isSustainNote) npsArray.unshift(Date.now());
			}
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				if (hitSound == 'GF_') {
					var number:Int = note.noteData;
					number++;
					if (number > 3) number = FlxG.random.int(1,4);
					//trace(hitSound + number);
					FlxG.sound.play(Paths.sound(hitSound + number), ClientPrefs.hitsoundVolume);
				} else {
					FlxG.sound.play(Paths.sound(hitSound), ClientPrefs.hitsoundVolume);
				}
			}

			if(boyfriend.shakeScreen) {
				FlxG.camera.shake(0.0075, 0.1/playbackRate);
				camHUD.shake(0.0045, 0.1/playbackRate);
			}
			if(boyfriend.scareBf && dad != null && dad.animOffsets.exists('scared'))
				dad.playAnim('scared', true);

			if(boyfriend.scareGf && gf != null && gf.animOffsets.exists('scared'))
				gf.playAnim('scared', true);

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
				if(highestCombo < combo) highestCombo = combo;
				popUpScore(note);
			}
			intendedHealth += note.hitHealth * healthGain;

			var resetFlinch:Bool = false;
			if (!poison && flinching) {
				resetFlinch = true;
			} else if (poison && flinching && poisonMult == 0) {
				resetFlinch = true;
				iconP1Poison.visible = false;
			}
			if (resetFlinch) {
				flinching = false;
				if (flinchTimer != null) flinchTimer.cancel();
				recalculateIconAnimations();
			}

			if(!note.noAnimation)
			{
				var daAlt = '';
	
				var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
				var noAnimation:String = 'singUP';
				var char = (note.gfNote && gf != null) ? gf : boyfriend;

				if (ClientPrefs.camPans) {
					camPanRoutine(animToPlay, 'bf', char.curCharacter);
				}

				if(note.noteType == 'Alt Animation'){
					daAlt = '-alt';
				}

				if (char.animOffsets.exists(animToPlay)) {
					char.playAnim(animToPlay + daAlt, true);
				} else {
					char.playAnim(noAnimation, true);
				}
				char.holdTimer = 0;

				if(note.noteType == 'Hey!') {
					if(char.animOffsets.exists('hey'))
					{
						char.playAnim('hey', true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
					if(char != gf && gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}

				if (SONG.notes[publicSection] != null)
				{
					if (SONG.notes[publicSection].crossFade) {
						if (SONG.notes[publicSection].gfSection) {
							if (ClientPrefs.crossFadeMode != 'Off' && !note.isSustainNote)
								new CrossFade(gf, gfCrossFade, true);
						} else {
							if (ClientPrefs.crossFadeMode != 'Off' && !note.isSustainNote)
								new BFCrossFade(boyfriend, grpBFCrossFade);
						}
					}
				}
		
				switch(note.noteType)
				{
					case 'Cross Fade': //CF note
						if (ClientPrefs.crossFadeMode != 'Off' && !note.isSustainNote)
							new BFCrossFade(boyfriend, grpBFCrossFade);
					case 'GF Cross Fade': //GFCF note
						if (ClientPrefs.crossFadeMode != 'Off' && !note.isSustainNote)
							new CrossFade(gf, gfCrossFade, true);
				}
			}

			if(cpuControlled)
			{
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					time += 0.15;

				StrumPlayAnim(1, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
						spr.playAnim('confirm', true);
				});
			}
			note.wasGoodHit = true;
			if (SONG.header.needsVoices) {
				vocals.volume = SONG.header.vocalsVolume;
				secondaryVocals.volume = SONG.header.secVocalsVolume;
			}

			callOnLuas('goodNoteHit', [notes.members.indexOf(note), Math.round(Math.abs(note.noteData)), note.noteType, note.isSustainNote]);
			hscript.call('goodNoteHit', [notes.members.indexOf(note), Math.round(Math.abs(note.noteData)), note.noteType, note.isSustainNote]);

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
		if(PlayState.SONG.assets.splashSkin != null && PlayState.SONG.assets.splashSkin.length > 0) skin = PlayState.SONG.assets.splashSkin;
		
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

	var billBoardCanBill:Bool = true;

	public function resetBillBoard():Void
	{
		billBoard.x = -12600;
		billBoard.y = FlxG.random.int(-840, -1050);
		billBoard.velocity.x = 0;
		billBoardCanBill = true;
		switch(FlxG.random.int(0,2)) {
			case 0:
				billBoardWho = 'limo/fastMomLol';
			case 1:
				billBoardWho = 'limo/fastBfLol';
			case 2:
				billBoardWho = 'limo/fastPicoLol';
		}
		billBoard.loadGraphic(Paths.image(billBoardWho));
	}

	var billTimer:FlxTimer;
	public function billBoardBill()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		billBoard.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		billBoardCanBill = false;
		billTimer = new FlxTimer().start(FlxG.random.int(4,8), function(tmr:FlxTimer)
		{
			resetBillBoard();
			billTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	public function trainStart(?cutscene:Bool = false):Void
	{
		trainMoving = true;
		if (!trainSound.playing && !cutscene)
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
		if(!ClientPrefs.lowQuality && curStage == 'spooky') {
			halloweenBG.animation.play('halloweem bg lightning strike');
		} 

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
			halloweenWhite.visible = true;
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0.001}, 0.25, {startDelay: 0.15, onComplete: function(twn:FlxTween) {
				halloweenWhite.visible = false;
			}});
		}
	}

	public function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && (curStage == 'limo' || curStage == 'limoNight')) {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;
			}
		}
	}

	public function resetLimoKill():Void
	{
		if(curStage == 'limo' || curStage == 'limoNight') {
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

	public function rosesLightningStrike():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) {
			var fuck:Int = FlxG.random.int(0,2);
			for (rosesLightning in rosesLightningGrp) {
				if (rosesLightning.ID == fuck) {
					rosesLightning.visible = true;
					rosesLightning.alpha = 0.7;
					FlxTween.tween(rosesLightning, {alpha: 1}, 0.075);
					FlxTween.tween(rosesLightning, {alpha: 0.001}, 0.75, {startDelay: 0.15, onComplete: function(twn:FlxTween) {
						rosesLightning.visible = false;
					}});
				}
			}
			for (schoolClouds in schoolCloudsGrp) {
				if (schoolClouds.ID == fuck) {
					schoolClouds.color = 0xffffffff;
					FlxTween.color(schoolClouds, 0.95, schoolClouds.color, 0xffdadada, {startDelay: 0.15});
				} else {
					schoolClouds.color = 0xffebebeb;
					FlxTween.color(schoolClouds, 0.95, schoolClouds.color, 0xffdadada, {startDelay: 0.15});
				}
			}
		}

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.visible = true;
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0.001}, 0.25, {startDelay: 0.15, onComplete: function(twn:FlxTween) {
				halloweenWhite.visible = false;
			}});
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
		hscript.call("onDestroy", []);

		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		//if(!ClientPrefs.controllerMode)
		//{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		//}
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
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
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.header.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		switch (SONG.header.song.toLowerCase()) {
			case 'eggnog':
				switch (curStep) {
					case 937:
						eggnogEndCutscene();
				}
			case 'guns':
				switch (curStep) {
					case 896:
						gunsThing.visible = true;
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
					case 1024:
						raiseTankman = false;
					case 1152:
						tankmanRainbow = false;
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
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								gunsThing.visible = false;
								gunsThing.kill();
								gunsThing.destroy();
							}
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
				}
			case 'stress':
				switch (curStep) {
					case 736:
						opponentStrums.forEach(function(spr:FlxSprite)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.5/playbackRate, {ease: FlxEase.quadInOut, startDelay: 0.5});
						});
					case 765:
						opponentStrums.forEach(function(spr:FlxSprite)
						{
							FlxTween.tween(spr, {alpha: 1}, 0.2/playbackRate, {ease: FlxEase.quadInOut});
						});
				}
			case 'thorns':
				switch (curStep) {
					case 127:
						if (!ClientPrefs.lowQuality) {
							waveEffectBG.speed += 2;
							waveEffectFG.speed += 3;
						}
					case 256 | 639:
						if (!ClientPrefs.lowQuality) {
						waveEffectBG.speed -= 1;
						waveEffectFG.speed -= 3;
						}
					case 384 | 767:
						if (!ClientPrefs.lowQuality) {
						waveEffectBG.speed += 1;
						waveEffectFG.speed += 2;
						}
					case 512 | 895:
						if (!ClientPrefs.lowQuality) {
						waveEffectBG.speed += 1;
						waveEffectFG.speed += 1;
						}
					case 1151:
						if (ClientPrefs.flashing) {
							camGame.flash(FlxColor.RED, 1, null, true);
						}
						if (!ClientPrefs.lowQuality) {
						waveEffectBG.speed = 3;
						waveEffectBG.direction = HORIZONTAL;
						waveEffectFG.speed = 5;
						waveEffectFG.direction = HORIZONTAL;
						}
					case 1023:
						if (ClientPrefs.flashing) {
							camGame.flash(FlxColor.RED, 1, null, true);
						}
						if (!ClientPrefs.lowQuality) {
						waveEffectBG.speed = 5;
						waveEffectBG.direction = VERTICAL;
						waveEffectFG.speed = 7;
						waveEffectFG.direction = VERTICAL;
						}
					case 1279:
						if (!ClientPrefs.lowQuality) {
						waveEffectBG.speed = 0;
						waveEffectFG.speed = 0;
						}
					case 1311:
						thornsEndCutscene();
				}
			case 'roses':
				if (canIUseTheCutsceneMother()) {
					switch (curStep) {
						case 704:
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom-0.08}, 0.25, {ease: FlxEase.quadInOut, onComplete: function(twn:FlxTween) {
								defaultCamZoom = FlxG.camera.zoom;
							}});
					}
				}
			case 'monster':
				if (usingAlt) {
					switch (curStep){
						case 1:
							FlxTween.tween(camTint, {alpha: 0.65}, 3);
						case 272:
							FlxTween.tween(camTint, {alpha: 0.45}, 3);
						case 544 | 1248:
							FlxTween.tween(camTint, {alpha: 0.65}, 1.2);
						case 784:
							FlxTween.tween(camTint, {alpha: 0.2}, 0.25);
						case 905:
							FlxTween.tween(camTint, {alpha: 0.55}, 2);
					}		
				}
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
		hscript.call('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var lastBeatHit:Int = -1;
	var gunsColorIncrementor:Int = 0;
	public var beatZoomingInterval:Int = 4;
	
	override public function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (curBeat % 4 == 0)
			publicSection++;

		//if behind to prevent desync
		if (publicSection < Math.floor(curStep/16))
			publicSection = Math.floor(curStep/16);

		//if ahead for ditto
		if (publicSection > Math.ceil(curStep/16))
			publicSection = Math.floor(curStep/16);

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[publicSection] != null)
		{
			if (SONG.notes[publicSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[publicSection].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[publicSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[publicSection].altAnim);
			setOnLuas('gfSection', SONG.notes[publicSection].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[publicSection] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(publicSection);
		}
		if (beatZoomingInterval > 0) {
			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % beatZoomingInterval == 0 && SONG.options.autoZooms)
				{
					FlxG.camera.zoom += 0.015;
					camHUD.zoom += 0.03;
				}
		}

		if (SONG.options.beatDrain) {
			if (intendedHealth > 0.10) {
				intendedHealth -= 0.0475 * 0.5;
			}
		}

		if(SONG.options.autoIcons){
		switch (curIconSwing)
		{
			case 'Swing':
			if (curBeat % gfSpeed == 0) {
				curBeat % (gfSpeed * 2) == 0 ? {
					iconP1.scale.set(1.1, 0.8);
					iconP1Poison.scale.set(1.1, 0.8);
					iconP2.scale.set(1.1, 1.3);
					iconP4.scale.set(0.85, 1.1);
	
					FlxTween.angle(iconP1, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1Poison, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP2, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP4, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				} : {
					iconP1.scale.set(1.1, 1.3);
					iconP1Poison.scale.set(1.1, 1.3);
					iconP2.scale.set(1.1, 0.8);
					iconP4.scale.set(0.85, 0.65);
	
					FlxTween.angle(iconP2, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP4, -15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.angle(iconP1Poison, 15, 0, Conductor.crochet / 1300 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				}
	
				FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP1Poison, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
				FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
	
				iconP1.updateHitbox();
				iconP1Poison.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			}
			case 'Squish':
				if (curBeat % gfSpeed == 0) {
					curBeat % (gfSpeed * 2) == 0 ? {
						iconP1.scale.set(1.3, 0.3);
						iconP1Poison.scale.set(1.3, 0.3);
						iconP2.scale.set(0.3, 1.7);
						iconP4.scale.set(0.265, 1.4);
					} : {
						iconP1.scale.set(0.3, 1.3);
						iconP1Poison.scale.set(0.3, 1.3);
						iconP2.scale.set(1.3, 0.3);
						iconP4.scale.set(1.1, 0.265);
					}
		
					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP1Poison, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
		
					iconP1.updateHitbox();
					iconP1Poison.updateHitbox();
					iconP2.updateHitbox();
					iconP4.updateHitbox();
				}
			case 'Bop':
				iconP1.scale.set(1.2, 1.2);
				iconP1Poison.scale.set(1.2, 1.2);
				iconP2.scale.set(1.2, 1.2);
				iconP4.scale.set(1, 1);
		
				iconP1.updateHitbox();
				iconP1Poison.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Old':
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP1Poison.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));
				iconP4.setGraphicSize(Std.int(iconP4.width + 30));
		
				iconP1.updateHitbox();
				iconP1Poison.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
			case 'Snap':
				if (curBeat % gfSpeed == 0) {
					curBeat % (gfSpeed * 2) == 0 ? {
						iconP1.scale.set(1.1, 0.8);
						iconP1Poison.scale.set(1.1, 0.8);
						iconP2.scale.set(1.1, 1.3);
						iconP4.scale.set(0.85, 1.1);
		
						iconP1.angle = -15;
						iconP1Poison.angle = -15;
						iconP2.angle = 15;
						iconP4.angle = 15;
					} : {
						iconP1.scale.set(1.1, 1.3);
						iconP1Poison.scale.set(1.1, 1.3);
						iconP2.scale.set(1.1, 0.8);
						iconP4.scale.set(0.85, 0.65);
		
						iconP2.angle = -15;
						iconP4.angle = -15;
						iconP1.angle = 15;
						iconP1Poison.angle = 15;
					}
		
					FlxTween.tween(iconP1, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP1Poison, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP2, {'scale.x': 1, 'scale.y': 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
					FlxTween.tween(iconP4, {'scale.x': 0.75, 'scale.y': 0.75}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {ease: FlxEase.quadOut});
		
					iconP1.updateHitbox();
					iconP1Poison.updateHitbox();
					iconP2.updateHitbox();
					iconP4.updateHitbox();
				}
			case 'Stretch':
				var funny:Float = (healthBar.percent * 0.01) + 0.01;
				iconP1.setGraphicSize(Std.int(iconP1.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
				iconP1Poison.setGraphicSize(Std.int(iconP1.width + (50 * funny)),Std.int(iconP2.height - (25 * funny)));
				iconP2.setGraphicSize(Std.int(iconP2.width + (50 * (2 - funny))),Std.int(iconP2.height - (25 * (2 - funny))));
				iconP4.setGraphicSize(Std.int(iconP4.width + (25 * (2 - funny))),Std.int(iconP4.height - (12 * (2 - funny))));
		
				iconP1.updateHitbox();
				iconP1Poison.updateHitbox();
				iconP2.updateHitbox();
				iconP4.updateHitbox();
		}
		}

		if (SONG.options.autoIdles){
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
			} else if (!ClientPrefs.opponentAlwaysDance && SONG.notes[publicSection].mustHitSection) {
				dad.dance();
				dadmirror.dance();
			}
		}
		if (curBeat % player4.danceEveryNumBeats == 0 && player4.animation.curAnim != null && !player4.animation.curAnim.name.startsWith('sing') && !player4.stunned)
		{
			player4.dance();
		}
		}

		switch (curStage)
		{
			case 'tank':
				if(!ClientPrefs.lowQuality && SONG.options.autoIdles) tankWatchtower.dance();
				if(SONG.options.autoIdles){
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
				}
				switch (SONG.header.song.toLowerCase()) {
					case 'guns':
						if (curBeat % 4 == 0 && tankmanRainbow && gunsThing != null) {
							if (gunsTween != null) gunsTween.cancel();
							gunsTween = null;
							gunsTween = FlxTween.color(gunsThing, 1, gunsThing.color, gunsColors[gunsColorIncrementor]);
							gunsColorIncrementor++;
							if (gunsColorIncrementor > 5) gunsColorIncrementor = 0;
						}
				}
			case 'school':
				if(!ClientPrefs.lowQuality && SONG.options.autoIdles) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality && SONG.options.autoIdles) {
					upperBoppers.dance(true);
				}

				if(SONG.options.autoIdles){
				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);
				}

			case 'limo':
				if(!ClientPrefs.lowQuality && SONG.options.autoIdles) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
				if (FlxG.random.bool(5) && billBoardCanBill) //7
					billBoardBill();
			case 'limoNight':
				if(!ClientPrefs.lowQuality && SONG.options.autoIdles) {
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
		timeTxtTween = FlxTween.tween(timeTxt.scale, {x: 1, y: 1}, Conductor.crochet / 1250 / playbackRate * gfSpeed, {
			onComplete: function(twn:FlxTween) {
				timeTxtTween = null;
			}
		});

		if ((curStage == 'spooky' || curStage == 'streetlight') && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		if ((curStage == 'school') && SONG.header.song.toLowerCase() == 'roses' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			rosesLightningStrike();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
		hscript.call('onBeatHit', []);
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
			switch (ratingFC) {
				case "PFC":
					perfectMode = true;
					fullComboMode = false;
				case "SFC" | "GFC" | "FC":
					perfectMode = false;
					fullComboMode = true;
				default:
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
						scoreTxt.text = 'Score: ' + songScore + ' | Breaks: ' + songMisses + ' | Rating: ' + ratingName;
					default:
						scoreTxt.text = 'Score: ' + songScore + ' | Breaks: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
				}
			case 'Kade':
				scoreTxt.text = 'NPS/MAX: ' + notesPerSecond + '/' + maxNps + ' | SCORE:' + songScore + ' | BREAKS:' + songMisses + ' | ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%' + ' | (' + ratingFC + ') ' + ratingName;
			case 'Sarvente':
				if (perfectMode) {
					scoreTxt.text = 'RATING: PERFECT COMBO';
					deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
					sarvRightTxt.text = 'SCORE:' + songScore;
					sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
					scoreTxtBg.color = FlxColor.YELLOW;
					sarvAccuracyBg.color = FlxColor.YELLOW;
				} else if (fullComboMode) {
					scoreTxt.text = 'RATING: FULL COMBO';
					deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
					sarvRightTxt.text = 'SCORE:' + songScore;
					sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
					scoreTxtBg.color = 0xffff9100;
					sarvAccuracyBg.color = 0xffff9100;
				} else {
					scoreTxt.text = 'RATING:' + ratingName;
					deathTxt.text = 'DEATHS:' + deathCounter + ' BREAKS:' + songMisses;
					sarvRightTxt.text = 'SCORE:' + songScore;
					sarvAccuracyTxt.text = 'ACCURACY: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';
					switch (ratingName)
					{
						case 'X':
							scoreTxtBg.color = FlxColor.YELLOW;
							sarvAccuracyBg.color = FlxColor.YELLOW;
						case 'S':
							scoreTxtBg.color = FlxColor.CYAN;
							sarvAccuracyBg.color = FlxColor.CYAN;
						case 'A':
							scoreTxtBg.color = FlxColor.RED;
							sarvAccuracyBg.color = FlxColor.RED;
						default: 
							scoreTxtBg.color = FlxColor.BLACK;
							sarvAccuracyBg.color = FlxColor.BLACK;
					}
				}
			case 'FPS+':
				scoreTxt.text = 'Score: ' + songScore + ' | Breaks: ' + songMisses + ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%';//peeps wanted no integer rating
			case 'FNF+':
				sarvRightTxt.text = 'HP\n' + healthBar.percent + '%\n\nACCURACY\n' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%\n\nSCORE\n' + songScore;
			case 'Vanilla':
				sarvRightTxt.text = 'Score:' + songScore;
			case 'FNM':
				sarvRightTxt.text = 'score:' + songScore;
		}

		if (ClientPrefs.ratingsDisplay) {
			ratingsTxt.text = "Max Combo:"+highestCombo
			+"\nCombo:"+combo
			+"\nPerfects:"+perfects
			+"\nSicks:"+sicks
			+"\nGoods:"+goods
			+"\nBads:"+bads
			+"\nShits:"+shits
			+"\nWTFs:"+wtfs
			+"\nMisses:"+songMisses;
		}
	}

	public function recalculateIconAnimations(?forceNeutral:Bool = false) {
		//find less buggy way of doing this
		if (cpuControlled) {
			iconP1.changeIcon('botfriend');
			iconP1Poison.changeIcon('botfriend');
		} else if (iconP1.getCharacter() != boyfriend.healthIcon) {
			iconP1.changeIcon(boyfriend.healthIcon);
			iconP1Poison.changeIcon(boyfriend.healthIcon);
		}
		if (!forceNeutral) {
			switch (iconP1.widthThing) {
				case 150:
					if (flinching){
						if (poison) {
							if(!ClientPrefs.hideHud) iconP1Poison.visible = true;
							if (SONG.notes[publicSection].player4Section) {
								reloadHealthBarColors(true, null, true);
							} else {
								reloadHealthBarColors(false, null, true);
							}
						}
					}
					else
					{
						iconP1.animation.curAnim.curFrame = 0; //Neutral BF
						iconP1Poison.animation.curAnim.curFrame = 0;
					}
				case 300:
					if (flinching){
						if (poison) {
							if(!ClientPrefs.hideHud) iconP1Poison.visible = true;
							if (SONG.notes[publicSection].player4Section) {
								reloadHealthBarColors(true, null, true);
							} else {
								reloadHealthBarColors(false, null, true);
							}
						}
						iconP1.animation.curAnim.curFrame = 1;
						iconP1Poison.animation.curAnim.curFrame = 1;
					}
					else
					{
						if (healthBar.percent < 20) {
							iconP1.animation.curAnim.curFrame = 1; //Losing BF
							iconP1Poison.animation.curAnim.curFrame = 1;
						} else if (healthBar.percent > 20) {
							iconP1.animation.curAnim.curFrame = 0; //Neutral BF
							iconP1Poison.animation.curAnim.curFrame = 0;
						}
					}
				case 450:
					if (flinching){
						if (poison) {
							if(!ClientPrefs.hideHud) iconP1Poison.visible = true;
							if (SONG.notes[publicSection].player4Section) {
								reloadHealthBarColors(true, null, true);
							} else {
								reloadHealthBarColors(false, null, true);
							}
						}
						iconP1.animation.curAnim.curFrame = 1;
						iconP1Poison.animation.curAnim.curFrame = 1;
					}
					else
					{
						if (healthBar.percent < 20) {
							iconP1.animation.curAnim.curFrame = 1; //Losing BF
							iconP1Poison.animation.curAnim.curFrame = 1;
						} else if (healthBar.percent > 20 && healthBar.percent < 80) {
							iconP1.animation.curAnim.curFrame = 0; //Neutral BF
							iconP1Poison.animation.curAnim.curFrame = 0;
						} else if (healthBar.percent > 80) {
							iconP1.animation.curAnim.curFrame = 2; //Winning BF
							iconP1Poison.animation.curAnim.curFrame = 2;
						}
					}
			}
			switch (iconP2.widthThing) {
				case 150:
					iconP2.animation.curAnim.curFrame = 0; //Nuetral Oppt
				case 300:
					if (healthBar.percent < 80) {
						iconP2.animation.curAnim.curFrame = 0; //Nuetral Oppt
					} else if (healthBar.percent > 80) {
						iconP2.animation.curAnim.curFrame = 1; //Losing Oppt
					}
				case 450:
					if (healthBar.percent < 20) {
						iconP2.animation.curAnim.curFrame = 2; //Winning Oppt
					} else if (healthBar.percent > 20 && healthBar.percent < 80) {
						iconP2.animation.curAnim.curFrame = 0; //Nuetral Oppt
					} else if (healthBar.percent > 80) {
						iconP2.animation.curAnim.curFrame = 1; //Losing Oppt
					}
			}
			switch (iconP4.widthThing) {
				case 150:
					iconP4.animation.curAnim.curFrame = 0; //Nuetral p4
				case 300:
					if (healthBar.percent < 80) {
						iconP4.animation.curAnim.curFrame = 0; //Nuetral p4
					} else if (healthBar.percent > 80) {
						iconP4.animation.curAnim.curFrame = 1; //Losing p4
					}
				case 450:
					if (healthBar.percent < 20) {
						iconP4.animation.curAnim.curFrame = 2; //Winning p4
					} else if (healthBar.percent > 20 && healthBar.percent < 80) {
						iconP4.animation.curAnim.curFrame = 0; //Nuetral p4
					} else if (healthBar.percent > 80) {
						iconP4.animation.curAnim.curFrame = 1; //Losing p4
					}
			}
		} else {
			iconP1.animation.curAnim.curFrame = 0;
			iconP1Poison.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
			iconP4.animation.curAnim.curFrame = 0;
		}
	}

	public function addGlitchShader(sprite:Dynamic, amplitude:Float, frequency:Float, speed:Float):Void {
		if ((sprite is ModchartSprite || sprite is FlxSprite) && sprite.shader != null) {
			sprite.shader = null;
		}
		var testshader:GlitchEffect = new GlitchEffect();
		testshader.waveAmplitude = amplitude;
		testshader.waveFrequency = frequency;
		testshader.waveSpeed = speed;
		if (sprite is ModchartSprite) {
			sprite.shader = testshader.shader;
			luabg = sprite;
		} else if (sprite is FlxSprite) {
			sprite.shader = testshader.shader;
			curbg = sprite;
		}
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

	function quartizRoutine():Void {
		var quartiz:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('quartiz'));
		quartiz.x = FlxG.random.int(0, FlxG.width);
		quartiz.y = FlxG.random.int(0, FlxG.height);
		quartiz.angle = FlxG.random.int(0, 359);
		quartiz.alpha = FlxG.random.float(0.06, 1);
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
		if (FlxG.random.bool(12.5)) {
			switch(FlxG.random.int(0,3)) {
				case 0:
					FlxTween.tween(quartiz, {x: quartiz.x + FlxG.random.int(-150,150)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
				case 1:
					FlxTween.tween(quartiz, {y: quartiz.y + FlxG.random.int(-150,150)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
				case 2:
					FlxTween.tween(quartiz, {angle: quartiz.angle + FlxG.random.int(-150,150)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
				case 3:
					FlxTween.tween(quartiz, {x: quartiz.x + FlxG.random.int(-150,150), y: quartiz.y + FlxG.random.int(-150,150)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
			}
		}
		add(quartiz);
	}

	function poisonRoutine():Void {
		poisonMult += 0.038;
		for (poisonSprite in poisonSpriteGrp) {
			poisonSprite.visible = true;
			if (poisonSprite.alpha < 1) FlxTween.tween(poisonSprite, {alpha: 1}, 0.2);
		}
		if (poisonTimer != null) {
			poisonTimer.cancel();
			poisonTimer = null;
		}
		poisonTimer = new FlxTimer().start(3, function(tmr:FlxTimer) {
			poisonMult = 0;
			if(!ClientPrefs.hideHud) iconP1Poison.visible = false;
			recalculateIconAnimations();
			if (SONG.notes[publicSection].player4Section) {
				reloadHealthBarColors(true);
			} else {
				reloadHealthBarColors(false);
			}
			for (poisonSprite in poisonSpriteGrp) {
				FlxTween.tween(poisonSprite, {alpha: 0}, 0.2, {
					onComplete: function(twn:FlxTween) {
						poisonSprite.visible = false;
					}
				});
			}
		});
	}

	function freezeRoutine():Void {
		if (freezeTimer == null && freezeCooldownTimer == null) {
			for (freezeSprite in freezeSpriteGrp) {
				freezeSprite.visible = true;
				if (freezeSprite.alpha < 1) FlxTween.tween(freezeSprite, {alpha: 1}, 0.4);
			}
			FlxTween.tween(FlxG.sound.music, {volume: 0.25}, 0.4);
			FlxTween.tween(vocals, {volume: 0.05}, 0.4);
			FlxTween.tween(secondaryVocals, {volume: 0.25}, 0.4);
			boyfriend.color = 0xff7eeeff;
			boyfriend.stunned = true;
			freezeTimer = new FlxTimer().start(2, function(tmr:FlxTimer) {
				boyfriend.stunned = false;
				for (freezeSprite in freezeSpriteGrp) {
					FlxTween.tween(freezeSprite, {alpha: 0}, 0.4, {
						onComplete: function(twn:FlxTween) {
							freezeSprite.visible = false;
						}
					});
				}
				FlxTween.tween(FlxG.sound.music, {volume: SONG.header.instVolume}, 0.4);
				FlxTween.tween(vocals, {volume: SONG.header.vocalsVolume}, 0.4);
				FlxTween.tween(secondaryVocals, {volume: SONG.header.secVocalsVolume}, 0.4);
				boyfriend.color = 0xffffffff;
				freezeCooldownTimer = new FlxTimer().start(0.2, function(tmr:FlxTimer) {
					freezeCooldownTimer = null;
				});
				freezeTimer = null;
			});
		}
	}

	function ghostModeRoutine(daNote:Note):Void {
        daNote.copyAlpha = false;
		if(ClientPrefs.downScroll){
			if(daNote.y > (FlxG.height / 1.75)){
				if (daNote.alpha == 1)
					FlxTween.tween(daNote,{alpha: 0},0.1);
			}
		} else {
			if(daNote.y < (FlxG.height / 1.75)){
				if (daNote.alpha == 1)
					FlxTween.tween(daNote,{alpha: 0},0.1);
			}
		}
	}

	/**
	* Function used to determine when cutscenes can be run.
	*/
	inline function canIUseTheCutsceneMother():Bool
	{
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
		return shouldBeSeeingCutscene;
	}

	inline function addATint(alpha:Float, color:FlxColor):FlxSprite {
		var tint:FlxSprite = new FlxSprite().makeGraphic(FlxG.width,FlxG.width,FlxColor.WHITE);
		tint.scrollFactor.set();
		tint.screenCenter();
		tint.alpha = alpha;
		tint.blend = BlendMode.MULTIPLY;
		tint.color = color;
		tint.cameras = [camTint];
		add(tint);
		return(tint);
	}

	function camPanRoutine(anim:String = 'singUP', who:String = 'bf', character:String = 'bf'):Void {
		var fps:Float = Main.fpsCounter.currentFPS;
		var mode:String = ClientPrefs.camPanMode;
		var bfCanPan:Bool = (mode == 'Always' || mode == 'BF Only' || (mode == 'Camera Focus' && SONG.notes[publicSection].mustHitSection)) ? true : false;
		var dadCanPan:Bool = (mode == 'Always' || mode == 'Oppt Only' || (mode == 'Camera Focus' && !SONG.notes[publicSection].mustHitSection)) ? true : false;
		var p4CanPan:Bool = (mode == 'Always' || mode == 'Player 4 Only' || (mode == 'Camera Focus' && !SONG.notes[publicSection].mustHitSection && SONG.notes[publicSection].player4Section)) ? true : false;
		var clear:Bool = false;
		var reverseLR:Bool = /*((dadCanPan || p4CanPan) && character.toLowerCase().startsWith('monster')) ? true : */false;
		switch (who) {
			case 'bf':
				clear = bfCanPan;
			case 'oppt':
				clear = dadCanPan;
			case 'p4':
				clear = p4CanPan;
		}
		//FlxG.elapsed is stinky poo poo for this, it just makes it look jank as fuck
		if (clear) {
			if (fps == 0) fps = 1;
			switch (anim.split('-')[0])
			{
				case 'singUP':
					moveCamTo[1] = -40*240/fps;
				case 'singDOWN':
					moveCamTo[1] = 40*240/fps;
				case 'singLEFT':
					moveCamTo[0] = reverseLR ? 40*240/fps : -40*240/fps;
				case 'singRIGHT':
					moveCamTo[0] = reverseLR ? -40*240/fps : 40*240/fps;
			}
		}
	}

	function initModifiers() {
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		poison = ClientPrefs.getGameplaySetting('poison', false);
		freeze = ClientPrefs.getGameplaySetting('freeze', false);
		quartiz = ClientPrefs.getGameplaySetting('quartiz', false);
		randomMode = ClientPrefs.getGameplaySetting('randommode', false);
		ghostMode = ClientPrefs.getGameplaySetting('ghostmode', false);
		flashLight = ClientPrefs.getGameplaySetting('flashlight', false);
		sickOnly = ClientPrefs.getGameplaySetting('sickonly', false);
		if(cpuControlled == true && !SONG.options.allowBot) {
			cpuControlled = false;
		}
		tappy = ClientPrefs.ghostTapping;
		if(tappy == true && !SONG.options.allowGhostTapping) {
			tappy = false;
		}
	}

	function phillyIntro()
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();
		var localCpu = cpuControlled;
		cpuControlled = true;
	
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		camHUD.alpha = 0.00001;
		cutsceneHandlerCutscene = true;
	
		var gfCutscene:FlxSprite = new FlxSprite(phillyTrain.x, phillyTrain.y - 120);
		gfCutscene.frames = Paths.getSparrowAtlas('characters/GF_assets');
		gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);
		var picoCutscene:FlxSprite = new FlxSprite(dad.x + 45, dad.y + 18);
		picoCutscene.frames = Paths.getSparrowAtlas('characters/Week3/Pico_FNF_assetss');
		picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);
		var boyfriendCutscene:FlxSprite = new FlxSprite(phillyTrain.x + 100, phillyTrain.y + 20);
		boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
		boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);
		var dearest:FlxSprite = new FlxSprite(picoCutscene.x - 400, picoCutscene.y + 100).loadGraphic(Paths.image('dearest'));
		dearest.antialiasing = ClientPrefs.globalAntialiasing;
		dearest.scrollFactor.set(1.05,1.2);
		dearest.alpha = 0.78;
		cutsceneHandler.push(dearest);

		canPause = false;
	
		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 3.25;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			FlxTween.tween(camHUD, {alpha: 1}, timeForStuff/2, {ease: FlxEase.quadInOut});
			moveCamera(false, false);
			startCountdown();
	
			dadGroup.alpha = 1;
			gfGroup.alpha = 1;
			boyfriendGroup.alpha = 1;
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
			gf.visible = true;
			gf.alpha = 1;
			cpuControlled = localCpu;
			recalculateIconAnimations();
			cutsceneHandlerCutscene = false;
			canPause = true;
		};
	
		camFollow.set(dad.x + 280, dad.y + 170);
		cutsceneHandler.endTime = 7.5;
		cutsceneHandler.music = 'Pico';

		gfCutscene.animation.addByPrefix('hairblow', 'GF Dancing Beat Hair blowing', 24, true);
		gfCutscene.animation.addByPrefix('hairland', 'GF Dancing Beat Hair Landing', 24, false);
		gfCutscene.animation.addByPrefix('sobbingrn', 'gf sad', 24, false);
		gfCutscene.animation.play('hairblow', true);

		boyfriendCutscene.animation.addByPrefix('ouch', 'BF NOTE DOWN MISS', 24, false);
		boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
		boyfriendCutscene.animation.play('idle');

		picoCutscene.animation.addByPrefix('waitasecond', 'Pico NOTE LEFT miss', 24, false);
		picoCutscene.animation.addByPrefix('ohtheresmykill', 'Pico NOTE LEFT0', 24, false);
		picoCutscene.animation.addByPrefix('bored', 'Pico Down Note0', 24, false);
		picoCutscene.animation.addByPrefix('idle', 'Pico Idle Dance', 24, false);
		picoCutscene.animation.play('idle');

		addBehindDad(gfCutscene);
		addBehindDad(picoCutscene);
		addBehindDad(boyfriendCutscene);
		addBehindDad(dearest);

		gfGroup.alpha = 0.00001;
		boyfriendGroup.alpha = 0.00001;

		precacheList.set('train_passes', 'sound');
		var train:FlxSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
		FlxG.sound.list.add(train);
		cutsceneHandler.sounds.push(train);

		precacheList.set('gunThing', 'sound');
		var gun:FlxSound = new FlxSound().loadEmbedded(Paths.sound('gunThing'));
		FlxG.sound.list.add(gun);
		cutsceneHandler.sounds.push(gun);

		precacheList.set('picoYeah1', 'sound');
		var picoYeah1:FlxSound = new FlxSound().loadEmbedded(Paths.sound('picoYeah1'));
		FlxG.sound.list.add(picoYeah1);
		cutsceneHandler.sounds.push(picoYeah1);

		precacheList.set('picoYeah2', 'sound');
		var picoYeah2:FlxSound = new FlxSound().loadEmbedded(Paths.sound('picoYeah2'));
		FlxG.sound.list.add(picoYeah2);
		cutsceneHandler.sounds.push(picoYeah2);

		precacheList.set('picoOh1', 'sound');
		var picoOh1:FlxSound = new FlxSound().loadEmbedded(Paths.sound('picoOh1'));
		FlxG.sound.list.add(picoOh1);
		cutsceneHandler.sounds.push(picoOh1);

		precacheList.set('picoOh2', 'sound');
		var picoOh2:FlxSound = new FlxSound().loadEmbedded(Paths.sound('picoOh2'));
		FlxG.sound.list.add(picoOh2);
		cutsceneHandler.sounds.push(picoOh2);

		var tweenDearest:Void->Void = function()
		{
			FlxTween.tween(dearest, {y: dearest.y - 12}, 0.12, {onComplete: function(_) {
				FlxTween.tween(dearest, {y: dearest.y + 12}, 0.12);
			}});
		}
	
		cutsceneHandler.onStart = function()
		{
			moveCamera(true, false);
			camFollow.y += 100;
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 0.97}, 4, {ease: FlxEase.quadInOut});
			train.play(true);
		};

		picoCutscene.animation.finishCallback = function(name:String)
		{
			picoCutscene.x = dad.x + 45;
			picoCutscene.y = dad.y + 18;
			picoCutscene.animation.play('idle');
		};

		cutsceneHandler.timer(0.8, function()
		{
			tweenDearest();
		});

		cutsceneHandler.timer(1, function()
		{
			picoCutscene.x -= 84;
			picoCutscene.y -= -80;
			tweenDearest();
			picoCutscene.animation.play('bored');
			picoYeah1.play(true);
		});

		cutsceneHandler.timer(2.1, function()
		{
			tweenDearest();
		});

		cutsceneHandler.timer(2.3, function()
		{
			picoCutscene.x -= 84;
			picoCutscene.y -= -80;
			tweenDearest();
			picoCutscene.animation.play('bored');
			picoOh1.play(true);
		});

		cutsceneHandler.timer(3.5, function()
		{
			tweenDearest();
		});

		cutsceneHandler.timer(3.7, function()
		{
			picoCutscene.x -= 84;
			picoCutscene.y -= -80;
			tweenDearest();
			picoCutscene.animation.play('bored');
			picoYeah2.play(true);
		});

		cutsceneHandler.timer(4.3, function()
		{
			tweenDearest();
		});
	
		cutsceneHandler.timer(4.5, function()
		{
			picoCutscene.x -= 84;
			picoCutscene.y -= -80;
			picoCutscene.animation.play('bored');
			picoOh2.play(true);
		});

		cutsceneHandler.timer(4.7, function()
		{
			FlxTween.tween(dearest, {alpha: 0, y: dearest.y + 40, x: dearest.x - 150}, 0.5, {onComplete: function(_){
				dearest.visible = false;
			}});
		});

		cutsceneHandler.timer(4.779, function()
		{
			camFollow.x += 300;
			camFollow.y -= 20;
			phillyTrain.x = 2000;
			FlxTween.tween(phillyTrain, {x: -4000}, 0.6);
			boyfriendCutscene.x = phillyTrain.x + 100;
			boyfriendCutscene.y = phillyTrain.y - 120;
			gfCutscene.x = phillyTrain.x;
			gfCutscene.y = phillyTrain.y - 520;
			FlxTween.tween(boyfriendCutscene, {angle: 360, x: boyfriend.x, y: boyfriend.y}, 0.4, {ease: FlxEase.circInOut, startDelay: 0.2, onComplete: function(twn:FlxTween) {
				boyfriendCutscene.animation.play('ouch');
				boyfriendCutscene.y += 14;
				boyfriendCutscene.x += 2;
				FlxTween.tween(boyfriendCutscene, {"scale.x": 1.2, "scale.y": 0.85, y: boyfriendCutscene.y + 10}, 0.1);
				FlxTween.tween(boyfriendCutscene, {"scale.x": 1, "scale.y": 1, y: boyfriendCutscene.y - 10}, 0.16, {startDelay: 0.1, onComplete: function(_) {
					boyfriendCutscene.updateHitbox();
				}});
				boyfriendCutscene.animation.finishCallback = function(name:String)
				{
					if (name == 'ouch') {
						boyfriendCutscene.visible = false;
						boyfriendGroup.alpha = 1;
					}
				}
			}});
			gfCutscene.animation.play('hairland', true);
			FlxTween.tween(gfCutscene, {angle: 360, x: gf.x, y: gf.y}, 0.35, {ease: FlxEase.circInOut, startDelay: 0.25, onComplete: function(twn:FlxTween) {
				gfCutscene.animation.play('sobbingrn');
				gfCutscene.y += 17;
				FlxTween.tween(gfCutscene, {"scale.x": 1.05, "scale.y": 0.95, y: gfCutscene.y + 5}, 0.1);
				FlxTween.tween(gfCutscene, {"scale.x": 1, "scale.y": 1, y: gfCutscene.y - 5}, 0.1, {startDelay: 0.1, onComplete: function(_) {
					gfCutscene.updateHitbox();
				}});
				var howMany:Int = 0;
				gfCutscene.animation.finishCallback = function(name:String)
				{
					if (name == 'sobbingrn') {
						if (howMany < 4) {
							gfCutscene.animation.play('sobbingrn');
							howMany++;
						} else {
							gfCutscene.visible = false;
							gfGroup.alpha = 1;
						}
					}
				}
			}});
		});

		cutsceneHandler.timer(6.9, function()
		{
			camFollow.x -= 300;
			picoCutscene.animation.finishCallback = null;
			picoYeah2.play(true);
			gun.play(true);
			picoCutscene.flipX = true;
			picoCutscene.x = 215;
			picoCutscene.y = 420;
			picoCutscene.animation.play('ohtheresmykill');
			if(boyfriend != null && boyfriend.animOffsets.exists('singSPACEmiss')) {
				boyfriend.playAnim('singSPACEmiss');
			}
		});
	}

	public function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		black.scrollFactor.set();
		black.screenCenter();
		add(black);

		var red:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFff1b31);
		red.scrollFactor.set();
		red.screenCenter();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.header.song);
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
					if (Paths.formatToSongPath(SONG.header.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0.001;
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
		var localCpu = cpuControlled;
		cpuControlled = true;
	
		var songName:String = Paths.formatToSongPath(SONG.header.song);
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;
		cutsceneHandlerCutscene = true;
	
		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = ClientPrefs.globalAntialiasing;
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		cutsceneHandler.canSkip = true;
		canPause = false;
	
		cutsceneHandler.finishCallback = function()
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			moveCamera(true, false);
			startCountdown();
	
			dadGroup.alpha = 1;
			gfGroup.alpha = 1;
			boyfriendGroup.alpha = 1;
			camHUD.alpha = 0;
			FlxTween.tween(camHUD, {alpha: 1}, timeForStuff/2, {ease: FlxEase.quadInOut});
			camHUD.visible = true;
			boyfriend.animation.finishCallback = null;
			gf.animation.finishCallback = null;
			gf.dance();
			cpuControlled = localCpu;
			recalculateIconAnimations();
			if (songName == 'stress') {
				tankmanRun.forEach(function(tankman:TankmenBG){
					tankman.visible = true;
				});
			}
			cutsceneHandlerCutscene = false;
			canPause = true;
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
				cutsceneHandler.sounds.push(wellWellWell);

				var beep:FlxSound = new FlxSound().loadEmbedded(Paths.sound('bfBeep'));
				FlxG.sound.list.add(beep);
				cutsceneHandler.sounds.push(beep);
	
				var killYou:FlxSound = new FlxSound().loadEmbedded(Paths.sound('killYou'));
				FlxG.sound.list.add(killYou);
				cutsceneHandler.sounds.push(killYou);
	
				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				var right:Bool = false;
				var cutsceneCam:Void->Void = function()
				{
					camFollow.x += right ? 750 : -750;
					camFollow.y += right ? 100 : -100;
				}
	
				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, function()
				{
					wellWellWell.play(true);
				});
	
				// Move camera to BF
				cutsceneHandler.timer(3, function()
				{
					right = true;
					cutsceneCam();
				});
	
				// Beep!
				cutsceneHandler.timer(4.5, function()
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					beep.play(true);
				});
	
				// Move camera to Tankman
				cutsceneHandler.timer(6, function()
				{
					right = false;
					cutsceneCam();
	
					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.animation.play('killYou', true);
					killYou.play(true);
				});
	
			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
				tankman.x += 40;
				tankman.y += 10;
				precacheList.set('tankSong2', 'sound');
	
				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2'));
				FlxG.sound.list.add(tightBars);
				cutsceneHandler.sounds.push(tightBars);
	
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
				tankmanRun.forEach(function(tankman:TankmenBG){
					tankman.visible = false;
				});
				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.y += 100;
				});
				precacheList.set('stressCutscene', 'sound');
	
				var tankman2:FlxSprite = new FlxSprite(16, 312);
				tankman2.antialiasing = ClientPrefs.globalAntialiasing;
				tankman2.alpha = 0.000001;
				cutsceneHandler.push(tankman2);
				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);
	
				var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
				gfDance.antialiasing = ClientPrefs.globalAntialiasing;
				cutsceneHandler.push(gfDance);
				if (!ClientPrefs.lowQuality)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/Week7/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}
	
				var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
				gfCutscene.antialiasing = ClientPrefs.globalAntialiasing;
				cutsceneHandler.push(gfCutscene);
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
	
				var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
				picoCutscene.antialiasing = ClientPrefs.globalAntialiasing;
				cutsceneHandler.push(picoCutscene);
				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;
	
				var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
				boyfriendCutscene.antialiasing = ClientPrefs.globalAntialiasing;
				cutsceneHandler.push(boyfriendCutscene);
				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);
				cutsceneHandler.sounds.push(cutsceneSnd);
	
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

	function thornsEndCutscene():Void {
		if (canIUseTheCutsceneMother()) {
			inCutscene = true;
			FlxG.sound.play(Paths.sound('tp1'));
			var timer = new FlxTimer().start(0.45, function(tmr:FlxTimer) {
				//FlxG.sound.play(Paths.sound('tp2'));
				if(boyfriend.animOffsets.exists('teleport-loop')) {
					boyfriend.playAnim('teleport-loop', true);
					boyfriend.specialAnim = true;
				}
				if(gf != null && gf.animOffsets.exists('teleport-loop')) {
					gf.playAnim('teleport-loop', true);
					gf.specialAnim = true;
				}
				FlxTween.tween(boyfriend, {'scale.y': 0.0001, 'scale.x': 1.1}, 0.6, {
					ease: FlxEase.expoOut,
					onComplete: function(twn:FlxTween) {
						inCutscene = false;
						boyfriend.visible = false;
						gf.visible = false;
					}
				});
				FlxTween.tween(gf, {'scale.y': 0.0001, 'scale.x': 1.1}, 0.6, {
					ease: FlxEase.expoOut
				});
			});
			if(boyfriend.animOffsets.exists('teleport')) {
				boyfriend.playAnim('teleport', true);
				boyfriend.specialAnim = true;
			}
			if(gf != null && gf.animOffsets.exists('teleport')) {
				gf.playAnim('teleport', true);
				gf.specialAnim = true;
			}
		}
	}

	function eggnogEndCutscene():Void {
		if (canIUseTheCutsceneMother()) {
			inCutscene = true;
			FlxG.sound.play(Paths.sound('Lights_Shut_off'));
			var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, FlxColor.BLACK);
			add(blackScreen);
			blackScreen.scrollFactor.set();
			blackScreen.screenCenter();
			var redScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, 0xff990000);
			add(redScreen);
			redScreen.scrollFactor.set();
			redScreen.screenCenter();
			redScreen.alpha = 0.7;
			FlxTween.tween(redScreen, {alpha: 1}, 0.1);
			FlxTween.tween(redScreen, {alpha: 0}, 0.65, {ease:FlxEase.quadInOut, startDelay: 0.1});
			camHUD.visible = false;
		}
	}
}

class ModifierSprite extends FlxSprite {

    public function new(image:String, camera:FlxCamera, gridPosX:Int, gridPosY:Int)
    {
        super();
        loadGraphic(Paths.image('modifiers/' + image));
        scrollFactor.set();
		scale.set(0.5,0.5);
		updateHitbox();
        x = FlxG.width - (75 * (gridPosX+1));
        y = FlxG.height - (75 * (gridPosY+1));
		y -= ClientPrefs.downScroll ? FlxG.height/2 : 50;
        cameras = [camera];
    }
}
