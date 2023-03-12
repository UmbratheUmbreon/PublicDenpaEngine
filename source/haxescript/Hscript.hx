package haxescript;

//Put any flash related stuff in here for HscriptMacros to work
#if !macro
import flixel.FlxSubState;
import flixel.FlxState;
import flixel.util.FlxColor;
#end
import haxe.CallStack;
import haxe.Json;
import lime.app.Application;
import openfl.utils.Assets;
#if HSCRIPT_ALLOWED
import hscript.Interp;
import hscript.Parser;
import hscript.Expr;
import haxescript.HClassComps;
#end

using Reflect;

enum HscriptType{
    H_BASIC;
    H_CLASS;
    H_STATE;
    H_SUBSTATE;
}

@:structInit class AbstractVal {
    public var isFunc:Bool;
    public var val:Dynamic;
}
/**
* Class used to control `HScript`.
* Written by _jorge, extended on by AT & YanniZ06.
*/
class Hscript 
{
    #if HSCRIPT_ALLOWED
    public static var activeScripts:Array<Hscript> = [];
    /**
     * 
     */
    public var interpreter:Interp;
    /**
     * The parser variable, used to parse the text from the Hscript file into useable haxe code
     */
    public var parser:Parser;
    /**
     * Ensures this hscript instance is not removed from the static script pool on state switch (must be static variable!)
     */
    public var persistent:Bool = false;
    /**
     * The name of the script, defined by its file name
     */
    public var scriptName:String = '';
    /**
     * An abstract enum representing this scripts type, used to define use-case and to define allowed/unallowed properties
     */
    public var scriptType:HscriptType = H_BASIC;
    /**
     * The (public) static variables defined in this hscript file. Cannot be obtained on files of type H_BASIC. 
     */
    public var staticVars:Array<String> = [];

