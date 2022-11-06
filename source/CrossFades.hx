package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.animation.FlxAnimation;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;

/**
* Class used to create `CrossFade`s, as seen in Mid-Fight Masses.
* All sprite creation and destruction is handled automatically.
*/
class CrossFade extends FlxSprite
{
    public function new(character:Character, group:FlxTypedGroup<CrossFade>, ?isDad:Bool = true)
    {
        super();
        frames = character.frames;
		alpha = 0.3;
		setGraphicSize(Std.int(character.width), Std.int(character.height));
		scrollFactor.set(character.scrollFactor.x,character.scrollFactor.y);
		updateHitbox();
		flipX = character.flipX;
		flipY = character.flipY;
		var curCrossFadeMode:String = ClientPrefs.crossFadeMode;
		switch (curCrossFadeMode)
		{
			case 'Static':
				x = character.x + 60;
				y = character.y - 50;
			case 'Eccentric':
				x = character.x + FlxG.random.float(-20,90);
				y = character.y + FlxG.random.float(-80, 80);
			default:
				x = character.x + FlxG.random.float(0,60);
				y = character.y + FlxG.random.float(-50, 50);
		}
		offset.x = character.offset.x;
		offset.y = character.offset.y; 
		animation.add('cur', character.animation.curAnim.frames, 24, false);
		animation.play('cur', true);
        animation.curAnim.curFrame = character.animation.curAnim.curFrame;
		if (!character.flixelTrail) {
			switch(character.curCharacter)
			{
				case 'gf-pixel':
					color = 0xFFa5004d;
					antialiasing = false;
				case 'monster' | 'monster-christmas' | 'monster-streetlight':
					color = 0xff919400;
					antialiasing = character.antialiasing;
				case 'bf' | 'bf-car' | 'bf-christmas' | 'bf-streetlight':
					color = 0xFF1b008c;
					antialiasing = character.antialiasing;
				case 'pico' | 'pico-player':
					color = 0xff2c8c00;
					antialiasing = character.antialiasing;
				case 'bf-holding-gf':
					color = FlxG.random.bool(50) ? 0xFF1b008c : 0xFFa5004d;
					antialiasing = character.antialiasing;
				case 'parents-christmas':
					color = PlayState.SONG.notes[PlayState.publicSection].altAnim ? 0xff882952 : 0xff6a3381;
					antialiasing = character.antialiasing;
				case 'spooky':
					color = FlxG.random.bool(50) ? 0xff777777 : 0xff925500;
					antialiasing = character.antialiasing;
				case 'bf-pixel' | 'bf-pixel-opponent':
					color = 0xFF00368c;
					antialiasing = false;
				case 'senpai' | 'senpai-angry':
					color = 0xFFffaa6f;
					antialiasing = false;
				case 'sarvente' | 'sarvente-dark' | 'sarvente-lucifer' | 'selever':
					color = 0xFFe32486;
					antialiasing = character.antialiasing;
				case 'ruv':
					color = 0xFF2e0069;
					antialiasing = character.antialiasing;
				case 'tankman' | 'tankman-player':
					if (PlayState.tankmanRainbow) {
						switch(FlxG.random.int(0,5)) {
							case 0:
								color = 0xff7c0000;
							case 1:
								color = 0xff7e3200;
							case 2:
								color = 0xff7c6900;
							case 3:
								color = 0xff0a7c00;
							case 4:
								color = 0xff02007c;
							case 5:
								color = 0xff6d007c;
							default:
								color = 0xff000000;
						}
					} else {
						color = 0xff000000;
					}
					antialiasing = character.antialiasing;
				default:
					color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
					color = FlxColor.subtract(color, 0x00333333);
					antialiasing = character.antialiasing;
			}
		} else {
			alpha = 0;
			kill();
			destroy();
			return;
		}
	
		var fuck = FlxG.random.bool(70);
		
		var velo = 12 * 5;
		switch (curCrossFadeMode)
		{
			case 'Static':
				if (isDad) {
					if (fuck) velocity.x = 0;
					else velocity.x = 0;
				}
				else {
					if (fuck) velocity.x = 0;
					else velocity.x = 0;
				}
			case 'Eccentric':
				velo = 12 * 8;
				if (isDad) {
					if (fuck) velocity.x = -velo;
					else velocity.x = velo;
				}
				else {
					if (fuck) velocity.x = velo;
					else velocity.x = -velo;
				}
				acceleration.x = (velocity.x > 0) ? FlxG.random.int(25,75) : FlxG.random.int(-25,-75);
			default:
				if (isDad) {
					if (fuck) velocity.x = -velo;
					else velocity.x = velo;
				}
				else {
					if (fuck) velocity.x = velo;
					else velocity.x = -velo;
				}
				acceleration.x = (velocity.x > 0) ? FlxG.random.int(4,12) : FlxG.random.int(-4,-12);
		}
	
		FlxTween.tween(this, {alpha: 0}, FlxG.random.float(0.32,0.37), {
			onComplete: function(twn:FlxTween)
			{
				kill();
				destroy();
			}
		});

		group.add(this);
    }
}

