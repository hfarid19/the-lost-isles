package combat;

import entities.MeleeSwing;
import entities.Player;
import flixel.group.FlxGroup.FlxTypedGroup;

/** Sword swings: spawns a short-lived hurtbox in the aim direction. */
class MeleeWeapon implements Weapon
{
	public var cooldown(default, null):Float = 0.45;

	/** Set by PlayState so swings recycle from the shared pool. */
	public static var swings:FlxTypedGroup<MeleeSwing>;

	var timer:Float = 0;

	public function new() {}

	public function update(elapsed:Float):Void
	{
		if (timer > 0)
			timer -= elapsed;
	}

	/** Twin Shot: a second strike 35 degrees off the first. */
	public static function twin(owner:Player, aimX:Float, aimY:Float, strike:(Float, Float) -> Void):Void
	{
		var a = Math.atan2(aimY, aimX) + (owner.flipX ? -0.6 : 0.6);
		strike(Math.cos(a), Math.sin(a));
	}

	public function tryFire(owner:Player, aimX:Float, aimY:Float):Bool
	{
		if (timer > 0 || swings == null)
			return false;
		timer = owner.fireCooldown;
		var a = swings.recycle(MeleeSwing.new);
		a.strike(owner, aimX, aimY);
		if (owner.twinShot)
			twin(owner, aimX, aimY, (ax, ay) ->
			{
				var b = swings.recycle(MeleeSwing.new);
				b.strike(owner, ax, ay);
				b.link(a);
			});
		fx.Sfx.play("sword_swing", 0.7);
		return true;
	}
}
