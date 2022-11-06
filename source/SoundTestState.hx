package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;

using StringTools;

/**
* State used to play and select songs for the menus.
*/
class SoundTestState extends MusicBeatState
{
	public static var disk:Int = 0;
	public static var track:Int = 0;
	public static var isPlaying:Bool = false;
	var lastDisk:Int = 0;
	var lastTrack:Int = 0;
	var diskName:String = '';
	var trackName:String = '';
	var totalDisks:Int = 3;
	var totalTracks:Int = 0;
	var leftOrRight:String = '';
	var upOrDown:String = '';
	var paused:Bool = false;

	var albumCover:FlxSprite;
	var diskImg:String = 'engine';
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
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		isPlaying = false;
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

		albumCover = new FlxSprite().loadGraphic(Paths.image('albums/$diskImg'));
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
			
		if (FlxG.keys.justPressed.SPACE)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				if (!paused) {
					FlxG.sound.music.pause();
					paused = true;
				} else {
					FlxG.sound.music.play(false);
					paused = false;
				}
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
		isPlaying = true;
		switch (epicDisk)
		{
			case 0:
				switch (epicTrack)
				{
					case 0:
						setTrackThing('freakyMenu', 'Menu Song', 255,131,0, 100);
					case 1:
						setTrackThing('overdose', 'OVERDOSE', 32,32,32, 104);
					case 2:
						setTrackThing('characterSelect', 'Character Select', 200,200,200, 80);
				}
			case 1:
				switch (epicTrack)
				{
					case 0:
						setTrackThing('tdm1/0', 'Main Theme', 222,222,222, 100);
					case 1:
						setTrackThing('tdm1/1', 'Digitoll', 5,154,38, 105);
					case 2:
						setTrackThing('tdm1/2', 'Antenna Tower', 244,244,244, 80);
					case 3:
						setTrackThing('tdm1/3', 'Shop', 166,166,166, 105);
					case 4:
						setTrackThing('tdm1/4', 'Computer', 122,122,122, 150);
					case 5:
						setTrackThing('tdm1/5', 'Denpa Mens\' House', 145,145,145, 105);
					case 6:
						setTrackThing('msm', 'Museum', 31,213,73, 99);
					case 7:
						setTrackThing('tdm1/7', 'Ferry Wharf', 21,0,255, 105);
					case 8:
						setTrackThing('tdm1/8', 'Cave', 236,99,19, 82);
					case 9:
						setTrackThing('tdm1/9', 'Battle', 55,55,55, 200);
					case 10:
						setTrackThing('tdm1/10', 'Theme of the Forest', 0,255,59, 82);
					case 11:
						setTrackThing('tdm1/11', 'Village of the Underground Man', 255,205,75, 70);
					case 12:
						setTrackThing('tdm1/12', 'Tower of the Demon King', 25,110,0, 76);
					case 13:
						setTrackThing('tdm1/13', 'Boss Battle', 24,24,24, 180);
					case 14:
						setTrackThing('tdm1/14', 'Incandescence Zone', 122,0,0, 88);
					case 15:
						setTrackThing('tdm1/15', 'Barren Land', 0,122,0, 120);
					case 16:
						setTrackThing('tdm1/16', 'Fairy Oasis', 245,245,245, 98);
					case 17:
						setTrackThing('tdm1/17', 'Ice World', 48,207,239, 82);
					case 18:
						setTrackThing('tdm1/18', 'Remains of the Darkness', 10,10,10, 82);
					case 19:
						setTrackThing('tdm1/19', 'Great Demon King', 255,249,66, 186);
					case 20:
						setTrackThing('tdm1/20', 'Ending', 255,255,255, 100);
				}
			case 2:
				switch (epicTrack)
				{
					case 0:
						setTrackThing('tdm2/0', 'Title', 200,200,200, 120);
					case 1:
						setTrackThing('tdm2/1', 'Antenna', 244,244,244, 80);
					case 2:
						setTrackThing('tdm2/2', 'Digitown', 5,154,38, 120);
					case 3:
						setTrackThing('tdm2/3', 'Battle', 55,55,55, 180);
					case 4:
						setTrackThing('tdm2/4', 'Elegy', 33,33,33, 81);
					case 5:
						setTrackThing('tdm2/5', 'World Map', 0,255,0, 117);
					case 6:
						setTrackThing('tdm2/6', 'Denpa Mens\' House', 145,145,145, 141);
					case 7:
						setTrackThing('tdm2/7', 'Farm', 196,122,0, 150);
					case 8:
						setTrackThing('tdm2/8', 'Cave', 236,99,19, 93);
					case 9:
						setTrackThing('tdm2/9', 'Boss Battle', 24,24,24, 180);
					case 10:
						setTrackThing('tdm1/4', 'PC', 122,122,122, 150);
					case 11:
						setTrackThing('tdm2/11', 'Village', 0,144,225, 95);
					case 12:
						setTrackThing('tdm2/12', 'Dwarf Home', 255,205,75, 92);
					case 13:
						setTrackThing('tdm2/13', 'Mystic', 255,255,255, 65);
					case 14:
						setTrackThing('tdm2/14', 'Cave of Darkness', 10,10,10, 82);
					case 15:
						setTrackThing('tdm1/6', 'Museum', 31,213,73, 99);
					case 16:
						setTrackThing('tdm1/12', 'Tower of Evil', 25,110,0, 76);
					case 17:
						setTrackThing('tdm2/17', 'At Sea', 21,0,255, 60);
					case 18:
						setTrackThing('tdm1/14', 'Volcano', 122,0,0, 88);
					case 19:
						setTrackThing('tdm2/19', 'Desert', 255,219,0, 152);
					case 20:
						setTrackThing('tdm2/20', 'Pyramid', 255,219,0, 170);
					case 21:
						setTrackThing('tdm2/21', 'Coliseum', 128,128,128, 100);
					case 22:
						setTrackThing('tdm2/22', 'Coliseum Battle', 157,157,157, 188);
					case 23:
						setTrackThing('tdm2/23', 'Dark Ocean', 1,0,84, 60);
					case 24:
						setTrackThing('tdm2/24', 'Water Temple', 95,148,211, 125);
					case 25:
						setTrackThing('tdm2/25', 'Shop', 166,166,166, 88);
					case 26:
						setTrackThing('tdm2/26', 'Fairy', 245,245,245, 98);
					case 27:
						setTrackThing('tdm1/17', 'Ice Island', 48,207,239, 82);
					case 28:
						setTrackThing('tdm2/28', 'Evil Cave', 15,15,15, 68);
					case 29:
						setTrackThing('tdm2/29', 'Palace', 255,240,0, 59);
					case 30:
						setTrackThing('tdm2/30', 'Final Boss Battle', 19,19,19, 185);
					case 31:
						setTrackThing('tdm2/31', 'Ending', 255,255,255, 55);
				}
			case 3:
				switch (epicTrack)
				{
					case 0:
						setTrackThing('tdm3/0', 'Title', 222,222,222, 123);
					case 1:
						setTrackThing('tdm3/1', 'Antenna', 244,244,244, 144);
					case 2:
						setTrackThing('tdm3/2', 'Digitoll', 10,220,0, 117);
					case 3:
						setTrackThing('tdm3/3', 'PC', 208,208,208, 99);
					case 4:
						setTrackThing('tdm3/4', 'Squelch\'s Cave', 208,99,0, 96);
					case 5:
						setTrackThing('tdm3/5', 'Battle', 128,128,128, 108);
					case 6:
						setTrackThing('tdm3/6', 'Boss Battle', 24,24,24, 92);
					case 7:
						setTrackThing('tdm3/7', 'Digipelago', 116,112,255, 112);
					case 8:
						setTrackThing('tdm3/8', 'Museum', 31,213,73, 108);
					case 9:
						setTrackThing('tdm3/9', 'Village', 255,205,75, 172);
					case 10:
						setTrackThing('tdm3/10', 'Fishing', 67,111,248, 144);
					case 11:
						setTrackThing('tdm3/11', 'Rare Fish', 0,53,217, 152);
					case 12:
						setTrackThing('tdm3/12', 'Fairy Spring', 170,170,170, 99);
					case 13:
						setTrackThing('tdm3/13', 'Jewel Shop', 0,227,255, 96);
					case 14:
						setTrackThing('tdm3/14', 'Overworld', 0,255,0, 108);
					case 15:
						setTrackThing('tdm3/15', 'Cannon Village', 0,144,225, 86);
					case 16:
						setTrackThing('tdm3/16', 'Evil Hideout', 32,32,32, 96);
					case 17:
						setTrackThing('tdm3/17', 'Hot Spring Village', 255,0,0, 112);
					case 18:
						setTrackThing('tdm3/18', 'Mystic', 255,255,255, 136);
					case 19:
						setTrackThing('tdm3/19', 'Volcano', 78,0,0, 89);
					case 20:
						setTrackThing('tdm3/20', 'At Sea', 21,0,255, 92);
					case 21:
						setTrackThing('tdm3/21', 'Elegy', 33,33,33, 161);
					case 22:
						setTrackThing('tdm3/22', 'Cave of Darkness', 10,10,10, 123);
					case 23:
						setTrackThing('tdm3/23', 'Coliseum', 128,128,128, 103);
					case 24:
						setTrackThing('tdm3/24', 'Coliseum Battle', 157,157,157, 89);
					case 25:
						setTrackThing('tdm3/25', 'Dark Ruins', 5,5,5, 152);
					case 26:
						setTrackThing('tdm3/26', 'Fairy Village', 245,245,245, 99);
					case 27:
						setTrackThing('tdm3/27', 'Dark Ocean', 1,0,84, 92);
					case 28:
						setTrackThing('tdm3/28', 'Water Temple', 95,148,211, 123);
					case 29:
						setTrackThing('tdm3/29', 'Tuhot Village', 255,219,0, 152);
					case 30:
						setTrackThing('tdm3/30', 'Jewel Mine', 48,207,239, 96);
					case 31:
						setTrackThing('tdm3/31', 'Shock Temple', 255,249,66, 89);
					case 32:
						setTrackThing('tdm3/32', 'Final Battle', 12,12,12, 136);
					case 33:
						setTrackThing('tdm3/33', 'Ending', 255,255,255, 86);
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
			DiscordClient.changePresence("Album: " + diskName, "Track: " + trackName, imgName, true);
			#end
		} else {
			lastTrack = supaTrack;
			tweenTexts(upOrDown);
			setMusic(supaDisk, supaTrack);
			#if desktop
			// Updating Discord Rich Presence.
			DiscordClient.changePresence("Album: " + diskName, "Track: " + trackName, imgName, true);
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
							diskImg = 'engine';
						case 1:
							diskImg = 'tdm1';
						case 2:
							diskImg = 'tdm2';
						case 3:
							diskImg = 'tdm3';
					}
					albumCover.loadGraphic(Paths.image('albums/$diskImg'));
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
							diskImg = 'engine';
						case 1:
							diskImg = 'tdm1';
						case 2:
							diskImg = 'tdm2';
						case 3:
							diskImg = 'tdm3';
					}
					albumCover.loadGraphic(Paths.image('albums/$diskImg'));
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

	public static function getDaColor():FlxColor {
		//do i even need this function? probs not 
		if (!setColor) {
			colorToSet = FlxColor.fromRGB(255,255,255);
		}
		//CustomFadeTransition.colorForFunnyGrad = colorToSet;
		return colorToSet;
	}

	function setTrackThing(music:String = '', track:String = '', r:Int = 255, g:Int = 255, b:Int = 255, bpm:Float = 100, ?loopStart:Float = null, ?loopEnd:Float = null, ?stream:Bool = false) {
		if (!stream) {
			FlxG.sound.playMusic(Paths.music(music), 0);
		} else {
			FlxG.sound.music.loadStream(music, true, false, null, null).play();
		}
		FlxG.sound.music.fadeIn(4, 0, 0.7);
		trackName = track;
		colorToSet = FlxColor.fromRGB(r,g,b);
		Conductor.changeBPM(bpm);
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		//trace('beat hit' + curBeat);
	}
}
