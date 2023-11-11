//ALL flixel related shit needs to go in here because macros cant import flash package stuff (and flixel is based a lot on flash)
#if !macro
import ClientPrefs.control;
import Paths;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
using CoolUtil.MapUtil;
#end

import haxe.*;
import haxe.ds.Vector as HaxeVector;

using StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#else
import openfl.utils.Assets as OpenFlAssets;
#end
#if (target.threaded && sys)
import sys.thread.Thread;
#end
