#if HSCRIPT_ALLOWED
package haxescript;
import hscript.Expr;

//A bunch of classes acting like typedefs are contained here (hence the @:structInit metadata)
//Possibly add documentation? Maybe? If you want me to

//class HApi {}

@:structInit class HClass {
    public var name:String;
    public var extend:String;

    public var vars:Map<String, HVariable>;
    public var funcs:Map<String, HFunction>;
    public function toString():String
    {
        return 'HClass($name, extends: $extend,\n\nvariables: $vars,\n\nfunctions: $funcs)';
    }
}

@:structInit class HVariable {
    public var name:String;
    public var access:Array<FieldAccess>;
    public var val:Dynamic;

    public var getter:HGetSet;
    public var setter:HGetSet;
    public function toString():String
    {
        return '\nHVariable(name: $name, access: $access, value: $val,\ngetter:$getter,\nsetter: $setter)\n';
    }
}

enum abstract GetSetType(String) from String to String { //Question, does this need to be abstract?? I dont think so.
    var GET = "get";
    var SET = "set";
    var DEFAULT = "default";
    var NULL = "null";
    var NEVER = "never";
}
@:structInit class HGetSet {
    public var access:GetSetType;
    public var func:Dynamic;
    public function content(?v:Dynamic = null):Dynamic { //We do no safety checks because we only use it interally when these checks have already been done!!
        return Reflect.callMethod(this, func, access == GET ? [] : [v]);
    }
    public function toString():String
    {
        return 'HGetSet(access:$access, func: $func)';
    }
}

@:structInit class HFunction {
    public var name:String;
    public var access:Array<FieldAccess>;

    public var expression:Dynamic;
    public function toString():String
    {
        return '\nHFunction(name: $name, access: $access, expr: $expression)\n';
    }
}

@:structInit class HFuncArg {
    public var name:String;
    public var type:String;
    public var defaultVal:Dynamic; //if exists is automatically optional arg
}
#end