package world;

import Constants.*;
import entities.Enemy;
import entities.Pickup;
import entities.Player;
import entities.Prop;
import entities.TntGoblin;
import entities.TorchGoblin;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import world.FloorMap;

/** Owns the instantiated floor: rooms, doors, activation, transitions. */
class RoomController
{
	public var floor(default, null):FloorMap;
	public var rooms(default, null):Map<Int, Room> = new Map();
	public var doors(default, null):Array<Door> = [];

	/** The active floor's doors (for the player's bridge footsteps). */
	public static var allDoors:Array<Door> = [];
	public var active(default, null):RoomNode;
	public var transitioning(default, null):Bool = false;
	public var onBossActivate:Void->Void;

	var player:Player;
	var enemies:FlxTypedGroup<Enemy>;
	var pickups:FlxTypedGroup<Pickup>;
	var roomDoors:Map<Int, Array<Door>> = new Map();

	/** Set by PlayState before build(): scattered props land here. */
	public var solidProps:FlxTypedGroup<Prop>;
	public var softProps:FlxTypedGroup<Prop>;
	public var campfires:FlxTypedGroup<entities.Campfire>;
	public var pedestals:FlxTypedGroup<entities.ItemPedestal>;
	public var shopItems:FlxTypedGroup<entities.ShopItem>;


	public function new(floor:FloorMap, player:Player, enemies:FlxTypedGroup<Enemy>, pickups:FlxTypedGroup<Pickup>)
	{
		this.floor = floor;
		this.player = player;
		this.enemies = enemies;
		this.pickups = pickups;
	}

	public function build():Void
	{
		allDoors = doors;
		for (n in floor.nodes)
		{
			if (n.owner != null)
				continue; // extra cells of a big room: the primary builds it
			var room = new Room(LdtkLoader.get(n.templateId), n.gx, n.gy);
			rooms.set(floor.key(n.gx, n.gy), room);
			var list = [];
			// one door per outward cell edge that has a neighbour
			for (j in 0...n.ch)
				for (i in 0...n.cw)
				{
					var cell = floor.get(n.gx + i, n.gy + j);
					if (cell == null)
						continue;
					for (dir in [FloorMap.N, FloorMap.E, FloorMap.S, FloorMap.W])
						if (cell.doors & dir != 0)
						{
							var dc = room.doorCell(dir, i, j);
							var door = new Door(room, dir, dc.cx, dc.cy);
							door.cell = cell;
							var nb = neighborCellOf(cell, dir);
							door.target = nb == null ? null : nb.primary();
							doors.push(door);
							list.push(door);
						}
				}
			roomDoors.set(floor.key(n.gx, n.gy), list);
			if (!gallery)
			{
				scatterProps(n, room);
				placeAuthored(room);
			}
		}
		// doors on either side of the shop need a key; doors into a secret room are hidden
		for (n in floor.nodes)
		{
			if (n.owner != null)
				continue;
			for (door in roomDoors.get(floor.key(n.gx, n.gy)))
			{
				var nb = door.target;
				if (n.kind == Shop || (nb != null && nb.kind == Shop))
					door.setKeyed();
				if (n.kind == Secret || (nb != null && nb.kind == Secret))
				{
					door.setSecret();
					// the tell: a lone water rock bobbing right where the hidden wall is
					if (n.kind != Secret && softProps != null)
						softProps.add(new Prop(door.room.worldX + door.cx * TILE, door.room.worldY + door.cy * TILE, WaterRock, 2));
				}
			}
		}
	}

	/** The grid cell on the far side of one of this cell's edges (may belong to a big room). */
	function neighborCellOf(cell:RoomNode, dir:Int):RoomNode
		return switch (dir)
		{
			case FloorMap.N: floor.get(cell.gx, cell.gy - 1);
			case FloorMap.S: floor.get(cell.gx, cell.gy + 1);
			case FloorMap.E: floor.get(cell.gx + 1, cell.gy);
			default: floor.get(cell.gx - 1, cell.gy);
		}

