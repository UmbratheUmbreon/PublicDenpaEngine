package updates;

import haxe.Json;
import Paths;
import lime.utils.Assets;

typedef PatchFile = {
    var name:String;
    var version:Int;
    var description:String;
}

class PatchParser {
    public static function activate():PatchFile {
        if(sys.FileSystem.exists(Paths.update('NewestPatch.json')))
            return cast Json.parse(Assets.getText(Paths.update('NewestPatch.json')));

        return {name: "ERROR", version: 0, description: "No patch found. Contact the Denpa Engine discord!!"};
    }
}