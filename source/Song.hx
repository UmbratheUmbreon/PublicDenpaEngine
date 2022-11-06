package;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

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
	var events:Array<Dynamic>;
}

/**
* Typedef used to create the header in `Song` jsons.
*/
typedef SongHeader = {
	var song:String;
	var bpm:Float;
	var needsVoices:Bool;
	var instVolume:Null<Float>;
	var vocalsVolume:Null<Float>;
	var secVocalsVolume:Null<Float>;
	var validScore:Bool;
}

/**
* Typedef used to create the asset definitions in `Song` jsons.
*/
typedef SongAssets = {
	var player1:String;
	var player2:String;
	var player3:String; //deprecated, now replaced by gfVersion
	var gfVersion:String;
	var enablePlayer4:Bool;
	var player4:String;
	var arrowSkin:String;
	var splashSkin:String;
	var stage:String;
}

/**
* Typedef used to create the options definitions in `Song` jsons.
*/
typedef SongOptions =
{
	var speed:Float;
	var mania:Null<Int>;
	var autoIcons:Bool;
	var autoIdles:Bool;
	var autoZooms:Bool;
	var dangerMiss:Bool;
	var crits:Bool;
	var allowBot:Bool;
	var allowGhostTapping:Bool;
	var beatDrain:Bool;
	var tintRed:Null<Int>;
	var tintGreen:Null<Int>;
	var tintBlue:Null<Int>;
	var modchart:String;
	var dadModchart:String;
	var p4Modchart:String;
	var credits:String;
	var remixCreds:String;
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
	public var events:Array<Dynamic>;

	private static function onLoadJson(songJson:SwagSong) // Convert old charts to newest format
	{
		//DONT MESS WITH THIS SHIT!!! -AT
		if (songJson.assets.gfVersion == null) {
			songJson.assets.gfVersion = songJson.assets.player3;
			songJson.assets.player3 = null;
		}
		//idk if this works or not but i cant really test it
		if (songJson.options.mania == null)
        {
			/*var estimateMania:Int = 0;
			for (section in songJson.notes) {
				for (note in section.sectionNotes) {
					if (note[1] > estimateMania) estimateMania == note[1];
				}
			}*/
            songJson.options.mania = Note.defaultMania;
        }

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
	}

	public function new(song, notes, bpm)
	{
		this.header.song = song;
		this.notes = notes;
		this.header.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var path:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if (!FileSystem.exists(path)) {
			path = Paths.json(formattedFolder + '/' + formattedSong);
		}
		#else
		var path:String = Paths.json(formattedFolder + '/' + formattedSong);
		#end
		//trace (path);

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
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		var songJson:SwagSong = parseJSONshit(rawJson);
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var songJson:SwagSong;
		var oldSongJson:OldSong;
		try {
			songJson = cast Json.parse(rawJson).song;
			songJson.header.validScore = true;
		} catch (e) {
			//yes honey i know you work, now please shut the fuck up <3
			//trace('\n<----ERROR---->\n' + e + '\nSong JSON was detected invalid/old, attempting conversion...\n<-------->');
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
			songJson = null;
			songJson = {
				header: {
					song: oldSongJson.song,
					bpm: oldSongJson.bpm,
					needsVoices: oldSongJson.needsVoices,
					instVolume: oldSongJson.instVolume,
					vocalsVolume: oldSongJson.vocalsVolume,
					secVocalsVolume: oldSongJson.secVocalsVolume,
					validScore: true
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
					autoIcons: oldSongJson.autoIcons,
					autoIdles: oldSongJson.autoIdles,
					autoZooms: oldSongJson.autoZooms,
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
		}
		return songJson;
	}
}

/**
* Typedef used to create the section definitions in `Song` jsons.
*/
typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
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
	var type:String;
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
* Class containing all related functions for section loading and control.
*/
class Section
{
	public var sectionNotes:Array<Dynamic> = [];

	public var lengthInSteps:Int = 16;
	public var gfSection:Bool = false;
	public var crossFade:Bool = false;
	public var typeOfSection:Int = 0;
	public var mustHitSection:Bool = true;
	public var player4Section:Bool = false;

	/**
	 *	Copies the first section into the second section!
	 */
	public static var COPYCAT:Int = 0;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}

/**
* Typedef used to convert old song jsons into the new song jsons.
*/
typedef OldSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var instVolume:Null<Float>;
	var vocalsVolume:Null<Float>;
	var secVocalsVolume:Null<Float>;
	var needsVoices:Bool;
	var autoIcons:Bool;
	var autoIdles:Bool;
	var autoZooms:Bool;
	var dangerMiss:Bool;
	var crits:Bool;
	var allowBot:Bool;
	var allowGhostTapping:Bool;
	var beatDrain:Bool;
	var enablePlayer4:Bool;
	var speed:Float;
	var tintRed:Null<Int>;
	var tintGreen:Null<Int>;
	var tintBlue:Null<Int>;

	var player1:String;
	var player2:String;
	var player4:String;
	var player3:String; //deprecated, now replaced by gfVersion
	var gfVersion:String;
	var stage:String;
	var modchart:String;
	var dadModchart:String;
	var p4Modchart:String;
	var credits:String;
	var remixCreds:String;

	var mania:Null<Int>;

	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
}
