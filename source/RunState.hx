import entities.Player;

/** One run: which level and floor the player is on, and the hero's stats
 * carried between floors (PlayState builds a fresh Player per floor). */
class RunState
{
	static var allLevels:Array<{id:String, name:String, floors:Int}> = [
		{id: "plains", name: "Plains", floors: 2},
		{id: "forest", name: "Forest", floors: 2},
		{id: "camp", name: "Goblin Camp", floors: 2},
		{id: "caves", name: "Caves", floors: 2},
		{id: "bamboo", name: "Mystic Bamboo Isle", floors: 2},
		{id: "waters", name: "Shark Waters", floors: 2},
		{id: "troy", name: "Troy", floors: 2},
		{id: "mines", name: "Gnome Mines", floors: 2},
		{id: "keep", name: "The Keep", floors: 1},
	];

	/** This run's levels: the four base levels, any unlocked extra levels, then the Keep. */
	public static var levels(default, null):Array<{id:String, name:String, floors:Int}> = allLevels.filter(l -> ["plains", "forest", "camp", "caves", "keep"].indexOf(l.id) >= 0);

	public static function buildLevels(?ids:Array<String>):Void
	{
		if (ids == null)
			ids = ["plains", "forest", "camp", "caves"].concat(Unlocks.bambooUnlocked() ? ["bamboo"] : [])
				.concat(Unlocks.watersUnlocked() ? ["waters"] : []).concat(Unlocks.troyUnlocked() ? ["troy"] : [])
				.concat(Unlocks.minesUnlocked() ? ["mines"] : []).concat(["keep"]);
		levels = [for (id in ids) for (l in allLevels) if (l.id == id) l];
	}

	public static function levelIds():Array<String>
		return [for (l in levels) l.id];

	/** Set by PlayState before advancing: was the last transition a cave walk? */
	public static var caveWalk:Bool = false;

	/** Boss id of the previous floor, so the next floor never repeats it. */
	public static var lastBoss:String = "";

	/** Boss id spawned on this floor (set by LevelDefs.spawnBoss; drives the intro card). */
	public static var currentBoss:String = "";

	/** Monk unlock: finish a run without buying anything. */
	public static var boughtSomething:Bool = false;

	/** The floating shop between levels shows once per run. */
	public static var raftUsed:Bool = false;

	/** Weather rolled for the current floor: 0 clear, 1 rain, 2 storm. */
	public static var weather:Int = 0;

	// run summary for the game-over screen
	public static var kills:Int = 0;
	public static var damageTaken:Int = 0;
	public static var timeSec:Float = 0;
	public static var itemsTaken:Int = 0;
	public static var lastHitBy:String = "";

	/** A readable name for whatever last hurt the hero. */
	public static function describe(source:Dynamic):String
	{
		if (source == null)
			return "the sea";
		var cls = Type.getClassName(Type.getClass(source));
		var short = cls.split(".").pop();
		return switch (short)
		{
			case "Explosion": "an explosion";
			case "Campfire": "a campfire";
			case "EnemyShot": "a " + (Reflect.field(source, "kind") == "arrow" ? "black arrow" : (Reflect.field(source, "kind") == "harpoon" ? "harpoon" : "shot"));
			case "Dynamite": "dynamite";
			default:
				// CamelCase -> words: "GiantTorchGoblin" -> "Giant Torch Goblin"
				var words = ~/([a-z])([A-Z])/g.replace(short, "$1 $2");
				"the " + words;
		}
	}

	/** Seed to rebuild the saved floor with; 0 = fresh random floor. */
	public static var resumeSeed:Int = 0;

	static var runSave:flixel.util.FlxSave;

	public static function rebind():Void
		runSave = null;

	static function store():flixel.util.FlxSave
	{
		if (runSave == null)
		{
			runSave = new flixel.util.FlxSave();
			runSave.bind(SaveSlots.runName(SaveSlots.current));
		}
		return runSave;
	}

	/** Checkpoint: called at the start of every floor. Resuming restarts that floor. */
	public static function persist(p:Player, seed:Int):Void
	{
		save(p);
		var d = store().data;
		d.present = true;
		d.level = level;
		d.floor = floor;
		d.kind = Type.enumIndex(Player.selectedKind);
		d.lastBoss = lastBoss;
		d.floorName = floorName();
		d.seed = seed;
		d.pool = items.ItemPool.remainingIds();
		d.bought = boughtSomething;
		d.raft = raftUsed;
		d.weather = weather;
		d.levelIds = levelIds();
		d.stats = haxe.Json.stringify({kills: kills, dmg: damageTaken, t: timeSec, items: itemsTaken});
		d.carry = haxe.Json.stringify(carry);
		store().flush();
	}

	public static function hasSavedRun():Bool
		return store().data.present == true;

