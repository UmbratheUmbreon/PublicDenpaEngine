package;

import flixel.FlxSprite;
import editors.ChartingState;
import Shaders.ColorSwap;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

/**
* Basic class for all `Note`s.
*/
class Note extends FlxSprite
{
	public static var gfxLetter:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];

	public static var scales:Array<Float> = [0.9, 0.85, 0.8, 0.7, 0.66, 0.6, 0.55, 0.50, 0.46];
	public static var lessX:Array<Int> = [0, 0, 0, 0, 0, 8, 7, 8, 8];
	public static var separator:Array<Int> = [0, 0, 1, 1, 2, 2, 2, 3, 3];
	public static var xtra:Array<Int> = [150, 89, 0, 0, 0, 0, 0, 0, 0];
	public static var posRest:Array<Int> = [0, 0, 0, 0, 25, 32, 46, 52, 60];
	public static var gridSizes:Array<Int> = [40, 40, 40, 40, 40, 40, 40, 40, 40];
	public static var offsets:Array<Dynamic> = [
		[20, 10],
		[10, 10],
		[10, 10],
		[10, 10],
		[10, 10],
		[10, 10],
		[10, 10],
		[10, 10],
		[10, 10],
		[10, 20],
		[10, 10],
		[10, 10]
	];

	public static var minMania:Int = 0;
	public static var maxMania:Int = 8;
	public static var defaultMania:Int = 3;
	//E = Space
	//ABCD = Left Down Up Right
	//FGHI = LDUR 2
	//J = Circ 1
	//K = Circ 2

	public static var keysShit:Map<Int, Map<String, Dynamic>> = [
		0 => ["letters" => ["E"], "anims" => ["SPACE"],
			"strumAnims" => ["SPACE"], "pixelAnimIndex" => [4]],

		1 => ["letters" => ["A", "D"], "anims" => ["LEFT", "RIGHT"],
			"strumAnims" => ["LEFT", "RIGHT"], "pixelAnimIndex" => [0, 3]],

		2 => ["letters" => ["A", "E", "D"], "anims" => ["LEFT", "SPACE", "RIGHT"],
			"strumAnims" => ["LEFT", "SPACE", "RIGHT"], "pixelAnimIndex" => [0, 4, 3]],

		3 => ["letters" => ["A", "B", "C", "D"], "anims" => ["LEFT", "DOWN", "UP", "RIGHT"],
			"strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 2, 3]],

		4 => ["letters" => ["A", "B", "E", "C", "D"], "anims" => ["LEFT", "DOWN", "SPACE", "UP", "RIGHT"],
			 "strumAnims" => ["LEFT", "DOWN", "SPACE", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 4, 2, 3]],

		5 => ["letters" => ["A", "C", "D", "F", "B", "I"], "anims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"],
			 "strumAnims" => ["LEFT", "UP", "RIGHT", "LEFT", "DOWN", "RIGHT"], "pixelAnimIndex" => [0, 2, 3, 5, 1, 8]],

		6 => ["letters" => ["A", "C", "D", "E", "F", "B", "I"], "anims" => ["LEFT", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "RIGHT"],
			 "strumAnims" => ["LEFT", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "RIGHT"], "pixelAnimIndex" => [0, 2, 3, 4, 5, 1, 8]],
			
		7 => ["letters" => ["A", "B", "C", "D", "F", "G", "H", "I"], "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"],
			 "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "LEFT", "DOWN", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 2, 3, 5, 6, 7, 8]],
		
		8 => ["letters" => ["A", "B", "C", "D", "E", "F", "G", "H", "I"], "anims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT"],
			 "strumAnims" => ["LEFT", "DOWN", "UP", "RIGHT", "SPACE", "LEFT", "DOWN", "UP", "RIGHT"], "pixelAnimIndex" => [0, 1, 2, 3, 4, 5, 6, 7, 8]],
	];

	public static var ammo:Array<Int> = [
		1, 2, 3, 4, 5, 6, 7, 8, 9
	];

	public static var pixelScales:Array<Float> = [1.2, 1.15, 1.1, 1, 0.9, 0.83, 0.8, 0.74, 0.7];

	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	//public var isSustainEnd:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	public var gfNote:Bool = false;
	public var altNote:Bool = false;
	private var earlyHitMult:Float = 0.5;

	public static var swagWidth:Float = 160 * 0.7;

	// Lua shit
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyScale:Bool = false;
	public var scaleHackHitbox:Bool = true;

	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;

	public var mania:Int = 1;

	var ogW:Float;
	var ogH:Float;

	var defaultWidth:Float = 0;
	var defaultHeight:Float = 0;

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote('', value);
		}
		texture = value;
		return value;
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.assets.splashSkin;
		colorSwap.hue = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData] % Note.ammo[mania])][0] / 360;
		colorSwap.saturation = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData] % Note.ammo[mania])][1] / 100;
		colorSwap.brightness = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(mania).get('pixelAnimIndex')[noteData] % Note.ammo[mania])][2] / 100;

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					reloadNote('HURT');
					noteSplashTexture = 'splashes/HURTnoteSplashes';
					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;
					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;
				case 'No Animation':
					noAnimation = true;
				case 'GF Sing' | 'GF Cross Fade':
					gfNote = true;
				case 'Third Strum':
					altNote = true;
			}
			noteType = value;
		}
		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false)
	{
		super();

		mania = PlayState.mania;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;

		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.noteOffset;

		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';
			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData % Note.ammo[mania]);
			if(!isSustainNote) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = Note.keysShit.get(mania).get('letters')[noteData % Note.ammo[mania]];
				animation.play(animToPlay);
			}
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
			{
				alpha = 0.6;
				multAlpha = 0.6;
				hitsoundDisabled = true;
				if(ClientPrefs.downScroll) flipY = true;
	
				offsetX += width / 2;
				copyAngle = false;
	
				animation.play(Note.keysShit.get(mania).get('letters')[noteData] + ' tail');
	
				updateHitbox();
	
				offsetX -= width / 2;
	
				if (PlayState.isPixelStage)
					offsetX += 30 * Note.pixelScales[mania];
	
				if (prevNote.isSustainNote)
				{
					prevNote.animation.play(Note.keysShit.get(mania).get('letters')[prevNote.noteData] + ' hold');
	
					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
					if(PlayState.instance != null)
					{
						prevNote.scale.y *= PlayState.instance.songSpeed;
					}
	
					if(PlayState.isPixelStage) { ///Y E  A H
						prevNote.scale.y *= 1.19;
						prevNote.scale.y *= (6 / height); //Auto adjust note size
					}
					prevNote.updateHitbox();
					// prevNote.setGraphicSize();
				}
	
				if(PlayState.isPixelStage) {
					scale.y *= PlayState.daPixelZoom;
					updateHitbox();
				}
			} else if(!isSustainNote) {
				earlyHitMult = 1;
			}
		x += offsetX;
	}

	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	public var originalHeightForCalcs:Float = 6;
	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';
		
		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG.assets.arrowSkin;
			if(skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length-1] = prefix + arraySkin[arraySkin.length-1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		defaultWidth = 157;
		defaultHeight = 154;
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'));
				width = width / 18;
				height = height / 2;
				originalHeightForCalcs = height;
				loadGraphic(Paths.image('pixelUI/' + blahblah + 'ENDS'), true, Math.floor(width), Math.floor(height));
			} else {
				loadGraphic(Paths.image('pixelUI/' + blahblah));
				width = width / 18;
				height = height / 5;
				loadGraphic(Paths.image('pixelUI/' + blahblah), true, Math.floor(width), Math.floor(height));
			}
			defaultWidth = width;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[mania]));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += lastNoteOffsetXForPixelAutoAdjusting;
				lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
				
				/*if(animName != null && !animName.endsWith('end'))
				{
					lastScaleY /= lastNoteScaleToo;
					lastNoteScaleToo = (6 / height);
					lastScaleY *= lastNoteScaleToo; 
				}*/
			}
		} else {
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
			antialiasing = ClientPrefs.globalAntialiasing;
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();

		if(animName != null)
			animation.play(animName, true);

		if(inEditor) {
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	}

	function loadNoteAnims() {
		for (i in 0...gfxLetter.length)
			{
				animation.addByPrefix(gfxLetter[i], gfxLetter[i] + '0');
	
				if (isSustainNote)
				{
					animation.addByPrefix(gfxLetter[i] + ' hold', gfxLetter[i] + ' hold');
					animation.addByPrefix(gfxLetter[i] + ' tail', gfxLetter[i] + ' tail');
				}
			}
				
			ogW = width;
			ogH = height;
			if (!isSustainNote)
				setGraphicSize(Std.int(defaultWidth * scales[mania]));
			else
				setGraphicSize(Std.int(defaultWidth * scales[mania]), Std.int(defaultHeight * scales[0]));
			updateHitbox();
	}

	function loadPixelNoteAnims() {
		if(isSustainNote) {
			for (i in 0...gfxLetter.length) {
				animation.add(gfxLetter[i] + ' hold', [i]);
				animation.add(gfxLetter[i] + ' tail', [i + 18]);
			}
		} else {
			for (i in 0...gfxLetter.length) {
				animation.add(gfxLetter[i], [i + 18]);
			}
		}
	}

	public function applyManiaChange()
		{
			if (isSustainNote) 
				scale.y = 1;
			reloadNote(texture);
			if (isSustainNote)
				offsetX = width / 2;
			if (!isSustainNote)
			{
				var animToPlay:String = '';
				animToPlay = Note.keysShit.get(mania).get('letters')[noteData % Note.ammo[mania]];
				animation.play(animToPlay);
			}
	
			if (isSustainNote && prevNote != null)
			{
				animation.play(Note.keysShit.get(mania).get('letters')[noteData % Note.ammo[mania]] + ' tail');
				if (prevNote.isSustainNote)
				{
					prevNote.animation.play(Note.keysShit.get(mania).get('letters')[noteData % Note.ammo[mania]] + ' hold');
					prevNote.updateHitbox();
				}
			}
	
			updateHitbox();
		}

		override function update(elapsed:Float)
			{
				super.update(elapsed);
		
				mania = PlayState.mania;
		
				if (mustPress)
				{
					// ok river
					if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
						&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
						canBeHit = true;
					else
						canBeHit = false;
		
					if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
						tooLate = true;
				}
				else
				{
					canBeHit = false;
		
					if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
					{
						if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
							wasGoodHit = true;
					}
				}
		
				if (!inEditor) {
					/*if(animation.curAnim.name.endsWith("tail") && ClientPrefs.osuManiaSustains)
					{
						isSustainEnd = true;
					}
					else
					{
						isSustainEnd = false;
					}*/
		
					if(tooLate && alpha > 0.3)
					{
						alpha = 0.3;
					}
				}
			}
}

