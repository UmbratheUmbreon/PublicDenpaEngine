package updates;

import flixel.FlxBasic;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.OneOfTwo; // imported because full name was too long for its use-case
import haxe.io.Bytes;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.FileTools;
import sys.io.File;

/**
 * Class that holds all the functionality for updating the game. Functions are (planned to) ran over OutdatedState
 */
class Updater extends FlxBasic {
    public var bytesDownloaded(get, default):String = '0 Bytes';
    function get_bytesDownloaded():String { return formatBytes(bytesDownloaded_); }
    var bytesDownloaded_:Float = 0;

    public var bytesRequired:String = '0 Bytes';
    var bytesRequired_:Float = 0; //internally set value

    public var progressPercent(get, null):Float = 0;

    public var onProgressDownload:ProgressEvent -> Void = null;
    public var onFinishUpdate:Void -> Void = null;
    var updateName:String = '0.8.0';

    public function new(updateName:String, autoStart:Bool = false) {
        super();

        this.updateName = updateName;
        if(autoStart) { start('https://github.com/UmbratheUmbreon/PublicDenpaEngine/releases/download/$updateName/updaterPackage.zip'); } //Format ZIP names to properly suit shit later bla bla
    }

    var zip:URLLoader;
    /**
     * Starts the downloading process of the new update zip assets.
     * @param zipWebPath The path to the GitHub located zip (must be RAW path!!!!)
     */
    public function start(zipWebPath:String) {
        zip = new URLLoader();
        zip.dataFormat = BINARY;

        zip.addEventListener(ProgressEvent.PROGRESS, onDownloadProgress);
        zip.addEventListener(Event.COMPLETE, onDownloadFinish);
        zip.load(new URLRequest(zipWebPath)); //Start download process

        FlxG.autoPause = false;
        new FlxTimer().start(0.1, function(tmr:FlxTimer) { 
            if(bytesRequired_ != 0) bytesRequired = formatBytes(bytesRequired_); 
            else tmr.reset(0.1);
        });
    }

    //Function called when the asset download has progressed, keeps track of the necessary progress variables.
    private function onDownloadProgress(result:ProgressEvent) {
        bytesDownloaded_ = result.bytesLoaded;
        bytesRequired_ = result.bytesTotal;
        //progressPercent = FlxMath.roundDecimal((bytesDownloaded_ / bytesRequired_) * 100, 2);
        if(onProgressDownload != null) onProgressDownload(result);
    }

    //Function called when the asset download has finished.
    private function onDownloadFinish(result:Event) {
        final tempPath:String = './assets/temp';
        if(!FileSystem.exists('${tempPath}/')) FileSystem.createDirectory('${tempPath}/');

        final convertedBytes:Bytes = cast (zip.data, ByteArray); //i hate how long this specific line took, so fucking much (took me ages to realize bytearray auto casts to bytes)
        if(FileSystem.exists('${tempPath}/updateRaw')) {
            for(file in FileSystem.readDirectory('${tempPath}/updateRaw')) {
                function folderCheck(del_File:String) //A recursive function to empty all folders to be deleted before deleting the actual folders to prevent crashes
                {
                    function emptyDirectory(directory:String):Void {
                        var contents = FileSystem.readDirectory(directory);
                        contents.push(directory); //make sure that lastly, the empty folder gets deleted

                        for(deleteFile in contents) { folderCheck(deleteFile); }
                    }

                    if(FileSystem.isDirectory(del_File)) {
                        try {
                            if(FileSystem.stat(del_File).size > 0) {
                                emptyDirectory(del_File);
                                return;
                            }
                            FileSystem.deleteDirectory(del_File);
                            return;   
                        }
                        catch(e) {
                            trace('$e, $del_File folder wasnt empty! Killing sub-folders!');

                            emptyDirectory(del_File);
                            return;
                        }
                    }
                    FileSystem.deleteFile(del_File);
                }
                folderCheck(file);
            }
        }
        File.saveBytes('${tempPath}/update.zip', convertedBytes);
        ZipHandler.saveUncompressed('${tempPath}/update.zip', '${tempPath}/updateRaw'); //automatically store stuff in updateRaw folder

        if(onFinishUpdate != null) onFinishUpdate();
        applyUpdate('${tempPath}/updateRaw'); //add 'exampleUpdate' to get to work
    }

