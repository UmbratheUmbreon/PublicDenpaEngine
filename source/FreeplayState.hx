package;

#if desktop
import Discord.DiscordClient;
#end
import WeekData;
import editors.ChartingState;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import haxescript.Hscript;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

/**
* State used to select and load any song to play.
* Only the songs in the currently selected section will appear!
*/
class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var lerpList:Array<Bool> = [];
	var playlistSongs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var ratingText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedLetter:String = 'Unrated';
	var intendedIntensity:String = 'Unknown';

	//var playlistBG:FlxSprite;
	//var playlistHeaderTxt:FlxText;
	//var playlistSongsTxt:FlxText;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxSprite;
	var gradient:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var bgScrollColorTween:FlxTween;
	var bgScroll2ColorTween:FlxTween;
	var gradientColorTween:FlxTween;
	//makes freeplaysection transition look better
	public var black:FlxSprite;

	var section:String = '';

	public var hscript:Hscript;
	public static var instance:FreeplayState;

	override function create()
	{
		Paths.clearUnusedCache();
		Paths.refreshModsMaps(true, true, true);
		instance = this;
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if HSCRIPT_ALLOWED
		hscript = new Hscript(Paths.hscript('scripts/menus/Freeplay'));
		#end

		section = FreeplaySectionSubstate.daSection;

		if (section == null || section == '') section = 'All';

		var doFunnyContinue = false;

		#if debug
		addSong('Test', 0, 'bf-pixel', 0xff7bd6f6);
		#end
		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if (leWeek.sections != null) {
				for (sex in leWeek.sections) {
					if (sex != section) {
						doFunnyContinue = true;
					} else {
						doFunnyContinue = false;
						break;
					}	
				}
			} else {
				if (section != "All") {
					doFunnyContinue = true;
				}
			}
			if (doFunnyContinue) {
				doFunnyContinue = false;
				continue;
			}
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);
		bg.screenCenter();

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
			add(bgScroll2);
		}

		gradient = new FlxSprite().loadGraphic(Paths.image('gradient'));
		add(gradient);
		gradient.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.targetY = i;
			lerpList.push(true);
			grpSongs.add(songText);

			if (songText.width > 980)
			{
				var textScale:Float = 980 / songText.width;
				songText.scale.x = textScale;
				for (letter in songText.lettersArray)
				{
					letter.x *= textScale;
					letter.offset.x *= textScale;
				}
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.bopMult = 0.95;
			icon.sprTracker = songText;

			iconArray.push(icon);
			add(icon);
			icon.copyState = true;
		}

		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		scoreText.active = false;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 98, 0xFFffffff);
		scoreBG.alpha = 0.6;
		scoreBG.active = false;
		add(scoreBG);

		/*playlistBG = new FlxSprite(scoreBG.x, scoreBG.height + 20).makeGraphic(1, 98, 0xff000000);
		playlistBG.alpha = 0.6;
		//add(playlistBG); //hiding this for now

		playlistHeaderTxt = new FlxText(playlistBG.x + (playlistBG.width / 2), playlistBG.y + 32, 0, "CUSTOM PLAYLIST", 32);
		playlistHeaderTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		//playlistHeaderTxt playlistSongsTxt
		updateSongPlaylist();*/

		ratingText = new FlxText(scoreText.x, scoreText.y + 32, 0, "", 32);
		ratingText.font = scoreText.font;
		ratingText.active = false;
		add(ratingText);

		diffText = new FlxText(scoreText.x, scoreText.y + 68, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.active = false;
		add(diffText);

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll.color = songs[curSelected].color;
			bgScroll2.color = songs[curSelected].color;
		}
		gradient.color = songs[curSelected].color;
		intendedColor = bg.color;

		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		changeSelection(0, false, true);
		changeDiff();

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 38).makeGraphic(FlxG.width, 38, 0xFF000000);
		textBG.alpha = 0.6;
		textBG.active = false;
		add(textBG);

		final leTextSplit:Array<String> = [ //easier to read
			"Press SPACE to listen to the Song. / Press CTRL to open the Gameplay Changers Menu.",
			"Press COMMA to change the Section. / Press RESET to Reset your Score and Accuracy. / Press ALT to change the player Character."
		];
		final leText:String = '${leTextSplit[0]}\n${leTextSplit[1]}';
		var size:Int = 16;
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		text.active = false;
		add(text);

		black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff000000);
        black.scrollFactor.set();
        black.visible = false;
		black.active = false;
        add(black);

		#if desktop
		DiscordClient.changePresence("In the Freeplay Menu", '"$section" Section - ${songs.length} Songs');
		#end

		hscript.call("onCreatePost", []);

		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	inline private function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*@:deprecated("`FreeplayState.addWeek` is deprecated, use `FreeplayState.addSong` instead.")
	public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	private static var vocals:FlxSound = null;
	private static var secondaryVocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		hscript.call('onUpdate', [elapsed]);
		FlxG.mouse.visible = true;

		if (FlxG.sound.music != null) {
			if (FlxG.sound.music.volume < 0.7)
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
	
			if (FlxG.sound.music != null)
				Conductor.songPosition = FlxG.sound.music.time;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.clamp(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.clamp(elapsed * 12, 0, 1));

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		bg.offset.set();

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}


		scoreText.text = 'Score: ${FlxStringUtil.formatMoney(lerpScore, false)} (${ratingSplit.join('.')}%)';
		ratingText.text = '$intendedLetter Rate, $intendedIntensity Generosity';
		switch (intendedLetter)
		{
			case 'X':
				scoreBG.color = FlxColor.YELLOW;
			case 'S':
				scoreBG.color = FlxColor.CYAN;
			case 'A':
				scoreBG.color = FlxColor.RED;
			case 'Unrated':
				ratingText.text = '$intendedLetter, $intendedIntensity Generosity';
				scoreBG.color = FlxColor.BLACK;
			default:
				scoreBG.color = FlxColor.BLACK;
		}
		positionHighscore();

		final lerpVal:Float = CoolUtil.clamp(elapsed * 9.6, 0, 1);
		for (i=>song in grpSongs.members) {
			@:privateAccess {
				if (lerpList[i]) {
					song.y = FlxMath.lerp(song.y, (song.scaledY * song.yMult) + (FlxG.height * 0.48) + song.yAdd, lerpVal);
					if(song.forceX != Math.NEGATIVE_INFINITY) {
						song.x = song.forceX;
					} else {
						switch (song.targetY) {
							case 0:
								song.x = FlxMath.lerp(song.x, (song.targetY * 20) + 90 + song.xAdd, lerpVal);
							default:
								song.x = FlxMath.lerp(song.x, (song.targetY * (song.targetY < 0 ? 20 : -20)) + 90 + song.xAdd, lerpVal);
						}
					}
				} else {
					song.y = ((song.scaledY * song.yMult) + (FlxG.height * 0.48) + song.yAdd);
					if(song.forceX != Math.NEGATIVE_INFINITY) {
						song.x = song.forceX;
					} else {
						switch (song.targetY) {
							case 0:
								song.x = ((song.targetY * 20) + 90 + song.xAdd);
							default:
								song.x = ((song.targetY * (song.targetY < 0 ? 20 : -20)) + 90 + song.xAdd);
						}
					}
				}
			}
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(songs.length > 1)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		else if (controls.UI_RIGHT_P)
			changeDiff(1);
		else if (upP || downP) changeDiff();

		if (controls.BACK)
		{
			persistentUpdate = false;
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

			FlxG.mouse.visible = false;
			return;
		}

		if(FlxG.keys.justPressed.E) {
			if(!songs[curSelected].selected) playlistSongs.push(songs[curSelected]);
			else playlistSongs.remove(songs[curSelected]);

			songs[curSelected].selected = !songs[curSelected].selected;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			updateSongPlaylist();
		}

		if (FlxG.keys.justPressed.COMMA) {
			persistentUpdate = false;
			openSubState(new FreeplaySectionSubstate());
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if(ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}

		if(space)
		{
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
			function playSong() {
				destroyFreeplayVocals();
				Paths.clearUnusedCache();
				FlxG.sound.destroy(false);
				Paths.currentModDirectory = songs[curSelected].folder;
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.header.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.header.song));
				else
					vocals = new FlxSound();

				secondaryVocals = new FlxSound().loadEmbedded(Paths.secVoices(PlayState.SONG.header.song));

				FlxG.sound.list.add(vocals);
				FlxG.sound.list.add(secondaryVocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.header.song), 0.7);
				vocals.play();
				secondaryVocals.play();
				vocals.persist = true;
				secondaryVocals.persist = true;
				vocals.looped = true;
				secondaryVocals.looped = true;
				vocals.volume = 0.7;
				secondaryVocals.volume = 0.7;
				instPlaying = curSelected;
				Conductor.songPosition = 0;
				Conductor.changeBPM(PlayState.SONG.header.bpm);
			}
			function songJsonPopup() {
				trace(poop + '\'s .ogg does not exist!');
				FlxG.sound.play(Paths.sound('invalidJSON'));
				FlxG.camera.shake(0.05, 0.05);
				var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid Song!");
				funnyText.scrollFactor.set();
				funnyText.screenCenter();
				funnyText.x = 5;
				funnyText.y = FlxG.height/2 - 64;
				funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(funnyText);
				FlxTween.tween(funnyText, {alpha: 0}, 0.9, {
					onComplete: _ -> {
						remove(funnyText, true);
						funnyText.destroy();
					}
				});
			}
			#if desktop
			if(instPlaying != curSelected)
			{
				if(sys.FileSystem.exists(Paths.inst(songLowercase + '/'  + poop)) || sys.FileSystem.exists(Paths.json('charts/' + songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.modsJson('charts/' + songLowercase + '/' + poop)))
					playSong();
				else
					songJsonPopup();
			}
			#else
			if(instPlaying != curSelected)
			{
				if(OpenFlAssets.exists(Paths.inst(songLowercase + '/' + poop)) || OpenFlAssets.exists(Paths.json('charts/' + songLowercase + '/' + poop)))
					playSong();
				else
					songJsonPopup();
			}
			#end
		} else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			function fittingName() {
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);

				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
	
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
				
				if (FlxG.keys.pressed.SHIFT){
					PlayState.chartingMode = true;
					LoadingState.loadAndSwitchState(new ChartingState());
				}else{
					LoadingState.globeTrans = false;
					LoadingState.loadAndSwitchState(new PlayState());
				}
	
				FlxG.sound.music.volume = 0;
						
				destroyFreeplayVocals();
				FlxG.mouse.visible = false;
			}
			function jsonPopup() {
				trace(poop + '.json does not exist!');
				FlxG.sound.play(Paths.sound('invalidJSON'));
				FlxG.camera.shake(0.03, 0.03);
				var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!\n" + poop + ".json");
				funnyText.scrollFactor.set();
				funnyText.screenCenter();
				funnyText.x = 5;
				funnyText.y = FlxG.height/2 - 64;
				funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(funnyText);
				FlxTween.tween(funnyText, {alpha: 0}, 0.9, {
					onComplete: _ -> {
						remove(funnyText, true);
						funnyText.destroy();
					}
				});
			}
			#if desktop
			if(sys.FileSystem.exists(Paths.modsJson('charts/' + songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.json('charts/' + songLowercase + '/' + poop)))
				fittingName();
			else
				jsonPopup();
			#else
			if(OpenFlAssets.exists(Paths.json('charts/' + songLowercase + '/' + poop)))
				fittingName();
			else
				jsonPopup();
			#end
		}

		if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if(FlxG.keys.justPressed.ALT)
		{
			persistentUpdate = false;
			openSubState(new CharacterSelectSubstate());
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if(FlxG.keys.anyJustPressed([END, HOME]))
		{
			changeSelection((FlxG.keys.pressed.END ? (songs.length - curSelected)-1 : -curSelected), true, true);
			changeDiff();
		}

		hscript.call("onUpdatePost", [elapsed]);

		super.update(elapsed);
	}

	function updateSongPlaylist() {

	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			secondaryVocals.stop();
			vocals.destroy();
			secondaryVocals.destroy();
		}
		vocals = null;
		secondaryVocals = null;
	}

	function changeDiff(change:Int = 0)
	{
		hscript.call('onChangeDifficulty', [change]);

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		intendedLetter = Highscore.getLetter(songs[curSelected].songName, curDifficulty);
		intendedIntensity = Highscore.getIntensity(songs[curSelected].songName, curDifficulty);

		PlayState.storyDifficulty = curDifficulty;
		if (CoolUtil.difficulties.length > 1) {
			if (curDifficulty <= 0) {
				diffText.text = CoolUtil.toTitleCase(CoolUtil.difficultyString().toLowerCase()) + ' >>>';
			} else if (curDifficulty >= CoolUtil.difficulties.length-1) {
				diffText.text = '<<< ' + CoolUtil.toTitleCase(CoolUtil.difficultyString().toLowerCase());
			} else {
				diffText.text = '<<< ' + CoolUtil.toTitleCase(CoolUtil.difficultyString().toLowerCase()) + ' >>>';
			}
		} else {
			diffText.text = CoolUtil.toTitleCase(CoolUtil.difficultyString().toLowerCase());
		}

		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true, ?allActive:Bool = false)
	{
		hscript.call('onChangeSelection', [change]);

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			if (!ClientPrefs.settings.get("lowQuality")) {
				if(bgScrollColorTween != null) {
					bgScrollColorTween.cancel();
				}
				if(bgScroll2ColorTween != null) {
					bgScroll2ColorTween.cancel();
				}
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
				bgScroll2ColorTween = FlxTween.color(bgScroll2, 1, bgScroll2.color, intendedColor, {
					onComplete: function(twn:FlxTween) {
						bgScroll2ColorTween = null;
					}
				});
			}
			gradientColorTween = FlxTween.color(gradient, 1, gradient.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					gradientColorTween = null;
				}
			});
		}

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		intendedLetter = Highscore.getLetter(songs[curSelected].songName, curDifficulty);
		intendedIntensity = Highscore.getIntensity(songs[curSelected].songName, curDifficulty);

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].visible = true;
			iconArray[i].active = true;
			iconArray[i].alpha = 0.6;
			iconArray[i].animation.curAnim.curFrame = 0;
		}

		iconArray[curSelected].alpha = 1;
		if (iconArray[curSelected].type == WINNING)
			iconArray[curSelected].animation.curAnim.curFrame = 2;

		for (i=>item in grpSongs.members)
		{
			item.active = item.visible = lerpList[i] = true;
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
			if (!allActive) {
				if (Math.abs(item.targetY) > 7 && !(curSelected == 0 || curSelected == songs.length - 1)) {
					item.active = item.visible = lerpList[i] = false;
				}
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		#if debug //doesnt have a week
		if (songs[curSelected].songName == 'Test') diffStr = 'Normal';
		#end
		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		if (scoreText.width > ratingText.width) {
			scoreText.x = FlxG.width - scoreText.width - 6;
			ratingText.x = scoreText.x;
			scoreBG.scale.x = FlxG.width - scoreText.x + 6;
			scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		} else {
			ratingText.x = FlxG.width - ratingText.width - 6;
			scoreText.x = ratingText.x;
			scoreBG.scale.x = FlxG.width - ratingText.x + 6;
			scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		}
		
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	override function beatHit() {
		super.beatHit();

		hscript.call('onBeatHit', [curBeat]);

		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		bg.offset.set();
		for (i in 0...iconArray.length)
		{
			if (iconArray[i].isOnScreen() && iconArray[i] != null) {
				iconArray[i].bop({curBeat: curBeat}, "Bop");
			}
		}
	}

	override function destroy(){
		super.destroy();
		instance = null;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var selected:Bool = false; //so I dont need to check the array for if the song exists in it

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
