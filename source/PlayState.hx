package;

#if desktop
import Discord.DiscordClient;
#end
import Character;
import ClientPrefs;
import CrossFades;
import DialogueBoxDenpa;
import FunkinLua;
import HealthIcon;
import haxescript.Hscript;
import Note;
import Shaders;
import Song;
import StageData;
import VanillaBG;
import animateatlas.AtlasFrameMaker;
import editors.CharacterEditorState;
import editors.ChartingState;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.animation.FlxAnimationController;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.display.BlendMode;
import openfl.events.KeyboardEvent;
#if VIDEOS_ALLOWED
	#if (hxCodec >= "2.6.1") import hxcodec.VideoHandler;
	#elseif (hxCodec == "2.6.0") import VideoHandler;
	#else import vlc.MP4Handler as VideoHandler;
	#end
#end

/**
* State containing all gameplay.
*/
class PlayState extends MusicBeatState
{
	//instance
	public static var instance:PlayState;

	//Strum positions??
	public static var STRUM_X = 48.5;
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
	//json sprites (can be used in lua as well)
	public var jsonSprites:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	public var jsonSprGrp:FlxTypedGroup<FlxBasic>;
	public var jsonSprGrpFront:FlxTypedGroup<FlxBasic>;
	public var jsonSprGrpMiddle:FlxTypedGroup<FlxBasic>;
	//for modcharts
	public var elapsedtime:Float = 0;
	public var playerModchart:Modcharts;
	public var dadModchart:Modcharts;
	public var p4Modchart:Modcharts;
	//crossfade groups
	public var grpCrossFade:FlxTypedGroup<CrossFade>;
	public var grpP4CrossFade:FlxTypedGroup<CrossFade>;
	public var grpBFCrossFade:FlxTypedGroup<CrossFade>;
	public var gfCrossFade:FlxTypedGroup<CrossFade>;
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var player4Map:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();

	//important character switcher
	public static var characterVersion = 'bf';

	//story mode shit
	public static var skipNextArrowTween:Bool = false;

	//stage positions
	public var BF_X:Single = 770;
	public var BF_Y:Single = 100;
	public var DAD_X:Single = 100;
	public var DAD_Y:Single = 100;
	public var P4_X:Single = 0;
	public var P4_Y:Single = 0;
	public var GF_X:Single = 400;
	public var GF_Y:Single = 130;

	//stuff for gameplay settings (i think)
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	//character groups
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var player4Group:FlxSpriteGroup;
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
	public var songPercent(default, set):Float = 0;

	function set_songPercent(newPercent:Float) {
		songPercent = newPercent;
		hud.updateSongPercent(songPercent);
		
		return songPercent;
	}
	public var curSection:Int = 0;

	//vocals
	public var vocals:FlxSound;
	public var secondaryVocals:FlxSound;

	//characters
	public var dad:Character = null;
	public var player4:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	//note shits
	public var notes:FlxTypedGroup<Note>;
	public var sustains:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	//the hud
	public var hud:HUD;

	//strum lines
	private var strumLine:FlxSprite;

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
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	//values for shit like health and combo
	public var gfSpeed:Int = 1;

	public var intendedHealth(default, set):Float = 1;
	function set_intendedHealth(newHealth:Float):Float
	{
		intendedHealth = FlxMath.bound(newHealth, -1, maxHealth);
		recalculateIconAnimations();
		
		return intendedHealth;
	}

	public var health(default, set):Float = 1;
	function set_health(newHealth:Float):Float
	{
		health = newHealth;
		setIconPositions();
		hud.updateHealth(health);
		doDeathCheck();
			
		return health;
	}

	public var maxHealth:Float = 2;
	public var combo:Int = 0;
	public var highestCombo:Int = 0;

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
	public static var mania(default, set):Int = 3;
	public static function set_mania(newMania:Int) {
		mania = newMania;
		if (PlayState.instance == null) return mania;

		//oh my god this makes me want to puke
		function maniaCheck(note:Note) {
			if (note.mania != mania) note.mania = mania;
			note.applyManiaChange();
		}
		if (PlayState.instance.unspawnNotes != null)
			for (note in PlayState.instance.unspawnNotes) maniaCheck(note);

		if (PlayState.instance.notes != null)
			for (note in PlayState.instance.notes) maniaCheck(note);

		if (PlayState.instance.sustains != null)
			for (sus in PlayState.instance.sustains) maniaCheck(sus);

		return mania;
	}

	//stuff for song again
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var playbackRate(default, set):Single = 1;
	public var healthGain:Single = 1;
	public var healthLoss:Single = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	function set_cpuControlled(newV:Bool):Bool {
		cpuControlled = newV;
		if (hud != null) hud.botplayTxt.visible = cpuControlled;

		return cpuControlled;
	}
	public var practiceMode:Bool = false;
	public var poison:Bool = false;
	public var poisonMult:Single = 0;
	var poisonTimer:FlxTimer = null;
	var poisonSpriteGrp:FlxTypedGroup<FlxSprite> = null;
	public var sickOnly:Bool = false;
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
	var flip:Bool = false;

	//local storage of ghost tapping
	public var tappy:Bool = false;

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
	public var cameraSpeed:Single = 1;

	//timers
	#if desktop
	var discordUpdateTimer:FlxTimer;
	#end

	//dialogue
	public var dialogue:Array<String> = null;
	public var dialogueJson:DialogueFile = null;

	//week 2 stage
	var halloweenWhite:BGSprite;

	//week 3 stage
	final phillyLightsColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
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

	//week 5 stage
	var upperBoppers:Array<BGSprite>;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;
	var snowEmitter:SnowEmitter;

	//week 6 stage
	var bgGirls:FlxTypedGroup<BackgroundGirls>;
	var bgGhouls:BGSprite;
	var rosesLightningGrp:FlxTypedGroup<BGSprite>;
	var schoolCloudsGrp:FlxTypedGroup<BGSprite>;
	var schoolRain:FlxSprite;
	var rainSound:FlxSound = null;
	var schoolWavy:BGSprite;
	var senpaiLoveGrp:FlxTypedGroup<FlxSprite> = null;

	//week 7 stage
	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;
	var gunsThing:FlxSprite;
	var gunsExtraClouds:FlxBackdrop;

	//week 7 extras
	public var tankmanRainbow:Bool = false;
	final gunsColors:Array<FlxColor> = [0xBFFF0000, 0xBFFF5E00, 0xBFFFFB00, 0xBF00FF0D, 0xBF0011FF, 0xBFD400FF]; //WTF BOYFRIEND REFERENCE?!?!??!#11/1/1??!Q
	var gunsTween:FlxTween = null;
	var stageGraphicArray:Array<FlxSprite> = []; //just for the guns thingamabob
	var gunsNoteTweens:Array<FlxTween> = [];

	//this probably doesnt need to exist but whatever
	public var hudIsSwapped:Bool = false;

	//ms timing popup shit
	public var msTxt:FlxText;
	public var msTimer:FlxTimer = null;

	//score stuff
	public var ratingIntensity:String = ClientPrefs.settings.get("ratingIntensity");
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;

	//stuff for story mode
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var hasCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	//default zooms
	public var defaultStageZoom(default, set):Float = 1.05;
	function set_defaultStageZoom(newZoom:Float):Float {
		defaultStageZoom = newZoom;
		defaultCamZoom = defaultStageZoom;

		return defaultStageZoom;
	}
	public var defaultCamZoom:Float = 1.05;
	public var defaultHudCamZoom:Float = 1;

	// how big to stretch the pixel art assets
	public static final daPixelZoom:Int = 6;

	//cutscene shit
	public var inCutscene:Bool = false;
	public var stopCountdown:Bool = false;
	public var cutsceneHandlerCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	//woah wtf camera offsets
	public var boyfriendCameraOffset:Array<Single> = [0,0];
	public var opponentCameraOffset:Array<Single> = [0,0];
	public var girlfriendCameraOffset:Array<Single> = [0,0];
	public var player4CameraOffset:Array<Single> = [0,0];

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
	// stores the last crit bg sprite object
	public static var lastNumbg:FlxSprite;
	// stores the last combo score objects in an array
	public static var lastScore:Array<FlxSprite> = [];

	//cam panning
	var moveCamTo:HaxeVector<Float> = new HaxeVector(2);

	//nps
	var notesPerSecond:Int = 0;
	var npsArray:Array<Date> = [];
	var maxNps:Int = 0;

	//tinter
	var tintMap:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	//makes the loading screen peace out if restarting
	public static var customTransition:Bool = true;

	//hscript thing
	public var hscripts:Array<Hscript> = [];

	//orbit
	var orbit:Bool = false;

	override public function create()
	{
		Paths.clearUnusedCache();
		
		#if cpp
		cpp.vm.Gc.enable(false); //prevent lag spikes where it matters most
		#end

		MusicBeatState.disableManual = true;
		SoundTestState.isPlaying = false;
		FlxG.mouse.visible = false;
		FreeplayState.destroyFreeplayVocals();
		instance = this;
		debugKeysChart = ClientPrefs.keyBinds.get('debug_1').copy();
		debugKeysCharacter = ClientPrefs.keyBinds.get('debug_2').copy();
		PauseSubState.songName = null; //Reset to default
		keysArray = ClientPrefs.fillKeys();

		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		// Gameplay settings
		initModifiers();

		//init mania
		mania = SONG.options.mania;
		if (mania < Note.minMania || mania > Note.maxMania) mania = Note.defaultMania;
		
		//Debug Init
		#if debug final debugInit:Debug = new Debug(); #end

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camTint = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		camTint.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camTint, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>((mania+1)*3); //We add a limit so it doesnt cause absurd lag. Since its jsut recyling, we shouldnt have any issues.

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		var loading:FlxSprite = null;
		if (customTransition) {
			loading = new FlxSprite(0, 0).loadGraphic(Paths.image('loadingscreen'));
			loading.cameras = [camOther];
			loading.setGraphicSize(0, FlxG.height);
			loading.updateHitbox();
			loading.x = FlxG.width - loading.width;
			add(loading);
		}

		//failsafe
		if (SONG == null) SONG = Song.loadFromJson('test');

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
		curStage = SONG.assets.stage;
		if(SONG.assets.stage == null || SONG.assets.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south': curStage = 'spooky';
				case 'monster': curStage = 'streetlight';
				case 'pico' | 'blammed' | 'philly-nice': curStage = 'philly';
				case 'satin-panties' | 'high': curStage = 'limo';
				case 'milf': curStage = 'limo';
				case 'cocoa' | 'eggnog': curStage = 'mall';
				case 'winter-horrorland': curStage = 'mallEvil';
				case 'senpai' | 'roses': curStage = 'school';
				case 'thorns': curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress': curStage = 'tank';
				default: curStage = 'stage';
			}
			SONG.assets.stage = curStage; //fix for chart editor lolll
		}

		//get stage data
		Paths.setModsDirectoryFromType(STAGE, curStage, false);
		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
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

