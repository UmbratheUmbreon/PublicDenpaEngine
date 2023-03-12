package;

import haxescript.Hscript;

class Modcharts {
	public var hscript:Hscript;
	public var strum:Int;
    public function new(name:String = 'none', strumNum:Int = 0) {
		if (strumNum > 1 || (name != 'none' && strumNum < 2))
			hscript = new Hscript(Paths.hscript('scripts/modcharts/$name'), true);
		this.strum = strumNum;
		if (hscript == null) return;
		hscript.call("onStartModchart", [strum]);
		PlayState.instance.hscripts.push(hscript);
    }

    public function changeModchart(newName:String = 'none') {
		PlayState.instance.hscripts.remove(hscript);
		if (hscript != null) {
			hscript.stop();
			hscript = null;
		}
		if (strum > 1 || (newName != 'none' && strum < 2))
			hscript = new Hscript(Paths.hscript('scripts/modcharts/$newName'), true);
		if (hscript == null) return;
		PlayState.instance.hscripts.push(hscript);
		hscript.call("onStartModchart", [strum]);
    }

	public function destroy() {
		changeModchart();
	}
}