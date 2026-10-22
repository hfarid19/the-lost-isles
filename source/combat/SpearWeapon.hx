package combat;

import entities.MeleeSwing;
import entities.Player;

/** Lancer thrust: a long narrow hurtbox aligned with the aim direction. */
class SpearWeapon implements Weapon
{
	public var cooldown(default, null):Float = 0.55;

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
		var horizontal = Math.abs(aimX) >= Math.abs(aimY);
		var diagonal = aimX != 0 && aimY != 0;
		var w = diagonal ? 86.0 : (horizontal ? 120.0 : 40.0);
		var h = diagonal ? 86.0 : (horizontal ? 40.0 : 120.0);
		var a = MeleeWeapon.swings.recycle(MeleeSwing.new);
		a.strike(owner, aimX, aimY, 95, w, h);
		if (owner.twinShot)
			MeleeWeapon.twin(owner, aimX, aimY, (ax, ay) ->
			{
				var b = MeleeWeapon.swings.recycle(MeleeSwing.new);
				b.strike(owner, ax, ay, 95, 86, 86);
				b.link(a);
			});
		fx.Sfx.play("sword_swing", 0.7);
		return true;
	}
}
