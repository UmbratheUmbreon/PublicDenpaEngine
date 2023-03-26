package;

import flixel.FlxSprite;
import flixel.effects.particles.FlxEmitter;
import flixel.effects.particles.FlxParticle;
import flixel.util.FlxColor;
import flixel.util.helpers.FlxBounds;
import flixel.util.helpers.FlxPointRangeBounds;
import flixel.util.helpers.FlxRangeBounds;

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
		start(x, y, color);
	}

	public function start(x:Float, y:Float, color:FlxColor) {
		setPosition(x, y);
		this.color = color;

		alpha = 1;
		loadGraphic(Paths.image('effectSprites/particle'));
		lifeTime = FlxG.random.float(0.6, 0.9);
		decay = FlxG.random.float(0.8, 1);
		if(!ClientPrefs.settings.get("flashing"))
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

		loadGraphic(Paths.image('effectSprites/gradient'));
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
		
		frames = Paths.getSparrowAtlas('vanilla/week4/limo/limoDancer');
		animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		animation.play('danceLeft');
	}

	public var danceDir(default, set):Bool = false;
	var animSuffix:String = 'Left';
	function set_danceDir(dir:Bool):Bool {
		danceDir = dir;
		animSuffix = danceDir ? 'Right' : 'Left';
		return danceDir;
	}

	public function dance():Void
	{
		danceDir = !danceDir;
		animation.play('dance$animSuffix', true);
	}
}

class SnowEmitter extends FlxEmitter
{
	public function new(x:Float = 0, y:Float = 0, size:Int = 0, color:FlxColor = 0xffffffff) {
		super(x, y, size);
		alpha = new FlxRangeBounds(0.8, 1);
		this.color = new FlxRangeBounds(FlxColor.subtract(color, 0x001B1B1B), color);
		keepScaleRatio = true;
		launchAngle = new FlxBounds(0.0, 0.0);
		lifespan = new FlxBounds(15.0, 15.0);
		velocity = new FlxPointRangeBounds(-12, 120, 12, 220);
		acceleration = new FlxPointRangeBounds(0, 1, 0, 8);
		width = 2600;
		height = 70;
		launchMode = FlxEmitterMode.SQUARE;
		keepScaleRatio = true;
		scale = new FlxPointRangeBounds(0.5, 0, 0.8, 0);
		loadParticles(Paths.image('effectSprites/particle'), 200, 0);
		start(false, 0.2);
		frequency = 0.2;
	}
}

/**
* Class used to create `BackgroundGirls`s for the School stage.
*/
class BackgroundGirls extends FlxSprite
{
	var isPissed:Bool = true;
	public var stopDancing:Bool = false;
	public function new(x:Float, y:Float)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('vanilla/week6/weeb/bgFreaks');

		swapDanceType();

		animation.play('danceLeft');
		antialiasing = false;
	}

	public var danceDir(default, set):Bool = false;
	var animSuffix:String = 'Left';
	function set_danceDir(dir:Bool):Bool {
		danceDir = dir;
		animSuffix = danceDir ? 'Right' : 'Left';
		return danceDir;
	}

	public function swapDanceType():Void
	{
		isPissed = !isPissed;
		final xmlName:String = isPissed ? 'BG fangirls dissuaded' : 'BG girls group';

		animation.addByIndices('danceLeft', xmlName, CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', xmlName, CoolUtil.numberArray(30, 15), "", 24, false);

		dance();
	}

	public function dance():Void
	{
		if (stopDancing) return;
		danceDir = !danceDir;
		animation.play('dance$animSuffix', true);
	}
}

/**
* Class used to create `TankmenBG`s for the Tank stage.
*/
class TankmenBG extends FlxSprite
{
	public static var animationNotes:Array<Dynamic> = [];
	private var tankSpeed(get, default):Float;
	private var endingOffset:Float;
	private var goingRight:Bool;
	public var strumTime:Float;
	var actualSpeed_:Float;

	public function new(x:Float, y:Float, facingRight:Bool)
	{
		goingRight = false;
		strumTime = 0;
		goingRight = facingRight;
		actualSpeed_ = goingRight ? 0.7 : -0.7;
		runningOffset = goingRight ? 0.02 : 0.74;
		super(x, y);

		frames = Paths.getSparrowAtlas('vanilla/week7/tankmanKilled1');
		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
		animation.play('run');
		animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);
		animation.finishCallback = function(name:String) {
			if(name == 'shot') kill();
		}

		updateHitbox();
		setGraphicSize(Std.int(0.8 * width));
		updateHitbox();
	}

	var runningOffset:Float = 0.02;
	public function resetShit(x:Float, y:Float, goingRight:Bool):Void
	{
		this.x = x;
		this.y = y;
		this.goingRight = goingRight;
		endingOffset = FlxG.random.float(50, 200) * (goingRight ? 1 : -1);
		runningOffset = goingRight ? 0.02 : 0.74;
		actualSpeed_ = FlxG.random.float(0.6, 1) * (goingRight ? 1 : -1);
		flipX = goingRight;
	}

	var stop:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(stop) return;

		visible = (x > -0.5 * FlxG.width && x < 1.2 * FlxG.width);

		x = (runningOffset * FlxG.width + endingOffset) + tankSpeed; //summed up into one equation which is pre-set instead of checking constantly

		if(Conductor.songPosition > strumTime)
		{
			animation.play('shot');
			if(goingRight)
			{
				offset.x = 300;
				offset.y = 200;
			}
			stop = true; //no longer needs to run this update function (cant set active to false or else the entire sprite stops working!!)
		}
	}

	function get_tankSpeed():Float {
		return (Conductor.songPosition - strumTime) * actualSpeed_;
	}
}