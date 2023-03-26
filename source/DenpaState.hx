package;

import flash.system.System;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.text.FlxTypeText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.events.KeyboardEvent;
#if desktop
import editors.*;
#end

/**
* Class used to create the splash screen on startup.
* The splash screen is chosen from a random pool of premade splashes.
*/
class DenpaState extends MusicBeatState
{

	var logo:FlxSprite;
	var jonScare:FlxSprite;
	var skipTxt:FlxText;

	var chooseYerIntroMate:Int = FlxG.random.int(0,9);

	override public function create():Void
	{
		#if desktop
		Application.current.window.focus();
		#end

		CoolUtil.precacheSound('denpa', 'splash');
		if (chooseYerIntroMate == 9) {
			CoolUtil.precacheSound('dennad', 'splash');
		}

		if (FlxG.random.bool(1)) {
			chooseYerIntroMate = 9999;
			CoolUtil.precacheSound('explosion', 'splash');
		} 

		#if desktop
		if (FlxG.random.bool(0.01)) {
			chooseYerIntroMate = 666;
			CoolUtil.precacheSound('JON_JUIMPSCARE', 'splash');
			CoolUtil.precacheSound('undertale-game-over', 'splash');
			CoolUtil.precacheSound('wasted', 'splash');
			CoolUtil.precacheSound('soulbreak', 'splash');
			CoolUtil.precacheSound('ourple', 'splash');
		} 
		#end

		logo = new FlxSprite().loadGraphic(Paths.image('logo', 'splash', false));
		logo.scrollFactor.set();
		logo.screenCenter();
		logo.alpha = 0;
		logo.active = false;
		add(logo);

		skipTxt = new FlxText(12, FlxG.height - 24, 0, 'Press ENTER to Skip');
		skipTxt.scrollFactor.set();
		skipTxt.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.NONE, FlxColor.BLACK);
		skipTxt.active = false;
		skipTxt.alpha = 0.33;
		FlxTween.tween(skipTxt, {alpha: 0}, 0.5, {
			startDelay: 0.2,
			ease: FlxEase.quadInOut,
			onComplete: _ -> {
				remove(skipTxt, true);
				skipTxt.destroy();
			}
		});
		add(skipTxt);

