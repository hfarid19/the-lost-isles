package combat;

import entities.MeleeSwing;
import entities.Player;

/** Monk palm strikes: short reach, tiny hurtbox, very fast. */
class FistWeapon implements Weapon
{
	public var cooldown(default, null):Float = 0.28;

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
		a.strike(owner, aimX, aimY, 40, 56, 56);
		if (owner.twinShot)
			MeleeWeapon.twin(owner, aimX, aimY, (ax, ay) ->
			{
				var b = MeleeWeapon.swings.recycle(MeleeSwing.new);
				b.strike(owner, ax, ay, 40, 56, 56);
				b.link(a);
			});
		fx.Sfx.play("sword_swing", 0.4, 0.15);
		return true;
	}
}
