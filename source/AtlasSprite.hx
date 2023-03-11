package;

import flixel.FlxSprite;
import flxanimate.FlxAnimate;

class AtlasSprite extends FlxSprite
{
    public var atlas:FlxAnimate = null;

    public function new(x:Float, y:Float, character:String)
	{
        super(x, y);

        //hard coding this cuz im stupid lol
        switch (character) {
            case 'tankman-ugh':
                var path = Paths.atlas('images/vanilla/week7/cutscenes/tankman', 'shared');
                atlas = new FlxAnimate(0, 0, path.substr(0, path.length - 15));
                atlas.anim.addBySymbol('talk1', 'TANK TALK 1 P1', 24, false);
                atlas.anim.addBySymbol('talk2', 'TANK TALK 1 P2', 24, false);
            case 'tankman-guns':
                var path = Paths.atlas('images/vanilla/week7/cutscenes/tankman', 'shared');
                atlas = new FlxAnimate(0, 0, path.substr(0, path.length - 15));
                atlas.anim.addBySymbol('talk1', 'TANK TALK 2', 24, false);
            case 'tankman-stress':
                var path = Paths.atlas('images/vanilla/week7/cutscenes/tankman', 'shared');
                atlas = new FlxAnimate(0, 0, path.substr(0, path.length - 15));
                atlas.anim.addBySymbol('talk1', 'TANK TALK 3 P1 UNCUT', 24, false);
                atlas.anim.addBySymbol('talk2', 'TANK TALK 3 P2 UNCUT', 24, false);
            case 'pico-stress':
                var path = Paths.atlas('images/vanilla/week7/cutscenes/stressPico', 'shared');
                atlas = new FlxAnimate(0, 0, path.substr(0, path.length - 15));
                atlas.anim.addBySymbol('anim', 'Pico Saves them sequence', 24, false);
        }
        if (atlas != null) {
            atlas.showPivot = false;
        }
        antialiasing = ClientPrefs.settings.get('globalAntialiasing');
    }

    public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
        @:privateAccess atlas.anim.play(AnimName, Force, Reversed, Frame);
	}

    override function update(elapsed) {
		super.update(elapsed);
        if (atlas == null) return;
		atlas.update(elapsed);
	}

    override function destroy() {
		super.destroy();
        if (atlas == null || atlas.frames == null) return;
        for(f in atlas.frames.frames)
            FlxG.bitmap.remove(f.parent);
        atlas = FlxDestroyUtil.destroy(atlas);
	}

    override function draw() {
		if (atlas != null) {
			copyValsToAtlas();
            if (atlas.anim.curInstance != null)
			    atlas.draw();
		} else
			super.draw();
	}

    function copyValsToAtlas() {
        @:privateAccess {
            atlas.cameras = cameras;
            atlas.scrollFactor = scrollFactor;
            atlas.scale = scale;
            atlas.offset = offset;
            atlas.x = x;
            atlas.y = y;
            atlas.angle = angle;
            atlas.alpha = alpha;
            atlas.visible = visible;
            atlas.flipX = flipX;
            atlas.flipY = flipY;
            atlas.shader = shader;
            atlas.antialiasing = antialiasing;
        }
	}
}