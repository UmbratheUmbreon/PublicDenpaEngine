package;

import Character;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

enum abstract IconType(Int) to Int from Int //abstract so it can hold int values for the frame count
{
    var SINGLE = 0;
    var DEFAULT = 1;
    var WINNING = 2;
}

typedef BopInfo =
{
	var curBeat:Int;
	var ?playbackRate:Float;
	var ?gfSpeed:Int;
	var ?healthBarPercent:Float;
}

/**
* Class used to create and control the `HealthIcon`s used on the Healthbar.
*/
class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	private var isPlayer:Bool = false;
	public var char:String = '';
    public var type:IconType = DEFAULT;
	public var trackerOffsets:Array<Float> = [0,0];
	public var bopMult:Float = 1;
	public var scaleMult:Float = 1;
	public var copyState:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null) {
			setPosition(sprTracker.x + sprTracker.width + 10 + trackerOffsets[0], sprTracker.y - 30 + trackerOffsets[1]);
			if (copyState) {
				visible = sprTracker.visible;
				active = sprTracker.active;
			}
		}

		//Internal Bopping
		//maybe make this affected by gf speed would be cool i think (takes longer on higher ones)
		switch (curBopType.toLowerCase()) {
			case 'swing' | 'snap' | 'none':
				//Prevent Default Scaling
			case 'stretch':
				setGraphicSize(Std.int(FlxMath.lerp(150 * scaleMult, width, 0.8)), Std.int(FlxMath.lerp(150 * scaleMult, height, 0.8)));
				updateHitbox();
			case 'old':
				setGraphicSize(Std.int(FlxMath.lerp(150 * scaleMult, width, 0.50)));
				updateHitbox();
			default:
				var mult:Float = FlxMath.lerp(1 * scaleMult, scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
				scale.set(mult, mult);
				updateHitbox();
		}
	}

	public var curBopType(default, set):String = "None";
	/**
	 * Internal function to animate the Icon.
	 * @param iconAnim The name of the Animation, set to "Client"
	 * @param type (0 = BF, 1 = DAD, 2 = SECONDARY (P4 for example))
	 * @param bopInfo {curBeat, playbackRate, gfSpeed, healthBarPercent} curBeat is mandatory, the rest are limited to PlayState.
	 * Values are necessary for proper calculations!!
	 */
	public function bop(bopInfo:BopInfo, iconAnim:String = "ClientPrefs", type:Int = 0) {
		if(iconAnim.toLowerCase() == "clientprefs") iconAnim = ClientPrefs.settings.get("iconAnim");
		if(iconAnim == "None") return;

		if(curBopType != iconAnim) curBopType = iconAnim;

		final info:BopInfo = checkInfo(bopInfo);
		if (info.curBeat % info.gfSpeed == 0) {
			switch (iconAnim.toLowerCase()) { //Messy Math hell jumpscare (it is more customizeable though)
				case 'swing':
					info.curBeat % (info.gfSpeed * 2) == 0 ? {
						var scaleArray:Array<Float> = [1.1 * bopMult, 0.8 / bopMult];
						switch(type) {
							case 1: scaleArray = [1.1 / bopMult, 1.3 * bopMult];
							case 2: scaleArray = [0.85 / bopMult, 1.1 * bopMult];
						}
						scale.set(scaleMult * scaleArray[0], scaleMult * scaleArray[1]);
						final reverse = type > 0 ? 1 : -1;
			
						FlxTween.angle(this, 15 * reverse, 0, Conductor.crochet / 1300 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
					} : {
						var scaleArray:Array<Float> = [1.1 / bopMult, 1.3 * bopMult];
						switch(type) {
							case 1: scaleArray = [1.1 * bopMult, 0.8 / bopMult];
							case 2: scaleArray = [0.85 * bopMult, 0.65 / bopMult];
						}
						scale.set(scaleMult * scaleArray[0], scaleMult * scaleArray[1]);
						final reverse = type > 0 ? -1 : 1;
			
						FlxTween.angle(this, 15 * reverse, 0, Conductor.crochet / 1300 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
					}
						
					final scaleThing:Float = type == 2 ? 0.75 : 1;
					FlxTween.tween(this, {'scale.x': scaleMult * scaleThing, 'scale.y': scaleMult * scaleThing}, Conductor.crochet / 1250 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
				case 'bop':
					final scaleThing:Float = type == 2 ? 1 : 1.2;
					scale.set((scaleMult * scaleThing) * bopMult, (scaleMult * scaleThing) * bopMult);
				case 'old':
					setGraphicSize(Std.int((width + 30) * bopMult));
				case 'snap':
					info.curBeat % (info.gfSpeed * 2) == 0 ? {
						var scaleArray:Array<Float> = [1.1 * bopMult, 0.8 / bopMult];
						switch(type) {
							case 1: scaleArray = [1.1 / bopMult, 1.3 * bopMult];
							case 2: scaleArray = [0.85 / bopMult, 1.1 * bopMult];
						}
						scale.set(scaleMult * scaleArray[0], scaleMult * scaleArray[1]);
	
						angle = type > 0 ? 15 : -15;
					} : {
						var scaleArray:Array<Float> = [1.1 / bopMult, 1.3 * bopMult];
						switch(type) {
							case 1: scaleArray = [1.1 * bopMult, 0.8 / bopMult];
							case 2: scaleArray = [0.85 * bopMult, 0.65 / bopMult];
						}
						scale.set(scaleMult * scaleArray[0], scaleMult * scaleArray[1]);
	
						angle = type > 0 ? -15 : 15;
					}
				
					final scaleThing:Float = type == 2 ? 0.75 : 1;
					FlxTween.tween(this, {'scale.x': scaleMult * scaleThing, 'scale.y': scaleMult * scaleThing}, Conductor.crochet / 1250 / info.playbackRate * info.gfSpeed, {ease: FlxEase.quadOut});
				case 'stretch':
					var funny:Float = (info.healthBarPercent * 0.01) + 0.01;
					final trueFunny:Float = type > 0 ? (scaleMult * (2 - funny)) * bopMult : (scaleMult * funny) * bopMult;
					final stretchValues = type == 2 ? [25, 12] : [50, 25];
	
					setGraphicSize(Std.int(width + (stretchValues[0] * trueFunny)),Std.int(height - (stretchValues[1] * trueFunny)));
			}
		}
		updateHitbox();
	}

	function set_curBopType(newType:String):String { //Resets values
		curBopType = newType;
		angle = 0;
		scale.set(1, 1);
		setGraphicSize(150, 150);
		updateHitbox();
		return curBopType;
	}

	inline function checkInfo(oldInfo:BopInfo):BopInfo {
		final playbackRate = oldInfo.playbackRate == null ? 1 : oldInfo.playbackRate;
		final gfSpeed = oldInfo.gfSpeed == null ? 1 : oldInfo.gfSpeed;
		final healthBarPercent = oldInfo.healthBarPercent == null ? 100: oldInfo.healthBarPercent;

		return {curBeat: oldInfo.curBeat, playbackRate: playbackRate, gfSpeed: gfSpeed, healthBarPercent: healthBarPercent};
	}

	public var offsets(default, set):Array<Float> = [0, 0];
	@:noCompletion public var ignoreChange:Bool = false;
	public function changeIcon(char:String, ?characterFile:Character = null):HealthIcon {
		if(this.char != char || ignoreChange) {
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			var file:FlxGraphic = Paths.image(name);

			type = (file.width < 200 ? SINGLE : ((file.width > 199 && file.width < 301) ? DEFAULT : WINNING));

			loadGraphic(file, true, Math.floor(file.width / (type+1)), file.height);
			offsets[0] = offsets[1] = (width - 150) / (type+1);
			var frames:Array<Int> = [];
			for (i in 0...type+1) frames.push(i);
			animation.add(char, frames, 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			//Earlier Version Icon Control Support
			antialiasing = !char.endsWith('-pixel');
			if(characterFile != null) {
				//reverse because offsets are backwards 
				offsets[0] -= characterFile.iconProperties.offsets[0];
				offsets[1] -= characterFile.iconProperties.offsets[1];
				antialiasing = characterFile.iconProperties.antialiasing;
			}

			if(antialiasing) antialiasing = ClientPrefs.settings.get("globalAntialiasing");
			updateHitbox();
		}
		ignoreChange = false;

		//for chaining
		return this;
	}

	//necessary??? 
	override function updateHitbox() {
		super.updateHitbox();
		offset.x = offsets[0];
		offset.y = offsets[1];
	}

	function set_offsets(newArr:Array<Float>):Array<Float>
	{
		offsets = newArr;
		offset.x = offsets[0];
		offset.y = offsets[1];
		return offsets;
	}
}

/**
 * Contains infos and functions for one Healthbar-Side.
 * 
 * Currently only used in PlayState's `reloadHealthBarColors` function.
 */
class HealthbarColorContainer {
	public var colorMap:Map<Int, FlxColor> = new Map<Int, FlxColor>();

	public function new(colors:Array<FlxColor>) {
		for(i in 0...colors.length) colorMap.set(i, colors[i]);
	}

	public function setFadingColor(mainColor:FlxColor){
		colorMap[0] = mainColor;
		colorMap[1] = FlxColor.subtract(mainColor, 0x00141414);
		colorMap[2] = FlxColor.subtract(colorMap[1], 0x00141414);
	}

	public static function getCharacterBarRGB(char:Character):Array<FlxColor> {
		var returnArray:Array<FlxColor> = [];
		for (curColor in char.healthColorArray) {
			returnArray.push(FlxColor.fromRGB(curColor.red, curColor.green, curColor.blue));
		}

		return returnArray;
	}

	/**
	 * Creates an array with 4 Colors representing the HealthBar Top, Upper Middle, Lower Middle and Bottom
	 */
	public static function createBarColorArray(char:Character, container:HealthbarColorContainer):Array<FlxColor> {
		var returnArray:Array<FlxColor> = [];

		returnArray.push(container.colorMap[0]);
		if (char.healthBarCount > 1) returnArray.push(container.colorMap[1]);
		if (char.healthBarCount > 2) returnArray.push(container.colorMap[2]);

		return returnArray;
	}
}