	/** The same doorway seen from the other room: the door on the neighbouring cell facing back. */
	function counterpart(n:RoomNode, door:Door):Door
	{
		if (door.target == null)
			return null;
		var back = switch (door.dir)
		{
			case FloorMap.N: FloorMap.S;
			case FloorMap.S: FloorMap.N;
			case FloorMap.E: FloorMap.W;
			default: FloorMap.E;
		}
		var far = neighborCellOf(door.cell, door.dir);
		for (d in roomDoors.get(floor.key(door.target.gx, door.target.gy)))
			if (d.dir == back && d.cell == far)
				return d;
		return null;
	}

	/** Seeded random decoration per room. Solid props keep a 1-cell gap from
	 * each other and never sit on doors, approaches, or entity spawns. */
	function scatterProps(node:RoomNode, room:Room):Void
	{
		if (solidProps == null)
			return;
		var g = room.template.ground;
		var TW = room.tw, TH = room.th;
		var taken = new Map<Int, Bool>();
		var RESERVED = room.reservedCells();
		for (c in RESERVED)
			taken.set(c[1] * TW + c[0], true);
		for (s in room.template.spawns)
			taken.set(s.cy * TW + s.cx, true);

		var grass = [], water = [];
		for (cy in 1...TH - 1)
			for (cx in 1...TW - 1)
			{
				var i = cy * TW + cx;
				if (taken.exists(i))
					continue;
				(g[i] == 1 ? grass : water).push({cx: cx, cy: cy});
			}
		// outer-ring water is fine for water rocks
		for (cy in [0, TH - 1])
			for (cx in 0...TW)
				if (g[cy * TW + cx] == 0 && !taken.exists(cy * TW + cx))
					water.push({cx: cx, cy: cy});

		FlxG.random.shuffle(grass);
		FlxG.random.shuffle(water);

		// start room stays clean: just grass and the training dummy.
		// Combat rooms get one light set of obstacles: destructible bushes,
		// indestructible rocks/trees, or a small mix of both.
		var solids = 0, bushes = 0;
		var authored = false;
		for (s in room.template.spawns)
			if (s.kind == "RockSpawn" || s.kind == "BushSpawn" || s.kind == "FireSpawn")
				authored = true;
		if (node.kind == Normal && !authored)
			switch (FlxG.random.int(0, 2))
			{
				case 0: bushes = FlxG.random.int(2, 3);
				case 1: solids = FlxG.random.int(2, 3);
				default:
					solids = FlxG.random.int(1, 2);
					bushes = FlxG.random.int(1, 2);
			}
		var cells = Std.int(TW / ROOM_TW) * Std.int(TH / ROOM_TH);
		solids *= cells;
		bushes = Std.int(bushes * LevelDefs.bushScale() * cells);
		var goldStones = node.kind == Normal && FlxG.random.bool(30) ? 1 : 0;
		if (LevelDefs.id() == "mines")
			goldStones += FlxG.random.int(2, 4); // the gold level
		var decos = switch (node.kind) { case Boss: FlxG.random.int(2, 3); case Start: 0; default: FlxG.random.int(1, 2); };
		var waterRocks = LevelDefs.isIndoor() ? 0 : switch (node.kind) { case Boss, Start: 0; default: FlxG.random.int(1, 2); };

		var solidCells = new Map<Int, Bool>();

		// anchors that must stay mutually reachable: grass reserved cells + spawns
		var anchors:Array<Int> = [];
		for (c in RESERVED)
			if (g[c[1] * TW + c[0]] == 1)
				anchors.push(c[1] * TW + c[0]);
		for (s in room.template.spawns)
			if (g[s.cy * TW + s.cx] == 1)
				anchors.push(s.cy * TW + s.cx);

		// flood fill over grass minus solid cells; all anchors must be reached
		function connected():Bool
		{
			if (anchors.length == 0)
				return true;
			var seen = new Map<Int, Bool>();
			var queue = [anchors[0]];
			seen.set(anchors[0], true);
			while (queue.length > 0)
			{
				var i = queue.pop();
				var cx = i % TW, cy = Std.int(i / TW);
				for (d in [[0, -1], [1, 0], [0, 1], [-1, 0]])
				{
					var nx = cx + d[0], ny = cy + d[1];
					if (nx < 0 || ny < 0 || nx >= TW || ny >= TH)
						continue;
					var ni = ny * TW + nx;
					if (seen.exists(ni) || g[ni] != 1 || solidCells.exists(ni))
						continue;
					seen.set(ni, true);
					queue.push(ni);
				}
			}
			for (a in anchors)
				if (!seen.exists(a))
					return false;
			return true;
		}

		function takeSolidCell(minCy:Int = 0, minCx:Int = 0, maxCx:Int = 99):Null<{cx:Int, cy:Int}>
		{
			var rejected = [];
			var found = null;
			while (grass.length > 0)
			{
				var c = grass.pop();
				if (c.cy < minCy || c.cx < minCx || c.cx > maxCx)
				{
					rejected.push(c);
					continue;
				}
				var i = c.cy * TW + c.cx;
				var nearSolid = false;
				for (dy in -1...2)
					for (dx in -1...2)
						if (solidCells.exists((c.cy + dy) * TW + c.cx + dx))
							nearSolid = true;
				if (nearSolid)
				{
					rejected.push(c);
					continue;
				}
				solidCells.set(i, true);
				if (connected())
				{
					found = c;
					break;
				}
				solidCells.remove(i); // would wall off part of the room
				rejected.push(c);
			}
			for (c in rejected)
				grass.unshift(c); // non-solid props can still use these cells
			return found;
		}

		function place(kind, variant:Int, solid:Bool):Void
		{
			// trees are 3 tiles tall: keep them out of the top rows so their
			// canopy never pokes into the view of the room above
			// tall/wide art keeps clear of the top rows and the island's side edges
			var c = solid ? switch (kind)
			{
				case Tree: takeSolidCell(3);
				case GoblinHut: takeSolidCell(3, 2, 11); // 192 px wide, 240 px tall
				case BlackBarracks, BlackMonastery: takeSolidCell(4, 3, 10);
				case BlackHouse, GnomeHut: takeSolidCell(3, 2, 11);
				case Castle: takeSolidCell(3, 3, 9);
				default: takeSolidCell(0);
			} : (grass.length > 0 ? grass.pop() : null);
			if (c == null)
				return;
			var p = new Prop(room.worldX + c.cx * TILE, room.worldY + c.cy * TILE, kind, variant);
			if (solid)
			{
				p.navRoom = room;
				p.navCell = c.cy * TW + c.cx;
			}
			(solid ? solidProps : softProps).add(p);
		}

		for (i in 0...solids)
		{
			var k = LevelDefs.solidKind();
			place(k, k == Rock ? FlxG.random.int(1, 4) : (k == SkullSpike ? FlxG.random.int(1, 2) : 1), true);
		}
		// goblin camp: one hut per combat room, top right, well clear of the doors
		if (node.kind == Normal && LevelDefs.id() == "camp")
			place(GoblinHut, 1, true);
		// Troy courtyards: a barracks or monastery plus a house; the mines: a gnome hut
		if (node.kind == Normal && LevelDefs.id() == "troy")
		{
			place(FlxG.random.bool(60) ? BlackBarracks : BlackMonastery, 1, true);
			place(BlackHouse, FlxG.random.int(1, 3), true);
		}
		if (node.kind == Normal && LevelDefs.id() == "mines" && FlxG.random.bool(70))
			place(GnomeHut, 1, true);
		for (i in 0...goldStones)
			place(GoldStone, FlxG.random.int(1, 3), true);
		for (i in 0...bushes)
			place(Bush, FlxG.random.int(1, 4), true);
		for (i in 0...decos)
			place(LevelDefs.decoKind(), LevelDefs.decoKind() == Bones ? FlxG.random.int(1, 3) : FlxG.random.int(1, 18), false);
		for (i in 0...waterRocks)
		{
			if (water.length == 0)
				break;
			var c = water.pop();
			softProps.add(new Prop(room.worldX + c.cx * TILE, room.worldY + c.cy * TILE, WaterRock, FlxG.random.int(1, 4)));
		}

		// campfire: ~40% of combat rooms get one
		if (campfires != null && node.kind == Normal && FlxG.random.bool(LevelDefs.campfireChance()))
		{
			var c = takeSolidCell();
			if (c != null)
			{
				var fire = new entities.Campfire(room.worldX + c.cx * TILE + 4, room.worldY + c.cy * TILE + 18);
				fire.navRoom = room;
				fire.navCell = c.cy * TW + c.cx;
				campfires.add(fire);
			}
		}

		room.buildNav([for (k in solidCells.keys()) k]);
	}

