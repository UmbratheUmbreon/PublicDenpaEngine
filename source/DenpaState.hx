package;

import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
//import FlxTransWindow;

#if desktop
import editors.MasterEditorMenu;
import editors.CharacterEditorState;
import editors.ChartingState;
#end

import flash.system.System;

using StringTools;

/**
* Class used to create the splash screen on startup.
* The splash screen is chosen from a random pool of premade splashes.
*/
class DenpaState extends MusicBeatState
{

	var logo:FlxSprite;
	var jonScare:FlxSprite;

	public static var errorFixer:Bool = false;

	var chooseYerIntroMate:Int = FlxG.random.int(0,9);

	override public function create():Void
	{
		Paths.clearUnusedMemory();
		//var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(1, 1, 1));
		//bg.scrollFactor.set();
		//add(bg);
		//FlxTransWindow.getWindowsTransparent();
		Application.current.window.title = "FNFSPLASH";
		#if desktop
		Application.current.window.focus();
		#end
		var directory:String = 'splash';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
		CoolUtil.precacheSound('denpa');
		if (chooseYerIntroMate == 9) {
			CoolUtil.precacheSound('dennad');
		}

		if (FlxG.random.bool(1)) {
			chooseYerIntroMate = 9999;
			CoolUtil.precacheSound('explosion');
		} 

		#if desktop
		if (FlxG.random.bool(0.01)) { //0.01
			chooseYerIntroMate = 666;
			CoolUtil.precacheSound('JON_JUIMPSCARE');
			CoolUtil.precacheSound('undertale-game-over');
			CoolUtil.precacheSound('wasted');
			CoolUtil.precacheSound('soulbreak');
			CoolUtil.precacheSound('ourple');
		} 
		#end

		logo = new FlxSprite().loadGraphic(Paths.image('logo'));
		logo.scrollFactor.set();
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		logo.alpha = 0;
		add(logo);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);

