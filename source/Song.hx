package;

import haxe.Json;

/**
* Typedef used to create `Song` jsons.
*/
typedef SwagSong =
{
	//header shit
	var header:SongHeader;

	//assets shit
	var assets:SongAssets;

	//chart shit
	var options:SongOptions;
	var notes:Array<SwagSection>;
	var events:Array<Array<Dynamic>>;
}

/**
* Typedef used to create the header in `Song` jsons.
*/
typedef SongHeader = {
	var song:String;
	var bpm:Float;
	var needsVoices:Bool;
	var ?instVolume:Null<Float>;
	var ?vocalsVolume:Null<Float>;
	var ?secVocalsVolume:Null<Float>;
}

/**
* Typedef used to create the asset definitions in `Song` jsons.
*/
typedef SongAssets = {
	var player1:String;
	var player2:String;
	var ?player3:String; //deprecated, now replaced by gfVersion
	var ?player4:String;
	var gfVersion:String;
	var ?enablePlayer4:Bool;
	var ?arrowSkin:String;
	var ?splashSkin:String;
	var ?stage:String;
}

/**
* Typedef used to create the options definitions in `Song` jsons.
*/
typedef SongOptions =
{
	var speed:Float;
	var ?mania:Null<Int>;
	var ?dangerMiss:Null<Bool>;
	var ?crits:Null<Bool>;
	var ?allowBot:Null<Bool>;
	var ?allowGhostTapping:Null<Bool>;
	var ?beatDrain:Null<Bool>;
	var ?tintRed:Null<Int>;
	var ?tintGreen:Null<Int>;
	var ?tintBlue:Null<Int>;
	var ?modchart:String;
	var ?dadModchart:String;
	var ?p4Modchart:String;
	var ?credits:String;
	var ?remixCreds:String;
}

/**
* Class containing all related functions for song loading and control.
*/
class Song
{
	public var header:SongHeader;
	public var assets:SongAssets;
	public var options:SongOptions;
	public var notes:Array<SwagSection>;
	public var events:Array<Array<Dynamic>>;

	private static function onLoadJson(songJson:SwagSong):SwagSong // Convert old charts to newest format
	{
		//DONT MESS WITH THIS SHIT!!! -AT
		if (songJson.assets.gfVersion == null) {
			songJson.assets.gfVersion = songJson.assets.player3;
			songJson.assets.player3 = null;
		}

		if (songJson.options.mania == null) /*{
			var max:Int = 0;
			for (section in songJson.notes) {
				for (note in section.sectionNotes) {
					max = (note[1] % uhhhhh > max ? note[1] % uhhhhh : max);
				}
			}
			songJson.options.mania = max;
		}*/
            songJson.options.mania = Note.defaultMania;

		if (songJson.options.allowBot == null)
			songJson.options.allowBot = true;

		if (songJson.options.allowGhostTapping == null)
			songJson.options.allowGhostTapping = true;

		if (songJson.options.dangerMiss == null)
			songJson.options.dangerMiss = false;

		if (songJson.options.beatDrain == null)
			songJson.options.beatDrain = false;

		if (songJson.options.crits == null)
			songJson.options.crits = false;

		if (songJson.assets.splashSkin == 'noteSplashes')
			songJson.assets.splashSkin = 'splashes/noteSplashes';


		//dont need it i think???
		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
		return songJson;
	}

	public function new(name:String) loadFromJson(name);

