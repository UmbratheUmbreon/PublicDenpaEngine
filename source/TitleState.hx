package;

import flixel.graphics.frames.FlxFrame;
#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import options.OptionsSubState.GraphicsSettingsSubState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import Shaders.ColorSwap;

using StringTools;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	gfscalex:Float,
	gfscaley:Float,
	gfantialiasing:Bool,
	backgroundSprite:String,
	bpm:Int
}
typedef NGSprData =
{
	sprite:String,
	textArray:Array<String>,
	height:Float
}
class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;
	#if DENPA_WATERMARKS
	var credIcon1:FlxSprite;
	var credIcon2:FlxSprite;
	var credIcon3:FlxSprite;
	var credIcon4:FlxSprite;
	#end
	var sex:Array<String> = ['In association', 'with', 'Newgrounds'];
	var curWacky:Array<String> = [];

	var mustUpdate:Bool = false;
	
	var titleJSON:TitleData;
	var ngSprJSON:NGSprData;
	
	public static var updateVersion:String = '';

	override public function create():Void
	{
		Paths.clearUnusedMemory();
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		//trace(path, FileSystem.exists(path));
		
		if (ClientPrefs.checkForUpdates) {
			if(!closedState) {
				trace('checking for update');
				var http = new haxe.Http("https://raw.githubusercontent.com/UmbratheUmbreon/PublicDenpaEngine/main/gitVersion.txt");
				
				http.onData = function (data:String)
				{
					updateVersion = data.split('\n')[0].trim();
					var curVersion:String = MainMenuState.denpaEngineVersion.trim();
					trace('version online: ' + updateVersion + ', your version: ' + curVersion);
					if(updateVersion != curVersion) {
						trace('versions arent matching!');
						#if !debug
						mustUpdate = true;
						#else
						trace('you\'re on debug so you get a pass');
						mustUpdate = false;
						#end
					}
				}
				
				http.onError = function (error) {
					trace('error: $error');
				}
				
				http.request();
			}
		}

		curWacky = FlxG.random.getObject(getIntroTextShit());

		#if desktop
		DiscordClient.changePresence("On the Title Screen", null);
		#end

		// DEBUG BULLSHIT

		super.create();

		// IGNORE THIS!!!
		titleJSON = Json.parse(Paths.getTextFromFile('images/title/gfDanceTitle.json'));
		//lmao
		ngSprJSON = Json.parse(Paths.getTextFromFile('images/title/newgroundsSprite.json'));

		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			#if desktop
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add (function (exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];
	var swagShader:ColorSwap = null;

	function startIntro()
	{
		if (!initialized)
		{
			if(FlxG.sound.music == null) {
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxG.sound.music.loopTime = 71853;
				FlxG.sound.music.endTime = null;

				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
		}

		Conductor.changeBPM(100);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();
		
		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != "none"){
			bg.loadGraphic(Paths.image(titleJSON.backgroundSprite));
		}else{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}
		add(bg);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		
		logoBl.antialiasing = ClientPrefs.globalAntialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		if (!ClientPrefs.lowQuality) {
			swagShader = new ColorSwap();
		}
		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);

		gfDance.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.scale.set(titleJSON.gfscalex, titleJSON.gfscaley);
		gfDance.updateHitbox();
		gfDance.antialiasing = titleJSON.gfantialiasing ? ClientPrefs.globalAntialiasing : false;
		
		add(gfDance);
		add(logoBl);
		if (!ClientPrefs.lowQuality) {
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}
		
		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);
		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/title/titleEnter.png";
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)){
			path = "mods/images/title/titleEnter.png";
		}
		//trace(path, FileSystem.exists(path));
		if (!FileSystem.exists(path)){
			path = "assets/images/title/titleEnter.png";
		}
		//trace(path, FileSystem.exists(path));
		titleText.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromFile(path),File.getContent(StringTools.replace(path,".png",".xml")));
		#else
		
		titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		#end
		var animFrames:Array<FlxFrame> = [];
		@:privateAccess {
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0) {
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.antialiasing = ClientPrefs.globalAntialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		var height:Float = 0.52;
		var sprite:String = 'newgrounds_logo';
		ngSpr = new FlxSprite();
		#if DENPA_WATERMARKS
		switch (FlxG.random.int(0,3))
		{
			case 0:
				sex[0] = 'Not associated';
			case 1:
				sprite = 'bambail';
				height = 0.43;
				sex = ['The good mod', 'with stridents', 'Bambail Insurgency'];
			case 2:
				sprite = 'denpa';
				height = 0.42;
				sex = ['No way', 'its the', 'Denpa Mod'];
			default:
				sprite = ngSprJSON.sprite;
				height = ngSprJSON.height;
				sex = ngSprJSON.textArray;
		}
		#end
		ngSpr.loadGraphic(Paths.image('title/$sprite'));
		ngSpr.y = FlxG.height * height;
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.globalAntialiasing;

		#if DENPA_WATERMARKS
		credIcon1 = new FlxSprite(150,150).loadGraphic(Paths.image('credits/at'));
		add(credIcon1);
		credIcon1.antialiasing = ClientPrefs.globalAntialiasing;
		credIcon1.visible = false;

		credIcon2 = new FlxSprite(FlxG.width-300,150).loadGraphic(Paths.image('credits/toadette'));
		add(credIcon2);
		credIcon2.antialiasing = ClientPrefs.globalAntialiasing;
		credIcon2.visible = false;
		credIcon2.flipX = true;

		credIcon3 = new FlxSprite(150,FlxG.height-300).loadGraphic(Paths.image('credits/discord'));
		add(credIcon3);
		credIcon3.antialiasing = ClientPrefs.globalAntialiasing;
		credIcon3.visible = false;

		credIcon4 = new FlxSprite(FlxG.width-300,FlxG.height-300).loadGraphic(Paths.image('credits/thrift'));
		add(credIcon4);
		credIcon4.antialiasing = ClientPrefs.globalAntialiasing;
		credIcon4.visible = false;
		credIcon4.flipX = false;
		#end

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;

	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	var idling:Bool = false;
	var idlingTimer:Float = 180;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		if (FlxG.mouse.justPressed && ClientPrefs.mouseControls) pressedEnter = true;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;
		}

		if (newTitle) {
			titleTimer += CoolUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;
				if (timer >= 1)
					timer = (-timer) + 2;
				
				timer = FlxEase.quadInOut(timer);
					
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}

			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;
				
				if(titleText != null) titleText.animation.play('press');

				if (!ClientPrefs.lowQuality) {
					swagShader.hue = 0;
					swagShader.brightness = 0;
				}
				FlxG.camera.flash(ClientPrefs.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (mustUpdate) {
						FlxG.sound.music.fadeOut(0.5);
						MusicBeatState.switchState(new OutdatedState());
					} else {
						MusicBeatState.switchState(new MainMenuState());
					}
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if (!pressedEnter) {
			if (idlingTimer <= 0) {
				idling = true;
			}
			if (!idling) {
				idlingTimer -= elapsed * 13;
			}
		}
		FlxG.watch.addQuick("idler", idlingTimer);
		if (FlxG.keys.justPressed.ANY){
			idlingTimer = 180;
			idling = false;
		}

		if (!ClientPrefs.lowQuality) {
			if(swagShader != null)
			{
				if(controls.UI_LEFT){
					swagShader.hue -= elapsed * 0.1;
				} 
				if(controls.UI_RIGHT){
					swagShader.hue += elapsed * 0.1;
				} 
				if(controls.UI_DOWN){
					swagShader.brightness -= elapsed * 0.1;
				} 
				if(controls.UI_UP){
					swagShader.brightness += elapsed * 0.1;
				} 
				if (idling) {
					swagShader.hue += elapsed * 0.05;
				}
			}
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	var zoomies:Float = 1.025;
	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		FlxG.camera.zoom = zoomies;

		FlxTween.tween(FlxG.camera, {zoom: 1}, Conductor.crochet / 1300, {
			ease: FlxEase.quadOut
		});

		if(logoBl != null) 
			logoBl.animation.play('bump', true);

		if(gfDance != null) {
			danceLeft = !danceLeft;
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		if(!closedState) {
			sickBeats++;
			if (!skippedIntro) {
				switch (sickBeats)
				{
					case 1:
						zoomies = 1.1;
						#if DENPA_WATERMARKS
						createCoolText(['Denpa Engine by'], -115);
						#else
						createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
						#end
					case 3:
						#if DENPA_WATERMARKS
						credIcon1.visible = true;
						credIcon2.visible = true;
						credIcon3.visible = true;
						credIcon4.visible = true;
						addMoreText('BlueVapor1234', -55);
						addMoreText('Bethany Clone', -55);
						addMoreText('Box', -55);
						addMoreText('Thrifty', -55);
						addMoreText('Toadette8394', -55);
						addMoreText('Ziad', -55);
						addMoreText('_Jorge', -55);
						#else
						addMoreText('present');
						#end
					case 4:
						#if DENPA_WATERMARKS
						credIcon1.destroy();
						credIcon2.destroy();
						credIcon3.destroy();
						credIcon4.destroy();
						#end
						deleteCoolText();
					case 5:
						createCoolText([sex[0], sex[1]], -115);
						zoomies = 1.2;
					case 7:
						addMoreText(sex[2], -115);
						ngSpr.visible = true;
					case 8:
						zoomies = 1.05;
						deleteCoolText();
						ngSpr.visible = false;
					case 9:
						Conductor.changeBPM(150);
						createCoolText([curWacky[0]]);
					case 10:
						addMoreText(curWacky[1]);
					case 11:
						deleteCoolText();
						curWacky = FlxG.random.getObject(getIntroTextShit());
					case 12:
						createCoolText([curWacky[0]]);
					case 13:
						addMoreText(curWacky[1]);
					case 14:
						zoomies = 1.13;
						deleteCoolText();
						Conductor.changeBPM(300);
					case 17:
						addMoreText('Drop');
					case 18:
						addMoreText('The');
					case 19:
						addMoreText('Beat');
					case 20:
						addMoreText('Drop');
					case 21:
						addMoreText('The');
					case 22:
						deleteCoolText();
					case 23:
						addMoreText('Drop');
					case 24:
						addMoreText('The');
					case 25:
						addMoreText('Beat');
					case 26:
						addMoreText('Drop');
					case 27:
						addMoreText('The');
					case 28:
						Conductor.changeBPM(100);
						zoomies = 1.025;
						deleteCoolText();
						skipIntro();
				}
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			zoomies = 1.025;
			if (!SoundTestState.isPlaying) Conductor.changeBPM(100);
			remove(ngSpr);
			remove(credGroup);
			#if DENPA_WATERMARKS
			credIcon1.destroy();
			credIcon2.destroy();
			credIcon3.destroy();
			credIcon4.destroy();
			#end
			FlxG.camera.flash(FlxColor.WHITE, 3);
			skippedIntro = true;
		}
	}
}
