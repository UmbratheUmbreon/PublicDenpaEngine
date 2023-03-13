package;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.Json;
#if desktop
import Discord.DiscordClient;
#end

typedef AlbumData =
{
	name:String,
	image:String,
	tracks:Array<TrackData>
}
typedef TrackData =
{
	file:String,
	name:String,
	rgb:Array<Int>,
	bpm:Int
}
/**
* State used to play and select songs for the menus.
*/
class SoundTestState extends MusicBeatState
{
	public static var disk:Int = 0;
	public static var track:Int = 0;
	public static var isPlaying:Bool = false;
	public static var playingTrack:String = 'freakyMenu';
	public static var playingTrackBPM:Float = 100;
	var lastDisk:Int = 0;
	var lastTrack:Int = 0;
	var diskName:String = '';
	var trackName:String = '';
	var totalDisks:Int = 0;
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
	var albums:Array<AlbumData> = [];

	override function create()
	{
		isPlaying = false;
		#if desktop
		DiscordClient.changePresence("On the Sound Test Menu", null);
		#end

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var path = "assets/data/albums";
        for (file in FileSystem.readDirectory(path)) {
            if (file.endsWith(".json")) {
				//i hate you
                albums.push(Json.parse(Paths.getTextFromFile(path.replace("assets/", "") + '/' + file)));
            }
        }
		#if MODS_ALLOWED
		path = Paths.modFolders("data/albums");
		if (FileSystem.exists(path)) {
			for (file in FileSystem.readDirectory(path)) {
				if (file.endsWith(".json")) {
					albums.push(Json.parse(Paths.getTextFromFile("data/albums" + '/' + file)));
				}
			}
		}
        #end
		totalDisks = albums.length-1;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite(-FlxG.width/2,-FlxG.height/2).loadGraphic(Paths.image('gradient'));
		add(gradient);

		albumCover = new FlxSprite().loadGraphic(Paths.image('albums/$diskImg'));
		albumCover.scrollFactor.set(0, 0);
		albumCover.x = FlxG.width/2 - 240;
		albumCover.y = FlxG.height/2 - 120;
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
		if (!ClientPrefs.settings.get("lowQuality")) {
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
	
		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

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
		
		if (controls.BACK)
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
			FlxG.autoPause = ClientPrefs.settings.get("autoPause");
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

		//horrible horrible spicy, i will get rid of all this garbo next
		diskTxt.text = 'Album: ' + diskName;
		trackTxt.text = 'Track: ' + trackName;

		var lerpVal:Float = CoolUtil.clamp(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		super.update(elapsed);
	}

	function setMusic(track:TrackData)
	{
		isPlaying = true;
		FlxG.autoPause = false;
		setTrackThing(track.file, track.name, track.rgb, track.bpm);
		playingTrack = track.file;
		playingTrackBPM = track.bpm;
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
			var album = albums[supaDisk];
			diskName = album.name;
			imgName = album.image;
			totalTracks = album.tracks.length-1;
			if (supaTrack > totalTracks) supaTrack = totalTracks;
			setMusic(album.tracks[supaTrack]);
			#if desktop
			DiscordClient.changePresence("Album: " + diskName, "Track: " + trackName, imgName, true);
			#end
		} else {
			lastTrack = supaTrack;
			tweenTexts(upOrDown);
			var album = albums[supaDisk];
			if (supaTrack > totalTracks) supaTrack = totalTracks;
			setMusic(album.tracks[supaTrack]);
			#if desktop
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
					diskImg = albums[disk].image;
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
					diskImg = albums[disk].image;
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
			FlxTween.tween(diskTxt, {y: (-FlxG.height) - 100}, 0.1, {
				ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
				{
					diskTxt.y = FlxG.height;
					FlxTween.tween(diskTxt, {y: FlxG.height/2 - 120}, 0.1, {
						ease: FlxEase.quadInOut
					});
				}
			});
			FlxTween.tween(trackTxt, {y: (-FlxG.height) - 66}, 0.1, {
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
			if (!ClientPrefs.settings.get("lowQuality")) {
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
			}
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
		return colorToSet;
	}

	function setTrackThing(music:String = '', track:String = '', rgb:Array<Int>, bpm:Float = 100, ?loopStart:Float = null, ?loopEnd:Float = null, ?stream:Bool = false) {
		Paths.clearUnusedCache();
		if (!stream) {
			FlxG.sound.playMusic(Paths.music(music), 0);
		} else {
			FlxG.sound.music.loadStream(music, true, false, null, null).play();
		}
		FlxG.sound.music.fadeIn(4, 0, 0.7);
		trackName = track;
		colorToSet = FlxColor.fromRGB(rgb[0], rgb[1], rgb[2]);
		Conductor.changeBPM(bpm);
	}

	override function beatHit() {
		super.beatHit();

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		bg.offset.set();
	}
}
