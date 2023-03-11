package editors;

class EditorMusic {
    //lmao
    public function new() {
        shuffleMusic();
    }

    public function shuffleMusic() {
        function funnyLocalThing() {
            switch (FlxG.random.int(0, 4))
            {
                case 0:
                    FlxG.sound.playMusic(Paths.music('shop'), 0.5);
                    Conductor.changeBPM(143);
                case 1:
                    FlxG.sound.playMusic(Paths.music('sneaky'), 0.5);
                    Conductor.changeBPM(108);
                case 2:
                    FlxG.sound.playMusic(Paths.music('mii'), 0.5);
                    Conductor.changeBPM(118);
                case 3:
                    FlxG.sound.playMusic(Paths.music('dsi'), 0.5);
                    Conductor.changeBPM(150);
                case 4:
                    FlxG.sound.playMusic(Paths.music('breakfast'), 0.5);
                    Conductor.changeBPM(160);
            }
            FlxG.sound.music.fadeIn(1, 0, 0.5);
            FlxG.sound.music.onComplete = shuffleMusic;
        }
        funnyLocalThing();
    }

    public function reset() {
        FlxG.sound.music.onComplete = null;
    }
}