/**
* Basic class for all `StrumNote`s.
* This class is used to create the strum line.
*/
class StrumNote extends FlxSprite
{
	private var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	private var player:Int;

	private var skinThing:Array<String> = ['static', 'pressed'];
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var stat:String = Note.keysShit.get(PlayState.mania).get('strumAnims')[leData];
		var pres:String = Note.keysShit.get(PlayState.mania).get('letters')[leData];
		skinThing[0] = stat;
		skinThing[1] = pres;

		var skin:String = 'NOTE_assets';
		//if(PlayState.isPixelStage) skin = 'PIXEL_' + skin;
		if(PlayState.SONG.assets.arrowSkin != null && PlayState.SONG.assets.arrowSkin.length > 1) skin = PlayState.SONG.assets.arrowSkin;
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
			{
				loadGraphic(Paths.image('pixelUI/' + texture));
				width = width / 18;
				height = height / 5;
				antialiasing = false;
				loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));
				var daFrames:Array<Int> = Note.keysShit.get(PlayState.mania).get('pixelAnimIndex');

				setGraphicSize(Std.int(width * PlayState.daPixelZoom * Note.pixelScales[PlayState.mania]));
				updateHitbox();
				antialiasing = false;
				animation.add('static', [daFrames[noteData]]);
				animation.add('pressed', [daFrames[noteData] + 18, daFrames[noteData] + 36], 12, false);
				animation.add('confirm', [daFrames[noteData] + 54, daFrames[noteData] + 72], 24, false);
				//i used calculator
			}
		else
			{
				frames = Paths.getSparrowAtlas(texture);

				antialiasing = ClientPrefs.globalAntialiasing;

				setGraphicSize(Std.int(width * Note.scales[PlayState.mania]));
		
				animation.addByPrefix('static', 'arrow' + skinThing[0]);
				animation.addByPrefix('pressed', skinThing[1] + ' press', 24, false);
				animation.addByPrefix('confirm', skinThing[1] + ' confirm', 24, false);
			}

		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		switch (PlayState.mania)
		{
			case 0 | 1 | 2: x += width * noteData;
			case 3: x += (Note.swagWidth * noteData);
			default: x += ((width - Note.lessX[PlayState.mania]) * noteData);
		}

		x += Note.xtra[PlayState.mania];
	
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
		x -= Note.posRest[PlayState.mania];
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if(animation.curAnim != null){ //my bad i was upset
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			colorSwap.hue = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][0] / 360;
			colorSwap.saturation = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][1] / 100;
			colorSwap.brightness = ClientPrefs.arrowHSV[Std.int(Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[noteData] % Note.ammo[PlayState.mania])][2] / 100;

			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}
}

