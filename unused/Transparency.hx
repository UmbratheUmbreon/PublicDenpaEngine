package;

@:native("HWND__") extern class HWNDStruct { }
typedef HWND = cpp.Pointer<HWNDStruct>;
typedef BOOL = Int;
typedef BYTE = Int;
typedef LONG = Int;
typedef DWORD = LONG;
typedef COLORREF = DWORD;

@:headerCode("#include <windows.h>")
class Transparency {
    @:native("FindWindowA") @:extern
    private static function findWindow(className:cpp.ConstCharStar, windowName:cpp.ConstCharStar) : HWND return null;

    @:native("SetWindowLongA") @:extern
    private static function setWindowLong(hWnd:HWND, nIndex:Int, dwNewLong:LONG) : LONG return null;

    @:native("SetLayeredWindowAttributes") @:extern
    private static function setLayeredWindowAttributes(hwnd:HWND, crKey:COLORREF, bAlpha:BYTE, dwFlags:DWORD) : BOOL return null;

    @:native("GetLastError") @:extern
    private static function getLastError() : DWORD return null;

    @:functionCode('
        printf("something not inline!\\n");
    ')
    public static function test() {}
    
    public static function setTransparency(winName:String, color:Int):Void {
        test();
        var win:HWND = findWindow(null, winName);
        if (win == null) {
            trace("Error finding window!");
            trace("Code: " + Std.string(getLastError()));
        }
        if (setWindowLong(win, -20, 0x00080000) == 0) {
            trace("Error setting window to be layered!");
            trace("Code: " + Std.string(getLastError()));
        }
        if (setLayeredWindowAttributes(win, color, 0, 0x00000001) == 0) {
            trace("Error setting color key on window!the onlu ");
            trace("Code: " + Std.string(getLastError()));
        }
    }
}