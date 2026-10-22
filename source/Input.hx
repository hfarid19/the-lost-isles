import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;

/** Keyboard + first gamepad, read through one place so every state agrees.
 * Pad: left stick / d-pad move, right stick aims and fires, X bomb, Y active item,
 * LB or RB block, BACK map, START pause. */
class Input
{
	static inline var DEAD:Float = 0.25;

	static function pad():FlxGamepad
		return Settings.gamepad ? FlxG.gamepads.lastActive : null;

	static inline function key(action:String):Bool
		return FlxG.keys.checkStatus(Settings.bind(action), PRESSED);

	static inline function keyJust(action:String):Bool
		return FlxG.keys.checkStatus(Settings.bind(action), JUST_PRESSED);

	public static var moveX(get, never):Float;
	public static var moveY(get, never):Float;

	static function get_moveX():Float
	{
		var v:Float = (key("right") ? 1 : 0) - (key("left") ? 1 : 0);
		var p = pad();
		if (v == 0 && p != null)
		{
			var s = p.analog.value.LEFT_STICK_X;
			if (Math.abs(s) > DEAD) v = s;
			else v = (p.pressed.DPAD_RIGHT ? 1 : 0) - (p.pressed.DPAD_LEFT ? 1 : 0);
		}
		return v;
	}

	static function get_moveY():Float
	{
		var v:Float = (key("down") ? 1 : 0) - (key("up") ? 1 : 0);
		var p = pad();
		if (v == 0 && p != null)
		{
			var s = p.analog.value.LEFT_STICK_Y;
			if (Math.abs(s) > DEAD) v = s;
			else v = (p.pressed.DPAD_DOWN ? 1 : 0) - (p.pressed.DPAD_UP ? 1 : 0);
		}
		return v;
	}

	/** Keyboard aim keys as -1/0/1 per axis. */
	public static var aimX(get, never):Float;
	static function get_aimX():Float
		return (key("aimRight") ? 1 : 0) - (key("aimLeft") ? 1 : 0);

	public static var aimY(get, never):Float;
	static function get_aimY():Float
		return (key("aimDown") ? 1 : 0) - (key("aimUp") ? 1 : 0);

	/** Right stick past the dead zone: aim direction, or null. */
	public static function padAim():{x:Float, y:Float}
	{
		var p = pad();
		if (p == null)
			return null;
		var x = p.analog.value.RIGHT_STICK_X, y = p.analog.value.RIGHT_STICK_Y;
		var len = Math.sqrt(x * x + y * y);
		if (len < 0.4)
			return null;
		return {x: x / len, y: y / len};
	}

	public static var bomb(get, never):Bool;
	static function get_bomb():Bool
		return keyJust("bomb") || (pad() != null && pad().justPressed.X);

	public static var active(get, never):Bool;
	static function get_active():Bool
		return keyJust("active") || (pad() != null && pad().justPressed.Y);

	public static var block(get, never):Bool;
	static function get_block():Bool
		return key("block") || (pad() != null && (pad().pressed.LEFT_SHOULDER || pad().pressed.RIGHT_SHOULDER));

	public static var map(get, never):Bool;
	static function get_map():Bool
		return key("map") || FlxG.keys.pressed.M || (pad() != null && pad().pressed.BACK);

	public static var pause(get, never):Bool;
	static function get_pause():Bool
		return FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.P || (pad() != null && pad().justPressed.START);

	public static var menuUp(get, never):Bool;
	static function get_menuUp():Bool
		return FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W || (pad() != null && (pad().justPressed.DPAD_UP || pad().justPressed.LEFT_STICK_DIGITAL_UP));

	public static var menuDown(get, never):Bool;
	static function get_menuDown():Bool
		return FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S || (pad() != null && (pad().justPressed.DPAD_DOWN || pad().justPressed.LEFT_STICK_DIGITAL_DOWN));

	public static var menuLeft(get, never):Bool;
	static function get_menuLeft():Bool
		return FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A || (pad() != null && (pad().justPressed.DPAD_LEFT || pad().justPressed.LEFT_STICK_DIGITAL_LEFT));

	public static var menuRight(get, never):Bool;
	static function get_menuRight():Bool
		return FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D || (pad() != null && (pad().justPressed.DPAD_RIGHT || pad().justPressed.LEFT_STICK_DIGITAL_RIGHT));

	public static var back(get, never):Bool;
	static function get_back():Bool
		return FlxG.keys.justPressed.ESCAPE || (pad() != null && pad().justPressed.B);

	public static var confirm(get, never):Bool;
	static function get_confirm():Bool
		return FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE || (pad() != null && pad().justPressed.A);
}
