package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;

using StringTools;

/**
* State used to select and load a single song to play.
* Only the songs in the currently selected section will appear!
*/
class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

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

	var section:String = '';

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		section = FreeplaySectionState.daSection;

		if (section == null || section == '') section = 'All';

		var doFunnyContinue = false;

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

		//Unclear whether i need this or not
		//Gonna leave it unused unless shit goes down
		//if (songs == null) {
		//	addSong("Tutorial", 1, "gf", FlxColor.fromRGB(165, 0, 77));
		//}

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('data/fuckYourWeeks'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		if (!ClientPrefs.lowQuality) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll);
	
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
			bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
			bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
			add(bgScroll2);
		}

		gradient = new FlxSprite().loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		add(gradient);
		gradient.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.altRotation = true;
			songText.targetY = i;
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
				//songText.updateHitbox();
				//trace(songs[i].songName + ' new scale: ' + textScale);
			}

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 98, 0xFFffffff);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		ratingText = new FlxText(scoreText.x, scoreText.y + 32, 0, "", 32);
		ratingText.font = scoreText.font;
		add(ratingText);

		diffText = new FlxText(scoreText.x, scoreText.y + 68, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		if (!ClientPrefs.lowQuality) {
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
		
		changeSelection();
		changeDiff();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
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

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
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
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		//else {
			//Conductor.songPosition = vocals.time;
		//}
		//trace('song positon ' + Conductor.songPosition);

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		
		for (i in 0...iconArray.length)
		{
			var mult:Float = FlxMath.lerp(1, iconArray[i].scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
			iconArray[i].scale.set(mult, mult);
			iconArray[i].updateHitbox();
		}

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

		switch (intendedLetter)
		{
			case 'X':
				scoreText.text = 'Score: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
				ratingText.text = intendedLetter + ' Rate, ' + intendedIntensity + ' Generosity';
				scoreBG.color = FlxColor.YELLOW;
			case 'S':
				//scoreText.text = 'PERSONAL BEST: ' + lerpScore + '(' + intendedIntensity + '), ' + intendedLetter + ' Rate (' + ratingSplit.join('.') + '%)';
				scoreText.text = 'Score: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
				ratingText.text = intendedLetter + ' Rate, ' + intendedIntensity + ' Generosity';
				scoreBG.color = FlxColor.CYAN;
			case 'A':
				scoreText.text = 'Score: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
				ratingText.text = intendedLetter + ' Rate, ' + intendedIntensity + ' Generosity';
				scoreBG.color = FlxColor.RED;
			case 'Unrated':
				scoreText.text = 'Score: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
				ratingText.text = intendedLetter + ', ' + intendedIntensity + ' Generosity';
				scoreBG.color = FlxColor.BLACK;
			default:
				scoreText.text = 'Score: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
				ratingText.text = intendedLetter + ' Rate, ' + intendedIntensity + ' Generosity';
				scoreBG.color = FlxColor.BLACK;
		}
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (FlxG.mouse.justPressed && ClientPrefs.mouseControls) accepted = true;

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

			if(FlxG.mouse.wheel != 0 && ClientPrefs.mouseControls)
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

		if (controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls))
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
			MusicBeatState.switchState(new FreeplaySectionState());
		}

		if(ctrl)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(space)
		{
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
			#if desktop
			if(instPlaying != curSelected)
			{
				if(sys.FileSystem.exists(Paths.inst(songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop))) {
				destroyFreeplayVocals();
				Paths.clearUnusedMemory();
				FlxG.sound.music.volume = 0;
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
				//trace('bpm is' + PlayState.SONG.bpm);
				} else {
					trace(poop + '\'s .ogg does not exist!');
					FlxG.sound.play(Paths.sound('invalidJSON'));
					FlxG.camera.shake(0.05, 0.05);
					var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid Song!");
					funnyText.scrollFactor.set();
					funnyText.screenCenter();
					funnyText.x = FlxG.width/2 - 250;
					funnyText.y = FlxG.height/2 - 64;
					funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					add(funnyText);
					FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
						onComplete: function(tween:FlxTween)
						{
							funnyText.destroy();
						}
					});
				} 
			}
			#else
			if(instPlaying != curSelected)
				{
					if(OpenFlAssets.exists(Paths.inst(songLowercase + '/' + poop)) || OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
					destroyFreeplayVocals();
					Paths.clearUnusedMemory();
					FlxG.sound.music.volume = 0;
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
					//trace('bpm is' + PlayState.SONG.bpm);
					} else {
						trace(poop + '\'s .ogg does not exist!');
						FlxG.sound.play(Paths.sound('invalidJSON'));
						FlxG.camera.shake(0.05, 0.05);
						var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid Song!");
						funnyText.scrollFactor.set();
						funnyText.screenCenter();
						funnyText.x = FlxG.width/2 - 250;
						funnyText.y = FlxG.height/2 - 64;
						funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
						add(funnyText);
						FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
							onComplete: function(tween:FlxTween)
							{
								funnyText.destroy();
							}
						});
					} 
				}
			#end
		}

		else if (accepted)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			#if desktop
			if(sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) || sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
				trace(poop);

				PlayState.SONG = Song.loadFromJson(poop, songLowercase);

				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
	
				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
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
			} else {
				trace(poop + '.json does not exist!');
				FlxG.sound.play(Paths.sound('invalidJSON'));
				FlxG.camera.shake(0.05, 0.05);
				var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!");
				funnyText.scrollFactor.set();
				funnyText.screenCenter();
				funnyText.x = FlxG.width/2 - 250;
				funnyText.y = FlxG.height/2 - 64;
				funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(funnyText);
				FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
					onComplete: function(tween:FlxTween)
					{
						funnyText.destroy();
					}
				});
			}
			#else
			if(OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
				trace(poop);

				PlayState.SONG = Song.loadFromJson(poop, songLowercase);

				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
	
				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
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
			} else {
				trace(poop + '.json does not exist!');
				FlxG.sound.play(Paths.sound('invalidJSON'));
				FlxG.camera.shake(0.05, 0.05);
				var funnyText = new FlxText(12, FlxG.height - 24, 0, "Invalid JSON!");
				funnyText.scrollFactor.set();
				funnyText.screenCenter();
				funnyText.x = FlxG.width/2 - 250;
				funnyText.y = FlxG.height/2 - 64;
				funnyText.setFormat("VCR OSD Mono", 64, FlxColor.RED, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				add(funnyText);
				FlxTween.tween(funnyText, {alpha: 0}, 0.6, {
					onComplete: function(tween:FlxTween)
					{
						funnyText.destroy();
					}
				});
			}
			#end
		}
		else if(controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		super.update(elapsed);
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
		//Conductor.songPosition = 0;
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		intendedLetter = Highscore.getLetter(songs[curSelected].songName, curDifficulty);
		intendedIntensity = Highscore.getIntensity(songs[curSelected].songName, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		if (CoolUtil.difficulties.length > 1) {
			if (curDifficulty <= 0) {
				diffText.text = CoolUtil.formatStringProper(CoolUtil.difficultyString().toLowerCase()) + ' >>>';
			} else if (curDifficulty >= CoolUtil.difficulties.length-1) {
				diffText.text = '<<< ' + CoolUtil.formatStringProper(CoolUtil.difficultyString().toLowerCase());
			} else {
				diffText.text = '<<< ' + CoolUtil.formatStringProper(CoolUtil.difficultyString().toLowerCase()) + ' >>>';
			}
		} else {
			diffText.text = CoolUtil.formatStringProper(CoolUtil.difficultyString().toLowerCase());
		}

		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
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
			if (!ClientPrefs.lowQuality) {
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
			if (!ClientPrefs.lowQuality) {
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
		//CustomFadeTransition.colorForFunnyGrad = newColor; //looks weird

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		intendedLetter = Highscore.getLetter(songs[curSelected].songName, curDifficulty);
		intendedIntensity = Highscore.getIntensity(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
			iconArray[i].animation.curAnim.curFrame = 0;
		}

		iconArray[curSelected].alpha = 1;
		if (iconArray[curSelected].widthThing == 450)
			iconArray[curSelected].animation.curAnim.curFrame = 2;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

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
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
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

	//var lastBeatHit:Int = -1;

	override function beatHit() {
		super.beatHit();

		//if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			//return;
		//}
		bg.scale.set(1.06,1.06);
		bg.updateHitbox();
		for (i in 0...iconArray.length)
			{
				iconArray[i].scale.set(1.10, 1.10);
				iconArray[i].updateHitbox();
			}
		//lastBeatHit = curBeat;
		//trace('beat hit' + curBeat);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

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