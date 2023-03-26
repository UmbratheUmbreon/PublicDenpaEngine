package;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;

/**
* Class used to handle cutscenes, such as the ones seen in Week 7.
* See `PlayState` for how to use this class.
*/
class CutsceneHandler extends FlxBasic
{
	public var timedEvents:Array<Dynamic> = [];
	public var finishCallback:Void->Void = null;
	public var finishCallback2:Void->Void = null;
	public var onStart:Void->Void = null;
	public var endTime:Float = 0;
	public var objects:Array<FlxSprite> = [];
	public var tweens:Array<FlxTween> = [];
	public var music:String = null;
	public var sounds:Array<FlxSound> = [];
	public var canSkip:Bool = false;
	public function new()
	{
		super();

		timer(0, function()
		{
			if(music != null)
			{
				FlxG.sound.playMusic(Paths.music(music), 0, false);
				FlxG.sound.music.fadeIn();
			}
			if(onStart != null) onStart();
		});
		PlayState.instance.add(this);
	}

	private var cutsceneTime:Float = 0;
	private var firstFrame:Bool = false;
	var acceptKeys:Array<flixel.input.keyboard.FlxKey> = ClientPrefs.keyBinds.get('accept');
	override function update(elapsed)
	{
		super.update(elapsed);

		if(FlxG.state != PlayState.instance || !firstFrame)
		{
			firstFrame = true;
			return;
		}

		cutsceneTime += elapsed;
		if(endTime <= cutsceneTime)
		{
			finishCallback();
			if(finishCallback2 != null) finishCallback2();

			for (spr in objects)
			{
				PlayState.instance.remove(spr);
				spr.destroy();
			}
			
			kill();
			destroy();
			PlayState.instance.remove(this);
		}

		if (canSkip) {
			if (FlxG.keys.anyJustPressed(acceptKeys))
			{
				finishCallback();
				if(finishCallback2 != null) finishCallback2();
		
				for (spr in objects)
				{
					PlayState.instance.remove(spr);
					objects.remove(spr);
					spr.destroy();
				}
		
				for (sound in sounds)
				{
					if (sound.playing)
						sound.stop();
					sounds.remove(sound);
				}

				for (tween in tweens)
				{
					if (tween != null) tween.cancel();
					tween = null;
					tweens.remove(tween);
				}

				timedEvents = [];
		
				PlayState.instance.remove(this);
				destroy();
			}
		}
		
		while(timedEvents.length > 0 && timedEvents[0][0] <= cutsceneTime)
		{
			timedEvents[0][1]();
			timedEvents.splice(0, 1);
		}
	}

	inline public function push(spr:FlxSprite)
	{
		objects.push(spr);
	}

	inline public function timer(time:Float, func:Void->Void)
	{
		timedEvents.push([time, func]);
		timedEvents.sort(sortByTime);
	}

	inline function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
}