    private static var hadError:Bool = false;
    public function new(path:String, ?skipCreateCall:Bool = false, parseType:HscriptType = H_BASIC, isInit:Bool = false) //isInit is only used for compiling
    {
        var file:String = 'trace("No script found");';
        //jorge im sobbing why didnt you use Sys.File before it works perfectly unlike lime Assets
        #if sys
        if (FileSystem.exists(path))
            file = File.getContent(path);
        #else
        if (OpenFlAssets.exists(path))
            file = Assets.getText(path);
        #end
        //trace(file);

        scriptType = parseType;

        interpreter = new Interp();
        interpreter.cType = parseType;

        parser = new Parser();
        parser.allowJSON = true;
        parser.allowTypes = true;

        if (hadError)
        {
            file = 'trace("Replaced script to continue gameplay");';
            hadError = false;
        }

        scriptName = path;        
        setPreProcessorValues();

        //haha you require("sex");
        interpreter.variables.set("require", (str) -> {
            if (FileSystem.exists(FileSystem.absolutePath(str)))
            {
                var fileContent:Any = null;
                if (str.endsWith(".json"))
                    fileContent = Json.parse(Assets.getText(FileSystem.absolutePath(str)))
                else if (str.endsWith(".xml"))
                    fileContent = Xml.parse(Assets.getText(FileSystem.absolutePath(str)));
                else
                    fileContent = Assets.getText(FileSystem.absolutePath(str));
                return fileContent;
            }
            else {
                //if(!initAbstractVals(str))
                return Type.resolveClass(str);
                //return 'ABSTRACT__VAL'; //trolling
            }
        });

        //GENERALLY PUBLIC HSCRIPT FUNCTIONS
        #if !macro
        interpreter.variables.set("openState", (name) -> {
            if(FileSystem.exists('assets/scripts/states/$name.hscript')) 
                MusicBeatState.switchState(new HscriptState(name));
            else {
                try {
                    final rawClass = Type.resolveClass(name);
                    if(rawClass == null) { 
                        #if HSCRIPT_DEBUG trace('failed state switch: $name is not a valid hscript- or base class!'); #end
                        return; 
                    }

                    var state:FlxState = cast(Type.createInstance(rawClass, []), FlxState);
                    MusicBeatState.switchState(state);
                }
                catch(e) {
                    #if HSCRIPT_DEBUG trace('$e : Unspecified result for opening state "$name", could not switch states!'); #end
                    return;
                }
            }
            #if HSCRIPT_DEBUG trace('switched to state: $name'); #end
        });

        interpreter.variables.set("openSubState", (name:String, args:Array<Dynamic>) -> {
            if(FlxSubState.curInstance != null) { //We check if theres already a substate open and if we can override it
                FlxG.log.warn('Substate ${Type.getClassName(cast(FlxSubState.curInstance, Class<Dynamic>))} is already active!');
                if(!FlxSubState.curInstance.overrideable) return;

                FlxSubState.curInstance.close();
            }
            if(FileSystem.exists('assets/scripts/substates/$name.hscript')) 
                MusicBeatState.curInstance.openSubState(new HscriptSubstate(name, args));
            else {
                try {
                    final rawClass = Type.resolveClass(name);
                    if(rawClass == null) { 
                        #if HSCRIPT_DEBUG trace('failed to open substate: $name is not a valid hscript- or base class!'); #end
                        return;
                    }
                    //Did a lil oopsie, now it should work fine!!
                    var substate:FlxSubState = cast(Type.createInstance(rawClass, args), FlxSubState);
                    MusicBeatState.curInstance.openSubState(substate);
                }
                catch(e) {
                    #if HSCRIPT_DEBUG trace('$e : Unspecified result for opening substate "$name", could not be opened!'); #end
                    return;
                }
            }
            #if HSCRIPT_DEBUG trace('Opened substate: $name'); #end
        });
        #end

        interpreter.variables.set("extends", (name:String, args:Array<Dynamic>) -> {
            if(scriptType != H_CLASS) throw 'Invalid "extends" call, only allowed on class-scripts';
            set("ext_info", [name, args]);
        });
        //END
    
        try {
            if (file != 'trace("No script found");') {
                #if HSCRIPT_DEBUG trace('Loading hscript of type $parseType: $path'); #end
                activeScripts.push(this);
                FlxG.signals.preStateSwitch.add(() -> { activeScripts.remove(this); });

                final n:Array<String> = path.split('/');
                interpreter.execute(parser.parseString(file, n[n.length-1], scriptType == H_BASIC), isInit);

                if (!skipCreateCall)
                    call("onCreate", []);
                return;
            }
            #if HSCRIPT_DEBUG trace('$path hscript file doesnt exist!! (Loading Error)'); #end
        } catch(e) { //Truly the variable naming ever, like at least be a little bit concise
            if (e.toString() == "Null Object Reference")
            {
                var m = "", c = CallStack.callStack();
                for (i in c)
                {
                    switch (i)
                    {
                        case FilePos(s, file, line):
                            m+='$file (line $line)\n';
                        default:
                    }
                }
                Application.current.window.alert(e + "\n\n" + m + "\n\nRemoving script to continue gameplay.", "Error on HaxeScript");
            }
            else
                Application.current.window.alert('From "$path":\n' + e.toString() + "\n\nRemoving script to continue gameplay.", "Error on HaxeScript");
    
            hadError = true;
        }
    }
    #end

    /**
     * Neat little workaround for abstract values like FlxColor. Commented out for now because TIME CONSTRAINTSSSS
     * @param n Name of the abstract.
     * @return If it initialized any abstract values or not.
     */
    /*private function initAbstractVals(n:String):Bool {
        switch(n) {
            case 'flixel.util.FlxColor':
                final fieldMap:Map<String, Dynamic> = [
                    "TRANSPARENT" => 0x00000000,
                    "WHITE" => 0xFFFFFFFF,
                    "GRAY" => 0xFF808080,
                    "BLACK" => 0xFF000000,
                    "GREEN" => 0xFF008000,
                    "LIME" => 0xFF00FF00,
                    "YELLOW" => 0xFFFFFF00,
                    ""
                ];
                //Commented out
                final fields = Reflect.fields(FlxColor);
                for(field in fields) {
                    final val__:Dynamic = Reflect.getProperty(FlxColor, field);
                    set('FlxColor__$field', {isFunc: Reflect.isFunction(val__), val: val__});
                }
                //End
            default:
                return false;
        }
        return true;
    }*/

