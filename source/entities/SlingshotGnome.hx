package entities;

import flixel.FlxG;

/** Forest ranged unit (Enemy Pack Slingshot Gnome). slingshot.png: 10 cols @192 —
 * idle(10), run(6), shoot(9). Keeps its distance and lobs acorns. */
class SlingshotGnome extends Enemy
{
	static inline var NEAR:Float = 190;
	static inline var FAR:Float = 330;
	static inline var SHOOT_FRAME:Int = 5;

	var shootTimer:Float = 1.2;
	var shooting:Bool = false;
	var shot:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/slingshot.png", true, 192, 192);
		animation.add("idle", [for (i in 0...10) i], 10);
		animation.add("run", [for (i in 10...16) i], 12);
		animation.add("shoot", [for (i in 20...29) i], 16, false);
		animation.play("idle");
		setSize(40, 30);
		offset.set(76, 107);
		hp = 3;
		moveSpeed = 140;
		touchDamage = 1;
	}

	override public function update(elapsed:Float):Void
	{
		if (state == DYING || target == null)
		{
			updateCore(elapsed);
			return;
		}
		shootTimer -= elapsed;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		if (shooting)
		{
			velocity.set(0, 0);
			if (!shot && animation.curAnim != null && animation.curAnim.curFrame >= SHOOT_FRAME)
			{
				shot = true;
				var cx = x + width / 2, cy = y + height / 2 - 10;
				var tx = target.x + target.width / 2 - cx, ty = target.y + target.height / 2 - cy;
				var len = Math.max(1, Math.sqrt(tx * tx + ty * ty));
				EnemyShot.fire("acorn", cx, cy, tx / len, ty / len, 330);
				fx.Sfx.play("throw", 0.5);
			}
			if (animation.finished)
			{
				shooting = false;
				shootTimer = FlxG.random.float(1.6, 2.4);
			}
			updateCore(elapsed);
			return;
		}
		var d = distToTarget();
		if (d < 650 && shootTimer <= 0)
		{
			shooting = true;
			shot = false;
			flipX = dx < 0;
			animation.play("shoot", true);
		}
		else if (d < NEAR)
		{
			// back away, keeping the sling pointed at the hero
			var dy = (target.y + target.height / 2) - (y + height / 2);
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			velocity.set(-dx / len * moveSpeed, -dy / len * moveSpeed);
			flipX = dx < 0;
			if (animation.name != "run")
				animation.play("run");
		}
		else if (d > FAR)
		{
			if (animation.name != "run")
				animation.play("run");
			chaseSmart(elapsed, moveSpeed);
		}
		else
		{
			velocity.set(0, 0);
			flipX = dx < 0;
			if (animation.name != "idle")
				animation.play("idle");
		}
		updateCore(elapsed);
	}
}
