package entities;

import flixel.FlxSprite;

/** AoE blast. Damaging window = first few frames. explosions.png: 9 frames @192. */
class Explosion extends FlxSprite
{
	public static inline var RADIUS:Float = 96;



	public var damaging(get, never):Bool;

	/** Each thing is hurt once per blast, not once per frame. */
	var hitList:Array<flixel.FlxBasic> = [];

	public function hasHit(b:flixel.FlxBasic):Bool
		return hitList.indexOf(b) >= 0;

	public function markHit(b:flixel.FlxBasic):Void
		hitList.push(b);

	inline function get_damaging():Bool
		return alive && animation.curAnim != null && animation.curAnim.curFrame < 4;

	public function new()
	{
		super();
		loadGraphic("assets/images/fx/explosions.png", true, 192, 192);
		animation.add("boom", [for (i in 0...9) i], 18, false);
		animation.onFinish.add(_ -> kill());
		setSize(RADIUS * 2, RADIUS * 2);
		centerOffsets();
	}

	public function boom(cx:Float, cy:Float):Void
	{
		reset(cx - width / 2, cy - height / 2);
		hitList.resize(0);
		animation.play("boom", true);
		fx.Sfx.play("explosion", 0.9);

		if (!Settings.reduceFlash)
			fx.LightManager.flash(cx, cy, 240);
	}
}
