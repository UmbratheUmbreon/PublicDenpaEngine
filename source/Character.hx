package;

import Song.SwagSection;
import VanillaBG.TankmenBG;
import animateatlas.AtlasFrameMaker;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxAnimation;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import flixel.util.typeLimit.OneOfTwo;
import haxe.Json;
import haxe.xml.Access;
import openfl.utils.Assets;

/**
* Typedef containing all `Character` variables to be loaded and saved to a JSON.
*/
typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthbar_count:Null<Int>;
	var ?float_magnitude:Null<Float>;
	var ?float_speed:Null<Float>;
	var ?trail_length:Null<Int>;
	var ?trail_delay:Null<Int>;
	var ?trail_alpha:Null<Float>;
	var ?trail_diff:Null<Float>;
	var ?drain_floor:Null<Float>;
	var ?drain_amount:Null<Float>;
	var icon_props:IconProperties;
	var ?healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var player:Bool;
	var no_antialiasing:Bool;
	var sarvente_floating:Bool;
	var orbit:Bool;
	var ?flixel_trail:Bool;
	var ?trail_data:TrailData;
	var shake_screen:Bool;
	var scare_bf:Bool;
	var scare_gf:Bool;
	var health_drain:Bool;
	var healthbar_colors:Array<OneOfTwo<Int, HealthBarRBG>>;
	var ?death_props:DeathProperties;
	var ?selector_offsets:Array<Int>;
}

/**
* Typedef containing all `FlxAnimation` variables to be used to set the `Character`'s animations.
*/
typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	var loop_point:Null<Int>;
}

/**
* Typedef containing all Death variables to be used when a `Character` dies.
*/
typedef DeathProperties = {
	var character:String;
	var startSfx:String;
	var loopSfx:String;
	var endSfx:String;
	var bpm:Int;
}

/**
* Typedef containing rgb data for the health bar.
*/
typedef HealthBarRBG = {
	var red:Int;
	var green:Int;
	var blue:Int;
}

/**
* Typedef containing data for icons.
*/
typedef IconProperties = {
	var name:String;
	var offsets:Array<Float>;
	var antialiasing:Bool;
}

/**
* Typedef containing data for trails.
*/
typedef TrailData = {
	var enabled:Bool;
	var length:Null<Int>;
	var delay:Null<Int>;
	var alpha:Null<Float>;
	var diff:Null<Float>;
}

