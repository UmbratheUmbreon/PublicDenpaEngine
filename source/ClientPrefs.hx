package;

import Controls;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSave;
import lime.app.Application;

/**
* Class containing all settings.
* Automatically saves and loads.
*/
class ClientPrefs {
	public static var settings:Map<String, Dynamic> = [
        //Name, Value
        //Bools
        "downScroll" => false,
        "middleScroll" => false,
        "showFPS" => #if debug true, #else false, #end
        "autoPause" => true,
        "flashing" => true,
        "globalAntialiasing" => true,
        "noteSplashes" => true,
        "lowQuality" => false,
		"animateMouse" => true,
        "camZooms" => true,
        "camPans" => true,
        "hideHud" => false,
        "ghostTapping" => true,
        "scoreZoom" => true,
        "noReset" => true,
        "watermarks" => true,
        "ratingsDisplay" => false,
        "gsMiss" => false,
        "ogHp" => false,
        "wrongCamera" => false,
        "msPopup" => true,
        "flinching" => true,
		"disableBotIcon" => false,
        "checkForUpdates" => true,
        "subtitles" => true,
		"complexAccuracy" => false,
        //Ints
        "framerate" => 60,
        "noteOffset" => 0,
        "ratingOffset" => 0,
        "perfectWindow" => 15,
        "sickWindow" => 45,
        "goodWindow" => 90,
        "badWindow" => 135,
        "shitWindow" => 180,
        //Floats
        "hitsoundVolume" => 0,
        "safeFrames" => 10,
        //Strings
		"resolution" => "1280x720",
        "uiSkin" => "FNF",
        "iconAnim" => "Swing",
        "scoreDisplay" => "Psych",
        "timeBarType" => "Time Left",
        "pauseMusic" => "OVERDOSE",
        "ratingIntensity" => "Default",
        "cutscenes" => "Story Mode Only",
		//Arrays
		"crossFadeData" => ['Default', 'Healthbar', [255, 255, 255], 0.3, 0.35]
	];

