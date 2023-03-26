package;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

/**
* Substate used to select the player character.
*/
class CharacterSelectSubstate extends MusicBeatSubstate
{
    var character:Character;
    var dummy:Character;
    var selectedText:FlxText;
    //Hard coded ones because i dont feel like dealing with the auto one lol
    var charactersArray:Array<String> = ["bf", "bf-pixel", "bf-christmas", "bf-holding-gf", "pico-player", "tankman-player"];
    var selected:Int = 0;
    var bg:FlxSprite;
    var icon:HealthIcon;
    var spotlight:FlxSprite;
    var alphabetArrows:Alphabet;

	public function new()
	{
		super();
        FreeplayState.destroyFreeplayVocals();
        FlxG.sound.playMusic(Paths.music("program_blood"), 0);
        FlxG.sound.music.fadeIn(2, 0, 0.6);
        Conductor.changeBPM(112);

        #if MODS_ALLOWED
        for (character=>folder in Paths.characterMap) {
            if (folder == '') continue;
            if (character.contains("player") || character.startsWith("bf")) {
                charactersArray.push(character);
            }
        }
        #end
        //DNR
        /*for (file in FileSystem.readDirectory("assets/data/characters")) {
            if (file.contains("player") || file.startsWith("bf")) {
                charactersArray.push(file.split(".")[0]);
            }
        }*/

        if (charactersArray == null || charactersArray.length < 0) charactersArray.push("bf");
        for (i in 0...charactersArray.length) {
            if (charactersArray[i].toLowerCase().contains("dead")) charactersArray.remove(charactersArray[i]);
        }
        charactersArray = CoolUtil.removeDuplicates(charactersArray);

        bg = new FlxSprite().makeGraphic(1280,720,0xcf000000);
        add(bg);

        for (i in 0...charactersArray.length) {
            if (charactersArray[i] == PlayState.characterVersion) {
                selected = i;
                break;
            }
        }

        Paths.setModsDirectoryFromType(CHARACTER, charactersArray[selected], false);
        character = new Character(0,0, charactersArray[selected], true);
        character.screenCenter();
        for (key => value in character.animOffsets) {
            character.animOffsets.set(key, [value[0] + character.selectorOffsets.x, value[1] + character.selectorOffsets.y]);
        }
        add(character);
        character.dance();

        dummy = new Character(0,0, charactersArray[selected], true);
        dummy.screenCenter();
        for (key => value in dummy.animOffsets) {
            dummy.animOffsets.set(key, [value[0] + dummy.selectorOffsets.x, value[1] + dummy.selectorOffsets.y]);
        }
        add(dummy);
        dummy.x = FlxG.width*1.5;
        dummy.dance();

        spotlight = new FlxSprite(0,0).loadGraphic(Paths.image("spotlight"));
        spotlight.alpha = 0.35;
        spotlight.screenCenter(X);
        spotlight.y -= spotlight.height/2.8;
        spotlight.blend = flash.display.BlendMode.DIFFERENCE;
        add(spotlight);

        alphabetArrows = new Alphabet(0, 0, "<              >", true, false, 0.05, 1.3);
        alphabetArrows.screenCenter();
        add(alphabetArrows);

        selectedText = new FlxText(0,65,0, CoolUtil.toTitleCase(charactersArray[selected].toLowerCase()).replace("Player", " ").trim(), 32).setFormat("VCR OSD Mono", 32, 0xffffffff, CENTER, OUTLINE, 0xff000000);
        selectedText.screenCenter(X);
        add(selectedText);

        Paths.setModsDirectoryFromType(NONE, '', true);
        Paths.setModsDirectoryFromType(ICON, character.iconProperties.name, false);
        icon = new HealthIcon(character.iconProperties.name, true);
        icon.sprTracker = selectedText;
        icon.trackerOffsets = [0, -30];
        add(icon);
        Paths.setModsDirectoryFromType(NONE, '', true);
	}

