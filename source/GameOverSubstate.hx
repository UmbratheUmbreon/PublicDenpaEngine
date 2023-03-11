package;

import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxescript.Hscript;

/**
* Substate that is loaded upon health falling below 0.
*/
class GameOverSubstate extends MusicBeatSubstate
{
	public static var instance:GameOverSubstate;
	public var boyfriend:Character.Boyfriend;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;
	var updateZoom:Bool = false;
	var playingDeathSound:Bool = false;

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var loopBPM:Int = 100;

	public var hscript:Hscript;

	public static function resetVariables() {
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		loopBPM = 100;
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	//Good lord what the hell is your problem man
	var usingSepModFolder:Bool = false;
	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();
		if (Paths.characterMap.exists(PlayState.characterVersion) && Paths.characterMap.get(PlayState.characterVersion) != Paths.currentModDirectory && PlayState.characterVersion != 'bf'){
			Paths.setModsDirectoryFromType(CHARACTER, PlayState.characterVersion, false);
			usingSepModFolder = true;
		} else if (Paths.characterMap.exists(PlayState.SONG.assets.player1) && Paths.characterMap.get(PlayState.SONG.assets.player1) != Paths.currentModDirectory) {
			Paths.setModsDirectoryFromType(CHARACTER, PlayState.SONG.assets.player1, false);
			usingSepModFolder = true;
		}

		#if HSCRIPT_ALLOWED
		hscript = new Hscript(Paths.hscript('scripts/songs/${Paths.formatToSongPath(PlayState.SONG.header.song)}/GameOver'));
		#end

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;
		
		boyfriend = new Character.Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionOffset.x;
		boyfriend.y += boyfriend.positionOffset.y;
		add(boyfriend);

		camFollow = FlxPoint.get(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(loopBPM);
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');
		boyfriend.animation.callback = (name, num, index) -> {
			if (name != 'firstDeath') return;

			if(num >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			//week 4 death bcs thrifty lost the fla lmfao
			if(num == 37 && boyfriend.curCharacter == 'bf-dead-car')
			{
				var mic = new FlxSprite(boyfriend.x + 33, boyfriend.y + 353).loadGraphic(Paths.image('vanilla/week4/limo/mic'));
				mic.offset.set(37, 11);
				insert(members.indexOf(boyfriend) + 1, mic);
				//frame 44
				FlxTween.tween(mic, {x: mic.x - FlxG.width/1.2, y: mic.y - 100}, 0.144, {
					startDelay: 0.264,
					ease: FlxEase.circIn
				});
			}
		}
		boyfriend.animation.finishCallback = name -> {
			if (playingDeathSound || name != 'firstDeath') return;

			switch (PlayState.SONG.assets.stage.toLowerCase()) {
				case 'tank':
					playingDeathSound = true;
					coolStartDeath(0.2);
	
					FlxG.sound.play(Paths.sound('vanilla/week7/jeffGameover/jeffGameover-' + FlxG.random.int(1, 25)), 1, false, null, true, () -> {
						if(!isEnding) FlxG.sound.music.fadeIn(0.2, 1, 4);
					});
				default:
					coolStartDeath();
			}
			boyfriend.startedDeath = true;
			boyfriend.animation.finishCallback = null;
		}

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
		new FlxTimer().start(1.04, function(_) {
			updateZoom = true;
		});

		hscript.call("onCreatePost", []);

		Paths.clearUnusedCache();
	}

	var isFollowingAlready:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		hscript.call('onUpdate', [elapsed]);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = CoolUtil.clamp(elapsed*0.9, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}
		if (updateZoom) {
			var lerpVal:Float = CoolUtil.clamp(elapsed*10, 0, 1);
			var bfHeight:Float = FlxMath.bound(FlxMath.remapToRange(boyfriend.height, 1, 720, 2, 0.5), 0.5, 2);
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, bfHeight, lerpVal);
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			WeekData.loadTheFirstEnabledMod();
			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack));
			Conductor.changeBPM(SoundTestState.playingTrackBPM);
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
			hscript.call('onGameOverConfirm', [false]);
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
		hscript.call('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();
		hscript.call('onBeatHit', [curBeat]);
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
		if (boyfriend.curCharacter == 'bf-dead-car') {
			camFollow.set(boyfriend.getGraphicMidpoint().x + 100, boyfriend.getGraphicMidpoint().y + 300);
		}
	}

	inline function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
			hscript.call('onGameOverConfirm', [true]);
			if(usingSepModFolder) Paths.setModsDirectoryFromType(NONE, '', true);
		}
	}

	override function destroy(){
		camFollow = FlxDestroyUtil.put(camFollow);
		super.destroy();
		instance = null;
	}
}
