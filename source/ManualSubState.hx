package;

import flash.geom.Rectangle;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

class ManualSubState extends MusicBeatSubstate {
    var state:MusicBeatState;
    var manual:FlxSprite;
    var loadedSprs:Array<FlxSprite> = [];
    var bgMusic:FlxSound;
    static var lastMusTime:Float = 0;
    static var lastManualPos:Float = 60;
    var scrollSound:FlxSound;
    var pageSound:FlxSound;
    var endSound:FlxSound;
    var curTween:FlxTween;
    var icons:Array<HealthIcon> = [];
    final usableIcons:Array<String> = ['bf', 'dad', 'gf', 'mom', 'senpai', 'spirit', 'skid-and-pump', 'tankman', 'monster', 'parents', 'pico', 'botfriend', 'bf-and-gf', 'face'];
    public function new(_state:MusicBeatState) {
        super();
        //hand this over so we dont leave the state not updating
        this.state = _state;
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
        Paths.image('oscillators/manual');
        bgMusic = new FlxSound().loadEmbedded(Paths.music('elevator'), true, false);
        FlxG.sound.list.add(bgMusic);
        scrollSound = new FlxSound().loadEmbedded(Paths.sound('appScroll'));
        FlxG.sound.list.add(scrollSound);
        pageSound = new FlxSound().loadEmbedded(Paths.sound('pageJump'));
        FlxG.sound.list.add(pageSound);
        endSound = new FlxSound().loadEmbedded(Paths.sound('endJump'));
        FlxG.sound.list.add(endSound);

        if (FlxG.sound.music != null)
            FlxG.sound.music.fadeOut(0.44, 0);

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xffffffff);
        bg.screenCenter();
        bg.alpha = 0;
        bg.scrollFactor.set();
        FlxTween.tween(bg, {alpha: 1}, 0.44);
        add(bg);
        loadedSprs.push(bg);