/**
* Class containing all needed code for a singing `Chracter`.
*/
class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>>; //MAKE THIS AN FLXPOINT
	@:noCompletion private var _spriteType:String = 'sparrow';
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var playerOffsets:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer(default, set):Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var healthBarCount:Null<Int> = 1;
	public var floatMagnitude:Null<Float> = 0.6;
	public var floatSpeed:Null<Float> = 1;
	public var drainFloor:Null<Float> = 0.1; //healthdrain shit
	public var drainAmount:Null<Float> = 0.01;
	public var selectorOffsets:FlxPoint = FlxPoint.get();
	//for death shit
	public var deathProperties:DeathProperties = null;
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character uses "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	//PlayState stuff
	public var charTrail:FlxTrail = null;
	public var charGroup:FlxSpriteGroup = null;

	//need to have this here
	public var missing:Bool = false;
	public var colorSwap:Shaders.ColorSwap = null;

	//icon shit
	public var iconProperties:IconProperties = {
		name: 'face',
		offsets: [0, 0],
		antialiasing: true
	};
	public var animationsArray:Array<AnimArray> = [];

	public var positionOffset:FlxPoint = FlxPoint.get();
	public var cameraPosition:FlxPoint = FlxPoint.get();

	public var hasMissAnimations:Bool = false;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var sarventeFloating:Bool = false;
	public var orbit:Bool = false;
	public var trailData:TrailData = {
		enabled: false,
		length: 4,
		delay: 24,
		alpha: 0.3,
		diff: 0.069
	};
	public var flixelTrail:Bool = false;
	public var shakeScreen:Bool = false;
	public var scareBf:Bool = false;
	public var scareGf:Bool = false;
	public var healthDrain:Bool = false;
	public var originalFlipX:Bool = false;
	public var flippedFlipX:Bool = false;
	public var healthColorArray:Array<HealthBarRBG> = [
		{
			red: 255,
			green: 0,
			blue: 0
		},
		{
			red: 255,
			green: 0,
			blue: 0
		},
		{
			red: 255,
			green: 0,
			blue: 0
		}
	];

	public static inline final DEFAULT_CHARACTER:String = 'placeman'; //PLACEMAN IS BEST
	public function new(x:Float, y:Float, ?character:String = 'placeman', ?isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map();
		curCharacter = character;
		this.isPlayer = isPlayer;
		setupCharacter();
	}

	function set_heyTimer(Hey:Float):Float
	{
		heyTimer = Hey;
		if(heyTimer <= 0)
		{
			heyTimer = 0;
			if(specialAnim && (animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer'))
			{
				specialAnim = false;
				dance();
			}
		}
		return heyTimer;
	}

	override function destroy() {
		animationsArray = null;
		animOffsets = null;
		shader = null;
		colorSwap = null;
		charTrail = FlxDestroyUtil.destroy(charTrail);
		colorTween = FlxDestroyUtil.destroy(colorTween);
		positionOffset = FlxDestroyUtil.put(positionOffset);
		cameraPosition = FlxDestroyUtil.put(cameraPosition);
		selectorOffsets = FlxDestroyUtil.put(selectorOffsets);
		animationNotes = null;
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (debugMode || (animation == null || animation.curAnim == null)) return;
		//make this not cancer

		if (heyTimer > 0) heyTimer -= elapsed * (PlayState.instance == null ? 1 : PlayState.instance.playbackRate);
		else if(specialAnim && animation.curAnim.finished)
		{
			specialAnim = false;
			dance();
		}

		switch(curCharacter)
		{
			case 'pico-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
		}

		if (!isPlayer)
		{
			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}

			if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
			{
				dance();
				holdTimer = 0;
			}
		}

		if(animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
		{
			playAnim(animation.curAnim.name + '-loop');
		}
	}

	public var danced:Bool = false;

	public function dance()
	{
		if (debugMode || specialAnim || skipDance) return;
		if(danceIdle)
		{
			danced = !danced;

			if (danced) playAnim('danceRight' + idleSuffix);
			else playAnim('danceLeft' + idleSuffix);
		}
		else if(animation.getByName('idle' + idleSuffix) != null) {
			playAnim('idle' + idleSuffix);
		}
		if (color == 0xffa89ef8) {
			missing = false;
			color = 0xffffffff;
		}
	}

	inline function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.header.song)).notes;
		for (section in noteData) {
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	inline function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect {
		if (flipDrawing) {
			scale.x *= -1;
			var bounds = super.getScreenBounds(newRect, camera);
			scale.x *= -1;
			return bounds;
		}
		return super.getScreenBounds(newRect, camera);
	}

	var flipDrawing:Bool = false;

	/**
	 * prob looks insane but it works
	 * shoutouts to yoshman for figuring this out
	 */

	override function draw() {
		//draw backwards if flipped
		if ((isPlayer != playerOffsets) != (flipX != flippedFlipX)) {
			flipDrawing = true;
			flipX = !flipX;
			scale.x *= -1;
			super.draw();
			flipX = !flipX;
			scale.x *= -1;
			flipDrawing = false;
		} else {
			super.draw();
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0] * (isPlayer != playerOffsets ? -1 : 1), daOffset[1]); //swap offsets if flipped
		else
			offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			switch (AnimName) {
				case 'singLEFT': danced = true;
				case 'singRIGHT': danced = false;
				case 'singUP' | 'singDOWN': danced = !danced;
			}
		}

		if (color == 0xffa89ef8 && !missing) {
			color = 0xffffffff;
		}
	}

	function switchAnimFrames(anim1:FlxAnimation, anim2:FlxAnimation) {
		if (anim1 == null || anim2 == null) return;
		var old = anim1.frames;
		anim1.frames = anim2.frames;
		anim2.frames = old;
	}

	function switchOffset(anim1:String, anim2:String) {
		if (!animOffsets.exists(anim1) || !animOffsets.exists(anim2)) return;
		var offsets1 = animOffsets.get(anim1);
		var offsets2 = animOffsets.get(anim2);
		animOffsets.set(anim1, offsets2);
		animOffsets.set(anim2, offsets1);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	inline public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	inline public function quickAnimAdd(name:String, anim:String)
	{
        animation.addByPrefix(name, anim, 24, false);
	}

	private function setupCharacter() {
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode them instead':

			default:
				final characterPath:String = 'data/characters/' + curCharacter + '.json';

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if (!FileSystem.exists(path))
				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getPreloadPath('data/characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to default just to prevent a crash
				}

				#if MODS_ALLOWED
				var rawJson = File.getContent(path);
				#else
				var rawJson = Assets.getText(path);
				#end

				var json:CharacterFile = cast Json.parse(rawJson);
				var spriteType = "sparrow";
				#if MODS_ALLOWED
				var modTxtToFind:String = Paths.modsTxt(json.image);
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);
				
				if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
				#end
				{
					spriteType = "packer";
				}
				
				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);
				
				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
				#end
				{
					spriteType = "texture";
				}
				_spriteType = spriteType;

				switch (spriteType){
					case "texpack":
						frames = Paths.getTexturePacker(json.image);
					case "packer":
						frames = Paths.getPackerAtlas(json.image);
					case "sparrow":
						frames = Paths.getSparrowAtlas(json.image);
					case "texture":
						frames = AtlasFrameMaker.construct(json.image);
				}
				imageFile = json.image;

				if(json.scale != 1) {
					jsonScale = json.scale;
					scale.set(jsonScale, jsonScale);
					updateHitbox();
				}

				playerOffsets = json.player;
				positionOffset.set(json.position[0], json.position[1]);
				cameraPosition.set(json.camera_position[0], json.camera_position[1]);

				singDuration = json.sing_duration;
				if (json.healthbar_count != null) {
					healthBarCount = json.healthbar_count;
				}
				if (json.float_magnitude != null) {
					floatMagnitude = json.float_magnitude;
				}
				if (json.float_speed != null) {
					floatSpeed = json.float_speed;
				}
				sarventeFloating = json.sarvente_floating;
				orbit = json.orbit;
				shakeScreen = json.shake_screen;
				scareBf = json.scare_bf;
				scareGf = json.scare_gf;
				healthDrain = json.health_drain;
				if (json.drain_floor != null) {
					drainFloor = json.drain_floor; //this was the reason drain floor wasnt working. kms.
				}
				if (json.drain_amount != null) {
					drainAmount = json.drain_amount;
				}
				flipX = json.flip_x;
				if(json.no_antialiasing) {
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.death_props != null) {
					deathProperties = json.death_props;
				}

				if (json.selector_offsets != null) {
					selectorOffsets.set(json.selector_offsets[0], json.selector_offsets[1]);
				}

				//loose backwards compatability
				if (json.healthbar_colors != null) {
					if (json.healthbar_colors[0] is Int) {
						healthColorArray = [
							{
								red: json.healthbar_colors[0],
								green: json.healthbar_colors[1],
								blue: json.healthbar_colors[2]
							},
							{
								red: json.healthbar_colors[0],
								green: json.healthbar_colors[1],
								blue: json.healthbar_colors[2]
							},
							{
								red: json.healthbar_colors[0],
								green: json.healthbar_colors[1],
								blue: json.healthbar_colors[2]
							}
						];
					} else {
						healthColorArray = json.healthbar_colors;
					}
				}

				//backwards compatability
				if (json.healthicon != null && json.icon_props == null) {
					iconProperties = {
						name: json.healthicon,
						offsets: [0,0],
						antialiasing: true
					};
				}

				if (json.icon_props != null) {
					iconProperties = json.icon_props;
				}

				if (json.flixel_trail != null) {
					trailData = {
						enabled: json.flixel_trail,
						length: json.trail_length,
						delay: json.trail_delay,
						alpha: json.trail_alpha,
						diff: json.trail_diff
					};
				}

				if (json.trail_data != null) {
					trailData = json.trail_data;
				}

				antialiasing = !noAntialiasing;
				if(!ClientPrefs.settings.get("globalAntialiasing")) antialiasing = false;

				animationsArray = json.animations;
				if(animationsArray != null && animationsArray.length > 0) {
					for (anim in animationsArray) {
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop;
						var animIndices:Array<Int> = anim.indices;
						var loopPoint:Null<Int> = anim.loop_point;
						if (loopPoint == null) loopPoint = 0;
						if(animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop, false, false, loopPoint);
						} else {
                            animation.addByPrefix(animAnim, animName, animFps, animLoop, false, false, loopPoint);
						}

						if(anim.offsets != null && anim.offsets.length > 1) {
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				} else {
					quickAnimAdd('idle', 'BF idle dance');
				}
		}
		originalFlipX = flipX;

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		//flip the animations
		if (isPlayer != playerOffsets) {
			cameraPosition.x *= -1; //flip camera and shit
			positionOffset.x *= -1;
			switchAnimFrames(animation.getByName('singRIGHT'), animation.getByName('singLEFT'));
			switchOffset('singLEFT', 'singRIGHT');
			if(hasMissAnimations) {
				switchAnimFrames(animation.getByName('singRIGHTmiss'), animation.getByName('singLEFTmiss'));
				switchOffset('singLEFTmiss', 'singRIGHTmiss');
			}
		}

		if (isPlayer) {
			flipX = !flipX;
			if (!hasMissAnimations) {
				animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
					if (!missing) return;
					if (name.startsWith('sing'))
						color = 0xffa89ef8;
				}
			}
		}
		//set the actual flip
		flippedFlipX = flipX;

		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
	}

	public function changeCharacter(char:String = "placeman") {
		if (this.curCharacter == char) return;

		animOffsets.clear();
		this.curCharacter = char;
		animation.destroyAnimations();
		scale.set(1,1);
		updateHitbox();
		selectorOffsets.set();
		setupCharacter();
	}

	public function getAnimationsFromXml():Array<String>
	{
		Paths.setModsDirectoryFromType(CHARACTER, curCharacter, false);
		var arr:Array<String> = [];
		if (Paths.fileExists('images/$imageFile.xml', TEXT)) {
			switch (_spriteType) {
				case 'sparrow':
					var data:Access = new Access(Xml.parse(Paths.getTextFromFile('images/$imageFile.xml')).firstElement());
					for (texture in data.nodes.SubTexture) arr.push(texture.att.name.substr(0, texture.att.name.length - 3));
				//? do i need substr here? i cant really check since no one uses these
				/*case 'packer':
					var data = Paths.getTextFromFile('images/$imageFile.xml').trim().split('\n');
					for (i in 0...data.length)
					{
						var currImageData = data[i].split("=");
						arr.push(currImageData[0].trim());
					}
				case 'texpack':
					var xml = Xml.parse(Paths.getTextFromFile('images/$imageFile.xml'));
					for (sprite in xml.firstElement().elements()) arr.push(sprite.get("n"));*/
			}		
		}
		Paths.setModsDirectoryFromType(NONE, '', true);
		return CoolUtil.removeDuplicates(arr);
	}
}


