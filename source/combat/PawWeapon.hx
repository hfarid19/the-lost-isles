package combat;

import entities.MeleeSwing;
import entities.Player;

/** Panda paw swipes: slow, heavy, a wide box right in front. */
class PawWeapon implements Weapon
{
	public var cooldown(default, null):Float = 0.7;

	var timer:Float = 0;

	public function new() {}

	public function update(elapsed:Float):Void
	{
		if (timer > 0)
			timer -= elapsed;
	}

	public function tryFire(owner:Player, aimX:Float, aimY:Float):Bool
	{
		if (timer > 0 || MeleeWeapon.swings == null)
			return false;
		timer = owner.fireCooldown;
		var a = MeleeWeapon.swings.recycle(MeleeSwing.new);
		a.strike(owner, aimX, aimY, 58, 84, 76);
		if (owner.twinShot)
			MeleeWeapon.twin(owner, aimX, aimY, (ax, ay) ->
			{
				var b = MeleeWeapon.swings.recycle(MeleeSwing.new);
				b.strike(owner, ax, ay, 58, 84, 76);
				b.link(a);
			});
		fx.Sfx.play("swipe", 0.7, 0.1);
		return true;
	}
}
