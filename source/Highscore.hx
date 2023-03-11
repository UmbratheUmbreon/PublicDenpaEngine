package;

/**
* Class used to save and load Highscores.
*/
class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map();
	public static var songRating:Map<String, Float> = new Map();
	public static var songLetter:Map<String, String> = new Map();
	public static var songIntensity:Map<String, String> = new Map();

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 0);
		setLetter(daSong, 'Unrated');
		setIntensity(daSong, 'Unknown');
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	inline public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1) return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals) { tempMult *= 10; }
		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:Float = -1, ?letter:String = 'Unrated', ?intensity:String = 'Unknown'):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				if(rating >= 0) setRating(daSong, rating);
				setLetter(daSong, letter);
				setIntensity(daSong, intensity);
			}
		}
		else {
			setScore(daSong, score);
			if(rating >= 0) setRating(daSong, rating);
			setLetter(daSong, letter);
			setIntensity(daSong, intensity);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else
			setWeekScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:Float):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	static function setLetter(song:String, letter:String):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songLetter.set(song, letter);
		FlxG.save.data.songLetter = songLetter;
		FlxG.save.flush();
	}

	static function setIntensity(song:String, intensity:String):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songIntensity.set(song, intensity);
		FlxG.save.data.songIntensity = songIntensity;
		FlxG.save.flush();
	}

	inline public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + CoolUtil.getDifficultyFilePath(diff);
	}

	inline public static function getScore(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong)) setScore(daSong, 0);

		return songScores.get(daSong);
	}

	inline public static function getRating(song:String, diff:Int):Float
	{
		var daSong:String = formatSong(song, diff);
		if (!songRating.exists(daSong)) setRating(daSong, 0);

		return songRating.get(daSong);
	}

	inline public static function getLetter(song:String, diff:Int):String
	{
		var daSong:String = formatSong(song, diff);
		if (!songLetter.exists(daSong)) setLetter(daSong, 'Unrated');

		return songLetter.get(daSong);
	}

	inline public static function getIntensity(song:String, diff:Int):String
	{
		var daSong:String = formatSong(song, diff);
		if (!songIntensity.exists(daSong)) setIntensity(daSong, 'Unknown');

		return songIntensity.get(daSong);
	}

	inline public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek)) setWeekScore(daWeek, 0);

		return weekScores.get(daWeek);
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null) weekScores = FlxG.save.data.weekScores;
		if (FlxG.save.data.songScores != null) songScores = FlxG.save.data.songScores;
		if (FlxG.save.data.songRating != null) songRating = FlxG.save.data.songRating;
		if (FlxG.save.data.songLetter != null) songLetter = FlxG.save.data.songLetter;
		if (FlxG.save.data.songIntensity != null) songIntensity = FlxG.save.data.songIntensity;
	}
}
