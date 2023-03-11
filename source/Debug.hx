package;

import CoolUtil.getObjectFromClass;
import CoolUtil.setObjectFromClass;
import PlayState;
import flixel.FlxBasic;
import flixel.FlxG.mouse;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import openfl.Lib.application;
import openfl.events.KeyboardEvent;

//Quick Setters for cleaner code
enum ErrorType {
    INVALID_TARGETS;
}
/**
 * Represents a reference to an object inside of a class via two values, the Class object and the name of the target variable as a string.
 */
typedef ClassRef = {
    var targetClass:Dynamic;
    var targetObj:String;
}

/**
 * Class used to control further debug functionality like dragging around objects on any stage.
 * 
 * CONTROLS:
 * 
 * CONTROL TO TOGGLE DEBUGGING (must have Debug.onUpdate in the State's update function)
 * 
 * PRESS LEFT MOUSE BUTTON TO SET OBJECT POSITION AT MOUSE POSITION
 * 
 * HOLD MOUSE BUTTON TO DRAG OBJECT 
 * 
 * SCROLL MOUSE TO CHANGE SCALE OF OBJECT (WILL RETURN IN WIDTH AND HEIGHT AND TAKE THE ASPECT RATIO INTO ACCOUNT)
 * 
 * LET GO TO TRACE SAID POSITION TO CONSOLE
 * 
 * UP AND DOWN KEY TO CHANGE SELECT TARGET
 */
class Debug extends FlxBasic{
    public static var instance:Debug;
    var debugMode:Bool = false;
    
    public var main_targetsGroup:Array<ClassRef> = []; //overall targets
    public var targetsGroup:Array<ClassRef> = []; //selectable targets
    
    var targetNum(default, set):Int = 0;
    var targetsAmount:Int = 0;
    var lastTargetsAmount:Int = 0; //to push notif if new target was added after reinit of loadable targets

    var isDebug_:Bool = false;
    var firstTimeDebug:Bool = true;

    var initialXY:Array<Int> = []; //for calculating group-moved
    var mouseXY:Array<Int> = []; //mouse xy on drag start
    var mainGroupLen:Int = 0;

