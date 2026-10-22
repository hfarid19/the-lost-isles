package world;

import Constants.*;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tile.FlxTilemap;
import world.LdtkLoader.RoomTemplate;

/**
 * One room instanced into world space at grid slot (gx, gy).
 * Visuals: autotiled grass FlxTilemap over the global water backdrop.
 * Collision: invisible FlxTilemap where water/void is solid.
 */
class Room
{
	public var gx(default, null):Int;
	public var gy(default, null):Int;
	public var template(default, null):RoomTemplate;
	public var groundMap(default, null):FlxTilemap;
	public var collisionMap(default, null):FlxTilemap;
	/** Water Walker collision: like collisionMap, but one-tile-wide water pits are walkable. */
	public var pitMap(default, null):FlxTilemap;
	public var foam(default, null):FlxSpriteGroup;

	/** Raised plateau (elevation tiles) drawn over the ground; null when flat. */
	public var plateauMap(default, null):FlxTilemap;

	/** One-way cliff edges under each plateau's bottom row (stairs excluded):
	 * block bodies coming from below, let bodies above drop off. */
	public var tierWalls(default, null):flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxObject>;

	/** Cells that walkers must path around (cliff faces); stairs stay open. */
	var faceCells:Array<Int> = [];

	/** Water + solid props; used only for enemy pathfinding (never rendered).
	 * Built by RoomController after props are scattered. */
	public var navMap(default, null):FlxTilemap;

	public var worldX(get, never):Float;
	public var worldY(get, never):Float;

	/** Size in tiles and pixels: a whole multiple of the level's cell (15x9 islands, 23x13 in the Keep). */
	public var tw(default, null):Int;
	public var th(default, null):Int;
	public var pxW(get, never):Float;
	public var pxH(get, never):Float;

	inline function get_worldX():Float
		return gx * ROOM_W;

	inline function get_worldY():Float
		return gy * ROOM_H;

	inline function get_pxW():Float
		return tw * TILE;

	inline function get_pxH():Float
		return th * TILE;

	/** Door cells and their two approach cells on every cell edge, for every cell of the room. */
	public function reservedCells():Array<Array<Int>>
	{
		var out = [];
		var cellsX = Std.int(tw / ROOM_TW), cellsY = Std.int(th / ROOM_TH);
		for (i in 0...cellsX)
		{
			var cx = DOOR_N_X + i * ROOM_TW;
			out.push([cx, 0]); out.push([cx, 1]); out.push([cx, 2]);
			out.push([cx, th - 1]); out.push([cx, th - 2]); out.push([cx, th - 3]);
		}
		for (j in 0...cellsY)
		{
			var cy = DOOR_W_Y + j * ROOM_TH;
			out.push([0, cy]); out.push([1, cy]); out.push([2, cy]);
			out.push([tw - 1, cy]); out.push([tw - 2, cy]); out.push([tw - 3, cy]);
		}
		return out;
	}

	/** Tile of the door on side `dir` of the room's cell (i, j). */
	public function doorCell(dir:Int, i:Int, j:Int):{cx:Int, cy:Int}
		return switch (dir)
		{
			case FloorMap.N: {cx: DOOR_N_X + i * ROOM_TW, cy: 0};
			case FloorMap.S: {cx: DOOR_S_X + i * ROOM_TW, cy: th - 1};
			case FloorMap.E: {cx: tw - 1, cy: DOOR_E_Y + j * ROOM_TH};
			default: {cx: 0, cy: DOOR_W_Y + j * ROOM_TH};
		}