    public function call(Function:String, Arguments:Array<Dynamic>):Dynamic
    {
        #if HSCRIPT_ALLOWED
        if (interpreter == null || parser == null || !interpreter.variables.exists(Function)) return null;

        var shit = interpreter.variables.get(Function);
        return Reflect.callMethod(interpreter, shit, Arguments);
        #end
    }

    public function get(Function:String):Dynamic
    {
        #if HSCRIPT_ALLOWED
        return interpreter.variables.get(Function);
        #end
    }

    public function set(Function:String, value:Dynamic):Void
    {
        #if HSCRIPT_ALLOWED
        return interpreter.variables.set(Function, value);
        #end
    }

    public function exists(Function:String)
    {
        #if HSCRIPT_ALLOWED
        return interpreter.variables.exists(Function);
        #end
    }

    public function stop()
    {
        #if HSCRIPT_ALLOWED
        interpreter = null;
        parser = null;
        activeScripts.remove(this);
        #end
    }

    public function parseString(daString:String, ?name:String = 'hscript')
    {
        #if HSCRIPT_ALLOWED
        return parser.parseString(daString, name);
        #end
    }

    public function parseFile(daFile:String, ?name:String = 'hscript'){
        #if HSCRIPT_ALLOWED
        if (name == null)
			name = daFile;

        return parser.parseString(Assets.getText(daFile), name);
        #end
    }

    //"htlm5" lmfao -AT
    private function setPreProcessorValues():Void
    {
        #if HSCRIPT_ALLOWED
        parser.preprocesorValues.set("sys", #if sys true #else false #end);
        parser.preprocesorValues.set("cpp", #if cpp true #else false #end);
        parser.preprocesorValues.set("PRELOAD_ALL", #if PRELOAD_ALL true #else false #end);
        parser.preprocesorValues.set("NO_PRELOAD_ALL", #if NO_PRELOAD_ALL true #else false #end);
        parser.preprocesorValues.set("html5", #if html5 true #else false #end);
        parser.preprocesorValues.set("flash", #if flash true #else false #end);
        parser.preprocesorValues.set("mobile", #if mobile true #else false #end);
        parser.preprocesorValues.set("desktop", #if desktop true #else false #end);
        parser.preprocesorValues.set("debug", #if debug true #else false #end);
        parser.preprocesorValues.set("web", #if web true #else false #end);
        parser.preprocesorValues.set("js", #if js true #else false #end);
        parser.preprocesorValues.set("hl", #if hl true #else false #end);
        parser.preprocesorValues.set("neko", #if neko true #else false #end);
        parser.preprocesorValues.set("java", #if java true #else false #end);
        parser.preprocesorValues.set("MODS_ALLOWED", #if MODS_ALLOWED true #else false #end);
        parser.preprocesorValues.set("LUA_ALLOWED", #if LUA_ALLOWED true #else false #end);
        parser.preprocesorValues.set("VIDEOS_ALLOWED", #if VIDEOS_ALLOWED true #else false #end);
        parser.preprocesorValues.set("DENPA_WATERMARKS", #if DENPA_WATERMARKS true #else false #end);
        parser.preprocesorValues.set("CRASH_HANDLER", #if CRASH_HANDLER true #else false #end);
        #end
    }
}

//Fancy dancy method calling thingy ill keep here for now
//var substate:FlxSubState = cast(Reflect.callMethod(rawClass, rawClass.field("new"), args), FlxSubState);