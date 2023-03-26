package;

import flash.media.Sound;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;

/**
 * Class used for `Alphabet` text in menus.
 * 
 * Loosely based on FlxText, as Ninjamuffin99 says.
 */
class Alphabet extends FlxSpriteGroup
{
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var targetY(default, set):Float = 0;
	function set_targetY(newY:Float) {
		targetY = newY;

		scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
		return targetY;
	}
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var isMenuItem:Bool = false;
	public var altRotation:Bool = false;
	public var align:String = '';
	public var alignAdd:Float = 0;
	public var textSize:Float = 1.0;

	public var text:String = "";

	var _finalText:String = "";
	var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;

	var splitWords:Array<String> = [];

	public var isBold:Bool = false;
	public var lettersArray:Array<AlphaCharacter> = [];

	public var finishedText:Bool = false;
	public var typed:Bool = false;

	public var typingSpeed:Float = 0.05;
	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, ?typingSpeed:Float = 0.05, ?textSize:Float = 1)
	{
		super(x, y);
		forceX = Math.NEGATIVE_INFINITY;
		this.textSize = textSize;

		_finalText = text;
		this.text = text;
		this.typed = typed;
		isBold = bold;

		if (text != "")
		{
			if (typed)
				startTypedText(typingSpeed);
			else
				addText();
		} else {
			finishedText = true;
		}
	}

	public function changeText(newText:String, newTypingSpeed:Float = -1)
	{
		for (i in 0...lettersArray.length) {
			var letter = lettersArray[0];
			remove(letter, true);
			lettersArray.remove(letter);
			letter.destroy();
		}
		lettersArray = [];
		splitWords = [];
		loopNum = 0;
		xPos = 0;
		curRow = 0;
		consecutiveSpaces = 0;
		xPosResetted = false;
		finishedText = false;
		lastSprite = null;

		var lastX = x;
		x = 0;
		_finalText = newText;
		text = newText;
		if(newTypingSpeed != -1) {
			typingSpeed = newTypingSpeed;
		}

		if (text != "") {
			if (typed)
				startTypedText(typingSpeed);
			else
				addText();
		} else {
			finishedText = true;
		}
		x = lastX;
	}

	public function addText()
	{
		doSplitWords();

		var xPos:Float = 0;
		for (character in splitWords)
		{
			var spaceChar:Bool = (character == " ");
			if (spaceChar)
				consecutiveSpaces++;

			var isNumber:Bool = AlphaCharacter.numbers.indexOf(character) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(character) != -1;
			var isAlphabet:Bool = AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1;
			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null)
					xPos = lastSprite.x + lastSprite.width;

				if (consecutiveSpaces > 0)
					xPos += 40 * consecutiveSpaces * textSize;

				consecutiveSpaces = 0;

				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0, textSize);

				letter.set(character, isAlphabet, isBold, typed);

				add(letter);
				lettersArray.push(letter);

				lastSprite = letter;
			}
		}
	}

	inline function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	var loopNum:Int = 0;
	var xPos:Float = 0;
	public var curRow:Int = 0;
	var dialogueSound:FlxSound = null;
	private static var soundDialog:Sound = null;
	var consecutiveSpaces:Int = 0;
	inline public static function setDialogueSound(name:String = '')
	{
		if (name == null || name.trim() == '') name = 'dialogue';
		soundDialog = Paths.sound(name);
		if(soundDialog == null) soundDialog = Paths.sound('dialogue');
	}

	var typeTimer:FlxTimer = null;
	public function startTypedText(speed:Float):Void
	{
		_finalText = text;
		doSplitWords();

		if(soundDialog == null)
			Alphabet.setDialogueSound();

		if(speed <= 0) {
			while(!finishedText) { 
				timerCheck();
			}
			if(dialogueSound != null) dialogueSound.stop();
			dialogueSound = FlxG.sound.play(soundDialog);
		} else {
			typeTimer = new FlxTimer().start(0.1, function(tmr:FlxTimer) {
				typeTimer = new FlxTimer().start(speed, function(tmr:FlxTimer) {
					timerCheck(tmr);
				}, 0);
			});
		}
	}

	var LONG_TEXT_ADD:Float = -24; //text is over 2 rows long, make it go up a bit
	public function timerCheck(?tmr:FlxTimer = null) {
		var autoBreak:Bool = false;
		if ((loopNum <= splitWords.length - 2 && splitWords[loopNum] == "\\" && splitWords[loopNum+1] == "n") ||
			((autoBreak = true) && xPos >= FlxG.width * 0.65 && splitWords[loopNum] == ' ' ))
		{
			if(tmr != null) tmr.loops -= (autoBreak ? 1 : 2);
				loopNum += (autoBreak ? 1 : 2);
				
			yMulti += 1;
			xPosResetted = true;
			xPos = 0;
			curRow += 1;
			if(curRow == 2) y += LONG_TEXT_ADD;
		}

		if(loopNum <= splitWords.length && splitWords[loopNum] != null) {
			var spaceChar:Bool = (splitWords[loopNum] == " ");
			if (spaceChar)
				consecutiveSpaces++;

			var isNumber:Bool = AlphaCharacter.numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(splitWords[loopNum]) != -1;
			var isAlphabet:Bool = AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1;

			if ((isAlphabet || isSymbol || isNumber) && (!isBold || !spaceChar))
			{
				if (lastSprite != null && !xPosResetted)
				{
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
				}
				else
				{
					xPosResetted = false;
				}

				if (consecutiveSpaces > 0)
					xPos += 20 * consecutiveSpaces * textSize;

				consecutiveSpaces = 0;

				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti, textSize);
				letter.row = curRow;

				letter.set(splitWords[loopNum], isAlphabet, isBold);
				letter.x += 90;

				if(tmr != null) {
					if(dialogueSound != null) dialogueSound.stop();
					dialogueSound = FlxG.sound.play(soundDialog);
				}

				add(letter);
				lettersArray.push(letter); //so it can be destroyed later

				lastSprite = letter;
			}
		}

		loopNum++;
		if(loopNum >= splitWords.length) {
			if(tmr != null) {
				typeTimer = null;
				tmr.cancel();
				tmr.destroy();
			}
			finishedText = true;
		}
	}

	var scaledY:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		final lerpVal:Float = CoolUtil.clamp(elapsed * 9.6, 0, 1);
		if (isMenuItem)
		{
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
			x = (forceX != Math.NEGATIVE_INFINITY ? forceX : FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal));
			return;
		}
		if (altRotation) {
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
			if(forceX != Math.NEGATIVE_INFINITY) {
				x = forceX;
			} else {
				switch (targetY) {
					case 0:
						x = FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
					default:
						x = FlxMath.lerp(x, (targetY * (targetY < 0 ? 20 : -20)) + 90 + xAdd, lerpVal);
				}
			}
			return;
		}
		if (!altRotation && !isMenuItem && align.length > 0) {
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpVal);
			if(forceX != Math.NEGATIVE_INFINITY) {
				x = forceX;
			} else {
				switch (align.toLowerCase()) {
					case 'left':
						x = FlxMath.lerp(x, (isBold ? 30 : 15) + alignAdd, lerpVal);
					case 'right':
						x = FlxMath.lerp(x, (FlxG.width - width) - (isBold ? 30 : 15) + alignAdd, lerpVal);
					case 'center':
						x = FlxMath.lerp(x, (FlxG.width/2) - width/2, lerpVal);
					case 'none':
						//do nothing
					default:
						x = FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpVal);
				}
			}
		}
	}

	override function destroy() {
		lettersArray = FlxDestroyUtil.destroyArray(lettersArray);
		lastSprite = FlxDestroyUtil.destroy(lastSprite);
		killTheTimer();
		super.destroy();
	}

	inline public function killTheTimer() {
		if(typeTimer != null) {
			typeTimer.cancel();
			typeTimer.destroy();
		}
		typeTimer = null;
	}
}

