package entities;

/** Shark Waters (Enemy Pack Harpoon Shark). harpoonshark.png: 8 cols @192 — idle(8), run(6), throw(8).
 * Surfaces by the shore and throws a harpoon that pins the hero for half a second. */
class HarpoonShark extends WaterEnemy
{
	public function new(x:Float, y:Float, boss:Bool = false)
	{
		super(x, y);
		loadGraphic("assets/images/chars/harpoonshark.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("swim", [for (i in 8...14) i], 12);
		animation.add("throw", [for (i in 16...24) i], 16, false);
		setSize(56, 32);
		offset.set(58, 104);
		swimSpeed = 160;
		surfaceTime = 1.8;
		restTime = 2.6;
		moveSpeed = 160;
		setupWater(boss, 30, 4);
	}

	override function surface():Void
	{
		super.surface();
		animation.play("throw", true);
	}

	override function surfacedUpdate(elapsed:Float):Void
	{
		velocity.set(0, 0);
		if (!attacked && animation.curAnim != null && animation.curAnim.curFrame >= 5)
		{
			attacked = true;
			var cx = x + width / 2, cy = y + height / 2 - 10;
			var dx = target.x + target.width / 2 - cx, dy = target.y + target.height / 2 - cy;
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			var offs = phase2 ? [-0.18, 0.18] : [0.0];
			for (o in offs)
			{
				var a = Math.atan2(dy, dx) + o;
				EnemyShot.fire("harpoon", cx, cy, Math.cos(a), Math.sin(a), 420);
			}
			fx.Sfx.play("throw", 0.7);
		}
		if (animation.finished && animation.name != "idle")
			animation.play("idle");
	}
}