        var gradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00ffffff, 0xffaaaaaa]);
        gradient.screenCenter();
        gradient.y += FlxG.height;
        FlxTween.tween(gradient, {y: 0}, 0.77, {
            ease: FlxEase.cubeIn,
            startDelay: 0.44,
            onComplete: _ -> startIntro()
        });
        gradient.scrollFactor.set();
        add(gradient);
        loadedSprs.push(gradient);

        for (i in 0...6) {
            var icon = new HealthIcon(usableIcons[i], i % 2 == 0);
            icon.screenCenter();
            icon.x += ((FlxG.width*0.4) * (i % 2 == 0 ? -1 : 1)) + FlxG.random.float(-100,100);
            icon.y = FlxG.height + 120;
            icon.alpha = 0.6;
            icon.velocity.y = FlxG.random.int(-40,-110);
            icon.visible = false;
            icon.ID = i;
            icons.push(icon);
            loadedSprs.push(icon);
            add(icon);
        }
    }

    function startIntro() {
        var icon:HealthIcon = new HealthIcon('gf', true);
        icon.screenCenter();
        icon.alpha = 0;
        icon.trackerOffsets = [3, 1];
        icon.updateHitbox();
        icon.scale.set(8,8);
        icon.scrollFactor.set();
        add(icon);
        loadedSprs.push(icon);
		var iconOverlay = new FlxUI9SliceSprite(0, 0, Paths.image('oscillators/blue'), new Rectangle(0, 0, 192, 192), [32, 32, 96, 96]);
		iconOverlay.screenCenter();
		iconOverlay.alpha = 0;
        add(iconOverlay);
        iconOverlay.scale.set(8,8);
        iconOverlay.scrollFactor.set();
        loadedSprs.push(iconOverlay);

        FlxG.sound.play(Paths.sound('appPreStart'), 0.8);
        FlxTween.tween(icon, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.95, {
            ease: FlxEase.quadInOut
        });
        FlxTween.tween(iconOverlay, {"scale.x": 1, "scale.y": 1, alpha: 1}, 0.95, {
            ease: FlxEase.quadInOut,
            onComplete: _ -> {
                FlxG.sound.play(Paths.sound('appStart'), 0.8);
                var fader = new FlxSprite();
                fader.pixels = iconOverlay.pixels.clone();
                fader.scrollFactor.set();
                insert(members.indexOf(icon) - 1, fader);
                fader.setPosition(iconOverlay.x, iconOverlay.y);
                FlxTween.tween(fader, {"scale.x": 3, "scale.y": 3, alpha: 0}, 0.77, {
                    ease: FlxEase.quadInOut,
                    onComplete: _ -> spawnManual()
                });
                loadedSprs.push(fader);
            }
        });
    }

    function spawnManual() {
        manual = new FlxSprite().loadGraphic(Paths.image('oscillators/manual'));
        manual.screenCenter(X);
        manual.y = FlxG.height;
        FlxTween.tween(manual, {y: lastManualPos}, 1, {
            ease: FlxEase.expoOut,
            onComplete: _ -> blockInput = false
        });
        manual.scrollFactor.set();
        manual.antialiasing = false;
        add(manual);
        loadedSprs.push(manual);
        bgMusic.play();
        bgMusic.time = lastMusTime;
        bgMusic.fadeIn(2, 0, 0.8);
        for (icon in icons) {
            icon.y = FlxG.height + 120;
            icon.visible = true;
        }
    }

    var blockInput:Bool = true;
    override function update(elapsed) {
        super.update(elapsed);
        if (control('back')) exit();
        if (manual == null) return;
        for (icon in icons) {
            icon.angle += elapsed*12;
            if (icon.y > -160) continue;
            icon.screenCenter();
            icon.x += ((FlxG.width*0.4) * (icon.ID % 2 == 0 ? -1 : 1)) + FlxG.random.float(-100,100);
            icon.y = FlxG.height + FlxG.random.int(60,120);
            icon.velocity.y = FlxG.random.int(-40,-110);
            icon.angle = FlxG.random.float(0,360);
            icon.changeIcon(usableIcons[FlxG.random.int(0, usableIcons.length-1)]);
            icon.animation.curAnim.curFrame = FlxG.random.int(0, icon.animation.curAnim.frames.length-1);
        }
        if (blockInput) return;
        final mult = (FlxG.keys.pressed.SHIFT ? 32000 : (FlxG.keys.pressed.CONTROL ? 5000 : 9000)); //keep in mind how large this is
        if (controls.UI_DOWN) moveManual(manual.y - (elapsed*mult), scrollSound);
        if (controls.UI_UP) moveManual(manual.y + (elapsed*mult), scrollSound);
        if (FlxG.keys.justPressed.HOME) moveManual(60, endSound);
        if (FlxG.keys.justPressed.END) moveManual((-manual.height + FlxG.height) - 60, endSound);
        if (FlxG.keys.justPressed.PAGEUP) moveManual(manual.y + manual.height/22, pageSound);
        if (FlxG.keys.justPressed.PAGEDOWN) moveManual(manual.y - (manual.height/22), pageSound);
        #if debug FlxG.watch.addQuick('manualY', manual.y); #end
    }

    var moveTwn:FlxTween = null;
    function moveManual(val:Float, snd:FlxSound) {
        if(moveTwn != null) moveTwn.cancel();
        val = CoolUtil.clamp(val, (-manual.height + FlxG.height) - 60, 60);
        moveTwn = FlxTween.tween(manual, {y: val}, val / (val * 1.83), {ease: FlxEase.expoOut, onComplete: (_) -> { moveTwn = null; }});

        snd.play(false); 
    }

    var alreadyExiting:Bool = false;
    function exit() {
        if (alreadyExiting || blockInput) return;
        blockInput = alreadyExiting = true;

        state.persistentDraw = true; //doing this seperate so you can see it during the exit anim
        bgMusic.fadeOut(0.44, 0, _ -> {
            bgMusic.destroy();
            lastMusTime = bgMusic.time;
        });
        lastManualPos = manual.y;
        FlxG.sound.play(Paths.sound('appSuspend'), 0.8);
        cameras[0].fade(FlxColor.WHITE, 0.44, false, () -> {
            for (spr in loadedSprs) {
                spr.visible = false;
            }
            if (FlxG.sound.music != null)
                FlxG.sound.music.fadeIn(0.44, 0, 0.8);
            cameras[0].fade(FlxColor.WHITE, 0.44, true, () -> {
                close();
            }, true);
        }, true);
    }

    override function close() {
        //actually making it start updating again
        state.persistentUpdate = true;
        super.close();
    }
}