package;

import Song.SwagSong;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

/**
* Class used to control all timing related functions for bpm.
*/
class Conductor
{
	/**
	* Current Beats per Minute (NOT AN INTEGER!).
	*/
	public static var bpm:Float = 100;
	/**
	* Current Beats per Minute in Milliseconds.
	*/
	public static var crochet:Float = ((60 / bpm) * 1000);
	/**
	* Current Steps per Minute in Milliseconds.
	*/
	public static var stepCrochet:Float = crochet / 4;
	/**
	* Current Song position in Milliseconds.
	*/
	public static var songPosition:Float = 0;
	@:keep public static var lastSongPos:Float; // just in case DCE tries to remove them (when you're not using hscript)
	@:keep public static var offset:Float = 0;

	public static var safeZoneOffset:Float = (ClientPrefs.settings.get("safeFrames") / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	/**
	* Map of the bpm changes in the current song.
	* Each element of the array contains stepTime, songTime, and the new bpm.
	*/
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function judgeNote(note:Note, diff:Float=0, ?bot:Bool = false)
	{
		if (bot) return 'perfect';

		final timingWindows:Array<Int> = [ClientPrefs.settings.get("perfectWindow"), ClientPrefs.settings.get("sickWindow"), ClientPrefs.settings.get("goodWindow"), ClientPrefs.settings.get("badWindow"), ClientPrefs.settings.get("shitWindow")];
		final windowNames:Array<String> = ['perfect', 'sick', 'good', 'bad', 'shit'];

		for(i in 0...timingWindows.length)
		{
			if (diff <= timingWindows[i]) {
				return windowNames[i];
			}
		}
		return 'wtf';
	}

	/**
	 * Creates a new `bpmChangeMap` from the inputted song.
	 *
	 * @param	song	Song to take the BPM and time signature changes from.
	 */	
	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.header.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if(song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		//trace("new BPM map BUDDY " + bpmChangeMap);
	}

	/**
	 * Changes the Conductor's BPM.
	 *
	 * @param	newBpm	The BPM to change to.
	 */
	public static function changeBPM(newBpm:Float)
	{
		if (newBpm <= 0) return;

		bpm = newBpm;
		crochet = getCrochet(bpm);
		stepCrochet = crochet / 4;
	}

	inline public static function getCrochet(bpm:Float){
		return (60 / bpm) * 1000;
	}
}
