package entities;

/** Troy boss: the Black Lancer at 2x. Long thrusts, and every few seconds a lance charge
 * across the courtyard. Faster and charging twice as often once bloodied. */
class BlackChampion extends BossBase
{
	var cooldown:Float = 1.0;
	var thrusting:Bool = false;
	var didHit:Bool = false;
	var chargeTimer:Float = 4.0;
	var charging:Float = 0;
	var cx:Float = 0;
	var cy:Float = 0;
	var chargeHit:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/blacklancer.png", true, 320, 320);
		animation.add("idle", [for (i in 0...12) i], 10);
		animation.add("run", [for (i in 12...18) i], 12);
		animation.add("atk_right", [24, 25, 26], 12, false);
		animation.add("atk_up", [36, 37, 38], 12, false);
		animation.add("atk_down", [48, 49, 50], 12, false);
		animation.play("idle");
		scale.set(2, 2);
		setSize(80, 40);
		offset.set(120, 246);
		setScaledHp(30);
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
			baseColor = 0xFFFFC8C8;
			color = baseColor;
		}
		cooldown -= elapsed;
		chargeTimer -= elapsed;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		if (charging > 0)
		{
			charging -= elapsed;
			velocity.set(cx * 620, cy * 620);
			if (!chargeHit && distToTarget() < 90)
			{
				chargeHit = true;
				if (target.hurt2(1, this))
					target.shove(cx * 450, cy * 450, 0.25);
			}
			if (charging <= 0)
			{
				velocity.set(0, 0);
				cooldown = 0.7;
			}
			updateCore(elapsed);
			return;
		}
		if (thrusting)
		{
			velocity.set(0, 0);
			if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= 1)
			{
				didHit = true;
				if (distToTarget() < 190 && target.hurt2(1, this))
					target.shove(dx < 0 ? -320 : 320, 0, 0.15);
				fx.Sfx.play("sword_swing", 0.7);
			}
			if (animation.finished)
			{
				thrusting = false;
				cooldown = phase2 ? 0.6 : 0.9;
			}
			updateCore(elapsed);
			return;
		}
		if (chargeTimer <= 0 && distToTarget() > 220)
		{
			chargeTimer = phase2 ? 2.8 : 4.5;
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			cx = dx / len;
			cy = dy / len;
			charging = 0.6;
			chargeHit = false;
			flipX = cx < 0;
			animation.play("atk_right", true);
			fx.Sfx.play("snort", 0.8);
			fx.Juice.shake(0.003, 0.15);
			updateCore(elapsed);
			return;
		}
		if (distToTarget() < 160 && cooldown <= 0)
		{
			thrusting = true;
			didHit = false;
			velocity.set(0, 0);
			flipX = dx < 0;
			animation.play(Math.abs(dy) > Math.abs(dx) * 1.5 ? (dy < 0 ? "atk_up" : "atk_down") : "atk_right", true);
		}
		else
		{
			if (animation.name != "run")
				animation.play("run");
			chaseSmart(elapsed, moveSpeed * (phase2 ? 1.25 : 1));
		}
		updateCore(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("impact", x + width / 2, y + height / 2, 2.2);
		fx.Juice.shake(0.005, 0.3);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.9, {onComplete: _ -> kill()});
	}
}
