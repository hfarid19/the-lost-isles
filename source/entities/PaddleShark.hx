package entities;

/** Shark Waters (Enemy Pack Paddle Shark). paddleshark.png: 8 cols @192 — idle(8), run(6), attack(6).
 * Surfaces by the shore and leaps onto the islet with a paddle slam, then slips back. */
class PaddleShark extends WaterEnemy
{
	var leaping:Float = 0;
	var lx:Float = 0;
	var ly:Float = 0;
	var leaps:Int = 0;
	var leapHit:Bool = false;

	public function new(x:Float, y:Float, boss:Bool = false)
	{
		super(x, y);
		loadGraphic("assets/images/chars/paddleshark.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("swim", [for (i in 8...14) i], 12);
		animation.add("attack", [for (i in 16...22) i], 16, false);
		setSize(60, 34);
		offset.set(66, 102);
		swimSpeed = 190;
		surfaceTime = 1.7;
		restTime = 2.2;
		moveSpeed = 190;
		setupWater(boss, 32, 5);
	}

	override function surface():Void
	{
		super.surface();
		leaps = 0;
		startLeap();
	}

	function startLeap():Void
	{
		var dx = target.x + target.width / 2 - (x + width / 2), dy = target.y + target.height / 2 - (y + height / 2);
		var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
		lx = dx / len;
		ly = dy / len;
		leaping = 0.45;
		leapHit = false;
		flipX = lx < 0;
		animation.play("attack", true);
		fx.Sfx.play("swipe", 0.6);
	}

	/** Boss, bloodied: the slam floods a row of tiles for 3 s, shrinking the ground to stand on. */
	function flood():Void
	{
		var cy = y + height / 2;
		for (i in -3...4)
		{
			var s = EnemyShot.fire("flood", x + width / 2 + i * 64, cy, 0, 0, 0);
			if (s != null)
				s.setLife(3.0);
		}
		fx.Sfx.play("splash", 0.9, 0.1);
		fx.Juice.shake(0.004, 0.25);
	}

	override function surfacedUpdate(elapsed:Float):Void
	{
		if (leaping > 0)
		{
			leaping -= elapsed;
			velocity.set(lx * 520, ly * 520);
			if (!leapHit && distToTarget() < 70)
			{
				leapHit = true;
				if (target.hurt2(1, this))
					target.shove(lx * 400, ly * 400, 0.25);
				fx.Juice.shake(0.004, 0.15);
			}
			if (leaping <= 0)
			{
				velocity.set(0, 0);
				leaps++;
				if (isBoss && phase2)
					flood();
				if (phase2 && leaps < 2)
					startLeap();
			}
			return;
		}
		velocity.set(0, 0);
		if (animation.finished && animation.name != "idle")
			animation.play("idle");
	}
}
