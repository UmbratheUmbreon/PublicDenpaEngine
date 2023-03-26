package;

#if LUA_ALLOWED
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.State;
#end

import DialogueBoxDenpa;
import Type.ValueType;
import animateatlas.AtlasFrameMaker;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import lime.app.Application;

#if desktop
import Discord;
#end

//@sayofthelor
#if LUA_ALLOWED
using llua.Lua.Lua_helper;
#end

/**
* Class used to control Lua scripts in PlayState.
*/
class FunkinLua {
	public static var Function_Stop:Dynamic = "##LUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##LUA_FUNCTIONCONTINUE";

	#if LUA_ALLOWED
	public var lua:State = null;
	#end
	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	var gonnaClose:Bool = false;

	public function new(script:String) {
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		var result:Dynamic = LuaL.dofile(lua, script);
		var resultStr:String = Lua.tostring(lua, result);
		if(resultStr != null && result != 0) {
			Application.current.window.alert(resultStr, 'Error on .LUA script!');
			trace('Error on .LUA script! ' + resultStr);
			lua = null;
			return;
		}
		scriptName = script;
		trace('Lua file loaded succesfully:' + script);

		// just for security reasons, block some os and require functions, alongside some others
		if (lua != null){
			LuaL.dostring(lua, "
				os.execute, os.getenv, os.rename, os.remove, os.tmpname = nil, nil, nil, nil, nil
				io, load, loadfile, loadstring, dofile = nil, nil, nil, nil, nil
				require, module, package = nil, nil, nil
				setfenv, getfenv = nil, nil
				newproxy = nil
				gcinfo = nil
				debug = nil
				jit = nil
			");
		}

		// Lua shit
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.header.bpm);
		set('scrollSpeed', PlayState.SONG.options.speed);
		set('curScrollSpeed', PlayState.instance.songSpeed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.header.song);
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.assets.stage);
		set('mania', PlayState.SONG.options.mania);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);
		set('difficultyName', CoolUtil.difficulties[PlayState.storyDifficulty]);
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);
		
		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('version', Main.denpaEngineVersion.version);
		
		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);
		set('player4Section', false);

		// Gameplay settings
		set('healthGainMult', PlayState.instance.healthGain);
		set('healthLossMult', PlayState.instance.healthLoss);
		set('playbackRate', PlayState.instance.playbackRate);
		set('instakillOnMiss', PlayState.instance.instakillOnMiss);
		set('botPlay', PlayState.instance.cpuControlled);
		set('practice', PlayState.instance.practiceMode);

		for (i in 0...Note.ammo[PlayState.mania]) {
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Default character positions woooo
		set('defaultBoyfriendX', PlayState.instance.BF_X);
		set('defaultBoyfriendY', PlayState.instance.BF_Y);
		set('defaultOpponentX', PlayState.instance.DAD_X);
		set('defaultOpponentY', PlayState.instance.DAD_Y);
		set('defaultGirlfriendX', PlayState.instance.GF_X);
		set('defaultGirlfriendY', PlayState.instance.GF_Y);
		set('defaultPlayer4X', PlayState.instance.P4_X);
		set('defaultPlayer4Y', PlayState.instance.P4_Y);

		// Character shit
		set('boyfriendName', PlayState.SONG.assets.player1);
		set('dadName', PlayState.SONG.assets.player2);
		set('gfName', PlayState.SONG.assets.gfVersion);
		set('p4Name', PlayState.SONG.assets.player4);

		// Some settings, no jokes
		set('downscroll', ClientPrefs.settings.get("downsScroll"));
		set('middlescroll', ClientPrefs.settings.get("middleScroll"));
		set('framerate', ClientPrefs.settings.get("framerate"));
		set('ghostTapping', ClientPrefs.settings.get("ghostTapping"));
		set('hideHud', ClientPrefs.settings.get("hideHud"));
		set('timeBarType', ClientPrefs.settings.get("timeBarType"));
		set('scoreZoom', ClientPrefs.settings.get("scoreZoom"));
		set('cameraZoomOnBeat', ClientPrefs.settings.get("camZooms"));
		set('flashingLights', ClientPrefs.settings.get("flashing"));
		set('noteOffset', ClientPrefs.settings.get("noteOffset"));
		set('noResetButton', ClientPrefs.settings.get("noReset"));
		set('lowQuality', ClientPrefs.settings.get("lowQuality"));

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#elseif ios
		set('buildTarget', 'ios');
		#else
		set('buildTarget', 'unknown');
		#end

		lua.add_callback("addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
			var luaPath = luaFile + ".lua";
			var doPush = false;
			if(FileSystem.exists(Paths.modFolders(luaPath))) {
				luaPath = Paths.modFolders(luaPath);
				doPush = true;
			} else {
				luaPath = Paths.getPreloadPath(luaPath);
				if(FileSystem.exists(luaPath)) {
					doPush = true;
				}
			}

			if(doPush)
			{
				if(!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.instance.luaArray)
					{
						if(luaInstance.scriptName == luaPath)
						{
							luaTrace('The script "' + luaPath + '" is already running!');
							return;
						}
					}
				}
				PlayState.instance.luaArray.push(new FunkinLua(luaPath)); 
				return;
			}
			luaTrace("Script doesn't exist!");
		});

		//The better "runHaxeCode"... IF IT WORKED
		/*#if HSCRIPT_ALLOWED
		lua.add_callback("runHaxeCode", function(code_:String) {			
			haxescript.HscriptMacros.executeCode(code_);
		});
		#end*/

		lua.add_callback("removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false) { //would be dope asf. 
			var luaPath = luaFile + ".lua";
			var doPush = false;
			if(FileSystem.exists(Paths.modFolders(luaPath))) {
				luaPath = Paths.modFolders(luaPath);
				doPush = true;
			} else {
				luaPath = Paths.getPreloadPath(luaPath);
				if(FileSystem.exists(luaPath)) {
					doPush = true;
				}
			}

			if(doPush)
			{
				if(!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.instance.luaArray)
					{
						if(luaInstance.scriptName == luaPath)
						{
							//luaTrace('The script "' + luaPath + '" is already running!');
							
								PlayState.instance.luaArray.remove(luaInstance); 
							return;
						}
					}
				}
				return;
			}
			luaTrace("Script doesn't exist!");
		});
		
		lua.add_callback("loadSong", function(?name:String = null, ?difficultyNum:Int = -1) {
			if(name == null || name.length < 1)
				name = PlayState.SONG.header.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			PlayState.instance.persistentUpdate = false;
			LoadingState.globeTrans = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if(PlayState.instance.vocals != null)
			{
				PlayState.instance.vocals.pause();
				PlayState.instance.vocals.volume = 0;
			}
		});

		lua.add_callback("clearUnusedCache", function() {
			Paths.clearUnusedCache();
			return true;
		});

		lua.add_callback("loadGraphic", function(variable:String, image:String) {
			var spr:FlxSprite = cast (getObjectDirectly(variable));
			if(spr != null && image != null && image.length > 0)
			{
				spr.loadGraphic(Paths.image(image));
			}
		});

		lua.add_callback("loadFrames", function(variable:String, image:String, spriteType:String = "sparrow") {
			var spr:FlxSprite = cast (getObjectDirectly(variable));
			if(spr != null && image != null && image.length > 0)
			{
				loadFrames(spr, image, spriteType);
			}
		});

		//for cutscene shit
		lua.add_callback("cutsceneCheck", function(endCutscene:Bool = false) {
			return PlayState.instance.canIUseTheCutsceneMother(endCutscene);
		});

		//clientprefs uses a map now so you cant getPropertyFromClass. This is a workaround -AT
		lua.add_callback("getSetting", function(setting:String) {
			if (ClientPrefs.settings.exists(setting)) {
				return ClientPrefs.settings.get(setting);
			}
			luaTrace("Setting does not exist!", false, false);
			return null;
		});

		lua.add_callback("setSetting", function(setting:String, value:Dynamic) {
			ClientPrefs.settings.exists(setting) ? ClientPrefs.settings.set(setting, value) : luaTrace("Setting does not exist!", false, false);
		});
		
		lua.add_callback("getProperty", function(variable:String, ?jsonSpr:Bool = false) {
			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				if (jsonSpr)
					return Reflect.getProperty(getPropertyLoopThingWhatever(split, false, true), split[split.length-1]);
				else
					return Reflect.getProperty(getPropertyLoopThingWhatever(split), split[split.length-1]);
			}
			return Reflect.getProperty(getInstance(), variable);
		});

		lua.add_callback("setProperty", function(variable:String, value:Dynamic, ?jsonSpr:Bool = false) {
			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				if (jsonSpr)
					return Reflect.setProperty(getPropertyLoopThingWhatever(split, false, true), split[split.length-1], value);
				else
					return Reflect.setProperty(getPropertyLoopThingWhatever(split), split[split.length-1], value);
			}
			return Reflect.setProperty(getInstance(), variable, value);
		});

		lua.add_callback("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			if(Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup)) {
				return getGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable);
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj)[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					return leArray[variable];
				}
				return getGroupStuff(leArray, variable);
			}
			luaTrace('Object #$index from group: $obj doesnt exist!');
			return null;
		});

		lua.add_callback("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			if(Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup)) {
				setGroupStuff(Reflect.getProperty(getInstance(), obj).members[index], variable, value);
				return;
			}

			var leArray:Dynamic = Reflect.getProperty(getInstance(), obj)[index];
			if(leArray != null) {
				if(Type.typeof(variable) == ValueType.TInt) {
					leArray[variable] = value;
					return;
				}
				setGroupStuff(leArray, variable, value);
			}
		});

		lua.add_callback("removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false) {
			if(Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup)) {
				var object = Reflect.getProperty(getInstance(), obj).members[index];
				if(!dontDestroy)
					object.kill();
				Reflect.getProperty(getInstance(), obj).remove(object, true);
				if(!dontDestroy)
					object.destroy();
				return;
			}
			Reflect.getProperty(getInstance(), obj).remove(Reflect.getProperty(getInstance(), obj)[index]);
		});

		lua.add_callback("getPropertyFromClass", function(classVar:String, variable:String) {
			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var dynamicValue:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), split[0]);
				for (i in 1...split.length-1) {
					dynamicValue = Reflect.getProperty(dynamicValue, split[i]);
				}
				return Reflect.getProperty(dynamicValue, split[split.length-1]);
			}
			return Reflect.getProperty(Type.resolveClass(classVar), variable);
		});
		
		lua.add_callback("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic) {
			var split:Array<String> = variable.split('.');
			if(split.length > 1) {
				var dynamicValue:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), split[0]);
				for (i in 1...split.length-1) {
					dynamicValue = Reflect.getProperty(dynamicValue, split[i]);
				}
				return Reflect.setProperty(dynamicValue, split[split.length-1], value);
			}
			return Reflect.setProperty(Type.resolveClass(classVar), variable, value);
		});

		//shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		lua.add_callback("getObjectOrder", function(obj:String) {
			if(PlayState.instance.modchartSprites.exists(obj))
			{
				return getInstance().members.indexOf(PlayState.instance.modchartSprites.get(obj));
			}
			else if(PlayState.instance.modchartTexts.exists(obj))
			{
				return getInstance().members.indexOf(PlayState.instance.modchartTexts.get(obj));
			}
			else if(PlayState.instance.jsonSprites.exists(obj))
			{
				return getInstance().members.indexOf(PlayState.instance.jsonSprites.get(obj));
			}

			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if(leObj != null)
			{
				return getInstance().members.indexOf(leObj);
			}
			luaTrace('Object $obj doesnt exist!');
			return -1;
		});

		lua.add_callback("setObjectOrder", function(obj:String, position:Int) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var spr:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				if(spr.wasAdded) {
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}
			if(PlayState.instance.modchartTexts.exists(obj)) {
				var spr:ModchartText = PlayState.instance.modchartTexts.get(obj);
				if(spr.wasAdded) {
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				var spr:FlxSprite = PlayState.instance.jsonSprites.get(obj);
				if(spr != null) {
					getInstance().remove(spr, true);
				}
				getInstance().insert(position, spr);
				return;
			}

			var leObj:FlxBasic = Reflect.getProperty(getInstance(), obj);
			if(leObj != null) {
				getInstance().remove(leObj, true);
				getInstance().insert(position, leObj);
				return;
			}
			luaTrace('Object $obj doesnt exist!');
		});

		// gay ass tweens

		//i wanted to make a tween that worked with any value
		//but apparently not
		/*lua.add_callback("doTween", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			var vargo:String = vars.split('.').slice(1).join('.');
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {vargo: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});*/

		lua.add_callback("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {x: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		lua.add_callback("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {y: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		lua.add_callback("doTweenScaleX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {"scale.x": value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		lua.add_callback("doTweenScaleY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {"scale.y": value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		lua.add_callback("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {angle: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		lua.add_callback("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {alpha: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		lua.add_callback("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(object, {zoom: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		lua.add_callback("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String) {
			var object:Dynamic = tweenShit(tag, vars);
			if(object != null) {
				var color:Int = Std.parseInt(targetColor);
				if(!targetColor.startsWith('0x')) color = Std.parseInt('0xff' + targetColor);

				var curColor:FlxColor = object.color;
				curColor.alphaFloat = object.alpha;
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(object, duration / PlayState.instance.playbackRate, curColor, color, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			} else luaTrace('Couldnt find object: $vars');
		});

		//Tween shit, but for strums
		lua.add_callback("noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {x: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {y: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("noteTweenScaleX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {"scale.x": value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("noteTweenScaleY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {"scale.y": value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {angle: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {direction: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {angle: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var noteThing:Note.StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(noteThing != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(noteThing, {alpha: value}, duration / PlayState.instance.playbackRate, {ease: CoolUtil.easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		lua.add_callback("mouseClicked", function(button:String) {
			var returner = FlxG.mouse.justPressed;
			switch(button){
				case 'middle':
					returner = FlxG.mouse.justPressedMiddle;
				case 'right':
					returner = FlxG.mouse.justPressedRight;
			}
			
			
			return returner;
		});

		lua.add_callback("mousePressed", function(button:String) {
			var returner = FlxG.mouse.pressed;
			switch(button){
				case 'middle':
					returner = FlxG.mouse.pressedMiddle;
				case 'right':
					returner = FlxG.mouse.pressedRight;
			}
			return returner;
		});

		lua.add_callback("mouseReleased", function(button:String) {
			var returner = FlxG.mouse.justReleased;
			switch(button){
				case 'middle':
					returner = FlxG.mouse.justReleasedMiddle;
				case 'right':
					returner = FlxG.mouse.justReleasedRight;
			}
			return returner;
		});

		lua.add_callback("cancelTween", function(tag:String) {
			cancelTween(tag);
		});

		lua.add_callback("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			cancelTimer(tag);
			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time / PlayState.instance.playbackRate, function(tmr:FlxTimer) {
				if(tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}
				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});

		lua.add_callback("cancelTimer", function(tag:String) {
			cancelTimer(tag);
		});

		//stupid bietch ass functions
		lua.add_callback("setWindowTitle", function(value:String = "Friday Night Funkin': Denpa Engine") {
			Application.current.window.title = value;
		});

		lua.add_callback("setWindowBorderless", function(value:Bool = false) {
			Application.current.window.borderless = value;
		});

		lua.add_callback("setWindowMaximized", function(value:Bool = false) {
			Application.current.window.maximized = value;
		});

		lua.add_callback("setWindowMinimized", function(value:Bool = false) {
			Application.current.window.minimized = value;
		});
		
		lua.add_callback("setWindowFullscreen", function(value:Bool = false) {
			Application.current.window.fullscreen = value;
		});

		lua.add_callback("setWindowWidth", function(value:Int = 1280) {
			Application.current.window.width = value;
		});

		lua.add_callback("setWindowHeight", function(value:Int = 720) {
			Application.current.window.height = value;
		});

		lua.add_callback("moveWindow", function(val1:Float = 0, val2:Float = 0) {
			Application.current.window.move(Std.int(val1), Std.int(val2));
		});

		lua.add_callback("focusWindow", function() {
			Application.current.window.focus();
		});

		lua.add_callback("addScore", function(value:Int = 0) {
			PlayState.instance.songScore += value;
			PlayState.instance.recalculateRating();
		});

		lua.add_callback("addMisses", function(value:Int = 0) {
			PlayState.instance.songMisses += value;
			PlayState.instance.recalculateRating();
		});

		lua.add_callback("addHits", function(value:Int = 0) {
			PlayState.instance.songHits += value;
			PlayState.instance.recalculateRating();
		});

		lua.add_callback("setScore", function(value:Int = 0) {
			PlayState.instance.songScore = value;
			PlayState.instance.recalculateRating();
		});

		lua.add_callback("setMisses", function(value:Int = 0) {
			PlayState.instance.songMisses = value;
			PlayState.instance.recalculateRating();
		});

		lua.add_callback("setHits", function(value:Int = 0) {
			PlayState.instance.songHits = value;
			PlayState.instance.recalculateRating();
		});

		lua.add_callback("setHealth", function(value:Float = 0) {
			PlayState.instance.intendedHealth = value;
		});
		
		lua.add_callback("addHealth", function(value:Float = 0) {
			PlayState.instance.intendedHealth += value;
		});

		lua.add_callback("getHealth", function() {
			return PlayState.instance.intendedHealth;
		});

		lua.add_callback("getColorFromHex", function(color:String) {
			if(!color.startsWith('0x')) color = '0xff' + color;
			return Std.parseInt(color);
		});

		lua.add_callback("keyJustPressed", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT_P');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN_P');
				case 'up': key = PlayState.instance.getControl('NOTE_UP_P');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT_P');
				case 'accept': key = PlayState.instance.getControl('ACCEPT');
				case 'back': key = PlayState.instance.getControl('BACK');
				case 'pause': key = PlayState.instance.getControl('PAUSE');
				case 'reset': key = PlayState.instance.getControl('RESET');
				case 'space': key = FlxG.keys.justPressed.SPACE;
			}
			return key;
		});

		lua.add_callback("keyPressed", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN');
				case 'up': key = PlayState.instance.getControl('NOTE_UP');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT');
				case 'space': key = FlxG.keys.pressed.SPACE;
			}
			return key;
		});

		lua.add_callback("keyReleased", function(name:String) {
			var key:Bool = false;
			switch(name) {
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT_R');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN_R');
				case 'up': key = PlayState.instance.getControl('NOTE_UP_R');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT_R');
				case 'space': key = FlxG.keys.justReleased.SPACE;
			}
			return key;
		});

		lua.add_callback("addCharacterToList", function(name:String, type:String) {
			var charType:Int = 0;
			switch(type.toLowerCase()) {
				case 'dad': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
			PlayState.instance.addCharacterToList(name, charType);
		});

		lua.add_callback("precacheImage", function(name:String) {
			Paths.returnGraphic(name);
		});

		lua.add_callback("precacheSound", function(name:String) {
			CoolUtil.precacheSound(name);
		});

		lua.add_callback("precacheMusic", function(name:String) {
			CoolUtil.precacheMusic(name);
		});

		lua.add_callback("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic) {
			var value1:String = arg1;
			var value2:String = arg2;
			PlayState.instance.triggerEventNote(name, value1, value2);
		});

		lua.add_callback("startCountdown", function(variable:String) {
			PlayState.instance.startCountdown();
		});

		lua.add_callback("endSong", function() {
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();
		});

		lua.add_callback("restartSong", function(skipTransition:Bool) {
			PlayState.instance.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);
		});

		lua.add_callback("exitSong", function(skipTransition:Bool) {
			if(skipTransition)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();
			CustomFadeTransition.nextCamera = PlayState.instance.camOther;
			if(FlxTransitionableState.skipNextTransIn)
				CustomFadeTransition.nextCamera = null;

			if(PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
			Conductor.changeBPM(SoundTestState.playingTrackBPM);
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.instance.transitioning = true;
		});

		lua.add_callback("getSongPosition", function() {
			return Conductor.songPosition;
		});

		lua.add_callback("getCharacterX", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.x;
				default:
					return PlayState.instance.boyfriendGroup.x;
			}
		});

		lua.add_callback("setCharacterX", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.x = value;
				default:
					PlayState.instance.boyfriendGroup.x = value;
			}
		});

		lua.add_callback("getCharacterY", function(type:String) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.y;
				default:
					return PlayState.instance.boyfriendGroup.y;
			}
		});

		lua.add_callback("setCharacterY", function(type:String, value:Float) {
			switch(type.toLowerCase()) {
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.y = value;
				default:
					PlayState.instance.boyfriendGroup.y = value;
			}
		});

		lua.add_callback("cameraSetTarget", function(target:String) {
			var isDad:Bool = false;
			var focusP4:Bool = false;
			if(target == 'dad') {
				isDad = true;
			}
			if(target == 'p4') {
				focusP4 = true;
			}
			PlayState.instance.moveCamera(isDad, focusP4);
		});

		lua.add_callback("cameraShake", function(camera:String, intensity:Float, duration:Float) {
			cameraFromString(camera).shake(intensity, duration / PlayState.instance.playbackRate);
		});
		
		lua.add_callback("cameraFlash", function(camera:String, color:String, duration:Float,forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			cameraFromString(camera).flash(colorNum, duration / PlayState.instance.playbackRate,null,forced);
		});

		lua.add_callback("cameraFade", function(camera:String, color:String, duration:Float,forced:Bool) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);
			cameraFromString(camera).fade(colorNum, duration / PlayState.instance.playbackRate,false,null,forced);
		});

		lua.add_callback("setRatingPercent", function(value:Float) {
			PlayState.instance.ratingPercent = value;
		});

		lua.add_callback("setRatingName", function(value:String) {
			PlayState.instance.ratingName = value;
		});

		lua.add_callback("setRatingFC", function(value:String) {
			PlayState.instance.ratingFC = value;
		});
		
		lua.add_callback("getMouseX", function(camera:String) {
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});

		lua.add_callback("getMouseY", function(camera:String) {
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		lua.add_callback("getMidpointX", function(variable:String) {
			var obj:FlxObject = cast (getObjectDirectly(variable));
			if(obj != null) return obj.getMidpoint().x;

			return 0;
		});

		lua.add_callback("getMidpointY", function(variable:String) {
			var obj:FlxObject = cast (getObjectDirectly(variable));
			if(obj != null) return obj.getMidpoint().y;

			return 0;
		});

		lua.add_callback("getGraphicMidpointX", function(variable:String) {
			var obj:FlxSprite = cast (getObjectDirectly(variable));
			if(obj != null) return obj.getGraphicMidpoint().x;

			return 0;
		});

		lua.add_callback("getGraphicMidpointY", function(variable:String) {
			var obj:FlxSprite = cast (getObjectDirectly(variable));
			if(obj != null) return obj.getGraphicMidpoint().y;

			return 0;
		});

		lua.add_callback("getScreenPositionX", function(variable:String) {
			var obj:FlxObject = cast (getObjectDirectly(variable));
			if(obj != null) return obj.getScreenPosition().x;

			return 0;
		});
		
		lua.add_callback("getScreenPositionY", function(variable:String) {
			var obj:FlxObject = cast (getObjectDirectly(variable));
			if(obj != null) return obj.getScreenPosition().y;

			return 0;
		});

		lua.add_callback("characterDance", function(character:String) {
			switch(character.toLowerCase()) {
				case 'dad': PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend': if(PlayState.instance.gf != null) PlayState.instance.gf.dance();
				default: PlayState.instance.boyfriend.dance();
			}
		});

		lua.add_callback("makeLuaBackdrop", function(tag:String, image:String, scrollX:Float, scrollY:Float, ?repeatAxes:String = 'XY', ?spaceX:Int = 0, ?spaceY:Int = 0) {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
            var repeatArr:Array<Bool> = [true, true]; //coding this while high -AT
            switch(repeatAxes.toLowerCase()) {case 'x': repeatArr = [true, false]; case 'y': repeatArr = [false, true]; case 'none': repeatArr = [false, false];}
			var leSprite:FlxBackdrop = new FlxBackdrop(Paths.image(image), FlxAxes.fromBools(repeatArr[0], repeatArr[1]), spaceX, spaceY);
			leSprite.velocity.set(scrollX, scrollY);
			PlayState.instance.modchartBackdrops.set(tag, leSprite);
			leSprite.active = true;
		});

		lua.add_callback("addLuaBackdrop", function(tag:String, front:Bool = false) {
			if(PlayState.instance.modchartBackdrops.exists(tag)) {
				var shit:FlxBackdrop = PlayState.instance.modchartBackdrops.get(tag);
				if(front)
				{
					getInstance().add(shit);
				}
				else
				{
					if(PlayState.instance.isDead)
					{
						GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), shit);
					}
					else
					{
						var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
						if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
							position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
						} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
							position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
						}
						PlayState.instance.insert(position, shit);
					}
				}
			}
		});

		lua.add_callback("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			if(image != null && image.length > 0)
			{
				leSprite.loadGraphic(Paths.image(image));
			}
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = false;
		});

		lua.add_callback("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = tag.replace('.', '');
			resetSpriteTag(tag);
			var leSprite:ModchartSprite = new ModchartSprite(x, y);
			
			loadFrames(leSprite, image, spriteType);
			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});

		lua.add_callback("makeGraphic", function(obj:String, width:Int, height:Int, color:String) {
			var colorNum:Int = Std.parseInt(color);
			if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(object != null) {
				object.makeGraphic(width, height, colorNum);
			}
		});

		lua.add_callback("addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var object:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				object.animation.addByPrefix(name, prefix, framerate, loop);
				if(object.animation.curAnim == null) {
					object.animation.play(name, true);
				}
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				var spr:FlxSprite = PlayState.instance.jsonSprites.get(obj);
				spr.animation.addByPrefix(name, prefix, framerate, loop);
				if(spr.animation.curAnim == null) {
					spr.animation.play(name, true);
				}
				return;
			}
			
			var sprite:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(sprite != null) {
				sprite.animation.addByPrefix(name, prefix, framerate, loop);
				if(sprite.animation.curAnim == null) {
					sprite.animation.play(name, true);
				}
			}
		});

		lua.add_callback("addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			var strIndices:Array<String> = indices.trim().split(',');
			var intArray:Array<Int> = [];
			for (i in 0...strIndices.length) {
				intArray.push(Std.parseInt(strIndices[i]));
			}
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var spr:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				spr.animation.addByIndices(name, prefix, intArray, '', framerate, false);
				if(spr.animation.curAnim == null) {
					spr.animation.play(name, true);
				}
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				var spr:FlxSprite = PlayState.instance.jsonSprites.get(obj);
				spr.animation.addByIndices(name, prefix, intArray, '', framerate, false);
				if(spr.animation.curAnim == null) {
					spr.animation.play(name, true);
				}
				return;
			}
			
			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(spr != null) {
				spr.animation.addByIndices(name, prefix, intArray, '', framerate, false);
				if(spr.animation.curAnim == null) {
					spr.animation.play(name, true);
				}
			}
		});

		lua.add_callback("playAnim", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			switch (obj) {
				case 'dad' | 'opponent' | 'oppt' | 'player2' | '1':
					if(PlayState.instance.dad.animOffsets.exists(name))
						PlayState.instance.dad.playAnim(name, forced, false, startFrame);
				case 'gf' | 'girlfriend' | 'player3' | '2':
					if(PlayState.instance.gf.animOffsets.exists(name))
						PlayState.instance.gf.playAnim(name, forced, false, startFrame);
				case 'player4' | 'p4' | '3':
					if(PlayState.instance.player4.animOffsets.exists(name))
						PlayState.instance.player4.playAnim(name, forced, false, startFrame);
				case 'bf' | 'boyfriend' | 'player1' | '0':
					if(PlayState.instance.boyfriend.animOffsets.exists(name))
						PlayState.instance.boyfriend.playAnim(name, forced, false, startFrame);
				default:
					if(PlayState.instance.modchartSprites.exists(obj)) {
						var spr = PlayState.instance.modchartSprites.get(obj);
						if(spr.animation.getByName(name) != null) {
							spr.animation.play(name, forced, startFrame);
						}
						return;
					}
					if(PlayState.instance.jsonSprites.exists(obj)) {
						var spr = PlayState.instance.jsonSprites.get(obj);
						if(spr.animation.getByName(name) != null) {
							spr.animation.play(name, forced, startFrame);
						}
						return;
					}
		
					var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
					if(spr != null) {
						if(spr.animation.getByName(name) != null) {
							spr.animation.play(name, forced);
						}
						return;
					}
			}
		});
		
		lua.add_callback("setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				PlayState.instance.jsonSprites.get(obj).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if(object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});
		
		lua.add_callback("addLuaSprite", function(tag:String, front:Bool = false) {
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				if(!sprite.wasAdded) {
					if(front)
					{
						getInstance().add(sprite);
					}
					else
					{
						if(PlayState.instance.isDead)
						{
							GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.boyfriend), sprite);
						}
						else
						{
							var position:Int = PlayState.instance.members.indexOf(PlayState.instance.gfGroup);
							if(PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.boyfriendGroup);
							} else if(PlayState.instance.members.indexOf(PlayState.instance.dadGroup) < position) {
								position = PlayState.instance.members.indexOf(PlayState.instance.dadGroup);
							}
							PlayState.instance.insert(position, sprite);
						}
					}
					sprite.wasAdded = true;
				}
			}
		});

		lua.add_callback("addGlitchShader", function(tag:String, amplitude:Float, frequency:Float, speed:Float) {
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var spr:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				PlayState.instance.addGlitchShader(spr, amplitude, frequency, speed);
				return;
			}
			if(PlayState.instance.jsonSprites.exists(tag)) {
				var spr:FlxSprite = PlayState.instance.jsonSprites.get(tag);
				PlayState.instance.addGlitchShader(spr, amplitude, frequency, speed);
				return;
			}
			var spr:FlxSprite = Reflect.getProperty(getInstance(), tag);
			if(spr != null) {
				PlayState.instance.addGlitchShader(spr, amplitude, frequency, speed);
			}
		});

		lua.add_callback("setGraphicSize", function(obj:String, x:Int, y:Int = 0) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				sprite.setGraphicSize(x, y);
				sprite.updateHitbox();
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				var sprite:FlxSprite = PlayState.instance.jsonSprites.get(obj);
				sprite.setGraphicSize(x, y);
				sprite.updateHitbox();
				return;
			}

			var sprite:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(sprite != null) {
				sprite.setGraphicSize(x, y);
				sprite.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
		});

		lua.add_callback("scaleObject", function(obj:String, x:Float, y:Float, ?updateHitbox:Bool = true) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				sprite.scale.set(x, y);
				if (updateHitbox) {
					sprite.updateHitbox();
				}
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				var sprite:FlxSprite = PlayState.instance.jsonSprites.get(obj);
				sprite.scale.set(x, y);
				if (updateHitbox) {
					sprite.updateHitbox();
				}
				return;
			}

			var sprite:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(sprite != null) {
				sprite.scale.set(x, y);
				sprite.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
		});

		lua.add_callback("updateHitbox", function(obj:String) {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(obj);
				sprite.updateHitbox();
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				var sprite:FlxSprite = PlayState.instance.jsonSprites.get(obj);
				sprite.updateHitbox();
				return;
			}

			var sprite:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(sprite != null) {
				sprite.updateHitbox();
				return;
			}
			luaTrace('Couldnt find object: ' + obj);
		});

		lua.add_callback("updateHitboxFromGroup", function(group:String, index:Int) {
			if(Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup)) {
				Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
				return;
			}
			Reflect.getProperty(getInstance(), group)[index].updateHitbox();
		});

		lua.add_callback("removeLuaSprite", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartSprites.exists(tag)) {
				return;
			}
			
			var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			if(destroy) {
				sprite.kill();
			}

			if(sprite.wasAdded) {
				getInstance().remove(sprite, true);
				sprite.wasAdded = false;
			}

			if(destroy) {
				PlayState.instance.modchartSprites.remove(tag);
				sprite.destroy();
			}
		});

		lua.add_callback("luaSpriteExists", function(tag:String) {
			return PlayState.instance.modchartSprites.exists(tag);
		});

		lua.add_callback("luaTextExists", function(tag:String) {
			return PlayState.instance.modchartTexts.exists(tag);
		});

		lua.add_callback("luaSoundExists", function(tag:String) {
			return PlayState.instance.modchartSounds.exists(tag);
		});

		lua.add_callback("setHealthBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.hud.healthBar.createFilledBar(left, right);
			PlayState.instance.hud.healthBar.updateBar();
		});

		lua.add_callback("setTimeBarColors", function(leftHex:String, rightHex:String) {
			var left:FlxColor = Std.parseInt(leftHex);
			if(!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);
			var right:FlxColor = Std.parseInt(rightHex);
			if(!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.hud.timeBar.createFilledBar(right, left);
			PlayState.instance.hud.timeBar.updateBar();
		});

		lua.add_callback("setObjectCamera", function(obj:String, camera:String = '') {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}
			else if(PlayState.instance.modchartTexts.exists(obj)) {
				PlayState.instance.modchartTexts.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}
			else if(PlayState.instance.jsonSprites.exists(obj)) {
				PlayState.instance.jsonSprites.get(obj).cameras = [cameraFromString(camera)];
				return true;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);
			if(object != null) {
				object.cameras = [cameraFromString(camera)];
				return true;
			}
			luaTrace("Object " + obj + " doesn't exist!");
			return false;
		});

		lua.add_callback("setBlendMode", function(obj:String, blend:String = '') {
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).blend = CoolUtil.blendFromString(blend);
				return true;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				PlayState.instance.jsonSprites.get(obj).blend = CoolUtil.blendFromString(blend);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(spr != null) {
				spr.blend = CoolUtil.blendFromString(blend);
				return true;
			}
			luaTrace("Object " + obj + " doesn't exist!");
			return false;
		});

		lua.add_callback("screenCenter", function(obj:String, pos:String = 'xy') {
			var spr:FlxSprite;
			if(PlayState.instance.modchartSprites.exists(obj)) {
				spr = PlayState.instance.modchartSprites.get(obj);
			} else if(PlayState.instance.modchartTexts.exists(obj)) {
				spr = PlayState.instance.modchartTexts.get(obj);
			} else if(PlayState.instance.jsonSprites.exists(obj)) {
				spr = PlayState.instance.jsonSprites.get(obj);
			} else {
				spr = Reflect.getProperty(getInstance(), obj);
			}

			if(spr != null)
			{
				switch(pos.trim().toLowerCase())
				{
					case 'x':
						spr.screenCenter(X);
						return;
					case 'y':
						spr.screenCenter(Y);
						return;
					default:
						spr.screenCenter(XY);
						return;
				}
			}
			luaTrace("Object " + obj + " doesn't exist!");
		});

		lua.add_callback("setOrigin", function(obj:String, pos:String = '0,0') {
			var spr:FlxSprite;
			if(PlayState.instance.modchartSprites.exists(obj)) {
				spr = PlayState.instance.modchartSprites.get(obj);
			} else if(PlayState.instance.modchartTexts.exists(obj)) {
				spr = PlayState.instance.modchartTexts.get(obj);
			} else if(PlayState.instance.jsonSprites.exists(obj)) {
				spr = PlayState.instance.jsonSprites.get(obj);
			} else {
				spr = Reflect.getProperty(getInstance(), obj);
			}

			if(spr != null)
			{
				var split = pos.trim().toLowerCase().split(',');
				var x = Std.parseFloat(split[0]);
				var y = Std.parseFloat(split[1]);
				spr.origin.set(x,y);
				return;
			}
			luaTrace("Object " + obj + " doesn't exist!");
		});

		lua.add_callback("objectsOverlap", function(obj1:String, obj2:String) {
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];
			for (i in 0...namesArray.length)
			{
				if(PlayState.instance.modchartSprites.exists(namesArray[i])) {
					objectsArray.push(PlayState.instance.modchartSprites.get(namesArray[i]));
				}
				else if(PlayState.instance.modchartTexts.exists(namesArray[i])) {
					objectsArray.push(PlayState.instance.modchartTexts.get(namesArray[i]));
				}
				else if(PlayState.instance.jsonSprites.exists(namesArray[i])) {
					objectsArray.push(PlayState.instance.jsonSprites.get(namesArray[i]));
				}
				else {
					objectsArray.push(Reflect.getProperty(getInstance(), namesArray[i]));
				}
			}

			if(!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1]))
			{
				return true;
			}
			return false;
		});

		lua.add_callback("getPixelColor", function(obj:String, x:Int, y:Int) {
			var spr:FlxSprite = null;
			if(PlayState.instance.modchartSprites.exists(obj)) {
				spr = PlayState.instance.modchartSprites.get(obj);
			} else if(PlayState.instance.modchartTexts.exists(obj)) {
				spr = PlayState.instance.modchartTexts.get(obj);
			} else if(PlayState.instance.jsonSprites.exists(obj)) {
				spr = PlayState.instance.jsonSprites.get(obj);
			} else {
				spr = Reflect.getProperty(getInstance(), obj);
			}

			if(spr != null)
			{
				if(spr.framePixels != null) spr.framePixels.getPixel32(x, y);
				return spr.pixels.getPixel32(x, y);
			}
			return 0;
		});

		lua.add_callback("getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}
			return FlxG.random.int(min, max, toExclude);
		});
		
		lua.add_callback("getRandomFloat", function(min:Float, max:Float = 1, exclude:String = '') {
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];
			for (i in 0...excludeArray.length)
			{
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}
			return FlxG.random.float(min, max, toExclude);
		});
		lua.add_callback("getRandomBool", function(chance:Float = 50) {
			return FlxG.random.bool(chance);
		});

		lua.add_callback("startDialogue", function(dialogueFile:String, music:String = null) {
			var path:String = Paths.modsJson(Paths.formatToSongPath(PlayState.SONG.header.song) + '/' + dialogueFile);
			if(!FileSystem.exists(path)) {
				path = Paths.json(Paths.formatToSongPath(PlayState.SONG.header.song) + '/' + dialogueFile);
			}
			luaTrace('Trying to load dialogue: ' + path);

			if(FileSystem.exists(path)) {
				var shit:DialogueFile = DialogueBoxDenpa.parseDialogue(path);
				if(shit.dialogue.length > 0) {
					PlayState.instance.startDialogue(shit, music);
					luaTrace('Successfully loaded dialogue');
				} else {
					luaTrace('Your dialogue file is badly formatted!');
				}
			} else {
				luaTrace('Dialogue file not found');
				if(PlayState.instance.endingSong) {
					PlayState.instance.endSong();
				} else {
					PlayState.instance.startCountdown();
				}
			}
		});
		
		lua.add_callback("startVideo", function(videoFile:String) {
			#if VIDEOS_ALLOWED
			if(FileSystem.exists(Paths.video(videoFile))) {
				PlayState.instance.startVideo(videoFile);
				return true;
			} else {
				luaTrace('startVideo: Video file not found: ' + videoFile, false, false);
			}
			return false;

			#else
			if(PlayState.instance.endingSong) {
				PlayState.instance.endSong();
			} else {
				PlayState.instance.startCountdown();
			}
			return true;
			#end
		});
		
		lua.add_callback("playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});

		lua.add_callback("playSound", function(sound:String, volume:Float = 1, ?tag:String = null) {
			if(tag != null && tag.length > 0) {
				tag = tag.replace('.', '');
				if(PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).stop();
				}
				PlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
					PlayState.instance.modchartSounds.remove(tag);
					PlayState.instance.callOnLuas('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});

		lua.add_callback("stopSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});

		lua.add_callback("pauseSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});

		lua.add_callback("resumeSound", function(tag:String) {
			if(tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});

		lua.add_callback("soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration / PlayState.instance.playbackRate, fromValue, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration / PlayState.instance.playbackRate, fromValue, toValue);
			}
			
		});

		lua.add_callback("soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0) {
			if(tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration / PlayState.instance.playbackRate, toValue);
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration / PlayState.instance.playbackRate, toValue);
			}
		});

		lua.add_callback("soundFadeCancel", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound.fadeTween != null) {
					theSound.fadeTween.cancel();
					PlayState.instance.modchartSounds.remove(tag);
				}
			}
		});

		lua.add_callback("getSoundVolume", function(tag:String) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null) {
					return FlxG.sound.music.volume;
				}
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				return PlayState.instance.modchartSounds.get(tag).volume;
			}
			return 0;
		});

		lua.add_callback("setSoundVolume", function(tag:String, value:Float) {
			if(tag == null || tag.length < 1) {
				if(FlxG.sound.music != null) {
					FlxG.sound.music.volume = value;
				}
			} else if(PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).volume = value;
			}
		});

		lua.add_callback("getSoundTime", function(tag:String) {
			if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
				return PlayState.instance.modchartSounds.get(tag).time;
			}
			return 0;
		});

		lua.add_callback("setSoundTime", function(tag:String, value:Float) {
			if(tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);
				if(theSound != null) {
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if(wasResumed) theSound.play();
				}
			}
		});

		lua.add_callback("debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = '') {
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';
			luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
		});

		lua.add_callback("close", function(printMessage:Bool) {
			if(!gonnaClose) {
				if(printMessage) {
					luaTrace('Stopping lua script: ' + scriptName);
				}
				PlayState.instance.closeLuas.push(this);
			}
			gonnaClose = true;
		});

		lua.add_callback("changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			#if desktop
			DiscordClient.changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			#else
			luaTrace('Platform does not support Discord client change presence.');
			#end
		});

		// LUA TEXTS
		lua.add_callback("makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = tag.replace('.', '');
			resetTextTag(tag);
			var leText:ModchartText = new ModchartText(x, y, text, width);
			PlayState.instance.modchartTexts.set(tag, leText);
		});

		lua.add_callback("setTextString", function(tag:String, text:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.text = text;
			}
		});

		lua.add_callback("setTextSize", function(tag:String, size:Int) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.size = size;
			}
		});

		lua.add_callback("setTextWidth", function(tag:String, width:Float) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.fieldWidth = width;
			}
		});

		lua.add_callback("setTextBorder", function(tag:String, size:Int, color:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.borderSize = size;
				obj.borderColor = colorNum;
			}
		});

		lua.add_callback("setTextColor", function(tag:String, color:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.color = colorNum;
			}
		});

		lua.add_callback("setTextFont", function(tag:String, newFont:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.font = Paths.font(newFont);
			}
		});

		lua.add_callback("setTextItalic", function(tag:String, italic:Bool) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.italic = italic;
			}
		});

		lua.add_callback("setTextAlignment", function(tag:String, alignment:String = 'left') {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				obj.alignment = LEFT;
				switch(alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}
			}
		});

		lua.add_callback("getTextString", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				return obj.text;
			}
			return null;
		});

		lua.add_callback("getTextSize", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				return obj.size;
			}
			return -1;
		});

		lua.add_callback("getTextFont", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				return obj.font;
			}
			return null;
		});

		lua.add_callback("getTextWidth", function(tag:String) {
			var obj:FlxText = getTextObject(tag);
			if(obj != null)
			{
				return obj.fieldWidth;
			}
			return 0;
		});

		lua.add_callback("addLuaText", function(tag:String) {
			if(PlayState.instance.modchartTexts.exists(tag)) {
				var shit:ModchartText = PlayState.instance.modchartTexts.get(tag);
				if(!shit.wasAdded) {
					getInstance().add(shit);
					shit.wasAdded = true;
				}
			}
		});

		lua.add_callback("removeLuaText", function(tag:String, destroy:Bool = true) {
			if(!PlayState.instance.modchartTexts.exists(tag)) {
				return;
			}
			
			var text:ModchartText = PlayState.instance.modchartTexts.get(tag);
			if(destroy) {
				text.kill();
			}

			if(text.wasAdded) {
				getInstance().remove(text, true);
				text.wasAdded = false;
			}

			if(destroy) {
				PlayState.instance.modchartTexts.remove(tag);
				text.destroy();
			}
		});

		lua.add_callback("initSaveData", function(name:String, ?folder:String = 'denpaenginemods') {
			if(!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				save.bind(name);
				PlayState.instance.modchartSaves.set(name, save);
				return;
			}
			luaTrace('Save file already initialized: ' + name);
		});

		lua.add_callback("flushSaveData", function(name:String) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}
			luaTrace('Save file not initialized: ' + name);
		});

		lua.add_callback("getDataFromSave", function(name:String, field:String) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				var retVal:Dynamic = Reflect.field(PlayState.instance.modchartSaves.get(name).data, field);
				return retVal;
			}
			luaTrace('Save file not initialized: ' + name);
			return null;
		});

		lua.add_callback("setDataFromSave", function(name:String, field:String, value:Dynamic) {
			if(PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}
			luaTrace('Save file not initialized: ' + name);
		});
		
		lua.add_callback("getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false) {
			return Paths.getTextFromFile(path, ignoreModFolders);
		});

		lua.add_callback("stringStartsWith", function(str:String, start:String) {
			return str.startsWith(start);
		});

		lua.add_callback("stringEndsWith", function(str:String, end:String) {
			return str.endsWith(end);
		});

		lua.add_callback("stringSplit", function(str:String, split:String) {
			return str.split(split);
		});

		lua.add_callback("stringTrim", function(str:String) {
			return str.trim();
		});
		
		lua.add_callback("directoryFileList", function(folder:String) {
			var list:Array<String> = [];
			#if sys
			if(FileSystem.exists(folder)) {
				for (folder in FileSystem.readDirectory(folder)) {
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end
			return list;
		});

		// DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		lua.add_callback("getStageProperty", function(variable:String) {
			luaTrace("getStageProperty is deprecated! Use getProperty instead", false, true);
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				return Reflect.getProperty(getPropertyLoopThingWhatever(killMe, false, true), killMe[killMe.length-1]);
			}
			return Reflect.getProperty(getInstance(), variable);
		});

		lua.add_callback("setStageProperty", function(variable:String, value:Dynamic) {
			luaTrace("setStageProperty is deprecated! Use setProperty instead", false, true);
			var killMe:Array<String> = variable.split('.');
			if(killMe.length > 1) {
				return Reflect.setProperty(getPropertyLoopThingWhatever(killMe, false, true), killMe[killMe.length-1], value);
			}
			return Reflect.setProperty(getInstance(), variable, value);
		});

		lua.add_callback("luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String) {
			luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var colorNum:Int = Std.parseInt(color);
				if(!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});

		lua.add_callback("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if(cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		lua.add_callback("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if(pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});

		lua.add_callback("objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0) {
			luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.modchartSprites.exists(obj)) {
				PlayState.instance.modchartSprites.get(obj).animation.play(name, forced, startFrame);
				return;
			}
			if(PlayState.instance.jsonSprites.exists(obj)) {
				PlayState.instance.jsonSprites.get(obj).animation.play(name, forced, startFrame);
				return;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);
			if(spr != null) {
				spr.animation.play(name, forced);
			}
		});
		
		lua.add_callback("characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false) {
			luaTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent':
					if(PlayState.instance.dad.animOffsets.exists(anim))
						PlayState.instance.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if(PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists(anim))
						PlayState.instance.gf.playAnim(anim, forced);
				case 'p4' | 'player4':
					if(PlayState.instance.player4 != null && PlayState.instance.player4.animOffsets.exists(anim))
						PlayState.instance.player4.playAnim(anim, forced);
				default: 
					if(PlayState.instance.boyfriend.animOffsets.exists(anim))
						PlayState.instance.boyfriend.playAnim(anim, forced);
			}
		});
		
		lua.add_callback("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false) {
			luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});

		lua.add_callback("setLuaSpriteCamera", function(tag:String, camera:String = '') {
			luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).cameras = [cameraFromString(camera)];
				return true;
			}
			luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
			return false;
		});

		lua.add_callback("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float) {
			luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
			}
		});

		lua.add_callback("scaleLuaSprite", function(tag:String, x:Float, y:Float) {
			luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var shit:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				shit.scale.set(x, y);
				shit.updateHitbox();
			}
		});

		lua.add_callback("getPropertyLuaSprite", function(tag:String, variable:String) {
			luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
				}
				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}
			return null;
		});

		lua.add_callback("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic) {
			luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);
			if(PlayState.instance.modchartSprites.exists(tag)) {
				var killMe:Array<String> = variable.split('.');
				if(killMe.length > 1) {
					var coverMeInPiss:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), killMe[0]);
					for (i in 1...killMe.length-1) {
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
				}
				return Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
			}
			luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");
		});

		lua.add_callback("musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			FlxG.sound.music.fadeIn(duration / PlayState.instance.playbackRate, fromValue, toValue);
			luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);

		});

		lua.add_callback("musicFadeOut", function(duration:Float, toValue:Float = 0) {
			FlxG.sound.music.fadeOut(duration / PlayState.instance.playbackRate, toValue);
			luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});
		
		call('onCreate', []);
		#end
	}

	//should be better than copy pasting the same code
	//needs more testing
	function getObject(name:String, ?luaSprites:Bool = true, ?luaBackdrops:Bool = true, ?luaTexts:Bool = true, ?jsonSprites:Bool = true, ?playStateObjects:Bool = true):Dynamic
	{
		if (luaSprites) {
			if(PlayState.instance.modchartSprites.exists(name)) {
				return PlayState.instance.modchartSprites.get(name);
			}
		}
		if (luaBackdrops) {
			if(PlayState.instance.modchartBackdrops.exists(name)) {
				return PlayState.instance.modchartBackdrops.get(name);
			}
		}
		if (luaTexts) {
			if(PlayState.instance.modchartTexts.exists(name)) {
				return PlayState.instance.modchartTexts.get(name);
			}
		}
		if (jsonSprites) {
			if(PlayState.instance.jsonSprites.exists(name)) {
				return PlayState.instance.jsonSprites.get(name);
			}
		}
		if (playStateObjects) {
			return Reflect.getProperty(getInstance(), name);
		}
		return null;
	}

	inline static function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	function getGroupStuff(leArray:Dynamic, variable:String) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			return Reflect.getProperty(coverMeInPiss, killMe[killMe.length-1]);
		}
		return Reflect.getProperty(leArray, variable);
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String)
	{
		switch(spriteType.toLowerCase().trim())
		{	
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image);
				
			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);
				
			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);
			
			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic) {
		var killMe:Array<String> = variable.split('.');
		if(killMe.length > 1) {
			var coverMeInPiss:Dynamic = Reflect.getProperty(leArray, killMe[0]);
			for (i in 1...killMe.length-1) {
				coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
			}
			Reflect.setProperty(coverMeInPiss, killMe[killMe.length-1], value);
			return;
		}
		Reflect.setProperty(leArray, variable, value);
	}

	function resetTextTag(tag:String) {
		if(!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}
		
		var text:ModchartText = PlayState.instance.modchartTexts.get(tag);
		text.kill();
		if(text.wasAdded) {
			PlayState.instance.remove(text, true);
		}
		text.destroy();
		PlayState.instance.modchartTexts.remove(tag);
	}

	function resetSpriteTag(tag:String) {
		if (PlayState.instance.modchartSprites.exists(tag)) {
			var spr:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
			spr.kill();
			if(spr.wasAdded) {
				PlayState.instance.remove(spr, true);
			}
			spr.destroy();
			PlayState.instance.modchartSprites.remove(tag);
			return;
		}
		if (PlayState.instance.modchartBackdrops.exists(tag)) {
			var backdr:FlxBackdrop = PlayState.instance.modchartBackdrops.get(tag);
			backdr.kill();
			if(backdr != null) {
				PlayState.instance.remove(backdr, true);
			}
			backdr.destroy();
			PlayState.instance.modchartBackdrops.remove(tag);
			return;
		}
	}

	function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}
	
	function tweenShit(tag:String, vars:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.replace(' ', '').split('.');
		var obj:Dynamic = Reflect.getProperty(getInstance(), variables[0]);
		if(PlayState.instance.modchartSprites.exists(variables[0])) {
			obj = PlayState.instance.modchartSprites.get(variables[0]);
		}
		if(PlayState.instance.modchartTexts.exists(variables[0])) {
			obj = PlayState.instance.modchartTexts.get(variables[0]);
		}
		if(PlayState.instance.jsonSprites.exists(variables[0])) {
			obj = PlayState.instance.jsonSprites.get(variables[0]);
		}

		for (i in 1...variables.length) {
			obj = Reflect.getProperty(obj, variables[i]);
		}
		return obj;
	}

	function cancelTimer(tag:String) {
		if(PlayState.instance.modchartTimers.exists(tag)) {
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();
			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	function cameraFromString(cam:String):FlxCamera {
		switch(cam.toLowerCase()) {
			case 'camgame' | 'game': return PlayState.instance.camGame;
			case 'camtint' | 'tint': return PlayState.instance.camTint;
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		return PlayState.instance.camGame;
	}

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false) {
		#if LUA_ALLOWED
		if(ignoreCheck || getBool('luaDebugMode')) {
			if(deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}
			PlayState.instance.addTextToDebug(text);
			trace(text);
		}
		#end
	}
	
	public function call(event:String, args:Array<Dynamic>):Dynamic {
		#if LUA_ALLOWED
		if(lua == null) return Function_Continue;

		Lua.getglobal(lua, event);

		for (arg in args) Convert.toLua(lua, arg);

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);
		if(result != null && resultIsAllowed(lua, result)) {
			/*var resultStr:String = Lua.tostring(lua, result);
			var error:String = Lua.tostring(lua, -1);
			Lua.pop(lua, 1);*/
			if(Lua.type(lua, -1) == Lua.LUA_TSTRING) {
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if(error == 'attempt to call a nil value') { //Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
					return Function_Continue;
				}
			}

			var conv:Dynamic = Convert.fromLua(lua, result);
			return conv;
		}
		#end
		return Function_Continue;
	}

	function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?jsonSprite:Bool = false):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo, jsonSprite);
		for (i in 1...killMe.length-1) {
			coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
		}
		return coverMeInPiss;
	}

	function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true, ?jsonSprite:Bool = false):Dynamic
	{
		var coverMeInPiss:Dynamic = null;
		if(jsonSprite && PlayState.instance.jsonSprites.exists(objectName)) {
			coverMeInPiss = PlayState.instance.jsonSprites.get(objectName);
			return coverMeInPiss;
		}

		if(PlayState.instance.modchartSprites.exists(objectName))
			coverMeInPiss = PlayState.instance.modchartSprites.get(objectName);
		else if(checkForTextsToo && PlayState.instance.modchartTexts.exists(objectName))
			coverMeInPiss = PlayState.instance.modchartTexts.get(objectName);
		else
			coverMeInPiss = Reflect.getProperty(getInstance(), objectName);

		return coverMeInPiss;
	}

	#if LUA_ALLOWED
	function resultIsAllowed(leLua:State, leResult:Null<Int>) { //Makes it ignore warnings
		switch(Lua.type(leLua, leResult)) {
			case Lua.LUA_TNIL | Lua.LUA_TBOOLEAN | Lua.LUA_TNUMBER | Lua.LUA_TSTRING | Lua.LUA_TTABLE:
				return true;
		}
		return false;
	}
	#end

	public function set(variable:String, data:Dynamic) {
		#if LUA_ALLOWED
		if(lua == null) return;

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	#if LUA_ALLOWED
	public function getBool(variable:String) {
		var result:String = null;
		Lua.getglobal(lua, variable);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if(result == null) return false;
		return (result == 'true');
	}
	#end

	public function stop() {
		#if LUA_ALLOWED
		if(lua == null) return;

		Lua.close(lua);
		lua = null;
		#end
	}

	inline function getInstance()
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
	}
}

class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, text:String, width:Float)
	{
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

class DebugLuaText extends FlxText
{
	private var disableTime:Float = 6;
	public var parentGroup:FlxTypedGroup<DebugLuaText>; 
	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>) {
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		disableTime -= elapsed;
		if(disableTime <= 0) {
			kill();
			parentGroup.remove(this);
			destroy();
		}
		else if(disableTime < 1) alpha = disableTime;
	}
	
}
