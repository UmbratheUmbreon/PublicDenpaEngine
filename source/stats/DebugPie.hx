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

		text = "";

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 340;
		height = 90;
	}

	private function onEnter(_)
	{
		//this will render a pie chart later
		//it will make total from all the mem counts, then make percentages
		//then map the percentages to the chart and render
		if (!visible) return;
		var sndArr = CoolUtil.truncateByteFormat(FlxG.sound.getTotalSoundBytes());
		var mscArr = CoolUtil.truncateByteFormat(FlxG.sound.getTotalMusicBytes());
		var bmpArr = CoolUtil.truncateByteFormat(FlxG.bitmap.getTotalBytes());
		text = 'BMP: ${bmpArr[0]} ${bmpArr[1]}' +
			'\nSND: ${sndArr[0]} ${sndArr[1]}' +
			'\nMUS: ${mscArr[0]} ${mscArr[1]}';
	}
}