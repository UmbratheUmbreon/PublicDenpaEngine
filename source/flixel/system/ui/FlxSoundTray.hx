package flixel.system.ui;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
#if flash
import flash.text.AntiAliasType;
import flash.text.GridFitType;
#end

/**
 * The flixel sound tray, the little volume meter that pops down sometimes.
 * Accessed via `FlxG.game.soundTray` or `FlxG.sound.soundTray`.
 */
class FlxSoundTray extends Sprite
{
	/**
	 * Because reading any data from DisplayObject is insanely expensive in hxcpp, keep track of whether we need to update it or not.
	 */
	public var active:Bool;

	/**
	 * Helps us auto-hide the sound tray after a volume change.
	 */
	var _timer:Float;

	/**
	 * Helps display the volume bars on the sound tray.
	 */
	var _bars:Array<Bitmap>;

    /**
	 * Displays the actual volume as text.
	 */
    var _volumeDisplay:TextField;

	/**
	 * How wide the sound tray background is.
	 */
	var _width:Int = 80;

	var _defaultScale:Float = 2.0;

	/**The sound used when increasing the volume.**/
	//public var volumeSound:String = "flixel/sounds/beep";

	/**Whether or not changing the volume should make noise.**/
	public var silent:Bool = false;

	/**
	 * Sets up the "sound tray", the little volume meter that pops down sometimes.
	 */
	@:keep
	public function new()
	{
		super();

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;
		var tmp:Bitmap = new Bitmap(new BitmapData(_width, 30, true, 0x7F000000));
		screenCenter();
		addChild(tmp);

		var text:TextField = new TextField();
		text.width = tmp.width;
		text.height = tmp.height;
		text.multiline = true;
		text.wordWrap = true;
		text.selectable = false;

		#if flash
		text.embedFonts = true;
		text.antiAliasType = AntiAliasType.NORMAL;
		text.gridFitType = GridFitType.PIXEL;
		#else
		#end
		var dtf:TextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 8, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		text.defaultTextFormat = dtf;
		addChild(text);
		text.text = "VOLUME";
		text.y = 18;

        _volumeDisplay = new TextField();
		_volumeDisplay.width = tmp.width;
		_volumeDisplay.height = tmp.height;
		_volumeDisplay.multiline = true;
		_volumeDisplay.wordWrap = true;
		_volumeDisplay.selectable = false;

		#if flash
		_volumeDisplay.embedFonts = true;
		_volumeDisplay.antiAliasType = AntiAliasType.NORMAL;
		_volumeDisplay.gridFitType = GridFitType.PIXEL;
		#else
		#end
		var dtf:TextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 4, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		_volumeDisplay.defaultTextFormat = dtf;
		addChild(_volumeDisplay);
		_volumeDisplay.text = "%";
		_volumeDisplay.y = 12;

		var bx:Int = 10;
		var by:Int = 12;
		_bars = new Array();

		for (i in 0...10)
		{
			tmp = new Bitmap(new BitmapData(4, i + 1, false, FlxColor.WHITE));
			tmp.x = bx;
			tmp.y = by;
			addChild(tmp);
			_bars.push(tmp);
			bx += 6;
			by--;
		}

		y = -height;
		visible = false;
	}

	/**
	 * This function just updates the soundtray object.
	 */
	public function update(MS:Float):Void
	{
		// Animate stupid sound tray thing
		if (_timer > 0)
		{
			_timer -= MS / 1000;
		}
		else if (y > -height)
		{
			y -= (MS / 1000) * FlxG.height * 2;

			if (y <= -height)
			{
				visible = false;
				active = false;

				// Save sound preferences
				if (FlxG.save.isBound)
				{
					FlxG.save.data.mute = FlxG.sound.muted;
					FlxG.save.data.volume = FlxG.sound.volume;
					FlxG.save.flush();
				}
			}
		}
	}

	/**
	 * Makes the little volume tray slide out.
	 *
	 * @param	up Whether the volume is increasing.
	 */
	public function show(up:Bool = false, _silent:Bool = false):Void
	{
		if (!_silent && !silent)
		{
			//atleast its better than the ear piercing beep 
			FlxG.sound.play(Paths.sound('bfBeep'));
		}

		_timer = 1;
		y = 0;
		visible = true;
		active = true;
		var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

		if (FlxG.sound.muted)
		{
			globalVolume = 0;
		}

		for (i in 0..._bars.length)
		{
			if (i < globalVolume)
			{
				_bars[i].alpha = 1;
			}
			else
			{
				_bars[i].alpha = 0.5;
			}
		}

        final vol = Math.round(FlxG.sound.volume*100);
        _volumeDisplay.text = '$vol%${(FlxG.sound.muted ? ' (MUTE)' : '')}';
	}

	public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (0.5 * (Lib.current.stage.stageWidth - _width * _defaultScale) - FlxG.game.x);
	}
}
#end