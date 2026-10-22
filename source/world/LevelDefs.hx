package world;

import entities.Enemy;
import entities.Prop.PropKind;
import flixel.FlxG;

/** Per-level content: tileset, look, obstacle style, and which enemies the room
 * templates' generic spawns (melee 'T', special 'N') and the boss room turn into. */
class LevelDefs
{
	public static function id():String
		return RunState.levels[RunState.level].id;

	public static function idAt(level:Int):String
		return RunState.levels[Std.int(Math.min(level, RunState.levels.length - 1))].id;

	public static function tileset():String
		return switch (id())
		{
			case "forest": "assets/images/tiles/tilemap_forest.png";
			case "camp": "assets/images/tiles/tilemap_camp.png";
			case "caves": "assets/images/tiles/tilemap_caves.png";
			case "bamboo": "assets/images/tiles/tilemap_bamboo.png";
			case "troy": "assets/images/tiles/tilemap_troy.png";
			case "mines": "assets/images/tiles/tilemap_mines.png";
			default: "assets/images/tiles/tilemap_flat.png";
		}

	/** Caves: black void instead of water, no foam, no clouds, darkness overlay. */
	public static function isIndoor():Bool
		return id() == "caves";

	/** Indestructible obstacle kind and how often trees replace rocks. */
	public static function solidKind():PropKind
		return switch (id())
		{
			case "forest", "bamboo": Tree;
			case "waters", "mines": Rock;
			case "troy": FlxG.random.bool(30) ? Tree : Rock;
			case "camp": Fence;
			case "caves": SkullSpike;
			default: FlxG.random.bool(45) ? Tree : Rock;
		}

	/** Destructible bushes per room (0 in the caves). */
	public static function bushScale():Float
		return switch (id()) { case "caves": 0; case "waters": 0.4; case "troy": 0.5; default: 1; }

	public static function decoKind():PropKind
		return id() == "caves" ? Bones : Deco;

	/** Blossom recolours of the tree and bushes on the Bamboo Isle. */
	public static function propSuffix():String
		return id() == "bamboo" ? "_pink" : "";

	public static function campfireChance():Int
		return switch (id())
		{
			case "bamboo": 25;
			case "waters": 10;
			case "troy": 20;
			case "mines": 30;
			case "camp": 80;
			case "caves": 20;
			default: 40;
		}

	public static function spawnMelee(x:Float, y:Float):Enemy
		return spawnMeleeFor(id(), x, y);

	static function spawnMeleeFor(lv:String, x:Float, y:Float):Enemy
		return switch (lv)
		{
			case "keep": spawnMeleeFor(["plains", "forest", "camp", "caves"][FlxG.random.int(0, 3)], x, y);
			case "forest": FlxG.random.bool(50) ? new entities.Snake(x, y) : new entities.Gnome(x, y);
			case "bamboo":
				var r = FlxG.random.int(0, 9);
				if (r < 4) new entities.Thief(x, y) else if (r < 7) new entities.Snake(x, y) else if (r < 9) new entities.Turtle(x, y) else new entities.PandaGuard(x, y);
			case "waters":
				var r = FlxG.random.int(0, 9);
				if (r < 5) new entities.Thief(x, y) else if (r < 8) new entities.Snake(x, y) else new entities.Turtle(x, y);
			case "troy":
				var r = FlxG.random.int(0, 9);
				if (r < 4) new entities.BlackKnight(x, y) else if (r < 7) new entities.BlackLancer(x, y) else if (r < 9) new entities.BlackArcher(x, y) else new entities.BlackPawn(x, y);
			case "mines":
				var r = FlxG.random.int(0, 9);
				if (r < 4) new entities.Gnome(x, y) else if (r < 6) new entities.SlingshotGnome(x, y) else if (r < 8) new entities.Turtle(x, y) else new entities.MinoGuard(x, y);
			case "camp":
				var r = FlxG.random.int(0, 9);
				if (RunState.floor >= 1 && r < 2) new entities.SpearGoblinElite(x, y)
				else if (r < 6) new entities.SpearGoblin(x, y)
				else if (r < 8) new entities.TorchGoblin(x, y)
				else new entities.BarrelGoblin(x, y);
			case "caves":
				var r = FlxG.random.int(0, 9);
				if (r < 4) new entities.Thief(x, y) else if (r < 7) new entities.Skull(x, y) else if (r < 9) new entities.Imp(x, y) else new entities.MinoGuard(x, y);
			default: FlxG.random.bool(80) ? new entities.TorchGoblin(x, y) : new entities.Pig(x, y);
		}