	public static var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
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
		'flip' => false,
		'opponentplay' => false
	];

	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];
	public static var comboOffset:Array<Int> = [0, 0, 0, 0, 0, 0];

	//Every key has two binds, default, and alt.
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_41'	=> [D],
		'note_42'	=> [F],
		'note_43'	=> [J],
		'note_44'	=> [K], //who actually used WASD by choice
		
		'ui_left'	=> [LEFT],
		'ui_down'	=> [DOWN],
		'ui_up'		=> [UP],
		'ui_right'	=> [RIGHT],
		
		'accept'	=> [SPACE, ENTER],
		'back'		=> [BACKSPACE, ESCAPE],
		'pause'		=> [ENTER, ESCAPE],
		'reset'		=> [R],
		
		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'	=> [SEVEN],
		'debug_2'	=> [EIGHT],
		'debug_3'	=> [F3],
		'debug_4'	=> [F4],

		'manual'	=> [F12],

		'note_11'	=> [SPACE, UP],

		'note_21'	=> [D, LEFT],
		'note_22'	=> [K, RIGHT],

		'note_31'	=> [D, LEFT],
		'note_32'	=> [SPACE, UP],
		'note_33'	=> [K, RIGHT],

		'note_51'	=> [D, LEFT],
		'note_52'	=> [F, DOWN],
		'note_53'	=> [SPACE, NUMPADZERO],
		'note_54'	=> [J, UP],
		'note_55'	=> [K, RIGHT],

		'note_61'	=> [S, LEFT],
		'note_62'	=> [D, DOWN],
		'note_63'	=> [F, NUMPADFOUR],
		'note_64'	=> [J, NUMPADSIX],
		'note_65'	=> [K, UP],
		'note_66'	=> [L, RIGHT],

		'note_71'	=> [S, LEFT],
		'note_72'	=> [D, DOWN],
		'note_73'	=> [F, NUMPADFOUR],
		'note_74'	=> [SPACE, NUMPADZERO],
		'note_75'	=> [J, NUMPADSIX],
		'note_76'	=> [K, UP],
		'note_77'	=> [L, RIGHT],

		'note_81'	=> [A, LEFT],
		'note_82'	=> [S, DOWN],
		'note_83'	=> [D, UP],
		'note_84'	=> [F, RIGHT],
		'note_85'	=> [H, NUMPADFOUR],
		'note_86'	=> [J, NUMPADEIGHT],
		'note_87'	=> [K, NUMPADSIX],
		'note_88'	=> [L, NUMPADTWO],

		'note_91'	=> [A, LEFT],
		'note_92'	=> [S, DOWN],
		'note_93'	=> [D, UP],
		'note_94'	=> [F, RIGHT],
		'note_95'	=> [SPACE, NUMPADZERO],
		'note_96'	=> [H, NUMPADFOUR],
		'note_97'	=> [J, NUMPADEIGHT],
		'note_98'	=> [K, NUMPADSIX],
		'note_99'	=> [L, NUMPADTWO]
	];

	//gamepad keybinds yeye
	//TODO: though, they arent programmed into the actual playstate yet
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_41'	=> [X, DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT],
		'note_42'	=> [A, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN],
		'note_43'	=> [Y, DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
		'note_44'	=> [B, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT],
		
		'ui_left'	=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'	=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_up'		=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_right'	=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'	=> [A, START],
		'back'		=> [B, BACK],
		'pause'		=> [START],
		'reset'		=> [LEFT_STICK_CLICK],

		'note_11'	=> [Y, DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],

		'note_21'	=> [X, DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT],
		'note_22'	=> [B, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT],

		'note_31'	=> [X, DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT],
		'note_32'	=> [Y, DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
		'note_33'	=> [B, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT],

		'note_51'	=> [X, DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT],
		'note_52'	=> [A, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN],
		'note_53'	=> [LEFT_STICK_CLICK, RIGHT_STICK_CLICK], //Kinda hard to figure out??
		'note_54'	=> [Y, DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
		'note_55'	=> [B, DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT],

		'note_61'	=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'note_62'	=> [A, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN],
		'note_63'	=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		'note_64'	=> [X, RIGHT_STICK_DIGITAL_LEFT],
		'note_65'	=> [Y, DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
		'note_66'	=> [B, RIGHT_STICK_DIGITAL_RIGHT],

		'note_71'	=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'note_72'	=> [A, DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN],
		'note_73'	=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		'note_74'	=> [LEFT_STICK_CLICK, RIGHT_STICK_CLICK],
		'note_75'	=> [X, RIGHT_STICK_DIGITAL_LEFT],
		'note_76'	=> [Y, DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
		'note_77'	=> [B, RIGHT_STICK_DIGITAL_RIGHT],

		'note_81'	=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'note_82'	=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'note_83'	=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'note_84'	=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		'note_85'	=> [X, RIGHT_STICK_DIGITAL_LEFT],
		'note_86'	=> [A, RIGHT_STICK_DIGITAL_DOWN],
		'note_87'	=> [Y, RIGHT_STICK_DIGITAL_UP],
		'note_88'	=> [B, RIGHT_STICK_DIGITAL_RIGHT],

		'note_91'	=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'note_92'	=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'note_93'	=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'note_94'	=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		'note_95'	=> [LEFT_STICK_CLICK, RIGHT_STICK_CLICK],
		'note_96'	=> [X, RIGHT_STICK_DIGITAL_LEFT],
		'note_97'	=> [A, RIGHT_STICK_DIGITAL_DOWN],
		'note_98'	=> [Y, RIGHT_STICK_DIGITAL_UP],
		'note_99'	=> [B, RIGHT_STICK_DIGITAL_RIGHT]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static var controllerEnabled:Bool = false; //we use this shit to make sure not to check for controller inputs unless needed
	private static var controlsPostfix:String = '_';
	private static var FORCE_CASE_SENSITIVITY:Bool = false;
	/**
	* Returns a `Bool` dictating whether a specific keybind is pressed/released.
	* 
	* @param keyToCheck `String` dictating the key that will be checked. Adding `_p` to the end of the key name checks for just pressed, and adding `_r` checks for just released. Otherwise, pressed will be checked
	*/
	public static function control(keyToCheck:String):Bool {
		final individualKey:Array<String> = FORCE_CASE_SENSITIVITY ? keyToCheck.split(controlsPostfix) : keyToCheck.toLowerCase().split(controlsPostfix);
		final pureBindName:String = individualKey.join(controlsPostfix).replace(controlsPostfix + individualKey[individualKey.length-1], '');
		final keyArray:Array<FlxKey> = keyBinds.get(pureBindName);
		final gamepadArray:Array<FlxGamepadInputID> = (gamepadBinds.exists(pureBindName) ? gamepadBinds.get(pureBindName) : [NONE]);

		final check = individualKey[individualKey.length-1].toLowerCase();
		switch(check) {
			case 'p': return (FlxG.keys.anyJustPressed(keyArray) ? true : getGamepad(gamepadArray, check));
			case 'r': return (FlxG.keys.anyJustReleased(keyArray) ? true : getGamepad(gamepadArray, check));
			default:  return (FlxG.keys.anyPressed(keyArray) ? true : getGamepad(gamepadArray, check));
		}
		return false;
	}

	private static function getGamepad(keys:Array<FlxGamepadInputID>, check:String):Bool
	{
		if (keys == null || keys.contains(NONE)) return false;
		for (key in keys)
		{
			//may look strange but this is bcs you cant do anyJustPressed and shit on gamepads
			//it doesnt return false because that would break the loop and return early
			switch(check) {
				case 'p':
					if (FlxG.gamepads.anyJustPressed(key)) {
						return true;
					}
				case 'r':
					if (FlxG.gamepads.anyJustReleased(key)) {
						return true;
					}
				default: 
					if (FlxG.gamepads.anyPressed(key)) {
						return true;
					}
			}
		}
		return false;
	}

	//for why?
	inline public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
	}

	public static function saveSettings() {
		var settingsSave:FlxSave = new FlxSave();
		settingsSave.bind('settings');
		settingsSave.data.arrowHSV = arrowHSV;
		settingsSave.data.comboOffset = comboOffset;
		settingsSave.data.settings = settings;
		settingsSave.data.gameplaySettings = gameplaySettings;
		settingsSave.flush();

		var controlsSave:FlxSave = new FlxSave();
		controlsSave.bind('controls_v3'); //Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		controlsSave.data.customControls = keyBinds;
		controlsSave.flush();

		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		var settingsSave:FlxSave = new FlxSave();
		settingsSave.bind('settings');

		if (settingsSave != null) {
			//something about settings.set
			if(settingsSave.data.settings != null)
			{
				var savedMap:Map<String, Dynamic> = settingsSave.data.settings;
				for (name => value in savedMap)
				{
					switch(name) {
						case "framerate":
							//need to do this because flixel big weird
							if(value > FlxG.drawFramerate) {
								FlxG.updateFramerate = value;
								FlxG.drawFramerate = value;
							} else {
								FlxG.drawFramerate = value;
								FlxG.updateFramerate = value;
							}
						case "globalAntialiasing": 
							flixel.FlxSprite.defaultAntialiasing = value;
							FlxG.mouse.unload();
							flixel.input.mouse.FlxMouse.antialiasing = value;
							FlxG.mouse.load();
						case "animateMouse": flixel.input.mouse.FlxMouse.animated = value;
						case "resolution":
							var val = cast (value, String);
							var split = val.split("x");
							CoolUtil.resetResolutionScaling(Std.parseInt(split[0]), Std.parseInt(split[1]));
							FlxG.resizeGame(Std.parseInt(split[0]), Std.parseInt(split[1]));
							Application.current.window.width = Std.parseInt(split[0]);
							Application.current.window.height = Std.parseInt(split[1]);
						#if !html5
						case "autoPause": FlxG.autoPause = value;
						#end
					}
					settings.set(name, value);
				}
			}

			if(settingsSave.data.gameplaySettings != null)
			{
				var savedMap:Map<String, Dynamic> = settingsSave.data.gameplaySettings;
				for (name => value in savedMap)
				{
					gameplaySettings.set(name, value);
				}
			}

			if (settingsSave.data.arrowHSV != null) arrowHSV = settingsSave.data.arrowHSV;
			if (settingsSave.data.comboOffset != null) comboOffset = settingsSave.data.comboOffset;
		}

		var controlsSave:FlxSave = new FlxSave();
		controlsSave.bind('controls_v3');
		if(controlsSave != null && controlsSave.data.customControls != null) {
			var loadedControls:Map<String, Array<FlxKey>> = controlsSave.data.customControls;
			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
			reloadControls();
		}
		
		// flixel automatically saves your volume!
		if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic {
		return (gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadControls() {
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);
		InitState.muteKeys = keyBinds.get('volume_mute').copy();
		InitState.volumeDownKeys = keyBinds.get('volume_down').copy();
		InitState.volumeUpKeys = keyBinds.get('volume_up').copy();
		FlxG.sound.muteKeys = InitState.muteKeys;
		FlxG.sound.volumeDownKeys = InitState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = InitState.volumeUpKeys;
	}

	inline public static function fillKeys():Array<Array<Dynamic>>
    {
        var returArr:Array<Array<Dynamic>> = [];
        var tempArr:Array<Dynamic> = [];
        for (i in 1...10) {
            for (j in 1...i+1) {
                tempArr.push(keyBinds.get('note_$i$j').copy());
            }
            returArr.push(tempArr);
            tempArr = [];
        }
        return returArr;
    }
}