/**
* Basic class for all `NoteSplash`s.
*/
class NoteSplash extends FlxSprite
{
	public var colorSwap:ColorSwap = null;
	private var idleAnim:String;
	private var textureLoaded:String = null;
	var isSustainSplash:Bool = false;

	var sc:Array<Float> = [1.3, 1.2, 1.1, 1, 1, 0.9, 0.8, 0.7, 0.6];

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skin:String = 'splashes/noteSplashes';
		if(PlayState.SONG.assets.splashSkin != null && PlayState.SONG.assets.splashSkin.length > 0) skin = PlayState.SONG.assets.splashSkin;

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		if (PlayState.isPixelStage) {
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * sc[PlayState.mania]));
			antialiasing = false;
			setPosition((x + 150) - Note.swagWidth * 0.95, (y + 150) - Note.swagWidth);
		} else {
			setGraphicSize(Std.int(width * sc[PlayState.mania]));
		}

		alpha = 0.6;

		/*switch(FlxG.random.int(0,3)) {
			case 0:
				angle = 0;
			case 1:
				angle = 90;
			case 2:
				angle = 180;
			case 3:
				angle = 270;
		}*/

		if(texture == null) {
			if (PlayState.isPixelStage) {
				texture = 'splashes/pixelSplashes';
			} else {
				texture = 'splashes/noteSplashes';
			}
			
			if(PlayState.SONG.assets.splashSkin != null && PlayState.SONG.assets.splashSkin.length > 0) texture = PlayState.SONG.assets.splashSkin;
		}

		if (texture != 'splashes/noteSplashes') {
			isSustainSplash = false;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}
		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		var offsets:Array<Int> = [Note.offsets[PlayState.mania][0], Note.offsets[PlayState.mania][1]];

		offset.set(offsets[0], offsets[1]);

		var animNum:Int = FlxG.random.int(1, 2);
		var fps:Int = 24;
		if (PlayState.isPixelStage) {
			animNum = 1;
			fps = 34;
		}
		/*if (animNum == 3) {
			x += 15;
			y += 5;
		}*/
		animation.play('note' + Note.keysShit.get(PlayState.mania).get('pixelAnimIndex')[note] + '-' + animNum, true, false);
		if(animation.curAnim != null)animation.curAnim.frameRate = fps + FlxG.random.int(-2, 2);
	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		for (i in 1...3/*4*/) {
			animation.addByPrefix('note0-' + i, 'note splash A ' + i, 24, false);
			animation.addByPrefix('note1-' + i, 'note splash B ' + i, 24, false);
			animation.addByPrefix('note2-' + i, 'note splash C ' + i, 24, false);
			animation.addByPrefix('note3-' + i, 'note splash D ' + i, 24, false);
			animation.addByPrefix('note4-' + i, 'note splash E ' + i, 24, false);
			animation.addByPrefix('note5-' + i, 'note splash F ' + i, 24, false);
			animation.addByPrefix('note6-' + i, 'note splash G ' + i, 24, false);
			animation.addByPrefix('note7-' + i, 'note splash H ' + i, 24, false);
			animation.addByPrefix('note8-' + i, 'note splash I ' + i, 24, false);
		}
	}

	override function update(elapsed:Float) {
		if(animation.curAnim != null)
		{
			if(animation.curAnim.finished)
			{
				if (isSustainSplash) {
					if (!PlayState.isPixelStage) {
						animation.play(animation.curAnim.name, true, true);
						animation.curAnim.frameRate = 48;
					} else {
						kill();
					}
				} else {
					kill();
				}
			}
			if(animation.curAnim.curFrame == 0 && animation.curAnim.reversed)
			{
				kill();
			}
		}

		super.update(elapsed);
	}
}