/**
* Class used to handle the extra needs of the playable character.
*/
class Boyfriend extends Character
{
	public var startedDeath:Bool = false;

	public function new(x:Float, y:Float, ?char:String = 'bf')
	{
		super(x, y, char, true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (debugMode || animation.curAnim == null) return;

		if (animation.curAnim.name.startsWith('sing'))
			holdTimer += elapsed;
		else
			holdTimer = 0;

		if (!animation.curAnim.finished) return;

		if (animation.curAnim.name.endsWith('miss'))
			playAnim('idle', true, false, 10);

		if (animation.curAnim.name == 'firstDeath' && startedDeath)
			playAnim('deathLoop');
	}
}

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipX:Bool;
}

/**
* Class used to create rudimentary `Character`s for the Story Menu.
*/
class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;
	private static final DEFAULT_CHARACTER:String = 'bf';

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf') {
		if(character == null) character = '';
		if(character == this.character) return;

		this.character = character;
		visible = true;

		var dontPlayAnim:Bool = false;
		scale.set(1, 1);
		updateHitbox();

		hasConfirmAnimation = false;
		switch(character) {
			case '':
				visible = false;
				dontPlayAnim = true;
			default:
				final characterPath:String = 'data/menucharacters/' + character + '.json';
				var rawJson = null;

				#if MODS_ALLOWED
				var path:String = Paths.modFolders(characterPath);
				if (!FileSystem.exists(path)) {
					path = Paths.getPreloadPath(characterPath);
				}

				if(!FileSystem.exists(path)) {
					path = Paths.getPreloadPath('data/menucharacters/' + DEFAULT_CHARACTER + '.json');
				}
				rawJson = File.getContent(path);

				#else
				var path:String = Paths.getPreloadPath(characterPath);
				if(!Assets.exists(path)) {
					path = Paths.getPreloadPath('data/menucharacters/' + DEFAULT_CHARACTER + '.json');
				}
				rawJson = Assets.getText(path);
				#end
				
				var charFile:MenuCharacterFile = cast Json.parse(rawJson);
				frames = Paths.getSparrowAtlas('menucharacters/' + charFile.image);
				animation.addByPrefix('idle', charFile.idle_anim, 24);

				var confirmAnim:String = charFile.confirm_anim;
				if(confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charFile.idle_anim)
				{
					animation.addByPrefix('confirm', confirmAnim, 24, false);
					if (animation.getByName('confirm') != null) //check for invalid animation
						hasConfirmAnimation = true;
				}

				flipX = (charFile.flipX == true);

				if(charFile.scale != 1) {
					scale.set(charFile.scale, charFile.scale);
					updateHitbox();
				}
				offset.set(charFile.position[0], charFile.position[1]);
				animation.play('idle');
		}
	}
}
