package;

import WeekData;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
#if desktop
import Discord.DiscordClient;
#end

/**
* State used to decide which selection of songs should be loaded in `FreeplayState`.
*/
class FreeplaySectionSubstate extends MusicBeatSubstate {
    public static var daSection:String = 'All';
	var counter:Int = 0;
	var sectionArray:Array<String> = [];
	var sectionImageMap:Map<String, FlxGraphic> = new Map();

	var sectionSpr:FlxSprite;
	var sectionTxt:FlxText;

	var bg:FlxSprite;
	var gradient:FlxSprite;
	var bgScroll:FlxBackdrop;
	var bgScroll2:FlxBackdrop;

	var transitioning:Bool = false;

	override public function new()
	{
        super();

		WeekData.reloadWeekFiles(false);

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			if(leWeek.hideFreeplay || leWeek.sections == null) continue;
			WeekData.setDirectoryFromWeek(leWeek);
			//you're so sexy omg ily so much <3 (not you, the code dumbass)
			for (fuck=>section in leWeek.sections) {
				if (section.toLowerCase() != sectionArray[fuck].toLowerCase()) {
					sectionArray.push(section);
					sectionImageMap.set(section.toLowerCase(), Paths.image('freeplaysections/${section.toLowerCase()}'));
				}
			}
		}
		sectionArray = CoolUtil.removeDuplicates(sectionArray);
		WeekData.loadTheFirstEnabledMod();

        for (i in 0...sectionArray.length) {
            if (sectionArray[i] == daSection) {
                counter = i;
                break;
            }
        }

		daSection = sectionArray[counter];

        var funnyArray:Array<FlxSprite> = [];
        var black1 = new FlxSprite(-FlxG.width/2, 0).makeGraphic(Std.int(FlxG.width/2), Std.int(FlxG.height), 0xff000000);
        add(black1);
        funnyArray.push(black1);
        var black2 = new FlxSprite(FlxG.width, 0).makeGraphic(Std.int(FlxG.width/2), Std.int(FlxG.height), 0xff000000);
        add(black2);
        funnyArray.push(black2);
        FlxTween.tween(black1, {x:0}, 0.7, {
            ease: FlxEase.expoOut
        });
        FlxTween.tween(black2, {x:FlxG.width/2}, 0.7, {
            ease: FlxEase.expoOut
        });

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set(0, 0);
        bg.scale.set(0.003,0.003);
		bg.screenCenter();
        bg.alpha = 0;
		add(bg);

		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll.velocity.set(29, 30);
			bgScroll2 = new FlxBackdrop(Paths.image('menuBGHexL6'));
			bgScroll2.velocity.set(-29, -30);
            bgScroll.visible = false;
            bgScroll2.visible = false;
			add(bgScroll);
			add(bgScroll2);
		}

		gradient = new FlxSprite(-FlxG.width/2,-FlxG.height/2).loadGraphic(Paths.image('gradient'));
		add(gradient);
        gradient.visible = false;
        gradient.screenCenter();

		sectionSpr = new FlxSprite(0,0).loadGraphic(sectionImageMap.get(daSection.toLowerCase()));
		sectionSpr.scrollFactor.set();
		sectionSpr.screenCenter(XY);
        final secSprY = sectionSpr.y;
        sectionSpr.y += 3000;
        sectionSpr.scale.set(11,11);
        sectionSpr.alpha = 0;
		add(sectionSpr);

		sectionTxt = new FlxText(0, 0, 0, "");
		sectionTxt.scrollFactor.set();
		sectionTxt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.BLACK);
		sectionTxt.screenCenter(X);
		sectionTxt.y += 620;
        sectionTxt.visible = false;
		add(sectionTxt);

        transitioning = true;
        FlxTween.tween(sectionSpr, {'scale.x': 1, 'scale.y': 1, y: secSprY, alpha: 1}, 0.7, {
            ease: FlxEase.expoOut
        });
        FlxTween.tween(bg, {'scale.x': 1, 'scale.y': 1, alpha: 1}, 0.9, {
            ease: FlxEase.expoOut,
            onComplete: function(twn:FlxTween) {
                transitioning = false;
                sectionTxt.visible = true;
                gradient.visible = true;
                if (!ClientPrefs.settings.get("lowQuality")) {
                    bgScroll.visible = true;
                    bgScroll2.visible = true;
                }
                for (spr in funnyArray) {
					remove(spr, true);
                    funnyArray.remove(spr);
                    spr.destroy();
                }
            }
        });

		bg.color = SoundTestState.getDaColor();
		if (!ClientPrefs.settings.get("lowQuality")) {
			bgScroll.color = SoundTestState.getDaColor();
			bgScroll2.color = SoundTestState.getDaColor();
		}
		gradient.color = SoundTestState.getDaColor();

		#if desktop
		DiscordClient.changePresence("Selecting a Freeplay Section", '${sectionArray.length} Sections');
		#end
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
	
		if (!transitioning) {
			var mult:Float = FlxMath.lerp(1, bg.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
			bg.scale.set(mult, mult);
			bg.updateHitbox();
			bg.offset.set();
			var mult:Float = FlxMath.lerp(1, sectionSpr.scale.x, CoolUtil.clamp(1 - (elapsed * 9), 0, 1));
			sectionSpr.scale.set(mult, mult);
			sectionSpr.updateHitbox();
		}

		if (controls.UI_LEFT_P && !transitioning)
			changeSelection(-1);

		if (controls.UI_RIGHT_P && !transitioning)
			changeSelection(1);
		
		if ((controls.BACK) && !transitioning)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if ((controls.ACCEPT) && !transitioning)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			transitioning = true;
            //lol?
            FreeplayState.instance.black.visible = true;
			sectionTxt.visible = false;
			if (!ClientPrefs.settings.get("lowQuality")) {
				bgScroll.visible = false;
				bgScroll2.visible = false;
			}
			gradient.visible = false;
			FlxTween.tween(sectionSpr, {'scale.x': 11, 'scale.y': 11, y: sectionSpr.y + 3000, alpha: 0}, 0.7, {
				ease: FlxEase.expoIn
			});
			FlxTween.tween(bg, {'scale.x': 0.003, 'scale.y': 0.003, alpha: 0}, 0.9, {
				ease: FlxEase.expoIn,
				onComplete: function(twn:FlxTween) {
                    FlxTransitionableState.skipNextTransIn = true;
					MusicBeatState.resetState();
				}
			});
		}

		sectionTxt.text = daSection.toUpperCase();
		sectionTxt.screenCenter(X);
		
		if(transitioning) {
			bg.screenCenter(XY);
		} 

		super.update(elapsed);
	}

	function changeSelection(by:Int = 0) {
		counter += by;
		if (counter < 0) counter = sectionArray.length-1;
		if (counter > sectionArray.length - 1) counter = 0;
		daSection = sectionArray[counter];
		sectionSpr.loadGraphic(sectionImageMap.get(daSection.toLowerCase()));
		sectionSpr.scale.set(1.1, 1.1);
		sectionSpr.updateHitbox();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function beatHit() {
		super.beatHit();

		if (!transitioning) {
			bg.scale.set(1.06,1.06);
			bg.updateHitbox();
			bg.offset.set();
		}
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
}