    var blockInput:Bool = false;
	override function update(elapsed:Float)
	{
        super.update(elapsed);
        if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

        if (blockInput) return;
        if (controls.ACCEPT) {
            blockInput = true;
            Paths.clearUnusedCache();
            character.skipDance = true;
            if (character != null) {
                if(character.animOffsets.exists('hey')) {
                    character.playAnim('hey', true);
                    character.specialAnim = true;
                    character.heyTimer = 0.6;
                } else if (character.animOffsets.exists('singUP')) {
                    character.playAnim('singUP', true);
                    character.specialAnim = true;
                }
            }
            PlayState.characterVersion = charactersArray[selected];
			FlxG.sound.play(Paths.sound('confirmMenu'));
            leEpicTween();
        }
        if (controls.BACK) {
            blockInput = true;
            Paths.clearUnusedCache();
            character.skipDance = true;
            FlxG.sound.play(Paths.sound('cancelMenu'), 1);
            leEpicTween();
        }
        if (controls.NOTE_DOWN_P) {
            if(character != null && character.animOffsets.exists('singDOWN')) {
                character.playAnim('singDOWN', true);
                canDance = false;
            }
        }
        if (controls.NOTE_LEFT_P) {
            if(character != null && character.animOffsets.exists('singLEFT')) {
                character.playAnim('singLEFT', true);
                canDance = false;
            }
        }
        if (controls.NOTE_RIGHT_P) {
            if(character != null && character.animOffsets.exists('singRIGHT')) {
                character.playAnim('singRIGHT', true);
                canDance = false;
            }
        }
        if (controls.NOTE_UP_P) {
            if(character != null && character.animOffsets.exists('singUP')) {
                character.playAnim('singUP', true);
                canDance = false;
            }
        }
        if (controls.NOTE_DOWN_R || controls.NOTE_LEFT_R || controls.NOTE_RIGHT_R || controls.NOTE_UP_R) canDance = true;
        if (controls.UI_LEFT_P) {
            changeSelection(-1);
        }
        if (controls.UI_RIGHT_P) {
            changeSelection(1);
        }
	}

    override function destroy() {
        FlxG.sound.playMusic(Paths.music(SoundTestState.playingTrack), 0);
        if (SoundTestState.playingTrack == 'freakyMenu') {
            FlxG.sound.music.loopTime = 71853;
            FlxG.sound.music.endTime = null;
        }
        Conductor.changeBPM(SoundTestState.playingTrackBPM);
        FlxG.sound.music.fadeIn(2, 0, 0.7);

        super.destroy();
    }

    var canDance = true;
    override function beatHit() {
        super.beatHit();

        if (character != null && canDance) character.dance();
    }

    var dummyTween:FlxTween = null;
    var characterTween:FlxTween = null;
    function changeSelection(value:Int = 0) {
        if (dummyTween != null) {
            return;
        }
        FlxG.sound.play(Paths.sound('scrollMenu'));
        if (selected == 0 && value == -1) value = charactersArray.length - 1;
        if (selected == charactersArray.length-1 && value == 1) value = -(charactersArray.length - 1);
        selected += value;

        Paths.setModsDirectoryFromType(CHARACTER, charactersArray[selected], false);
        dummy.changeCharacter(charactersArray[selected]);
        for (key => value in dummy.animOffsets) {
            dummy.animOffsets.set(key, [value[0] + dummy.selectorOffsets.x, value[1] + dummy.selectorOffsets.y]);
        }
        dummy.dance();
        dummy.x = (value > 0 ? FlxG.width*1.5 : -dummy.width*1.5);
        final store = dummy.x;
        dummy.screenCenter();
        final tweenTo = dummy.x;
        dummy.x = store;
        Paths.setModsDirectoryFromType(NONE, '', true);

        dummyTween = FlxTween.tween(dummy, {x: tweenTo}, 0.17, {
            ease: FlxEase.cubeInOut
        });
        characterTween = FlxTween.tween(character, {x: (value > 0 ? -character.width*1.5 : FlxG.width*1.5)}, 0.17, {
            ease: FlxEase.cubeInOut,
            onComplete: function(_) {
                changeCharacter();
            }
        });
    }

    function changeCharacter() {
        Paths.setModsDirectoryFromType(CHARACTER, charactersArray[selected], false);
        character.changeCharacter(charactersArray[selected]);
        character.screenCenter();
        for (key => value in character.animOffsets) {
            character.animOffsets.set(key, [value[0] + character.selectorOffsets.x, value[1] + character.selectorOffsets.y]);
        }
        character.dance();

        dummy.x = FlxG.width*2;
        selectedText.text = CoolUtil.toTitleCase(charactersArray[selected].toLowerCase()).replace("Player", " ").trim();
        selectedText.screenCenter(X);
        Paths.setModsDirectoryFromType(NONE, '', true);
        Paths.setModsDirectoryFromType(ICON, character.iconProperties.name, false);
        icon.changeIcon(character.iconProperties.name, character);
        dummyTween = null;
        characterTween = null;
        Paths.setModsDirectoryFromType(NONE, '', true);
    }

    function leEpicTween() {
        FlxTween.tween(bg, {alpha: 0}, 0.7, {
            onComplete: function(_) {
                remove(bg, true);
                bg.destroy();
            }
        });
        final shitToTween:Array<FlxBasic> = [character, selectedText, icon, spotlight, alphabetArrows];
        for (shit in shitToTween) {
            FlxTween.tween(shit, {alpha: 0}, 0.5, {
                onComplete: function(_) {
                    remove(shit, true);
                    shit.destroy();
                }
            });
        }
        new FlxTimer().start(0.75, _ -> close());
    }
}