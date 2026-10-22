import flixel.util.FlxSave;

/** Three profile slots. Each slot owns its unlocks and its run checkpoint;
 * Unlocks and RunState bind to the current slot's save names. */
class SaveSlots
{
	public static var current(default, null):Int = 1;

	public static function select(slot:Int):Void
	{
		current = slot;
		Unlocks.rebind();
		RunState.rebind();
	}

	public static inline function unlocksName(slot:Int):String
		return 'thelostisles_s$slot';

	public static inline function runName(slot:Int):String
		return 'thelostisles_run_s$slot';

	/** What the slot screen shows for a slot. */
	public static function summary(slot:Int):{empty:Bool, hasRun:Bool, hero:String, floor:String, wins:Int}
	{
		var u = new FlxSave();
		u.bind(unlocksName(slot));
		var r = new FlxSave();
		r.bind(runName(slot));
		var wins:Int = u.data.wins == null ? 0 : u.data.wins;
		var touched = u.data.wins != null || r.data.present == true;
		var hasRun = r.data.present == true;
		var hero = hasRun ? ["Archer", "Knight", "Lancer", "Monk"][r.data.kind] : "";
		var floor:String = hasRun && r.data.floorName != null ? r.data.floorName : "";
		return {empty: !touched, hasRun: hasRun, hero: hero, floor: floor, wins: wins};
	}

	public static function erase(slot:Int):Void
	{
		var u = new FlxSave();
		u.bind(unlocksName(slot));
		u.erase();
		var r = new FlxSave();
		r.bind(runName(slot));
		r.erase();
		if (slot == current)
		{
			Unlocks.rebind();
			RunState.rebind();
		}
	}
}