	public static function spawnSpecial(x:Float, y:Float):Enemy
		return switch (id())
		{
			case "keep": spawnMeleeFor(["plains", "forest", "camp", "caves"][FlxG.random.int(0, 3)], x, y);
			case "forest", "bamboo": FlxG.random.bool(50) ? new entities.Bumblebee(x, y) : new entities.SlingshotGnome(x, y);
			case "camp": switch (FlxG.random.int(0, 2))
				{
					case 0: new entities.Cannon(x, y);
					case 1: new entities.Pig(x, y);
					default: new entities.TntGoblin(x, y);
				}
			case "caves": new entities.Bat(x, y);
			case "waters":
				var r = FlxG.random.int(0, 9);
				if (r < 3) new entities.HarpoonShark(x, y) else if (r < 5) new entities.BombFish(x, y) else if (r < 7) new entities.PaddleShark(x, y)
				else if (r < 9) new entities.SeahorseRider(x, y) else new entities.PirateTower(x, y);
			case "troy":
				var r = FlxG.random.int(0, 9);
				if (r < 4) new entities.BlackTower(x, y) else if (r < 7) new entities.BlackMonk(x, y, null) else new entities.BlackArcher(x, y);
			case "mines":
				var r = FlxG.random.int(0, 9);
				if (r < 4) new entities.GoldMine(x, y) else if (r < 7) new entities.Bat(x, y) else new entities.GnomeTower(x, y);
			default: new entities.TntGoblin(x, y);
		}

	/** Boss pool per level (first entry is the level's own boss). A floor never
	 * rolls the boss the previous floor had, so the same fight can't repeat. */
	static function bossPool():Array<String>
		return switch (id())
		{
			case "forest": ["bear", "lizard", "spider"];
			case "camp": ["shaman", "warlord", "hut"];
			case "caves": ["minotaur", "skullguard", "giantbat"];
			case "bamboo": ["panda", "pandaguard"];
			case "waters": ["harpoonshark", "paddleshark", "bombfish"];
			case "troy": ["blackcaptain", "blackchampion", "blackabbot"];
			case "mines": ["gnometower", "giantslingshot", "turtleguard"];
			case "keep": ["blackking"];
			default: ["troll", "gnoll", "bigtorch"];
		}

	/** Debug: force the next boss roll. */
	public static var forceBoss:String = null;

