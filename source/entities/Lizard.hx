package entities;

import flixel.FlxG;

/** Forest boss. Spits acid globs that linger as puddles; at half HP it sheds
 * its tail (a decoy that draws the hero's aim) and gets faster.
 * lizard.png: 9x4 @192 — idle(7), run(6), attack(9), hit(2). */
class Lizard extends BossBase
{
	var phase2:Bool = false;
	var spitTimer:Float = 1.5;
	var spat:Bool = false;
	var biteCooldown:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/lizard.png", true, 192, 192);
		animation.add("idle", [for (i in 0...7) i], 10);
		animation.add("run", [for (i in 9...15) i], 12);
		animation.add("attack", [for (i in 18...27) i], 14, false);
		animation.add("hit", [27, 28], 10, false);
		animation.play("idle");
		scale.set(1.5, 1.5);
		setSize(64, 40);
		offset.set(64, 112);
		setScaledHp(28);
		touchDamage = 1;
		moveSpeed = 170;
	}

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
			baseColor = 0xFFC8FFB0;
			color = baseColor;
			moveSpeed = 240;
			// shed the tail: a decoy that soaks arrows for a while
			var decoy = new TrainingDummy(x, y + 30);
			decoy.loadGraphic("assets/images/boss/lizard.png", true, 192, 192);
			decoy.animation.add("idle", [27, 28], 4);
			decoy.animation.play("idle");
			decoy.scale.set(1.5, 1.5);
			decoy.offset.set(64, 112);
			decoy.color = 0xFF90B890;
			if (summonHost != null)
				summonHost.add(decoy);
			flixel.util.FlxTimer.wait(6.0, () -> decoy.kill());
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		spitTimer -= elapsed;
		if (biteCooldown > 0)
			biteCooldown -= elapsed;
		var d = distToTarget();
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				if ((spitTimer <= 0 && d > 140) || (d < 110 && biteCooldown <= 0))
				{
					state = ATTACK;
					spat = false;
					velocity.set(0, 0);
					if (dx != 0) flipX = dx < 0;
					animation.play("attack", true);
				}
				else
				{
					if (animation.name != "run") animation.play("run");
					moveToward(moveSpeed);
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!spat && animation.curAnim != null && animation.curAnim.curFrame >= 5)
				{
					spat = true;
					if (d < 130)
					{
						target.hurt2(touchDamage, this);
						biteCooldown = 0.9;
					}
					else
					{
						var a = Math.atan2(dy, dx);
						fx.Sfx.play("acid", 0.7);
						var g = EnemyShot.fire("acid", x + width / 2, y + height / 2 - 10, Math.cos(a), Math.sin(a), 280);
						if (g != null)
							g.puddleOnStop(2.5);
						if (phase2)
							for (off in [-0.35, 0.35])
							{
								var g2 = EnemyShot.fire("acid", x + width / 2, y + height / 2 - 10, Math.cos(a + off), Math.sin(a + off), 280);
								if (g2 != null)
									g2.puddleOnStop(2.5);
							}
					}
				}
				if (animation.finished)
				{
					spitTimer = phase2 ? 1.3 : 2.2;
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
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 1.8);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.8, {onComplete: _ -> kill()});
	}
}