	/** Restore the checkpoint; the caller then switches to PlayState. */
	public static function resume():Void
	{
		var d = store().data;
		if (d.levelIds != null)
			buildLevels(cast d.levelIds);
		else
			buildLevels(["plains", "forest", "camp", "caves", "keep"]);
		active = true;
		level = d.level;
		floor = d.floor;
		Player.selectedKind = Type.createEnumIndex(entities.Player.PlayerKind, d.kind);
		lastBoss = d.lastBoss;
		resumeSeed = d.seed;
		carry = haxe.Json.parse(d.carry);
		items.ItemPool.setRemaining(d.pool);
		boughtSomething = d.bought == true;
		raftUsed = d.raft == true;
		weather = d.weather == null ? 0 : d.weather;
		caveWalk = false;
		if (d.stats != null)
		{
			var st:Dynamic = haxe.Json.parse(d.stats);
			kills = st.kills;
			damageTaken = st.dmg;
			timeSec = st.t;
			itemsTaken = st.items;
		}
	}

	/** Run over (death or victory): drop the checkpoint. */
	public static function clearSaved():Void
	{
		store().data.present = false;
		store().flush();
	}

	public static var active:Bool = false;
	public static var level:Int = 0;
	public static var floor:Int = 0; // 0-based within the level

	static var carry:Dynamic = null;

	public static function reset():Void
	{
		buildLevels();
		active = true;
		level = 0;
		floor = 0;
		carry = null;
		lastBoss = "";
		kills = 0;
		damageTaken = 0;
		timeSec = 0;
		itemsTaken = 0;
		lastHitBy = "";
		boughtSomething = false;
		raftUsed = false;
		weather = 0;
	}

	public static function floorName():String
	{
		var l = levels[level];
		if (l.floors == 1)
			return l.name.toUpperCase();
		return l.name.toUpperCase() + " " + ["I", "II", "III", "IV"][floor];
	}

	/** Global floor number, 0 = the first floor of the run. */
	public static function floorNumber():Int
	{
		var n = 0;
		for (i in 0...level)
			n += levels[i].floors;
		return n + floor;
	}

	public static function isLastFloor():Bool
		return level == levels.length - 1 && floor == levels[level].floors - 1;

	public static function advance():Void
	{
		var from = level;
		floor++;
		if (floor >= levels[level].floors)
		{
			floor = 0;
			level++;
		}
		caveWalk = world.LevelDefs.caveTransition(from, level);
	}

	/** Snapshot the hero before leaving a floor. */
	public static function save(p:Player):Void
	{
		carry = {
			hp: p.hp, maxHp: p.maxHp, gold: p.gold, bombs: p.bombs, keys: p.keys,
			damage: p.damage, fireCooldown: p.fireCooldown, arrowRange: p.arrowRange, speed: p.speed,
			luck: p.luck, burnHits: p.burnHits, scale: p.scale.x, items: p.items.copy(), itemIds: p.itemIds.copy(),
			twinShot: p.twinShot, waterWalker: p.waterWalker, secondWind: p.secondWind, goldBonus: p.goldBonus,
			shopDiscount: p.shopDiscount, campfireHeart: p.campfireHeart, bearClaw: p.bearClaw,
			activeId: p.activeId, activeCharge: p.activeCharge, activeMax: p.activeMax,
			trollSkin: p.trollSkin, harpoon: p.harpoon, horns: p.horns, sheepHex: p.sheepHex, blackCrown: p.blackCrown
		};
	}

	/** Restore the snapshot onto a fresh Player (no-op on the first floor). */
	public static function apply(p:Player):Void
	{
		if (carry == null)
			return;
		p.hp = carry.hp;
		p.maxHp = carry.maxHp;
		p.gold = carry.gold;
		p.bombs = carry.bombs;
		p.keys = carry.keys;
		p.damage = carry.damage;
		p.fireCooldown = carry.fireCooldown;
		p.arrowRange = carry.arrowRange;
		p.speed = carry.speed;
		p.luck = carry.luck;
		p.burnHits = carry.burnHits;
		p.scale.set(carry.scale, carry.scale);
		p.items = carry.items;
		p.itemIds = carry.itemIds;
		// item flags (saves from before these items existed leave them null)
		p.twinShot = carry.twinShot == true;
		p.waterWalker = carry.waterWalker == true;
		p.secondWind = carry.secondWind == true ? 1 : (Std.isOfType(carry.secondWind, Int) ? carry.secondWind : 0);
		p.goldBonus = carry.goldBonus != null ? carry.goldBonus : 1;
		p.shopDiscount = carry.shopDiscount != null ? carry.shopDiscount : 1;
		p.campfireHeart = carry.campfireHeart == true;
		p.activeId = carry.activeId;
		p.activeCharge = carry.activeCharge != null ? carry.activeCharge : 0;
		p.activeMax = carry.activeMax != null ? carry.activeMax : 0;
		p.bearClaw = carry.bearClaw == true;
		p.trollSkin = carry.trollSkin == true;
		p.harpoon = carry.harpoon == true;
		p.horns = carry.horns == true;
		p.sheepHex = carry.sheepHex == true;
		p.blackCrown = carry.blackCrown == true;
		entities.Prop.goldBonus = p.goldBonus;
	}
}
