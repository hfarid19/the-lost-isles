package entities;

import flixel.FlxG;

/** Bamboo Isle boss (Enemy Pack Panda at 1.6x). panda.png: 13 cols @256 — idle(10), run(6), attack(13).
 * Chases with a two-hit combo, and every few seconds tucks into a rolling charge that
 * bounces off the walls. At half HP two Panda Guards join it. Beating it unlocks the Panda hero. */
class PandaBoss extends BossBase
{
	var cooldown:Float = 1.0;
	var swinging:Bool = false;
	var hits:Int = 0;
	var rollTimer:Float = 5.0;
	var rolling:Float = 0;
	var rx:Float = 0;
	var ry:Float = 0;
	var rollHit:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/panda.png", true, 256, 256);
		animation.add("idle", [for (i in 0...10) i], 10);
		animation.add("run", [for (i in 13...19) i], 12);
		animation.add("attack", [for (i in 26...39) i], 18, false);
		animation.play("idle");
		scale.set(1.6, 1.6);
		setSize(90, 44);
		offset.set(83, 172);
		setScaledHp(34);
		touchDamage = 1;
		moveSpeed = 170;
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
			baseColor = 0xFFFFD0D0;
			color = baseColor;
			if (summonHost != null)
				for (off in [-150.0, 150.0])
				{
					var g = new PandaGuard(x + off, y + 30, false);
					g.init(target);
					summonHost.add(g);
					fx.PackFx.play("smoke", x + off + 26, y + 40, 1.3);
				}
			fx.Sfx.play("roar", 0.8);
		}
		cooldown -= elapsed;
		rollTimer -= elapsed;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		if (rolling > 0)
		{
			rolling -= elapsed;
			// bounce off whatever it hits
			if (wasTouching.has(LEFT) || wasTouching.has(RIGHT))
				rx = -rx;
			if (wasTouching.has(UP) || wasTouching.has(DOWN))
				ry = -ry;
			velocity.set(rx * 520, ry * 520);
			angle += elapsed * 720 * (rx < 0 ? -1 : 1);
			if (!rollHit && distToTarget() < 80)
			{
				rollHit = true;
				if (target.hurt2(1, this))
					target.shove(rx * 420, ry * 420, 0.25);
			}
			if (rolling <= 0)
			{
				angle = 0;
				velocity.set(0, 0);
				cooldown = 0.8;
			}
			updateCore(elapsed);
			return;
		}
		if (swinging)
		{
			velocity.set(0, 0);
			var f = animation.curAnim != null ? animation.curAnim.curFrame : 0;
			if ((hits == 0 && f >= 5) || (hits == 1 && f >= 10))
			{
				hits++;
				if (distToTarget() < 130 && dx * (flipX ? -1 : 1) > -40)
					target.hurt2(1, this);
				fx.Sfx.play("swipe", 0.7);
			}
			if (animation.finished)
			{
				swinging = false;
				cooldown = phase2 ? 0.8 : 1.2;
			}
			updateCore(elapsed);
			return;
		}
		if (rollTimer <= 0 && distToTarget() > 160)
		{
			rollTimer = phase2 ? 4.0 : 6.0;
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			rx = dx / len;
			ry = dy / len;
			rolling = 1.1;
			rollHit = false;
			animation.play("idle");
			fx.Sfx.play("snort", 0.8);
			updateCore(elapsed);
			return;
		}
		if (distToTarget() < 110 && cooldown <= 0)
		{
			swinging = true;
			hits = 0;
			velocity.set(0, 0);
			if (dx != 0)
				flipX = dx < 0;
			animation.play("attack", true);
		}
		else
		{
			if (animation.name != "run")
				animation.play("run");
			chaseSmart(elapsed, moveSpeed * (phase2 ? 1.2 : 1));
		}
		updateCore(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		angle = 0;
		animation.play("idle");
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 2.2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.9, {onComplete: _ -> kill()});
	}
}