    /**
     * Initializes the debug variables. 
     * 
     * Put into your state's `create` function by doing `final debugInit:Debug = new Debug()`!
     */
    public function new():Void {
        super();

        instance = this;
        debugMode = false; //make sure to force reload on state switches

        //requires "-debug" flag to be toggled to work (lime test windows -debug)
        #if debug
        if(!isDebug_) {
            isDebug_ = true;
        }
        #end

        //Refer to typedef ClassRef for formatting
        //Done here since class needs to be initialized for shit to work
        main_targetsGroup = [
            {targetClass: PlayState.instance, targetObj: "dad"},
            {targetClass: PlayState.instance, targetObj: "boyfriend"}
        ];
        mainGroupLen = main_targetsGroup.length;

        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, toggleDebug);
        FlxG.signals.preStateSwitch.add(destroy); //make sure that if you exit target state functionality stops FULLY!!!
    }

	public function toggleDebug(keyHit:KeyboardEvent):Void
    {
        if(keyHit.keyCode != F5 || !isDebug_) return;

        debugMode = !debugMode;
        trace('Debug: $debugMode');

        targetsAmount = 0;
        targetsGroup = [];
        
        var availableTargetsString:Array<String> = [];
        for(i in 0...main_targetsGroup.length){
            if(getObjectFromClass(main_targetsGroup[i].targetClass, main_targetsGroup[i].targetObj) == null) {
                trace("awh hell nah null object!!");
                continue;
            }
            else {
                availableTargetsString.push(main_targetsGroup[i].targetObj);
                targetsGroup.push(main_targetsGroup[i]);
                targetsAmount++;
            }
        }

        if (targetsAmount < 1) { analyzeError(INVALID_TARGETS); return; }

        if(lastTargetsAmount != targetsAmount && !firstTimeDebug) {
            lastTargetsAmount = targetsAmount;
            targetNum = 0;
            trace("ayo bro we reloaded your shit so your selection has been set back to 0");
        }

        trace("available targets: " + targetsAmount + " " + availableTargetsString);
        firstTimeDebug = false;
    }

    function analyzeError(e:ErrorType = INVALID_TARGETS):Void {
        switch(e) {
            case INVALID_TARGETS: //might be useful later
                if(mainGroupLen > 0) {
                    trace("All current targets are null, try debugging again later!");
                    application.window.alert("All current targets are null, try debugging again later!!", "Null Targets");
        
                    return;
                }
                trace("no targets found in targetsGroup array, debug cant be triggered");
                application.window.alert("Debug cannot be triggered!", "No Targets");
            default:
                analyzeError(INVALID_TARGETS);
        }
    }

    var lastScaledObj:String = '';
    /**
     * Calls the update checks necessary for Debug.
     * 
     * Call this function in your state's `update` function using `Debug.instance.onUpdate();`
     */
    public function onUpdate():Void {
        if(isDebug_) FlxG.mouse.visible = debugMode;
        if(!isDebug_ || mainGroupLen < 0 || !debugMode || cease) return;

        final targetClass:Dynamic = main_targetsGroup[targetNum].targetClass;
        final targetObj:String = targetsGroup[targetNum].targetObj;

        final doingShit:Bool = FlxG.mouse.pressed || mouse.wheel != 0 || FlxG.mouse.justReleased; //prevent target changing while targets are being modified

        if(FlxG.mouse.justPressed){
            initialXY = [getObjectFromClass(targetClass, targetObj + ".x"), getObjectFromClass(targetClass, targetObj + ".y")];
            mouseXY = [FlxG.mouse.x, FlxG.mouse.y]; //init
            trace(initialXY + ", " + mouseXY);
        }
        if(FlxG.mouse.pressed && !FlxG.mouse.justPressed){
            setObjectFromClass(targetClass, targetObj + ".x", initialXY[0] + (FlxG.mouse.x - mouseXY[0]));
            setObjectFromClass(targetClass, targetObj + ".y", initialXY[1] + (FlxG.mouse.y - mouseXY[1]));
        }
        if(mouse.wheel != 0){
            final mouseVal:Float = FlxMath.bound(mouse.wheel, -1, 1);
            final scrollValue:Int = (FlxG.keys.pressed.SHIFT) ? Std.int(100 * mouseVal) : Std.int(50 * mouseVal);

            var scaledobjct:Dynamic = getObjectFromClass(targetClass, targetObj);
            scaledobjct.setGraphicSize(Std.int(scaledobjct.width + scrollValue), 0); //actually change scale
            setObjectFromClass(targetClass, targetObj, scaledobjct); //replace the old unscaled sprite with a new properly scaled sprite

            setObjectFromClass(targetClass, targetObj + ".width", scaledobjct.width + scrollValue); //change internal values [does not change actual width!!]
            
            //Make sure we only have relevant watches on the list!
            if(lastScaledObj != '') {
                FlxG.watch.removeQuick('$lastScaledObj.width');
                FlxG.watch.removeQuick('$lastScaledObj.height');
            }
            FlxG.watch.addQuick(targetObj + ".width", scaledobjct.width);
            FlxG.watch.addQuick(targetObj + ".height", scaledobjct.height);

            lastScaledObj = targetObj;
        }
        if(FlxG.mouse.justReleased)
            trace("current target x: " + getObjectFromClass(targetClass, targetObj + ".x") + " | current target y: " + getObjectFromClass(targetClass, targetObj + ".y"));

        if(!doingShit && FlxG.keys.anyJustPressed([FlxKey.UP, FlxKey.DOWN])){
            final pressedMap:Map<Int, Int> = [FlxKey.UP => 1, FlxKey.DOWN => -1];
            targetNum += pressedMap[FlxG.keys.firstJustPressed()];
        }
    }

    var cease:Bool = false; //ensure no null errors get thrown for WHATEVER reason
    function set_targetNum(add:Int):Int{
        cease = true;

        final nextTarget:Int = Std.int(FlxMath.bound(targetNum + add, -1, targetsAmount));
        final boundsMap:Map<Int, Int> = [-1 => targetsAmount - 1, targetsAmount => 0];

        targetNum = boundsMap.exists(nextTarget) ? boundsMap[nextTarget] : nextTarget;
        cease = false;

        trace("select object is: " + targetsGroup[targetNum].targetObj);
        return targetNum;
    }

    override function destroy(){
        instance = null;
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, toggleDebug);
        FlxG.signals.preStateSwitch.remove(destroy);

        super.destroy();
    }
}