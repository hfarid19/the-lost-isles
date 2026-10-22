package entities;

import flixel.FlxG;

/** Gnome Mines boss: a Slingshot Gnome at 2x that kites and fires a three-acorn fan
 * (five once bloodied). */
class GiantSlingshot extends BossBase
{
	static inline var NEAR:Float = 220;
	static inline var FAR:Float = 380;
	var shootTimer:Float = 1.5;
	var shooting:Bool = false;
	var shot:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/slingshot.png", true, 192, 192);
		animation.add("idle", [for (i in 0...10) i], 10);
		animation.add("run", [for (i in 10...16) i], 12);
		animation.add("shoot", [for (i in 20...29) i], 16, false);
		animation.play("idle");
		scale.set(2, 2);
		setSize(70, 40);
		offset.set(61, 166);
		setScaledHp(26);
		touchDamage = 1;
		moveSpeed = 150;
	}

	override public function update(elapsed:Float):Void
	{
		if (dying || target == null)
		{
			velocity.set(0, 0);
			updateCore(elapsed);
			return;
		}
		if (!phase2 && hp <= maxHp / 2)
		{
			phase2 = true;
			baseColor = 0xFFFFC8C8;
			color = baseColor;
		}
		shootTimer -= elapsed;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		if (shooting)
		{
			velocity.set(0, 0);
			if (!shot && animation.curAnim != null && animation.curAnim.curFrame >= 5)
			{
				shot = true;
				var cx = x + width / 2, cy = y + height / 2 - 20;
				var base = Math.atan2(dy, dx);
				var n = phase2 ? 5 : 3;
				for (i in 0...n)
				{
					var a = base + (i - (n - 1) / 2) * 0.22;
					EnemyShot.fire("acorn", cx, cy, Math.cos(a), Math.sin(a), 340);
				}
				fx.Sfx.play("throw", 0.7);
			}
			if (animation.finished)
			{
				shooting = false;
				shootTimer = phase2 ? 1.3 : 1.9;
			}
			updateCore(elapsed);
			return;
		}
		var d = distToTarget();
		if (shootTimer <= 0)
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

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 2.0);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.8, {onComplete: _ -> kill()});
	}
}
