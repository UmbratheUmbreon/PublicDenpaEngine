package stats;

import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;

class DebugPie extends TextField
{
	var tmr:Timer;
	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();

		x = inX;
		y = inY;

		selectable = false;

		defaultTextFormat = new TextFormat("VCR OSD Mono", 12, inCol);

		text = 'BMP: 0 B' +
			'\nSND: 0 B' +
			'\nMUS: 0 B';

		width = 110;
		height = 40;
	}

	var lastFT:Float = 0.0;
	private override function __enterFrame(deltaTime:Float):Void
	{
		//this will render a pie chart later
		//it will make total from all the mem counts, then make percentages
		//then map the percentages to the chart and render
		if (!visible) return;

		//le buffer
		lastFT += deltaTime;
		lastFT -= lastFT > 750 ? 750 : return;
		
		var sndArr = CoolUtil.truncateByteFormat(FlxG.sound.getTotalSoundBytes());
		var musArr = CoolUtil.truncateByteFormat(FlxG.sound.getTotalMusicBytes());
		var bmpArr = CoolUtil.truncateByteFormat(FlxG.bitmap.getTotalBytes());
		text = 'BMP: ${Math.fround(cast (bmpArr[0], Float) * 100)/100} ${bmpArr[1]}' +
			'\nSND: ${Math.fround(cast (sndArr[0], Float) * 100)/100} ${sndArr[1]}' +
			'\nMUS: ${Math.fround(cast (musArr[0], Float) * 100)/100} ${musArr[1]}';
	}
}