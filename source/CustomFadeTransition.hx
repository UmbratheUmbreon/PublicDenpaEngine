package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

/**
* Class used to create the fade transition between states.
* By default, an `FlxGradient` is used.
*/
class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	private var leTween:FlxTween;
	public static var nextCamera:FlxCamera;
	public static var colorForFunnyGrad:FlxColor = FlxColor.BLACK;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	public function new(duration:Float, isTransIn:Bool, ?useAnimatedSprite:Bool = false, ?animatedSpriteValues:Array<Any>) {
		super();

		this.isTransIn = isTransIn;
		var zoom:Float = CoolUtil.clamp(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);
		if (!useAnimatedSprite) {
			transGradient = FlxGradient.createGradientFlxSprite(width, height, (isTransIn ? [0x0, colorForFunnyGrad] : [colorForFunnyGrad, 0x0]));
			transGradient.scrollFactor.set();
			transGradient.active = false;
			add(transGradient);
	
			transBlack = new FlxSprite().makeGraphic(width, height + 400, colorForFunnyGrad);
			transBlack.scrollFactor.set();
			transBlack.active = false;
			add(transBlack);
	
			transGradient.x -= (width - FlxG.width) / 2;
			transBlack.x = transGradient.x;
	
			if(isTransIn) {
				transGradient.y = transBlack.y - transBlack.height;
				FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
					onComplete: function(twn:FlxTween) {
						close();
					},
				ease: FlxEase.linear});
			} else {
				transGradient.y = -transGradient.height;
				transBlack.y = transGradient.y - transBlack.height + 50;
				leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
					onComplete: function(twn:FlxTween) {
						if(finishCallback != null) {
							finishCallback();
						}
					},
				ease: FlxEase.linear});
			}
		} else {
			transGradient = new FlxSprite();
			transGradient.frames = Paths.getSparrowAtlas(cast (animatedSpriteValues[0], String));
			transGradient.animation.addByPrefix(cast (animatedSpriteValues[1], String), cast (animatedSpriteValues[1], String), cast (animatedSpriteValues[2], Int), false);
			transGradient.animation.finishCallback = function(name:String) {
				close();
			}
			transGradient.scrollFactor.set();
			transGradient.setGraphicSize(1280, 720);
			transGradient.updateHitbox();
			transGradient.active = false;
		}

		if(nextCamera != null) {
			transBlack.cameras = [nextCamera];
			transGradient.cameras = [nextCamera];
		}
		nextCamera = null;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		if(isTransIn) {
			transBlack.y = transGradient.y + transGradient.height;
		} else {
			transBlack.y = transGradient.y - transBlack.height;
		}
	}

	override function destroy() {
		if(leTween != null) {
			finishCallback();
			leTween.cancel();
			leTween.destroy();
		}
		colorForFunnyGrad = FlxColor.BLACK;
		super.destroy();
	}
}
