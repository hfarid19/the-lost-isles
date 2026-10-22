package world;

enum RoomKind
{
	Start;
	Normal;
	Treasure;
	Shop;
	Secret;
	Boss;
}

class RoomNode
{
	public var gx:Int;
	public var gy:Int;
	public var kind:RoomKind = Normal;
	public var templateId:String = null;
	public var doors:Int = 0; // bitmask N=1, E=2, S=4, W=8
	public var cleared:Bool = false;
	public var visited:Bool = false;
	public var revealed:Bool = false; // secret rooms: the wall has been bombed open
	/** Size in grid cells (big rooms span 2x1, 1x2 or 2x2 cells; this is the top-left cell). */
	public var cw:Int = 1;
	public var ch:Int = 1;
	/** For the extra cells of a big room: the node that owns the room. Null on the primary cell. */
	public var owner:RoomNode = null;

	public inline function primary():RoomNode
		return owner == null ? this : owner;

	public function new(gx:Int, gy:Int)
	{
		this.gx = gx;
		this.gy = gy;
	}
}

class FloorMap
{
	public static inline var N:Int = 1;
	public static inline var E:Int = 2;
	public static inline var S:Int = 4;
	public static inline var W:Int = 8;

	public var nodes(default, null):Map<Int, RoomNode> = new Map();
	public var start(default, null):RoomNode;

	public function new() {}

	public inline function key(gx:Int, gy:Int):Int
		return gy * Constants.FLOOR_GRID + gx;

	public function get(gx:Int, gy:Int):RoomNode
		return nodes.get(key(gx, gy));

	public function place(gx:Int, gy:Int):RoomNode
	{
		var n = new RoomNode(gx, gy);
		nodes.set(key(gx, gy), n);
		if (start == null)
		{
			start = n;
			n.kind = Start;
		}
		return n;
	}

	public function neighborCount(gx:Int, gy:Int):Int
	{
		var c = 0;
		if (get(gx, gy - 1) != null) c++;
		if (get(gx + 1, gy) != null) c++;
		if (get(gx, gy + 1) != null) c++;
		if (get(gx - 1, gy) != null) c++;
		return c;
	}

	/** Doors per cell; an edge shared by two cells of the same big room gets none. */
	public function computeDoors():Void
	{
		for (n in nodes)
		{
			n.doors = 0;
			var p = n.primary();
			var up = get(n.gx, n.gy - 1), right = get(n.gx + 1, n.gy), down = get(n.gx, n.gy + 1), left = get(n.gx - 1, n.gy);
			if (up != null && up.primary() != p) n.doors |= N;
			if (right != null && right.primary() != p) n.doors |= E;
			if (down != null && down.primary() != p) n.doors |= S;
			if (left != null && left.primary() != p) n.doors |= W;
		}
	}

	public function toAscii():String
	{
		var g = Constants.FLOOR_GRID;
		var out = "";
		for (gy in 0...g)
		{
			var line = "";
			for (gx in 0...g)
			{
				var n = get(gx, gy);
				line += n == null ? "." : switch (n.kind)
				{
					case Start: "S";
					case Boss: "B";
					case Treasure: "T";
					case Shop: "$";
					case Secret: "?";
					case Normal: "#";
				};
			}
			out += line + "\n";
		}
		return out;
	}
}
