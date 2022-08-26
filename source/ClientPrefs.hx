package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

class ClientPrefs {
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var showFPS:Bool = true;
	public static var fullscreen:Bool = false;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var framerate:Int = 60;
	public static var crossFadeLimit:Null<Int> = 4;
	public static var boyfriendCrossFadeLimit:Null<Int> = 1;
	public static var opponentNoteAnimations:Bool = true;
	public static var opponentAlwaysDance:Bool = true;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var camPans:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var timeBarRed:Int = 255;
	public static var timeBarGreen:Int = 255;
	public static var timeBarBlue:Int = 255;
	public static var uiSkin:String = 'fnf';
	public static var iconSwing:String = 'Swing Mild';
	public static var scoreDisplay:String = 'Psych';
	public static var crossFadeMode:String = 'Mid-Fight Masses';
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = false;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'Tea Time';
	public static var inputType:String = 'Psych';
	public static var ratingIntensity:String = 'Default';
	public static var randomMode:Bool = false;
	public static var quartiz:Bool = false;
	public static var ghostMode:Bool = false; //Unused, Does nothing as of rn because its disabled.
	public static var watermarks:Bool = true;
	public static var ratingsDisplay:Bool = true;
	public static var gsmiss:Bool = true;
	public static var winningicons:Bool = true;
	public static var changeTBcolour:Bool = true;
	public static var greenhp:Bool = false;
	public static var newHP:Bool = true;
	public static var sarvAccuracy:Bool = false;
	public static var comboPopup:Bool = true;
	public static var msPopup:Bool = true;
	public static var msPrecision:Int = 2;
	public static var flinchy:Bool = true;
	public static var cutscenes:String = 'Story Mode Only';
	public static var camPanMode:String = 'Always';
	public static var mouseControls:Bool = true;
	public static var checkForUpdates:Null<Bool> = true;
	public static var darkenBG:Bool = false;
	public static var accuracyMode:String = 'Simple';
	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0, 0, 0];
	public static var noAntimash:Bool = false;
	public static var ratingOffset:Int = 0;
	public static var perfectWindow:Int = 10;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var shitWindow:Int = 205;
	public static var safeFrames:Float = 10;

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_one1'		=> [SPACE, NONE],

		'note_two1'		=> [D, NONE],
		'note_two2'		=> [K, NONE],

		'note_three1'	=> [D, NONE],
		'note_three2'	=> [SPACE, NONE],
		'note_three3'	=> [K, NONE],

		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'note_five1'	=> [D, NONE],
		'note_five2'	=> [F, NONE],
		'note_five3'	=> [SPACE, NONE],
		'note_five4'	=> [J, NONE],
		'note_five5'	=> [K, NONE],

		'note_six1'		=> [S, NONE],
		'note_six2'		=> [D, NONE],
		'note_six3'		=> [F, NONE],
		'note_six4'		=> [J, NONE],
		'note_six5'		=> [K, NONE],
		'note_six6'		=> [L, NONE],

		'note_seven1'	=> [S, NONE],
		'note_seven2'	=> [D, NONE],
		'note_seven3'	=> [F, NONE],
		'note_seven4'	=> [SPACE, NONE],
		'note_seven5'	=> [J, NONE],
		'note_seven6'	=> [K, NONE],
		'note_seven7'	=> [L, NONE],

		'note_eight1'	=> [A, NONE],
		'note_eight2'	=> [S, NONE],
		'note_eight3'	=> [D, NONE],
		'note_eight4'	=> [F, NONE],
		'note_eight5'	=> [H, NONE],
		'note_eight6'	=> [J, NONE],
		'note_eight7'	=> [K, NONE],
		'note_eight8'	=> [L, NONE],

		'note_nine1'	=> [A, NONE],
		'note_nine2'	=> [S, NONE],
		'note_nine3'	=> [D, NONE],
		'note_nine4'	=> [F, NONE],
		'note_nine5'	=> [SPACE, NONE],
		'note_nine6'	=> [H, NONE],
		'note_nine7'	=> [J, NONE],
		'note_nine8'	=> [K, NONE],
		'note_nine9'	=> [L, NONE],

		'note_ten1'		=> [A, NONE],
		'note_ten2'		=> [S, NONE],
		'note_ten3'		=> [D, NONE],
		'note_ten4'		=> [F, NONE],
		'note_ten5'		=> [G, NONE],
		'note_ten6'		=> [SPACE, NONE],
		'note_ten7'		=> [H, NONE],
		'note_ten8'     => [J, NONE],
		'note_ten9'		=> [K, NONE],
		'note_ten10'	=> [L, NONE],

		'note_elev1'	=> [A, NONE],
		'note_elev2'	=> [S, NONE],
		'note_elev3'	=> [D, NONE],
		'note_elev4'	=> [F, NONE],
		'note_elev5'	=> [G, NONE],
		'note_elev6'	=> [SPACE, NONE],
		'note_elev7'	=> [H, NONE],
		'note_elev8'    => [J, NONE],
		'note_elev9'	=> [K, NONE],
		'note_elev10'	=> [L, NONE],
		'note_elev11'	=> [PERIOD, NONE],
		
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],
		
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R, NONE],
		
		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		//trace(defaultKeys);
	}

	public static function saveSettings() {
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.fullscreen = fullscreen;
		FlxG.save.data.flashing = flashing;
		FlxG.save.data.globalAntialiasing = globalAntialiasing;
		FlxG.save.data.noteSplashes = noteSplashes;
		FlxG.save.data.lowQuality = lowQuality;
		FlxG.save.data.framerate = framerate;
		FlxG.save.data.crossFadeLimit = crossFadeLimit;
		FlxG.save.data.boyfriendCrossFadeLimit = boyfriendCrossFadeLimit;
		FlxG.save.data.opponentNoteAnimations = opponentNoteAnimations;
		FlxG.save.data.opponentAlwaysDance = opponentAlwaysDance;
		//FlxG.save.data.cursing = cursing;
		//FlxG.save.data.violence = violence;
		FlxG.save.data.camZooms = camZooms;
		FlxG.save.data.camPans = camPans;
		FlxG.save.data.noteOffset = noteOffset;
		FlxG.save.data.hideHud = hideHud;
		FlxG.save.data.arrowHSV = arrowHSV;
		FlxG.save.data.timeBarRed = timeBarRed;
		FlxG.save.data.timeBarGreen = timeBarGreen;
		FlxG.save.data.timeBarBlue = timeBarBlue;
		FlxG.save.data.uiSkin = uiSkin;
		FlxG.save.data.iconSwing = iconSwing;
		FlxG.save.data.scoreDisplay = scoreDisplay;
		FlxG.save.data.crossFadeMode = crossFadeMode;
		FlxG.save.data.ghostTapping = ghostTapping;
		FlxG.save.data.timeBarType = timeBarType;
		FlxG.save.data.scoreZoom = scoreZoom;
		FlxG.save.data.noReset = noReset;
		FlxG.save.data.healthBarAlpha = healthBarAlpha;
		FlxG.save.data.comboOffset = comboOffset;
		FlxG.save.data.achievementsMap = Achievements.achievementsMap;
		FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
		FlxG.save.data.noAntimash = noAntimash;
		FlxG.save.data.quartiz = quartiz;
		FlxG.save.data.randomMode = randomMode;
		FlxG.save.data.ghostMode = ghostMode;
		FlxG.save.data.watermarks = watermarks;
		FlxG.save.data.ratingsDisplay = ratingsDisplay;
		FlxG.save.data.gsmiss = gsmiss;
		FlxG.save.data.greenhp = greenhp;
		FlxG.save.data.newHP = newHP;
		FlxG.save.data.sarvAccuracy = sarvAccuracy;
		FlxG.save.data.comboPopup = comboPopup;
		FlxG.save.data.msPopup = msPopup;
		FlxG.save.data.msPrecision = msPrecision;
		FlxG.save.data.winningicons = winningicons;
		FlxG.save.data.changeTBcolour = changeTBcolour;
		FlxG.save.data.ratingOffset = ratingOffset;
		FlxG.save.data.perfectWindow = perfectWindow;
		FlxG.save.data.sickWindow = sickWindow;
		FlxG.save.data.goodWindow = goodWindow;
		FlxG.save.data.badWindow = badWindow;
		FlxG.save.data.shitWindow = shitWindow;
		FlxG.save.data.safeFrames = safeFrames;
		FlxG.save.data.gameplaySettings = gameplaySettings;
		FlxG.save.data.controllerMode = controllerMode;
		FlxG.save.data.hitsoundVolume = hitsoundVolume;
		FlxG.save.data.pauseMusic = pauseMusic;
		FlxG.save.data.inputType = inputType;
		FlxG.save.data.ratingIntensity = ratingIntensity;
		FlxG.save.data.cutscenes = cutscenes;
		FlxG.save.data.camPanMode = camPanMode;
		FlxG.save.data.flinchy = flinchy;
		FlxG.save.data.mouseControls = mouseControls;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.darkenBG = darkenBG;
		FlxG.save.data.accuracyMode = accuracyMode;
	
		FlxG.save.flush();

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99'); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		save.data.customControls = keyBinds;
		save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		if(FlxG.save.data.downScroll != null) {
			downScroll = FlxG.save.data.downScroll;
		}
		if(FlxG.save.data.middleScroll != null) {
			middleScroll = FlxG.save.data.middleScroll;
		}
		if(FlxG.save.data.showFPS != null) {
			showFPS = FlxG.save.data.showFPS;
			if(Main.fpsVar != null) {
				Main.fpsVar.visible = showFPS;
			}
		}
		if(FlxG.save.data.fullscreen != null) {
			fullscreen = FlxG.save.data.fullscreen;
		}
		if(FlxG.save.data.flashing != null) {
			flashing = FlxG.save.data.flashing;
		}
		if(FlxG.save.data.globalAntialiasing != null) {
			globalAntialiasing = FlxG.save.data.globalAntialiasing;
		}
		if(FlxG.save.data.noteSplashes != null) {
			noteSplashes = FlxG.save.data.noteSplashes;
		}
		if(FlxG.save.data.lowQuality != null) {
			lowQuality = FlxG.save.data.lowQuality;
		}
		if(FlxG.save.data.crossFadeLimit != null) {
			crossFadeLimit = FlxG.save.data.crossFadeLimit;
		}
		if(FlxG.save.data.boyfriendCrossFadeLimit != null) {
			boyfriendCrossFadeLimit = FlxG.save.data.boyfriendCrossFadeLimit;
		}
		if(FlxG.save.data.framerate != null) {
			framerate = FlxG.save.data.framerate;
			if(framerate > FlxG.drawFramerate) {
				FlxG.updateFramerate = framerate;
				FlxG.drawFramerate = framerate;
			} else {
				FlxG.drawFramerate = framerate;
				FlxG.updateFramerate = framerate;
			}
		}
		if(FlxG.save.data.opponentNoteAnimations != null) {
			opponentNoteAnimations = FlxG.save.data.opponentNoteAnimations;
		}
		if(FlxG.save.data.opponentAlwaysDance != null) {
			opponentAlwaysDance = FlxG.save.data.opponentAlwaysDance;
		}
		/*if(FlxG.save.data.cursing != null) {
			cursing = FlxG.save.data.cursing;
		}
		if(FlxG.save.data.violence != null) {
			violence = FlxG.save.data.violence;
		}*/
		if(FlxG.save.data.camZooms != null) {
			camZooms = FlxG.save.data.camZooms;
		}
		if(FlxG.save.data.camPans != null) {
			camPans = FlxG.save.data.camPans;
		}
		if(FlxG.save.data.hideHud != null) {
			hideHud = FlxG.save.data.hideHud;
		}
		if(FlxG.save.data.noteOffset != null) {
			noteOffset = FlxG.save.data.noteOffset;
		}
		if(FlxG.save.data.arrowHSV != null) {
			arrowHSV = FlxG.save.data.arrowHSV;
		}
		if(FlxG.save.data.timeBarRed != null) {
			timeBarRed = FlxG.save.data.timeBarRed;
		}
		if(FlxG.save.data.timeBarGreen != null) {
			timeBarGreen = FlxG.save.data.timeBarGreen;
		}
		if(FlxG.save.data.timeBarBlue != null) {
			timeBarBlue = FlxG.save.data.timeBarBlue;
		}
		if(FlxG.save.data.uiSkin != null) {
			uiSkin = FlxG.save.data.uiSkin;
		}
		if(FlxG.save.data.iconSwing != null) {
			iconSwing = FlxG.save.data.iconSwing;
		}
		if(FlxG.save.data.scoreDisplay != null) {
			scoreDisplay = FlxG.save.data.scoreDisplay;
		}
		if(FlxG.save.data.crossFadeMode != null) {
			crossFadeMode = FlxG.save.data.crossFadeMode;
		}
		if(FlxG.save.data.ghostTapping != null) {
			ghostTapping = FlxG.save.data.ghostTapping;
		}
		if(FlxG.save.data.timeBarType != null) {
			timeBarType = FlxG.save.data.timeBarType;
		}
		if(FlxG.save.data.scoreZoom != null) {
			scoreZoom = FlxG.save.data.scoreZoom;
		}
		if(FlxG.save.data.noReset != null) {
			noReset = FlxG.save.data.noReset;
		}
		if(FlxG.save.data.healthBarAlpha != null) {
			healthBarAlpha = FlxG.save.data.healthBarAlpha;
		}
		if(FlxG.save.data.comboOffset != null) {
			comboOffset = FlxG.save.data.comboOffset;
		}
		
		if(FlxG.save.data.ratingOffset != null) {
			ratingOffset = FlxG.save.data.ratingOffset;
		}
		if(FlxG.save.data.perfectWindow != null) {
			perfectWindow = FlxG.save.data.perfectWindow;
		}
		if(FlxG.save.data.sickWindow != null) {
			sickWindow = FlxG.save.data.sickWindow;
		}
		if(FlxG.save.data.goodWindow != null) {
			goodWindow = FlxG.save.data.goodWindow;
		}
		if(FlxG.save.data.badWindow != null) {
			badWindow = FlxG.save.data.badWindow;
		}
		if(FlxG.save.data.shitWindow != null) {
			shitWindow = FlxG.save.data.shitWindow;
		}
		if(FlxG.save.data.safeFrames != null) {
			safeFrames = FlxG.save.data.safeFrames;
		}
		if(FlxG.save.data.controllerMode != null) {
			controllerMode = FlxG.save.data.controllerMode;
		}
		if(FlxG.save.data.hitsoundVolume != null) {
			hitsoundVolume = FlxG.save.data.hitsoundVolume;
		}
		if(FlxG.save.data.pauseMusic != null) {
			pauseMusic = FlxG.save.data.pauseMusic;
		}
		if(FlxG.save.data.inputType != null) {
			inputType = FlxG.save.data.inputType;
		}
		if(FlxG.save.data.ratingIntensity != null) {
			ratingIntensity = FlxG.save.data.ratingIntensity;
		}
		if(FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
			{
				gameplaySettings.set(name, value);
			}
		}
		
		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}

		if (FlxG.save.data.noAntimash != null)
			{
				noAntimash = FlxG.save.data.noAntimash;
			}
		
		if (FlxG.save.data.quartiz != null)
			{
				quartiz = FlxG.save.data.quartiz;
			}


		if (FlxG.save.data.randomMode != null)
			{
				randomMode = FlxG.save.data.randomMode;
			}

		if (FlxG.save.data.ghostMode != null)
			{
				ghostMode = FlxG.save.data.ghostMode;
			}
		if (FlxG.save.data.watermarks != null)
			{
				watermarks = FlxG.save.data.watermarks;
			}
		if (FlxG.save.data.ratingsDisplay != null)
			{
				ratingsDisplay = FlxG.save.data.ratingsDisplay;
			}
		if (FlxG.save.data.gsmiss != null)
			{
				gsmiss = FlxG.save.data.gsmiss;
			}
		if (FlxG.save.data.greenhp != null)
			{
				greenhp = FlxG.save.data.greenhp;
			}
		if (FlxG.save.data.newHP != null)
			{
				newHP = FlxG.save.data.newHP;
			}
		if (FlxG.save.data.sarvAccuracy != null)
			{
				sarvAccuracy = FlxG.save.data.sarvAccuracy;
			}
		if (FlxG.save.data.comboPopup != null)
			{
				comboPopup = FlxG.save.data.comboPopup;
			}
		if (FlxG.save.data.msPopup != null)
			{
				msPopup = FlxG.save.data.msPopup;
			}
		if (FlxG.save.data.msPrecision != null)
			{
				msPrecision = FlxG.save.data.msPrecision;
			}
		if (FlxG.save.data.winningicons != null)
			{
				winningicons = FlxG.save.data.winningicons;
			}
		if (FlxG.save.data.changeTBcolour != null)
			{
				changeTBcolour = FlxG.save.data.changeTBcolour;
			}		
		if (FlxG.save.data.cutscenes != null)
			{
				cutscenes = FlxG.save.data.cutscenes;
			}
		if (FlxG.save.data.camPanMode != null)
			{
				camPanMode = FlxG.save.data.camPanMode;
			}
		if (FlxG.save.data.flinchy != null)
			{
				flinchy = FlxG.save.data.flinchy;
			}
		if (FlxG.save.data.mouseControls != null)
			{
				mouseControls = FlxG.save.data.mouseControls;
			}
		if (FlxG.save.data.checkForUpdates != null)
			{
				checkForUpdates = FlxG.save.data.checkForUpdates;
			}
		if (FlxG.save.data.darkenBG != null)
			{
				darkenBG = FlxG.save.data.darkenBG;
			}
		if (FlxG.save.data.accuracyMode != null)
			{
				accuracyMode = FlxG.save.data.accuracyMode;
			}

		var save:FlxSave = new FlxSave();
		save.bind('controls_v2', 'ninjamuffin99');
		if(save != null && save.data.customControls != null) {
			var loadedControls:Map<String, Array<FlxKey>> = save.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
			reloadControls();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return /*PlayState.isStoryMode ? defaultValue : */ (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		InitState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		InitState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		InitState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));
		FlxG.sound.muteKeys = InitState.muteKeys;
		FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;
	}
	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey> {
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len) {
			if(copiedArray[i] == NONE) {
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