		new FlxTimer().start(0.01, function(tmr:FlxTimer)
			{
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				switch (chooseYerIntroMate){
					case 0:
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxTween.tween(logo, {alpha: 0}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					case 1:
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						logo.scale.set(0.1,0.1);
						logo.updateHitbox();
						logo.screenCenter();
						FlxTween.tween(logo, {alpha: 1, "scale.x": 1, "scale.y": 1,}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								logo.updateHitbox();
								logo.screenCenter();
								FlxTween.tween(logo, {alpha: 0, "scale.x": 8, "scale.y": 8}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					case 9999:
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxG.sound.pause();
								FlxG.sound.play(Paths.sound('explosion', 'splash'));
								for (i in 0...5) {
									var kaboom:FlxSprite = new FlxSprite();
									kaboom.frames = Paths.getSparrowAtlas('explosion', 'splash');
									kaboom.animation.addByPrefix('boom', 'kaboom', 16, false);
									kaboom.animation.play('boom');
									kaboom.scrollFactor.set();
									kaboom.antialiasing = false;
									kaboom.screenCenter();
									kaboom.x = logo.x + (FlxG.random.int(75,150) * i);
									kaboom.y = logo.y + (FlxG.random.int(50,300));
									add(kaboom);
									FlxTween.tween(kaboom, {alpha: 0}, 1, {
										ease: FlxEase.quadOut,
										onComplete: _ -> {
											remove(kaboom, true);
											kaboom.destroy();
										}
									});
								}
								FlxTween.tween(logo, {y: logo.y - 250}, 0.2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> {
										FlxTween.tween(logo, {y: 15000, x: logo.x + 500}, 1.8, {onComplete: _ -> goToTitle()});
									}
								});
							}
						});
					case 2:
						for (i in 0...80) {
							var logoPiece:FlxSprite = new FlxSprite().loadGraphic(Paths.image('loader/' + 'row-' + (i+1) + '-column-1', 'splash', false));
							logoPiece.scrollFactor.set();
							logoPiece.screenCenter();
							logoPiece.alpha = 0;
							logoPiece.y = logo.y + 6*i;
							logoPiece.x = logo.x + 1*i + FlxG.random.int(-100,100);
							logoPiece.active = false;
							add(logoPiece);
							FlxTween.tween(logoPiece, {alpha: 1, x: logo.x}, 0.01 + i/34, {ease: FlxEase.quadInOut});
						}
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						new FlxTimer().start(2, _ -> goToTitle());
					case 3:
						logo.x = -1000;
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1, x: FlxG.width/2 - 691/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxTween.tween(logo, {alpha: 0, x: FlxG.width + 1000}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					case 4:
						logo.y = -500;
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1, y: FlxG.height/2 - 476/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxTween.tween(logo, {alpha: 0, y: FlxG.height + 500}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					#if desktop
					case 666:
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxG.sound.pause();
								FlxG.sound.play(Paths.sound('JON_JUIMPSCARE', 'splash'));
								jonScare = new FlxSprite().loadGraphic(Paths.image('JONJUMPSCARE', 'splash', false));
								jonScare.scrollFactor.set();
								jonScare.screenCenter();
								add(jonScare);
								remove(logo, true);
								logo.destroy();
								new FlxTimer().start(2.66, _ ->
								{
									var random:Bool = FlxG.random.bool(10);
									if (!random) {
										var gameOver:FlxSprite = new FlxSprite().loadGraphic(Paths.image('fnaf1dead', 'splash', false));
										gameOver.scrollFactor.set();
										gameOver.screenCenter();
										add(gameOver);
										remove(jonScare, true);
										jonScare.destroy();
										FlxG.sound.pause();
										new FlxTimer().start(3, _ -> System.exit(0));
									} else {
										var randomInt:Int = FlxG.random.int(0,2);
										switch (randomInt) {
											case 0:
												FlxG.sound.pause();
												remove(jonScare, true);
												jonScare.destroy();
												var soul:FlxSprite = new FlxSprite().loadGraphic(Paths.image('soul', 'splash', false));
												soul.scrollFactor.set();
												soul.scale.set(3,3);
												soul.updateHitbox();
												soul.screenCenter();
												soul.antialiasing = false;
												soul.y += 150;
												add(soul);
												new FlxTimer().start(1, _ ->
												{
													FlxG.sound.play(Paths.sound('soulbreak', 'splash'));
													remove(soul, true);
													soul.destroy();
													var brokenSoul:FlxSprite = new FlxSprite().loadGraphic(Paths.image('brokensoul', 'splash', false));
													brokenSoul.scrollFactor.set();
													brokenSoul.scale.set(3,3);
													brokenSoul.updateHitbox();
													brokenSoul.screenCenter();
													brokenSoul.antialiasing = false;
													brokenSoul.y += 150;
													add(brokenSoul);
													new FlxTimer().start(1.3, _ ->
													{
														remove(brokenSoul, true);
														brokenSoul.destroy();
														var velY = 755;
														var velX = 455;
														var durs:Array<Float> = [0.1, 1];
														for (i in 0...6) {
															if (i == 3) {
																velY = 255;
																velX = 55;
																durs = [0.3, 1.3];
															}
															var soulShard:FlxSprite = new FlxSprite().loadGraphic(Paths.image('shard' + Math.min(4, Math.max(i+1 % 5, 1)), 'splash', false));
															soulShard.scrollFactor.set();
															soulShard.scale.set(3,3);
															soulShard.updateHitbox();
															soulShard.screenCenter();
															soulShard.antialiasing = false;
															soulShard.y += 150;
															soulShard.velocity.x = FlxG.random.int(-velX, velX);
															soulShard.velocity.y = FlxG.random.int(55, velY);
															FlxTween.tween(soulShard, {alpha: 0}, FlxG.random.float(durs[0], durs[1]), {
																ease: FlxEase.quadInOut,
																onComplete: _ -> {
																	remove(soulShard, true);
																	soulShard.destroy();
																}
															});
															add(soulShard);
														}
														new FlxTimer().start(1.6, _ ->
														{
															FlxG.sound.play(Paths.sound('undertale-game-over', 'splash'));
															var gameOver:FlxSprite = new FlxSprite().loadGraphic(Paths.image('undertaledead', 'splash', false));
															gameOver.scrollFactor.set();
															gameOver.screenCenter();
															gameOver.antialiasing = false;
															gameOver.y -= 200;
															gameOver.alpha = 0;
															add(gameOver);
															FlxTween.tween(gameOver, {alpha: 1}, 0.95, {ease: FlxEase.quadInOut});
															new FlxTimer().start(2.76, function(tmr:FlxTimer)
															{
																var text = new FlxTypeText(0, 0, 0, "DONT GIVE UP");
																text.scrollFactor.set();
																text.setFormat(Paths.font("determination.otf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
																text.screenCenter();
																text.y = gameOver.y + 350;
																text.cursorBlinkSpeed = 0;
																text.antialiasing = false;
																text.x -= 220/2;
																add(text);
																text.start(0.06);
																new FlxTimer().start(1, function(tmr:FlxTimer)
																{
																	var text = new FlxTypeText(0, 0, 0, "STAY DETERMINED");
																	text.scrollFactor.set();
																	text.setFormat(Paths.font("determination.otf"), 36, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
																	text.screenCenter();
																	text.y = gameOver.y + 400;
																	text.cursorBlinkSpeed = 0;
																	text.antialiasing = false;
																	text.x -= 274/2;
																	add(text);
																	text.start(0.06);
																});
															});
															new FlxTimer().start(8.4, _ -> System.exit(0));
														});
													});
												});
											case 1:
												FlxG.sound.pause();
												FlxG.sound.play(Paths.sound('wasted', 'splash'));
												var wasted:FlxSprite = new FlxSprite().loadGraphic(Paths.image('wasted', 'splash', false));
												wasted.scrollFactor.set();
												wasted.screenCenter();
												wasted.alpha = 0;
												add(wasted);
												remove(jonScare, true);
												jonScare.destroy();
												FlxTween.tween(wasted, {alpha: 1}, 0.3, {ease: FlxEase.quadInOut});
												new FlxTimer().start(6, _ -> System.exit(0));
											case 2:
												FlxG.sound.pause();
												FlxG.sound.play(Paths.sound('ourple', 'splash'));
												var ourple:FlxBackdrop = new FlxBackdrop(Paths.image('ourple', 'splash'), XY, 0, 0);
												ourple.frames = Paths.getSparrowAtlas('ourple', 'splash');
												ourple.animation.addByPrefix('dance', 'dance', 24, true);
												ourple.animation.play('dance');
												ourple.scrollFactor.set();
												ourple.acceleration.set(700, 700);
												new FlxTimer().start(0.5, tmr -> {
													ourple.acceleration.y *= -1.2;
													tmr.reset(0.5);
												});
												add(ourple);
												remove(jonScare, true);
												jonScare.destroy();
												new FlxTimer().start(9, _ -> System.exit(0));
										}
									}
								});
							}
						});
					#end
					case 5:
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						logo.scale.set(8,8);
						logo.updateHitbox();
						logo.screenCenter();
						FlxTween.tween(logo, {alpha: 1, "scale.x": 1, "scale.y": 1,}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								logo.updateHitbox();
								logo.screenCenter();
								FlxTween.tween(logo, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					case 6:
						logo.x = 1000;
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1, x: FlxG.width/2 - 691/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxTween.tween(logo, {alpha: 0, x: FlxG.width - 1000}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					case 7:
						logo.y = 500;
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1, y: FlxG.height/2 - 476/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxTween.tween(logo, {alpha: 0, y: FlxG.height - 500}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					case 8:
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1, angle: -12}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxTween.tween(logo, {alpha: 0, angle: 12}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					case 9:
						FlxG.sound.play(Paths.sound('dennad', 'splash'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								var circle:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bigCircle', 'splash', false));
								circle.blend = openfl.display.BlendMode.INVERT;
								circle.scrollFactor.set();
								circle.scale.set(0.001,0.001);
								circle.updateHitbox();
								circle.screenCenter();
								circle.alpha = 0;
								add(circle);
								FlxTween.tween(circle, {alpha: 1, "scale.x": 1.3, "scale.y": 1.3}, 0.95, {
									ease: FlxEase.expoOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
					default:
						FlxG.sound.play(Paths.sound('denpa', 'splash'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: _ -> {
								FlxTween.tween(logo, {alpha: 0}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: _ -> goToTitle()
								});
							}
						});
				}
			});

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (jonScare != null) {
			jonScare.x = FlxG.random.int(-10, 10);
		}

		super.update(elapsed);
	}

	function goToTitle() {
		//negates the need for stupid lib swapping
		LoadingState.silentLoading = true;
		LoadingState.globeTrans = false;
		LoadingState.loadAndSwitchState(new TitleState());
	}

	public override function keyPress(event:KeyboardEvent):Void
	{
		super.keyPress(event);
		var eventKey:FlxKey = event.keyCode;

		#if !debug
		if (eventKey == FlxKey.ENTER)
		#end
		switch (eventKey) {
			case FlxKey.ENTER:
				goToTitle();
			#if debug
			case FlxKey.SHIFT:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				MusicBeatState.switchState(new MainMenuState());
			case FlxKey.S:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				MusicBeatState.switchState(new StoryMenuState());
			case FlxKey.F:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				MusicBeatState.switchState(new FreeplayState());
			case FlxKey.C:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				MusicBeatState.switchState(new CreditsState());
			case FlxKey.O:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				LoadingState.loadAndSwitchState(new options.OptionsState());
			case FlxKey.U:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				MusicBeatState.switchState(new OutdatedState());
			case FlxKey.P:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				MusicBeatState.switchState(new PatchState());
			#if desktop
			case FlxKey.M:
				if(FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
	
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
				Conductor.changeBPM(100);
				MusicBeatState.switchState(new MasterEditorMenu());
			case FlxKey.EIGHT:
				LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
			case FlxKey.SEVEN:
				LoadingState.loadAndSwitchState(new ChartingState(), false);
			case FlxKey.ESCAPE:
				System.exit(0);
			#end
			#end
			default:
				//do NOTHING
		}
	}
}
