#if HSCRIPT_ALLOWED
package haxescript;

import haxescript.Hscript;
/*import sys.FileTools;
import sys.FileSystem;*/

class HscriptSubstate extends MusicBeatSubstate {
    public var hscriptRef:Hscript;
    public static var instance:HscriptSubstate = null;
    public function new(name:String, args:Array<Dynamic>) {
        super();
        instance = this;

        hscriptRef = new Hscript('assets/scripts/substates/$name.hscript', true, H_SUBSTATE); //skip init create call to avoid errors

        setVar("instance", instance);
        hscriptRef.call("new", args);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        hscriptRef.call("update", [elapsed]);
    }

    private inline function setVar(name:String, content:Dynamic) {
        hscriptRef.interpreter.variables.set(name, content);
    }
}
#end