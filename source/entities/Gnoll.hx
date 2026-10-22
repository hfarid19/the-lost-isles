package entities;

import flixel.FlxG;

/** Plains boss. Keeps its distance and throws bones; when the hero closes in it
 * lunges away. Phase 2 throws a fan of three. gnoll.png: 8x4 @192 — idle(6), walk(8), throw(8), hit(2). */
class Gnoll extends BossBase
{
	var phase2:Bool = false;
	var throwTimer:Float = 1.5;
	var thrown:Bool = false;
	var lungeTimer:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/gnoll.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 10);
		animation.add("walk", [for (i in 8...16) i], 12);
		animation.add("throw", [for (i in 16...24) i], 14, false);
		animation.add("hit", [24, 25], 10, false);
		animation.play("idle");
		scale.set(1.4, 1.4);
		setSize(56, 36);
		offset.set(68, 99);
		setScaledHp(26);
		touchDamage = 1;
		moveSpeed = 210;
	}

	function throwBone(a:Float):Void
		EnemyShot.fire("gnollbone", x + width / 2, y + height / 2 - 20, Math.cos(a), Math.sin(a), 330);

	override public function update(elapsed:Float):Void
	{
		if (dying)
		{
			velocity.set(0, 0);
			super.update(elapsed);
			return;
		}
		if (!phase2 && hp <= maxHp / 2)
		{
			phase2 = true;
			baseColor = 0xFFFFB0A0;
			color = baseColor;
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		throwTimer -= elapsed;
		lungeTimer -= elapsed;
		var d = distToTarget();
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				if (throwTimer <= 0)
				{
					state = ATTACK;
					thrown = false;
					velocity.set(0, 0);
					if (dx != 0) flipX = dx < 0;
					animation.play("throw", true);
				}
				else if (d < 150 && lungeTimer <= 0)
				{
					// hop away, sideways, to keep the range open
					lungeTimer = 1.2;
					var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
					velocity.set(-dx / len * 520 + dy / len * 200, -dy / len * 520 - dx / len * 200);
					animation.play("walk");
					fx.PackFx.play("smoke", x + width / 2, y + height, 0.8);
				}
				else if (lungeTimer > 0.9)
				{
					// keep the hop's velocity
				}
				else if (d > 320)
				{
					if (animation.name != "walk") animation.play("walk");
					moveToward(moveSpeed);
				}
				else
				{
					velocity.set(0, 0);
					if (dx != 0) flipX = dx < 0;
					if (animation.name != "idle") animation.play("idle");
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!thrown && animation.curAnim != null && animation.curAnim.curFrame >= 4)
				{
					thrown = true;
					var a = Math.atan2(dy, dx);
					throwBone(a);
					if (phase2)
					{
						throwBone(a - 0.3);
						throwBone(a + 0.3);
					}
				}
				if (animation.finished)
				{
					throwTimer = phase2 ? 1.3 : 2.0;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("hit", true);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 1.6);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.8, {onComplete: _ -> kill()});
	}
}
