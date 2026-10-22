package world;

import Constants.*;
import flixel.FlxG;
import world.FloorMap;

/** Isaac-style floor layout: BFS growth from center, specials at dead ends. */
class FloorGenerator
{
	public static function generate(target:Int = FLOOR_ROOMS):FloorMap
	{

		for (attempt in 0...50)
		{
			var map = tryGenerate(target);
			if (map != null)
				return map;
		}
		throw "Floor generation failed repeatedly";
	}

	/** Debug gallery: a block of empty, pre-cleared rooms (two rows east of the start) for sprite previews. */
	public static function gallery(count:Int):FloorMap
	{
		var map = new FloorMap();
		var c = Std.int(FLOOR_GRID / 2);
		var placed = 0;
		for (row in 0...FLOOR_GRID)
			for (x in c...FLOOR_GRID)
			{
				if (placed >= count) break;
				var y = row % 2 == 0 ? c - Std.int(row / 2) : c + Std.int((row + 1) / 2);
				map.place(x, y);
				placed++;
			}
		map.computeDoors();
		var pre = LevelDefs.templatePrefix();
		for (n in map.nodes)
		{
			n.templateId = pre + "Start";
			n.cleared = true;
		}
		return map;
	}

	/** Fuse adjacent combat cells into bigger rooms (Isaac's 2x1, 1x2 and 2x2 layouts), at most two per floor. */
	static function mergeBigRooms(map:FloorMap):Void
	{
		var sizes = LevelDefs.bigRoomSizes();
		if (sizes.length == 0)
			return;
		function free(n:RoomNode):Bool
			return n != null && n.owner == null && n.kind == Normal && n.cw == 1 && n.ch == 1;
		function has(cw:Int, ch:Int):Bool
		{
			for (s in sizes)
				if (s[0] == cw && s[1] == ch)
					return true;
			return false;
		}
		function fuse(p:RoomNode, others:Array<RoomNode>, cw:Int, ch:Int):Void
		{
			p.cw = cw;
			p.ch = ch;
			for (o in others)
			{
				o.owner = p;
				o.kind = Normal;
				o.templateId = null;
			}
		}
		var prims = [for (n in map.nodes) if (free(n)) n];
		FlxG.random.shuffle(prims);
		var merges = 0;
		for (n in prims)
		{
			if (merges >= 2 || !free(n))
				continue;
			var r = map.get(n.gx + 1, n.gy), d = map.get(n.gx, n.gy + 1), rd = map.get(n.gx + 1, n.gy + 1);
			if (has(2, 2) && free(r) && free(d) && free(rd) && FlxG.random.bool(35))
			{
				fuse(n, [r, d, rd], 2, 2);
				merges++;
			}
			else if (has(2, 1) && free(r) && FlxG.random.bool(45))
			{
				fuse(n, [r], 2, 1);
				merges++;
			}
			else if (has(1, 2) && free(d) && FlxG.random.bool(45))
			{
				fuse(n, [d], 1, 2);
				merges++;
			}
		}
	}

	static function tryGenerate(target:Int):FloorMap
	{
		var map = new FloorMap();
		var c = Std.int(FLOOR_GRID / 2);
		map.place(c, c);
		var queue = [map.start];
		var placed = 1;

		while (queue.length > 0 && placed < target)
		{
			var cell = queue.shift();
			var dirs = [[0, -1], [1, 0], [0, 1], [-1, 0]];
			FlxG.random.shuffle(dirs);
			for (d in dirs)
			{
				var nx = cell.gx + d[0], ny = cell.gy + d[1];
				if (nx < 0 || ny < 0 || nx >= FLOOR_GRID || ny >= FLOOR_GRID) continue;
				if (map.get(nx, ny) != null) continue;
				// the hero lands on the start room's west shore: nothing ever sits there
				if (nx == map.start.gx - 1 && ny == map.start.gy) continue;
				if (map.neighborCount(nx, ny) > 1) continue; // keep corridor-y layouts
				if (placed >= target || FlxG.random.bool(50)) continue;
				map.place(nx, ny);
				queue.push(map.get(nx, ny));
				placed++;
			}
			if (queue.length == 0 && placed < target)
				return null; // ran dry too early
		}
		if (placed < target)
			return null;

		// dead ends (exactly 1 neighbor), farthest first
		var deadEnds = [for (n in map.nodes) if (n != map.start && map.neighborCount(n.gx, n.gy) == 1) n];
		if (deadEnds.length < 3)
			return null; // boss, shop, treasure each need their own dead end
		deadEnds.sort((a, b) ->
		{
			var da = Math.abs(a.gx - map.start.gx) + Math.abs(a.gy - map.start.gy);
			var db = Math.abs(b.gx - map.start.gx) + Math.abs(b.gy - map.start.gy);
			return Std.int(db - da);
		});
		deadEnds[0].kind = Boss;
		deadEnds[1].kind = Shop;
		deadEnds[deadEnds.length - 1].kind = Treasure;

		// every floor: a secret room hidden behind one combat room's wall, never beside the boss
		{
			var spots = [];
			for (n in map.nodes)
			{
				if (n.kind != Normal)
					continue;
				for (d in [[0, -1], [1, 0], [0, 1], [-1, 0]])
				{
					var nx = n.gx + d[0], ny = n.gy + d[1];
					if (nx < 0 || ny < 0 || nx >= FLOOR_GRID || ny >= FLOOR_GRID || map.get(nx, ny) != null)
						continue;
					if (nx == map.start.gx - 1 && ny == map.start.gy)
						continue; // the landing shore stays clear
					// exactly one neighbour (this combat room), and never next to the boss room
					if (map.neighborCount(nx, ny) != 1)
						continue;
					var nearBoss = false;
					for (e in [[0, -1], [1, 0], [0, 1], [-1, 0]])
					{
						var m = map.get(nx + e[0], ny + e[1]);
						if (m != null && m.kind == Boss)
							nearBoss = true;
					}
					if (!nearBoss)
						spots.push([nx, ny]);
				}
			}
			if (spots.length > 0)
			{
				var sp = spots[FlxG.random.int(0, spots.length - 1)];
				var s = map.place(sp[0], sp[1]);
				s.kind = Secret;
			}
		}

		mergeBigRooms(map);
		map.computeDoors();

		// assign templates (big rooms draw from their own size's pool)
		var pre = LevelDefs.templatePrefix();
		var last = "";
		for (n in map.nodes)
		{
			if (n.owner != null)
				continue;
			n.templateId = switch (n.kind)
			{
				case Start: pre + "Start";
				case Boss: pre + "Boss";
				case Treasure: pre + "Treasure";
				case Shop: pre + "Shop";
				case Secret: pre + "Secret";
				case Normal:
					var normals = LevelDefs.normalTemplates(n.cw, n.ch);
					var pick = last;
					var guard = 0;
					while ((pick == last || pick == null) && guard++ < 20)
						pick = normals[FlxG.random.int(0, normals.length - 1)];
					last = pick;
					pick;
			};
		}
		return map;
	}
}
