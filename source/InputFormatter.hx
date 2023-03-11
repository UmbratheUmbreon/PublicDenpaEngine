package;

import flixel.input.keyboard.FlxKey;

class InputFormatter {
	inline public static function getKeyName(key:FlxKey):String {
		switch (key) {
			case BACKSPACE: return "BckSpc";
			case CONTROL: return "Ctrl";
			case ALT: return "Alt";
			case CAPSLOCK: return "Caps";
			case PAGEUP: return "PgUp";
			case PAGEDOWN: return "PgDown";
			case ZERO: return "0";
			case ONE: return "1";
			case TWO: return "2";
			case THREE: return "3";
			case FOUR: return "4";
			case FIVE: return "5";
			case SIX: return "6";
			case SEVEN: return "7";
			case EIGHT: return "8";
			case NINE: return "9";
			case NUMPADZERO: return "NmPd 0";
			case NUMPADONE: return "NmPd 1";
			case NUMPADTWO: return "NmPd 2";
			case NUMPADTHREE: return "NmPd 3";
			case NUMPADFOUR: return "NmPd 4";
			case NUMPADFIVE: return "NmPd 5";
			case NUMPADSIX: return "NmPd 6";
			case NUMPADSEVEN: return "NmPd 7";
			case NUMPADEIGHT: return "NmPd 8";
			case NUMPADNINE: return "NmPd 9";
			case NUMPADMULTIPLY: return "NmPd *";
			case NUMPADPLUS: return "NmPd +";
			case NUMPADMINUS: return "NmPd -";
			case NUMPADPERIOD: return "NmPd .";
			case SEMICOLON: return ";";
			case COMMA: return ",";
			case PERIOD: return ".";
			case SLASH: return "Slash";
			case GRAVEACCENT: return "`";
			case LBRACKET: return "[";
			case BACKSLASH: return "BckSlsh";
			case RBRACKET: return "]";
			case QUOTE: return "'";
			case PRINTSCREEN: return "PrtScrn";
			case NONE: return '---';
			default:
                if (key != 'null')
				    return CoolUtil.toTitleCase(key.toString().toLowerCase());
                return '---';
		}
	}
}
