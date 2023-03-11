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
	public var isPlayer:Bool = false;
	public var playerOffsets:Bool = false;
	public var flippedFlipX:Bool = false;
	//dynamic is a big no no
	//AT this is literally a dynamic
    public function new(character:Any, group:FlxTypedGroup<CrossFade>, ?isDad:Bool = true)
    {
        super();

		var char:Character = cast(character, Character);

		isPlayer = char.isPlayer;
		playerOffsets = char.playerOffsets;
		flippedFlipX = char.flippedFlipX;
        frames = char.frames;
		alpha = (!isDad ? ClientPrefs.settings.get('crossFadeData')[3] : 0.3);
		setGraphicSize(Std.int(char.width), Std.int(char.height));
		scrollFactor.set(char.scrollFactor.x, char.scrollFactor.y);
		updateHitbox();
		flipX = char.flipX;
		flipY = char.flipY;
		final curCrossFadeMode:String = ClientPrefs.settings.get('crossFadeData')[0];
		switch (curCrossFadeMode)
		{
			case 'Static':
				x = char.x + (isDad ? 60 : -60);
				y = char.y - 48;
			case 'Subtle':
				x = char.x;
				y = char.y;
			case 'Eccentric':
				x = char.x + FlxG.random.float(-20,90);
				y = char.y + FlxG.random.float(-80, 80);
			default:
				x = char.x + FlxG.random.float(0,60);
				y = char.y + FlxG.random.float(-50, 50);
		}
		offset.x = char.offset.x;
		offset.y = char.offset.y; 
		animation.add('cur', char.animation.curAnim.frames, 24, false);
		animation.play('cur', true);
        animation.curAnim.curFrame = char.animation.curAnim.curFrame;
		antialiasing = char.antialiasing;
		if (!char.trailData.enabled) {
			switch(char.curCharacter)
			{
				case 'gf-pixel':
					color = 0xFFa5004d;
					antialiasing = false;
				case 'monster' | 'monster-christmas' | 'monster-streetlight':
					color = 0xff919400;
				case 'bf' | 'bf-car' | 'bf-christmas' | 'bf-streetlight':
					color = 0xFF1b008c;
				case 'pico' | 'pico-player':
					color = 0xff2c8c00;
				case 'bf-holding-gf':
					color = FlxG.random.bool(50) ? 0xFF1b008c : 0xFFa5004d;
				case 'parents-christmas':
					color = PlayState.SONG.notes[PlayState.instance.curSection].altAnim ? 0xff882952 : 0xff6a3381;
				case 'spooky':
					color = FlxG.random.bool(50) ? 0xff777777 : 0xff925500;
				case 'bf-pixel' | 'bf-pixel-opponent':
					color = 0xFF00368c;
					antialiasing = false;
				case 'senpai' | 'senpai-angry':
					color = 0xFFffaa6f;
					antialiasing = false;
				case 'sarvente' | 'sarvente-dark' | 'sarvente-lucifer' | 'selever':
					color = 0xFFe32486;
				case 'ruv':
					color = 0xFF2e0069;
				case 'tankman' | 'tankman-player':
					color = 0xffcccccc;
					if (PlayState.instance != null && PlayState.instance.tankmanRainbow) {
						switch(FlxG.random.int(0,5)) {
							case 0: color = 0xff7c0000;
							case 1: color = 0xff7e3200;
							case 2: color = 0xff7c6900;
							case 3: color = 0xff0a7c00;
							case 4: color = 0xff02007c;
							case 5: color = 0xff6d007c;
						}
					}
				default:
					//oooo scary chaining
					color = FlxColor.subtract(FlxColor.fromRGB(char.healthColorArray[0].red, char.healthColorArray[0].green, char.healthColorArray[0].blue), 0x00333333);
			}
		} else {
			alpha = 0;
			kill();
			destroy();
			return;
		}
	
		final dirLeft = FlxG.random.bool(70); //no mor shadow wario naming wahoo
		final velo = 12 * (curCrossFadeMode == 'Eccentric' ? 8 : 5);
		switch (curCrossFadeMode)
		{
			case 'Static' | 'Subtle':
				velocity.x = 0;
			case 'Eccentric':
				velocity.x = (isDad ? (dirLeft ? -velo : velo) : (dirLeft ? velo : -velo)) * PlayState.instance.playbackRate;
				acceleration.x = (velocity.x > 0 ? FlxG.random.int(25,75) : FlxG.random.int(-25,-75)) * PlayState.instance.playbackRate * PlayState.instance.playbackRate;
			default:
				velocity.x = (isDad ? (dirLeft ? -velo : velo) : (dirLeft ? velo : -velo)) * PlayState.instance.playbackRate;
				acceleration.x = (velocity.x > 0 ? FlxG.random.int(4,12) : FlxG.random.int(-4,-12)) * PlayState.instance.playbackRate * PlayState.instance.playbackRate;
		}
		var fadeTime = (!isDad ? ClientPrefs.settings.get('crossFadeData')[4] : 0.35);
		FlxTween.tween(this, {alpha: 0}, FlxG.random.float(fadeTime - 0.03, fadeTime + 0.03) / PlayState.instance.playbackRate, {
			onComplete: _ -> {
				kill();
				group.remove(this, true);
				destroy();
			}
		});

		group.add(this);
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