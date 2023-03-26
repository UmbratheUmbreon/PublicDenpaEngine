package;

import flash.media.Sound;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

/**
* Class used for all pathfinding in the game.
* This class should be used instead of the default Flixel method of loading assets.
*/
class Paths
{
	inline public static final SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static final VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static final ignoreModFolders:Array<String> = [
		'data',
		'fonts',
		'images',
		'music',
		'scripts',
		'shaders',
		'songs',
		'sounds',
		'videos'
	];
	#end

	inline public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/music/elevator.$SOUND_EXT',
		'assets/sounds/bfBeep.$SOUND_EXT',
		'assets/sounds/scrollMenu.$SOUND_EXT',
		'assets/sounds/confirmMenu.$SOUND_EXT',
		'assets/sounds/cancelMenu.$SOUND_EXT'
	];
	/// haya I love you for the base cache dump I took to the max
	/**
	* Clear unused cache items.
	* 
	* Only clears bitmap caches!
	*/
	public static function clearUnusedCache() {
		for (key in currentTrackedAssets) {
			if ((!localTrackedAssets.contains(key) || freeableAssets.contains(key)) && !dumpExclusions.contains(key)) {
				var obj = FlxG.bitmap.get(key);
				@:privateAccess
				if (obj != null) {
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.dump();
					obj.destroy();
				}
				currentTrackedAssets.remove(key);
			}
		}
		freeableAssets = [];
		#if cpp
		cpp.vm.Gc.run(false);
		#else
		openfl.system.System.gc();
		#end
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];
	//shit to be freed on next unused dump
	//must be handled manually.
	public static var freeableAssets:Array<String> = [];
	/**
	* Clear all cached items.
	* 
	* @param cleanUnused A `Bool` to determine whether unused cache should be cleared as well. Default false.
	*/
	public static function clearStoredCache(?cleanUnused:Bool = false) {
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap.get(key);
			if (obj != null && !currentTrackedAssets.contains(key)) {
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.dump();
				obj.destroy();
			}
		}

		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key) 
			&& !dumpExclusions.contains(key) && key != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
		if (!cleanUnused) return;
		clearUnusedCache();
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
	{
		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type)) return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type)) return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String)
		return '$library:assets/$library/$file';

	inline public static function getPreloadPath(file:String = '')
		return 'assets/$file';

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('data/$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('data/$key.json', TEXT, library);

	inline static public function update(key:String, ?library:String)
		return getPath('update/$key', TEXT, library);

	inline static public function frag(key:String, ?library:String)
		return File.getContent(getPath('data/shaders/$key.frag', TEXT, library));

	inline static public function vert(key:String, ?library:String)
		return File.getContent(getPath('data/shaders/$key.vert', TEXT, library));

	inline static public function lua(key:String, ?library:String)
		return getPath('$key.lua', TEXT, library);

    inline static public function hscript(key:String, ?library:String)
	{
       	#if MODS_ALLOWED
       	if (FileSystem.exists(modsHscript(key))) return modsHscript(key);
       	#end
       	return getPath('$key.hscript', TEXT, library);
    }

	inline static public function atlas(key:String, ?library:String)
	{
       	#if MODS_ALLOWED
       	if (FileSystem.exists(modsAtlas(key))) return modsAtlas(key);
       	#end
       	return getPath('$key/Animation.json', TEXT, library);
    }

	inline static public function video(key:String)
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(modsVideo(key))) return modsVideo(key);
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?library:String):Sound
		return returnSound('sounds', key, library);
	
	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String):Sound
		return returnSound('music', key, library);

	inline static public function voices(song:String):Any
		return returnSound('songs', '${formatToSongPath(song)}/Voices');

	inline static public function inst(song:String):Any
		return returnSound('songs', '${formatToSongPath(song)}/Inst');

	inline static public function secVoices(song:String)
		return returnSound('songs', '${formatToSongPath(song)}/SecVoices');

	inline static public function image(key:String, ?library:String, ?persist:Bool = true):FlxGraphic
		return returnGraphic(key, library, !persist);
	
	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String	
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key))) return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getPreloadPath(key))) return File.getContent(getPreloadPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath)) return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath)) return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(modsFont(key))) return modsFont(key);
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(mods('$currentModDirectory/$key')) || FileSystem.exists(mods(key))) return true;
		#end
		if(OpenFlAssets.exists(getPath(key, type))) return true;

		return false;
	}

	inline static public function getXmlPath(key:String, ?library:String):String
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(modsXml(key))) return modsXml(key);
		#end
		return xml(key, library);
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = false;
		if(FileSystem.exists(modsXml(key))) xmlExists = true;

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getTexturePacker(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = false;
		if(FileSystem.exists(modsXml(key))) xmlExists = true;
	
		return FlxAtlasFrames.fromTexturePackerXml((imageLoaded != null ? imageLoaded : image(key, library)), (xmlExists ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromTexturePackerXml(image(key, library), file('images/$key.xml', library));
		#end
	}


	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = false;
		if(FileSystem.exists(modsTxt(key))) txtExists = true;

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)), (txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]+/g;
		var hideChars = ~/[.,'"%?!]+/g;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Array<String> = [];
	inline public static function returnGraphic(key:String, ?library:String, ?noPersist:Bool = false) {
		#if MODS_ALLOWED
		var path:String = modsImages(key);
		if(FileSystem.exists(path)) {
			if(!currentTrackedAssets.contains(path) && !FlxG.bitmap.checkCache(path)) {
				var graphic:FlxGraphic;
				var bitmap = BitmapData.fromFile(path);
				graphic = FlxGraphic.fromBitmapData(bitmap, false, path);
				graphic.persist = !noPersist;
				currentTrackedAssets.push(path);
			}
			localTrackedAssets.push(path);
			return FlxG.bitmap.get(path);
		}
		#end

		path = getPath('images/$key.png', IMAGE, library);
		if (OpenFlAssets.exists(path, IMAGE)) {
			if(!currentTrackedAssets.contains(path) && !FlxG.bitmap.checkCache(path)) {
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = !noPersist;
				currentTrackedAssets.push(path);
			}
			localTrackedAssets.push(path);
			return FlxG.bitmap.get(path);
		}

		trace('oh no its returning null NOOOO: images/$key.png, library: $library using mods? ${#if MODS_ALLOWED 'yes' #else 'no' #end}');
		return null;
	}

	inline public static function returnCompressedSound(path:String):Sound {
		var bytes = openfl.utils.ByteArray.fromFile(path);
		bytes.compress();
		var sound = new Sound();
		sound.loadCompressedDataFromByteArray(bytes, bytes.length);
		return sound;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	inline public static function returnSound(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);	
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath)) 
		#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./$gottenPath'));
		#else
		{
			var folder:String = '';
			#if html5
			if(path == 'songs') folder = 'songs:';
			#end
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		}
		#end
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}
	
	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/$key';
	
    inline static public function modsHscript(key:String)
		return modFolders('$key.hscript');

	inline static public function modsAtlas(key:String)
		return modFolders('$key/Animation.json');

	inline static public function modsFont(key:String)
		return modFolders('fonts/$key');

	inline static public function modsJson(key:String)
		return modFolders('data/$key.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/$key.$VIDEO_EXT');

	inline static public function modsSounds(path:String, key:String)
		return modFolders('$path/$key.$SOUND_EXT');

	inline static public function modsImages(key:String)
		return modFolders('images/$key.png');

	inline static public function modsXml(key:String)
		return modFolders('images/$key.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/$key.txt');

	inline static public function modsShaderFragment(key:String, ?library:String)
		return modFolders('shaders/$key.frag');

	inline static public function modsShaderVertex(key:String, ?library:String)
		return modFolders('shaders/$key.vert');

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			if(FileSystem.exists(mods('$currentModDirectory/$key'))) return mods('$currentModDirectory/$key');
		}
		return 'mods/$key';
	}

	inline static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if(FileSystem.exists(modsFolder)) {
			for (folder in FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}

	static var previousModDirectory:String;

	public static var characterMap:Map<String, String> = [];
	public static var iconsMap:Map<String, String> = [];
	public static var stageMap:Map<String, String> = [];
	public static function setModsDirectoryFromType(type:ModsDirectoryType, key:String, reset:Bool = false) {
		if (reset) {
			currentModDirectory = previousModDirectory;
			return;
		}
		previousModDirectory = currentModDirectory;
		switch(type) {
			case ICON:
				if(iconsMap.exists(key) && iconsMap.get(key) != currentModDirectory) {
					currentModDirectory = iconsMap.get(key);
				}
			case CHARACTER:
				if(characterMap.exists(key) && characterMap.get(key) != currentModDirectory) {
					currentModDirectory = characterMap.get(key);
				}
			case STAGE:
				if(stageMap.exists(key) && stageMap.get(key) != currentModDirectory) {
					currentModDirectory = stageMap.get(key);
				}
			default:
				//
		}
	}

	static var cachedFolderList:Array<String> = [];
	public static function refreshModsMaps(force:Bool = false, includePreload:Bool = false, clear:Bool = false) {
		var curFolderList = FileSystem.readDirectory('mods');
		if (!force && curFolderList.toString() == cachedFolderList.toString()) //cant compare arrays directly???
			return;

		cachedFolderList = curFolderList;

		if (clear) {
			characterMap.clear();
			iconsMap.clear();
			stageMap.clear();
		}

		for (a in curFolderList) {
            if (ignoreModFolders.contains(a) || a.contains('.')) continue;
			if (FileSystem.exists('mods/$a/data/characters')) {
				for (b in FileSystem.readDirectory('mods/$a/data/characters')) {
					if (!b.endsWith('.json')) continue;
					characterMap.set(b.substr(0, b.length - 5), a);
				}
			}
			if (FileSystem.exists('mods/$a/images/icons')) {
				for (b in FileSystem.readDirectory('mods/$a/images/icons')) {
					if (!b.endsWith('.png')) continue;
					iconsMap.set(b.substr(0, b.length - 4).replace('icon-', ''), a);
				}
			}
			if (FileSystem.exists('mods/$a/data/stages')) {
				for (b in FileSystem.readDirectory('mods/$a/data/stages')) {
					if (!b.endsWith('.json')) continue;
					stageMap.set(b.substr(0, b.length - 5), a);
				}
			}
        }

		if (FileSystem.exists('mods/data/characters')) {
			for (a in FileSystem.readDirectory('mods/data/characters')) {
				if (!a.endsWith('.json')) continue;
				characterMap.set(a.substr(0, a.length - 5), '');
			}
		}
		if (FileSystem.exists('mods/data/stages')) {
			for (a in FileSystem.readDirectory('mods/data/stages')) {
				if (!a.endsWith('.json')) continue;
				stageMap.set(a.substr(0, a.length - 5), '');
			}
		}
		if (FileSystem.exists('mods/images/icons')) {
			for (a in FileSystem.readDirectory('mods/images/icons')) {
				if (!a.endsWith('.png')) continue;
				iconsMap.set(a.substr(0, a.length - 4).replace('icon-', ''), '');
			}
		}

		if (!includePreload) return;
		for (a in FileSystem.readDirectory('assets/data/characters')) {
			if (!a.endsWith('.json')) continue;
			characterMap.set(a.substr(0, a.length - 5), '');
		}
		for (a in FileSystem.readDirectory('assets/images/icons')) {
			if (!a.endsWith('.png')) continue;
			iconsMap.set(a.substr(0, a.length - 4).replace('icon-', ''), '');
		}
		for (a in FileSystem.readDirectory('assets/data/stages')) {
			if (!a.endsWith('.json')) continue;
			stageMap.set(a.substr(0, a.length - 5), '');
		}
	}
	#end
}

#if MODS_ALLOWED
enum ModsDirectoryType
{
    CHARACTER;
    ICON;
	STAGE;
	NONE;
}
#end
