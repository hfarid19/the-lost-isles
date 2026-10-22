package entities;

import flixel.FlxG;

/** Forest boss (also the spiderling it spawns, at small scale). Skitters, then
 * dashes at the hero; at half HP it drops spiderlings.
 * spider.png: 8x3 @192 — idle(8), run(5), attack(8). */
class Spider extends BossBase
{
	var phase2:Bool = false;
	var dashTimer:Float = 1.6;
	var dashing:Float = 0;
	var spawnTimer:Float = 5.0;
	var small:Bool;

	public function new(x:Float, y:Float, small:Bool = false)
	{
		super(x, y);
		this.small = small;
		loadGraphic("assets/images/boss/spider.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 12);
		animation.add("run", [for (i in 8...13) i], 14);
		animation.add("attack", [for (i in 16...24) i], 16, false);
		animation.play("idle");
		var k = small ? 0.7 : 1.5;
		scale.set(k, k);
		setSize(small ? 34 : 70, small ? 22 : 44);
		offset.set(small ? 79 : 61, small ? 110 : 95);
		if (small)
		{
			maxHp = 2;
			hp = 2;
			moveSpeed = 260;
		}
		else
		{
			setScaledHp(26);
			moveSpeed = 200;
		}
		touchDamage = 1;
	}

	override public function update(elapsed:Float):Void
	{
		if (dying)
		{
			velocity.set(0, 0);
			super.update(elapsed);
			return;
		}
		if (!small && !phase2 && hp <= maxHp / 2)
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
		dashTimer -= elapsed;
		if (phase2)
			spawnTimer -= elapsed;
		var d = distToTarget();
		if (dashing > 0)
		{
			dashing -= elapsed;
			if (dashing <= 0)
			{
				velocity.set(0, 0);
				if (d < (small ? 50 : 90))
					target.hurt2(touchDamage, this);
			}
			super.update(elapsed);
			return;
		}
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				if (dashTimer <= 0 && d < 420)
				{
					dashTimer = small ? 2.0 : (phase2 ? 1.2 : 1.8);
					dashing = 0.35;
					animation.play("attack", true);
					moveToward(small ? 520 : 640);
				}
				else if (d > (small ? 40 : 120))
				{
					if (animation.name != "run") animation.play("run");
					moveToward(moveSpeed);
				}
				else
				{
					velocity.set(0, 0);
					if (animation.name != "idle") animation.play("idle");
				}
			case ATTACK:
			case DYING:
		}
		if (!small && phase2 && spawnTimer <= 0 && summonHost != null && summonHost.countLiving() < 5)
		{
			spawnTimer = 6.0;
			for (off in [-60.0, 60.0])
			{
				var s = new Spider(x + off, y + 20, true);
				s.init(target);
				summonHost.add(s);
				fx.PackFx.play("smoke", x + off + 17, y + 30, 0.7);
			}
		}
		super.update(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, small ? 0.8 : 1.8);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, small ? 0.3 : 0.8, {onComplete: _ -> kill()});
	}
}
