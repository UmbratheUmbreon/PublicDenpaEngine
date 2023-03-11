package;

import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.events.KeyboardEvent;

/**
* State used to warn the player of Flashing Lights, and allow them to turn Flashing Lights off.
*/
class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	override function create()
	{
		super.create();

        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		warnText = new FlxText(0, 0, FlxG.width,
			"There are flashing lights in this mod!\n
			Press ACCEPT to disable them.\n
			Press ESCAPE to enable them.\n",
			32);
		warnText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		super.destroy();
	}

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
        if(leftState) return;
		leftState = true;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		switch (eventKey) {
            case ESCAPE | BACKSPACE:
                FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					onComplete: function (twn:FlxTween) {
						MusicBeatState.switchState(new TitleState());
					}
				});
			default:
				ClientPrefs.settings.set("flashing", false);
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
					new FlxTimer().start(0.5, function (tmr:FlxTimer) {
						MusicBeatState.switchState(new TitleState());
					});
				});
        }
    }
}
