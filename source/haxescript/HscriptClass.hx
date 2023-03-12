#if HSCRIPT_ALLOWED
package haxescript;
import openfl.Lib;

import haxescript.Hscript;
import haxescript.HClassComps;
import hscript.Interp;
import hscript.Parser;
import hscript.Expr;

//Makes manual inheritance possible
class ExtendClass {
    public var instance:Dynamic = null;
    public var hasConstructor:Bool = true;
    public var classInstance:Class<Dynamic> = null;
    public function new(extendType:String, args:Array<Dynamic>, skip:Bool = false) { //Handles the inheritance stuff!!
        if(skip) return;

        classInstance = Type.resolveClass(extendType);
        try {
            if(args == null || args.length == 0) throw 'SKIP_THROW:NO_ARGS';
            instance = Type.createInstance(classInstance, args);
        }
        catch(error_A) {
            if(error_A.toString() != 'SKIP_THROW:NO_ARGS') 
                Lib.application.window.alert('(error $error_A): extender prob has no constructor, create empty instance', 'Error on HaxeScript');
            try {
                instance = Type.createEmptyInstance(classInstance);
                hasConstructor = false;
            }
            catch(error_B) {
                Lib.application.window.alert('(error $error_B): extender "$extendType" doesnt exist or something else, check error!', 'Error on HaxeScript');
            }
        }
    }
}

class HscriptClass extends ExtendClass {
    var hscriptRef:Hscript;
    var name:String;
    public var classContainer:HClass;

    public var extendedFields:Map<String, Bool> = [];
    public function new(name:String) { //Used in InitState!!
        hscriptRef = new Hscript('assets/scripts/classes/$name', true, H_CLASS);
        this.name = name;

        final extendArgs:Array<Dynamic> = hscriptRef.get('ext_info');
        final skipExtending:Bool = extendArgs == null;
        var constructorArgs:Array<Dynamic> = [];
        var extendClass:String = '';
        if(!skipExtending) 
        {
            extendClass = extendArgs[0];
            if(extendArgs.length > 0) constructorArgs = extendArgs[1];
        }
        super(extendClass, constructorArgs, skipExtending);

        if(instance != null) { //set inheritance instance var if available
            final extendedFields = Type.getInstanceFields(classInstance);
            for(field in extendedFields) {
                this.extendedFields.set(field, true);
            }
            setVar('this', instance);
        }

        final interpRef:Interp = hscriptRef.interpreter;
        @:privateAccess {
            classContainer = {
                name: this.name,
                extend: extendClass,
                vars: interpRef.trackedVars,
                funcs: interpRef.trackedFuncs
            };
            #if HSCRIPT_DEBUG trace(classContainer); #end
        }
        //Check post-parse related things
        for(name=>variable in classContainer.vars) {
            if(variable.getter.access == 'get' && variable.getter.func == null) throw 'Hscript-Class "${this.name}" variable "$name" requires "get_$name" function!';
            if(variable.setter.access == 'set' && variable.setter.func == null) throw 'Hscript-Class "${this.name}" variable "$name" requires "set_$name" function!';
        }
        if(hscriptRef.interpreter.variables.exists('init'))
            hscriptRef.call('init', []);
    }

    public function toString():String {
        return classContainer.toString();
    }
    
    function callStart(args:Array<Dynamic>) {
        hscriptRef.call("new", args);
    }

    /**
     * Gets the field defined by 'varName' and returns its value, or null if it has none.
     * 
     * Will throw if "varName" cannot be accessed due to insufficient permission!
     * @param fieldName The name of the field you want to get
     * @param requiredAccess The access this field must have for it to be returnable. (Should be set according from where you're accessing this function)
     */
    public function get_(fieldName:String, requiredAccess:Array<FieldAccess>, ?funcArgs:Array<Dynamic> = null):Dynamic {
        //Check for func and availability
        if(funcArgs != null) {
            final func = classContainer.funcs.get(fieldName);
            if (func == null) throw 'Invalid function parameters! "$name" has no function named "$fieldName"!';
            
            for(reqAccess in requiredAccess) {
                if(!func.access.contains(reqAccess)) throw 'Invalid access to "$fieldName", missing access "$reqAccess"!';
            }
            return Reflect.callMethod(func, func.expression, funcArgs);
        }
        else if (classContainer.funcs.get(fieldName) != null) throw 'Invalid access! "$fieldName" requires function parameters!';
        
        //Check if its available (must be var at this point!)
        final variable = classContainer.vars.get(fieldName);
        if(variable == null) throw 'Invalid access! "$name" has no field "$fieldName"!';
        for(reqAccess in requiredAccess) {
            if(!variable.access.contains(reqAccess)) throw 'Invalid access to "$fieldName", missing access "$reqAccess"!';
        }

        switch(variable.getter.access) {
            case GET: return variable.getter.content();
            case NULL: if(requiredAccess.length != 0) throw 'Cannot get "$fieldName" outside of class "$name" due to getter access "NULL"!';
            case NEVER: throw 'Cannot get "$fieldName" with getter access "NEVER"!';
            default: //regular behaviour
        }
        return variable.val;
    }

    public function set_(fieldName:String, requiredAccess:Array<FieldAccess>, value:Dynamic) {
        var func = classContainer.funcs.get(fieldName);
        if(func != null) {
            for(reqAccess in requiredAccess) {
                if(!func.access.contains(reqAccess)) throw 'Invalid access to "$fieldName", missing access "$reqAccess"!';
            }

            func.expression = value;
            classContainer.funcs.set(fieldName, func);
            return;
        }
        var variable = classContainer.vars.get(fieldName);
        if(variable == null) throw 'Invalid access! "$name" has no field "$fieldName"!';
        for(reqAccess in requiredAccess) {
            if(!variable.access.contains(reqAccess)) throw 'Invalid access to "$fieldName", missing access "$reqAccess"!';
        }

        switch(variable.getter.access) {
            case SET: variable.val = variable.setter.content(value);
            case NULL: if(requiredAccess.length != 0) throw 'Cannot set "$fieldName" outside of class "$name" due to setter access "NULL"!';
            case NEVER: throw 'Cannot set "$fieldName" with setter access "NEVER"!';
            default: //regular behaviour
        }
        variable.val = value;
    }
    private inline function setVar(name:String, content:Dynamic) {
        hscriptRef.interpreter.variables.set(name, content);
    }
    /*private inline function interp():Interp { //MFW this wont work for no reason
        return hscriptRef.interpreter;
    }*/
}
#end