	public function roomOf(node:RoomNode):Room
	{
		var p = node.primary();
		return rooms.get(floor.key(p.gx, p.gy));
	}

	/** Enter a room: mark visited, spawn its enemies (first visit, uncleared), lock doors if combat. */
	/** Debug: combat rooms count as pre-cleared (boss room unaffected). */
	public static var debugAutoClear:Bool = false;
	/** Debug gallery floor: no props, no spawns. */
	public static var gallery:Bool = false;

	public function activate(node:RoomNode):Void
	{
		node = node.primary();
		active = node;
		var firstVisit = !node.visited;
		node.visited = true;
		if (firstVisit && node.kind == Normal && player.campfireHeart && campfires != null)
			lightHeartFire(roomOf(node));
		if (firstVisit && node.kind == Normal)
			releaseGarrisons(roomOf(node));
		// a room with a hidden wall: the wall shivers once as you walk in
		for (door in roomDoors.get(floor.key(node.gx, node.gy)))
			if (door.secret && !door.revealed && node.kind != Secret)
			{
				var d = door;
				flixel.util.FlxTimer.wait(0.8, () ->
				{
					if (active != node)
						return;
					fx.PackFx.play("smoke", d.room.worldX + d.cx * TILE + TILE / 2, d.room.worldY + d.cy * TILE + TILE / 2, 0.8);
					fx.Sfx.play("door_open", 0.35, 0.1);
					fx.Juice.shake(0.002, 0.15);
				});
			}
		if (debugAutoClear && node.kind != Boss)
			node.cleared = true;
		var room = roomOf(node);
		FlxG.worldBounds.set(room.worldX - 128, room.worldY - 128, room.pxW + 256, room.pxH + 256);

		shopSlot = 0;
		if (!node.cleared)
		{
			var spawned = 0;
			// imported layouts can carry more spawns than the level wants: keep a random subset
			var cap = LevelDefs.enemyCap(node.cw * node.ch);
			var enemySpawns = [for (s in room.template.spawns) if (s.kind == "TorchSpawn" || s.kind == "TntSpawn") s];
			FlxG.random.shuffle(enemySpawns);
			var allowed = enemySpawns.slice(0, Std.int(Math.min(cap, enemySpawns.length)));
			for (s in room.template.spawns)
			{
				var px = room.worldX + s.cx * TILE;
				var py = room.worldY + s.cy * TILE;
				if ((s.kind == "TorchSpawn" || s.kind == "TntSpawn") && allowed.indexOf(s) < 0)
					continue;
				switch (s.kind)
				{
					case "TorchSpawn": // generic melee spawn; the level decides the class
						var e = LevelDefs.spawnMelee(px + 10, py + 16);
						e.init(player);
						e.nav = room.navMap;
						enemies.add(e);
						spawned++;
					case "TntSpawn": // generic special spawn
						var e = LevelDefs.spawnSpecial(px + 10, py + 16);
						e.init(player);
						e.nav = room.navMap;
						enemies.add(e);
						spawned++;
					case "MeatSpawn":
						pickups.add(new Pickup(px, py, Meat));
					case "GoldSpawn":
						pickups.add(new Pickup(px, py, Gold));
					case "HutSpawn":
						if (solidProps != null)
							solidProps.add(new Prop(px, py, Hut));
					case "CastleSpawn":
						if (solidProps != null)
						{
							var castle = new Prop(px, py, Castle);
							castle.navRoom = room;
							solidProps.add(castle);
							// block the 4x2 tiles under the keep in the nav grid so walkers path around it
							for (dy in -1...1)
								for (dx in -2...2)
									room.blockNavCell((s.cy + dy) * room.tw + s.cx + dx);
						}
					case "ShopSpawn":
						if (shopItems != null)
							shopItems.add(makeStock(px, py, shopSlot++));
					case "ItemSpawn":
						var def = items.ItemPool.draw();
						if (def != null && pedestals != null)
							pedestals.add(new entities.ItemPedestal(px, py, def));
						else
							pickups.add(new Pickup(px, py, Meat)); // pool exhausted
					case "BossSpawn":
						if (onBossActivate != null)
						{
							onBossActivate();
							spawned++;
						}
					case "PlayerSpawn":
				}
			}
			// later floors: one extra torch goblin per combat room, away from the doors (within the cap)
			if (node.kind == Normal && spawned > 0 && spawned < cap && RunState.floorNumber() >= 1)
			{
				var spots = [[4, 2], [room.tw - 5, 2], [4, room.th - 3], [room.tw - 5, room.th - 3]];
				var c = spots[FlxG.random.int(0, spots.length - 1)];
				var spot = snapToGrass(room.worldX + c[0] * TILE + 32, room.worldY + c[1] * TILE + 32);
				var e = LevelDefs.spawnMelee(spot.x - 22, spot.y - 16);
				e.init(player);
				e.nav = room.navMap;
				enemies.add(e);
			}
			if (spawned == 0)
				node.cleared = true;
			else
				fx.Sfx.play("door_lock", 0.6);
		}
		refreshLocks();
	}