class AlphaCharacter extends FlxSprite
{
	//actual xml mapping
	private static final characters:Map<String, String> = [
		//SPECIAL CHARS -> DIFF NAME
		"ñ" => "ENE LOWERCASE",
		"Ñ" => "ENE",
		//numbers -> proper name
		"1" => "ONE",
		"2" => "TWO",
		"3" => "THREE",
		"4" => "FOUR",
		"5" => "FIVE",
		"6" => "SIX",
		"7" => "SEVEN",
		"8" => "EIGHT",
		"9" => "NINE",
		"0" => "ZERO",
		//symbols -> proper/abbreviated name
		"|" => "BAR",
		"~" => "TILDA",
		"#" => "HASHTAG",
		"&" => "AMPERSAND",
		"$" => "DOLLAR",
		"%" => "PERCENTAGE",
		"(" => "L PARENTHESIS",
		")" => "R PARENTHESIS",
		"*" => "ASTERISK",
		"+" => "PLUS",
		"-" => "DASH",
		":" => "COLON",
		";" => "SEMICOLON",
		"<" => "LESS",
		"=" => "EQUAL",
		">" => "GREATER",
		"@" => "AT",
		"[" => "L SQR BRACKET",
		"]" => "R SQR BRACKET",
		"^" => "CARROT",
		"_" => "UNDERSCORE",
		"." => "PERIOD",
		"," => "COMMA",
		"'" => "APOSTROPHE",
		"\"" => "DBL QUOTE START",
		"!" => "EXCLAMATION",
		"¡" => "EXCLAMATION",
		"?" => "QUESTION",
		"¿" => "QUESTION",
		"{" => "L CRLY BRACKET",
		"}" => "R CRLY BRACKET",
		"`" => "BACKTICK",
		"\\" => "BACKSLASH",
		"/" => "FORWARD SLASH",
		"×" => "MULTIPLY",
		"↑" => "UP ARROW",
		"→" => "RIGHT ARROW",
		"←" => "LEFT ARROW",
		"↓" => "DOWN ARROW",
		"♥" => "HEART",
		"😡" => "ANGRY FAIC" //ah yes, emoji in code
	];
	
