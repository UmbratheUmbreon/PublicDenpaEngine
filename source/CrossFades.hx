package;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxRect;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/**
* Class used to create `CrossFade`s, as seen in Mid-Fight Masses.
* All sprite creation and destruction is handled automatically.
*/
class CrossFade extends FlxSprite
{
	public static var colorMap:Map<String, Array<Int>> = [
		'gf-tutorial' => [0xFFa5004d],
		'gf' => [0xFFa5004d],
		'gf-pixel' => [0xFFa5004d],
		'monster' => [0xff919400],
		'monster-streetlight' => [0xff919400],
		'monster-christmas' => [0xff919400],
		'bf' => [0xFF1b008c],
		'bf-streetlight' => [0xFF1b008c],
		'bf-car' => [0xFF1b008c],
		'bf-christmas' => [0xFF1b008c],
		'bf-holding-gf' => [0xFF1b008c, 0xFFa5004d],
		'bf-pixel' => [0xFF00368c],
		'bf-pixel-opponent' => [0xFF00368c],
		'pico' => [0xff2c8c00],
		'pico-player' => [0xff2c8c00],
		'parents-christmas' => [0xff6a3381, 0xff882952],
		'spooky' => [0xff777777, 0xff925500],
		'senpai' => [0xFFffaa6f],
		'senpai-angry' => [0xFFffaa6f],
		'sarvente' => [0xFFe32486],
		'sarvente-dark' => [0xFFe32486],
		'sarvente-lucifer' => [0xFFe32486],
		'selever' => [0xFFe32486],
		'ruv' => [0xFF2e0069],
		'tankman' => [0xffcccccc, 0xff7c0000, 0xff7e3200, 0xff7c6900, 0xff0a7c00, 0xff00407c, 0xff13007c, 0xff63007c]
	];
	private var isPlayer:Bool = false;
	private var playerOffsets:Bool = false;
	private var flippedFlipX:Bool = false;

	//these are recycled now so the new function is empty except for the super
    public function new()
        super();

	public function resetShit(character:Character, ?isDad:Bool = true) {
		if (character.trailData.enabled) {
			kill();
			return;
		}

		isPlayer = character.isPlayer;
		playerOffsets = character.playerOffsets;
		flippedFlipX = character.flippedFlipX;
        frames = character.frames;
		alpha = (!isDad ? ClientPrefs.settings.get('crossFadeData')[3] : 0.3);
		setGraphicSize(Std.int(character.width), Std.int(character.height));
		scrollFactor.set(character.scrollFactor.x, character.scrollFactor.y);
		updateHitbox();
		flipX = character.flipX;
		flipY = character.flipY;
		final curCrossFadeMode:String = ClientPrefs.settings.get('crossFadeData')[0];
		switch (curCrossFadeMode)
		{
			case 'Static':
				x = character.x + (isDad ? 60 : -60);
				y = character.y - 48;
			case 'Subtle':
				x = character.x;
				y = character.y;
			case 'Eccentric':
				x = character.x + FlxG.random.float(-20,90);
				y = character.y + FlxG.random.float(-80, 80);
			default:
				x = character.x + FlxG.random.float(0,60);
				y = character.y + FlxG.random.float(-50, 50);
		}
		offset.set(character.offset.x, character.offset.y);
		animation.add('cur', character.animation.curAnim.frames, 24, false);
		animation.play('cur', true);
        animation.curAnim.curFrame = character.animation.curAnim.curFrame;
		//animation.copyFrom(character.animation); //might be faster?
		antialiasing = character.antialiasing;

		if (colorMap.exists(character.curCharacter)) {
			final colors = colorMap.get(character.curCharacter);
			var index:Int = 0;

			if (character.curCharacter == 'parents-christmas')
				index = (PlayState.SONG.notes[PlayState.instance.curSection].altAnim ? 1 : 0);
			else if (character.curCharacter == 'spooky' || character.curCharacter == 'bf-holding-gf')
				index = (FlxG.random.bool() ? 1 : 0);
			else if ((character.curCharacter == 'tankman' || character.curCharacter == 'tankman-player') && PlayState.instance.tankmanRainbow)
				index = FlxG.random.int(1, 7);

			color = colors[index];
		} else
			color = FlxColor.subtract(FlxColor.fromRGB(character.healthColorArray[0].red, character.healthColorArray[0].green, character.healthColorArray[0].blue), 0x00333333);
	
		final oppositeDir = FlxG.random.bool(70); //no mor shadow wario naming wahoo
		final velo = 12 * (curCrossFadeMode == 'Eccentric' ? 8 : 5);
		switch (curCrossFadeMode)
		{
			case 'Static' | 'Subtle':
				velocity.x = 0;
			case 'Eccentric':
				velocity.x = (isDad ? (oppositeDir ? -velo : velo) : (oppositeDir ? velo : -velo)) * PlayState.instance.playbackRate;
				acceleration.x = (velocity.x > 0 ? FlxG.random.int(25,75) : FlxG.random.int(-25,-75)) * PlayState.instance.playbackRate * PlayState.instance.playbackRate;
			default:
				velocity.x = (isDad ? (oppositeDir ? -velo : velo) : (oppositeDir ? velo : -velo)) * PlayState.instance.playbackRate;
				acceleration.x = (velocity.x > 0 ? FlxG.random.int(4,12) : FlxG.random.int(-4,-12)) * PlayState.instance.playbackRate * PlayState.instance.playbackRate;
		}
		var fadeTime = (!isDad ? ClientPrefs.settings.get('crossFadeData')[4] : 0.35);
		FlxTween.tween(this, {alpha: 0}, FlxG.random.float(fadeTime - 0.03, fadeTime + 0.03) / PlayState.instance.playbackRate, {onComplete: _ -> kill()});
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
	override function draw() {
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
}