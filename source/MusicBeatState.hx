package;

import Conductor.BPMChangeEvent;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

/**
* Basic state to use for states in the game.
* Contains functions relating to state transfers, as well as beat/step functions.
*/
class MusicBeatState extends FlxUIState
{
	@:allow(stats.DebugDisplay)
	private var curStep:Int = 0;
	@:allow(stats.DebugDisplay)
	private var curBeat:Int = 0;

	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;
	public static var curInstance:MusicBeatState = null;
	public static var disableManual:Bool = false;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function destroy() {
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPress);
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, keyRelease);
		disableManual = false;
        super.destroy();
    }

	override function create() {
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPress);
        FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, keyRelease);

		curInstance = this; //why was this not done yet?
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.4, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	var trackedBPMChanges:Int = 0;
	/**
	 * A handy function to calculate how many seconds it takes for the given steps to all be hit.
	 * 
	 * This function takes the future BPM into account.
	 * If you feel this is not necessary, use `stepsToSecs_simple` instead.
	 * @param targetStep The step value to calculate with.
	 * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
	 * @return The amount of seconds as a float.
	 */
	inline function stepsToSecs(targetStep:Int, isFixedStep:Bool = false):Float {
		final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;
		function calc(stepVal:Single, crochetBPM:Int = -1) {
			return ((crochetBPM == -1 ? Conductor.getCrochet(Conductor.bpm)/4 : Conductor.getCrochet(crochetBPM)/4) * (stepVal - curStep)) / 1000;
		}

		final realStep:Single = isFixedStep ? targetStep : targetStep + curStep;
		var secRet:Float = calc(realStep);

		for(i in 0...Conductor.bpmChangeMap.length - trackedBPMChanges) {
			var nextChange = Conductor.bpmChangeMap[trackedBPMChanges+i];
			if(realStep < nextChange.stepTime) break;

			final diff = realStep - nextChange.stepTime;
			if(i == 0) secRet -= calc(diff);
			else secRet -= calc(diff, Std.int(Conductor.bpmChangeMap[(trackedBPMChanges+i) - 1].bpm)); //calc away bpm from before, not beginning bpm

			secRet += calc(diff, Std.int(nextChange.bpm));
		}
		//trace(secRet);
		return secRet / playbackRate;
	}

	inline function beatsToSecs(targetBeat:Int, isFixedBeat:Bool = false):Float
		return stepsToSecs(targetBeat * 4, isFixedBeat);

	/**
	 * A handy function to calculate how many seconds it takes for the given steps to all be hit.
	 * 
	 * This function does not take the future BPM into account.
	 * If you need to account for BPM, use `stepsToSecs` instead.
	 * @param targetStep The step value to calculate with.
	 * @param isFixedStep If true, calculation will assume `targetStep` is not being calculated as in "after `targetStep` steps", but rather as in "time until `targetStep` is hit".
	 * @return The amount of seconds as a float.
	 */
	inline function stepsToSecs_simple(targetStep:Int, isFixedStep:Bool = false):Float {
		final playbackRate:Single = PlayState.instance != null ? PlayState.instance.playbackRate : 1;

		return ((Conductor.stepCrochet * (isFixedStep ? targetStep : curStep + targetStep)) / 1000) / playbackRate;
	}

	//Now we keep track of the names!!
	override public function openSubState(tState:FlxSubState) {
		tState.name = Type.getClassName(Type.getClass(tState));
		FlxSubState.curInstance = tState;

		super.openSubState(tState);
	}

	function openManual() {
		FreeplayState.destroyFreeplayVocals();
		persistentUpdate = persistentDraw = false;
		openSubState(new ManualSubState(this));
	}

	/**
     * Function thats called whenever a key is pressed, automatically pre-handles whetever the input was valid or not.
	 * 
	 * Automatically handles debug display and manual toggling.
     * @param event The `KeyboardEvent` object that the value of the key pressed.
     */
	public function keyPress(event:KeyboardEvent):Void
    {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = keyInt(eventKey);
        if (key == -1) return;

		//yippie
		if (ClientPrefs.keyBinds.get('manual').contains(key) && !(FlxSubState.curInstance != null && FlxSubState.curInstance.name == 'ManualSubState') && !disableManual) 
			openManual();

		//FlxKeyManager L.187 (turn into trace later, inconvenient from here, this is only so i know what the error was tmmrw)
		#if debug try { #end
		if (!Main.fpsCounter.visible || !FlxG.keys.checkStatus(key, JUST_PRESSED)) return;
		#if debug
		} catch (e) {
			trace(e);
			return;
		}
		#end

		//toggle debug display
		if ([F3, F4, F5, F6].contains(key)) {
			Main.ramCount.forceUpdate = true;
			if (key == F3)
				Main.toggleMEM(!Main.ramCount.visible);
			if (key == F4)
				Main.ramCount.showSystem = !Main.ramCount.showSystem;
			if (key == F5)
				Main.ramCount.showConductor = !Main.ramCount.showConductor;
			if (key == F6)
				Main.ramCount.showFlixel = !Main.ramCount.showFlixel;

			return;
		}

		if (key == F7)
			Main.togglePIE(!Main.ramPie.visible);
    }

    public function keyRelease(event:KeyboardEvent):Void
    {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = keyInt(eventKey);
		if (key == -1) return;
    }

    public function keyInt(key:FlxKey):Int
	{
		if(key != NONE) return key;
		return -1;
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime) {
				trackedBPMChanges++;
				//trace(trackedBPMChanges);
				lastChange = Conductor.bpmChangeMap[i];
			}
		}

		curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - ClientPrefs.settings.get("noteOffset")) - lastChange.songTime) / Conductor.stepCrochet);
	}

	public static function switchState(nextState:FlxState, ?fadeDuration:Float = 0.35/*, ?dumpCache:Bool = false*/) {
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(fadeDuration, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
			} else {
				CustomFadeTransition.finishCallback = function() {
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		if (nextState == FlxG.state)
			FlxG.resetState();
		else
			FlxG.switchState(nextState);
	}

	inline public static function resetState() {
		MusicBeatState.switchState(FlxG.state);
	}

	inline public static function getState():MusicBeatState {
		return cast(FlxG.state, MusicBeatState);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