	//for determaining which it is
	public static final alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static final numbers:String = "1234567890";

	public static final symbols:String = "|~#&$%()*+-:;<=>@[]^_.,'\"!¡?¿\\/×↑→←↓♥😡ñÑ";

	public var row:Int = 0;

	private var textSize:Float = 1;

	public function new(x:Float, y:Float, textSize:Float)
	{
		super(x, y);

		this.textSize = textSize;
		moves = false;
	}

	public function set(character:String, letter:Bool, bold:Bool, ?typed:Bool = false) {
		var path = (letter ? (character.toUpperCase() != character ? '${character.toUpperCase()} LOWERCASE' : character) : '');
		if (!letter) path = characters.get((bold && character == '_') ? '-' : character); //??
		if (!Paths.fileExists('images/alphabet/' + (bold ? path.replace('LOWERCASE', '').trim() + ' BOLD' : path) + '.png', IMAGE))
			path = 'QUESTION';
		var gfx = Paths.image('alphabet/' + (bold ? path.replace('LOWERCASE', '').trim() + ' BOLD' : path));
		loadGraphic(gfx, true, Math.floor(gfx.width/2), gfx.height);
		setGraphicSize(Std.int(width * textSize));
		animation.add(character, [0, 0, 1, 1], 24);
		animation.play(character);
		updateHitbox();

		if (bold) {
			switch (character.toUpperCase())
			{
				case "'": y -= 20 * textSize;
				case '-': y += 22 * textSize;
				case '_': y += 50 * textSize; //totally real underscore
				case '(' | ')': y -= 5 * textSize;
				case '.': y += 47 * textSize;
				case 'Ñ': y -= 26 * textSize; //ñ (eñe)
				case '!': y -= 11 * textSize;
				case '?': y -= 7 * textSize;
				case '¿' | '¡': flipX = flipY = true;
				case '+': y += 13 * textSize;
				case '~': y += 16 * textSize;
			}
			return;
		}

		y = (110 - height) + (row * 60);
		switch (character)
		{
			//elaborate offsets
			case "~": y -= 18.5 * textSize;
			case "*": y -= 34.2 * textSize;
			case "^": y -= 35.7 * textSize;
			case "\"": y -= 42.8 * textSize;
			case "+": y -= 11.4 * textSize;
			case "=": y -= 15.7 * textSize;
			case "×" | "↑" | "→" | "←" | "↓" | "♥": y -= 14.2 * textSize;
			case "#": y -= 7.1 * textSize;
			case "'": y -= 28.5 * textSize;
			case '-': y -= 20 * textSize;
			case "|": y += 7.1 * textSize;
			case ';': y += 4.2 * textSize;
			case ',': y += 8.5 * textSize;
			case 'g': y += 10 * textSize;
			case 'j': y += 5.7 * textSize;
			case 'q': y += 12.8 * textSize;
			case 'y': y += 11.4 * textSize;
			case '¿' | '¡':
				y += 10 * textSize;
				flipX = flipY = true;
		}
	}
}

/**
* Class used to create `Alphabet`s that automatically follow an `FlxSprite`.
*/
class AttachedText extends Alphabet
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var sprTracker:FlxSprite;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;
	public var copyState:Bool = false;
	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0, ?bold = false, ?scale:Float = 1) {
		super(0, 0, text, bold, false, 0.05, scale);
		isMenuItem = false;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}

	override function update(elapsed:Float) {
		if (sprTracker != null) {
			setPosition(sprTracker.x + offsetX, sprTracker.y + offsetY);
			if(copyVisible) {
				visible = sprTracker.visible;
			}
			if(copyAlpha) {
				alpha = sprTracker.alpha;
			}
			if (copyState) {
				visible = sprTracker.visible;
				active = sprTracker.active;
			}
		}

		super.update(elapsed);
	}
}
