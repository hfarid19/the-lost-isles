import flixel.FlxG;
import flixel.util.FlxSave;

/** Player options shared by every save slot (FlxSave: localStorage on html5, a file on desktop). */
class Settings
{
	static var save:FlxSave;

	/** Master volume 0..1 in steps of 0.1; multiplies every sound and music track. */
	public static var volume(default, null):Float = 0.8;
	public static var music(default, null):Float = 1.0;
	public static var sfx(default, null):Float = 1.0;
	public static var ambience(default, null):Float = 1.0;
	public static var fullscreen(default, null):Bool = false;
	public static var shake(default, null):Bool = true;
	/** Skip lightning and explosion flashes. */
	public static var reduceFlash(default, null):Bool = false;
	public static var gamepad(default, null):Bool = true;

	static var defaultBinds:Map<String, Int> = [
		"up" => 87, "down" => 83, "left" => 65, "right" => 68, // W S A D
		"aimUp" => 38, "aimDown" => 40, "aimLeft" => 37, "aimRight" => 39, // arrows
		"bomb" => 69, "active" => 32, "block" => 16, "map" => 9 // E, Space, Shift, Tab
	];
	static var binds:Map<String, Int> = null;

	public static function bind(action:String):Int
	{
		load();
		var v = binds.get(action);
		return v == null ? defaultBinds.get(action) : v;
	}

	public static function setBind(action:String, key:Int):Void
	{
		load();
		binds.set(action, key);
		save.data.binds = haxe.Json.stringify([for (k in binds.keys()) {a: k, k: binds.get(k)}]);
		save.flush();
	}

	public static function resetBinds():Void
	{
		load();
		binds = new Map();
		save.data.binds = null;
		save.flush();
	}

	public static function load():Void
	{
		if (save != null)
			return;
		save = new FlxSave();
		save.bind("thelostisles_settings");
		var d = save.data;
		if (d.volume != null) volume = clamp(d.volume);
		if (d.music != null) music = clamp(d.music);
		if (d.sfx != null) sfx = clamp(d.sfx);
		if (d.ambience != null) ambience = clamp(d.ambience);
		if (d.fullscreen != null) fullscreen = d.fullscreen == true;
		if (d.shake != null) shake = d.shake == true;
		if (d.reduceFlash != null) reduceFlash = d.reduceFlash == true;
		if (d.gamepad != null) gamepad = d.gamepad == true;
		binds = new Map();
		if (d.binds != null)
			try
			{
				var list:Array<Dynamic> = haxe.Json.parse(d.binds);
				for (e in list)
					binds.set(e.a, e.k);
			}
			catch (_:Dynamic) {}
		apply();
	}

	static inline function clamp(v:Float):Float
		return Math.round(Math.max(0, Math.min(1, v)) * 10) / 10;

	/** Sliders: "volume", "music", "sfx", "ambience". */
	public static function get(key:String):Float
		return switch (key) { case "music": music; case "sfx": sfx; case "ambience": ambience; default: volume; }

	public static function set(key:String, v:Float):Void
	{
		load();
		v = clamp(v);
		switch (key)
		{
			case "music": music = v; save.data.music = v;
			case "sfx": sfx = v; save.data.sfx = v;
			case "ambience": ambience = v; save.data.ambience = v;
			default: volume = v; save.data.volume = v;
		}
		save.flush();
		apply();
	}

	public static function setVolume(v:Float):Void
		set("volume", v);

	/** Nudge the master volume by one step (+1 / -1); returns the new value. */
	public static function step(dir:Int):Float
	{
		set("volume", volume + dir * 0.1);
		return volume;
	}

	/** Toggles: "fullscreen", "shake", "reduceFlash", "gamepad". */
	public static function getFlag(key:String):Bool
		return switch (key) { case "fullscreen": fullscreen; case "shake": shake; case "reduceFlash": reduceFlash; default: gamepad; }

	public static function toggle(key:String):Bool
	{
		load();
		var v = !getFlag(key);
		switch (key)
		{
			case "fullscreen": fullscreen = v; save.data.fullscreen = v;
			case "shake": shake = v; save.data.shake = v;
			case "reduceFlash": reduceFlash = v; save.data.reduceFlash = v;
			default: gamepad = v; save.data.gamepad = v;
		}
		save.flush();
		apply();
		return v;
	}

	static function apply():Void
	{
		FlxG.sound.volume = volume;
		FlxG.sound.muted = false;
		fx.Sfx.refreshLevels();
		#if !html5
		if (FlxG.fullscreen != fullscreen)
			FlxG.fullscreen = fullscreen;
		#end
	}
}
