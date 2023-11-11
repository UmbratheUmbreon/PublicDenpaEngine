package;

import flash.display.BitmapData;
import flixel.util.FlxColor;
import openfl.geom.Rectangle;

class HealthBar extends flixel.ui.FlxBar
{
	//ty ziad for og code that i made cooler
    public function splitColor(filled:Bool = false, colors:Array<FlxColor>):HealthBar
	{
		var pixelData:BitmapData;
		try {
			pixelData = FlxG.bitmap.get((filled ? _filledKey : _emptyKey)).bitmap;
		} catch(e) {
			FlxG.log.add('Error: ' + e + ' at Healthbar.hx (12-14)');
			return this;
		}

		final chunkSize = height * (1/colors.length);
		for (i in 0...colors.length)
			pixelData.fillRect(new Rectangle(0, chunkSize * i, pixelData.width, chunkSize), colors[i]);

		return this;
	}
}