package fx;

import flixel.FlxG;

/** Camera shake and screen flashes, gated by the player's options. */
class Juice
{
	public static function shake(intensity:Float = 0.005, duration:Float = 0.2):Void
	{
		if (Settings.shake)
			FlxG.camera.shake(intensity, duration);
	}

	/** Full-screen flash (lightning); skipped with "reduce flashing". */
	public static function flash(color:Int, duration:Float):Void
	{
		if (!Settings.reduceFlash)
			FlxG.camera.flash(color, duration);
	}
}