	var shopSlot:Int = 0;

	/** Shop stock by slot: meat, then bombs or a key, then a run item. */
	function makeStock(px:Float, py:Float, slot:Int):entities.ShopItem
	{
		return switch (slot)
		{
			case 0: new entities.ShopItem(px, py, price(5), Meat);
			case 1: FlxG.random.bool(50) ? new entities.ShopItem(px, py, price(8), Bomb, 2) : new entities.ShopItem(px, py, price(8), Key);
			default:
				var def = items.ItemPool.draw();
				def != null ? new entities.ShopItem(px, py, price(FlxG.random.int(15, 25)), null, 1, def)
					: new entities.ShopItem(px, py, price(5), Meat);
		}
	}

	/** Rooms drawn by hand (Isaac imports): rocks, bushes and campfires at their template cells. */
	function placeAuthored(room:Room):Void
	{
		if (solidProps == null)
			return;
		for (s in room.template.spawns)
		{
			var wx = room.worldX + s.cx * TILE, wy = room.worldY + s.cy * TILE;
			var cell = s.cy * room.tw + s.cx;
			switch (s.kind)
			{
				case "RockSpawn":
					var k = LevelDefs.solidKind();
					if (k != Rock && k != Tree && k != SkullSpike)
						k = Rock;
					var p = new Prop(wx, wy, k, k == Rock ? FlxG.random.int(1, 4) : (k == SkullSpike ? FlxG.random.int(1, 2) : 1));
					p.navRoom = room;
					p.navCell = cell;
					room.blockNavCell(cell);
					solidProps.add(p);
				case "BushSpawn":
					if (LevelDefs.bushScale() > 0)
					{
						var p = new Prop(wx, wy, Bush, FlxG.random.int(1, 4));
						p.navRoom = room;
						p.navCell = cell;
						room.blockNavCell(cell);
						solidProps.add(p);
					}
				case "FireSpawn":
					if (campfires != null)
					{
						var fire = new entities.Campfire(wx + 4, wy + 18);
						fire.navRoom = room;
						fire.navCell = cell;
						room.blockNavCell(cell);
						campfires.add(fire);
					}
			}
		}
	}

