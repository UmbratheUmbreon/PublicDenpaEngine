package;

import flixel.FlxSprite;

/**
* Class used to create `FlxSprites`s for backgrounds quickly.
*/
class BGSprite extends FlxSprite
{
	private var idleAnim:String;
	public var animOffsets:Map<String, Array<Float>>;
	private var skipAllOffsets:Bool = true;
	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false, ?skipOffsets:Bool = true) {
		super(x, y);

		if (animArray != null) {
			this.skipAllOffsets = skipOffsets;
			frames = Paths.getSparrowAtlas(image);
			for (i in 0...animArray.length) {
				var anim:String = animArray[i];
				animation.addByPrefix(anim, anim, 24, loop);
				if(idleAnim == null) {
					idleAnim = anim;
					playAnim(anim, true, false, 0);
				}
			}
			animOffsets = new Map();
		} else {
			if(image != null) {
				loadGraphic(Paths.image(image));
			}
			active = false;
		}
		scrollFactor.set(scrollX, scrollY);
	}

	public function dance(?forceplay:Bool = false) {
		if(idleAnim != null) {
			playAnim(idleAnim, forceplay, false, 0);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0) {
		animation.play(AnimName, Force, Reversed, Frame);

		if (!skipAllOffsets && animOffsets != null) {
			var daOffset = animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName))
			{
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);
		}
	}
}