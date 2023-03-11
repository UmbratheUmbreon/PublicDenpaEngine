package;

import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

/**
* Class used to create and control `DialogueBox`s for Week 6 style dialogue.
*/
class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';
	var endEvent:Bool = false;

	var dialogue:Alphabet;
	var dialogueList:Array<String> = [];

	public var swagDialogue:FlxTypeText;
	var dialogSound:String = 'pixelText'; //only changes for dad, bf will always stick to his sound

	public var finishThing:Void->Void = null;
	public var onFinishText:Void->Void = null;
	public var nextDialogueThing:Void->Void = null;
	public var skipDialogueThing:Void->Void = null;
	public var enterFinishCallback:Void->Void = null;

	public var portraitLeft:DialoguePortrait = null;
	public var portraitRight:DialoguePortrait = null;
	var face:DialoguePortrait = null;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;
	var bgLight:FlxSprite;
	var alphaTween:FlxTween = null;
	var targetFade:Float = 0.7;

	public var curDialogue:Int = -1;
	var senpaiColors:Array<FlxColor> = [];
	private var isThorns:Bool = false;
	var skipable:Bool = true;
	public var canControl:Bool = true;

	public function new(?dialogueList:Array<String>, endEvent:Bool = false, canSkip:Bool = true)
	{
		super();

		skipable = canSkip;
		final songName:String = PlayState.SONG.header.song.toLowerCase();

		if (PlayState.instance.canIUseTheCutsceneMother(true) && dialogueList != null) {
			if(songName != 'roses') {
				isThorns = songName == 'thorns';

				FlxG.sound.playMusic(Paths.music('vanilla/week6/Lunchbox${isThorns ? 'Scary' : ''}'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			}
		}
		else 
			return; //Literally no need to load anything if the dialogue shouldnt be played (done because dialogue is automatically loaded)

		this.endEvent = endEvent;

		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		if(isThorns) {
			bgLight = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFFFFFFF);
			bgLight.scrollFactor.set();
			bgLight.alpha = 0;
			add(bgLight);
		}

		box = new FlxSprite(-20, 45);
		box.antialiasing = false;
		
		final songBoxShit:String = (endEvent && songName == 'roses') ? 'senpai' : songName; //make sure we get the senpai box on the end of roses
		switch (songBoxShit)
		{
			case 'senpai': //And Roses End-scene
				senpaiColors = [0xFF3F2021, 0xFFD89494];

				box.frames = Paths.getSparrowAtlas('vanilla/week6/weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear instance 1', [4], "", 24);
			case 'roses':
				senpaiColors = [0xFF420B0F, 0xFFBB3B40];

				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
				Paths.sound('vanilla/week6/pixelText'); //avoid loading bug
				dialogSound = 'ANGRY';

				box.frames = Paths.getSparrowAtlas('vanilla/week6/weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH instance ', [4], "", 24);

			case 'thorns':
				senpaiColors = [FlxColor.WHITE, FlxColor.BLACK];

				bgFade.color = 0xFF140404;
				bgFade.alpha = 1;

				box.frames = Paths.getSparrowAtlas('vanilla/week6/weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn instance ', [11], "", 24);

				face = new DialoguePortrait(320, 230, 'spirit', 'Hidden', true);
				face.scale.scale(6,6);
				add(face);

				function tweenFace() {
					moveTween = FlxTween.tween(face, {y: face.y + moveVal}, 2.75, {
						ease: FlxEase.sineInOut,
						onComplete: function(_:FlxTween) {
							moveVal /= -1; //turn around the value automatically
							tweenFace();
						}
					});
				}

				tweenFace();

				var targetAlpha:Float = 0.225;

				function tweenBG() {
					alphaTween = FlxTween.tween(bgLight, {alpha: targetAlpha}, 2.75, {
						ease: FlxEase.sineInOut,
						onComplete: function(_:FlxTween) {
							targetAlpha = 0.225 - targetAlpha; 
							tweenBG();
						}
					});
				}

				tweenBG();
		}

		this.dialogueList = dialogueList;
		
		portraitLeft = new DialoguePortrait(140, 150, 'senpai', 'Normal');
		add(portraitLeft);
		portraitLeft.visible = false;

		portraitRight = new DialoguePortrait(805, 205, 'bf', 'Normal');
		add(portraitRight);
		portraitRight.visible = false;

		box.animation.play('normalOpen');
		box.animation.finishCallback = function(name:String) { //why didnt they do this before lmao???
			if(name == 'normalOpen') {
				box.animation.play('normal');
				startDialogue();
				dialogueStarted = true;
			}
		}
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		add(box);

		box.screenCenter(X);

		handSelect = new FlxSprite(1042, 590).loadGraphic(Paths.image('vanilla/week6/weeb/pixelUI/hand_textbox'));
		handSelect.setGraphicSize(Std.int(handSelect.width * PlayState.daPixelZoom * 0.9));
		handSelect.updateHitbox();
		handSelect.visible = false;
		add(handSelect);
		handSelect.antialiasing = false;

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = 'Pixel Arial 11 Bold';
		swagDialogue.color = senpaiColors[0];
		swagDialogue.borderStyle = SHADOW;
		swagDialogue.shadowOffset = FlxPoint.get(2, 2);
		swagDialogue.borderColor = senpaiColors[1];
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('vanilla/week6/$dialogSound'), 0.6)];
		add(swagDialogue);

		dialogue = new Alphabet(0, 80, "", false, true);
	}

	var dialogueStarted:Bool = false;
	public var dialogueEnded:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!canControl) return;

		if(PlayerSettings.player1.controls.ACCEPT)
		{
			if (dialogueEnded)
			{
				remove(dialogue);
				if (dialogueList[1] == null && dialogueList[0] != null)
				{
					if (!isEnding)
					{
						isEnding = true;
						FlxG.sound.play(Paths.sound('clickText'), 0.8);	

						if (PlayState.SONG.header.song.toLowerCase() == 'senpai' || isThorns)
							FlxG.sound.music.fadeOut(1.5, 0);

						final oldAlpha:Float = isThorns ? bgLight.alpha : 0;
						if(alphaTween != null) { alphaTween.cancel(); alphaTween = null; }

						new FlxTimer().start(0.2, function(tmr:FlxTimer)
						{
							box.alpha -= 1 / 5;
							if(!endEvent) bgFade.alpha -= 1 / 5 * targetFade;
							portraitLeft.visible = false;
							portraitRight.visible = false;
							swagDialogue.alpha -= 1 / 5;
							handSelect.alpha -= 1 / 5;
							if(isThorns) {
								PlayState.instance.dad.x += 600 / 5;
								PlayState.instance.dad.alpha += 1 / 5;
								face.x -= 24;
								face.x += 6;
								face.alpha -= 1 / 5;
								bgLight.alpha -= 1 / 5 * oldAlpha;
							}
						}, 5);

						new FlxTimer().start(1.5, function(tmr:FlxTimer)
						{
							if(finishThing != null) finishThing();

							if(moveTween != null) { moveTween.cancel(); moveTween = null; }
							if(shakeTween != null) { shakeTween.cancel(); shakeTween = null; }
							if(onDialogueUpdate != null) onDialogueUpdate = null;
							kill();
						});
					}
				}
				else
				{
					dialogueList.remove(dialogueList[0]);
					startDialogue();
					FlxG.sound.play(Paths.sound('clickText'), 0.8);
				}
			}
			else if (dialogueStarted && skipable)
			{
				if(pauseTimer != null) pauseTimer.cancel();
				swagDialogue.paused = false;

				FlxG.sound.play(Paths.sound('clickText'), 0.8);
				swagDialogue.skip();
				
				if(skipDialogueThing != null) {
					skipDialogueThing();
				}
			}
		}
	}

	var pauseTimer:FlxTimer = null;
	private function pauseText(time:Float, ?onComplete:Void -> Void = null) {
		swagDialogue.paused = true;
		
		pauseTimer = new FlxTimer().start(time, function(_:FlxTimer) {
			swagDialogue.paused = false;
			pauseTimer = null;

			if(onComplete != null) onComplete();
		});
	}

	public var onDialogueUpdate(default, set):String -> Void = null;
	function set_onDialogueUpdate(func:String -> Void):String -> Void {
		onDialogueUpdate = func;

		@:privateAccess 
			swagDialogue.onUpdateText = onDialogueUpdate;
		
		return onDialogueUpdate;
	}

	var isEnding:Bool = false;
	var shakeTween:FlxTween = null;
	var moveTween:FlxTween = null;
	var moveVal:Float = 40;
	var handTimer:FlxTimer = null;
	var moveHandDirection:Bool = false;

	function resetHandThing(start:Bool = true) {
		handSelect.x = 1042;
		moveHandDirection = false;
		if (handTimer != null) {
			handTimer.cancel();
		}
		if (start) {
			handTimer = new FlxTimer().start(0.4, tmr -> {
				handSelect.x += (moveHandDirection ? -12 : 12);
				moveHandDirection = !moveHandDirection;
				tmr.reset(0.4);
			});
		}
	}

	function startDialogue():Void
	{
		cleanDialog();
		if(curDialogue == -1 && !isThorns && !endEvent) {
			new FlxTimer().start(0.2, function(tmr:FlxTimer)
				{
					bgFade.alpha += (1 / 5) * targetFade;
					if (bgFade.alpha > targetFade)
						bgFade.alpha = targetFade;
				}, 5);
		}

		curDialogue++;
		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);
		swagDialogue.completeCallback = function() {
			if(canControl) {
				resetHandThing();
				handSelect.visible = true;
			}
			dialogueEnded = true;

			if(onFinishText != null) onFinishText();
		};

		handSelect.visible = false;
		resetHandThing(false);
		dialogueEnded = false;

		switch (curCharacter)
		{
			case 'dad':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('vanilla/week6/$dialogSound'), 0.7)];

				swagDialogue.color = senpaiColors[0];
				swagDialogue.borderColor = senpaiColors[1];
				portraitRight.visible = false;
				switch(PlayState.SONG.header.song.toLowerCase()) {
					case 'senpai':
						if (!portraitLeft.visible)
						{
							portraitLeft.visible = true;
							enter(portraitLeft);
						}

						switch (curDialogue) {
							case 1:
								portraitLeft.changeExpression('Smug');
								portraitRight.changeExpression('Heh');
								if (!portraitRight.visible)
								{
									portraitRight.visible = true;
									enter(portraitRight, false);
								}
						}
					case 'roses':
						//senpai piss senpai pissed
						if (!portraitLeft.visible)
						{
							portraitLeft.visible = true;
							portraitLeft.changeExpression('Distraught');
							portraitLeft.x += 90;
							enterFinishCallback = function() {
								portraitLeft.changeExpression('Angry');
								enterFinishCallback = null;
							}
							enter(portraitLeft);
						}

						switch (curDialogue) {
							case 1:
								portraitLeft.changeExpression('Aggro');
								if (!portraitRight.visible)
								{
									portraitRight.visible = true;
									enter(portraitRight, false);
								}
								onDialogueUpdate = function(dialog:String) {
									if(swagDialogue.paused) return;
									
									//have to do stupid conditionals since the switch wont work
									//sorry :(
									if (dialog.endsWith('gargling')) {
										swagDialogue.delay = 0.04;
										portraitRight.changeExpression('Heh');
									}
									if (dialog.endsWith('finishes ')) {
										swagDialogue.delay = 0.15;
									}
									if (dialog.endsWith('nuts')) {
										swagDialogue.delay = 0.04;
									}
									if (dialog.endsWith('rip your ')) {
										swagDialogue.delay = 0.15;
										portraitRight.changeExpression('Shock');
									}
								};
						}
					case 'thorns':
						portraitLeft.visible = false;

						switch(curDialogue) {
							case 1: //and HER of all people..
								onDialogueUpdate = function(dialog:String) {
									if(swagDialogue.paused) return;
									
									switch(dialog) {
										case "and ": 
											swagDialogue.delay = 0.2;
											new FlxTimer().start(0.1, function(_:FlxTimer) {
												FlxG.sound.play(Paths.sound('vanilla/week6/ANGRY'), 0.6);
												shakeTween = FlxTween.shake(face, 0.08, 0.2, flixel.util.FlxAxes.XY, {onComplete: function(_:FlxTween) { shakeTween = null; }});
											});
										case "and HER ": swagDialogue.delay = 0.04; bgLight.color = FlxColor.WHITE;
									}
								};
							case 3: //I'll beat you and make you take my place.
								pauseText (0.175, function() {
									shakeTween = FlxTween.shake(face, 0.11, 1, flixel.util.FlxAxes.X, { type: LOOPING });
								});
								face.changeExpression('Normal');
								FlxG.sound.play(Paths.sound('vanilla/week6/ANGRY2'), 1);
								shakeTween = FlxTween.shake(face, 0.135, 0.175, flixel.util.FlxAxes.XY);

								swagDialogue.color = senpaiColors[0] = bgLight.color = 0xFFB40B13;
								swagDialogue.borderColor = senpaiColors[1] = 0xFFF5202B;

								swagDialogue.delay = 0.065;
							case 4: 
								swagDialogue.delay = 0.05; //You dont mind your bodies being borrowed right? Its only fair,,,
								face.changeExpression('Mouth');
						}
				}
			case 'bf':
				swagDialogue.sounds = [FlxG.sound.load(Paths.sound('vanilla/week6/bfText'), 0.6)];

				swagDialogue.color = 0xFF20223F;
				swagDialogue.borderColor = 0xFF94AFD8;
				
				//portraitLeft.visible = false;
				switch (PlayState.SONG.header.song.toLowerCase()) {
					case 'senpai':
						portraitLeft.changeExpression('Smile');
						portraitRight.changeExpression('Normal');
					case 'roses':
						portraitLeft.changeExpression('Pissed');
						portraitRight.changeExpression('Smug');
				}
				if (!portraitRight.visible)
				{
					portraitRight.visible = true;
					enter(portraitRight, false);
				}
		}

		if(nextDialogueThing != null) nextDialogueThing();
	}

	//Replaces the enter animation with manual stuff, using timer to give it pixely-effect like the animation used to
	function enter(portrait:FlxSprite, dad:Bool = true) {
		portrait.alpha = 0;
		portrait.x += dad ? -20 : 20;

		var loops:Int = 0;
		new FlxTimer().start(0.05, function(_){
			portrait.x += dad ? 5 : - 5;
			portrait.alpha += 0.25;
			if (loops == 3) {
				if(enterFinishCallback != null) enterFinishCallback();
			}
			loops++;
		}, 4);
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(":");
		curCharacter = splitName[1];
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
	}

	/*inline private function shouldPause(pauseChars:Array<String> = []):Bool { //scrapped ro now but could be useful
	if (pauseChars.length == 0) pauseChars = [',','?','.'];

	for(char in pauseChars) { if(swagDialogue.text.endsWith(char)) return true; }
	return false;
	}*/
}

class DialoguePortrait extends FlxSprite {
	public var character:String;
	public function new(x:Float, y:Float, _character:String, expression:String, skipSizing:Bool = false) {
		super(x,y);
		this.character = _character;
		loadGraphic(Paths.image('vanilla/week6/weeb/portraits/$_character$expression'));
		antialiasing = false;
		if (!skipSizing) {
			setGraphicSize(Std.int(width * PlayState.daPixelZoom * 0.9));
			updateHitbox();
		}
		scrollFactor.set();
	}

	public function changeExpression(expression:String)
		loadGraphic(Paths.image('vanilla/week6/weeb/portraits/$character$expression'));
}
