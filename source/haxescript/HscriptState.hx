#if HSCRIPT_ALLOWED
package haxescript;
import haxescript.Hscript;
/*import sys.FileTools;
import sys.FileSystem;*/

class HscriptState extends MusicBeatState {
    public var hscriptRef:Hscript;
    public static var instance:HscriptState = null;
    public function new(className:String) {
        super();
        instance = this;
        hscriptRef = new Hscript('assets/scripts/states/$className.hscript', true, H_STATE); //skip init create call to avoid errors

        setVar('instance', instance);
    }

    override function create() {
        hscriptRef.call("onCreate", []);
        super.create();
        hscriptRef.call("postCreate", []);
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