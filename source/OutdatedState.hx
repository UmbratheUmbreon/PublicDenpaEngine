package;

import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.display.BlendMode;
import flixel.tweens.FlxEase;
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import flash.geom.Rectangle;

/**
* State used to inform the user of updates.
*/
class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;

	var bottomLayer:FlxBackdrop;
	var middleLayer:FlxBackdrop;
	var topLayer:FlxBackdrop;
	var buttonYes:FlxSprite;
	var buttonNo:FlxSprite;
	var clouds:FlxBackdrop;
	var window:FlxUI9SliceSprite;
	var selected:Int = 0;
	override function create()
	{
		Paths.clearUnusedMemory();
		super.create();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		add(bg);

		bottomLayer = new FlxBackdrop(Paths.image('oscillators/bottom'), 0, 0, true, true, 0, 0);
		bottomLayer.velocity.set(-12, -5); // Speed (Can Also Be Modified For The Direction Aswell)
		bottomLayer.antialiasing = ClientPrefs.globalAntialiasing;
		bottomLayer.scale.set(2,2);
		bottomLayer.updateHitbox();
		bottomLayer.blend = BlendMode.MULTIPLY;

		middleLayer = new FlxBackdrop(Paths.image('oscillators/top'), 0, 0, true, true, 0, 0);
		middleLayer.velocity.set(-5, -12); // Speed (Can Also Be Modified For The Direction Aswell)
		middleLayer.antialiasing = ClientPrefs.globalAntialiasing;
		middleLayer.alpha = 0.5;
		middleLayer.scale.set(2,2);
		middleLayer.updateHitbox();
		middleLayer.blend = BlendMode.DIFFERENCE;

		topLayer = new FlxBackdrop(Paths.image('oscillators/verytop'), 0, 0, true, true, 0, 0);
		topLayer.velocity.set(-24, -14); // Speed (Can Also Be Modified For The Direction Aswell)
		topLayer.antialiasing = ClientPrefs.globalAntialiasing;
		topLayer.alpha = 0;
		topLayer.scale.set(2,2);
		topLayer.updateHitbox();
		topLayer.blend = BlendMode.ADD;

		clouds = new FlxBackdrop(Paths.image('oscillators/clouds'), 0, 0, true, true, 40, 20);
		clouds.velocity.set(27, 20); // Speed (Can Also Be Modified For The Direction Aswell)
		clouds.antialiasing = ClientPrefs.globalAntialiasing;
		clouds.scale.set(13,13);
		clouds.updateHitbox();
		clouds.alpha = 0;
		clouds.color = FlxColor.BLACK;
		clouds.blend = BlendMode.MULTIPLY;

		window = new FlxUI9SliceSprite(0,0, Paths.image('oscillators/sex'), new Rectangle(0, 0, 896, 512), [32, 32, 96, 96]);
		window.screenCenter();
		window.alpha = 0;
		//trace(window.x + ' ' + window.y);
		window.y += 700;

		buttonYes = new FlxSprite(0, 0);
		buttonYes.frames = Paths.getSparrowAtlas('oscillators/buttons');
		buttonYes.animation.addByPrefix('idle', "yesbutton", 12);
		buttonYes.animation.addByPrefix('selected', "yes lit", 12);
		buttonYes.animation.play('idle');
		buttonYes.scale.set(2.5,2.5);
		buttonYes.updateHitbox();
		buttonYes.screenCenter();
		buttonYes.y += 186;
		buttonYes.x -= 156;
		buttonYes.alpha = 0;

		buttonNo = new FlxSprite(0, 0);
		buttonNo.frames = Paths.getSparrowAtlas('oscillators/buttons');
		buttonNo.animation.addByPrefix('idle', "nobutton", 12);
		buttonNo.animation.addByPrefix('selected', "no lit", 12);
		buttonNo.animation.play('idle');
		buttonNo.screenCenter();
		buttonNo.scale.set(2.5,2.5);
		buttonNo.updateHitbox();
		buttonNo.y += 186;
		buttonNo.y -= 25;
		buttonNo.x += 166;
		buttonNo.alpha = 0;

		add(bottomLayer);
		add(middleLayer);
		add(topLayer);
		add(clouds);
		add(window);
		add(buttonYes);
		add(buttonNo);

		FlxTween.tween(topLayer, {alpha: 1}, 5, {
			type: PINGPONG,
			ease: FlxEase.quadInOut
		});

		FlxTween.tween(clouds, {alpha: 0.725}, 40, {
			type: PINGPONG,
			ease: FlxEase.quadInOut
		});

		warnText = new FlxText(10, 0, FlxG.width,
			"Your version of DENPA Engine is outdated!\n
			Your version is: " + MainMenuState.denpaEngineVersion + ",\n
			The current version is: " + TitleState.updateVersion + ".\n
			Would you like to update?",
			32);
		warnText.setFormat(Paths.font("calibri-regular.ttf"), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		warnText.y -= 40;
		warnText.alpha = 0;
		add(warnText);
		FlxTween.tween(window, {alpha: 1, x: 192, y: 104}, 0.5, {
			ease: FlxEase.quadInOut,
			onComplete: function(twn:FlxTween) {
				FlxG.sound.play(Paths.sound('windowOpen'));
				new FlxTimer().start(0.25, function(tmr:FlxTimer) {
					FlxTween.tween(buttonNo, {alpha: 1}, 1, {
						ease: FlxEase.quadInOut
					});
					FlxTween.tween(buttonYes, {alpha: 1}, 1, {
						ease: FlxEase.quadInOut
					});
					FlxTween.tween(warnText, {alpha: 1}, 1, {
						ease: FlxEase.quadInOut
					});
				});
			}
		});
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if ((controls.ACCEPT || (FlxG.mouse.justPressed && ClientPrefs.mouseControls)) && selected == 0) {
				leftState = true;
				CoolUtil.browserLoad("https://github.com/UmbratheUmbreon/PublicDenpaEngine");
			}
			if ((controls.ACCEPT || (FlxG.mouse.justPressed && ClientPrefs.mouseControls)) && selected == 1) {
				leftState = true;
			}

			if(leftState)
			{
				FlxG.sound.play(Paths.sound('windowClose'));
				FlxTween.tween(warnText, {alpha: 0}, 0.5, {
					onComplete: function (twn:FlxTween) {
						if(FlxG.sound.music == null) {
							FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			
							FlxG.sound.music.fadeIn(4, 0, 0.7);
						}
						MusicBeatState.switchState(new MainMenuState());
					}
				});
				FlxTween.tween(window, {alpha: 0}, 0.5);
				FlxTween.tween(buttonNo, {alpha: 0}, 0.5);
				FlxTween.tween(buttonYes, {alpha: 0}, 0.5);
			}
		}
		if (selected == 0){
			buttonNo.animation.play('idle');
			buttonYes.animation.play('selected');
		}
		if (selected == 1){
			buttonNo.animation.play('selected');
			buttonYes.animation.play('idle');
		}
		if (controls.UI_LEFT_P)
			{
				if (selected != 0) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selected = 0;
				}
			}

		if (controls.UI_RIGHT_P)
			{
				if (selected != 1) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selected = 1;
				}
			}
		super.update(elapsed);
	}
}