	//this would be so much faster if all i had to do was return song.notes.length... BUT THE NOTES ARE NESTED INSIDE THE SECTIONS!
	inline public static function getNoteCount(song:SwagSong):Int {
		var total:Int = 0;
		for (section in song.notes) {
			total += section.sectionNotes.length;
		}
		return total;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = 'charts/' + Paths.formatToSongPath(folder);
		if (formattedFolder == 'charts/') formattedFolder = 'charts';
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var path:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if (!FileSystem.exists(path)) {
			path = Paths.json(formattedFolder + '/' + formattedSong);
		}
		#else
		var path:String = Paths.json(formattedFolder + '/' + formattedSong);
		#end

		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path).trim();
		}
		#end

		if(rawJson == null) {
			#if sys
			rawJson = File.getContent(path).trim();
			#else
			rawJson = Assets.getText(path).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		var songJson:SwagSong = parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		return onLoadJson(songJson);
	}

	static inline function convertChart(rawJson:String) {
		var songJson:SwagSong;
		var oldSongJson:OldSong;
		oldSongJson = cast Json.parse(rawJson).song;
		//holy shit this hurt my head, im just gonna save this for later
		/*var oldEvents = oldSongJson.events;
		var newEvents:Array<SwagEvent>;
		if (oldEvents != null) {
			for (event in oldEvents) {
				var newEventData:Array<SwaggerEvent>;
				var oldEventShitter:Array<Array<Dynamic>> = oldEvents[1];
				for (eventers in oldEventShitter) {
					var newShitter:SwaggerEvent = {
						name: eventers[0],
						value1: eventers[1],
						value2: eventers[2]
					}
					newEventData.push(newShitter);
				}
				var newEvent:SwagEvent = {
					msTime: event[0],
					events: newEventData
				}
				newEvents.push(newEvent);
			}
		}*/
		//casting my beloathed
		var newLengths:Array<Dynamic> = [];
		if (oldSongJson.notes != null) {
			for (secData in oldSongJson.notes) {
				if(secData.sectionBeats != null) {
					newLengths.push(Std.int(secData.sectionBeats*4));
				} else {
					newLengths.push(16);
					continue;
				}
			}
			for (i in 0...oldSongJson.notes.length) {
				if(oldSongJson.notes[i].lengthInSteps == null) {
					oldSongJson.notes[i].lengthInSteps = newLengths[i];
				}
			} //Adds support for psych 0.6+ charts???
		}
		songJson = null;
		songJson = {
			header: {
				song: oldSongJson.song,
				bpm: oldSongJson.bpm,
				needsVoices: oldSongJson.needsVoices,
				instVolume: oldSongJson.instVolume,
				vocalsVolume: oldSongJson.vocalsVolume,
				secVocalsVolume: oldSongJson.secVocalsVolume,
			},
			assets: {
				player1: oldSongJson.player1,
				player2: oldSongJson.player2,
				player3: oldSongJson.player3,
				gfVersion: oldSongJson.gfVersion,
				enablePlayer4: oldSongJson.enablePlayer4,
				player4: oldSongJson.player4,
				arrowSkin: oldSongJson.arrowSkin,
				splashSkin: oldSongJson.splashSkin,
				stage: oldSongJson.stage
			},
			options: {
				speed: oldSongJson.speed,
				mania: oldSongJson.mania,
				dangerMiss: oldSongJson.dangerMiss,
				crits: oldSongJson.crits,
				allowBot: oldSongJson.allowBot,
				allowGhostTapping: oldSongJson.allowGhostTapping,
				beatDrain: oldSongJson.beatDrain,
				tintRed: oldSongJson.tintRed,
				tintGreen: oldSongJson.tintGreen,
				tintBlue: oldSongJson.tintBlue,
				modchart: oldSongJson.modchart,
				dadModchart: oldSongJson.dadModchart,
				p4Modchart: oldSongJson.p4Modchart,
				credits: oldSongJson.credits,
				remixCreds: oldSongJson.remixCreds
			},
			notes: oldSongJson.notes,
			events: oldSongJson.events
		}
		oldSongJson = null;
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		final songJson:SwagSong = cast Json.parse(rawJson).song;
		return (songJson.header == null ? convertChart(rawJson) : songJson);
	}
}

/**
* Typedef used to create the section definitions in `Song` jsons.
*/
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Null<Int>;
	var ?sectionBeats:Null<Float>;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var player4Section:Bool;
	var crossFade:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

/**
* Typedef used to create the note definitions in `Song` jsons.
*/
typedef SwagNote =
{
	var msTime:Float;
	var data:Int;
	var sustainLength:Float;
	var ?type:String;
}

/**
* Typedef used to create the event group definitions in `Song` jsons.
*/
typedef SwagEvent =
{
	var msTime:Float;
	var events:Array<SwaggerEvent>;
}

/**
* Typedef used to create the event definitions in `Song` jsons.
*/
typedef SwaggerEvent =
{
	var name:String;
	var value1:String;
	var value2:String;
}

/**
* Typedef used to convert old song jsons into the new song jsons.
*/
typedef OldSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Array<Dynamic>>;
	var bpm:Float;
	var ?instVolume:Null<Float>;
	var ?vocalsVolume:Null<Float>;
	var ?secVocalsVolume:Null<Float>;
	var needsVoices:Bool;
	var ?dangerMiss:Bool;
	var ?crits:Bool;
	var ?allowBot:Bool;
	var ?allowGhostTapping:Bool;
	var ?beatDrain:Bool;
	var ?enablePlayer4:Bool;
	var speed:Float;
	var ?tintRed:Null<Int>;
	var ?tintGreen:Null<Int>;
	var ?tintBlue:Null<Int>;

	var player1:String;
	var player2:String;
	var ?player4:String;
	var ?player3:String; //deprecated, now replaced by gfVersion
	var gfVersion:String;
	var ?stage:String;
	var ?modchart:String;
	var ?dadModchart:String;
	var ?p4Modchart:String;
	var ?credits:String;
	var ?remixCreds:String;

	var ?mania:Null<Int>;

	var ?arrowSkin:String;
	var ?splashSkin:String;
}