		new FlxTimer().start(0.01, function(tmr:FlxTimer)
			{
				errorFixer = true;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				switch (chooseYerIntroMate){
					case 0:
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxTween.tween(logo, {alpha: 0}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					case 1:
						FlxG.sound.play(Paths.sound('denpa'));
						logo.scale.set(0.1,0.1);
						logo.updateHitbox();
						logo.screenCenter();
						FlxTween.tween(logo, {alpha: 1, "scale.x": 1, "scale.y": 1,}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								logo.updateHitbox();
								logo.screenCenter();
								FlxTween.tween(logo, {alpha: 0, "scale.x": 8, "scale.y": 8}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					case 9999:
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxG.sound.pause();
								FlxG.sound.play(Paths.sound('explosion'));
								for (i in 0...5) {
									var kaboom:FlxSprite = new FlxSprite();
									kaboom.frames = Paths.getSparrowAtlas('explosion');
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
										onComplete: function(twn:FlxTween) {
											kaboom.kill();
											kaboom.destroy();
										}
									});
								}
								FlxTween.tween(logo, {y: logo.y - 250}, 0.2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										FlxTween.tween(logo, {y: 15000, x: logo.x + 500}, 1.8, {
											onComplete: function(twnFlxTween) {
												goToTitle();
											}
										});
									}
								});
							}
						});
					case 2:
						//logo.kill();
						//logo.destroy();
						for (i in 0...80) {
							var logoPiece:FlxSprite = new FlxSprite().loadGraphic(Paths.image('loader/' + 'row-' + (i+1) + '-column-1'));
							logoPiece.scrollFactor.set();
							logoPiece.screenCenter();
							logoPiece.antialiasing = ClientPrefs.globalAntialiasing;
							logoPiece.alpha = 0;
							logoPiece.y = logo.y + 6*i;
							logoPiece.x = logo.x + 1*i + FlxG.random.int(-100,100);
							add(logoPiece);
							FlxTween.tween(logoPiece, {alpha: 1, x: logo.x}, 0.01 + i/34, {
								ease: FlxEase.quadInOut
							});
						}
						FlxG.sound.play(Paths.sound('denpa'));
						new FlxTimer().start(2, function(tmr:FlxTimer)
							{
								goToTitle();
							});
					case 3:
						logo.x = -1000;
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1, x: FlxG.width/2 - 691/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxTween.tween(logo, {alpha: 0, x: FlxG.width + 1000}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					case 4:
						logo.y = -500;
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1, y: FlxG.height/2 - 476/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxTween.tween(logo, {alpha: 0, y: FlxG.height + 500}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					#if desktop
					case 666:
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxG.sound.pause();
								FlxG.sound.play(Paths.sound('JON_JUIMPSCARE'));
								jonScare = new FlxSprite().loadGraphic(Paths.image('JONJUMPSCARE'));
								jonScare.scrollFactor.set();
								jonScare.screenCenter();
								jonScare.antialiasing = ClientPrefs.globalAntialiasing;
								add(jonScare);
								FlxG.fullscreen = true;
								logo.kill();
								logo.destroy();
								new FlxTimer().start(2.66, function(tmr:FlxTimer)
									{
										FlxG.fullscreen = false;
										var random:Bool = FlxG.random.bool(10); //10
										if (!random) {
											var gameOver:FlxSprite = new FlxSprite().loadGraphic(Paths.image('fnaf1dead'));
											gameOver.scrollFactor.set();
											gameOver.screenCenter();
											gameOver.antialiasing = ClientPrefs.globalAntialiasing;
											add(gameOver);
											jonScare.kill();
											jonScare.destroy();
											FlxG.sound.pause();
											new FlxTimer().start(3, function(tmr:FlxTimer)
												{
													System.exit(0);
												});
										} else {
											var randomInt:Int = FlxG.random.int(0,2);
											switch (randomInt) {
												case 0:
													FlxG.sound.pause();
													//logo.kill();
													//logo.destroy();
													jonScare.kill();
													jonScare.destroy();
													var soul:FlxSprite = new FlxSprite().loadGraphic(Paths.image('soul'));
													soul.scrollFactor.set();
													soul.scale.set(3,3);
													soul.updateHitbox();
													soul.screenCenter();
													soul.antialiasing = false;
													soul.y += 150;
													add(soul);
													new FlxTimer().start(1, function(tmr:FlxTimer){
														FlxG.sound.play(Paths.sound('soulbreak'));
														soul.kill();
														soul.destroy();
														var brokenSoul:FlxSprite = new FlxSprite().loadGraphic(Paths.image('brokensoul'));
														brokenSoul.scrollFactor.set();
														brokenSoul.scale.set(3,3);
														brokenSoul.updateHitbox();
														brokenSoul.screenCenter();
														brokenSoul.antialiasing = false;
														brokenSoul.y += 150;
														add(brokenSoul);
														new FlxTimer().start(1.3, function(tmr:FlxTimer)
															{
																brokenSoul.kill();
																brokenSoul.destroy();
																for (i in 0...3) {
																	var soulShard:FlxSprite = new FlxSprite().loadGraphic(Paths.image('shard' + (i+1)));
																	soulShard.scrollFactor.set();
																	soulShard.scale.set(3,3);
																	soulShard.updateHitbox();
																	soulShard.screenCenter();
																	soulShard.antialiasing = false;
																	soulShard.y += 150;
																	soulShard.velocity.x = FlxG.random.int(-455,455);
																	soulShard.velocity.y = FlxG.random.int(55,755);
																	FlxTween.tween(soulShard, {alpha: 0}, FlxG.random.float(0.1,1), {
																		ease: FlxEase.quadInOut
																	});
																	add(soulShard);
																}
																for (i in 0...3) {
																	var soulShard:FlxSprite = new FlxSprite().loadGraphic(Paths.image('shard' + (i+1)));
																	soulShard.scrollFactor.set();
																	soulShard.scale.set(3,3);
																	soulShard.updateHitbox();
																	soulShard.screenCenter();
																	soulShard.antialiasing = false;
																	soulShard.y += 150;
																	soulShard.velocity.x = FlxG.random.int(-55,55);
																	soulShard.velocity.y = FlxG.random.int(55,255);
																	FlxTween.tween(soulShard, {alpha: 0}, FlxG.random.float(0.3,1.3), {
																		ease: FlxEase.quadInOut
																	});
																	add(soulShard);
																}
																new FlxTimer().start(1.6, function(tmr:FlxTimer)
																	{
																		FlxG.sound.play(Paths.sound('undertale-game-over'));
																		var gameOver:FlxSprite = new FlxSprite().loadGraphic(Paths.image('undertaledead'));
																		gameOver.scrollFactor.set();
																		gameOver.screenCenter();
																		gameOver.antialiasing = false;
																		gameOver.y -= 200;
																		gameOver.alpha = 0;
																		add(gameOver);
																		FlxTween.tween(gameOver, {alpha: 1}, 0.95, {
																			ease: FlxEase.quadInOut
																		});
																		new FlxTimer().start(2.76, function(tmr:FlxTimer)
																			{
																				var text:FlxText = new FlxText(0, 0, 0, "DONT GIVE UP");
																				text.scrollFactor.set();
																				text.setFormat(Paths.font("determination.otf"), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
																				text.screenCenter();
																				text.y = gameOver.y + 350;
																				add(text);
																				new FlxTimer().start(1, function(tmr:FlxTimer)
																					{
																						var text:FlxText = new FlxText(0, 0, 0, "STAY DETERMINED");
																						text.scrollFactor.set();
																						text.setFormat(Paths.font("determination.otf"), 36, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
																						text.screenCenter();
																						text.y = gameOver.y + 400;
																						add(text);
																					});
																			});
																		new FlxTimer().start(8.4, function(tmr:FlxTimer)
																			{
																				System.exit(0);
																			});
																	});
															});
													});
												case 1:
													FlxG.sound.pause();
													FlxG.sound.play(Paths.sound('wasted'));
													var wasted:FlxSprite = new FlxSprite().loadGraphic(Paths.image('wasted'));
													wasted.scrollFactor.set();
													wasted.screenCenter();
													wasted.antialiasing = ClientPrefs.globalAntialiasing;
													wasted.alpha = 0;
													add(wasted);
													jonScare.kill();
													jonScare.destroy();
													FlxTween.tween(wasted, {alpha: 1}, 0.3, {
														ease: FlxEase.quadInOut
													});
													new FlxTimer().start(6, function(tmr:FlxTimer)
														{
															System.exit(0);
														});
												case 2:
													FlxG.sound.pause();
													FlxG.sound.play(Paths.sound('ourple'));
													for (i in 0...4) {
														var ourple:FlxSprite = new FlxSprite();
														ourple.frames = Paths.getSparrowAtlas('ourple');
														ourple.animation.addByPrefix('dance', 'dance', 24, true);
														ourple.animation.play('dance');
														ourple.scrollFactor.set();
														ourple.antialiasing = ClientPrefs.globalAntialiasing;
														ourple.screenCenter();
														ourple.x = -250 + (450*i);
														ourple.y = -200;
														add(ourple);
													}
													for (i in 0...4) {
														var ourple:FlxSprite = new FlxSprite();
														ourple.frames = Paths.getSparrowAtlas('ourple');
														ourple.animation.addByPrefix('dance', 'dance', 24, true);
														ourple.animation.play('dance');
														ourple.scrollFactor.set();
														ourple.antialiasing = ClientPrefs.globalAntialiasing;
														ourple.screenCenter();
														ourple.x = -250 + (450*i);
														ourple.y = 200;
														add(ourple);
													}
													for (i in 0...4) {
														var ourple:FlxSprite = new FlxSprite();
														ourple.frames = Paths.getSparrowAtlas('ourple');
														ourple.animation.addByPrefix('dance', 'dance', 24, true);
														ourple.animation.play('dance');
														ourple.scrollFactor.set();
														ourple.antialiasing = ClientPrefs.globalAntialiasing;
														ourple.screenCenter();
														ourple.x = -250 + (450*i);
														ourple.y = 600;
														add(ourple);
													}
													jonScare.kill();
													jonScare.destroy();
													new FlxTimer().start(9, function(tmr:FlxTimer)
														{
															System.exit(0);
														});
											}
										}
									});
							}
						});
					#end
					case 5:
						FlxG.sound.play(Paths.sound('denpa'));
						logo.scale.set(8,8);
						logo.updateHitbox();
						logo.screenCenter();
						FlxTween.tween(logo, {alpha: 1, "scale.x": 1, "scale.y": 1,}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								logo.updateHitbox();
								logo.screenCenter();
								FlxTween.tween(logo, {alpha: 0, "scale.x": 0.1, "scale.y": 0.1}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					case 6:
						logo.x = 1000;
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1, x: FlxG.width/2 - 691/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxTween.tween(logo, {alpha: 0, x: FlxG.width - 1000}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					case 7:
						logo.y = 500;
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1, y: FlxG.height/2 - 476/2}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxTween.tween(logo, {alpha: 0, y: FlxG.height - 500}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					case 8:
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1, angle: -12}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxTween.tween(logo, {alpha: 0, angle: 12}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					case 9:
						FlxG.sound.play(Paths.sound('dennad'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								var circle:FlxSprite = new FlxSprite().loadGraphic(Paths.image('bigCircle'));
								circle.blend = openfl.display.BlendMode.INVERT;
								circle.scrollFactor.set();
								circle.scale.set(0.001,0.001);
								circle.updateHitbox();
								circle.screenCenter();
								circle.antialiasing = ClientPrefs.globalAntialiasing;
								circle.alpha = 0;
								add(circle);
								FlxTween.tween(circle, {alpha: 1, "scale.x": 1.3, "scale.y": 1.3}, 0.95, {
									ease: FlxEase.expoOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
								});
							}
						});
					default:
						FlxG.sound.play(Paths.sound('denpa'));
						FlxTween.tween(logo, {alpha: 1}, 0.95, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								FlxTween.tween(logo, {alpha: 0}, 2, {
									ease: FlxEase.quadInOut,
									onComplete: function(twn:FlxTween) {
										goToTitle();
									}
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

	override function destroy() {
		//FlxTransWindow.getWindowsBackward();
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		super.destroy();
	}

	function goToTitle() {
		resetWindow();
		MusicBeatState.switchState(new TitleState());
	}

	function resetWindow() {
		#if desktop
		Application.current.window.borderless = false;
		#end
		Application.current.window.title = "Friday Night Funkin': Denpa Engine";
	}

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;

		#if !debug
		if (eventKey == FlxKey.ENTER)
		#end
		resetWindow();
		switch (eventKey) {
			case FlxKey.ENTER:
				MusicBeatState.switchState(new TitleState());
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
