package fx;

import flixel.FlxG;
import flixel.sound.FlxSound;

/** Sound families in assets/sounds: `<name>_<n>.ogg`. play() picks a random
 * variant with a little pitch wobble so repeats don't sound identical. */
class Sfx
{
	static var counts:Map<String, Int> = [
		"bow_shot" => 2, "arrow_hit" => 3, "arrow_block" => 3, "sword_swing" => 3, "sword_hit" => 3, "parry" => 3,
		"player_hurt" => 6, "player_die" => 3, "enemy_hit" => 6, "enemy_die" => 4, "fuse" => 1, "explosion" => 2,
		"bush" => 4, "stone_break" => 5, "coin" => 4, "item" => 1, "fanfare" => 1, "eat" => 3, "key" => 1, "buy" => 1,
		"deny" => 1, "door_lock" => 3, "door_open" => 3, "boat" => 3, "rumble" => 3, "torch" => 2, "stomp" => 3,
		"snort" => 2, "spell" => 3, "hex" => 1, "fire" => 2, "cannon" => 3, "acid" => 3, "blink" => 1, "sheep" => 2,
		"ui" => 3, "stinger" => 1, "throw" => 3, "swipe" => 1, "crash" => 1, "flap" => 1,
		"step_dirt" => 5, "step_stone" => 5, "step_wood" => 5, "step_chain" => 5, "land" => 1,
		"splash" => 3, "buzz" => 3, "golem_step" => 3, "wing" => 3, "rope" => 3, "bubble" => 2, "roar" => 3,
	];

	public static var volume:Float = 0.8;

	/** Per-family throttle so a crowd of hits doesn't stack into noise. */
	static var lastPlayed:Map<String, Float> = new Map();

	public static function play(name:String, vol:Float = 1.0, pitchWobble:Float = 0.08, minGap:Float = 0.04):Void
	{
		var n = counts.get(name);
		if (n == null)
			return;
		var now = FlxG.game.ticks / 1000;
		var last = lastPlayed.get(name);
		if (last != null && now - last < minGap)
			return;
		lastPlayed.set(name, now);
		var i = n == 1 ? 1 : FlxG.random.int(1, n);
		var s = FlxG.sound.play('assets/sounds/${name}_$i.ogg', vol * volume * Settings.sfx);
		#if !html5
		if (s != null && pitchWobble > 0)
			s.pitch = 1 + FlxG.random.float(-pitchWobble, pitchWobble);
		#end
	}

	static var ambience:FlxSound;
	static var ambienceName:String = "";
	static var ambienceVol:Float = 0.35;
	static var musicVol:Float = 0.45;

	/** Options changed: re-level whatever is looping right now. */
	public static function refreshLevels():Void
	{
		if (ambience != null && ambience.playing)
			ambience.volume = ambienceVol * volume * Settings.ambience;
		if (FlxG.sound.music != null && FlxG.sound.music.playing && !musicFading)
			FlxG.sound.music.volume = musicVol * volume * Settings.music;
	}

	static var musicFading:Bool = false;

	/** Looping background: beach, forest, forest_night, cave, sea, or torch. */
	public static function ambient(name:String, vol:Float = 0.35):Void
	{
		if (ambienceName == name && ambience != null && ambience.playing)
			return;
		stopAmbient();
		ambienceName = name;
		ambienceVol = vol;
		ambience = FlxG.sound.play('assets/sounds/amb_$name.ogg', vol * volume * Settings.ambience, true);
		if (ambience != null)
			ambience.persist = true;
	}

	static var musicName:String = "";

	/** Looping music from assets/music (Pirate Music Pack Vol. 2): silent_harbor,
	 * hidden_booty, foggy_shores. Crossfades from whatever is playing. */
	public static function music(name:String, vol:Float = 0.45):Void
	{
		if (musicName == name && FlxG.sound.music != null && FlxG.sound.music.playing)
			return;
		musicName = name;
		musicVol = vol;
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			musicFading = true;
			FlxG.sound.music.fadeOut(0.8, 0, _ ->
			{
				FlxG.sound.playMusic('assets/music/$name.ogg', 0);
				FlxG.sound.music.fadeIn(1.0, 0, vol * volume * Settings.music, _ -> musicFading = false);
			});
			return;
		}
		musicFading = true;
		FlxG.sound.playMusic('assets/music/$name.ogg', 0);
		FlxG.sound.music.fadeIn(1.0, 0, vol * volume * Settings.music, _ -> musicFading = false);
	}

	public static function stopMusic():Void
	{
		musicName = "";
		if (FlxG.sound.music != null)
			FlxG.sound.music.fadeOut(0.6, 0, _ -> FlxG.sound.music.stop());
	}

	public static function stopAmbient():Void
	{
		if (ambience != null)
		{
			ambience.stop();
			ambience = null;
		}
		ambienceName = "";
	}
}
