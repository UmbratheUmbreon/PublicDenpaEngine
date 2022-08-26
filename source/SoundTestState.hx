package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;

using StringTools;

class SoundTestState extends MusicBeatState
{
	public static var disk:Int = 0;
	public static var track:Int = 0;
	var lastDisk:Int = 0;
	var lastTrack:Int = 0;
	var diskName:String = '';
	var trackName:String = '';
	var totalDisks:Int = 3;
	var totalTracks:Int = 0;
	var leftOrRight:String = '';
	var upOrDown:String = '';

	var albumCover:FlxSprite;
	var diskTxt:FlxText;
	var trackTxt:FlxText;

	var imgName:String = '';

	private var camGame:FlxCamera;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;
	var intendedColor:Int;
	public static var colorToSet:Int;
	public static var setColor:Bool = false;
	var colorTween:FlxTween;
	var bgScrollColorTween:FlxTween;
	var bgScroll2ColorTween:FlxTween;
	var gradientColorTween:FlxTween;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("On the Sound Test Menu", null);
		#end

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true); //new EPIC code
		//FlxCamera.defaultCameras = [camGame]; //old STUPID code

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
		bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
		if (!ClientPrefs.lowQuality) {
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite(-FlxG.width/2,-FlxG.height/2).loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		add(gradient);
		//gradient.screenCenter();

		albumCover = new FlxSprite();
		albumCover.frames = Paths.getSparrowAtlas('albumGrid');
		albumCover.animation.addByPrefix('tdm1', 'album tdm1', 1, true);
		albumCover.animation.addByPrefix('tdm2', 'album tdm2', 1, true);
		albumCover.animation.addByPrefix('tdm3', 'album tdm3', 1, true);
		albumCover.animation.addByPrefix('engine', 'album engine', 1, true);
		albumCover.scrollFactor.set(0, 0);
		albumCover.x = FlxG.width/2 - 240;
		albumCover.y = FlxG.height/2 - 120;
		albumCover.antialiasing = ClientPrefs.globalAntialiasing;
		add(albumCover);

		diskTxt = new FlxText(albumCover.x + 240, albumCover.y, 0, "Album: " + diskName);
		diskTxt.scrollFactor.set();
		diskTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		add(diskTxt);

		trackTxt = new FlxText(albumCover.x + 240, albumCover.y + 44, 0, "Track: " + trackName);
		trackTxt.scrollFactor.set();
		trackTxt.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		add(trackTxt);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, null, 1);

		reloadDisk(disk, track, true);

		FreeplayState.destroyFreeplayVocals();
		PlayState.SONG = null;

		colorToSet = FlxColor.fromRGB(255,255,255);

		bg.color = getDaColor();
		if (!ClientPrefs.lowQuality) {
			bgScroll.color = getDaColor();
			bgScroll2.color = getDaColor();
		}
		gradient.color = getDaColor();
		intendedColor = bg.color;

		reloadDisk(disk, track, true);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	
		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();

		switch (diskName) {
			case 'Denpa Engine':
				totalTracks = 2;
			case 'The "DENPA" Men':
				totalTracks = 20;
			case 'The "DENPA" Men 2':
				totalTracks = 32;
			case 'The "DENPA" Men 3':
				totalTracks = 33;
		}

		if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				disk -= 1;
				leftOrRight = 'left';
			}

		if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				disk += 1;
				leftOrRight = 'right';
			}

		if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				track += 1;
				upOrDown = 'up';
			}

		if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				track -= 1;
				upOrDown = 'down';
			}
		
		if (controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls))
		{
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
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (disk < 0) disk = 0;
		if (disk > totalDisks) disk = totalDisks;
		if (track < 0) track = 0;
		if (track > totalTracks) track = totalTracks;

		if (lastDisk != disk) {
			reloadDisk(disk, track, true);
		}
		if (lastTrack != track) {
			reloadDisk(disk, track, false);
		}

		diskTxt.text = 'Album: ' + diskName;
		trackTxt.text = 'Track: ' + trackName;

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		super.update(elapsed);
	}

	function setMusic(epicDisk:Int, epicTrack:Int)
	{
		switch (epicDisk)
		{
			case 0:
				switch (epicTrack)
				{
					case 0:
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Menu Song';
						Conductor.changeBPM(100);
						colorToSet = FlxColor.fromRGB(255,131,0);
					case 1:
						FlxG.sound.playMusic(Paths.music('OVERDOSE'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'OVERDOSE';
						Conductor.changeBPM(104);
						colorToSet = FlxColor.fromRGB(32,32,32);
					case 2:
						FlxG.sound.playMusic(Paths.music('characterSelect'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Character Select';
						Conductor.changeBPM(80);
						colorToSet = FlxColor.fromRGB(200,200,200);
				}
			case 1:
				switch (epicTrack)
				{
					case 0:
						FlxG.sound.playMusic(Paths.music('tdm1/0'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Main Theme';
						Conductor.changeBPM(100);
						colorToSet = FlxColor.fromRGB(222,222,222);
					case 1:
						FlxG.sound.playMusic(Paths.music('tdm1/1'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Digitoll';
						Conductor.changeBPM(105);
						colorToSet = FlxColor.fromRGB(5,154,38);
					case 2:
						FlxG.sound.playMusic(Paths.music('tdm1/2'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Antenna Tower';
						Conductor.changeBPM(80);
						colorToSet = FlxColor.fromRGB(244,244,244);
					case 3:
						FlxG.sound.playMusic(Paths.music('tdm1/3'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Shop';
						Conductor.changeBPM(105);
						colorToSet = FlxColor.fromRGB(166,166,166);
					case 4:
						FlxG.sound.playMusic(Paths.music('tdm1/4'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Computer';
						Conductor.changeBPM(150);
						colorToSet = FlxColor.fromRGB(122,122,122);
					case 5:
						FlxG.sound.playMusic(Paths.music('tdm1/5'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = "Denpa Mens' House";
						Conductor.changeBPM(105);
						colorToSet = FlxColor.fromRGB(145,145,145);
					case 6:
						FlxG.sound.playMusic(Paths.music('tdm1/6'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Museum';
						Conductor.changeBPM(99);
						colorToSet = FlxColor.fromRGB(31,213,73);
					case 7:
						FlxG.sound.playMusic(Paths.music('tdm1/7'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Ferry Wharf';
						Conductor.changeBPM(105);
						colorToSet = FlxColor.fromRGB(21,0,255);
					case 8:
						FlxG.sound.playMusic(Paths.music('tdm1/8'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Cave';
						Conductor.changeBPM(82);
						colorToSet = FlxColor.fromRGB(236,99,19);
					case 9:
						FlxG.sound.playMusic(Paths.music('tdm1/9'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Battle';	
						Conductor.changeBPM(200);
						colorToSet = FlxColor.fromRGB(55,55,55);
					case 10:
						FlxG.sound.playMusic(Paths.music('tdm1/10'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Theme of the Forest';
						Conductor.changeBPM(82);
						colorToSet = FlxColor.fromRGB(0,255,59);
					case 11:
						FlxG.sound.playMusic(Paths.music('tdm1/11'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Village of the Underground Man';
						Conductor.changeBPM(70);
						colorToSet = FlxColor.fromRGB(255,205,75);
					case 12:
						FlxG.sound.playMusic(Paths.music('tdm1/12'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Tower of the Demon King';
						Conductor.changeBPM(76);
						colorToSet = FlxColor.fromRGB(25,110,0);
					case 13:
						FlxG.sound.playMusic(Paths.music('tdm1/13'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Boss Battle';
						Conductor.changeBPM(180);
						colorToSet = FlxColor.fromRGB(24,24,24);
					case 14:
						FlxG.sound.playMusic(Paths.music('tdm1/14'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Incandescence Zone';
						Conductor.changeBPM(88);
						colorToSet = FlxColor.fromRGB(122,0,0);
					case 15:
						FlxG.sound.playMusic(Paths.music('tdm1/15'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Barren Land';
						Conductor.changeBPM(120);
						colorToSet = FlxColor.fromRGB(0,122,0);
					case 16:
						FlxG.sound.playMusic(Paths.music('tdm1/16'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Fairy Oasis';
						Conductor.changeBPM(98);
						colorToSet = FlxColor.fromRGB(245,245,245);
					case 17:
						FlxG.sound.playMusic(Paths.music('tdm1/17'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Ice World';
						Conductor.changeBPM(82);
						colorToSet = FlxColor.fromRGB(48,207,239);
					case 18:
						FlxG.sound.playMusic(Paths.music('tdm1/18'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Remains of the Darkness';
						Conductor.changeBPM(82);
						colorToSet = FlxColor.fromRGB(10,10,10);
					case 19:
						FlxG.sound.playMusic(Paths.music('tdm1/19'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Great Demon King';
						Conductor.changeBPM(186);
						colorToSet = FlxColor.fromRGB(255,249,66);
					case 20:
						FlxG.sound.playMusic(Paths.music('tdm1/20'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Ending';
						Conductor.changeBPM(100);
						colorToSet = FlxColor.fromRGB(255,255,255);
				}
			case 2:
				switch (epicTrack)
				{
					case 0:
						FlxG.sound.playMusic(Paths.music('tdm2/0'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Title';
						Conductor.changeBPM(120);
						colorToSet = FlxColor.fromRGB(200,200,200);
					case 1:
						FlxG.sound.playMusic(Paths.music('tdm2/1'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Antenna';
						Conductor.changeBPM(80);
						colorToSet = FlxColor.fromRGB(244,244,244);
					case 2:
						FlxG.sound.playMusic(Paths.music('tdm2/2'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Digitown';
						Conductor.changeBPM(120);
						colorToSet = FlxColor.fromRGB(5,154,38);
					case 3:
						FlxG.sound.playMusic(Paths.music('tdm2/3'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Battle';
						Conductor.changeBPM(180);
						colorToSet = FlxColor.fromRGB(55,55,55);
					case 4:
						FlxG.sound.playMusic(Paths.music('tdm2/4'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Elegy';
						Conductor.changeBPM(81); //maybe 80 or 82?
						colorToSet = FlxColor.fromRGB(33,33,33);
					case 5:
						FlxG.sound.playMusic(Paths.music('tdm2/5'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'World Map';
						Conductor.changeBPM(117);
						colorToSet = FlxColor.fromRGB(0,255,0);
					case 6:
						FlxG.sound.playMusic(Paths.music('tdm2/6'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = "Denpa Mens' House";
						Conductor.changeBPM(141);
						colorToSet = FlxColor.fromRGB(145,145,145);
					case 7:
						FlxG.sound.playMusic(Paths.music('tdm2/7'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Farm';
						Conductor.changeBPM(150);
						colorToSet = FlxColor.fromRGB(196,122,0);
					case 8:
						FlxG.sound.playMusic(Paths.music('tdm2/8'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Cave';
						Conductor.changeBPM(93);
						colorToSet = FlxColor.fromRGB(236,99,19);
					case 9:
						FlxG.sound.playMusic(Paths.music('tdm2/9'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Boss Battle';
						Conductor.changeBPM(180);
						colorToSet = FlxColor.fromRGB(24,24,24);
					case 10:
						FlxG.sound.playMusic(Paths.music('tdm1/4'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'PC';
						Conductor.changeBPM(150);
						colorToSet = FlxColor.fromRGB(122,122,122);
					case 11:
						FlxG.sound.playMusic(Paths.music('tdm2/11'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Village';
						Conductor.changeBPM(95);
						colorToSet = FlxColor.fromRGB(0,144,225);
					case 12:
						FlxG.sound.playMusic(Paths.music('tdm2/12'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Dwarf Home';
						Conductor.changeBPM(92);
						colorToSet = FlxColor.fromRGB(255,205,75);
					case 13:
						FlxG.sound.playMusic(Paths.music('tdm2/13'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Mystic';
						Conductor.changeBPM(65);
						colorToSet = FlxColor.fromRGB(255,255,255);
					case 14:
						FlxG.sound.playMusic(Paths.music('tdm2/14'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Cave of Darkness';
						Conductor.changeBPM(82);
						colorToSet = FlxColor.fromRGB(10,10,10);
					case 15:
						FlxG.sound.playMusic(Paths.music('tdm1/6'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Museum';
						Conductor.changeBPM(99);
						colorToSet = FlxColor.fromRGB(31,213,73);
					case 16:
						FlxG.sound.playMusic(Paths.music('tdm1/12'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Tower of Evil';
						Conductor.changeBPM(76);
						colorToSet = FlxColor.fromRGB(25,110,0);
					case 17:
						FlxG.sound.playMusic(Paths.music('tdm2/17'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'At Sea';
						Conductor.changeBPM(60);
						colorToSet = FlxColor.fromRGB(21,0,255);
					case 18:
						FlxG.sound.playMusic(Paths.music('tdm1/14'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Volcano';
						Conductor.changeBPM(88);
						colorToSet = FlxColor.fromRGB(122,0,0);
					case 19:
						FlxG.sound.playMusic(Paths.music('tdm2/19'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Desert';
						Conductor.changeBPM(152);
						colorToSet = FlxColor.fromRGB(255,219,0);
					case 20:
						FlxG.sound.playMusic(Paths.music('tdm2/20'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Pyramid';
						Conductor.changeBPM(170);
						colorToSet = FlxColor.fromRGB(255,219,0);
					case 21:
						FlxG.sound.playMusic(Paths.music('tdm2/21'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Coliseum';
						Conductor.changeBPM(100);
						colorToSet = FlxColor.fromRGB(128,128,128);
					case 22:
						FlxG.sound.playMusic(Paths.music('tdm2/22'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Coliseum Battle';
						Conductor.changeBPM(188);
						colorToSet = FlxColor.fromRGB(157,157,157);
					case 23:
						FlxG.sound.playMusic(Paths.music('tdm2/23'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Dark Ocean';
						Conductor.changeBPM(60);
						colorToSet = FlxColor.fromRGB(1,0,84);
					case 24:
						FlxG.sound.playMusic(Paths.music('tdm2/24'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Water Temple';
						Conductor.changeBPM(125);
						colorToSet = FlxColor.fromRGB(95,148,211);
					case 25:
						FlxG.sound.playMusic(Paths.music('tdm2/25'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Shop';
						Conductor.changeBPM(88);
						colorToSet = FlxColor.fromRGB(166,166,166);
					case 26:
						FlxG.sound.playMusic(Paths.music('tdm2/26'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Fairy';
						Conductor.changeBPM(98);
						colorToSet = FlxColor.fromRGB(245,245,245);
					case 27:
						FlxG.sound.playMusic(Paths.music('tdm1/17'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Ice Island';
						Conductor.changeBPM(82);
						colorToSet = FlxColor.fromRGB(48,207,239);
					case 28:
						FlxG.sound.playMusic(Paths.music('tdm2/28'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Evil Cave';
						Conductor.changeBPM(68);
						colorToSet = FlxColor.fromRGB(15,15,15);
					case 29:
						FlxG.sound.playMusic(Paths.music('tdm2/29'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Palace';
						Conductor.changeBPM(59);
						colorToSet = FlxColor.fromRGB(255,240,0);
					case 30:
						FlxG.sound.playMusic(Paths.music('tdm2/30'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Final Boss Battle';
						Conductor.changeBPM(185);
						colorToSet = FlxColor.fromRGB(19,19,19);
					case 31:
						FlxG.sound.playMusic(Paths.music('tdm2/31'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Ending';
						Conductor.changeBPM(55);
						colorToSet = FlxColor.fromRGB(255,255,255);
				}
			case 3:
				switch (epicTrack)
				{
					case 0:
						FlxG.sound.playMusic(Paths.music('tdm3/0'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Title';
						colorToSet = FlxColor.fromRGB(222,222,222);
						Conductor.changeBPM(123);
					case 1:
						FlxG.sound.playMusic(Paths.music('tdm3/1'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Antenna';
						colorToSet = FlxColor.fromRGB(244,244,244);
						Conductor.changeBPM(144);
					case 2:
						FlxG.sound.playMusic(Paths.music('tdm3/2'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Digitoll';
						colorToSet = FlxColor.fromRGB(10,220,0);
						Conductor.changeBPM(117);
					case 3:
						FlxG.sound.playMusic(Paths.music('tdm3/3'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'PC';
						colorToSet = FlxColor.fromRGB(208,208,208);
						Conductor.changeBPM(99);
					case 4:
						FlxG.sound.playMusic(Paths.music('tdm3/4'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = "Squelch's Cave";
						colorToSet = FlxColor.fromRGB(208,99,0);
						Conductor.changeBPM(96);
					case 5:
						FlxG.sound.playMusic(Paths.music('tdm3/5'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Battle';
						colorToSet = FlxColor.fromRGB(128,128,128);
						Conductor.changeBPM(108);
					case 6:
						FlxG.sound.playMusic(Paths.music('tdm3/6'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Boss Battle';
						colorToSet = FlxColor.fromRGB(24,24,24);
						Conductor.changeBPM(92);
					case 7:
						FlxG.sound.playMusic(Paths.music('tdm3/7'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Digipelago';
						colorToSet = FlxColor.fromRGB(116,112,255);
						Conductor.changeBPM(112);
					case 8:
						FlxG.sound.playMusic(Paths.music('tdm3/8'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Museum';
						colorToSet = FlxColor.fromRGB(31,213,73);
						Conductor.changeBPM(108);
					case 9:
						FlxG.sound.playMusic(Paths.music('tdm3/9'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Village';
						colorToSet = FlxColor.fromRGB(255,205,75);
						Conductor.changeBPM(172);
					case 10:
						FlxG.sound.playMusic(Paths.music('tdm3/10'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Fishing';
						colorToSet = FlxColor.fromRGB(67,111,248);
						Conductor.changeBPM(144);
					case 11:
						FlxG.sound.playMusic(Paths.music('tdm3/11'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Rare Fish';
						colorToSet = FlxColor.fromRGB(0,53,217);
						Conductor.changeBPM(152);
					case 12:
						FlxG.sound.playMusic(Paths.music('tdm3/12'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Fairy Spring';
						colorToSet = FlxColor.fromRGB(170,170,170);
						Conductor.changeBPM(99);
					case 13:
						FlxG.sound.playMusic(Paths.music('tdm3/13'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Jewel Shop';
						colorToSet = FlxColor.fromRGB(0,227,255);
						Conductor.changeBPM(96);
					case 14:
						FlxG.sound.playMusic(Paths.music('tdm3/14'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Overworld';
						colorToSet = FlxColor.fromRGB(0,255,0);
						Conductor.changeBPM(108);
					case 15:
						FlxG.sound.playMusic(Paths.music('tdm3/15'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Cannon Village';
						colorToSet = FlxColor.fromRGB(0,144,225);
						Conductor.changeBPM(86);
					case 16:
						FlxG.sound.playMusic(Paths.music('tdm3/16'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Evil Hideout';
						colorToSet = FlxColor.fromRGB(32,32,32);
						Conductor.changeBPM(96);
					case 17:
						FlxG.sound.playMusic(Paths.music('tdm3/17'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Hot Spring Village';
						colorToSet = FlxColor.fromRGB(255,0,0);
						Conductor.changeBPM(112);
					case 18:
						FlxG.sound.playMusic(Paths.music('tdm3/18'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Mystic';
						colorToSet = FlxColor.fromRGB(255,255,255);
						Conductor.changeBPM(136);
					case 19:
						FlxG.sound.playMusic(Paths.music('tdm3/19'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Volcano';
						colorToSet = FlxColor.fromRGB(78,0,0);
						Conductor.changeBPM(89);
					case 20:
						FlxG.sound.playMusic(Paths.music('tdm3/20'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'At Sea';
						colorToSet = FlxColor.fromRGB(21,0,255);
						Conductor.changeBPM(92);
					case 21:
						FlxG.sound.playMusic(Paths.music('tdm3/21'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Elegy';
						colorToSet = FlxColor.fromRGB(33,33,33);
						Conductor.changeBPM(161);
					case 22:
						FlxG.sound.playMusic(Paths.music('tdm3/22'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Cave of Darkness';
						colorToSet = FlxColor.fromRGB(10,10,10);
						Conductor.changeBPM(123);
					case 23:
						FlxG.sound.playMusic(Paths.music('tdm3/23'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Coliseum';
						colorToSet = FlxColor.fromRGB(128,128,128);
						Conductor.changeBPM(103);
					case 24:
						FlxG.sound.playMusic(Paths.music('tdm3/24'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Coliseum Battle';
						colorToSet = FlxColor.fromRGB(157,157,157);
						Conductor.changeBPM(89);
					case 25:
						FlxG.sound.playMusic(Paths.music('tdm3/25'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Dark Ruins';
						colorToSet = FlxColor.fromRGB(5,5,5);
						Conductor.changeBPM(152);
					case 26:
						FlxG.sound.playMusic(Paths.music('tdm3/26'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Fairy Village';
						colorToSet = FlxColor.fromRGB(245,245,245);
						Conductor.changeBPM(99);
					case 27:
						FlxG.sound.playMusic(Paths.music('tdm3/27'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Dark Ocean';
						colorToSet = FlxColor.fromRGB(1,0,84);
						Conductor.changeBPM(92);
					case 28:
						FlxG.sound.playMusic(Paths.music('tdm3/28'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Water Temple';
						colorToSet = FlxColor.fromRGB(95,148,211);
						Conductor.changeBPM(123);
					case 29:
						FlxG.sound.playMusic(Paths.music('tdm3/29'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Tuhot Village';
						colorToSet = FlxColor.fromRGB(255,219,0);
						Conductor.changeBPM(152);
					case 30:
						FlxG.sound.playMusic(Paths.music('tdm3/30'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Jewel Mine';
						colorToSet = FlxColor.fromRGB(48,207,239);
						Conductor.changeBPM(96);
					case 31:
						FlxG.sound.playMusic(Paths.music('tdm3/31'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Shock Temple';
						colorToSet = FlxColor.fromRGB(255,249,66);
						Conductor.changeBPM(89);
					case 32:
						FlxG.sound.playMusic(Paths.music('tdm3/32'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Final Battle';
						colorToSet = FlxColor.fromRGB(12,12,12);
						Conductor.changeBPM(136);
					case 33:
						FlxG.sound.playMusic(Paths.music('tdm3/33'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						trackName = 'Ending';
						colorToSet = FlxColor.fromRGB(255,255,255);
						Conductor.changeBPM(86);
				}
		}
		tweenColor();
		setColor = true;
	}

	function reloadDisk(supaDisk:Int, supaTrack:Int, reloadingDisk:Bool)
	{
		if(reloadingDisk) {
			lastDisk = supaDisk;
			lastTrack = supaTrack = 0;
			tweenAlbum(leftOrRight);
			tweenTexts('down');
			switch (supaDisk) {
				case 0:
					diskName = 'Denpa Engine';
				case 1:
					diskName = 'The "DENPA" Men';
					imgName = 'tdm1';
				case 2:
					diskName = 'The "DENPA" Men 2';
					imgName = 'tdm2';
				case 3:
					diskName = 'The "DENPA" Men 3';
					imgName = 'tdm3';
			}
			setMusic(supaDisk, supaTrack);
			#if desktop
			// Updating Discord Rich Presence.
			DiscordClient.changePresence("Album: " + diskName, "Track: " + trackName, imgName);
			#end
		} else {
			lastTrack = supaTrack;
			tweenTexts(upOrDown);
			setMusic(supaDisk, supaTrack);
			#if desktop
			// Updating Discord Rich Presence.
			DiscordClient.changePresence("Album: " + diskName, "Track: " + trackName, imgName);
			#end
		}
	}

	function tweenAlbum(supaDirection:String)
	{
		if (supaDirection == 'right') {
			FlxTween.tween(albumCover, {x: FlxG.width}, 0.15, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					albumCover.x = -240;
					switch (disk) {
						case 0:
							albumCover.animation.play('engine');
						case 1:
							albumCover.animation.play('tdm1');
						case 2:
							albumCover.animation.play('tdm2');
						case 3:
							albumCover.animation.play('tdm3');
					}
					FlxTween.tween(albumCover, {x: FlxG.width/2 - 240}, 0.15, {
						ease: FlxEase.quadInOut
					});
				}
			});
		} else {
			FlxTween.tween(albumCover, {x: -240}, 0.1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					albumCover.x = FlxG.width;
					switch (disk) {
						case 0:
							albumCover.animation.play('engine');
						case 1:
							albumCover.animation.play('tdm1');
						case 2:
							albumCover.animation.play('tdm2');
						case 3:
							albumCover.animation.play('tdm3');
					}
					FlxTween.tween(albumCover, {x: FlxG.width/2 - 240}, 0.1, {
						ease: FlxEase.quadInOut
					});
				}
			});
		}
	}

	function tweenTexts(supaDirection)
	{
		if (supaDirection == 'up') {
			FlxTween.tween(diskTxt, {y: (FlxG.height * -1) - 100}, 0.1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					diskTxt.y = FlxG.height;
					FlxTween.tween(diskTxt, {y: FlxG.height/2 - 120}, 0.1, {
						ease: FlxEase.quadInOut
					});
				}
			});
			FlxTween.tween(trackTxt, {y: (FlxG.height * -1) - 66}, 0.1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					trackTxt.y = FlxG.height + 44;
					FlxTween.tween(trackTxt, {y: FlxG.height/2 - 120 + 44}, 0.1, {
						ease: FlxEase.quadInOut
					});
				}
			});
		} else {
			FlxTween.tween(diskTxt, {y: FlxG.height}, 0.1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					diskTxt.y = (FlxG.height * -1) - 100;
					FlxTween.tween(diskTxt, {y: FlxG.height/2 - 120}, 0.1, {
						ease: FlxEase.quadInOut
					});
				}
			});
			FlxTween.tween(trackTxt, {y: FlxG.height + 44}, 0.1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					trackTxt.y = (FlxG.height * -1) - 66;
					FlxTween.tween(trackTxt, {y: FlxG.height/2 - 120 + 44}, 0.1, {
						ease: FlxEase.quadInOut
					});
				}
			});
		}
	}

	function tweenColor() {
		var newColor:Int =  getDaColor();
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
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
			bgScrollColorTween = FlxTween.color(bgScroll, 1, bgScroll.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					bgScrollColorTween = null;
				}
			});
			bgScrollColorTween = FlxTween.color(bgScroll2, 1, bgScroll2.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					bgScrollColorTween = null;
				}
			});
			gradientColorTween = FlxTween.color(gradient, 1, gradient.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					gradientColorTween = null;
				}
			});
		}
	}

	public static function getDaColor() {
		//do i even need this function? probs not 
		if (!setColor) {
			colorToSet = FlxColor.fromRGB(255,255,255);
		}
		return colorToSet;
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		//trace('beat hit' + curBeat);
	}
}
