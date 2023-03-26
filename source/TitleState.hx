package;

import Shaders.ColorSwap;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import haxe.xml.Access;
import openfl.Assets;
import openfl.display.BitmapData;
#if desktop
import Discord.DiscordClient;
#end

//this typedef shit is a mess LMAO
typedef TitleData =
{
	titleOffsets:Array<Float>,
	titleAntialiasing:Bool,
	startOffsets:Array<Float>,
	startAntialiasing:Bool,
	gfOffsets:Array<Float>,
	gfScale:Array<Float>,
	gfAntialiasing:Bool,
	background:String,
	backgroundAntialiasing:Bool,
	bpm:Float
}

typedef NGSprJson =
{
	data:Array<NGSprData>,
}
typedef NGSprData =
{
	sprite:String,
	textArray:Array<String>,
	height:Float
}

typedef IntroData = {
	beats:Array<BeatSet>
}
typedef BeatSet = {
	beat:Int,
	actions:Array<ActionSet>
}
typedef ActionSet = {
	name:String,
	values:Array<Dynamic>
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
	var ngSprJSON:NGSprJson;
	var introJSON:IntroData;
	
	public static var updateVersion:String = '';

	override public function create():Void
	{
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		MusicBeatState.disableManual = true;
		if (ClientPrefs.settings.get("checkForUpdates")) {
			if(!closedState) {
				trace('checking for update');
				var http = new haxe.Http("https://raw.githubusercontent.com/UmbratheUmbreon/PublicDenpaEngine/main/assets/preload/update/tracking/GitVer.txt");
				
				http.onData = function (data:String)
				{
					updateVersion = data.split('\n')[0].trim();
					var curVersion:String = Main.denpaEngineVersion.version;
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

		super.create();

		titleJSON = Json.parse(Paths.getTextFromFile('data/title/offsets.json'));
		ngSprJSON = Json.parse(Paths.getTextFromFile('data/title/shoutouts.json'));
		introJSON = Json.parse(Paths.getTextFromFile('data/title/intro.json'));

		if(FlxG.save.data.epilepsyCheck == null && !FlashingState.leftState) {
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.save.data.epilepsyCheck = true;
			FlxG.save.flush();
			MusicBeatState.switchState(new FlashingState());
		} else {
			//new FlxTimer().start(1, function(tmr:FlxTimer)
			//{
				startIntro();
			//});
		}
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var swagShader:ColorSwap = null;
	var animatedBg:Bool = false;
	var bg:FlxSprite;

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

		Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;

		bg = new FlxSprite();
		
		if (titleJSON.background != null && titleJSON.background.length > 0 && titleJSON.background.toLowerCase() != "none")
			if (FileSystem.exists(Paths.getXmlPath('title/${titleJSON.background}'))) {
				bg.frames = Paths.getSparrowAtlas('title/${titleJSON.background}');
				var arr:Array<String> = [];
				//get the first xml animation
				var data:Access = new Access(Xml.parse(Paths.getTextFromFile('images/title/${titleJSON.background}.xml')).firstElement());
				for (texture in data.nodes.SubTexture) arr.push(texture.att.name.substr(0, texture.att.name.length - 3));
				arr = CoolUtil.removeDuplicates(arr);
				bg.animation.addByPrefix('idle', arr[0], 24, false);
				bg.animation.play('idle', true);
				animatedBg = true;
				//! for some reason, the animation does not actually play.
			} else {
				bg.loadGraphic(Paths.image(titleJSON.background));
			}
		else
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.active = false;
		bg.antialiasing = titleJSON.backgroundAntialiasing ? ClientPrefs.settings.get("globalAntialiasing") : false;
		add(bg);

		logoBl = new FlxSprite(titleJSON.titleOffsets[0], titleJSON.titleOffsets[1]);
		logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		logoBl.antialiasing = titleJSON.titleAntialiasing ? ClientPrefs.settings.get("globalAntialiasing") : false;

		if (!ClientPrefs.settings.get("lowQuality")) {
			swagShader = new ColorSwap();
		}

		gfDance = new FlxSprite(titleJSON.gfOffsets[0], titleJSON.gfOffsets[1]);

		gfDance.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.scale.set(titleJSON.gfScale[0], titleJSON.gfScale[1]);
		gfDance.updateHitbox();
		gfDance.antialiasing = titleJSON.gfAntialiasing ? ClientPrefs.settings.get("globalAntialiasing") : false;
		
		add(gfDance);
		add(logoBl);
		if (!ClientPrefs.settings.get("lowQuality")) {
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}
		
		titleText = new FlxSprite(titleJSON.startOffsets[0], titleJSON.startOffsets[1]);
		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/title/titleEnter.png";
		if (!FileSystem.exists(path)){
			path = "mods/images/title/titleEnter.png";
		}
		if (!FileSystem.exists(path)){
			path = "assets/images/title/titleEnter.png";
		}
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
			titleText.animation.addByPrefix('press', ClientPrefs.settings.get("flashing") ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else {
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		
		titleText.animation.play('idle');
		titleText.updateHitbox();
		titleText.antialiasing = titleJSON.startAntialiasing ? ClientPrefs.settings.get("globalAntialiasing") : false;
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		var height:Float = 0.52;
		var sprite:String = 'newgrounds_logo';
		ngSpr = new FlxSprite();
		#if DENPA_WATERMARKS
		final r = FlxG.random.int(0, ngSprJSON.data.length-1);
		switch (r)
		{
			case 0:
				sex[0] = 'Not associated';
			//allow for infinite shit lol
			default:
				sprite = ngSprJSON.data[r].sprite;
				height = ngSprJSON.data[r].height;
				sex = ngSprJSON.data[r].textArray;
		}
		#end
		ngSpr.loadGraphic(Paths.image('title/$sprite'));
		ngSpr.y = FlxG.height * height;
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.active = false;

		#if DENPA_WATERMARKS
		credIcon1 = new FlxSprite(150,150).loadGraphic(Paths.image('credits/at'));
		add(credIcon1);
		credIcon1.visible = false;

		credIcon2 = new FlxSprite(FlxG.width-300,150).loadGraphic(Paths.image('credits/toadette'));
		add(credIcon2);
		credIcon2.visible = false;
		credIcon2.flipX = true;

		credIcon3 = new FlxSprite(150,FlxG.height-300).loadGraphic(Paths.image('credits/yanniz06'));
		add(credIcon3);
		credIcon3.visible = false;

		credIcon4 = new FlxSprite(FlxG.width-300,FlxG.height-300).loadGraphic(Paths.image('credits/thrift'));
		add(credIcon4);
		credIcon4.visible = false;
		credIcon4.flipX = true;
		
		credIcon1.active = false;
		credIcon2.active = false;
		credIcon3.active = false;
		credIcon4.active = false;
		#end

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Paths.getTextFromFile('data/introText.txt'); //allows mod intro sex

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
			swagGoodArray.push(i.split('--'));

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

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		if (newTitle) {
			titleTimer += CoolUtil.clamp(elapsed, 0, 1);
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
				titleText.alpha = FlxMath.lerp(1, .64, timer);
			}

			if(pressedEnter)
			{
				if(titleText != null) {
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
					titleText.animation.play('press');
				}

				if (!ClientPrefs.settings.get("lowQuality") && swagShader != null) {
					swagShader.hue = 0;
					swagShader.brightness = 0;
				}
				FlxG.camera.flash(ClientPrefs.settings.get("flashing") ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;

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

		if (!ClientPrefs.settings.get("lowQuality")) {
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
	var incrementor:Int = 0;
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

		if (bg != null && animatedBg) {
			bg.animation.play('idle', true);
		}

		if(!closedState) {
			sickBeats++;
			if (!skippedIntro) {
				switch (sickBeats)
				{
					//so soft coded
					default:
						runBeatHandler(introJSON.beats[incrementor]);
				}
			}
		}
	}

	function runBeatHandler(beatSet:BeatSet) {
		if (beatSet == null || (beatSet.beat != sickBeats || beatSet.actions == null)) return;
		incrementor++;
		for (actionSet in beatSet.actions) {
			if (actionSet.name == null) return;
			switch (actionSet.name.toLowerCase()) {
				case "setzoom": zoomies = cast (actionSet.values[0], Float);
				case "createstarttext": createCoolText(cast actionSet.values[0], cast (actionSet.values[1], Float));
				case "addmoretext": addMoreText(cast (actionSet.values[0], String), (actionSet.values[1] == null ? 0 : cast (actionSet.values[1], Float)));
				case "deletetext": deleteCoolText();
				case "skipintro": skipIntro();
				case "changebpm": Conductor.changeBPM(cast (actionSet.values[0], Float));
				case "setrandomtext": curWacky = FlxG.random.getObject(getIntroTextShit());
				case "addrandomtext":
					switch (cast (actionSet.values[0], Int)) {
						case 0:
							createCoolText([curWacky[0]]);
						default:
							addMoreText(curWacky[cast (actionSet.values[0], Int)]);
					}
				case "newgrounds":
					switch (cast (actionSet.values[0], Int)) {
						case 0:
							createCoolText([sex[0], sex[1]], -115);
						case 1:
							addMoreText(sex[2], -115);
							ngSpr.visible = true;
						case 2:
							deleteCoolText();
							ngSpr.visible = false;
					}
				#if DENPA_WATERMARKS
				case "icons":
					switch (cast (actionSet.values[0], Int)) {
						case 0:
							for (i in [credIcon1, credIcon2, credIcon3, credIcon4])
								i.visible = true;
						case 1:
							for (i in [credIcon1, credIcon2, credIcon3, credIcon4]) {
								remove(i, true);
								i.destroy();
							}
					}
				#end
			}
		}
	}

	var skippedIntro:Bool = false;
	var updateStuffText:FlxText;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			zoomies = 1.025;
			if (!SoundTestState.isPlaying) Conductor.changeBPM(titleJSON.bpm);
			remove(ngSpr);
			remove(credGroup);
			#if DENPA_WATERMARKS
			for (i in [credIcon1, credIcon2, credIcon3, credIcon4])
				if (i != null) {
					remove(i, true);
					i.destroy();
				}
			#end
			FlxG.camera.flash(FlxColor.WHITE, 3);
			
			skippedIntro = true;
		}
	}
}