	public function new(template:RoomTemplate, gx:Int, gy:Int)
	{
		this.template = template;
		this.gx = gx;
		this.gy = gy;
		tw = template.width;
		th = template.height;

		groundMap = new FlxTilemap();
		// StartingIndex=1: map value n renders graphic frame n-1, so 0 = empty water.
		groundMap.loadMapFromArray(autotile(template.ground), tw, th,
			LevelDefs.tileset(), TILE, TILE, OFF, 1, 1, 0x40000000);
		groundMap.x = worldX;
		groundMap.y = worldY;
		groundMap.solid = false;

		collisionMap = new FlxTilemap();
		// Tile index 1 = solid; graphic irrelevant (invisible).
		collisionMap.loadMapFromArray(template.collision, tw, th,
			"assets/images/tiles/tilemap_flat.png", TILE, TILE, OFF, 0, 1, 1);
		collisionMap.x = worldX;
		collisionMap.y = worldY;
		collisionMap.visible = false;

		// pits = water not connected to the sea around the island (flood fill from the border)
		var pits = template.collision.copy();
		var sea = [for (i in 0...tw * th) false];
		var stack = [];
		for (cy in 0...th)
			for (cx in 0...tw)
				if ((cx == 0 || cy == 0 || cx == tw - 1 || cy == th - 1) && template.ground[cy * tw + cx] != 1)
				{
					sea[cy * tw + cx] = true;
					stack.push(cy * tw + cx);
				}
		while (stack.length > 0)
		{
			var i = stack.pop();
			var cx = i % tw, cy = Std.int(i / tw);
			for (d in [[1, 0], [-1, 0], [0, 1], [0, -1]])
			{
				var nx = cx + d[0], ny = cy + d[1];
				if (nx < 0 || ny < 0 || nx >= tw || ny >= th)
					continue;
				var j = ny * tw + nx;
				if (sea[j] || template.ground[j] == 1)
					continue;
				sea[j] = true;
				stack.push(j);
			}
		}
		for (i in 0...pits.length)
			if (template.collision[i] == 1 && template.ground[i] != 1 && !sea[i])
				pits[i] = 0;
		pitMap = new FlxTilemap();
		pitMap.loadMapFromArray(pits, tw, th, "assets/images/tiles/tilemap_flat.png", TILE, TILE, OFF, 0, 1, 1);
		pitMap.x = worldX;
		pitMap.y = worldY;
		pitMap.visible = false;

		// Door cells start solid; RoomController carves open doors.

		if (!LevelDefs.isIndoor())
			buildFoam();
		else
			foam = new FlxSpriteGroup();
		if (template.elevation != null)
			buildPlateau();
	}

	/** Elevation sheet (4 cols): 0-2 top edge, 4-6 middle, 8-10 bottom edge, col 3 =
	 * single-column variants, 12-14 cliff faces, 16-19 single-row, 29 stairs. */
	function buildPlateau():Void
	{
		var e = template.elevation;
		inline function raised(cx:Int, cy:Int):Bool
			return cx >= 0 && cy >= 0 && cx < tw && cy < th && e[cy * tw + cx] == 1;
		var grid:Array<Int> = [];
		tierWalls = new flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxObject>();
		for (cy in 0...th)
			for (cx in 0...tw)
			{
				var v = e[cy * tw + cx];
				var t = -1;
				if (v == 1)
				{
					var n = raised(cx, cy - 1), s = raised(cx, cy + 1), w = raised(cx - 1, cy), ea = raised(cx + 1, cy);
					if (!n && !s)
						t = (!w && !ea) ? 19 : (!w ? 16 : (!ea ? 18 : 17));
					else if (!w && !ea)
						t = !n ? 3 : (!s ? 11 : 7);
					else
						t = (!n ? 0 : (!s ? 8 : 4)) + (!w ? 0 : (!ea ? 2 : 1));
				}
				else if (v == 2)
					t = 29; // stair: walkable both ways
				else if (raised(cx, cy - 1))
				{
					// cliff face under a plateau's bottom edge
					t = !raised(cx - 1, cy - 1) ? 12 : (!raised(cx + 1, cy - 1) ? 14 : 13);
					faceCells.push(cy * tw + cx);
					var wall = new flixel.FlxObject(worldX + cx * TILE, worldY + cy * TILE + 20, TILE, 44);
					wall.immovable = true;
					tierWalls.add(wall);
				}
				grid.push(t + 1);
			}
		plateauMap = new FlxTilemap();
		plateauMap.loadMapFromArray(grid, tw, th, "assets/images/tiles/tilemap_elevation.png", TILE, TILE, OFF, 1, 1, 0x40000000);
		plateauMap.x = worldX;
		plateauMap.y = worldY;
		plateauMap.solid = false;
	}

