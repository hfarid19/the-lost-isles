package world;

import openfl.Assets;

typedef SpawnPoint =
{
	var kind:String; // PlayerSpawn, TorchSpawn, TntSpawn, BossSpawn, MeatSpawn, GoldSpawn, ItemSpawn, HutSpawn, ShopSpawn
	var cx:Int;
	var cy:Int;
}

typedef RoomTemplate =
{
	var id:String;
	var ground:Array<Int>; // 1 = grass, row-major 15x9
	var collision:Array<Int>; // 1 = solid (water)
	var spawns:Array<SpawnPoint>;
	var width:Int; // tiles
	var height:Int;
	@:optional var elevation:Array<Int>; // 1 = raised plateau, 2 = stair (Keep rooms)
}

/**
 * Thin runtime loader for assets/levels/rooms.ldtk (LDtk 1.5.3 JSON).
 * Reads only what the game needs: IntGrid CSVs + entity instances.
 */
class LdtkLoader
{
	public static var templates(default, null):Map<String, RoomTemplate> = null;

	public static function load():Void
	{
		if (templates != null)
			return;
		templates = new Map();
		var doc:Dynamic = haxe.Json.parse(Assets.getText("assets/levels/rooms.ldtk"));
		var levels:Array<Dynamic> = doc.levels;
		for (level in levels)
		{
			var t:RoomTemplate = {
				id: level.identifier, ground: null, collision: null, spawns: [],
				width: Std.int(level.pxWid / 64), height: Std.int(level.pxHei / 64)
			};
			var layers:Array<Dynamic> = level.layerInstances;
			for (layer in layers)
			{
				switch (layer.__identifier)
				{
					case "Ground":
						t.ground = layer.intGridCsv;
					case "Collision":
						t.collision = layer.intGridCsv;
					case "Height":
						t.elevation = layer.intGridCsv;
					case "Entities":
						var ents:Array<Dynamic> = layer.entityInstances;
						for (e in ents)
							t.spawns.push({kind: e.__identifier, cx: e.__grid[0], cy: e.__grid[1]});
				}
			}
			templates.set(t.id, t);
		}
	}

	public static function get(id:String):RoomTemplate
	{
		load();
		var t = templates.get(id);
		if (t == null)
			throw 'Unknown room template: $id';
		return t;
	}
}