	public static function spawnBoss(x:Float, y:Float):entities.BossBase
	{
		var pool = bossPool().filter(b -> b != RunState.lastBoss);
		if (forceBoss != null)
		{
			pool = [forceBoss];
			forceBoss = null;
		}
		if (pool.length == 0)
			pool = bossPool();
		var pick = pool[FlxG.random.int(0, pool.length - 1)];
		RunState.lastBoss = pick;
		RunState.currentBoss = pick;
		return switch (pick)
		{
			case "shaman": new entities.HexShaman(x, y);
			case "minotaur": new entities.Minotaur(x, y);
			case "blackking": new entities.BlackKing(x, y);
			case "panda": new entities.PandaBoss(x, y);
			case "pandaguard": new entities.PandaGuard(x, y, true);
			case "harpoonshark": new entities.HarpoonShark(x, y, true);
			case "paddleshark": new entities.PaddleShark(x, y, true);
			case "bombfish": new entities.BombFish(x, y, true);
			case "blackcaptain": new entities.BlackKing(x, y, true);
			case "blackchampion": new entities.BlackChampion(x, y);
			case "blackabbot": new entities.BlackAbbot(x, y);
			case "gnometower": new entities.GnomeTowerBoss(x, y);
			case "giantslingshot": new entities.GiantSlingshot(x, y);
			case "turtleguard": new entities.TurtleGuardBoss(x, y);
			case "troll": new entities.Troll(x, y);
			case "gnoll": new entities.Gnoll(x, y);
			case "bigtorch": new entities.GiantTorchGoblin(x, y);
			case "lizard": new entities.Lizard(x, y);
			case "spider": new entities.Spider(x, y);
			case "warlord": new entities.PigRiderWarlord(x, y);
			case "hut": new entities.GoblinHutBoss(x, y);
			case "skullguard": new entities.SkullGuard(x, y);
			case "giantbat": new entities.GiantBat(x, y);
			default: new entities.BearBoss(x, y);
		}
	}

	/** The Keep: bigger rooms (23x13) with plateaus, stairs and cliff drops. */
	public static function isKeep():Bool
		return id() == "keep";

	/** Footstep family for the level's ground. */
	public static function stepSound():String
		return switch (id())
		{
			case "caves", "keep", "troy", "mines": "step_stone";
			default: "step_dirt";
		}

	/** Room size in tiles for the current level; applied before the floor is generated. */
	public static function applyRoomSize():Void
	{
		if (isKeep())
			Constants.setRoomSize(23, 13);
		else
			Constants.setRoomSize(15, 9);
	}

	public static function templatePrefix():String
		return isKeep() ? "Keep_" : "Room_";

	/** Which Isaac stage each level draws its combat rooms from (tools/isaac_rooms.py export). */
	static function isaacStage():String
		return switch (id())
		{
			case "forest": "02";
			case "camp": "03";
			case "caves": "04";
			case "bamboo": "05";
			case "waters": "06";
			case "troy": "07";
			case "mines": "09";
			default: "01";
		}

	/** Combat-room templates for a room of cw x ch cells. The Keep keeps its own elevation rooms. */
	public static function normalTemplates(cw:Int = 1, ch:Int = 1):Array<String>
	{
		if (isKeep())
			return ["Keep_A", "Keep_B", "Keep_C", "Keep_D"];
		var pool = IsaacRooms.get(isaacStage(), cw, ch);
		if (pool == null || pool.length == 0)
			return ["Room_A", "Room_B", "Room_C", "Room_D", "Room_E", "Room_Pits"];
		// floor I of a level draws the easier layouts (Isaac's own rating), floor II anything
		if (RunState.floor == 0)
		{
			var easy = pool.filter(id -> IsaacRooms.difficulty.get(id) != null && IsaacRooms.difficulty.get(id) <= 5);
			if (easy.length >= 4)
				return easy;
		}
		return pool;
	}

	/** Most enemies a room spawns from its template (a big room gets two more per extra cell). */
	public static function enemyCap(cells:Int):Int
	{
		var base = switch (id())
		{
			case "plains": RunState.floor == 0 ? 3 : 4;
			case "forest": 4;
			default: 5;
		}
		return base + 2 * (cells - 1);
	}

	/** Big room shapes the level has templates for (none in the Keep). */
	public static function bigRoomSizes():Array<Array<Int>>
	{
		if (isKeep())
			return [];
		var out = [];
		for (sz in [[2, 1], [1, 2], [2, 2]])
		{
			var pool = IsaacRooms.get(isaacStage(), sz[0], sz[1]);
			if (pool != null && pool.length > 0)
				out.push(sz);
		}
		return out;
	}

	/** Leaving or entering the caves goes through a cave mouth, not the boat. */
	public static function caveTransition(fromLevel:Int, toLevel:Int):Bool
		return idAt(fromLevel) == "caves" || idAt(toLevel) == "caves";
}
