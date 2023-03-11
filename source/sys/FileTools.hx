package sys;
import sys.FileStat;
import sys.FileSystem;

class FileTools {
    /**
     * Reads the directory AND all sub-directories aswell and KEEPS THEIR FULL PATHS unless toggled off!
     * @param path The path you want to read, must be a directory
     * @param onlyNewFolders If set to true, the old path will be ignored and only new relevant info will be returned.
     * @return A sorted Array of Strings representing the folders and underneath them their contents
     */
    public static function readDirectoryFull(path:String, onlyNewFolders:Bool = false):Array<String> {
        var content:Array<String> = [];
        var directoryContent:Array<String> = FileSystem.readDirectory(path);

        function folderCheck(file_:String) {
            content.push(file_);
            if(FileSystem.isDirectory(file_)) {
                final subFolder:Array<String> = FileSystem.readDirectory(file_);
                if(subFolder.length > 0) for(subFile in subFolder) { folderCheck('$file_/$subFile'); }
            }
        }
        for(file in directoryContent) { folderCheck('$path/$file'); }
        if(!onlyNewFolders) return content;

        var relevantContent:Array<String> = [];
        for(newStuff in content) { relevantContent.push(newStuff.replace('$path/', '')); }
        return relevantContent;
    }
}

//could be useful but for now arent
/*
typedef File = {
    var attributes:FileStat;
    var isFolder:Bool;
    var ?folderAttributes:Folder;
}

typedef Folder = {
    var name:String;
    var content:Array<File>;
    //var subFolders:Array<Folder>;
}*/