/**
* Class used to create `CrossFade`s for Boyfriend.
* All sprite creation and destruction is handled automatically.
*/
class BFCrossFade extends FlxSprite
{
    public function new(character:Character.Boyfriend, group:FlxTypedGroup<BFCrossFade>)
    {
        super();
        frames = character.frames;
		alpha = 0.3;
		setGraphicSize(Std.int(character.width), Std.int(character.height));
		scrollFactor.set(character.scrollFactor.x,character.scrollFactor.y);
		updateHitbox();
		flipX = character.flipX;
		flipY = character.flipY;
		var curCrossFadeMode:String = ClientPrefs.crossFadeMode;
		switch (curCrossFadeMode)
		{
			case 'Static':
				x = character.x - 60;
				y = character.y - 50;
			case 'Eccentric':
				x = character.x + FlxG.random.float(-20,90);
				y = character.y + FlxG.random.float(-80, 80);
			default:
				x = character.x + FlxG.random.float(0,60);
				y = character.y + FlxG.random.float(-50, 50);
		}
		offset.x = character.offset.x;
		offset.y = character.offset.y; 
		animation.add('cur', character.animation.curAnim.frames, 24, false);
		animation.play('cur', true);
        animation.curAnim.curFrame = character.animation.curAnim.curFrame;
		if (!character.flixelTrail) {
			switch(character.curCharacter)
			{
				case 'gf-pixel':
					color = 0xFFa5004d;
					antialiasing = false;
				case 'monster' | 'monster-christmas' | 'monster-streetlight':
					color = 0xff919400;
					antialiasing = character.antialiasing;
				case 'bf' | 'bf-car' | 'bf-christmas' | 'bf-streetlight':
					color = 0xFF1b008c;
					antialiasing = character.antialiasing;
				case 'pico' | 'pico-player':
					color = 0xff2c8c00;
					antialiasing = character.antialiasing;
				case 'bf-holding-gf':
					color = FlxG.random.bool(50) ? 0xFF1b008c : 0xFFa5004d;
					antialiasing = character.antialiasing;
				case 'parents-christmas':
					color = PlayState.SONG.notes[PlayState.publicSection].altAnim ? 0xff882952 : 0xff6a3381;
					antialiasing = character.antialiasing;
				case 'spooky':
					color = FlxG.random.bool(50) ? 0xff777777 : 0xff925500;
					antialiasing = character.antialiasing;
				case 'bf-pixel' | 'bf-pixel-opponent':
					color = 0xFF00368c;
					antialiasing = false;
				case 'senpai' | 'senpai-angry':
					color = 0xFFffaa6f;
					antialiasing = false;
				case 'sarvente' | 'sarvente-dark' | 'sarvente-lucifer' | 'selever':
					color = 0xFFe32486;
					antialiasing = character.antialiasing;
				case 'ruv':
					color = 0xFF2e0069;
					antialiasing = character.antialiasing;
				case 'tankman' | 'tankman-player':
					if (PlayState.tankmanRainbow) {
						switch(FlxG.random.int(0,5)) {
							case 0:
								color = 0xff7c0000;
							case 1:
								color = 0xff7e3200;
							case 2:
								color = 0xff7c6900;
							case 3:
								color = 0xff0a7c00;
							case 4:
								color = 0xff02007c;
							case 5:
								color = 0xff6d007c;
							default:
								color = 0xff000000;
						}
					} else {
						color = 0xff000000;
					}
					antialiasing = character.antialiasing;
				default:
					color = FlxColor.fromRGB(character.healthColorArray[0], character.healthColorArray[1], character.healthColorArray[2]);
					color = FlxColor.subtract(color, 0x00333333);
					antialiasing = character.antialiasing;
			}
		} else {
			alpha = 0;
			kill();
			destroy();
			return;
		}
	
		var fuck = FlxG.random.bool(70);
		
		var velo = 12 * 5;
		switch (curCrossFadeMode)
		{
			case 'Static':
				if (fuck) velocity.x = 0;
				else velocity.x = 0;
			case 'Eccentric':
				velo = 12 * 8;
				if (fuck) velocity.x = velo;
				else velocity.x = -velo;
				acceleration.x = (velocity.x > 0) ? FlxG.random.int(25,75) : FlxG.random.int(-25,-75);
			default:
				if (fuck) velocity.x = velo;
				else velocity.x = -velo;	
				acceleration.x = (velocity.x > 0) ? FlxG.random.int(4,12) : FlxG.random.int(-4,-12);
		}
	
		FlxTween.tween(this, {alpha: 0}, FlxG.random.float(0.32,0.37), {
			onComplete: function(twn:FlxTween)
			{
				kill();
				destroy();
			}
		});

		group.add(this);
    }
}