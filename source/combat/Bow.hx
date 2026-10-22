package combat;

import Constants.*;
import entities.Arrow;
import entities.Player;
import flixel.group.FlxGroup.FlxTypedGroup;

class Bow implements Weapon
{
	public var cooldown(default, null):Float = BOW_COOLDOWN;

	/** Set by PlayState so arrows recycle from the shared pool. */
	public static var pool:FlxTypedGroup<Arrow>;

	var timer:Float = 0;

	public function new() {}

	public function update(elapsed:Float):Void
	{
		if (timer > 0)
			timer -= elapsed;
	}

	public function tryFire(owner:Player, aimX:Float, aimY:Float):Bool
	{
		if (timer > 0 || pool == null)
			return false;
		timer = owner.fireCooldown;
		var cx = owner.x + owner.width / 2, cy = owner.y + owner.height / 2;
		if (owner.twinShot)
		{
			// Twin Shot: two arrows 12 degrees apart
			var a = Math.atan2(aimY, aimX);
			for (off in [-0.105, 0.105])
			{
				var arrow = pool.recycle(Arrow.new);
				arrow.fire(cx, cy, Math.cos(a + off), Math.sin(a + off), Std.int(owner.damage), owner.arrowRange);
				if (owner.burnHits)
					arrow.ignite();
			}
			fx.Sfx.play("bow_shot", 0.7);
			return true;
		}
		var arrow = pool.recycle(Arrow.new);
		arrow.fire(cx, cy, aimX, aimY, Std.int(owner.damage), owner.arrowRange);
		if (owner.burnHits)
			arrow.ignite();
		fx.Sfx.play("bow_shot", 0.7);
		return true;
	}
}
