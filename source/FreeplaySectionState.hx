package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;
import WeekData;

using StringTools;

class FreeplaySectionState extends MusicBeatState
{
	public static var daSection:String = '';
	var counter:Int = 0;
	var sectionArray:Array<String> = [];

	var sectionSpr:FlxSprite;
	var sectionTxt:FlxText;

	private var camGame:FlxCamera;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;

	var transitioning:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Selecting a Freeplay Section", null);
		#end

		persistentUpdate = true;
		WeekData.reloadWeekFiles(false);

		var doFunnyContinue = false;

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if(leWeek.hideFreeplay) continue;
			//you're so sexy omg ily so much <3 (not you, the code dumbass)
			if (leWeek.sections != null) {
				var fuck:Int = 0;
				for (section in leWeek.sections) {
					if (section.toLowerCase() != sectionArray[fuck].toLowerCase()) {
						sectionArray.push(section);
						fuck++;
					} else {
						fuck++;
					}
				}
			//trace (Std.string(sectionArray));
			} else {
				doFunnyContinue = true;
			}
			if (doFunnyContinue) {
				doFunnyContinue = false;
				continue;
			}

			WeekData.setDirectoryFromWeek(leWeek);
		}
		WeekData.loadTheFirstEnabledMod();

		daSection = sectionArray[0];

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxG.cameras.setDefaultDrawTarget(camGame, true); //new EPIC code
		//FlxCamera.defaultCameras = [camGame]; //old STUPID code

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll.velocity.set(29, 30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll.antialiasing = ClientPrefs.globalAntialiasing;
		bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'), 0, 0, 0);
		bgScroll2.velocity.set(-29, -30); // Speed (Can Also Be Modified For The Direction Aswell)
		bgScroll2.antialiasing = ClientPrefs.globalAntialiasing;
		if (!ClientPrefs.lowQuality) {
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite(-FlxG.width/2,-FlxG.height/2).loadGraphic(Paths.image('gradient'));
		gradient.antialiasing = ClientPrefs.globalAntialiasing;
		add(gradient);
		//gradient.screenCenter();

		sectionSpr = new FlxSprite(0,0).loadGraphic(Paths.image('freeplaysections/' + daSection.toLowerCase()));
		sectionSpr.antialiasing = ClientPrefs.globalAntialiasing;
		sectionSpr.scrollFactor.set();
		sectionSpr.screenCenter(XY);
		add(sectionSpr);

		sectionTxt = new FlxText(0, 0, 0, "");
		sectionTxt.scrollFactor.set();
		sectionTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		sectionTxt.screenCenter(X);
		sectionTxt.y += 620;
		add(sectionTxt);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, null, 1);

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.lowQuality) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	
		if (!transitioning) {
		var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		bg.scale.set(mult, mult);
		bg.updateHitbox();
		}

		if (controls.UI_LEFT_P && !transitioning)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			if (counter > 0) {
				counter -= 1;
				daSection = sectionArray[counter];
				sectionSpr.loadGraphic(Paths.image('freeplaysections/' + daSection.toLowerCase()));
			}
		}

		if (controls.UI_RIGHT_P && !transitioning)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
			if (counter < sectionArray.length - 1) {
				counter += 1;
				daSection = sectionArray[counter];
				sectionSpr.loadGraphic(Paths.image('freeplaysections/' + daSection.toLowerCase()));
			}
		}
		
		if ((controls.BACK || (FlxG.mouse.justPressedRight && ClientPrefs.mouseControls)) && !transitioning)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if ((controls.ACCEPT || (FlxG.mouse.justPressed && ClientPrefs.mouseControls)) && !transitioning)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			transitioning = true;
			sectionTxt.visible = false;
			bgScroll.visible = false;
			bgScroll2.visible = false;
			gradient.visible = false;
			FlxTween.tween(sectionSpr, {'scale.x': 11, 'scale.y': 11, y: sectionSpr.y + 3000, alpha: 0}, 0.9, {
				ease: FlxEase.expoIn
			});
			FlxTween.tween(bg, {'scale.x': 0.003, 'scale.y': 0.003, alpha: 0}, 1.1, {
				ease: FlxEase.expoIn,
				onComplete: function(twn:FlxTween) {
					FlxTransitionableState.skipNextTransIn = true;
					MusicBeatState.switchState(new FreeplayState());
				}
			});
		}

		sectionTxt.text = daSection.toUpperCase();
		sectionTxt.screenCenter(X);
		
		if(transitioning) {
			bg.screenCenter(XY);
		} 
		
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		super.update(elapsed);
	}

	override function beatHit() {
		super.beatHit();

		if (!transitioning) {
			bg.scale.set(1.06,1.06);
			bg.updateHitbox();
		}
		//trace('beat hit' + curBeat);
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
}
