package;

import flash.display.BitmapData;
import flixel.util.FlxColor;

class HealthBar extends flixel.ui.FlxBar
{
	//ty ziad for og code that i made cooler
    public function splitColor(filled:Bool = false, colors:Array<FlxColor>):HealthBar
	{
		//TODO: Make this function not use a switch and be able to be any amount
		var pixelData:BitmapData;
		try {
			pixelData = FlxG.bitmap.get((filled ? _filledKey : _emptyKey)).bitmap;
		} catch(e) {
			FlxG.log.add('Error: ' + e + ' at Healthbar.hx (12-14)');
			return this;
		}

		final height:Int = pixelData.height;
		switch (colors.length) {
			case 1:
				for (y in 0...height) {
					for (x in 0...pixelData.width) {
						pixelData.setPixel32(x, y, colors[0]);
					}
				}
			case 2:
				for (y in 0...height) {
					for (x in 0...pixelData.width) {
						(y <= (height / 2)-1) ? pixelData.setPixel32(x, y, colors[0]) : pixelData.setPixel32(x, y, colors[1]);
					}
				}
			case 3:
				final oneThird:Float = height * (1/3);
				final twoThird:Float = height * (2/3);
				for (y in 0...height) {
					for (x in 0...pixelData.width) {
						(y <= oneThird-1) ? pixelData.setPixel32(x, y, colors[0]) : ((y > oneThird-1 && y <= twoThird-1) ? pixelData.setPixel32(x, y, colors[1]) : pixelData.setPixel32(x, y, colors[2]));
					}
				}
		}
		return this;
	}
}