				sprites: [],
				animations: []
			};
		}

		//set variables using stage data
		defaultStageZoom = stageData.defaultZoom;
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
		}

		if (stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		if (stageData.camera_boyfriend != null)
			boyfriendCameraOffset = stageData.camera_boyfriend;

		if (stageData.camera_opponent != null)
			opponentCameraOffset = stageData.camera_opponent;

		if (stageData.camera_girlfriend != null)
			girlfriendCameraOffset = stageData.camera_girlfriend;

		if (stageData.camera_p4 != null)
			player4CameraOffset = stageData.camera_p4;

		//make groups (wtf!!!)
		phillyGroupThing = new FlxTypedGroup();
		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		player4Group = new FlxSpriteGroup(P4_X, P4_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		jsonSprGrp = new FlxTypedGroup();
		jsonSprGrpFront = new FlxTypedGroup();
		jsonSprGrpMiddle = new FlxTypedGroup();
		behindGfGroup = new FlxTypedGroup();

		var useJsonStage:Bool = false;
		if (stageData.sprites != null && stageData.sprites.length > 0) useJsonStage = true;

		if (!useJsonStage) {
			switch (curStage)
			{
				case 'limo': //Week 4
					final path = 'vanilla/week4';
					var skyBG:BGSprite = new BGSprite('$path/limo/limoSunset', -120, -50, 0.1, 0.1);
					add(skyBG);

					billBoard = new FlxSprite(1000, -500).loadGraphic(Paths.image('vanilla/week4/limo/fastBfLol'));
					billBoard.scrollFactor.set(0.36,0.36);
					billBoard.scale.set(1.9,1.9);
					billBoard.updateHitbox();
					add(billBoard);
					billBoard.active = true;
	
					if(!ClientPrefs.settings.get("lowQuality")) {
						limoMetalPole = new BGSprite('$path/gore/metalPole', -500, 220, 0.4, 0.4);
						add(limoMetalPole);
	
						bgLimo = new BGSprite('$path/limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
						add(bgLimo);
	
						limoCorpse = new BGSprite('$path/gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
						add(limoCorpse);
	
						limoCorpseTwo = new BGSprite('$path/gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
						add(limoCorpseTwo);
	
						grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
						add(grpLimoDancers);
	
						for (i in 0...5)
						{
							var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
							dancer.scrollFactor.set(0.4, 0.4);
							grpLimoDancers.add(dancer);
						}
	
						limoLight = new BGSprite('$path/gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
						add(limoLight);
	
						grpLimoParticles = new FlxTypedGroup<BGSprite>();
						add(grpLimoParticles);
	
						//PRECACHE BLOOD
						var particle:BGSprite = new BGSprite('$path/gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
						particle.alpha = 0.01;
						grpLimoParticles.add(particle);
						resetLimoKill();
	
						//PRECACHE SOUND
						precacheList.set('$path/dancerdeath', 'sound');
					}
	
					limo = new BGSprite('$path/limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
	
					fastCar = new BGSprite('$path/limo/fastCarLol', -300, 160);
					fastCar.active = true;
					limoKillingState = 0;
	
				case 'mall': //Week 5 - Cocoa, Eggnog
					final path = 'vanilla/week5';
					var layerArray:Array<FlxBasic> = [];
					var bg:BGSprite = new BGSprite('$path/christmas/bgWalls', -1000, -500, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
	
					var tree:BGSprite = new BGSprite('$path/christmas/christmasTree', 370, -250, 0.40, 0.40);

					var treeSnow:BGSprite = new BGSprite('$path/christmas/fgSnow', -600, 590, 0.6, 0.6);
					treeSnow.color = 0xfff0f0ff;

					var boppersSnow:BGSprite = new BGSprite('$path/christmas/fgSnow', -600, 640, 0.8, 0.8);
					boppersSnow.color = 0xfff9f9ff;
	
					bottomBoppers = new BGSprite('$path/christmas/bottomBop', -270, 140, 0.9, 0.9, ['Bottom Level Boppers Idle'], false, false);
					bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
					bottomBoppers.addOffset('Bottom Level Boppers Idle', 0, 0);
					bottomBoppers.addOffset('hey', -16, 26);
					bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					bottomBoppers.updateHitbox();
	
					var fgSnow:BGSprite = new BGSprite('$path/christmas/fgSnow', -600, 700);
	
					santa = new BGSprite('$path/christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
					precacheList.set('$path/Lights_Shut_off', 'sound');
	
					if(!ClientPrefs.settings.get("lowQuality")) {
						upperBoppers = [
							new BGSprite('$path/christmas/upperBopLeft', -290, -65, 0.3, 0.33, ['Upper Crowd Bob left']),
							new BGSprite('$path/christmas/upperBopRight', 792, -65, 0.3, 0.33, [(SONG.header.song.toLowerCase() == 'eggnog' ? 'Upper Crowd Bob right no lemon' : 'Upper Crowd Bob right0')])
						];
						for (bopper in upperBoppers) {
							bopper.setGraphicSize(Std.int(bopper.width * 0.85));
							bopper.updateHitbox();
						}
						var bgEscalator:BGSprite = new BGSprite('$path/christmas/bgEscalator', -1100, -575, 0.3, 0.3);
						bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
						bgEscalator.updateHitbox();

						snowEmitter = new SnowEmitter(-600, -210);
						layerArray = [bg, upperBoppers[0], upperBoppers[1], bgEscalator, tree, treeSnow, boppersSnow, bottomBoppers, snowEmitter, fgSnow, santa];
					} else {
						layerArray = [bg, tree, treeSnow, boppersSnow, bottomBoppers, fgSnow, santa];
					}
	
					autoLayer(layerArray);
	
				case 'mallEvil': //Week 5 - Winter Horrorland
					final path = 'vanilla/week5';
					var layerArray:Array<FlxBasic> = [];
					var bg:BGSprite = new BGSprite('$path/christmas/evilBG', -400, -250, 0.2, 0.2);
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
	
					var evilTree:BGSprite = new BGSprite('$path/christmas/evilTree', 400, -100, 0.36, 0.33);
					evilTree.setGraphicSize(Std.int(evilTree.width * 1.1));
					evilTree.updateHitbox();
	
					var evilSnow:BGSprite = new BGSprite('$path/christmas/evilSnow', -200, 700);
	
					layerArray = [bg, evilTree, evilSnow];
	
					autoLayer(layerArray);
	
				case 'school': //Week 6 - Senpai, Roses
					final path = 'vanilla/week6';
					final isRoses = SONG.header.song.toLowerCase() == 'roses';
					var layerArray:Array<FlxBasic> = [];
	
					var bgSky:BGSprite = new BGSprite('$path/weeb/weebSky', 0, 0, 0.1, 0.1);
					if (isRoses) bgSky.color = 0xffcecece;
	
					final repositionShit = -198;
	
					var bgSchool:BGSprite = new BGSprite('$path/weeb/weebSchool', repositionShit, 0, 0.6, 0.90); //0.6, 0.9
	
					var bgStreet:BGSprite = new BGSprite('$path/weeb/weebStreet', repositionShit, 0, 1, 1);
	
					var widShit = Std.int(bgSky.width * 6);
	
					var bgTrees:FlxSprite = new FlxSprite(repositionShit - 378, -798);
					bgTrees.frames = Paths.getPackerAtlas('$path/weeb/weebTrees');
					bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
					bgTrees.animation.play('treeLoop');
					bgTrees.scrollFactor.set(0.85, 0.85);

					halloweenWhite = new BGSprite(null, 0, 0, 0, 0);
					halloweenWhite.makeGraphic(Std.int(FlxG.width*2), Std.int(FlxG.height*2), FlxColor.WHITE);
					halloweenWhite.alpha = 0.001;
					halloweenWhite.blend = ADD;
					halloweenWhite.screenCenter();
					halloweenWhite.visible = false;
	
					if(!ClientPrefs.settings.get("lowQuality")) {
						var howMany:Int = (isRoses ? 3 : 1);
						schoolCloudsGrp = new FlxTypedGroup<BGSprite>();
						for (i in 0...howMany) {
							var schoolClouds = new BGSprite('$path/weeb/weebClouds', FlxG.random.int(isRoses ? -120 : -60, 60), FlxG.random.int(isRoses ? -120 : -24, 6), 0.15+0.05*i, 0.2+0.01*i);
							schoolClouds.ID = i;
							schoolClouds.active = true;
							schoolClouds.velocity.x = FlxG.random.float(-6, isRoses ? 12 : 6);
							schoolClouds.antialiasing = false;
							schoolClouds.setGraphicSize(widShit);
							schoolClouds.updateHitbox();
							if (isRoses) schoolClouds.color = 0xffdadada;
							schoolCloudsGrp.add(schoolClouds);
						}

						if (isRoses) {
							rosesLightningGrp = new FlxTypedGroup<BGSprite>();
							for (i in 0...howMany) {
								var rosesLightning = new BGSprite('$path/weeb/weebLightning', schoolCloudsGrp.members[i].x, schoolCloudsGrp.members[i].y, 0.15+0.05*i, 0.2+0.01*i);
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

						var fgTrees:BGSprite = new BGSprite('$path/weeb/weebTreesBack', repositionShit + 174, 132, 0.9, 0.9);
						fgTrees.setGraphicSize(Std.int(widShit * 0.8));
						fgTrees.updateHitbox();
						fgTrees.antialiasing = false;
	
						var treeLeaves:BGSprite = new BGSprite('$path/weeb/petals', repositionShit, -42, 0.85, 0.85, ['PETALS ALL'], true);
						treeLeaves.setGraphicSize(widShit);
						treeLeaves.updateHitbox();
						treeLeaves.antialiasing = false;
	
						bgGirls = new FlxTypedGroup<BackgroundGirls>(3);
						for (i in 0...3) {
							var bgGirl = new BackgroundGirls(-114 + (498 * i) + 48, 192);
							bgGirl.scrollFactor.set(1, 1);
		
							bgGirl.setGraphicSize(Std.int(bgGirl.width * daPixelZoom));
							bgGirl.updateHitbox();
							bgGirls.add(bgGirl);
						}
	
						if (isRoses)
							layerArray = [bgSky, rosesLightningGrp, schoolCloudsGrp, bgSchool, bgStreet, fgTrees, bgTrees, treeLeaves, bgGirls];
						else
							layerArray = [bgSky, schoolCloudsGrp, bgSchool, bgStreet, fgTrees, bgTrees, treeLeaves, bgGirls];
					}
					else
						layerArray = [bgSky, bgSchool, bgStreet, bgTrees];

					switch(SONG.header.song.toLowerCase()) {
						case 'senpai':
							if(!ClientPrefs.settings.get("lowQuality")) {
								senpaiLoveGrp = new FlxTypedGroup<FlxSprite>(); //if this causes a null ref on lowQuality just move it out of the if, shouldnt though
								makeEffectOverlay('poisonEffect', senpaiLoveGrp);
							}
						case 'roses':
							precacheList.set('$path/thunder_1', 'sound');
							precacheList.set('$path/thunder_2', 'sound');
							precacheList.set('rainSnd', 'sound');
							Paths.getSparrowAtlas('vanilla/week6/weeb/rain'); //directly precaching the sparrow atlas like a boss
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
					final path = 'vanilla/week6';
					var layerArray:Array<FlxBasic> = [];
	
					final posX = 402;
					final posY = 204;
					if(!ClientPrefs.settings.get("lowQuality")) {
						schoolWavy = new BGSprite('$path/weeb/animatedEvilSchool', posX, posY, 1, 1, ['background 2'], true);
						schoolWavy.scale.set(6, 6);
						schoolWavy.antialiasing = false;
						schoolWavy.setPosition(posX + 30, posY + 36);
						schoolWavy.visible = false;
	
						bgGhouls = new BGSprite('$path/weeb/bgGhouls', -150, 252, 1, 1, ['BG freaks glitch instance'], false);
						bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
						bgGhouls.updateHitbox();
						bgGhouls.visible = false;
						bgGhouls.antialiasing = false;
	
						layerArray = [schoolWavy, bgGhouls];
					} else {
						var bg:BGSprite = new BGSprite('$path/weeb/animatedEvilSchool_low', posX, posY + 30, 1, 1);
						bg.scale.set(6, 6);
						bg.antialiasing = false;
						
						layerArray = [bg];
					}
	
					autoLayer(layerArray);
	
				case 'tank': //Week 7 - Ugh, Guns, Stress
					final path = 'vanilla/week7';
					tankmanRainbow = false;
					var layerArray:Array<FlxBasic> = [];
					
					var sky:BGSprite = new BGSprite('$path/tankSky', -400, -400, 0, 0);
					sky.scale.set(1.5,1.5);
					sky.updateHitbox();
	
					var ruins:BGSprite = new BGSprite('$path/tankRuins',-200,0,.35,.35);
					ruins.setGraphicSize(Std.int(1.1 * ruins.width));
					ruins.updateHitbox();
	
					tankGround = new BGSprite('$path/tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
	
					tankmanRun = new FlxTypedGroup<TankmenBG>();
	
					var ground:BGSprite = new BGSprite('$path/tankGround', -420, -150);
					ground.setGraphicSize(Std.int(1.15 * ground.width));
					ground.updateHitbox();
					moveTank();
	
					if(!ClientPrefs.settings.get("lowQuality"))
					{
						var clouds:BGSprite = new BGSprite('$path/tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
						clouds.active = true;
						clouds.velocity.x = FlxG.random.float(5, 15);
	
						var mountains:BGSprite = new BGSprite('$path/tankMountains', -300, -20, 0.2, 0.2);
						mountains.setGraphicSize(Std.int(1.2 * mountains.width));
						mountains.updateHitbox();
	
						var buildings:BGSprite = new BGSprite('$path/tankBuildings', -200, 0, 0.3, 0.3);
						buildings.setGraphicSize(Std.int(1.1 * buildings.width));
						buildings.updateHitbox();
	
						var smokeLeft:BGSprite = new BGSprite('$path/smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
	
						var smokeRight:BGSprite = new BGSprite('$path/smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
	
						tankWatchtower = new BGSprite('$path/tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
	
						layerArray = [sky, clouds, mountains, buildings, ruins, smokeLeft, smokeRight, tankWatchtower, tankGround, tankmanRun, ground];
					} 
					else
						layerArray = [sky, ruins, tankGround, tankmanRun, ground];
	
					autoLayer(layerArray);

					layerArray.remove(sky);
					layerArray.remove(tankmanRun);
					stageGraphicArray = cast layerArray;

					if (SONG.header.song.toLowerCase() == 'guns') {
						gunsThing = new FlxSprite(-100,-100).makeGraphic(Std.int(FlxG.width*1.5),Std.int(FlxG.height*1.5),FlxColor.WHITE);
						gunsThing.color = 0xBFFF0000;
						gunsThing.alpha = 0.001;
						gunsThing.visible = false;
						gunsThing.scrollFactor.set();
						gunsThing.screenCenter();

						gunsExtraClouds = new FlxBackdrop(Paths.image('$path/tankClouds'), XY, 64, 128);
						gunsExtraClouds.velocity.set(12, 168);
						gunsExtraClouds.alpha = 0.001;
						gunsExtraClouds.visible = false;
						gunsExtraClouds.scrollFactor.set(0.1, 0.2);
						add(gunsExtraClouds);
					}

					foregroundSprites = new FlxTypedGroup<BGSprite>();
					foregroundSprites.add(new BGSprite('$path/tank0', -500, 650, 1.7, 1.5, ['fg']));
					if(!ClientPrefs.settings.get("lowQuality")) foregroundSprites.add(new BGSprite('$path/tank1', -300, 750, 2, 0.2, ['fg']));
					foregroundSprites.add(new BGSprite('$path/tank2', 450, 940, 1.5, 1.5, ['foreground']));
					if(!ClientPrefs.settings.get("lowQuality")) foregroundSprites.add(new BGSprite('$path/tank4', 1250, 900, 1.5, 1.5, ['fg']));
					foregroundSprites.add(new BGSprite('$path/tank5', 1620, 700, 1.5, 1.5, ['fg']));
					if(!ClientPrefs.settings.get("lowQuality")) foregroundSprites.add(new BGSprite('$path/tank3', 1300, 1200, 3.5, 2.5, ['fg']));
			}
		} else {
			generateJSONSprites(stageData);
		}
		
		//set pixel stage things
		introSoundsSuffix = isPixelStage ? '-pixel' : '';

		//crossfade
		grpCrossFade = new FlxTypedGroup<CrossFade>(4); // funny number is limit. 4 is most stable and still cool
		grpP4CrossFade = new FlxTypedGroup<CrossFade>(3);
		gfCrossFade = new FlxTypedGroup<CrossFade>(3);
		grpBFCrossFade = new FlxTypedGroup<CrossFade>(4);

		// STAGE SCRIPTS (Hscript)
		#if HSCRIPT_ALLOWED
		addHscript('stages/$curStage'); //lol?
		#end

		Paths.setModsDirectoryFromType(NONE, '', true);

		add(jsonSprGrp);
		add(phillyGroupThing); //Needed for philly lights
		add(behindGfGroup);
		add(gfCrossFade);
		add(gfGroup);

		// Shitty layering but whatev it works LOL
		switch(curStage) {
			case 'limo': add(limo);
			case 'tank': if (SONG.header.song.toLowerCase() == 'guns') add(gunsThing);
		}

		add(jsonSprGrpMiddle);
		add(grpP4CrossFade);
		add(player4Group);
		add(grpCrossFade);
		add(dadGroup);
		add(grpBFCrossFade);
		add(boyfriendGroup);
		add(jsonSprGrpFront);

		switch(curStage) {
			case 'school': add(halloweenWhite);
			case 'tank': add(foregroundSprites);
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

		#if HSCRIPT_ALLOWED
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
					if(file.endsWith('.hscript') && !filesPushed.contains(file))
					{
						hscripts.push(new Hscript(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		//LUA STAGES
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'scripts/stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush) luaArray.push(new FunkinLua(luaFile));
		#end

		//in case of null
		var gfVersion:String = SONG.assets.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo': gfVersion = 'gf-car';
				case 'mall' | 'mallEvil': gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil': gfVersion = 'gf-pixel';
				case 'tank': gfVersion = 'gf-tankmen';
				default: gfVersion = 'gf';
			}
			switch(Paths.formatToSongPath(SONG.header.song))
			{
				case 'stress': gfVersion = 'pico-speaker';
				case 'tutorial': gfVersion = 'gf-tutorial';
			}
			SONG.assets.gfVersion = gfVersion; //Fix for the Chart Editor
			SONG.assets.player3 = null; //your mother
		}
		var bfVersion:String = SONG.assets.player1;
		if (characterVersion != 'bf') bfVersion = characterVersion;
		if(bfVersion == null || bfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo': bfVersion = 'bf-car';
				case 'mall' | 'mallEvil': bfVersion = 'bf-christmas';
				case 'school' | 'schoolEvil': bfVersion = 'bf-pixel';
				case 'streetlight': bfVersion = 'bf-streetlight';
				default: bfVersion = 'bf';
			}
			switch(Paths.formatToSongPath(SONG.header.song))
			{
				case 'stress': bfVersion = 'bf-holding-gf';
			}
			SONG.assets.player1 = bfVersion;
		}
		var dadVersion:String = SONG.assets.player2;
		if(dadVersion == null || dadVersion.length < 1) {
			switch (curStage)
			{
				case 'limo': dadVersion = 'mom-car';
				case 'mall': dadVersion = 'parents-christmas';
				case 'mallEvil': dadVersion = 'monster-christmas';
				case 'school': dadVersion = 'senpai';
				case 'schoolEvil': dadVersion = 'spirit';
				case 'streetlight': dadVersion = 'monster-streetlight';
				case 'spooky': dadVersion = 'spooky';
				case 'philly': dadVersion = 'pico';
				case 'tank': dadVersion = 'tankman';
				default: dadVersion = 'dad';
			}
			switch(Paths.formatToSongPath(SONG.header.song))
			{
				case 'tutorial': gfVersion = 'gf-tutorial';
			}
			SONG.assets.player2 = dadVersion;
		}
		var p4Version:String = SONG.assets.player4;
		if(p4Version == null || p4Version.length < 1) {
			p4Version = 'dad';
			SONG.assets.player4 = p4Version;
		}

		if (!stageData.hide_girlfriend)
		{
			Paths.setModsDirectoryFromType(CHARACTER, gfVersion, false);
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			gf.charGroup = gfGroup;
			startCharacterScripts(gf.curCharacter);
	
			if(gfVersion == 'pico-speaker')
			{
				if(!ClientPrefs.settings.get("lowQuality"))
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
			Paths.setModsDirectoryFromType(NONE, '', true);
		}

		Paths.setModsDirectoryFromType(CHARACTER, p4Version, false);
		player4 = new Character(0, 0, p4Version);
		startCharacterPos(player4, true);
		if (SONG.assets.enablePlayer4) {
			player4Group.add(player4);
			player4.charGroup = player4Group;
		}
		startCharacterScripts(player4.curCharacter);
		Paths.setModsDirectoryFromType(NONE, '', true);

		Paths.setModsDirectoryFromType(CHARACTER, dadVersion, false);
		dad = new Character(0, 0, dadVersion);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		dad.charGroup = dadGroup;
		startCharacterScripts(dad.curCharacter);
		Paths.setModsDirectoryFromType(NONE, '', true);
		
		Paths.setModsDirectoryFromType(CHARACTER, bfVersion, false);
		boyfriend = new Boyfriend(0, 0, bfVersion);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		boyfriend.charGroup = boyfriendGroup;
		startCharacterScripts(boyfriend.curCharacter);	

		if (boyfriend != null && boyfriend.deathProperties != null) {
			GameOverSubstate.characterName = boyfriend.deathProperties.character;
			GameOverSubstate.deathSoundName = boyfriend.deathProperties.startSfx;
			GameOverSubstate.loopSoundName = boyfriend.deathProperties.loopSfx;
			GameOverSubstate.endSoundName = boyfriend.deathProperties.endSfx;
			GameOverSubstate.loopBPM = boyfriend.deathProperties.bpm;
		}
		Paths.setModsDirectoryFromType(NONE, '', true);
		
		var camPos:FlxPoint = FlxPoint.get(boyfriendCameraOffset[0], boyfriendCameraOffset[1]);
		if(boyfriend != null && stageData.hide_girlfriend)
		{
			camPos.x += boyfriend.getGraphicMidpoint().x + boyfriend.cameraPosition.x;
			camPos.y += boyfriend.getGraphicMidpoint().y + boyfriend.cameraPosition.y;
		}
		else if(gf != null)
		{
			camPos.x = girlfriendCameraOffset[0];
			camPos.y = girlfriendCameraOffset[1];
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition.x;
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition.y;
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null) gf.visible = false;
		}

		switch(curStage)
		{
			case 'limo':
				resetBillBoard();
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
		}

		//flixel trails
		//keep this on, trails will not generate otherwise
		for(char in [dad, gf, boyfriend, player4])
			resetTrailOf(char);

		//orbit
		orbit = dad.orbit;

		callOnLuas('onCharacterCreation', []);
		callOnHscripts("onCharacterCreation", []);

		//in create(), this does the actual tinting
		if (SONG.options.tintRed != null && SONG.options.tintGreen != null && SONG.options.tintBlue != null) {
			if(SONG.options.tintRed != 255 && SONG.options.tintGreen != 255 && SONG.options.tintBlue != 255) {
				tintMap.set('stage', addATint(0.5, FlxColor.fromRGB(SONG.options.tintRed,SONG.options.tintGreen,SONG.options.tintBlue)));
			}
		}
		switch (SONG.header.song.toLowerCase()) {
			case 'south':
				defaultStageZoom = 1.075;
				tintMap.set('south', addATint(0.3, FlxColor.fromRGB(10,20,90)));
			case 'monster':
				tintMap.set('monster', addATint(1, FlxColor.fromRGB(10,20,90)));
			case 'eggnog':
				tintMap.set('eggnog', addATint(1, FlxColor.fromRGB(120,10,5)));
				camTint.alpha = 0;
			case 'roses':
				defaultStageZoom += 0.05;
				tintMap.set('roses', addATint(0.15, FlxColor.fromRGB(90,20,10))); 
			case 'senpai':
				tintMap.set('senpai-love', addATint(0, FlxColor.fromRGB(255,105,180)));
				tintMap['senpai-love'].visible = false;
		}

		//dialogue shit
		var file:String = '';
		var doof:DialogueBox = null;
		if(canIUseTheCutsceneMother()) {
			file = Paths.json('dialogue/' + songName + '/dialogue'); //Checks for json/Denpa Engine dialogue

			if (#if sys sys.FileSystem.exists(file) #else OpenFlAssets.exists(file) #end) {
				dialogueJson = DialogueBoxDenpa.parseDialogue(file);
			}
	
			file = Paths.txt('dialogue/' + songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
			if (#if sys sys.FileSystem.exists(file) #else OpenFlAssets.exists(file) #end) {
				dialogue = CoolUtil.coolTextFile(file);

				doof = new DialogueBox(dialogue);
				doof.scrollFactor.set();
				doof.finishThing = startCountdown;
				doof.nextDialogueThing = startNextDialogue;
				doof.skipDialogueThing = skipDialogue;
				doof.cameras = [camOther];
			}
			
		}

		Conductor.songPosition = -5000 / Conductor.songPosition;

		strumLine = new FlxSprite(ClientPrefs.settings.get("middleScroll") ? STRUM_X_MIDDLESCROLL : STRUM_X, ClientPrefs.settings.get("downScroll") ? FlxG.height - 150 : 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		updateTime = (ClientPrefs.settings.get("timeBarType") != 'Disabled');

		hud = new HUD();
		hud.cameras = [camHUD];

		sustains = new FlxTypedGroup<Note>();
		add(sustains);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		//strum line settings
		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		thirdStrums = new FlxTypedGroup<StrumNote>();

		//modcharts
		playerModchart = new Modcharts(SONG.options.modchart, 0);
		dadModchart = new Modcharts(SONG.options.dadModchart, 1);
		p4Modchart = new Modcharts(SONG.options.p4Modchart, 2);

		generateSong();

		add(hud);

		camFollow = FlxPoint.get();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		camPos.put();
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

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultStageZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		moveCameraSection(0);

		//omg its that ms text from earlier
		msTxt = new FlxText(0, 0, 0, "");
		msTxt.cameras = [camHUD];
		msTxt.scrollFactor.set();
		msTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		msTxt.x = 408 + 250;
		msTxt.y = 290 - 25;
		if (PlayState.isPixelStage) {
			msTxt.x = 408 + 260;
			msTxt.y = 290 + 20;
		}
		msTxt.x += ClientPrefs.comboOffset[0];
		msTxt.y -= ClientPrefs.comboOffset[1];
		msTxt.active = false;
		msTxt.visible = false;
		insert(members.indexOf(strumLineNotes), msTxt);

		//icons
		//do a change icon on start with the chara to properly set the offsets
		Paths.setModsDirectoryFromType(ICON, boyfriend.iconProperties.name, false);
		iconP1 = new HealthIcon(boyfriend.iconProperties.name, true);
		iconP1.ignoreChange = true;
		iconP1.changeIcon(boyfriend.iconProperties.name, boyfriend);

		iconP1Poison = new HealthIcon(boyfriend.iconProperties.name, true);
		iconP1Poison.ignoreChange = true;
		iconP1Poison.changeIcon(boyfriend.iconProperties.name, boyfriend);
		iconP1Poison.visible = false;
		if (!poison) iconP1Poison.active = false;
		iconP1Poison.setColorTransform(1,0,1,1,255,-231,255,0);
		Paths.setModsDirectoryFromType(NONE, '', true);

		Paths.setModsDirectoryFromType(ICON, dad.iconProperties.name, false);
		iconP2 = new HealthIcon(dad.iconProperties.name, false);
		iconP2.ignoreChange = true;
		iconP2.changeIcon(dad.iconProperties.name, dad);
		Paths.setModsDirectoryFromType(NONE, '', true);

		Paths.setModsDirectoryFromType(ICON, player4.iconProperties.name, false);
		iconP4 = new HealthIcon(player4.iconProperties.name, false);
		iconP4.ignoreChange = true;
		iconP4.changeIcon(player4.iconProperties.name, player4);
		iconP4.scale.set(0.75, 0.75);
		iconP4.updateHitbox();
		Paths.setModsDirectoryFromType(NONE, '', true);
		setIconPositions(true);

		iconP4.visible = iconP1.visible = iconP2.visible = !ClientPrefs.settings.get("hideHud");
		if (iconP4.visible && !SONG.assets.enablePlayer4) iconP4.active = iconP4.visible = false; 

		add(iconP4);
		add(iconP1Poison);
		add(iconP1);
		add(iconP2);
		recalculateIconAnimations(true);
		setIconPositions();
		reloadHealthBarColors(false);

		flashLightSprite = new FlxSprite().loadGraphic(Paths.image('effectSprites/flashlightEffect'));
		flashLightSprite.scrollFactor.set();
		flashLightSprite.visible = flashLight;
		flashLightSprite.cameras = [camHUD];
		flashLightSprite.scale.set(1.5,1.5);
		flashLightSprite.updateHitbox();
		flashLightSprite.x = FlxG.width - flashLightSprite.width;
		flashLightSprite.x += 180;
		flashLightSprite.flipY = ClientPrefs.settings.get("downScroll") ? true : false;
		flashLightSprite.y = ClientPrefs.settings.get("downScroll") ? FlxG.height - flashLightSprite.height : 0;
		if (flashLight) {
			var black:FlxSprite = new FlxSprite(0,ClientPrefs.settings.get("downScroll") ? flashLightSprite.y : 0).makeGraphic(Math.floor(flashLightSprite.x), Math.floor(flashLightSprite.height), FlxColor.BLACK);
			black.scrollFactor.set();
			black.cameras = [camHUD];
			add(black);
			var black2:FlxSprite = new FlxSprite(0,ClientPrefs.settings.get("downScroll") ? 0 : black.height).makeGraphic(FlxG.width, Math.floor(FlxG.height-black.height), FlxColor.BLACK);
			black2.scrollFactor.set();
			black2.cameras = [camHUD];
			add(black2);
			add(flashLightSprite);
		} else {
			flashLightSprite = null;
		}

		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');
		final modifierDatas:Array<ModifierSpriteData> = [
			{name: 'botplay', condition: cpuControlled, xPos:0, yPos:0},
			{name: 'healthgain', condition: healthGain != 1, xPos:0, yPos:1},
			{name: 'healthloss', condition: healthLoss != 1, xPos:0, yPos:2},
			{name: 'instakill', condition: instakillOnMiss, xPos:0, yPos:3},
			{name: 'poison', condition: poison, xPos:1, yPos:0},
			{name: 'practice', condition: practiceMode, xPos:1, yPos:1},
			{name: 'sickonly', condition: sickOnly, xPos:1, yPos:2},
			{name: (songSpeedType == 'constant' ? 'scrolltypeconstant' : 'scrolltypemultiplicative'), condition: (songSpeedType == 'constant' ? true : ClientPrefs.getGameplaySetting('scrollspeed', 1) != 1), xPos:1, yPos:3},
			{name: 'freeze', condition: freeze, xPos:2, yPos:0},
			{name: 'flashlight', condition: flashLight, xPos:2, yPos:1},
			{name: 'randommode', condition: randomMode, xPos:2, yPos:2},
			{name: 'ghostmode', condition: ghostMode, xPos:2, yPos:3},
			{name: 'quartiz', condition: quartiz, xPos:3, yPos:0},
			{name: 'flip', condition: flip, xPos:3, yPos:1}
		];

		for (data in modifierDatas) {
			if (!data.condition) continue;
			var spr:ModifierSprite = new ModifierSprite(data.name, camHUD, data.xPos, data.yPos);
			add(spr);
			FlxTween.tween(spr, {alpha: 0}, 0.5, {
				ease: FlxEase.quadInOut,
				startDelay: 2.5/(Conductor.bpm/100),
				onComplete: _ -> {
					remove(spr, true);
					spr.destroy();
				}
			});
		}

		if (poison) {
			poisonSpriteGrp = new FlxTypedGroup();
			makeEffectOverlay('poisonEffect', poisonSpriteGrp);
		}

		if (freeze) {
			freezeSpriteGrp = new FlxTypedGroup();
			makeEffectOverlay('freezeEffect', freezeSpriteGrp);
		}

		//lets set ALL the cameras at once
		iconP1Poison.cameras = iconP1.cameras = iconP2.cameras = iconP4.cameras = sustains.cameras = notes.cameras = grpNoteSplashes.cameras = strumLineNotes.cameras = [camHUD];

		startingSong = true;

		// CUSTOM NOTETYPES AND EVENT SCRIPTS
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('scripts/notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('scripts/notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('scripts/events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('scripts/events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var hscriptToLoad:String = Paths.modFolders('scripts/notetypes/' + notetype + '.hscript');
			if(FileSystem.exists(hscriptToLoad))
			{
				hscripts.push(new Hscript(hscriptToLoad));
			}
			else
			{
				hscriptToLoad = Paths.getPreloadPath('scripts/notetypes/' + notetype + '.hscript');
				if(FileSystem.exists(hscriptToLoad))
				{
					hscripts.push(new Hscript(hscriptToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var hscriptToLoad:String = Paths.modFolders('scripts/events/' + event + '.hscript');
			if(FileSystem.exists(hscriptToLoad))
			{
				hscripts.push(new Hscript(hscriptToLoad));
			}
			else
			{
				hscriptToLoad = Paths.getPreloadPath('scripts/events/' + event + '.hscript');
				if(FileSystem.exists(hscriptToLoad))
				{
					hscripts.push(new Hscript(hscriptToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/songs/' + Paths.formatToSongPath(SONG.header.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/songs/' + Paths.formatToSongPath(SONG.header.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/songs/' + Paths.formatToSongPath(SONG.header.song) + '/'));
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

		#if HSCRIPT_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/songs/' + Paths.formatToSongPath(SONG.header.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/songs/' + Paths.formatToSongPath(SONG.header.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/songs/' + Paths.formatToSongPath(SONG.header.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.hscript') && !filesPushed.contains(file))
					{
						hscripts.push(new Hscript(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		switch (SONG.header.song.toLowerCase()) {
			case 'south':
				defaultStageZoom = 1.075;
			case 'roses':
				defaultStageZoom += 0.05;
			case 'thorns':
				boyfriend.alpha = 0;
				gf.alpha = 0;
				playerStrums.visible = false;
				hud.y = 1280;
				setIconPositions(true);
		}
		
		//cutscene shit
		var daSong:String = Paths.formatToSongPath(SONG.header.song);
		if (canIUseTheCutsceneMother())
		{
			recalculateIconAnimations(true); //ok yanni | ok AT
			hasCutscene = true; //set to false on default

			switch (daSong)
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					blackScreen.screenCenter();
					camHUD.visible = false;
					inCutscene = true;

					new FlxTimer().start(1.2, function(_) {
						FlxG.sound.play(Paths.sound('vanilla/week5/Lights_Turn_On'));
						blackScreen.alpha = 0;
					});
					snapCamFollowToPos(930, -450);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.6;

					new FlxTimer().start(2.2, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						camHUD.alpha = 0;
						remove(blackScreen, true);
						blackScreen.destroy();
						FlxTween.tween(camHUD, {alpha: 1}, 2.5, {ease: FlxEase.quadInOut});
						FlxTween.tween(FlxG.camera, {zoom: defaultStageZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> startCountdown()
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					schoolIntro(doof);
				case 'ugh' | 'guns' | 'stress':
					tankIntro();
				default:
					callOnHscripts("onCutscene", []);
					startCountdown();
					hasCutscene = false;
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		recalculateRating();
		#if desktop
		ratingText = ratingName + " " + ratingFC;
		#end

		if(ClientPrefs.settings.get("hitsoundVolume") > 0) precacheList.set('hitsound', 'sound');
		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');
		if(SONG.options.crits) precacheList.set('crit', 'sound');

		if (PauseSubState.songName != null)
			precacheList.set(PauseSubState.songName, 'music');
		else if(ClientPrefs.settings.get("pauseMusic") != 'None')
			precacheList.set(Paths.formatToSongPath(ClientPrefs.settings.get("pauseMusic")), 'music');

		//cant use keyPress override because it would count EVERY key
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		callOnLuas('onCreatePost', []);
		callOnHscripts("onCreatePost", []);

		if (customTransition && loading != null) {
			FlxTween.tween(loading, {alpha: 0}, 0.45, {
				onComplete: _ -> {
					remove(loading, true);
					loading.destroy();
				}
			});
		}
		customTransition = true;

		#if desktop
		var updaterThing:Single = 0.1;
		discordUpdateTimer = new FlxTimer().start(updaterThing, function(tmr:FlxTimer){
			if (updaterThing < 1)
				updaterThing = 1;
			if (!inCutscene && !cutsceneHandlerCutscene) {
				var player:String = CoolUtil.toTitleCase(iconP1.char);
				DiscordClient.changePresence(paused ? 'Paused - ' + detailsText : detailsText + ' - Playing as ' + player, SONG.header.song + " (" + storyDifficultyText + ")" + " -" + ((ratingText.toLowerCase().trim() == 'unrated') ? " " + ratingText : " Rating " + ratingText), iconP2.char, false);
			} else if (inCutscene || cutsceneHandlerCutscene) {
				DiscordClient.changePresence(detailsText, SONG.header.song + " - In a Cutscene", iconP2.char, false);
			}
		}, 0);
		#end
		
		super.create();

		#if (target.threaded && sys)
		Main.threadPool.run(() -> {
		#end
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
			Paths.clearUnusedCache();
		#if (target.threaded && sys)
		});
		#end
		CustomFadeTransition.nextCamera = camOther;
		if(eventNotes.length < 1) checkEventNote();
		persistentUpdate = persistentDraw = true;
	}

	function makeEffectOverlay(image:String, targetGroup:FlxTypedGroup<FlxSprite>) {
		for (i in 0...4) {
			var corner:FlxSprite = new FlxSprite().loadGraphic(Paths.image('effectSprites/$image'));
			corner.alpha = 0.001;
			corner.visible = false;
			corner.scrollFactor.set();
			corner.cameras = [camHUD];
			switch (i) {
				case 0:
					//top right
					corner.x = FlxG.width - corner.width;
				case 1:
					//bottom right
					corner.flipY = true;
					corner.x = FlxG.width - corner.width;
					corner.y = FlxG.height - corner.height;
				case 2:
					//top left
					corner.flipX = true;
				case 3:
					//bottom left
					corner.flipX = true;
					corner.flipY = true;
					corner.y = FlxG.height - corner.height;
			}
			targetGroup.add(corner);
		}
		add(targetGroup);
	}

	//WOO YEAH BABY
	//THATS WHAT IVE BEEN WAITING FOR
	public function cacheDeath()
	{
		var characterPath:String = 'data/characters/' + GameOverSubstate.characterName + '.json';
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
			path = Paths.getPreloadPath('data/characters/bf-dead.json'); //If a character couldn't be found, change him to BF just to prevent a crash
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

	public function set_playbackRate(value:Single):Single
	{
		if(generatedMusic)
		{
			try {
				if(vocals != null) vocals.pitch = value;
				if(secondaryVocals != null) secondaryVocals.pitch = value;
				FlxG.sound.music.pitch = value;
			} catch (e) {
				if(vocals != null) vocals.pitch = 1;
				if(secondaryVocals != null) secondaryVocals.pitch = 1;
				FlxG.sound.music.pitch = 1;
				trace('exception: ' + e);
			}
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		Conductor.safeZoneOffset = (ClientPrefs.settings.get("safeFrames") / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}

	public function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (sustain in sustains)
			{
				if (!sustain.animation.curAnim.name.endsWith('tail')) {
					sustain.scale.y *= ratio;
					sustain.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote)
				{
					if(!note.animation.curAnim.name.endsWith('tail'))
					{
						note.scale.y *= ratio;
						note.updateHitbox();
					}
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
		if (luaDebugGroup == null) return;
		luaDebugGroup.forEachAlive(spr -> {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			luaDebugGroup.remove(blah, true);
			blah.destroy();
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	//this function might be a little confusing so ill explain (helpful comment man is here). the first variable is if its using p4 as the main icon or dad. the second is for if its gf or dad.
	public function reloadHealthBarColors(p4:Bool, ?useGf:Bool = null, ?usePoison:Bool = null, ?otherGfVariable:Bool = null)
	{
		hud.healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		hud.healthBar.updateBar();
		if (ClientPrefs.settings.get("ogHp")) return;

		var who:Character = p4 ? player4 : dad; //who is either dad or p4, whichever has priority
		var who2:Character = boyfriend;
		
		//not even gonna ask and just keep it like this
		if (useGf && otherGfVariable == null) who = gf;
		if (useGf && otherGfVariable != null) who2 = gf;

		//CC stands for ColorContainer -> who_CC = who_ColorContainer
		var who_CC:HealthbarColorContainer = new HealthbarColorContainer(HealthbarColorContainer.getCharacterBarRGB(who));
		var who2_CC:HealthbarColorContainer = new HealthbarColorContainer(HealthbarColorContainer.getCharacterBarRGB(who2));

		if (cpuControlled && !ClientPrefs.settings.get('disableBotIcon')) who2_CC.setFadingColor(FlxColor.fromRGB(214,214,214));
		if (usePoison != null) who2_CC.setFadingColor(FlxColor.fromRGB(171,24,233));

		var whoColors:Array<FlxColor> = HealthbarColorContainer.createBarColorArray(who, who_CC);
		var who2Colors:Array<FlxColor> = HealthbarColorContainer.createBarColorArray(who2, who2_CC);
		hud.healthBar.splitColor(false, whoColors).splitColor(true, who2Colors);
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					newBoyfriend.charGroup = boyfriendGroup;
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.active = false;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					newDad.charGroup = dadGroup; 
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.active = false;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					newGf.charGroup = gfGroup;
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					newGf.active = false;
					startCharacterScripts(newGf.curCharacter);
				}
			
			case 3:
				if(!player4Map.exists(newCharacter)) {
					var newP4:Character = new Character(0, 0, newCharacter);
					player4Map.set(newCharacter, newP4);
					player4Group.add(newP4);
					newP4.charGroup = player4Group;
					startCharacterPos(newP4, true);
					newP4.alpha = 0.00001;
					newP4.active = false;
					startCharacterScripts(newP4.curCharacter);
				}
		}
	}

	// CHARACTER SPECIFIC SCRIPTS
	public function startCharacterScripts(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'scripts/characters/' + name + '.lua';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
		#end
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		#if MODS_ALLOWED
		}
		#end
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) 
				{
					#if HSCRIPT_ALLOWED
					addHscript(name);
					//dont want to skip hscript eh?
					#end
					return;
				}
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end

		#if HSCRIPT_ALLOWED
		addHscript('characters/$name');
		#end
	}
	
	public function startCharacterPos(char:Character, ?gfCheck:Bool = false)
	{
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionOffset.x;
		char.y += char.positionOffset.y;
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

		var video:VideoHandler = new VideoHandler();
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
		if(endingSong) endSong();
		else startCountdown();
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
				denpaDialogue.finishThing = () -> {
					denpaDialogue = null;
					endSong();
				}
			} else {
				denpaDialogue.finishThing = () -> {
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
			if(endingSong) endSong();
			else startCountdown();
		}
	}

	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	inline private function generateSong():Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative": songSpeed = SONG.options.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant": songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		//why use a seperate var?
		Conductor.changeBPM(SONG.header.bpm);
		if (SONG.header.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.header.song));
			secondaryVocals = new FlxSound().loadEmbedded(Paths.secVoices(SONG.header.song));
		} else {
			vocals = new FlxSound();
			secondaryVocals = new FlxSound();
		}

		secondaryVocals.pitch = vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(secondaryVocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(SONG.header.song)));

		if (SONG.header.vocalsVolume == null) SONG.header.vocalsVolume = 1;
		if (SONG.header.secVocalsVolume == null) SONG.header.secVocalsVolume = 1;
		if (SONG.header.instVolume == null) SONG.header.instVolume = 1;

		FlxG.sound.music.volume = SONG.header.instVolume;
		vocals.volume = SONG.header.vocalsVolume;
		secondaryVocals.volume = SONG.header.secVocalsVolume;

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		noteData = SONG.notes;

		var songName:String = Paths.formatToSongPath(SONG.header.song);
		var file:String = Paths.json('charts/' + songName + '/events');
	
		if (#if sys FileSystem.exists(Paths.modsJson('charts/' + songName + '/events')) || FileSystem.exists(file) #else OpenFlAssets.exists(file) #end) {
			final songData = Song.loadFromJson('events', songName);
			//if (songData.events == SONG.events) songData.events = [];
			var eventsData:Array<Dynamic> = songData.events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.settings.get("noteOffset"),
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		var bpmChangeIterator:Int = 0;
		var susCrochet:Float = Conductor.stepCrochet;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int;
				final modifierArr:Array<Bool> = [randomMode, flip];
				switch (modifierArr) {
					case [true, false] | [true, true]:
						daNoteData = FlxG.random.int(0, mania);
					case [false, true]:
						daNoteData = Std.int(Math.abs((songNotes[1] % Note.ammo[mania]) - mania)); //we do a little value flipping
					default:
						daNoteData = Std.int(songNotes[1] % Note.ammo[mania]);
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
				swagNote.sustainLength = Math.round(songNotes[2] / susCrochet) * susCrochet;
				swagNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				swagNote.scrollFactor.set();
				//swagNote.canBeHit = swagNote.mustPress;
				unspawnNotes.push(swagNote);
	
				var floorSus:Int = Math.round(swagNote.sustainLength / susCrochet);
	
				if(floorSus > 0) {
					if(floorSus == 1) floorSus++;
					for (susNote in 0...floorSus)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = new Note(daStrumTime + (susCrochet * susNote) + (susCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<Note.ammo[mania]));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						//sustainNote.canBeHit = sustainNote.mustPress;
						unspawnNotes.push(sustainNote);
					}
				}
	
				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
		}
		for (event in SONG.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.settings.get("noteOffset"),
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;

		callOnHscripts("onSongGenerated", []);
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
	public static var charterStart:Bool = false;

	public function startCountdown():Void {
		//dont want to call onStartCountdown when the countdown didnt actually start
		if (stopCountdown) return;

		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			callOnHscripts("onStartCountdown", []);
			return;
		}

		switch (SONG.header.song.toLowerCase()) {
			case 'senpai' | 'roses' | 'thorns':
				if (inCutscene) {
					new FlxTimer().start(0.15/(Conductor.bpm/100)/playbackRate, function(tmr:FlxTimer) {
						camHUD.alpha += 0.3;
						if (camHUD.alpha < 1)
							tmr.reset(0.15);
					});
				}

				if(SONG.header.song.toLowerCase() == 'senpai') setBeatZooms(1, 0); //make sure it starts off fast
		}
		inCutscene = false;
		recalculateIconAnimations(true);
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);

		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			if (SONG.assets.enablePlayer4) generateStaticArrows(2);
			skipNextArrowTween = false;
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				if(ClientPrefs.settings.get("middleScroll")) opponentStrums.members[i].visible = false;
			}
			if (SONG.assets.enablePlayer4) {
				for (i in 0...thirdStrums.length) {
					setOnLuas('defaultThirdStrumX' + i, thirdStrums.members[i].x);
					setOnLuas('defaultThirdStrumY' + i, thirdStrums.members[i].y);
					thirdStrums.members[i].cameras = [camGame];
					thirdStrums.members[i].scrollFactor.set(1,1);
				}
			}

			if(SONG.header.song.toLowerCase() == 'thorns') {
				playerStrums.forEach(function(spr:StrumNote) {
					spr.x += 1000;
				});
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);
			callOnHscripts("onCountdownStarted", []);

			var swagCounter:Int = 0;

			if (skipCountdown || startOnTime > 0) {
				clearNotesBefore(startOnTime - 500);
				setSongTime(startOnTime - 1000);
				return;
			}

			hud.tweenInCard();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				for (char in [boyfriend, dad, player4]) {
					if (char != null && tmr.loopsLeft % char.danceEveryNumBeats == 0 && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith('sing') && !char.stunned)
						char.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.settings.get("globalAntialiasing");
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.settings.get("lowQuality")) for (bopper in upperBoppers) bopper.dance(true);
					
					bottomBoppers.dance(true);
					santa.dance(true);
				}

				var sprites = [countdownReady, countdownSet, countdownGo];
				function countdownSprite(num:Int) {
					var sprite = sprites[num];
					sprite = new FlxSprite().loadGraphic(Paths.image(introAlts[num]));
					sprite.scrollFactor.set();
					sprite.updateHitbox();

					if (PlayState.isPixelStage)
						sprite.setGraphicSize(Std.int(sprite.width * daPixelZoom));

					sprite.screenCenter();
					sprite.antialiasing = antialias;
					sprite.cameras = [camHUD];
					add(sprite);
					FlxTween.tween(sprite, {'scale.x': sprite.scale.x*1.0228991278, 'scale.y': sprite.scale.y*1.0428991278, alpha: 0}, Conductor.crochet / 1000 / playbackRate, {
						ease: FlxEase.cubeInOut,
						onComplete: _ -> {
							remove(sprite, true);
							sprite.destroy();
						}
					});
				}
				switch (swagCounter)
				{
					case 0:
						canPause = true;
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownSprite(swagCounter-1);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSprite(swagCounter-1);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownSprite(swagCounter-1);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						for (char in [dad, boyfriend, gf, player4]) {
							if(char != null && (char.animOffsets.exists('hey') || char.animOffsets.exists('cheer'))) {
								char.playAnim(char.animOffsets.exists('hey') ? 'hey' : 'cheer', true);
								char.specialAnim = true;
								char.heyTimer = 0.6;
							}
						}
				}

				function setNoteAlphas(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.settings.get("middleScroll") && !note.mustPress) {
						note.alpha = 0.001;
					}
				}
				//tasty inline
				notes.forEachAlive(note -> setNoteAlphas(note));
				sustains.forEachAlive(sus -> setNoteAlphas(sus));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHscripts("onCountdownTick", [swagCounter]);

				swagCounter++;
			}, 4);
		}
	}

	inline public function addBehindGF(obj:FlxObject)
		insert(members.indexOf(gfGroup), obj);

	inline public function addBehindBF(obj:FlxObject)
		insert(members.indexOf(boyfriendGroup), obj);

	inline public function addBehindDad (obj:FlxObject)
		insert(members.indexOf(dadGroup), obj);

	public function clearNotesBefore(time:Float)
	{
		//i suggest not messing with this
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 500 < time)
			{
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
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}

		i = sustains.length - 1;
		while (i >= 0) {
			var daNote:Note = sustains.members[i];
			if(daNote.strumTime - 500 < time)
			{
				sustains.remove(daNote, true);
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

		if (charterStart) {
			charterStart = false;
			final volumes = [FlxG.sound.music.volume, vocals.volume, secondaryVocals.volume];
			//i feel like this isnt working for the music volume
			FlxG.sound.music.volume = 0;
			vocals.volume = 0;
			secondaryVocals.volume = 0;
			new FlxTimer().start(0.2, _ -> {
				var sprite = new FlxSprite().loadGraphic(Paths.image(isPixelStage ? 'pixelUI/date-pixel' : 'go'));
				sprite.scrollFactor.set();
				sprite.updateHitbox();
	
				if (PlayState.isPixelStage)
					sprite.setGraphicSize(Std.int(sprite.width * daPixelZoom));
	
				sprite.screenCenter();
				sprite.antialiasing = (isPixelStage ? false : ClientPrefs.settings.get('globalAntialiasing'));
				sprite.cameras = [camHUD];
				add(sprite);
				FlxTween.tween(sprite, {'scale.x': sprite.scale.x*1.0228991278, 'scale.y': sprite.scale.y*1.0428991278, alpha: 0}, 0.8 / playbackRate, {
					ease: FlxEase.cubeInOut,
					onComplete: _ -> {
						remove(sprite, true);
						sprite.destroy();
						FlxG.sound.music.volume = volumes[0];
						vocals.volume = volumes[1];
						secondaryVocals.volume = volumes[2];
					}
				});
				FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
			});
		}
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
		callOnHscripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
		callOnHscripts('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.header.song), 1, false);
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		secondaryVocals.play();

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
			secondaryVocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		hud.timeBar.scale.x = 0.01;
		hud.timeBarBG.scale.x = 0.01;
		if (isPixelStage) {
			var loops:Int = 0;
			new FlxTimer().start(0.1, tmr -> {
				loops++;
				hud.timeBarBG.scale.x = hud.timeBar.scale.x = FlxMath.lerp(hud.timeBar.scale.x, 1, 0.7);
				hud.timeBar.alpha += 0.2;
				hud.timeBarBG.alpha += 0.2;
				hud.timeTxt.alpha += 0.2;
				if (loops < 5) tmr.reset(0.1);
			});
		} else {
			FlxTween.tween(hud.timeBar, {alpha: 1, "scale.x": 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(hud.timeBarBG, {alpha: 1, "scale.x": 1}, 0.5, {ease: FlxEase.circOut});
			FlxTween.tween(hud.timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

		switch(curStage)
		{
			case 'tank':
				if(!ClientPrefs.settings.get("lowQuality")) tankWatchtower.dance();
				foregroundSprites.forEach(spr -> spr.dance());
		}
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
		callOnHscripts('onSongStart', []);
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
				blammedLightsBlack = new FlxSprite().makeGraphic(Std.int(FlxG.width/defaultStageZoom*1.1), Std.int(FlxG.height/defaultStageZoom*1.1), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				blammedLightsBlack.scrollFactor.set();
				blammedLightsBlack.screenCenter();
				phillyGroupThing.insert(0, blammedLightsBlack);

				if (curStage == 'philly') {
					phillyWindowEvent = new BGSprite('vanilla/week3/philly/window',-10, 0, 0.3, 0.3);
					phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
					phillyWindowEvent.updateHitbox();
					phillyWindowEvent.visible = false;
					phillyGroupThing.insert(1, phillyWindowEvent);
				}

				phillyGlowGradient = new PhillyGlowGradient(-400, 225); //This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				phillyGroupThing.insert(2, phillyGlowGradient);
				if(!ClientPrefs.settings.get("flashing")) phillyGlowGradient.intendedAlpha = 0.7;

				precacheList.set('effectSprites/particle', 'image'); //precache particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				phillyGroupThing.insert(3, phillyGlowParticles);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnLuas('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) return returnedValue;

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	inline function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	inline function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int, ?changingMania:Bool = false):Void
	{
		for (i in 0...Note.ammo[mania])
		{
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.settings.get("middleScroll") ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.settings.get("downScroll");
			if (!skipArrowStartTween && !skipNextArrowTween)
			{
				if (changingMania == false) {
					babyArrow.y += (babyArrow.downScroll ? 40 : -40);
					babyArrow.alpha = 0.001;
					FlxTween.tween(babyArrow, {y: babyArrow.y + (babyArrow.downScroll ? -40 : 40), alpha: 1}, Conductor.crochet/ 333.334 / playbackRate, {
						ease: FlxEase.circOut,
						startDelay: 0.5 + (0.2 * i)/((mania < 1 ? 1 : mania)/2) //mfw 0.5/0 = inf
					});
				}
			}
	
			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else if (player == 0)
			{
				if(ClientPrefs.settings.get("middleScroll"))
				{
					var separator:Int = Note.separator[mania];
	
					babyArrow.x += 310;
					if(i > separator) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
					babyArrow.visible = false;
				}
				opponentStrums.add(babyArrow);
			}
			else
			{
				babyArrow.y += 200;
				babyArrow.cameras = [camGame];
				babyArrow.scrollFactor.set(1,1);
				thirdStrums.add(babyArrow);
			}
	
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
			if (flip) {
				//this is so not gonna work on multikey but it will be fixed later
				var flipper:Float = 0;
				final offset:Single = isPixelStage ? 1.1 : 1.05;
				switch (i) {
					case 0:
						flipper = babyArrow.width*offset * 3;
					case 1:
						flipper = babyArrow.width*offset;
					case 2:
						flipper = -(babyArrow.width*offset);
					case 3:
						flipper = -(babyArrow.width*offset * 3);
				}
				babyArrow.x += flipper;
				babyArrow.angle += 180;
			}
			babyArrow.strum = player;
		}
	}

	//sustains do not change properly
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
		
				if(fade != 0) FlxTween.tween(oldStrum, {alpha: 0}, 1, {onComplete: _ -> remove(oldStrum, true)});
				else remove(oldStrum, true);
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
		
				if(fade != 0) FlxTween.tween(oldStrum, {alpha: 0}, 1, {onComplete: _ -> remove(oldStrum, true)});
				else remove(oldStrum, true);
			}
		}
	
		playerStrums.clear();
		opponentStrums.clear();
		thirdStrums.clear();
		strumLineNotes.clear();
	
		generateStaticArrows(0, fade == 0);
		generateStaticArrows(1, fade == 0);
		if (SONG.assets.enablePlayer4) generateStaticArrows(2, fade == 0);
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

			for (char in [boyfriend, gf, dad, player4]) {
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

			if(rainSound != null)
				rainSound.pause();
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

			for (char in [boyfriend, gf, dad, player4]) {
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

			if(rainSound != null)
				rainSound.play();

			paused = false;
			callOnLuas('onResume', []);
			callOnHscripts('onResume', []);
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		callOnHscripts('onFocus', []);
		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		callOnHscripts('onFocusLost', []);
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
	@:noCompletion private var orbit_sine:Float = 0;
	@:noCompletion private var orbit_front:Bool = false;
	@:noCompletion private var orbit_done:Bool = false;

	override public function update(elapsed:Float)
	{
		#if debug Debug.instance.onUpdate(); #end

		//stupid guns shit
		if (SONG.header.song.toLowerCase() == 'guns' && tankmanRainbow) {
			dad.y += (Math.sin(elapsedtime) * 0.2)*FlxG.elapsed*244; //i want you to go up not down silly tankman
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

		//kinda like genocide, it gradually drains your hp back to normal.
		if (SONG.options.crits) {
			if(maxHealth > 2) {
				maxHealth -= 0.0066666666666667;
				hud.healthBar.x += 1;
			} else {
				if (hud.healthBar.x != (FlxG.width/4) + 4) {
					FlxTween.tween(hud.healthBar, {x: (FlxG.width/4) + 4}, 0.1);
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
			var curTime:Float = Conductor.songPosition - ClientPrefs.settings.get("noteOffset");
			if(curTime < 0) curTime = 0;
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(cast (ClientPrefs.settings.get("timeBarType"), String).contains('Elapsed')) songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.settings.get("timeBarType") != 'Song Name')
				hud.timeTxt.text = '${FlxStringUtil.formatTime(secondsTotal, false)}${cast(ClientPrefs.settings.get("timeBarType"), String).contains('/') ? ' / ${FlxStringUtil.formatTime(songLength / 1000, false)}' : ''}';
		}
		//hard coded shader cast
		if (curbg != null)
		{
			var shad = cast(curbg.shader, GlitchShader);
			shad.uTime.value[0] += elapsed;
		}
		//lua shader cast
		if (luabg != null)
		{
			var shad = cast(luabg.shader, GlitchShader);
			shad.uTime.value[0] += elapsed;
		}

		//ooo floating
		for (char in [boyfriend, dad, player4, gf]) {
			if (char != null && char.sarventeFloating) {
				char.y += (Math.sin(elapsedtime*char.floatSpeed) * char.floatMagnitude)*FlxG.elapsed*244;
			}
		}

		if(orbit) {
			orbit_sine += elapsed * 2.5;
			dad.x = boyfriend.getMidpoint().x + Math.sin(orbit_sine) * 500 - (dad.width / 2);
			dad.y += (Math.sin(elapsedtime) * 0.2);

			if ((Math.sin(orbit_sine) >= 0.95 || Math.sin(orbit_sine) <= -0.95) && !orbit_done){
				orbit_front = !orbit_front;
				//dont need another character when we can just move the grp
				remove(dadGroup);
				insert(members.indexOf(boyfriendGroup) + (orbit_front ? 1 : -1), dadGroup);
				orbit_done = true;
			}
			if (orbit_done && !(Math.sin(orbit_sine) >= 0.95 || Math.sin(orbit_sine) <= -0.95)) orbit_done = false;
		}

		callOnLuas('onUpdate', [elapsed]);
		callOnHscripts('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'tank': moveTank(elapsed);
			case 'schoolEvil': if(!ClientPrefs.settings.get("lowQuality") && bgGhouls.animation.curAnim.finished) bgGhouls.visible = false;
			case 'limo':
				if(!ClientPrefs.settings.get("lowQuality")) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
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
											if(i == 0) FlxG.sound.play(Paths.sound('vanilla/week4/dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('vanilla/week4/gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('vanilla/week4/gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('vanilla/week4/gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('vanilla/week4/gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
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
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.clamp(elapsed * 9, 0, 1));
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
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		//way better than before :muscle:
		if(!inCutscene) {
			final lerpVal:Float = CoolUtil.clamp(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x + moveCamTo[0]/102, camFollow.x + moveCamTo[0]/102, lerpVal), FlxMath.lerp(camFollowPos.y + moveCamTo[1]/102, camFollow.y + moveCamTo[1]/102, lerpVal));
			final panLerpVal:Float = CoolUtil.clamp(elapsed * 4.4 * cameraSpeed, 0, 1);
			moveCamTo[0] = FlxMath.lerp(moveCamTo[0], 0, panLerpVal);
			moveCamTo[1] = FlxMath.lerp(moveCamTo[1], 0, panLerpVal);
		}

		super.update(elapsed);

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
					secondaryVocals.pause();
					@:privateAccess { //This is so hiding the debugger doesn't play the music again
						FlxG.sound.music._alreadyPaused = true;
						vocals._alreadyPaused = true;
						secondaryVocals._alreadyPaused = true;
					}
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
			openChartEditor();

		// I mean, this works without an extra var, you sure it's needed??
		// I'll revert the change if so
		health = FlxMath.lerp(health, intendedHealth, CoolUtil.clamp(elapsed*65, 0, 1));

		//not optimized! hell yeah!
		// but I love optimization :(
		if (ClientPrefs.settings.get("scoreDisplay") == 'FNF+') hud.rightTxt.text = 'HP\n${hud.healthBar.roundedPercent}%\n\nACCURACY\n${Highscore.floorDecimal(ratingPercent * 100, 2)}%\n\nSCORE\n${FlxStringUtil.formatMoney(songScore, false)}';

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
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

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
				}
			}
		}

		if (camZooming) {
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.clamp(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(defaultHudCamZoom, camHUD.zoom, CoolUtil.clamp(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		//we dont need to watch most of these
		#if debug
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);
		FlxG.watch.addQuick("sectionShit", curSection);
		FlxG.watch.addQuick("health", health);
		FlxG.watch.addQuick("camFollow", camFollow);
		#end

		if (ClientPrefs.settings.get("scoreDisplay") == 'Kade') {
			if (ratingFC != "") {
				hud.scoreTxt.text = 'NPS/MAX: $notesPerSecond/$maxNps | SCORE: ${FlxStringUtil.formatMoney(songScore, false)} | BREAKS: ${FlxStringUtil.formatMoney(songMisses, false)} | ACCURACY: ${Highscore.floorDecimal(ratingPercent * 100, 2)}% | ($ratingFC) $ratingName';
			} else {
				hud.scoreTxt.text = 'NPS/MAX: $notesPerSecond/$maxNps | SCORE: ${FlxStringUtil.formatMoney(songScore, false)} | BREAKS: ${FlxStringUtil.formatMoney(songMisses, false)} | ACCURACY: ${Highscore.floorDecimal(ratingPercent * 100, 2)}% | $ratingName';
			}
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
		if (!ClientPrefs.settings.get("noReset") && controls.RESET && !inCutscene && !endingSong)
			doDeathCheck(true);

		//NOTE SPAWNING BABY!!
		//swap to recylcing soon
		if (unspawnNotes[0] != null)
		{
			final spawnTime:Float = (1750/songSpeed)/(FlxMath.bound(camHUD.zoom, null, 1)); //spawns within [time] ms (btw this BARELY edges close enough to the screen to not be too far ahead and not spawning on screen)

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < spawnTime * unspawnNotes[0].spawnTimeMult)
			{
				var dunceNote:Note = unspawnNotes.shift();
				if(ghostMode) ghostModeRoutine(dunceNote);
				if (!dunceNote.isSustainNote)
					notes.insert(0, dunceNote);
				else
					sustains.insert(0, dunceNote);
			}
		}

		checkEventNote();

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}
			}

			var fakeCrochet:Float = (60 / Conductor.bpm) * 1000;
			//fuck off man
			if (!inCutscene && !cutsceneHandlerCutscene) {
				for (group in [notes, sustains]) group.forEachAlive(daNote -> {
					var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
					if(!daNote.mustPress && daNote.strum < 2) daNote.strum = 1;
                    switch (daNote.strum) {
                        case 0: strumGroup = playerStrums;
                    	case 1: strumGroup = opponentStrums;
                        case 2:
							strumGroup = thirdStrums;
							daNote.cameras = [camGame];
							daNote.scrollFactor.set(1,1);
                    }

					if (strumGroup.members[daNote.noteData] == null) daNote.noteData = mania;

					daNote.distance = ((strumGroup.members[daNote.noteData].downScroll ? 0.45 : -0.45) * (Conductor.songPosition - daNote.strumTime) * songSpeed);

					if (daNote.copyScale) {
						daNote.scale.set(strumGroup.members[daNote.noteData].scale.x, strumGroup.members[daNote.noteData].scale.y);
						if (!daNote.scaleHackHitbox)
							daNote.updateHitbox();
					}

					final strumDirection:Float = strumGroup.members[daNote.noteData].direction;
					final angleDir = strumDirection * Math.PI / 180;

					if (!daNote.isSustainNote) {
						if (daNote.copyAngle)
							daNote.angle = strumDirection - 90 + (strumGroup.members[daNote.noteData].angle + daNote.offsetAngle);
					} else {
						daNote.angle = strumDirection - 90 + (daNote.copyAngle ? (strumGroup.members[daNote.noteData].angle + daNote.offsetAngle) : 0);
					}

					if(daNote.copyAlpha)
						daNote.alpha = (strumGroup.members[daNote.noteData].alpha * daNote.multAlpha);

					if(daNote.copyVisible)
						daNote.visible = strumGroup.members[daNote.noteData].visible;

					if(daNote.copyX)
						daNote.x = (strumGroup.members[daNote.noteData].x + daNote.offsetX) + Math.cos(angleDir) * daNote.distance;

					if(daNote.copyY) {
						daNote.y = (strumGroup.members[daNote.noteData].y + daNote.offsetY) + Math.sin(angleDir) * daNote.distance;
						if (daNote.isSustainNote) {
							//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							if(strumGroup.members[daNote.noteData].downScroll)
							{
								if (daNote.animation.curAnim.name.endsWith('tail')) { 
									daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
									daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
									daNote.y += (isPixelStage ? 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom : -19);
								} 
								daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
								daNote.y += 27.5 * ((Conductor.bpm / 100) - 1) * (songSpeed - 1) * Note.scales[mania];
							}
						}
					}

					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
						opponentNoteHit(daNote, daNote.strum == 2);

					if(daNote.mustPress && cpuControlled) {
						if((daNote.strumTime <= Conductor.songPosition && !daNote.isSustainNote) || (daNote.isSustainNote && daNote.canBeHit))
							goodNoteHit(daNote);
					}

					if (daNote.isSustainNote) {
						var center:Float = (strumGroup.members[daNote.noteData].y + daNote.offsetY) + strumGroup.members[daNote.noteData].height / 2;
						if(strumGroup.members[daNote.noteData].sustainReduce && (daNote.mustPress || !daNote.ignoreNote) &&
							(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							if (strumGroup.members[daNote.noteData].downScroll)
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
					}

					// Kill extremely late notes and cause misses
					if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
							noteMiss(daNote);

						group.remove(daNote, true);
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
		}
		#end

		instance = this;

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
		callOnHscripts('onUpdatePost', [elapsed]);
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
		if (((practiceMode || health > 0) && !skipHealthCheck) || isDead) return false;
		var ret:Dynamic = callOnLuas('onGameOver', []);
		if(ret == FunkinLua.Function_Stop) return false;
		boyfriend.stunned = true;
		deathCounter++;
		paused = true;

		vocals.stop();
		secondaryVocals.stop();
		FlxG.sound.music.stop();

		persistentUpdate = persistentDraw = false;
		for (tween in modchartTweens)
			tween.active = true;
		for (timer in modchartTimers)
			timer.active = true;
		FlxAnimationController.globalSpeed = 1;
		openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionOffset.x, boyfriend.getScreenPosition().y - boyfriend.positionOffset.y, camFollowPos.x, camFollowPos.y));
				
		#if desktop
		discordUpdateTimer.cancel();
		// Game Over doesn't get his own variable because it's only used here
		DiscordClient.changePresence("Game Over", SONG.header.song + " (" + storyDifficultyText + ")", iconP2.char);
		#end
		isDead = true;
		return true;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
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
		return pressed;
	}

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
						bottomBoppers.playAnim('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1 && boyfriend.animOffsets.exists('hey')) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}
			
			case 'Philly Glow':
				var lightId:Int = Std.parseInt(value1);
				var colorInt:Int = Std.parseInt(value2);
				if(Math.isNaN(lightId)) lightId = 0;
				if(Math.isNaN(colorInt) || colorInt == 0) colorInt = 1;

				var doFlash:Void->Void = function() {
					var color:FlxColor = FlxColor.WHITE;
					if(!ClientPrefs.settings.get("flashing")) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15 / playbackRate, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.settings.get("camZooms"))
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
								who.color = FlxColor.WHITE;

							phillyGlowGradient.kill();
							phillyGlowParticles.forEach(function(particle:PhillyGlowParticle) {
								phillyGlowParticles.remove(particle, true);
								particle.destroy();
							});
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];
						if (colorInt != 1) color = FlxColor.fromInt(colorInt);

						if (!phillyGlowGradient.alive) phillyGlowGradient.revive();
						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.settings.get("camZooms"))
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
						else if(ClientPrefs.settings.get("flashing"))
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.settings.get("flashing")) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
							who.color = charColor;

						phillyGlowParticles.forEachAlive(particle -> particle.color = color);
						phillyGlowGradient.color = color;
						if (curStage == 'philly') phillyWindowEvent.color = color;

						color.brightness *= 0.5;

					case 2: // spawn particles
						if (curStage == 'philly') {
							var color:FlxColor = phillyLightsColors[curLightEvent];
							if(!ClientPrefs.settings.get("lowQuality"))
							{
								phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle) {
									if (particle.alpha > 0) {
										particle.color = color;
									} else {
										particle.kill(); //refresh recycler
									}
								});
								var particlesNum:Int = FlxG.random.int(8, 12);
								var width:Float = (2000 / particlesNum);
								for (j in 0...3)
								{
									for (i in 0...particlesNum)
									{
										var particle = phillyGlowParticles.recycle(PhillyGlowParticle);
										particle.start(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
										phillyGlowParticles.add(particle);
									}
								}
							}
							phillyGlowGradient.bop();
						}
				}

			case 'Kill Henchmen': killHenchmen();

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.settings.get("lowQuality")) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
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
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
					case 'p4' | 'player4' | '3':
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
							killTrailOf(boyfriend);
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							boyfriend.active = true;
							iconP1.changeIcon(boyfriend.iconProperties.name, boyfriend);
							iconP1Poison.changeIcon(boyfriend.iconProperties.name, boyfriend);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);
						reloadHealthBarColors(false);
						recalculateIconAnimations();
						resetTrailOf(boyfriend);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							killTrailOf(dad);
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							dad.active = true;
							iconP2.changeIcon(dad.iconProperties.name, dad);
						}
						setOnLuas('dadName', dad.curCharacter);
						reloadHealthBarColors(false);
						recalculateIconAnimations();
						resetTrailOf(dad);

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
								killTrailOf(gf);
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
								gf.active = true;
							}
							setOnLuas('gfName', gf.curCharacter);
							reloadHealthBarColors(false);
							recalculateIconAnimations();
							resetTrailOf(gf);
						}
					
					case 3:
						if(player4.curCharacter != value2 && player4 != null) {
							if(!player4Map.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = player4.alpha;
							player4.alpha = 0.00001;
							killTrailOf(player4);
							player4 = player4Map.get(value2);
							player4.alpha = lastAlpha;
							player4.active = true;
							if (SONG.notes[curSection].player4Section) {
								if (iconP2 != null && iconP4 != null) {
									iconP4.changeIcon(dad.iconProperties.name, dad);
									iconP2.changeIcon(player4.iconProperties.name, player4);
									reloadHealthBarColors(true);
									recalculateIconAnimations();
								}
							} else {
								if (iconP2 != null && iconP4 != null) {
									iconP2.changeIcon(dad.iconProperties.name, dad);
									iconP4.changeIcon(player4.iconProperties.name, player4);
									reloadHealthBarColors(false);
									recalculateIconAnimations();
								}
							}
						}
						setOnLuas('p4Name', dad.curCharacter);
						reloadHealthBarColors(true);
						resetTrailOf(player4);
				}
				setIconPositions(true);
			
			case 'BG Freaks Expression': if(bgGirls != null) bgGirls.forEach(bgGirl -> bgGirl.swapDanceType());
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant") return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.options.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
					songSpeed = newValue;
				else
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete: twn -> twn = null});

			//appears to be broken, the strums and notes go to the right places (turn on hitboxes) but the strums disappear?
			//if any of you know what in the world could be happening here, please fix it. im utterly lost
			/*case 'Change Modchart':
				var split:Array<String> = value2.split(',');
				switch (split[0].toLowerCase()) {
					case 'bf' | 'boyfriend' | 'player':
						playerModchart.changeModchart(value1);
						playerStrums.forEach(function(spr:FlxSprite)
						{
							if (split[1].toLowerCase() == 'true') {
								FlxTween.tween(spr, {x: spr.ID*spr.width*1.05 + 730, y: strumLine.y}, 0.25 / playbackRate);
							} else {
								spr.x = spr.ID*spr.width*1.05 + 730;
								spr.y = strumLine.y;
							}
							spr.angle = 0;
							spr.scale.set(Note.scales[mania]);
						});
						for(note in notes)
						{
							if(note.mustPress && note.strum != 2)
							{
								note.scale.x = opponentStrums.members[note.noteData].scale.x;
								note.scale.y = opponentStrums.members[note.noteData].scale.y;
							}
						}
					case 'dad' | 'opponent' | 'oppt':
						dadModchart.changeModchart(value1);
						opponentStrums.forEach(function(spr:FlxSprite)
						{
							if (split[1].toLowerCase() == 'true') {
								FlxTween.tween(spr, {x: spr.ID*spr.width*1.05 + 85, y: strumLine.y}, 0.25 / playbackRate);
							} else {
								spr.x = spr.ID*spr.width*1.05 + 85;
								spr.y = strumLine.y;
							}
							spr.angle = 0;
							spr.scale.set(Note.scales[mania]);
						});
						for(note in notes)
						{
							if(!note.mustPress && note.strum != 2)
							{
								note.scale.x = opponentStrums.members[note.noteData].scale.x;
								note.scale.y = opponentStrums.members[note.noteData].scale.y;
							}
						}
					case 'player 4' | 'player4' | 'p4':
						if (!SONG.assets.enablePlayer4) return;
						p4Modchart.changeModchart(value1);
						thirdStrums.forEach(function(spr:FlxSprite)
						{
							if (split[1].toLowerCase() == 'true') {
								FlxTween.tween(spr, {x: player4.x, y: player4.y - 100}, 0.25 / playbackRate);
							} else {
								spr.x = player4.x;
								spr.y = player4.y - 100;
							}
							spr.angle = 0;
							spr.scale.set(Note.scales[mania]);
						});
						for(note in notes)
						{
							if(!note.mustPress && note.strum == 2)
							{
								note.scale.x = opponentStrums.members[note.noteData].scale.x;
								note.scale.y = opponentStrums.members[note.noteData].scale.y;
							}
						}
				}*/

			case 'Stage Tint':
				var split:Array<String> = value2.split(',');
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(split[0]);
				var val3:Int = Std.parseInt(split[1]);
				var tint:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, val3);
				tint.alpha = 0.001;
				tint.scrollFactor.set(0,0);
				tint.screenCenter();
				tint.active = false;
				behindGfGroup.add(tint);
				FlxTween.tween(tint, {alpha: val1}, 0.25 / playbackRate);
				new FlxTimer().start(val2 / playbackRate, function(tmr:FlxTimer) {
					FlxTween.tween(tint, {alpha: 0}, 0.25 / playbackRate, {
						onComplete: _ -> {
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
				tint.active = false;
				addBehindDad(tint);
				FlxTween.tween(tint, {alpha: 0.95}, val1 / playbackRate, {onComplete: _ -> FlxTween.tween(tint, {alpha: 0}, 0.1, {onComplete: _ -> remove(tint, true)})});

			case 'Change Zoom Interval':
				var val1:Null<Int> = Std.parseInt(value1);
				if(Math.isNaN(val1) || val1 < 0) val1 = 4;
				var val2:Null<Int> = Std.parseInt(value2);
				if(Math.isNaN(val2) || val2 < 0) val2 = 0;
				beatZoomingInterval = val1;
				beatHitDelay = val2;

			case 'Swap Hud':
				if (ClientPrefs.settings.get('middleScroll')) return;
				if (!hudIsSwapped) {
					playerStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x - FlxG.width/2}, 0.1 / playbackRate, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x + FlxG.width/2}, 0.1 / playbackRate, {
							ease: FlxEase.circOut
						});
					});
					hudIsSwapped = true;
				} else {
					playerStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x + FlxG.width/2}, 0.1 / playbackRate, {
							ease: FlxEase.circOut
						});
					});
					opponentStrums.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: spr.x - FlxG.width/2}, 0.1 / playbackRate, {
							ease: FlxEase.circOut
						});
					});
					hudIsSwapped = false;
				}

			//i totally didnt need to do this but its here
			case 'Flash Camera':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				if (ClientPrefs.settings.get("flashing")) camGame.flash(val2, val1 / playbackRate, null, true);

			case 'Flash Camera (HUD)':
				var val1:Null<Float> = Std.parseFloat(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				if (ClientPrefs.settings.get("flashing")) camHUD.flash(val2, val1 / playbackRate, null, true);
			
			case 'Set Cam Speed':
				var value:Float = Std.parseFloat(value1);
				if(Math.isNaN(value) || value < 0) value = 1;
				cameraSpeed = value;

			case 'Hide HUD':
				var val1:Null<Float> = Std.parseFloat(value1);
				var alph:Float = 0;
				if (camHUD.alpha < 0.5) alph = 1;
				FlxTween.tween(camHUD, {alpha: alph}, val1, {ease: FlxEase.quadInOut});

			//this will be abused
			case 'Tween Note Direction':
				var val1:Null<Float> = Std.parseFloat(value1);
				var split:Array<String> = value2.split(',');
				var val2:Null<Float> = Std.parseFloat(split[0]);
				if (val1 != null && val2 != null) {
					playerStrums.forEach(function(spr:StrumNote) {
						FlxTween.tween(spr, {direction: val1}, val2 / playbackRate, {
							ease: CoolUtil.easeFromString(split[1])
						});
					});
					opponentStrums.forEach(function(spr:StrumNote) {
						FlxTween.tween(spr, {direction: val1}, val2 / playbackRate, {
							ease: CoolUtil.easeFromString(split[1])
						});
					});
					if (!SONG.assets.enablePlayer4) return;
					thirdStrums.forEach(function(spr:StrumNote) {
						FlxTween.tween(spr, {direction: val1}, val2 / playbackRate, {
							ease: CoolUtil.easeFromString(split[1])
						});
					});
				}

			case 'Tween Hud Angle':
				var val1:Null<Float> = Std.parseFloat(value1);
				var split:Array<String> = value2.split(',');
				var val2:Null<Float> = Std.parseFloat(split[0]);
				var angleTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					angleTween = FlxTween.tween(camHUD, {angle: val1}, val2 / playbackRate, {
						ease: CoolUtil.easeFromString(split[1])
					});
				}
			
			case 'Tween Hud Zoom':
				var val1:Null<Float> = Std.parseFloat(value1);
				var split:Array<String> = value2.split(',');
				var val2:Null<Float> = Std.parseFloat(split[0]);
				var zoomTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					zoomTween = FlxTween.tween(camHUD, {zoom: val1}, val2 / playbackRate, {
						ease: FlxEase.quadInOut,
						onComplete: _ -> defaultHudCamZoom = val1
					});
				}
			
			case 'Tween Camera Angle':
				var val1:Null<Float> = Std.parseFloat(value1);
				var split:Array<String> = value2.split(',');
				var val2:Null<Float> = Std.parseFloat(split[0]);
				var angleTween:FlxTween = null;
				if (val1 != null && val2 != null)
					angleTween = FlxTween.tween(camGame, {angle: val1}, val2 / playbackRate, {ease: CoolUtil.easeFromString(split[1])});
			
			case 'Tween Camera Zoom':
				var val1:Null<Float> = Std.parseFloat(value1);
				var split:Array<String> = value2.split(',');
				var val2:Null<Float> = Std.parseFloat(split[0]);
				var zoomTween:FlxTween = null;
				if (val1 != null && val2 != null) {
					zoomTween = FlxTween.tween(camGame, {zoom: val1}, val2 / playbackRate, {
						ease: CoolUtil.easeFromString(split[1]),
						onComplete: _ -> defaultCamZoom = val1
					});
				}

			case 'Add Subtitle':
				if (!ClientPrefs.settings.get("subtitles")) return;

				var split:Array<String> = value2.split(',');
				var val2:Null<Int> = Std.parseInt(split[0]);
				var funnyColor:FlxColor = FlxColor.WHITE;
				var useIco:Bool = false;
				switch (split[0].toLowerCase()) {
					case 'dadicon' | 'dad' | 'oppt' | 'oppticon' | 'opponent':
						funnyColor = FlxColor.fromRGB(dad.healthColorArray[0].red, dad.healthColorArray[0].green, dad.healthColorArray[0].blue);
						useIco = true;
					case 'bficon' | 'bf' | 'boyfriend' | 'boyfriendicon':
						funnyColor = FlxColor.fromRGB(boyfriend.healthColorArray[0].red, boyfriend.healthColorArray[0].green, boyfriend.healthColorArray[0].blue);
						useIco = true;
					case 'p4icon' | 'p4' | 'player4' | 'player 4' | 'player4icon' | 'player 4icon':
						funnyColor = FlxColor.fromRGB(player4.healthColorArray[0].red, player4.healthColorArray[0].green, player4.healthColorArray[0].blue);
						useIco = true;
					case 'gficon' | 'gf' | 'girlfriend' | 'girlfriendicon':
						funnyColor = FlxColor.fromRGB(gf.healthColorArray[0].red, gf.healthColorArray[0].green, gf.healthColorArray[0].blue);
						useIco = true;
				}
				var val3:Int = Std.parseInt(split[1]);
				if (Math.isNaN(val3) || val3 <= 0) val3 = 1;
				var sub:FlxText = new FlxText(0, ClientPrefs.settings.get("downScroll") ? hud.healthBar.y + 90 : hud.healthBar.y - 90, 0, value1, 32);
				sub.scrollFactor.set();
				sub.cameras = [camHUD];
				sub.setFormat(Paths.font("vcr.ttf"), 32, useIco ? funnyColor : val2, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
				var subBG:FlxSprite = new FlxSprite(0, ClientPrefs.settings.get("downScroll") ? hud.healthBar.y + 90 : hud.healthBar.y - 90).makeGraphic(Std.int(sub.width+10), Std.int(sub.height+10), FlxColor.BLACK);
				subBG.scrollFactor.set();
				subBG.cameras = [camHUD];
				subBG.alpha = 0.5;
				subBG.screenCenter(X);
				sub.screenCenter(X);
				sub.y += 5;
				sub.active = false;
				subBG.active = false;
				add(subBG);
				add(sub);
				new FlxTimer().start(stepsToSecs(val3), function(timer:FlxTimer) {
					FlxTween.tween(sub, {alpha: 0}, stepsToSecs(1), {ease: FlxEase.quadInOut, onComplete: _ -> {
						remove(sub, true);
						sub.destroy();
					}});
					FlxTween.tween(subBG, {alpha: 0}, stepsToSecs(1), {ease: FlxEase.quadInOut, onComplete: _ -> {
						remove(subBG, true);
						subBG.destroy();
					}});
				});
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
		callOnHscripts('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition.x + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition.y + girlfriendCameraOffset[1];
			callOnLuas('onMoveCamera', ['gf']);
			callOnHscripts('onMoveCamera', ['gf']);

			if (SONG.notes[id].mustHitSection) {
				if (iconP1 != null) {
					iconP1.changeIcon(gf.iconProperties.name, gf);
					reloadHealthBarColors(false, true, null, true);
					recalculateIconAnimations();
					setIconPositions(true);
				}
			} else {
				if (iconP2 != null && iconP4 != null && iconP1 != null) {
					iconP1.changeIcon(boyfriend.iconProperties.name, boyfriend);
					iconP2.changeIcon(gf.iconProperties.name, gf);
					iconP4.changeIcon(dad.iconProperties.name, dad);
					reloadHealthBarColors(false, true);
					recalculateIconAnimations();
					setIconPositions(true);
				}
			}
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			if (!SONG.notes[id].player4Section)
			{
				moveCamera(true, false);
				callOnLuas('onMoveCamera', ['dad']);
				callOnHscripts('onMoveCamera', ['dad']);
			} else {
				moveCamera(true, true);
				callOnLuas('onMoveCamera', ['p4']);
				callOnHscripts('onMoveCamera', ['p4']);
			}
		}
		else
		{
			moveCamera(false, false);
			callOnLuas('onMoveCamera', ['boyfriend']);
			callOnHscripts('onMoveCamera', ['boyfriend']);
		}
		//sex icons
		if (iconP2 != null && iconP4 != null && iconP1 != null) {
			iconP1.changeIcon(boyfriend.iconProperties.name, boyfriend);
			iconP2.changeIcon(dad.iconProperties.name, dad);
			iconP4.changeIcon(player4.iconProperties.name, player4);
			reloadHealthBarColors(false);
			recalculateIconAnimations();
			setIconPositions(true);
		}
		if (SONG.notes[id].player4Section) {
			if (iconP2 != null && iconP4 != null && iconP1 != null) {
				iconP1.changeIcon(boyfriend.iconProperties.name, boyfriend);
				iconP4.changeIcon(dad.iconProperties.name, dad);
				iconP2.changeIcon(player4.iconProperties.name, player4);
				reloadHealthBarColors(true);
				recalculateIconAnimations();
				setIconPositions(true);
			}
		}
	}

	public function moveCamera(isDad:Bool, focusP4:Bool)
	{
		if(isDad)
		{
			var char = focusP4 ? player4 : dad;
			var offset = focusP4 ? player4CameraOffset : opponentCameraOffset;
			camFollow.set(char.getMidpoint().x + 150, char.getMidpoint().y - 100);
			camFollow.x += char.cameraPosition.x + offset[0];
			camFollow.y += char.cameraPosition.y + offset[1];
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition.x - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition.y + boyfriendCameraOffset[1];
		}
	}

	public function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
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
		if(ClientPrefs.settings.get("noteOffset") <= 0 || ignoreNoteOffset)
			finishCallback();
		else
			finishTimer = new FlxTimer().start(ClientPrefs.settings.get("noteOffset") / 1000, _ -> finishCallback());
	}

	//End-event Variables
	var rosesEndDialogue:DialogueBox = null;
	var bfCrashSnd:FlxSound = null;

	//End Cutscenes
	function rosesEndCutscene() {
		rosesEndDialogue.onFinishText = function() {
			if (schoolRain != null) schoolRain.visible = false;

			var red = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFff1b31);
			red.scrollFactor.set();
			red.screenCenter();
			red.alpha = 0;
			addBehindDad(red);

			var crashLooper:Int = 1;
			final loopCount:Int = 16; //the max amount of times to loop, in case it needs to be adjusted

			bfCrashSnd = new FlxSound().loadEmbedded(Paths.sound('vanilla/week6/bfText'), true);
			bfCrashSnd.play();

			bfCrashSnd.onComplete = () -> {
				crashLooper++;
				if(crashLooper > loopCount) return; //bug evasion

				if(crashLooper < loopCount) {
					final portraits:Array<String> = ['Heh', 'Normal', 'Shock', 'Smug'];
					for (i in 0...FlxG.random.int(3,5)) {
						var bfPiece:FlxSprite = new FlxSprite(Math.floor(FlxG.random.int(0,1280)*6)/6, Math.floor(FlxG.random.int(0,720)*6)/6);
						bfPiece.loadGraphic(Paths.image('vanilla/week6/weeb/portraits/bf${portraits[FlxG.random.int(0, portraits.length-1)]}'), true, 8, 8);
						bfPiece.animation.add('blah', [FlxG.random.int(0,4) + (8*FlxG.random.int(0,3))]);
						bfPiece.animation.play('blah');
						bfPiece.antialiasing = false;
						bfPiece.setGraphicSize(Std.int(bfPiece.width * 6));
						rosesEndDialogue.add(bfPiece);
					}
					var bfClone:FlxSprite = new FlxSprite(rosesEndDialogue.portraitRight.x + 90, rosesEndDialogue.portraitRight.y + 135);
					bfClone.pixels = rosesEndDialogue.portraitRight.pixels;
					rosesEndDialogue.add(bfClone); //Works because dialoguebox is a spritegroup hee hee
					bfClone.y -= 45 * crashLooper;
					bfClone.antialiasing = false;
					bfClone.setGraphicSize(Std.int(bfClone.width * 6));

					red.alpha = crashLooper / loopCount;
					dad.alpha = boyfriend.alpha = 1 - red.alpha;
					return;
				}

				//after it looped fully
				camOther.fade(0xFFff1b31, 0.15, false, () -> {
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					endSong();
				});
			}

		};
	}

	public var transitioning = false;
	var seenEnd = false;
	public var stopEnding = false;
	public function endSong():Void
	{
		callOnHscripts('onEndSong', []);

		//Should kill you if you tried to cheat
		if(!startingSong) {
			function killCheck(note:Note) {
				if(note.strumTime < songLength - Conductor.safeZoneOffset)
					intendedHealth -= 0.05 * healthLoss;
			}
			notes.forEach(note -> killCheck(note));
			sustains.forEach(sus -> killCheck(sus));
			for (note in unspawnNotes) killCheck(note);

			if(doDeathCheck()) return;
		}
		if(bfCrashSnd != null) {
			bfCrashSnd.stop();
			bfCrashSnd = null;
		}

		camZooming = false;
		updateTime = false;
		canPause = false;
		hud.timeBarBG.visible = false;
		hud.timeBar.visible = false;
		hud.timeTxt.visible = false;
		endingSong = true;

		if(canIUseTheCutsceneMother(true) && !seenEnd) {
			inCutscene = true;
			switch(SONG.header.song.toLowerCase()) {
				case 'roses':
					seenEnd = true;
					camHUD.visible = false;
					if (rainSound != null) rainSound.fadeOut(0.7, 0, function(twn:FlxTween) {
						rainSound.stop();
						rainSound = null;
					});

					rosesEndDialogue = new DialogueBox([":bf:beep bo be"], true, false);
					rosesEndDialogue.scrollFactor.set();
					rosesEndDialogue.canControl = false;
					rosesEndDialogue.cameras = [camOther];
					add(rosesEndDialogue);

					rosesEndCutscene();

					return;
				default:
					//for end cutscenes or smth
					callOnHscripts("onEndCutscene", []);
			}
		}
		
		if (stopEnding) return;
		inCutscene = false;
		seenEnd = false; //making sure

		deathCounter = 0;
		seenCutscene = false;
		hasCutscene = false;
		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (!chartingMode)
			{
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.header.song, songScore, storyDifficulty, percent, ratingName, ratingIntensity);
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			function invalidJSON() {
				trace('Failed to load next story song: incorrect .json!');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				discordUpdateTimer.cancel();
				MusicBeatState.switchState(new StoryMenuState(), 0.35);
				FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
				Conductor.changeBPM(SoundTestState.playingTrackBPM);
				changedDifficulty = false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					WeekData.loadTheFirstEnabledMod();
					FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
					Conductor.changeBPM(SoundTestState.playingTrackBPM);

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					#if desktop
					discordUpdateTimer.cancel();
					#end
					MusicBeatState.switchState(new StoryMenuState());

					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (!chartingMode) Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var curDifficulty:Int = -1;
					var lastDifficultyName:String = CoolUtil.difficulties[storyDifficulty];
					if(lastDifficultyName == '')
					{
						lastDifficultyName = CoolUtil.defaultDifficulty;
					}
					curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

					var songLowercase:String = Paths.formatToSongPath(PlayState.storyPlaylist[0]);
					var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
					function iRanOutOfFunnyNamesForFunctions() {
						var difficulty:String = CoolUtil.getDifficultyFilePath();

						trace('LOADING NEXT SONG');
						trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

						//we use get because just doing prevCamFollow = camFollow fucks it up because camFollow gets put() in destroy().
						//what they dont know is that i fixed this bug less than 24 hours before release -AT
						prevCamFollow = FlxPoint.get(camFollow.x, camFollow.y);
						prevCamFollowPos = camFollowPos;
	
						PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
						skipNextArrowTween = true;
						FlxG.sound.music.stop();
						vocals.stop();
						secondaryVocals.stop();
	
						cancelMusicFadeTween();
						LoadingState.silentLoading = true;
						switch (SONG.header.song.toLowerCase()) { //this is BEFORE loading the song stated!
							case 'roses':
								LoadingState.globeTrans = false;
							case 'thorns':
								LoadingState.globeTrans = false;
								Main.toggleFPS(false);
								Main.toggleMEM(false);
								Main.togglePIE(false);
						}
						customTransition = false;
						LoadingState.loadAndSwitchState(new PlayState());
					}
					#if sys
					if(sys.FileSystem.exists(Paths.modsJson('charts/' + songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.json('charts/' + songLowercase + '/' + poop)))
						iRanOutOfFunnyNamesForFunctions();
					else
						invalidJSON();
					#else
					if(OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop)))
						iRanOutOfFunnyNamesForFunctions();
					else
						invalidJSON();
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
				FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
				Conductor.changeBPM(SoundTestState.playingTrackBPM);
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	public function KillNotes() {
		function killNote(note:Note, grp:Dynamic) {
			grp.remove(note, true);
			note.destroy();
		}
		while(notes.length > 0) {
			killNote(notes.members[0], notes);
		}
		while(sustains.length > 0) {
			killNote(sustains.members[0], sustains);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	public var showRating:Bool = true;

	public function cachePopUpScore()
	{
		final ratingsPath:String = (isPixelStage ? 'pixelUI/' : 'ratings/');
		final numsPath:String = (isPixelStage ? 'pixelUI/' : 'nums/');
		final suffix:String = (isPixelStage ? '-pixel' : '-${ClientPrefs.settings.get("uiSkin").toLowerCase()}');
		final skinOverride:String = (suffix == '-kade' ? '-fnf' : suffix);
	
		Paths.image('${ratingsPath}perfect${suffix}');
		Paths.image('${ratingsPath}sick${suffix}');
		Paths.image('${ratingsPath}good${suffix}');
		Paths.image('${ratingsPath}bad${suffix}');
		Paths.image('${ratingsPath}shit${suffix}');
		Paths.image('${ratingsPath}wtf${suffix}');
		if (SONG.options.crits) Paths.image('${ratingsPath}critBG${suffix}');
		for (i in 0...10) Paths.image('${numsPath}num${i}${skinOverride}');
	}

	public function popUpScore(note:Note = null):String
	{
		final noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.settings.get("ratingOffset"));
		final msTiming:Float = note.strumTime - Conductor.songPosition + ClientPrefs.settings.get("ratingOffset");

		if (SONG.header.needsVoices) secondaryVocals.volume = vocals.volume = SONG.header.vocalsVolume;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff / playbackRate, cpuControlled);
		switch (daRating)
		{
			case "wtf":
				if (sickOnly) health -= 5;
				if (noteDiff > 205)
					totalNotesHit += 0;
				else
					totalNotesHit += (ClientPrefs.settings.get("complexAccuracy") ? -(noteDiff/205 - 1) : 0);

				score = -100;
				wtfs++;
			case "shit":
				if (sickOnly) health -= 5;
				totalNotesHit += (ClientPrefs.settings.get("complexAccuracy") ? -(noteDiff/205 - 1) : 0.25);
				score = -50;
				shits++;
			case "bad":
				if (sickOnly) health -= 5;
				totalNotesHit += (ClientPrefs.settings.get("complexAccuracy") ? -(noteDiff/205 - 1) : 0.5);
				score = 50;
				bads++;
			case "good":
				if (sickOnly) health -= 5;
				totalNotesHit += (ClientPrefs.settings.get("complexAccuracy") ? -(noteDiff/205 - 1) : 0.75);
				score = 200;
				goods++;
			case "sick":
				totalNotesHit += (ClientPrefs.settings.get("complexAccuracy") ? -(noteDiff/205 - 1) : 0.95);
				score = 350;
				sicks++;
			case "perfect":
				totalNotesHit += (ClientPrefs.settings.get("complexAccuracy") ? -(noteDiff/205 - 1) : 1);
				score = 600;
				perfects++;
		}
		note.rating = daRating;

		switch (ratingIntensity) {
			case 'Default':
				if(daRating == 'wtf' || daRating == 'shit') {
					if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) gf.playAnim('sad');
					combo = 0;
					songMisses++;
				}
			case 'Harsh':
				if(daRating == 'wtf' || daRating == 'shit' || daRating == 'bad') {
					if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) gf.playAnim('sad');
					combo = 0;
					songMisses++;
				}
		}


		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			totalPlayed++;
			recalculateRating();
			#if desktop
			ratingText = ratingName + " " + ratingFC;
			#end

			if(ClientPrefs.settings.get("scoreZoom")) hud.scoreTween(daRating);
		}

		final offset = FlxG.width * 0.35;
		final ratingsPath:String = (isPixelStage ? 'pixelUI/' : 'ratings/');
		final numsPath:String = (isPixelStage ? 'pixelUI/' : 'nums/');
		final suffix:String = (isPixelStage ? '-pixel' : '-${ClientPrefs.settings.get("uiSkin").toLowerCase()}');
		final skinOverride:String = (suffix == '-kade' ? '-fnf' : suffix);

		rating.loadGraphic(Paths.image('${ratingsPath}${daRating}${suffix}'));
		rating.cameras = (ClientPrefs.settings.get("wrongCamera") ? [camGame] : [camHUD]);
		rating.screenCenter();
		rating.x = offset - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.settings.get("hideHud") && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];
		if (ClientPrefs.settings.get("wrongCamera")) { 
			rating.y += boyfriend.y;
			rating.x += boyfriend.x;
			rating.y -= isPixelStage ? 400 : 250;
			rating.x -= isPixelStage ? 800 : 600;
			switch(curStage) {
				case 'limo': rating.acceleration.x = 750 * playbackRate * playbackRate;
			}
		}

		insert(members.indexOf(strumLineNotes), rating);
		if (lastRating != null) lastRating.kill();
		lastRating = rating;

		if (!PlayState.isPixelStage)
			rating.setGraphicSize(Std.int(rating.width * 0.7));
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			rating.antialiasing = false;
		}
		rating.updateHitbox();

		if (ClientPrefs.settings.get("msPopup")) {
			msTxt.visible = ClientPrefs.settings.get("hideHud") ? false : true;
			msTxt.text = FlxMath.roundDecimal(-msTiming, 2) + " MS";
			if (msTimer != null) msTimer.cancel();
			msTimer = new FlxTimer().start(0.2 + (Conductor.crochet * 0.0005 / playbackRate), _ -> {
				msTxt.text = '';
				msTxt.visible = false;
			});
			switch (daRating) {
				case 'perfect': msTxt.color = FlxColor.YELLOW;
				case 'sick': msTxt.color = FlxColor.CYAN;
				case 'good': msTxt.color = FlxColor.LIME;
				case 'bad': msTxt.color = FlxColor.ORANGE;
				case 'shit': msTxt.color = FlxColor.RED;
				case 'wtf': msTxt.color = FlxColor.PURPLE;
				default: msTxt.color = FlxColor.WHITE;
			}
		}

		var crit = FlxG.random.bool(1);
		if (daRating == 'perfect') crit = FlxG.random.bool(10);
		if(crit && SONG.options.crits) {
			if(maxHealth < 3) {
				maxHealth += 0.2;
				intendedHealth += 0.2;
				hud.healthBar.x -= 30;
				FlxG.sound.play(Paths.sound('crit'), FlxG.random.float(0.1, 0.2));
			}

			var numBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('${ratingsPath}critBG${suffix}'));
			numBG.cameras = (ClientPrefs.settings.get("wrongCamera") ? [camGame] : [camHUD]);
			numBG.screenCenter();
			numBG.x = offset - 150;
			if (ClientPrefs.settings.get("wrongCamera")) { 
				numBG.y += boyfriend.y;
				numBG.x += boyfriend.x;
				numBG.y -= isPixelStage ? 400 : 250;
				numBG.x -= isPixelStage ? 800 : 600;
				switch(curStage) {
					case 'limo':
						numBG.acceleration.x = 750 * playbackRate * playbackRate;
				}
			}
			numBG.y += 80;
			numBG.x += ClientPrefs.comboOffset[2];
			numBG.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				var floater:Float = 0.6;
				floater += (Math.floor(Math.log(combo) / Math.log(10))) * 0.1;
				numBG.setGraphicSize(Std.int(numBG.width * floater));
			}
			else
			{
				numBG.setGraphicSize(Std.int(numBG.width * daPixelZoom));
				numBG.antialiasing = false;
			}
			numBG.updateHitbox();
			
			numBG.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numBG.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numBG.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numBG.visible = !ClientPrefs.settings.get("hideHud");

			insert(members.indexOf(strumLineNotes), numBG);
			if (lastNumbg != null) lastNumbg.kill();
			lastNumbg = numBG;
			
			FlxTween.tween(numBG, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: _ -> {
					remove(numBG, true);
					numBG.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}

		//atpx being clever
		final seperatedScore:Array<Int> = Std.string(combo).split("").map(str -> Std.parseInt(str));
		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}

		for (daLoop=>i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('${numsPath}num${i}${skinOverride}'));
			numScore.cameras = (ClientPrefs.settings.get("wrongCamera") ? [camGame] : [camHUD]);
			numScore.screenCenter();
			numScore.x = offset + (43 * daLoop); //need this bc i is the actual number
			if (combo < 10) numScore.x += 13;
			if (combo >= 10) numScore.x += 22;
			numScore.x -= (seperatedScore.length - 2) * 22;
			if (ClientPrefs.settings.get("wrongCamera")) { 
				numScore.y += boyfriend.y;
				numScore.x += boyfriend.x;
				numScore.y -= isPixelStage ? 400 : 250;
				numScore.x -= isPixelStage ? 800 : 600;
				switch(curStage) {
					case 'limo': numScore.acceleration.x = 750 * playbackRate * playbackRate;
				}
			}
			numScore.y += 40;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];
			lastScore.push(numScore);

			if (!PlayState.isPixelStage)
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom * 0.85));
				numScore.antialiasing = false;
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.settings.get("hideHud");

			insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: _ -> {
					remove(numScore, true);
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.002 / playbackRate,
			onComplete: _ -> {
				remove(rating, true);
				rating.destroy();
			}
		});

		return daRating;
	}

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if (key == -1 || cpuControlled || paused) return;

		if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
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
				function noteCheck(note:Note) {
					if (note.canBeHit && !note.tooLate && !note.wasGoodHit)
					{
						if(note.noteData == key) sortedNotesList.push(note);
						if (ratingIntensity == 'Harsh') canMiss = true;
					}
				}
				notes.forEachAlive(note -> noteCheck(note));
				sustains.forEachAlive(sus -> noteCheck(sus));
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								if (doubleNote.isSustainNote)
									sustains.remove(doubleNote, true);
								else
									notes.remove(doubleNote, true);

								doubleNote.destroy();
							} 
							else
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
					callOnHscripts('noteMissPress', [key]);
				}
				else if (!canMiss)
					gsTap(key, ClientPrefs.settings.get("gsMiss") ? true : false);

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
			callOnHscripts('onKeyPress', [key]);
		}
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
		callOnHscripts('onKeyRelease', [key]);
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
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			sustains.forEachAlive(function(daNote:Note)
			{
				if (dataKeyIsPressed(daNote.noteData % Note.ammo[mania]) && daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit)
					goodNoteHit(daNote);
			});

			if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}
	}

	public function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		function noteKillCheck(note:Note, grp:Dynamic) {
			if (note != note && note.mustPress && note.noteData == note.noteData && Math.abs(note.strumTime - note.strumTime) < 1) {
				grp.remove(note, true);
				note.destroy();
			}
		}
		notes.forEachAlive(note -> noteKillCheck(note, notes));
		sustains.forEachAlive(sus -> noteKillCheck(sus, sustains));

		var sustainMisser:Bool = false;
		switch (ratingIntensity){
			case 'Default':
				sustainMisser = FlxG.random.bool(50);
			case 'Generous':
				sustainMisser = false;
			case 'Harsh':
				sustainMisser = true;
		}
		if (daNote.isSustainNote && !sustainMisser) return;

		if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) gf.playAnim('sad');
		combo = 0;
	
		if(ClientPrefs.settings.get("flinching")) {
			var time:Float = 0.5;
			flinching = true;
			recalculateIconAnimations();
			if (flinchTimer != null) flinchTimer.cancel();
			if (poison) time = 3;
			flinchTimer = new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				flinching = false;
				recalculateIconAnimations();	
			});
		}
			
		if (SONG.options.dangerMiss) maxHealth -= 0.10;
		intendedHealth -= daNote.missHealth * healthLoss;
		if (poison) poisonRoutine();
		if(instakillOnMiss || sickOnly)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}
		if(freeze) freezeRoutine();
		songMisses++;
		vocals.volume = 0;
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		if(!practiceMode) songScore -= 10;
			
		totalPlayed++;
		recalculateRating();
		#if desktop
		ratingText = ratingName + " " + ratingFC;
		#end
		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		callOnHscripts('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	
		var char:Character = (daNote.gfNote ? gf : boyfriend);
	
		if(char != null)
		{
			if (freeze && char.stunned) return;
			final missStr:String = char.hasMissAnimations ? 'miss' : '';
			if (!char.hasMissAnimations)
				char.missing = true;

			final daAlt = (daNote.noteType == 'Alt Animation' ? '-alt' : '');
			final animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[daNote.noteData] + missStr + daAlt;
			final noAnimation:String = 'singUP' + missStr + daAlt;
			if (char.animOffsets.exists(animToPlay)) {
				char.playAnim(animToPlay, true);
			} else {
				char.playAnim(noAnimation, true);
			}
		}
	}

	public function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (boyfriend.stunned || tappy) return;

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

		if(ClientPrefs.settings.get("flinching")) {
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
		recalculateRating();
		#if desktop
		ratingText = ratingName + " " + ratingFC;
		#end
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		var missStr:String = boyfriend.hasMissAnimations ? 'miss' : '';
		if (!boyfriend.hasMissAnimations)
			boyfriend.missing = true;
		boyfriend.playAnim('sing' + Note.keysShit.get(mania).get('anims')[direction] + missStr, true);

		vocals.volume = 0;
	}

	inline function gsTap(direction:Int = 1, ?miss:Bool = false):Void //GS Tap Miss
	{
		var missStr:String = miss ? 'miss' : '';
		var char = ((SONG.notes[curSection].gfSection && SONG.notes[curSection].mustHitSection && gf != null) ? gf : boyfriend);
		if ((freeze && char.stunned) || char.specialAnim) return;

		if(ClientPrefs.settings.get("flinching") && miss) {
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

		if (!char.hasMissAnimations) {
			char.missing = miss;
			missStr = '';
		}

		var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[direction] + missStr;
		var noAnimation:String = 'singUP' + missStr;
		if (char.animOffsets.exists(animToPlay)) {
			char.playAnim(animToPlay, true);
		} else {
			char.playAnim(noAnimation, true);
		}
	}

	public function opponentNoteHit(note:Note, ?p4:Bool = false):Void
	{
		if (Paths.formatToSongPath(SONG.header.song) != 'tutorial') camZooming = true;

		var char:Character = dad;
		var cfgrp:FlxTypedGroup<CrossFade> = grpCrossFade;
		if (p4) {
            switch (note.strum) {
                case 2: 
			    	char = player4;
			    	cfgrp = grpP4CrossFade;
            }
		} 
		if(note.gfNote)
			char = gf;

		if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
			char.playAnim('hey', true);
			char.specialAnim = true;
			char.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			if (SONG.notes[curSection] != null)
			{
				if ((SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') && !SONG.notes[curSection].gfSection) altAnim = '-alt';
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
				if (ClientPrefs.settings.get("camPans")) camPanRoutine(animToPlay, (char == dad ? 'oppt' : 'p4'));
			}

			function makeCrossFade(_char:Character, _grp:FlxTypedGroup<CrossFade>, ?noteTypeThing:Bool = false) {
				if (ClientPrefs.settings.get("crossFadeMode") == 'Off' || note.isSustainNote || noteTypeThing) return;
				var crossfade = _grp.recycle(CrossFade);
				crossfade.resetShit(_char, true);
				_grp.add(crossfade);
			}

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].crossFade) {
					var charstore = char;
					if (SONG.notes[curSection].gfSection && !SONG.notes[curSection].player4Section) {
						char = gf;
						cfgrp = gfCrossFade;
					}
					makeCrossFade(char, cfgrp);
					char = charstore;
				} else {
					makeCrossFade(char, cfgrp, !note.noteType.contains("Cross Fade"));
				}
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
			if (char.drainFloor <= 0) {
				intendedHealth -= char.drainAmount;
			} else {
				if (intendedHealth >= char.drainFloor)
					intendedHealth -= char.drainAmount;
			}
				
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
		if(note.isSustainNote && note.animation.curAnim != null && !note.animation.curAnim.name.endsWith('tail')) time += 0.15;

		strumPlayAnim(p4 ? note.strum : 0, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);

		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, char.curCharacter]);
		callOnHscripts('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, char.curCharacter]);

		if (!note.isSustainNote)
		{
			notes.remove(note, true);
			note.destroy();
		}
	}

	public function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit || (cpuControlled && (note.ignoreNote || note.hitCausesMiss))) return;

		if (ClientPrefs.settings.get("scoreDisplay") == 'Kade') {
			if (!note.isSustainNote) npsArray.unshift(Date.now());
		}

		if (ClientPrefs.settings.get("hitsoundVolume") > 0 && !note.isSustainNote)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.settings.get("hitsoundVolume"));

		if(boyfriend.shakeScreen && !note.isSustainNote) {
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
				notes.remove(note, true);
				note.destroy();
			}
			return;
		}

		var rate:String = 'sick';
		if (!note.isSustainNote && !note.ratingDisabled)
		{
			combo += 1;
			if(highestCombo < combo) highestCombo = combo;
			rate = popUpScore(note);
		}

		if (!note.isSustainNote && !note.noteSplashDisabled && (['sick', 'perfect'].contains(rate) || note.forceNoteSplash))
			spawnNoteSplashOnNote(note);

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
			var animToPlay:String = 'sing' + Note.keysShit.get(mania).get('anims')[note.noteData];
			var noAnimation:String = 'singUP';
			var char = (note.gfNote && gf != null) ? gf : boyfriend;

			if (ClientPrefs.settings.get("camPans")) 
				camPanRoutine(animToPlay, 'bf');

			final daAlt = (note.noteType == 'Alt Animation' ? '-alt' : '');

			if (char.missing) {
				char.missing = false;
				char.color = 0xffffffff;
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

			function makeCrossFade(?_gf:Bool = false, ?noteTypeThing:Bool = false) {
				if (ClientPrefs.settings.get("crossFadeMode") == 'Off' || note.isSustainNote || noteTypeThing) return;
				switch (_gf) {
					case true:
						var crossfade = gfCrossFade.recycle(CrossFade);
						crossfade.resetShit(gf, true);
						gfCrossFade.add(crossfade);
					default:
						var crossfade = grpBFCrossFade.recycle(CrossFade);
						crossfade.resetShit(boyfriend, false);
						grpBFCrossFade.add(crossfade);
				}
			}

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].crossFade) {
					makeCrossFade(SONG.notes[curSection].gfSection);
				} else {
					makeCrossFade(note.noteType.contains("GF"), !note.noteType.contains("Cross Fade"));
				}
			}
		}

		if(cpuControlled)
		{
			var time:Float = 0.15;
			if(note.isSustainNote && !note.animation.curAnim.name.endsWith('tail')) time += 0.15;

			strumPlayAnim(1, Std.int(Math.abs(note.noteData)) % Note.ammo[mania], time);
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
		callOnHscripts('goodNoteHit', [notes.members.indexOf(note), Math.round(Math.abs(note.noteData)), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			notes.remove(note, true);
			note.destroy();
		}
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.settings.get("noteSplashes") && note != null) {
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
		remove(fastCar);
		insert((FlxG.random.bool(50) ? members.indexOf(boyfriendGroup) + 1 : members.indexOf(gfGroup) - 1), fastCar);
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	inline public function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('vanilla/week4/carPass', 0, 1), 0.7);

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
		var billBoardWho:String = '';
		switch(FlxG.random.int(0,2)) {
			case 0:
				billBoardWho = 'vanilla/week4/limo/fastMomLol';
			case 1:
				billBoardWho = 'vanilla/week4/limo/fastBfLol';
			case 2:
				billBoardWho = 'vanilla/week4/limo/fastPicoLol';
		}
		billBoard.loadGraphic(Paths.image(billBoardWho));
	}

	var billTimer:FlxTimer;
	inline public function billBoardBill()
	{
		FlxG.sound.play(Paths.soundRandom('vanilla/week4/carPass', 0, 1), 0.7);

		billBoard.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		billBoardCanBill = false;
		billTimer = new FlxTimer().start(FlxG.random.int(4,8), function(tmr:FlxTimer)
		{
			resetBillBoard();
			billTimer = null;
		});
	}

	inline public function killHenchmen():Void
	{
		if (ClientPrefs.settings.get("lowQuality") || curStage != 'limo' || limoKillingState >= 1) return;
		limoMetalPole.x = -400;
		limoMetalPole.visible = true;
		limoLight.visible = true;
		limoCorpse.visible = false;
		limoCorpseTwo.visible = false;
		limoKillingState = 1;
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

	public function rosesLightningStrike():Void
	{
		FlxG.sound.play(Paths.soundRandom('vanilla/week6/thunder_', 1, 2), FlxG.random.float(0.25,0.35));
		if(!ClientPrefs.settings.get("lowQuality")) {
			var fuck:Int = FlxG.random.int(0,2);
			for (rosesLightning in rosesLightningGrp) {
				if (rosesLightning.ID == fuck) {
					rosesLightning.visible = true;
					rosesLightning.alpha = 0.7;
					FlxTween.tween(rosesLightning, {alpha: 1}, 0.075 / playbackRate);
					FlxTween.tween(rosesLightning, {alpha: 0.001}, 0.75 / playbackRate, {startDelay: 0.15 / playbackRate, onComplete: _ -> rosesLightning.visible = false});
				}
			}
			for (schoolClouds in schoolCloudsGrp) {
				if (schoolClouds.ID == fuck) {
					schoolClouds.color = 0xffffffff;
					FlxTween.color(schoolClouds, 0.95 / playbackRate, schoolClouds.color, 0xffdadada, {startDelay: 0.15 / playbackRate});
				} else {
					schoolClouds.color = 0xffebebeb;
					FlxTween.color(schoolClouds, 0.95 / playbackRate, schoolClouds.color, 0xffdadada, {startDelay: 0.15 / playbackRate});
				}
			}
		}

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(ClientPrefs.settings.get("camZooms")) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) {
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5 / playbackRate);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5 / playbackRate);
			}
		}

		if(ClientPrefs.settings.get("flashing")) {
			halloweenWhite.visible = true;
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075 / playbackRate);
			FlxTween.tween(halloweenWhite, {alpha: 0.001}, 0.25 / playbackRate, {startDelay: 0.15 / playbackRate, onComplete: _ -> halloweenWhite.visible = false});
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0):Void
	{
		if(!inCutscene)
		{
			tankAngle += elapsed * tankSpeed * playbackRate;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	private var preventLuaRemove:Bool = false;
	override public function destroy() {
		#if cpp
		cpp.vm.Gc.enable(true);
		#end

		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];
		#if HSCRIPT_ALLOWED
		for (hscript in hscripts) {
			hscript.call('onDestroy', []);
			hscript.stop();
		}
		hscripts = [];
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		camFollow.put();

		TankmenBG.animationNotes = null;

		super.destroy();
		instance = null;
		Paths.clearStoredCache(true);
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
					case 736:
						if (canIUseTheCutsceneMother(true)) FlxTween.tween(camTint, {alpha: 0.6}, stepsToSecs(200), {ease: FlxEase.expoIn});
					case 937:
						eggnogEndCutscene();
				}
			case 'guns':
				switch (curStep) {
					case 896:
						//anyone reading this thinking im mentally insane:
						var moveVals:Array<Float> = [40];
						for (i in 0...(mania*2)+1) moveVals.push(40);
						function tweenNote(note:StrumNote, delay:Float, id:Int) {
							gunsNoteTweens[id] = FlxTween.tween(note, {y: strumLine.y + moveVals[id]}, 2 / playbackRate, {
								ease: FlxEase.sineInOut,
								startDelay: delay,
								onComplete: _ -> {
									moveVals[id] /= -1; //turn around the value automatically
									tweenNote(note, 0, id);
								}
							});
						}
						var i = 0;
						opponentStrums.forEach(note -> {
							gunsNoteTweens.push(null);
							tweenNote(note, (0.12*i) / playbackRate, i);
							i++;
						});
						playerStrums.forEach(note -> {
							gunsNoteTweens.push(null);
							tweenNote(note, (0.12*i) / playbackRate, i);
							i++;
						});
						gunsThing.visible = true;
						gunsExtraClouds.visible = true;
						FlxTween.tween(dad, {y: dad.y - 50}, 0.35 / playbackRate, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> tankmanRainbow = true
						});
						cameraSpeed = 2;
						FlxTween.tween(camGame, {zoom: 1.05}, 0.35 / playbackRate, {
							ease: FlxEase.circInOut,
							onComplete: _ -> defaultCamZoom = 1.05
						});
						FlxTween.tween(gunsThing, {alpha: 0.75}, 0.2 / playbackRate, {ease: FlxEase.quadInOut});
						FlxTween.tween(gunsExtraClouds, {alpha: 1}, 0.35 / playbackRate, {ease: FlxEase.quadInOut});
						foregroundSprites.forEach(spr -> FlxTween.tween(spr, {alpha: 0}, 0.35 / playbackRate, {ease: FlxEase.quadInOut}));
						for (object in stageGraphicArray) if (object != null) FlxTween.tween(object, {y: object.y + 820}, 0.35 / playbackRate, {ease: FlxEase.expoInOut});
						if (gf != null) FlxTween.tween(gf, {y: gf.y + 840}, 0.35 / playbackRate, {ease: FlxEase.expoInOut});
						FlxTween.tween(tankGround, {alpha: 0}, 0.35 / playbackRate, {ease: FlxEase.quadInOut});
					case 1024:
						boyfriend.colorSwap = new ColorSwap();
						boyfriend.shader = boyfriend.colorSwap.shader;
						iconP1.shader = boyfriend.colorSwap.shader;
						hud.healthBar.shader = boyfriend.colorSwap.shader;
						FlxTween.tween(camGame, {zoom: defaultStageZoom + 0.5}, stepsToSecs(128), {ease: FlxEase.quadInOut});
						FlxTween.tween(boyfriend.colorSwap, {hue: 0.9}, stepsToSecs(128), {ease: FlxEase.quadInOut});
					case 1152:
						for (tween in gunsNoteTweens) {
							if (tween != null) {
								tween.cancel();
								tween = null;
							}
						}
						FlxTween.tween(boyfriend.colorSwap, {hue: 1}, 0.4 / playbackRate, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								hud.healthBar.shader = null;
								iconP1.shader = null;
								boyfriend.shader = null;
								boyfriend.colorSwap = null;
							}
						});
						opponentStrums.forEach(note -> FlxTween.tween(note, {y: strumLine.y}, 0.4 / playbackRate, {ease: FlxEase.sineInOut}));
						playerStrums.forEach(note -> FlxTween.tween(note, {y: strumLine.y}, 0.4 / playbackRate, {ease: FlxEase.sineInOut}));
						tankmanRainbow = false;
						cameraSpeed = 1;
						if (gunsTween != null) gunsTween.cancel();
						gunsTween = null;
						FlxTween.tween(camGame, {zoom: 0.9}, 0.35 / playbackRate, {
							ease: FlxEase.circInOut,
							onComplete: _ -> defaultCamZoom = 0.9
						});
						FlxTween.tween(gunsThing, {alpha: 0}, 0.2 / playbackRate, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								remove(gunsThing, true);
								gunsThing.destroy();
							}
						});
						FlxTween.tween(gunsExtraClouds, {alpha: 0}, 0.35 / playbackRate, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								remove(gunsExtraClouds, true);
								gunsExtraClouds.destroy();
							}
						});
						foregroundSprites.forEach(spr -> FlxTween.tween(spr, {alpha: 1}, 0.35 / playbackRate, {ease: FlxEase.quadInOut}));
						FlxTween.tween(dad, {y: 340}, 0.3 / playbackRate, {ease: FlxEase.circInOut});
						for (object in stageGraphicArray) if (object != null) FlxTween.tween(object, {y: object.y - 820}, 0.35 / playbackRate, {ease: FlxEase.expoInOut});
						if (gf != null) FlxTween.tween(gf, {y: gf.y - 840}, 0.35 / playbackRate, {ease: FlxEase.expoInOut});
						FlxTween.tween(tankGround, {alpha: 1}, 0.35 / playbackRate, {ease: FlxEase.quadInOut});
				}
			case 'stress':
				switch (curStep) {
					case 736:
						opponentStrums.forEach(spr -> FlxTween.tween(spr, {alpha: 0}, 0.5/playbackRate, {ease: FlxEase.quadInOut, startDelay: 0.5}));
					case 765:
						opponentStrums.forEach(spr -> FlxTween.tween(spr, {alpha: 1}, 0.2/playbackRate, {ease: FlxEase.quadInOut}));
				}
			case 'thorns':
				switch (curStep) {
					//shits wacky yo
					case 48:
						playerStrums.forEach(spr -> {
							spr.alpha = 0;
							spr.x -= 1000;
						});
						new FlxTimer().start(stepsToSecs(2), function(tmr:FlxTimer) {
							if (boyfriend.alpha < 1) {
								boyfriend.alpha += 0.125;
								dad.alpha -= 0.125;
								playerStrums.forEach(spr -> spr.alpha += 0.125);
								opponentStrums.forEach(spr -> spr.alpha -= 0.125);
								tmr.reset(stepsToSecs(2));
							}
						});
					case 128:
						if (!ClientPrefs.settings.get("lowQuality")) {
							schoolWavy.animation.curAnim.frameRate += 24;
							schoolWavy.visible = true;
						}
						dad.alpha = 1;
						gf.alpha = 1;
						opponentStrums.forEach(spr -> spr.alpha = 1);
						hud.y = 0;
						setIconPositions(true);
					case 256 | 639:
						if (!ClientPrefs.settings.get("lowQuality")) schoolWavy.animation.curAnim.frameRate -= 24;
					case 384 | 767:
						if (!ClientPrefs.settings.get("lowQuality")) schoolWavy.animation.curAnim.frameRate += 12;
					case 512 | 895:
						if (!ClientPrefs.settings.get("lowQuality")) schoolWavy.animation.curAnim.frameRate += 6;
					case 1023:
						camGame.flash(FlxColor.BLACK, 1, null, true);
						if (!ClientPrefs.settings.get("lowQuality")) {
							schoolWavy.animation.curAnim.reverse();
							schoolWavy.animation.curAnim.frameRate = 48;
						}
					case 1151:
						camGame.flash(FlxColor.BLACK, 1, null, true);
						if (!ClientPrefs.settings.get("lowQuality")) {
							schoolWavy.animation.curAnim.reverse();
							schoolWavy.animation.curAnim.frameRate = 24;
						}
					case 1279:
						if (!ClientPrefs.settings.get("lowQuality")) {
							schoolWavy.animation.curAnim.frameRate = 0;
							schoolWavy.animation.curAnim.finish();
						}
					case 1311:
						thornsEndCutscene();
				}
			case 'senpai':
				//Often used functions
				function tweenZoom(newZoom:Float = 1.05, time:Float = 0, ease_:Null<flixel.tweens.EaseFunction> = null) {
					if(ease_ == null) ease_ = FlxEase.linear;
					FlxTween.tween(this, {defaultCamZoom: newZoom}, time, {ease: ease_});
				}

				function tweenLoveTint(alpha_:Float = 0.2, time:Float = 0, ease_:Null<flixel.tweens.EaseFunction> = null) {
					if(ease_ == null) ease_ = FlxEase.linear;
					FlxTween.tween(tintMap['senpai-love'], {alpha: alpha_}, time, {ease: ease_});
				}

				function setLoveGradient(alpha_:Float, time:Float, active:Bool = true) {
					if(ClientPrefs.settings.get("lowQuality")) return;

					for (loveGradient in senpaiLoveGrp) { //using the poisonSprites because they work!!
						loveGradient.visible = active;
						if (active) FlxTween.tween(loveGradient, {alpha: alpha_}, time);
					}
				}

				//Actual events
				switch (curStep) { //a lot of colouring and zooming because it just fits, sob over it
					case 118:
						setBeatZooms(4, 0);
					case 128:
						setBeatZooms(2, 1);
						tweenZoom(defaultStageZoom + 0.255, stepsToSecs(6), FlxEase.quadInOut);

						tintMap['senpai-love'].visible = true;
						tweenLoveTint(0.15, stepsToSecs(6), FlxEase.quadInOut);
					case 256:
						setBeatZooms(1, 0);
						tweenZoom(defaultStageZoom + 0.05, stepsToSecs(8), FlxEase.quadOut);
						tweenLoveTint(0.2, stepsToSecs(8));
					case 320:
						tweenZoom(defaultStageZoom + 0.15, stepsToSecs(8), FlxEase.quadOut);
						tweenLoveTint(0.125, stepsToSecs(4));
					case 384:
						tweenZoom(defaultStageZoom + 0.215, stepsToSecs(12), FlxEase.quadOut);
						tweenLoveTint(0.325, stepsToSecs(12));

						setBeatZooms(2, 1);
						setBeatDrain(2);

						setLoveGradient(0.3, stepsToSecs(16));
					case 448:
						tweenZoom(defaultStageZoom + 0.175, stepsToSecs(6), FlxEase.quadOut);
						setLoveGradient(0.2, stepsToSecs(8));
					case 512:
						if(ClientPrefs.settings.get("flashing")) camGame.flash(FlxColor.WHITE, 1, null, true);
						setBeatDrain(0);
						intendedHealth -= 0.3;

						setBeatZooms(1, 0);

						tweenZoom(defaultStageZoom + 0.07, stepsToSecs(6), FlxEase.quadOut);
						tweenLoveTint(0.05, stepsToSecs(8));
						setLoveGradient(0, stepsToSecs(6));
					case 576:
						tweenZoom(defaultStageZoom - 0.03, stepsToSecs(8), FlxEase.quadOut);
						tweenLoveTint(0.125, stepsToSecs(8));
					case 640:
						tweenZoom(defaultStageZoom + 0.1, stepsToSecs(8), FlxEase.quadOut);
						setBeatZooms(2, 1);
						tweenLoveTint(0.2, stepsToSecs(8));
						setLoveGradient(0.18, stepsToSecs(8));
					case 768:
						tweenZoom(defaultStageZoom + 0.2, stepsToSecs(8), FlxEase.quadOut);
						tweenLoveTint(0.15, stepsToSecs(8));

						setLoveGradient(0.12, stepsToSecs(8));
						setBeatDrain(2, 0.125);
					case 896:
						tweenZoom(defaultStageZoom, stepsToSecs(4), FlxEase.circOut);
						setBeatDrain(0, 0.1);
						tweenLoveTint(0.08, stepsToSecs(4), FlxEase.circOut);
						setLoveGradient(0.06, stepsToSecs(6));
						new FlxTimer().start(stepsToSecs(4), function(_:FlxTimer) {
							camHUD.alpha -= 0.25;
							if(camHUD.alpha < 0.25) {
								dad.stunned = true; //makes him not play animation anymore hee hee
								dad.animation.curAnim.finish();
							}
						}, 4);
					case 916:
						moveCamera(false, false);
						tweenZoom(defaultStageZoom + 0.325, stepsToSecs(10), FlxEase.quadOut);

						tweenLoveTint(0.12, stepsToSecs(6), FlxEase.circOut);
						setLoveGradient(0.3, stepsToSecs(6));

						bgGirls.forEach(bgGirl -> bgGirl.stopDancing = true);
						if(dad != null && dad.animOffsets.exists('pose')) {
							dad.stunned = false;
							dad.playAnim('pose', true); //he pissed now
							dad.specialAnim = true;
							dad.heyTimer = 5;
						}
						new FlxTimer().start(stepsToSecs(1) / 2, function(_:FlxTimer) {
							if(boyfriend != null && boyfriend.animOffsets.exists('hey')) {
								boyfriend.playAnim('hey', true); //gonna piss off that lil pissbaby real good :smug:
								boyfriend.specialAnim = true;
								boyfriend.heyTimer = 5;
							}
							if(gf != null && gf.animOffsets.exists('cheer')) {
								gf.playAnim('cheer', true); //cant forget gf :grimp:
								gf.specialAnim = true;
								gf.heyTimer = 5;
							}
						});
					case 924:
						if (isStoryMode) { //only do this on story mode because it doesnt make sense on freeplay 
							flixel.addons.transition.FlxTransitionableState.skipNextTransIn = true; //faster (you dont see it anyways)
							var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width*2, FlxG.height*2, FlxColor.BLACK);
							blackScreen.alpha = 0;
							add(blackScreen);
							blackScreen.scrollFactor.set();
							blackScreen.screenCenter();
	
							new FlxTimer().start(stepsToSecs(2), _ -> blackScreen.alpha += 0.25, 4);
						}
				}
			case 'roses':
				switch (curStep) {
					case 416:
						FlxTween.tween(tintMap['roses'], {alpha: 0.3}, ((Conductor.stepCrochet / 1000) * 16) / playbackRate);
					case 444:
						schoolRain = new FlxSprite(0, 0);
						schoolRain.frames = Paths.getSparrowAtlas('vanilla/week6/weeb/rain');
						schoolRain.animation.addByPrefix("idle", "rain", 24, true);
						schoolRain.animation.play("idle");

						schoolRain.scale.set(6,6);
						schoolRain.updateHitbox();
						schoolRain.screenCenter();
						schoolRain.alpha = 0.95;
						schoolRain.x += 115;
						schoolRain.y += 130;
						schoolRain.scrollFactor.set(0.7, 0.9);
						schoolRain.antialiasing = false;
						add(schoolRain);

						rainSound = new FlxSound().loadEmbedded(Paths.sound('rainSnd'));
						FlxG.sound.list.add(rainSound);
						rainSound.volume = 0;
						rainSound.looped = true;
						rainSound.play();
						rainSound.fadeIn(((Conductor.stepCrochet / 1000) * 4) / playbackRate, 0, 0.3);

						tintMap.set('roses-red', addATint(0.175, FlxColor.fromRGB(128,0,0)));
						
						rosesLightningStrike();
						if(ClientPrefs.settings.get("flashing"))FlxG.camera.flash(FlxColor.WHITE, ((Conductor.stepCrochet / 1000) * 4) / playbackRate);
					case 704:
						FlxTween.tween(this, {defaultCamZoom: defaultCamZoom-0.08}, 0.25 / playbackRate, {ease: FlxEase.quadInOut});
				}
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
		callOnHscripts('onStepHit', [curStep]);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var lastBeatHit:Int = -1;
	var gunsColorIncrementor:Int = 0;
	public var beatZoomingInterval:Int = 4; //The amount of beats between the next zoom
	public var beatHitDelay:Int = 0; //The delay which if set to half of beatZooming Interval can be used for inbetween zooms, example:
	//(x represents zoom on hit, o represents no zoom: x o x o [normal pattern], o x o x [beatDelay 1, interval 2 pattern])

	inline function setBeatZooms(interval:Int = 4, delay:Int = 0) {
		beatZoomingInterval = interval;
		beatHitDelay = delay;
	}

	var beatDrainInterval:Int = 0;
	var beatDrainDecrease:Float = 0.1;
	var beatDrainFloor:Float = 0;
	function setBeatDrain(interval:Int, healthDecrease:Float = 0.1, drainFloor:Float = 0) {
		beatDrainInterval = interval;
		beatDrainDecrease = healthDecrease;
		beatDrainFloor = drainFloor;
	}

	override public function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) return;

		if (curBeat % 4 == 0) curSection++;

		//if behind to prevent desync
		if (curSection < Math.floor(curStep/16))
			curSection = Math.floor(curStep/16);

		//if ahead for ditto
		if (curSection > Math.ceil(curStep/16))
			curSection = Math.floor(curStep/16);

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.settings.get("downScroll") ? FlxSort.ASCENDING : FlxSort.DESCENDING);
			sustains.sort(FlxSort.byY, ClientPrefs.settings.get("downScroll") ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[curSection] != null)
		{
			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
			setOnLuas('player4Section', SONG.notes[curSection].player4Section);
		}

		if(beatDrainInterval > 0 && curBeat % beatDrainInterval == beatHitDelay && intendedHealth > beatDrainFloor) intendedHealth -= beatDrainDecrease; //for senpai charm mainly

		if (generatedMusic && PlayState.SONG.notes[curSection] != null && !endingSong && !isCameraOnForcedPos && curBeat % 4 == 0)
		{
			moveCameraSection(curSection);
		}
		if (beatZoomingInterval > 0) {
			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.settings.get("camZooms") && curBeat % beatZoomingInterval == beatHitDelay)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}
		}

		if (SONG.options.beatDrain) if (intendedHealth > 0.10) intendedHealth -= 0.0475 * 0.5;
		
		var iconsArray:Array<HealthIcon> = [iconP1, iconP1Poison, iconP2, iconP4]; //not making this final for a good reason
		final curInfo:HealthIcon.BopInfo = {curBeat: curBeat, playbackRate: playbackRate, gfSpeed: gfSpeed, healthBarPercent: hud.healthBar.percent};
		for(i in 0...iconsArray.length) {
			if(!iconsArray[i].visible) continue;
			iconsArray[i].bop(curInfo, "ClientPrefs", Std.int(FlxMath.bound(i - 1, 0, 2)));
		}

		//geez this is horrible! ill fix it later perhaps
		if (gf != null && gf.animation.curAnim != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}
		for (char in [boyfriend, dad, player4]) {
			if (curBeat % char.danceEveryNumBeats == 0 && char.animation.curAnim != null && !char.animation.curAnim.name.startsWith('sing') && !char.stunned)
				char.dance();
		}

		switch (curStage)
		{
			case 'tank':
				if(!ClientPrefs.settings.get("lowQuality")) tankWatchtower.dance();
				foregroundSprites.forEach(spr -> spr.dance());
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
			case 'school': if(!ClientPrefs.settings.get("lowQuality")) bgGirls.forEach(bgGirl -> bgGirl.dance());
			case 'mall':
				if(!ClientPrefs.settings.get("lowQuality")){
					for (bopper in upperBoppers) bopper.dance(true);
					for (i in 0...5) snowEmitter.emitParticle();
				} 
				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);
			case 'limo':
				if(!ClientPrefs.settings.get("lowQuality")) grpLimoDancers.forEach(dancer -> dancer.dance());
				if (FlxG.random.bool(10) && fastCarCanDrive) fastCarDrive();
				if (FlxG.random.bool(5) && billBoardCanBill) billBoardBill();
		}

		if(curBeat % gfSpeed == 0) hud.timeTween();

		if(generatedMusic) { //prevent random null ref (it already happened so this is infact not useless)
			if ((curStage == 'school') && SONG.header.song.toLowerCase() == 'roses' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
				rosesLightningStrike();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat);
		callOnLuas('onBeatHit', []);
		callOnHscripts('onBeatHit', [curBeat]);
	}

	public function callOnHscripts(func:String, args:Array<Dynamic>) {
		if (hscripts != null && hscripts.length > 0) {
			for (hscript in hscripts)
				hscript.call(func, args);
		}
	}

	#if HSCRIPT_ALLOWED
	public function addHscript(path:String) {
		var doPush:Bool = false;
		var hscriptFile:String = 'scripts/' + path + '.hscript';
		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(hscriptFile))) {
			hscriptFile = Paths.modFolders(hscriptFile);
			doPush = true;
		} else {
		#end
			hscriptFile = Paths.getPreloadPath(hscriptFile);
			if(FileSystem.exists(hscriptFile)) {
				doPush = true;
			}
		#if MODS_ALLOWED
		}
		#end

		if(doPush) {
			for (hscript in hscripts)
			{
				if(hscript.scriptName == hscriptFile) return;
			}
			hscripts.push(new Hscript(hscriptFile));
		}
	}
	#end

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

	public function strumPlayAnim(whichLine:Int, id:Int, time:Float) {
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
			spr.resetAnim = time / playbackRate;
		}
	}

	public var ratingName:String = 'Unrated';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function recalculateRating() {
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
				if (songMisses > 0) {
					switch (Std.string(songMisses).split('').length) {
						case 1: ratingFC = "SDCB";
						case 2: ratingFC = "DDCB";
						case 3: ratingFC = "TDCB";
						case 4: ratingFC = "QDCB";
						default: ratingFC = "MDCB";
					}
				}
			switch (ratingFC) {
				case "PFC":
					perfectMode = true;
					fullComboMode = false;
				case "SFC" | "GFC" | "FC":
					perfectMode = false;
					fullComboMode = true;
			}
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);

		//I'm sorry to say that you have gone too deep into the code.
		//There is no way back out.
		switch (ClientPrefs.settings.get("scoreDisplay"))
		{
			case 'Psych':
                final ext:String = (ratingName == "Unrated" ? '' : ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC);
				hud.scoreTxt.text = 'Score: ${FlxStringUtil.formatMoney(songScore, false)} | Breaks: ${FlxStringUtil.formatMoney(songMisses, false)} | Rating: $ratingName' + ext;
			case 'Kade': hud.scoreTxt.text = 'NPS/MAX: $notesPerSecond/$maxNps | SCORE: ${FlxStringUtil.formatMoney(songScore, false)} | BREAKS: ${FlxStringUtil.formatMoney(songMisses, false)} | ACCURACY: ${Highscore.floorDecimal(ratingPercent * 100, 2)}% | ($ratingFC) $ratingName';
			case 'Sarvente':
				hud.leftTxt.text = 'DEATHS:${FlxStringUtil.formatMoney(deathCounter, false)} BREAKS:${FlxStringUtil.formatMoney(songMisses, false)}';
				hud.rightTxt.text = 'SCORE:${FlxStringUtil.formatMoney(songScore, false)}';
				hud.accuracyTxt.text = 'ACCURACY: ${Highscore.floorDecimal(ratingPercent * 100, 2)}%';
				if (perfectMode) {
					hud.scoreTxt.text = 'RATING: PERFECT COMBO';
					hud.accuracyBg.color = hud.scoreTxtBg.color = FlxColor.YELLOW;
				} else if (fullComboMode) {
					hud.scoreTxt.text = 'RATING: FULL COMBO';
					hud.accuracyBg.color = hud.scoreTxtBg.color = 0xffff9100;
				} else {
					hud.scoreTxt.text = 'RATING:' + ratingName;
					switch (ratingName)
					{
						case 'X': hud.accuracyBg.color = hud.scoreTxtBg.color = FlxColor.YELLOW;
						case 'S': hud.accuracyBg.color = hud.scoreTxtBg.color = FlxColor.CYAN;
						case 'A': hud.accuracyBg.color = hud.scoreTxtBg.color = FlxColor.RED;
						default: hud.accuracyBg.color = hud.scoreTxtBg.color = FlxColor.BLACK;
					}
				}
			case 'FPS+': hud.scoreTxt.text = 'Score: ${FlxStringUtil.formatMoney(songScore, false)} | Breaks: $songMisses | Accuracy: ${Highscore.floorDecimal(ratingPercent * 100, 2)}%';
			case 'FNF+': hud.rightTxt.text = 'HP\n${hud.healthBar.roundedPercent}%\n\nACCURACY\n${Highscore.floorDecimal(ratingPercent * 100, 2)}%\n\nSCORE\n${FlxStringUtil.formatMoney(songScore, false)}';
			case 'Vanilla': hud.rightTxt.text = 'Score:${FlxStringUtil.formatMoney(songScore, false)}';
			case 'FNM': hud.rightTxt.text = 'score:${FlxStringUtil.formatMoney(songScore, false)}';
		}

		hud.updateRatings();
	}

	public function recalculateIconAnimations(?forceNeutral:Bool = false) {
		//find less buggy way of doing this
		if (!ClientPrefs.settings.get('disableBotIcon')) {
			if (cpuControlled) {
				iconP1.changeIcon('botfriend');
				iconP1Poison.changeIcon('botfriend');
				setIconPositions(true);
			} else if (iconP1.char != boyfriend.iconProperties.name) {
				iconP1.changeIcon(boyfriend.iconProperties.name, boyfriend);
				iconP1Poison.changeIcon(boyfriend.iconProperties.name, boyfriend);
				setIconPositions(true);
			}
		}
        if (forceNeutral) {
            iconP4.animation.curAnim.curFrame = iconP2.animation.curAnim.curFrame = iconP1Poison.animation.curAnim.curFrame = iconP1.animation.curAnim.curFrame = 0;
            return;
        }

		switch (iconP1.type) {
			case SINGLE: iconP1Poison.animation.curAnim.curFrame = iconP1.animation.curAnim.curFrame = 0;
			case WINNING: iconP1Poison.animation.curAnim.curFrame = iconP1.animation.curAnim.curFrame = (hud.healthBar.percent > 80 ? 2 : (hud.healthBar.percent < 20 ? 1 : 0));
            default: iconP1Poison.animation.curAnim.curFrame = iconP1.animation.curAnim.curFrame = (hud.healthBar.percent < 20 ? 1 : 0);
		}
		if (flinching) {
			if (poison) {
				if(!ClientPrefs.settings.get("hideHud")) iconP1Poison.visible = true;
				reloadHealthBarColors(SONG.notes[curSection].player4Section, null, true);
			}
			if (iconP1.type != SINGLE) iconP1Poison.animation.curAnim.curFrame = iconP1.animation.curAnim.curFrame = 1;
		}
		switch (iconP2.type) {
			case SINGLE: iconP2.animation.curAnim.curFrame = 0;
			case WINNING: iconP2.animation.curAnim.curFrame = (hud.healthBar.percent > 80 ? 1 : (hud.healthBar.percent < 20 ? 2 : 0));
            default: iconP2.animation.curAnim.curFrame = (hud.healthBar.percent > 80 ? 1 : 0);
		}
		switch (iconP4.type) {
			case SINGLE: iconP4.animation.curAnim.curFrame = 0;
			case WINNING: iconP4.animation.curAnim.curFrame = (hud.healthBar.percent > 80 ? 1 : (hud.healthBar.percent < 20 ? 2 : 0));
            default: iconP4.animation.curAnim.curFrame = (hud.healthBar.percent > 80 ? 1 : 0);
		}
	}

	public var autoPositionIcons:Bool = true;
	public function setIconPositions(?y:Bool = false) {
		if (!autoPositionIcons) return;
		if (y) {
			iconP1.y = hud.healthBar.y - 75;
			iconP1Poison.y = iconP1.y + 5;
			iconP2.y = iconP1.y;
			iconP4.y = hud.healthBar.y - 135;
			return;
		}
		final iconOffset:Int = 26;
        final offsetter:Float = FlxMath.bound(health*50, 0, 100);
		iconP1.x = (hud.healthBar.x + (hud.healthBar.width * (FlxMath.remapToRange(offsetter, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset);
		iconP1Poison.x = iconP1.x;
		iconP2.x = (hud.healthBar.x + (hud.healthBar.width * (FlxMath.remapToRange(offsetter, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2);
		iconP4.x = iconP2.x - 80;
	}

	//two functions because killing the trail needs to be done before resetting
	private inline function killTrailOf(target:Character):Bool {
		if(target == null || target == player4 && !SONG.assets.enablePlayer4) return false; //workaround for p4 not existing occasionally

		if(target.charTrail != null) {
			target.charTrail.kill();
			target.charTrail.clear();
		}
		return true;
	}

	private inline function resetTrailOf(target:Character) {
		if(!killTrailOf(target)) return; //null check but shorter

		if(target.trailData.enabled && target.trailData.length != null && target.trailData.delay != null && target.trailData.alpha != null && target.trailData.diff != null) {
			target.charTrail = new FlxTrail(target, null, target.trailData.length, target.trailData.delay, target.trailData.alpha, target.trailData.diff);
			insert(members.indexOf(target.charGroup) - 1, target.charTrail);
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

	//AT what in the fresh fuck is this
	//my lovechild -AT
	function quartizRoutine():Void {
		if (!quartiz) return;
		var quartiz:FlxSprite = new FlxSprite(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height)).loadGraphic(Paths.image('quartiz'));
		quartiz.active = false; //save your computer from hell
		quartiz.angle = FlxG.random.float(0, 359);
		quartiz.alpha = FlxG.random.float(0.06, 1);
		quartiz.setGraphicSize(Std.int(quartiz.width * FlxG.random.float(0.1, 10)));
		quartiz.color = FlxColor.fromRGB(FlxG.random.int(0, 255), FlxG.random.int(0, 255), FlxG.random.int(0, 255));
		quartiz.antialiasing = FlxG.random.bool(50);

		final quartizBlends:Array<BlendMode> = [ADD, ALPHA, DARKEN, ERASE, HARDLIGHT, INVERT, LAYER, LIGHTEN, MULTIPLY, NORMAL, OVERLAY, SCREEN, SHADER, SUBTRACT];
		quartiz.blend = quartizBlends[FlxG.random.int(0,13)];

		switch (FlxG.random.bool(50)) {
			case true:
				quartiz.cameras = [camHUD];
				quartiz.scrollFactor.set();
			case false:
				quartiz.cameras = [camGame];
				quartiz.scrollFactor.set(FlxG.random.float(0,5), FlxG.random.float(0,5));
		}
		if (FlxG.random.bool(12.5)) {
			final num:Int = 150;
			switch(FlxG.random.int(0,3)) {
				case 0: FlxTween.tween(quartiz, {x: quartiz.x + FlxG.random.int(~num+1, num)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
				case 1: FlxTween.tween(quartiz, {y: quartiz.y + FlxG.random.int(~num+1, num)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
				case 2: FlxTween.tween(quartiz, {angle: quartiz.angle + FlxG.random.int(~num+1, num)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
				case 3: FlxTween.tween(quartiz, {x: quartiz.x + FlxG.random.int(~num+1, num), y: quartiz.y + FlxG.random.int(~num+1, num)}, FlxG.random.float(1,10), {ease: FlxEase.quadInOut, type: FlxTweenType.PINGPONG});
			}
		}
		add(quartiz);
	}

	inline function poisonRoutine():Void {
		poisonMult += 0.038;
		for (poisonSprite in poisonSpriteGrp) {
			poisonSprite.visible = true;
			if (poisonSprite.alpha < 1) FlxTween.tween(poisonSprite, {alpha: 1}, 0.2);
		}
		if (poisonTimer != null) {
			poisonTimer.cancel();
			poisonTimer = null;
		}
		poisonTimer = new FlxTimer().start(3, _ -> {
			poisonMult = 0;
			if(!ClientPrefs.settings.get("hideHud")) iconP1Poison.visible = false;
			recalculateIconAnimations();
			reloadHealthBarColors(SONG.notes[curSection].player4Section);
			for (poisonSprite in poisonSpriteGrp) {
				FlxTween.tween(poisonSprite, {alpha: 0}, 0.2, {onComplete: _ -> poisonSprite.visible = false});
			}
		});
	}

	inline function freezeRoutine():Void {
		if (freezeTimer != null || freezeCooldownTimer != null) return;
		for (freezeSprite in freezeSpriteGrp) {
			freezeSprite.visible = true;
			if (freezeSprite.alpha < 1) FlxTween.tween(freezeSprite, {alpha: 1}, 0.4);
		}
		for (sound in [vocals, secondaryVocals, FlxG.sound.music]) {
			FlxTween.tween(sound, {volume: (sound == vocals ? 0.05 : 0.25)}, 0.4);
		}
		boyfriend.color = 0xff7eeeff;
		boyfriend.stunned = true;
		freezeTimer = new FlxTimer().start(2, _ -> {
			boyfriend.stunned = false;
			for (freezeSprite in freezeSpriteGrp) {
				FlxTween.tween(freezeSprite, {alpha: 0}, 0.4, {onComplete: _ -> freezeSprite.visible = false});
			}
			FlxTween.tween(FlxG.sound.music, {volume: SONG.header.instVolume}, 0.4);
			FlxTween.tween(vocals, {volume: SONG.header.vocalsVolume}, 0.4);
			FlxTween.tween(secondaryVocals, {volume: SONG.header.secVocalsVolume}, 0.4);
			boyfriend.color = 0xffffffff;
			freezeCooldownTimer = new FlxTimer().start(0.2, _ -> {
				freezeCooldownTimer = null;
			});
			freezeTimer = null;
		});
	}

	inline function ghostModeRoutine(daNote:Note):Void {
        daNote.copyAlpha = daNote.isSustainNote;
		if (!daNote.isSustainNote) FlxTween.tween(daNote, {alpha: 0}, 0.26/songSpeed, {startDelay: 0.95/songSpeed});
		else FlxTween.tween(daNote, {multAlpha: 0}, 0.13/songSpeed, {startDelay: 0.95/songSpeed});
	}

	public function canIUseTheCutsceneMother(endCutscene:Bool = false):Bool
	{
		if(seenCutscene && !endCutscene) return false;
	
		switch (ClientPrefs.settings.get("cutscenes")) {
			case 'Story Mode Only': return isStoryMode;
			case 'Freeplay Only': return !isStoryMode;
			case 'Always': return true;
		}
		return false;
	}
	
	inline function addATint(alpha:Float, color:FlxColor):FlxSprite {
		var tint:FlxSprite = new FlxSprite().makeGraphic(FlxG.width,FlxG.width,FlxColor.WHITE);
		tint.scrollFactor.set();
		tint.screenCenter();
		tint.alpha = alpha;
		tint.blend = BlendMode.MULTIPLY;
		tint.color = color;
		tint.cameras = [camTint];
		tint.active = false;
		add(tint);
		return(tint);
	}

	function camPanRoutine(anim:String = 'singUP', who:String = 'bf'):Void {
		var fps:Float = Main.fpsCounter.currentFPS;
		final bfCanPan:Bool = SONG.notes[curSection].mustHitSection;
		final dadCanPan:Bool = !SONG.notes[curSection].mustHitSection;
		final p4CanPan:Bool = (!SONG.notes[curSection].mustHitSection && SONG.notes[curSection].player4Section) ? true : false;
		var clear:Bool = false;
		switch (who) {
			case 'bf': clear = bfCanPan;
			case 'oppt': clear = dadCanPan;
			case 'p4': clear = p4CanPan;
		}
		//FlxG.elapsed is stinky poo poo for this, it just makes it look jank as fuck
		if (clear) {
			if (fps == 0) fps = 1;
			switch (anim.split('-')[0])
			{
				case 'singUP': moveCamTo[1] = -40*240/fps;
				case 'singDOWN': moveCamTo[1] = 40*240/fps;
				case 'singLEFT': moveCamTo[0] = -40*240/fps;
				case 'singRIGHT': moveCamTo[0] = 40*240/fps;
			}
		}
	}

	public function initModifiers(?hotswap:Bool = false) {
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		quartiz = ClientPrefs.getGameplaySetting('quartiz', false);
		ghostMode = ClientPrefs.getGameplaySetting('ghostmode', false);
		sickOnly = ClientPrefs.getGameplaySetting('sickonly', false);
		if(cpuControlled == true && !SONG.options.allowBot) {
			cpuControlled = false;
		}
		tappy = ClientPrefs.settings.get("ghostTapping");
		if(tappy == true && !SONG.options.allowGhostTapping)
			tappy = false;

		if (hotswap) {
			playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
			songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');
			switch(songSpeedType)
			{
				case "multiplicative": songSpeed = SONG.options.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
				case "constant": songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
			}
		} else {
			randomMode = ClientPrefs.getGameplaySetting('randommode', false);
			flip = ClientPrefs.getGameplaySetting('flip', false);
			flashLight = ClientPrefs.getGameplaySetting('flashlight', false);
			poison = ClientPrefs.getGameplaySetting('poison', false);
			freeze = ClientPrefs.getGameplaySetting('freeze', false);
		}
	}

	public function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		if(dialogueBox == null) {
			startCountdown();
			return;
		} //again, no need to load any of this if theres no dialogue to begin with!!

		camHUD.alpha = 0;
		inCutscene = true;
		var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		black.scrollFactor.set();
		black.screenCenter();
		add(black);

		var red:FlxSprite = null;
		var senpaiEvil:FlxSprite = null;

		var songName:String = Paths.formatToSongPath(SONG.header.song);
		if (songName == 'thorns')
		{
			remove(black, true);
			Main.toggleFPS(ClientPrefs.settings.get("showFPS"));

			red = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFff1b31);
			red.scrollFactor.set();
			red.screenCenter();
		
			senpaiEvil = new FlxSprite();
			senpaiEvil.frames = Paths.getSparrowAtlas('vanilla/week6/weeb/senpaiCrazy');
			senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
			senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
			senpaiEvil.scrollFactor.set();
			senpaiEvil.updateHitbox();
			senpaiEvil.screenCenter();
			senpaiEvil.x += 300;
			senpaiEvil.antialiasing = false;

			add(red);
			camHUD.visible = false;
			dad.x -= 600;
			dad.alpha = 0;
		}

		new FlxTimer().start(0.3, tmr -> {
			black.alpha -= (songName == 'roses' ? 0.25 : 0.15);

			if (black.alpha > 0)
				tmr.reset((songName == 'roses' ? 0.15 : 0.3));
			else
			{
				if (Paths.formatToSongPath(SONG.header.song) == 'thorns')
				{
					add(senpaiEvil);
					senpaiEvil.alpha = 0.001;
					new FlxTimer().start(0.3, swagTimer -> {
						senpaiEvil.alpha += 0.15;
						if (senpaiEvil.alpha < 1)
							swagTimer.reset();
						else
						{
							senpaiEvil.animation.play('idle');
							FlxG.sound.play(Paths.sound('vanilla/week6/Senpai_Dies'), 1, false, null, true, () -> {
								remove(senpaiEvil, true);
								remove(red, true);

								camOther.flash(FlxColor.WHITE, 0.6, null, true);
								FlxG.camera.fade(FlxColor.WHITE, 0.01, true, () -> {
									add(dialogueBox);
									camHUD.visible = true;
								}, true);
							});
							new FlxTimer().start(3.2, _ -> FlxG.camera.fade(FlxColor.WHITE, 1.6, false));
						}
					});
				}
				else
					add(dialogueBox);
				
				remove(black, true);
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
	
		var tankman:AtlasSprite = new AtlasSprite(-20, 320, 'tankman-$songName');
		addBehindDad(tankman);
		cutsceneHandler.push(tankman);

		var boyfriendCutscene:FlxSprite = null;
		var gfDance:FlxSprite = null;

		cutsceneHandler.canSkip = true;
		canPause = false;
	
		cutsceneHandler.finishCallback = () -> {
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
				if (boyfriendCutscene != null) {
					boyfriendCutscene.kill();
					remove(boyfriendCutscene, true);
				}
				if (gfDance != null) {
					gfDance.kill();
					remove(gfDance, true);
				}
			}
			cutsceneHandlerCutscene = false;
		};
	
		camFollow.set(dad.x + 280, dad.y + 170);
		switch(songName)
		{
			case 'ugh':
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'vanilla/week7/DISTORTO';
				precacheList.set('vanilla/week7/wellWellWell', 'sound');
				precacheList.set('vanilla/week7/killYou', 'sound');
				precacheList.set('bfBeep', 'sound');
	
				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('vanilla/week7/wellWellWell'));
				FlxG.sound.list.add(wellWellWell);
				cutsceneHandler.sounds.push(wellWellWell);

				var beep:FlxSound = new FlxSound().loadEmbedded(Paths.sound('bfBeep'));
				FlxG.sound.list.add(beep);
				cutsceneHandler.sounds.push(beep);
	
				var killYou:FlxSound = new FlxSound().loadEmbedded(Paths.sound('vanilla/week7/killYou'));
				FlxG.sound.list.add(killYou);
				cutsceneHandler.sounds.push(killYou);
	
				tankman.playAnim('talk1', true);
				tankman.x += 455;
				tankman.y += 242;
				FlxG.camera.zoom *= 1.2;

				var right:Bool = false;
				function cutsceneCam():Void
				{
					camFollow.x += right ? 750 : -750;
					camFollow.y += right ? 100 : -100;
				}
	
				// Well well well, what do we got here?
				cutsceneHandler.timer(0.1, () -> wellWellWell.play(true));
	
				// Move camera to BF
				cutsceneHandler.timer(3, () -> {
					right = true;
					cutsceneCam();
				});
	
				// Beep!
				cutsceneHandler.timer(4.5, () -> {
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					beep.play(true);
				});
	
				// Move camera to Tankman
				cutsceneHandler.timer(6, () -> {
					right = false;
					cutsceneCam();
	
					// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
					tankman.playAnim('talk2', true);
					killYou.play(true);
				});
	
			case 'guns':
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'vanilla/week7/DISTORTO';
				precacheList.set('vanilla/week7/tankSong2', 'sound');
	
				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('vanilla/week7/tankSong2'));
				FlxG.sound.list.add(tightBars);
				cutsceneHandler.sounds.push(tightBars);
	
				tankman.playAnim('talk1', true);
				tankman.x += 455;
				tankman.y += 242;
				boyfriend.animation.curAnim.finish();
	
				cutsceneHandler.onStart = () -> {
					tightBars.play(true);
					cutsceneHandler.tweens.push(FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut}));
					cutsceneHandler.tweens.push(FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4}));
					cutsceneHandler.tweens.push(FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5}));
				};
	
				cutsceneHandler.timer(4, () -> {
					gf.playAnim('sad', true);
					gf.animation.finishCallback = name -> gf.playAnim('sad', true);
				});
	
			case 'stress':
				cutsceneHandler.endTime = 35.5;
				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;
				camFollow.set(dad.x + 400, dad.y + 170);
				cutsceneHandler.tweens.push(FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut}));
				tankmanRun.forEach(tankman -> tankman.visible = false);
				foregroundSprites.forEach(spr -> spr.y += 100);
				precacheList.set('stressCutscene', 'sound');
	
				gfDance = new FlxSprite(gf.x - 107, gf.y + 140);
				cutsceneHandler.push(gfDance);
				if (!ClientPrefs.settings.get("lowQuality"))
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/Week7/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}
	
				var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
				cutsceneHandler.push(gfCutscene);
				gfCutscene.frames = Paths.getSparrowAtlas('vanilla/week7/cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);
				if (!ClientPrefs.settings.get("lowQuality")) gfCutscene.alpha = 0.00001;
	
				var picoCutscene:AtlasSprite = new AtlasSprite(gf.x + 149, gf.y + 451, 'pico-stress');
				cutsceneHandler.push(picoCutscene);
				addBehindGF(picoCutscene);
				picoCutscene.alpha = 0.00001;

				boyfriendCutscene = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
				cutsceneHandler.push(boyfriendCutscene);
				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('loop', 'BF idle dance', 24, true);
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('loop', true);
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('vanilla/week7/stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);
				cutsceneHandler.sounds.push(cutsceneSnd);
	
				tankman.playAnim('talk1', true);
				tankman.x += 455;
				tankman.y += 242;
	
				var calledTimes:Int = 0;
				function zoomBack():Void
				{
					final camPosX:Float = 630;
					final camPosY:Float = 425;
					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);
					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;
	
					calledTimes++;
					if (calledTimes > 1) foregroundSprites.forEach(spr -> spr.y -= 100);
				}
	
				cutsceneHandler.onStart = () -> cutsceneSnd.play(true);
	
				cutsceneHandler.timer(15.2, () -> {
					cutsceneHandler.tweens.push(FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut}));
					cutsceneHandler.tweens.push(FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut}));
	
					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					boyfriendCutscene.animation.play('idle', true);
					boyfriendCutscene.animation.curAnim.finish();
					gfCutscene.animation.finishCallback = name -> {
						if(name == 'dieBitch') //Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.playAnim('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = name -> {
								if(name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
									boyfriend.animation.finishCallback = null;
								}
							};
	
							picoCutscene.atlas.anim.onComplete = () -> {
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};
							gfCutscene.animation.finishCallback = null;
						}
					};
				});
	
				cutsceneHandler.timer(17.5, zoomBack);
	
				cutsceneHandler.timer(19.5, () -> {
					tankman.playAnim('talk2', true);
				});
	
				cutsceneHandler.timer(20, () -> camFollow.set(dad.x + 500, dad.y + 170));
	
				cutsceneHandler.timer(31.2, () -> {
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = name -> {
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};
	
					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;
					cutsceneHandler.tweens.push(FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut}));
				});
	
				cutsceneHandler.timer(32.2, zoomBack);
		}
	}

	inline function thornsEndCutscene():Void {
		if (canIUseTheCutsceneMother(true)) {
			inCutscene = true;
			FlxG.sound.play(Paths.sound('vanilla/week6/tp1'));
			var mult = 1;
			new FlxTimer().start(0.05, _ -> {
				final offset = Std.int((255/9)*mult);
				boyfriend.setColorTransform(1, 1, 1, 1, offset, offset, offset, 0);
				gf.setColorTransform(1, 1, 1, 1, offset, offset, offset, 0);
				mult++;
			}, 9);
			new FlxTimer().start(0.45, t -> {
				FlxTween.tween(boyfriend, {'scale.y': 0.0001, 'scale.x': 1.1}, 0.6, {
					ease: FlxEase.expoOut,
					onComplete: _ -> {
						inCutscene = false;
						boyfriend.visible = false;
						gf.visible = false;
					}
				});
				FlxTween.tween(gf, {'scale.y': 0.0001, 'scale.x': 1.1}, 0.6, {ease: FlxEase.expoOut});
			});
		}
	}

	inline function eggnogEndCutscene():Void {
		if (canIUseTheCutsceneMother(true)) {
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
			LoadingState.globeTrans = false;
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
					leSprite.active = false;
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
				if (spriteData.size[2] == null) leSprite.updateHitbox();
			}
			if(spriteData.alpha != null && spriteData.alpha != 1) leSprite.alpha = spriteData.alpha;
			if(spriteData.angle != null && spriteData.angle != 0) leSprite.angle = spriteData.angle;
			if(spriteData.flip_x != null && spriteData.flip_x != false) leSprite.flipX = spriteData.flip_x;
			if(spriteData.flip_y != null && spriteData.flip_y != false) leSprite.flipY = spriteData.flip_y;
			leSprite.antialiasing = spriteData.antialiasing ? ClientPrefs.settings.get("globalAntialiasing") : false;
			if (!spriteData.front && !spriteData.gf_front) layerArray.insert(spriteData.layer_pos, leSprite);
			if (spriteData.gf_front) middleLayerArray.insert(spriteData.layer_pos, leSprite);
			if (spriteData.front && !spriteData.gf_front) topLayerArray.insert(spriteData.layer_pos, leSprite);
			if (spriteData.glitch_shader != null && spriteData.glitch_shader) addGlitchShader(leSprite, (spriteData.glitch_amplitude == null) ? 1 : spriteData.glitch_amplitude, (spriteData.glitch_frequency == null) ? 1 : spriteData.glitch_frequency, (spriteData.glitch_speed == null) ? 1 : spriteData.glitch_speed);
			if (spriteData.origin != null) leSprite.origin.set(spriteData.origin[0], spriteData.origin[1]);
			jsonSprites.set(spriteData.tag, leSprite);
		}
		autoLayer(layerArray, jsonSprGrp);
		autoLayer(middleLayerArray, jsonSprGrpMiddle);
		autoLayer(topLayerArray, jsonSprGrpFront);
	}

	/**
	* Function to automatically `add()` `FlxBasic` objects, either to a group or without.
	* 
	* @param array The `Array` of `FlxBasic`s to be used.
	* @param group The `FlxBasic` group for the `FlxBasic`s to be added into.
	*/
	public function autoLayer(array:Array<FlxBasic>, ?group:FlxTypedGroup<FlxBasic>):Void {
		try {
			if (group != null) for (object in array) group.add(object);
			else for (object in array) add(object);
		} catch (e) {
			trace('exception: ' + e);
			return;
		}
	}
}

@:structInit class ModifierSpriteData {
	public var name:String;
	public var condition:Bool;
	public var xPos:Int;
	public var yPos:Int;
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
		y -= ClientPrefs.settings.get("downScroll") ? FlxG.height/2 : 50;
        cameras = [camera];
		active = false;
    }
}