package compiletime;

import haxe.macro.Context;
import haxe.macro.Expr;

class GameBuildTime
{
	public static macro function getBuildTime():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		var buildTime = Date.now().toString();

		fields.push({
			name: "buildTime",
			doc: null,
			meta: [],
			access: [Access.APublic, Access.AStatic],
			kind: FieldType.FProp("default", "null", macro:Dynamic, macro $v{buildTime}),
			pos: Context.currentPos()
		});

		return fields;
	}
}