    //Finalizes update process
    private function applyUpdate(folderPath:String) {
        final gamePath:String = haxe.io.Path.normalize(Sys.getCwd()).replace('\\', '/'); //Get the actual game path for anything we need to do outside of assets
        trace(gamePath);

        var replacePaths:Array<String> = [];
        var deletePaths:Array<String> = [];
        
        final exeName:String = lime.app.Application.current.meta.get('file');
        var hasExe:Bool = false;

        var filePaths:Array<String> = FileTools.readDirectoryFull(folderPath);
        for(file in filePaths) { 
            trace(file);
            inline function throwOut() { filePaths.remove(file); continue; }

            //Check for any folders that need to be created
            if(FileSystem.isDirectory(file) && !FileSystem.exists('$gamePath/$file')) { 
                FileSystem.createDirectory('$gamePath/$file');
                throwOut();
            }
            //Next check for specific files
            if(file.contains('fileSysCommands')) { //Metadata file
                final content:String = File.getContent(file).trim();
                var contentRaw:OneOfTwo<String, Array<String>> = content.contains('~') ? content.split('~') : content;

                if(contentRaw is Array) {
                    final contentSplit:Array<String> = cast contentRaw;

                    //First Set the paths that need to renamed/placed somewhere else
                    replacePaths = contentSplit[0].split(',');
                    while(replacePaths[replacePaths.length-1] == '') replacePaths.pop();

                    //Second set the paths that need to be deleted
                    trace(contentSplit[1]);
                    deletePaths = contentSplit[1].split(',');
                    trace(deletePaths);
                    while(deletePaths[deletePaths.length-1] == '') deletePaths.pop();
                    throwOut();
                }
                var targetArray:Array<String> = (cast(contentRaw, String).contains('->')) ? replacePaths : deletePaths; //detect if theres only replace or delete files
                for(content in cast(contentRaw, String).split(',')) { targetArray.push(content); }

                throwOut();
            }
            else if(file.contains('App')) { //Exe file exists?? awesome
                hasExe = true;
                throwOut();
            }
        }
        //Initialization done!!
        //Now we remove the files to be removed!
        for(file_ in deletePaths) {
            var file = file_.substring(2, file_.length);
            if(!FileSystem.exists('$gamePath/$file')) { trace('file "$gamePath/$file" does not exist, skipping deletion!'); continue; }
            
            function folderCheck(del_File:String) //A recursive function to empty all folders to be deleted before deleting the actual folders to prevent crashes
            {
                function emptyDirectory(directory:String):Void {
                    var contents = FileSystem.readDirectory(directory);
                    contents.push(directory); //make sure that lastly, the empty folder gets deleted

                    for(deleteFile in contents) { folderCheck(deleteFile); }
                }

                if(FileSystem.isDirectory(del_File)) {
                    try {
                        if(FileSystem.stat(del_File).size > 0) {
                            emptyDirectory(del_File);
                            return;
                        }
                        FileSystem.deleteDirectory(del_File);
                        return;   
                    }
                    catch(e) {
                        trace('$e, $del_File folder wasnt empty! Killing sub-folders!');

                        emptyDirectory(del_File);
                        return;
                    }
                }
                FileSystem.deleteFile(del_File);
            }
            folderCheck('$gamePath/$file');
        }

        var fullExePath:String = '$gamePath/$exeName.exe';
        //Then we move/rename paths or files!
        for(path in replacePaths) {
            var change_To:Array<String> = path.split('->');
            if(!FileSystem.exists('$gamePath/${change_To[0]}')) continue;
            if(path.contains(exeName)) {fullExePath = '$gamePath/${change_To[1]}';}

            var folderSep:Array<String> = change_To[1].split('/'); //current path seperated into its little bits
            var newFolder:String = '$gamePath/${change_To[1]}'.replace(folderSep[folderSep.length-1], ''); //we make sure to take out the last part
            if(!FileSystem.exists(newFolder)) FileSystem.createDirectory(newFolder);

            trace('$gamePath/${change_To[0]}');
            FileSystem.rename('$gamePath/${change_To[0]}'.trim(), '$gamePath/${change_To[1]}'.trim());
        }

        //Second last step -- lets put the actual files where they belong!
        for(file in filePaths) {
            final trueFile:String = file.replace('./assets/temp/updateRaw/example update/', ''); //Formatted file name!!
            if(trueFile == '') continue;
            if(FileSystem.isDirectory(file)) {
                if(!FileSystem.exists('$gamePath/$trueFile')) FileSystem.createDirectory('$gamePath/$trueFile');
                continue;
            }
            final fileBytes:Bytes = File.getBytes('$file');

            final folderSep:Array<String> = trueFile.split('/');
            final newFolder:String = '$gamePath/$trueFile'.replace(folderSep[folderSep.length-1], ''); //we make sure to take out the last part
            if(!FileSystem.exists(newFolder)) FileSystem.createDirectory(newFolder);

            File.saveBytes('$gamePath/$trueFile', fileBytes);
        }

        //LAST STEP, REPLACE EXE!!! (if there is one)
        if(!hasExe) return;
        if(!FileSystem.exists('./assets/temp/backUp')) FileSystem.createDirectory('./assets/temp/backUp');
        File.saveBytes('./assets/temp/backUp/BackupExe', File.getBytes(fullExePath));

        new sys.io.Process('$gamePath/UPDATE FINISHER.bat', []); //seperately replace exe obviously
        Sys.sleep(0.15);
        Sys.exit(1);
    }

    function get_progressPercent():Float { return FlxMath.roundDecimal((bytesDownloaded_ / bytesRequired_) * 100, 2); }

    private static final formatNames:Array<String> = ['Bytes', 'KB', 'MB', 'GB'];
    public static function formatBytes(bytes:Float):String {
        var temp_bytes:Float = bytes;
        for(i in 0...formatNames.length) {
            if(temp_bytes > 1024) temp_bytes /= 1024;
            else return '${FlxMath.roundDecimal(temp_bytes, 2)} ${formatNames[i]}';
        }
        return '$bytes';
    }


    //Old one for reference, has been scrapped because AT specifically wanted to keep track of progress which haxe.HTTP doesnt grant, i like the other one more anyways!
    /*private function start_haxeHTTP(zipWebPath:String):Void {
        var zip = new haxe.Http(zipWebPath);

        zip.onBytes = function (siteBytes:Bytes) { //return site info in bytes, since site should be purely the zip it should only return the zip bytes
            final tempPath:String = './assets/temp';
            if(!FileSystem.exists('${tempPath}/')) FileSystem.createDirectory('${tempPath}/');

            File.saveBytes('${tempPath}/update.zip', siteBytes);
            ZipHandler.saveUncompressed('${tempPath}/update.zip', '${tempPath}/updateRaw'); //automatically store stuff in updateRaw folder
        }

        zip.onError = function (error) {
            trace('couldnt download zip: $error');
            //do more
        }

        zip.request();
    }*/
}
