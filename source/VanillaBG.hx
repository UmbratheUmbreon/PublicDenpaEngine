package;

import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
* Class used to create `PhillyGlowParticle`s for the Philly stage.
*/
class PhillyGlowParticle extends FlxSprite
{
	var lifeTime:Float = 0;
	var decay:Float = 0;
	var originalScale:Float = 1;
	public function new(x:Float, y:Float, color:FlxColor)
	{
		super(x, y);
		this.color = color;

		loadGraphic(Paths.image('philly/particle'));
		antialiasing = ClientPrefs.globalAntialiasing;
		lifeTime = FlxG.random.float(0.6, 0.9);
		decay = FlxG.random.float(0.8, 1);
		if(!ClientPrefs.flashing)
		{
			decay *= 0.5;
			alpha = 0.5;
		}

		originalScale = FlxG.random.float(0.75, 1);
		scale.set(originalScale, originalScale);

		scrollFactor.set(FlxG.random.float(0.3, 0.75), FlxG.random.float(0.65, 0.75));
		velocity.set(FlxG.random.float(-40, 40), FlxG.random.float(-175, -250));
		acceleration.set(FlxG.random.float(-10, 10), 25);
	}

	override function update(elapsed:Float)
	{
		lifeTime -= elapsed;
		if(lifeTime < 0)
		{
			lifeTime = 0;
			alpha -= decay * elapsed;
			if(alpha > 0)
			{
				scale.set(originalScale * alpha, originalScale * alpha);
			}
		}
		super.update(elapsed);
	}
}

/**
* Class used to create `PhillyGlowGradient`s for the Philly stage.
*/
class PhillyGlowGradient extends FlxSprite
{
	public var originalY:Float;
	public var originalHeight:Int = 400;
	public var intendedAlpha:Float = 1;
	public function new(x:Float, y:Float)
	{
		super(x, y);
		originalY = y;

		loadGraphic(Paths.image('philly/gradient'));
		antialiasing = ClientPrefs.globalAntialiasing;
		scrollFactor.set(0, 0.75);
		setGraphicSize(2000, originalHeight);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		var newHeight:Int = Math.round(height - 1000 * elapsed);
		if(newHeight > 0)
		{
			alpha = intendedAlpha;
			setGraphicSize(2000, newHeight);
			updateHitbox();
			y = originalY + (originalHeight - height);
		}
		else
		{
			alpha = 0;
			y = -5000;
		}

		super.update(elapsed);
	}

	public function bop()
	{
		setGraphicSize(2000, originalHeight);
		updateHitbox();
		y = originalY;
		alpha = intendedAlpha;
	}
}

/**
* Class used to create `BackgroundDancer`s for the Limo stage.
*/
class BackgroundDancer extends FlxSprite
{
	public function new(x:Float, y:Float, ?alt:Bool = false)
	{
		super(x, y);

		if (alt) {
			frames = Paths.getSparrowAtlas("limoNight/limoDancerNight");
			animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
			animation.play('danceLeft');
			antialiasing = ClientPrefs.globalAntialiasing;
		} else {
			frames = Paths.getSparrowAtlas("limo/limoDancer");
			animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
			animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
			animation.play('danceLeft');
			antialiasing = ClientPrefs.globalAntialiasing;
		}
	}

	var danceDir:Bool = false;

	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir)
			animation.play('danceRight', true);
		else
			animation.play('danceLeft', true);
	}
}

/**
* Class used to create `BackgroundGirls`s for the School stage.
*/
class BackgroundGirls extends FlxSprite
{
	var isPissed:Bool = true;
	public function new(x:Float, y:Float)
	{
		super(x, y);

		// BG fangirls dissuaded
		frames = Paths.getSparrowAtlas('weeb/bgFreaks');

		swapDanceType();

		animation.play('danceLeft');
	}

	var danceDir:Bool = false;

	public function swapDanceType():Void
	{
		isPissed = !isPissed;
		if(!isPissed) { //Gets unpissed
			animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
			animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
		} else { //Pisses
			animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
			animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
		}
		dance();
	}

	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir)
			animation.play('danceRight', true);
		else
			animation.play('danceLeft', true);
	}
}

/**
* Class used to create `TankmenBG`s for the Tank stage.
*/
class TankmenBG extends FlxSprite
{
	public static var animationNotes:Array<Dynamic> = [];
	private var tankSpeed:Float;
	private var endingOffset:Float;
	private var goingRight:Bool;
	public var strumTime:Float;

	public function new(x:Float, y:Float, facingRight:Bool)
	{
		tankSpeed = 0.7;
		goingRight = false;
		strumTime = 0;
		goingRight = facingRight;
		super(x, y);

		frames = Paths.getSparrowAtlas('tankmanKilled1');
		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
		animation.play('run');
		animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);
		antialiasing = ClientPrefs.globalAntialiasing;

		updateHitbox();
		setGraphicSize(Std.int(0.8 * width));
		updateHitbox();
	}

	public function resetShit(x:Float, y:Float, goingRight:Bool):Void
	{
		this.x = x;
		this.y = y;
		this.goingRight = goingRight;
		endingOffset = FlxG.random.float(50, 200);
		tankSpeed = FlxG.random.float(0.6, 1);
		flipX = goingRight;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		visible = (x > -0.5 * FlxG.width && x < 1.2 * FlxG.width);

		if(animation.curAnim.name == "run")
		{
			var speed:Float = (Conductor.songPosition - strumTime) * tankSpeed;
			if(goingRight)
				x = (0.02 * FlxG.width - endingOffset) + speed;
			else
				x = (0.74 * FlxG.width + endingOffset) - speed;
		}
		else if(animation.curAnim.finished)
		{
			kill();
		}

		if(Conductor.songPosition > strumTime)
		{
			animation.play('shot');
			if(goingRight)
			{
				offset.x = 300;
				offset.y = 200;
			}
		}
	}
}