	/** Animated water foam under every shoreline tile (drawn below groundMap).
	 * Each of the 16 foam frames is 192x192, designed to center under a 64px tile. */
	function buildFoam():Void
	{
		foam = new FlxSpriteGroup();
		var g = template.ground;
		for (cy in 0...th)
			for (cx in 0...tw)
			{
				if (g[cy * tw + cx] != 1)
					continue;
				var shore = false;
				for (dy in -1...2)
					for (dx in -1...2)
					{
						var nx = cx + dx, ny = cy + dy;
						if (nx < 0 || ny < 0 || nx >= tw || ny >= th || g[ny * tw + nx] == 0)
							shore = true;
					}
				if (!shore)
					continue;
				var s = new FlxSprite(worldX + cx * TILE - TILE, worldY + cy * TILE - TILE);
				s.loadGraphic("assets/images/vfx/water_foam.png", true, 192, 192);
				s.animation.add("foam", [for (i in 0...16) i], 10);
				s.animation.play("foam");
				foam.add(s);
			}
	}

	/** Mark a cell impassable for pathfinding (big solid props like the castle). */
	public function blockNavCell(cell:Int):Void
	{
		if (cell >= 0 && cell < tw * th && faceCells.indexOf(cell) < 0)
			faceCells.push(cell);
	}

	/** Clear collision at a tile so an open door's bridge is walkable. */
	public function carve(cx:Int, cy:Int):Void
	{
		collisionMap.setTileIndex(cy * tw + cx, 0);
		pitMap.setTileIndex(cy * tw + cx, 0);
		if (navMap != null)
			navMap.setTileIndex(cy * tw + cx, 0);
	}

	/** Build the pathfinding grid: room collision plus solid prop cells. */
	public function buildNav(solidCells:Array<Int>):Void
	{
		var data = template.collision.copy();
		for (cell in solidCells)
			data[cell] = 1;
		for (cell in faceCells)
			data[cell] = 1; // walkers go round the cliffs via the stairs
		navMap = new FlxTilemap();
		navMap.loadMapFromArray(data, tw, th,
			"assets/images/tiles/tilemap_flat.png", TILE, TILE, OFF, 0, 1, 1);
		navMap.x = worldX;
		navMap.y = worldY;
		navMap.visible = false;
	}

	/** A destructible solid prop died: its cell becomes walkable. */
	public function freeNavCell(cell:Int):Void
	{
		if (navMap != null)
			navMap.setTileIndex(cell, 0);
	}

	inline function autotile(ground:Array<Int>):Array<Int>
		return autotileGrid(ground, tw, th);

	/**
	 * 4-bit blob autotiling. tilemap_flat.png is a 10x4 sheet; the grass set
	 * occupies cols 0..3: 3x3 blob + vertical strip col 3 + horizontal strip
	 * row 3 + isolated tile at (3,3). Neighbor mask: N=1, E=2, S=4, W=8.
	 * Output uses StartingIndex=1 convention (0 = empty water).
	 */
	public static function autotileGrid(ground:Array<Int>, w:Int, h:Int):Array<Int>
	{
		var out = new Array<Int>();
		for (cy in 0...h)
			for (cx in 0...w)
			{
				if (ground[cy * w + cx] == 0)
				{
					out.push(0); // water: empty, backdrop shows through
					continue;
				}
				var mask = 0;
				if (cy > 0 && ground[(cy - 1) * w + cx] == 1) mask |= 1;
				if (cx < w - 1 && ground[cy * w + cx + 1] == 1) mask |= 2;
				if (cy < h - 1 && ground[(cy + 1) * w + cx] == 1) mask |= 4;
				if (cx > 0 && ground[cy * w + cx - 1] == 1) mask |= 8;
				out.push(MASK_TO_TILE[mask] + 1);
			}
		return out;
	}

	// Index = NESW neighbor-present mask, value = graphic frame (row * 10 + col).
	static final MASK_TO_TILE:Array<Int> = [
		33, // 0  none      -> isolated       (3,3)
		23, // 1  N         -> strip bottom   (3,2)
		30, // 2  E         -> strip left     (0,3)
		20, // 3  N+E       -> SW corner      (0,2)
		3,  // 4  S         -> strip top      (3,0)
		13, // 5  N+S       -> strip v-mid    (3,1)
		0,  // 6  E+S       -> NW corner      (0,0)
		10, // 7  N+E+S     -> W edge         (0,1)
		32, // 8  W         -> strip right    (2,3)
		22, // 9  N+W       -> SE corner      (2,2)
		31, // 10 E+W       -> strip h-mid    (1,3)
		21, // 11 N+E+W     -> S edge         (1,2)
		2,  // 12 S+W       -> NE corner      (2,0)
		12, // 13 N+S+W     -> E edge         (2,1)
		1,  // 14 E+S+W     -> N edge         (1,0)
		11, // 15 all       -> center         (1,1)
	];
}
