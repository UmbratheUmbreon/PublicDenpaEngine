package;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;

/**
* Class containing all settings.
* Automatically saves and loads.
*/
class ClientPrefs {
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var showFPS:Bool = #if debug true #else false #end;
	public static var fullscreen:Bool = false;
	public static var autoPause:Bool = true;
	public static var flashing:Bool = true;
	public static var globalAntialiasing:Bool = true;
	public static var noteSplashes:Bool = true;
	public static var lowQuality:Bool = false;
	public static var framerate:Int = 60;
	public static var crossFadeLimit:Null<Int> = 4;
	public static var boyfriendCrossFadeLimit:Null<Int> = 2;
	public static var opponentNoteAnimations:Bool = true;
	public static var opponentAlwaysDance:Bool = true;
	public static var cursing:Bool = true;
	public static var violence:Bool = true;
	public static var camZooms:Bool = true;
	public static var camPans:Bool = true;
	public static var hideHud:Bool = false;
	public static var noteOffset:Int = 0;
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var timeBarRGB:Array<Int> = [255, 255, 255];
	public static var uiSkin:String = 'FNF';
	public static var iconSwing:String = 'Swing';
	public static var scoreDisplay:String = 'Psych';
	public static var crossFadeMode:String = 'Mid-Fight Masses';
	public static var ghostTapping:Bool = true;
	public static var timeBarType:String = 'Time Left';
	public static var scoreZoom:Bool = true;
	public static var noReset:Bool = true;
	public static var healthBarAlpha:Float = 1;
	public static var controllerMode:Bool = false;
	public static var hitsoundVolume:Float = 0;
	public static var pauseMusic:String = 'OVERDOSE';
	public static var ratingIntensity:String = 'Default';
	public static var watermarks:Bool = true;
	public static var ratingsDisplay:Bool = true;
	public static var gsmiss:Bool = false;
	public static var changeTBcolour:Bool = true;
	public static var greenhp:Bool = false;
	public static var newHP:Bool = true;
	public static var sarvAccuracy:Bool = false;
	public static var comboPopup:Bool = false;
	public static var wrongCamera:Bool = false;
	public static var msPopup:Bool = true;
	public static var msPrecision:Int = 2;
	public static var flinchy:Bool = true;
	public static var cutscenes:String = 'Story Mode Only';
	public static var camPanMode:String = 'Camera Focus';
	public static var mouseControls:Bool = true;
	public static var checkForUpdates:Null<Bool> = true;
	public static var comboStacking:Bool = false;
	public static var accuracyMode:String = 'Simple';
	public static var subtitles:Bool = true;
	public static var missSoundVolume:Float = 0.2;
	public static var hitSound:String = 'Hit Sound';
	public static var osuManiaSustains:Bool = false;
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
		'poison' => false,
		'sickonly' => false,
		'freeze' => false,
		'flashlight' => false,
		'quartiz' => false,
		'ghostmode' => false,
		'randommode' => false,
		'opponentplay' => false
	];

	public static var comboOffset:Array<Int> = [0, 0, 0, 0, 0, 0];
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
		'note_one1'		=> [SPACE, UP],

		'note_two1'		=> [D, LEFT],
		'note_two2'		=> [K, RIGHT],

		'note_three1'	=> [D, LEFT],
		'note_three2'	=> [SPACE, UP],
		'note_three3'	=> [K, RIGHT],

		'note_four1'	=> [A, LEFT],
		'note_four2'	=> [S, DOWN],
		'note_four3'	=> [W, UP],
		'note_four4'	=> [D, RIGHT],

		'note_five1'	=> [D, LEFT],
		'note_five2'	=> [F, DOWN],
		'note_five3'	=> [SPACE, NUMPADZERO],
		'note_five4'	=> [J, UP],
		'note_five5'	=> [K, RIGHT],

		'note_six1'		=> [S, LEFT],
		'note_six2'		=> [D, DOWN],
		'note_six3'		=> [F, NUMPADFOUR],
		'note_six4'		=> [J, NUMPADSIX],
		'note_six5'		=> [K, UP],
		'note_six6'		=> [L, RIGHT],

		'note_seven1'	=> [S, LEFT],
		'note_seven2'	=> [D, DOWN],
		'note_seven3'	=> [F, NUMPADFOUR],
		'note_seven4'	=> [SPACE, NUMPADZERO],
		'note_seven5'	=> [J, NUMPADSIX],
		'note_seven6'	=> [K, UP],
		'note_seven7'	=> [L, RIGHT],

		'note_eight1'	=> [A, LEFT],
		'note_eight2'	=> [S, DOWN],
		'note_eight3'	=> [D, UP],
		'note_eight4'	=> [F, RIGHT],
		'note_eight5'	=> [H, NUMPADFOUR],
		'note_eight6'	=> [J, NUMPADEIGHT],
		'note_eight7'	=> [K, NUMPADSIX],
		'note_eight8'	=> [L, NUMPADTWO],

		'note_nine1'	=> [A, LEFT],
		'note_nine2'	=> [S, DOWN],
		'note_nine3'	=> [D, UP],
		'note_nine4'	=> [F, RIGHT],
		'note_nine5'	=> [SPACE, NUMPADZERO],
		'note_nine6'	=> [H, NUMPADFOUR],
		'note_nine7'	=> [J, NUMPADEIGHT],
		'note_nine8'	=> [K, NUMPADSIX],
		'note_nine9'	=> [L, NUMPADTWO],
		
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

	public static function getKeyThing(array:Array<FlxKey>, ?which:Int = 0):String {
		return array[which];
	}

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		//trace(defaultKeys);
	}

	public static function saveSettings() {
		FlxG.save.data.downScroll = downScroll;
		FlxG.save.data.middleScroll = middleScroll;
		FlxG.save.data.showFPS = showFPS;
		FlxG.save.data.fullscreen = fullscreen;
		FlxG.save.data.autoPause = autoPause;
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
		FlxG.save.data.timeBarRGB = timeBarRGB;
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
		FlxG.save.data.watermarks = watermarks;
		FlxG.save.data.ratingsDisplay = ratingsDisplay;
		FlxG.save.data.gsmiss = gsmiss;
		FlxG.save.data.greenhp = greenhp;
		FlxG.save.data.newHP = newHP;
		FlxG.save.data.sarvAccuracy = sarvAccuracy;
		FlxG.save.data.comboPopup = comboPopup;
		FlxG.save.data.wrongCamera = wrongCamera;
		FlxG.save.data.msPopup = msPopup;
		FlxG.save.data.msPrecision = msPrecision;
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
		FlxG.save.data.ratingIntensity = ratingIntensity;
		FlxG.save.data.cutscenes = cutscenes;
		FlxG.save.data.camPanMode = camPanMode;
		FlxG.save.data.flinchy = flinchy;
		FlxG.save.data.mouseControls = mouseControls;
		FlxG.save.data.checkForUpdates = checkForUpdates;
		FlxG.save.data.comboStacking = comboStacking;
		FlxG.save.data.accuracyMode = accuracyMode;
		FlxG.save.data.subtitles = subtitles;
		FlxG.save.data.missSoundVolume = missSoundVolume;
		FlxG.save.data.hitSound = hitSound;
		FlxG.save.data.osuManiaSustains = osuManiaSustains;
	
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
		if(FlxG.save.data.autoPause != null) {
			autoPause = FlxG.save.data.autoPause;
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
		if(FlxG.save.data.timeBarRGB != null) {
			timeBarRGB = FlxG.save.data.timeBarRGB;
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
		if (FlxG.save.data.wrongCamera != null)
			{
				wrongCamera = FlxG.save.data.wrongCamera;
			}
		if (FlxG.save.data.msPopup != null)
			{
				msPopup = FlxG.save.data.msPopup;
			}
		if (FlxG.save.data.msPrecision != null)
			{
				msPrecision = FlxG.save.data.msPrecision;
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
		if (FlxG.save.data.comboStacking != null)
			{
				comboStacking = FlxG.save.data.comboStacking;
			}
		if (FlxG.save.data.subtitles != null)
			{
				subtitles = FlxG.save.data.subtitles;
			}
		if (FlxG.save.data.missSoundVolume != null)
			{
				missSoundVolume = FlxG.save.data.missSoundVolume;
			}
		if (FlxG.save.data.hitSound != null)
			{
				hitSound = FlxG.save.data.hitSound;
			}
		if (FlxG.save.data.osuManiaSustains != null)
			{
				osuManiaSustains = FlxG.save.data.osuManiaSustains;
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

class Keybinds
{
    public static function fill():Array<Array<Dynamic>>
    {
        return [
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_one1'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_two1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_two2'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_three3'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_four1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_four2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_four3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_four4'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_five5'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_six6'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_seven7'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_eight8'))
			],
			[
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine1')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine2')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine3')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine4')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine5')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine6')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine7')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine8')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_nine9'))
			]
		];
    }
}