	/** Buildings that hold a unit: a Black Barracks releases a Black Knight, a Gnome Hut a Gnome. */
	function releaseGarrisons(room:Room):Void
	{
		if (solidProps == null || enemies == null)
			return;
		solidProps.forEachAlive(p ->
		{
			if (p.x < room.worldX || p.x >= room.worldX + room.pxW || p.y < room.worldY || p.y >= room.worldY + room.pxH)
				return;
			var e:Enemy = switch (p.kind)
			{
				case BlackBarracks: new entities.BlackKnight(p.x + p.width / 2 - 22, p.y + p.height + 6);
				case GnomeHut: new entities.Gnome(p.x + p.width / 2 - 22, p.y + p.height + 6);
				default: null;
			}
			if (e == null)
				return;
			e.init(player);
			e.nav = room.navMap;
			enemies.add(e);
			fx.PackFx.play("smoke", e.x + 22, e.y + 16, 1.0);
		});
	}

	/** Campfire Heart: a fire on the first free grass cell near the room's centre. */
	function lightHeartFire(room:Room):Void
	{
		var cx0 = Std.int(room.tw / 2), cy0 = Std.int(room.th / 2) - 1;
		for (r in 0...4)
			for (dy in -r...r + 1)
				for (dx in -r...r + 1)
				{
					var cx = cx0 + dx, cy = cy0 + dy;
					if (cx < 2 || cy < 2 || cx >= room.tw - 2 || cy >= room.th - 2)
						continue;
					var cell = cy * room.tw + cx;
					if (room.template.collision[cell] != 0 || (room.navMap != null && room.navMap.getTileIndex(cell) != 0))
						continue;
					var fire = new entities.Campfire(room.worldX + cx * TILE + 4, room.worldY + cy * TILE + 18);
					fire.navRoom = room;
					fire.navCell = cell;
					room.blockNavCell(cell);
					campfires.add(fire);
					fx.PackFx.play("sparkle", fire.x + fire.width / 2, fire.y + fire.height / 2, 1.0);
					return;
				}
	}

