import flixel.util.FlxSave;

/** Permanent progress between runs (FlxSave: localStorage on html5, a file on desktop). */
class Unlocks
{
	static var save:FlxSave;

	/** Slot changed: forget the cached save so the next call binds the new one. */
	public static function rebind():Void
		save = null;

	static function ensure():Void
	{
		if (save != null)
			return;
		save = new FlxSave();
		save.bind(SaveSlots.unlocksName(SaveSlots.current));
		if (save.data.knight == null) save.data.knight = false;
		if (save.data.lancer == null) save.data.lancer = false;
		if (save.data.monk == null) save.data.monk = false;
		if (save.data.wins == null) save.data.wins = 0;
		if (save.data.plainsKills == null) save.data.plainsKills = 0;
		if (save.data.forestKills == null) save.data.forestKills = 0;
		if (save.data.panda == null) save.data.panda = false;
	}

	public static function isUnlocked(kind:entities.Player.PlayerKind):Bool
	{
		ensure();
		return switch (kind)
		{
			case Archer: true;
			case Knight: save.data.knight == true;
			case Lancer: save.data.lancer == true;
			case Monk: save.data.monk == true;
			case Panda: save.data.panda == true;
		}
	}

	public static function wins():Int
	{
		ensure();
		return save.data.wins;
	}

	/** Call when a level's last boss dies. Returns the heroes unlocked by it. */
	public static function onLevelBeaten(levelId:String):Array<String>
	{
		ensure();
		var fresh = [];
		switch (levelId)
		{
			case "plains":
				save.data.plainsKills += 1;
				if (!save.data.knight)
				{
					save.data.knight = true;
					fresh.push("Knight");
				}
			case "forest":
				save.data.forestKills += 1;
				if (!save.data.lancer)
				{
					save.data.lancer = true;
					fresh.push("Lancer");
				}
		}
		save.flush();
		return fresh;
	}

	/** Boss intro cards play in full the first time; later meetings get the short version. */
	public static function bossSeen(id:String):Bool
	{
		ensure();
		var seen:Array<String> = save.data.bossesSeen;
		return seen != null && seen.indexOf(id) >= 0;
	}

	public static function markBossSeen(id:String):Void
	{
		ensure();
		var seen:Array<String> = save.data.bossesSeen;
		if (seen == null)
			seen = [];
		if (seen.indexOf(id) < 0)
			seen.push(id);
		save.data.bossesSeen = seen;
		save.flush();
	}

	/** The Mystic Bamboo Isle joins the run after the first win. */
	public static function bambooUnlocked():Bool
	{
		ensure();
		return save.data.wins >= 1;
	}

	/** Shark Waters joins the run after three wins. */
	public static function watersUnlocked():Bool
	{
		ensure();
		return save.data.wins >= 3;
	}

	public static function troyUnlocked():Bool
	{
		ensure();
		return save.data.wins >= 5;
	}

	public static function minesUnlocked():Bool
	{
		ensure();
		return save.data.wins >= 7;
	}

	/** Beating the Panda boss unlocks the Panda hero. Returns the heroes freshly unlocked. */
	public static function onBossBeaten(bossId:String):Array<String>
	{
		ensure();
		var fresh = [];
		if (bossId == "panda" && !save.data.panda)
		{
			save.data.panda = true;
			fresh.push("Panda");
		}
		save.flush();
		return fresh;
	}

	/** Returns the heroes unlocked by this win. */
	public static function onRunWon(boughtSomething:Bool):Array<String>
	{
		ensure();
		save.data.wins += 1;
		var fresh = [];
		if (!boughtSomething && !save.data.monk)
		{
			save.data.monk = true;
			fresh.push("Monk");
		}
		save.flush();
		return fresh;
	}

	public static function unlockAll():Void
	{
		ensure();
		save.data.knight = true;
		save.data.lancer = true;
		save.data.monk = true;
		save.data.panda = true;
		if (save.data.wins < 7)
			save.data.wins = 7; // also opens every extra level
		save.flush();
	}

	public static function status():String
	{
		ensure();
		return 'knight=${save.data.knight} lancer=${save.data.lancer} monk=${save.data.monk} wins=${save.data.wins} plainsKills=${save.data.plainsKills} forestKills=${save.data.forestKills}';
	}
}
