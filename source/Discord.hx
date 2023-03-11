package;

import Sys.sleep;
#if desktop
import discord_rpc.DiscordRpc;
#end

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

/**
* Class used to control Discord Rich Presence.
*/
class DiscordClient
{
	#if desktop
	public static var isInitialized:Bool = false;
	public function new()
	{
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "962137888961740890",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");

		while (true)
		{
			DiscordRpc.process();
			sleep(2);
		}

		DiscordRpc.shutdown();
	}
	
	public static function shutdown()
	{
		DiscordRpc.shutdown();
	}
	
	static function onReady()
	{
		DiscordRpc.presence({
			details: "Starting up...",
			state: null,
			largeImageKey: 'sun',
			largeImageText: "Denpa Engine"
		});
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		#if (target.threaded && sys)
		Main.threadPool.run(() -> {
			new DiscordClient();
		});
		#else
		trace("Discord Client shut down. (No threads available!)");
		return;
		#end
		trace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'sun',
			largeImageText: 'Version ${Main.denpaEngineVersion.version}',
			smallImageKey : smallImageKey,
			smallImageText: CoolUtil.toTitleCase(smallImageKey),
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp : Std.int(startTimestamp / 1000),
            endTimestamp : Std.int(endTimestamp / 1000)
		});
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State) {
		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});
	}
	#end
	#end
}