	/** Merchant's Ledger discount, never below 1 gold. */
	inline function price(base:Int):Int
		return Std.int(Math.max(1, Math.round(base * player.shopDiscount)));

	public function refreshLocks():Void
	{
		if (active == null)
			return;
		var living = 0;
		enemies.forEachAlive(e -> if (!e.harmless) living++);
		if (!active.cleared && living <= 0)
		{
			active.cleared = true;
			fx.Sfx.play("door_open", 0.6);
			player.monkHeal();
			player.chargeActive();
			maybeDropReward();
		}
		for (door in roomDoors.get(floor.key(active.gx, active.gy)))
			door.setLocked(!active.cleared || (door.keyed && !door.keyOpen) || (door.secret && !door.revealed));
	}

	/** Nearest grass-tile centre to a world point in the active room, so drops never land in water. */
	public function snapToGrass(px:Float, py:Float):{x:Float, y:Float}
	{
		var room = roomOf(active);
		var g = room.template.ground;
		var cx = Std.int((px - room.worldX) / TILE), cy = Std.int((py - room.worldY) / TILE);
		var best = null, bd = 1e12;
		for (ty in 1...room.th - 1)
			for (tx in 1...room.tw - 1)
			{
				if (g[ty * room.tw + tx] != 1)
					continue;
				var d = (tx - cx) * (tx - cx) + (ty - cy) * (ty - cy);
				if (d < bd)
				{
					bd = d;
					best = {x: room.worldX + tx * TILE + TILE / 2, y: room.worldY + ty * TILE + TILE / 2};
				}
			}
		return best != null ? best : {x: px, y: py};
	}

	/** Cleared a combat room: 75% chance of a key, gold, or bombs at the player's feet. */
	function maybeDropReward():Void
	{
		if (!FlxG.random.bool(75))
			return;
		var spot = snapToGrass(player.x + player.width / 2, player.y + player.height / 2);
		var px = spot.x - 16 + FlxG.random.float(-12, 12);
		var py = spot.y - 16;
		switch (FlxG.random.int(0, 2))
		{
			case 0: // money
				if (entities.Prop.coins != null)
					for (i in 0...Math.round(FlxG.random.int(3, 5) * player.goldBonus))
						entities.Prop.coins.recycle(entities.Coin.new).drop(px, py);
			case 1:
				pickups.add(new Pickup(px, py, Bomb));
			default:
				pickups.add(new Pickup(px, py, Key));
		}
	}

