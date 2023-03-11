package compiletime;

@:build(compiletime.GameBuildTime.getBuildTime())
class GameVersion
{
	public var release(default, null):Int;
	public var major(default, null):Int;
	public var minor(default, null):Int;
	public var patch(default, null):String;
	public var version(get, never):String;
	public var debugVersion(get, never):String;
	public var formatted(get, never):String;

	public function new(Release:Int, Major:Int, Minor:Int, Patch:String)
	{
		release = Release;
		major = Major;
		minor = Minor;
		patch = Patch;
	}

	function get_debugVersion():String
		return '$release.$major.$minor$patch (${GameVersion.buildTime})';

	function get_version():String
		return '$release.$major.$minor$patch';

	function get_formatted():String
		return 'Denpa v$release.$major.$minor$patch';
}