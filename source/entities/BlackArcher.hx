package entities;

import flixel.FlxG;

/** Keep ranged unit (Free Pack Black Archer). blackarcher.png: 8 cols @192 —
 * idle(6), run(4), shoot(8). Kites and looses an arrow every couple of seconds. */
class BlackArcher extends Enemy
{
	static inline var NEAR:Float = 200;
	static inline var FAR:Float = 380;
	static inline var SHOOT_FRAME:Int = 5;

	var shootTimer:Float = 1.0;
	var shooting:Bool = false;
	var shot:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/blackarcher.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 10);
		animation.add("run", [for (i in 8...12) i], 12);
		animation.add("shoot", [for (i in 16...24) i], 16, false);
		animation.play("idle");
		setSize(40, 32);
		offset.set(73, 104);
		hp = 3;
		moveSpeed = 150;
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
		var dy = (target.y + target.height / 2) - (y + height / 2);
		if (shooting)
		{
			velocity.set(0, 0);
			if (!shot && animation.curAnim != null && animation.curAnim.curFrame >= SHOOT_FRAME)
			{
				shot = true;
				var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
				EnemyShot.fire("arrow", x + width / 2, y + height / 2 - 12, dx / len, dy / len, 420);
				fx.Sfx.play("bow_shot", 0.5);
			}
			if (animation.finished)
			{
				shooting = false;
				shootTimer = FlxG.random.float(1.5, 2.2);
			}
			updateCore(elapsed);
			return;
		}
		var d = distToTarget();
		if (d < 700 && shootTimer <= 0)
		{
			shooting = true;
			shot = false;
			flipX = dx < 0;
			animation.play("shoot", true);
		}
		else if (d < NEAR)
		{
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