	/** Hidden walls: lean on one (stand pressed against it, room cleared) for 3 s to open it. */
	public function leanOnWalls(elapsed:Float):Void
	{
		if (active == null || transitioning)
			return;
		for (door in roomDoors.get(floor.key(active.gx, active.gy)))
		{
			if (!door.secret || door.revealed)
				continue;
			if (door.leanOn(elapsed, active.cleared && door.leaningOn(player)))
			{
				var other = counterpart(active, door);
				if (other != null)
					other.reveal();
				var nb = door.target;
				if (nb != null)
					nb.revealed = true;
				refreshLocks();
			}
		}
	}

	public function checkTransition():Void
	{
		if (transitioning || active == null)
			return;
		for (door in roomDoors.get(floor.key(active.gx, active.gy)))
		{
			// barred shop door: spend a key when the player walks up to it
			if (door.keyed && !door.keyOpen && active.cleared && player.keys > 0 && door.nearPlayer(player))
			{
				player.keys--;
				fx.Sfx.play("key", 0.8);
				door.keyOpen = true;
				var other = counterpart(active, door);
				if (other != null)
					other.keyOpen = true;
				fx.PackFx.play("sparkle", door.room.worldX + door.cx * TILE + TILE / 2, door.room.worldY + door.cy * TILE + TILE / 2);
				refreshLocks();
			}
			if (!door.overlapsPlayer(player))
				continue;
			if (door.target != null)
				transition(door.target, door);
			break;
		}
	}

	/** Debug: walk through whichever door of the active room leads to `next`. */
	public function transitionToward(next:RoomNode):Void
	{
		for (door in roomDoors.get(floor.key(active.gx, active.gy)))
			if (door.target == next.primary())
			{
				transition(next, door);
				return;
			}
	}

	function transition(next:RoomNode, through:Door):Void
	{
		transitioning = true;
		player.inputLocked = true;
		player.velocity.set(0, 0);

		// clear leftovers from the old room
		for (e in enemies)
			e.kill();
		enemies.clear();

		var room = roomOf(next);
		// land just inside the matching door of the new room
		var other = counterpart(active, through);
		var cx = other != null ? other.cx : Std.int(room.tw / 2), cy = other != null ? other.cy : Std.int(room.th / 2);
		var dir = other != null ? other.dir : through.dir;
		switch (dir)
		{
			case FloorMap.N: cy += 1;
			case FloorMap.S: cy -= 1;
			case FloorMap.E: cx -= 1;
			default: cx += 1;
		}
		var target = {x: room.worldX + cx * TILE + 10, y: room.worldY + cy * TILE + 16};
		player.setPosition(target.x, target.y);

		FlxG.camera.setScrollBounds(null, null, null, null);
		FlxG.camera.follow(null);
		// where the camera will rest in the new room (centred on the hero for big rooms)
		var sx = Math.max(room.worldX, Math.min(room.worldX + room.pxW - FlxG.width, target.x - FlxG.width / 2));
		var sy = Math.max(room.worldY - HUD_H, Math.min(room.worldY + room.pxH - FlxG.height, target.y - FlxG.height / 2));
		FlxTween.tween(FlxG.camera.scroll, {x: sx, y: sy}, 0.45, {
			ease: FlxEase.quadInOut,
			onComplete: _ ->
			{
				clampCamera(room);
				player.inputLocked = false;
				transitioning = false;
				activate(next);
			}
		});
	}

	public function clampCamera(room:Room):Void
	{
		FlxG.camera.setScrollBounds(room.worldX, room.worldX + room.pxW, room.worldY - HUD_H, room.worldY + room.pxH);
		if (room.pxW > FlxG.width || room.pxH + HUD_H > FlxG.height)
		{
			// room bigger than the screen: the camera tracks the hero inside it
			FlxG.camera.follow(player, TOPDOWN, 1);
			FlxG.camera.snapToTarget();
		}
		else
		{
			FlxG.camera.follow(null);
			FlxG.camera.scroll.set(room.worldX, room.worldY - HUD_H);
		}
		// quadtree bounds must cover the active room or overlap/collide go blind
		FlxG.worldBounds.set(room.worldX - 128, room.worldY - 128, room.pxW + 256, room.pxH + 256);
	}
}
