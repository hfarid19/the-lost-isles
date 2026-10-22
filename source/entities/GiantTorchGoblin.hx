package entities;

import flixel.FlxG;

/** Plains boss: a torch goblin at twice the size that leaves burning ground behind it.
 * Uses the regular torch goblin sheet (7x5 @192). */
class GiantTorchGoblin extends BossBase
{
	static inline var HIT_FRAME:Int = 3;

	var phase2:Bool = false;
	var attackCooldown:Float = 0;
	var didHit:Bool = false;
	var trailTimer:Float = 0;
	var dashTimer:Float = 4.0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/torch_red.png", true, 192, 192);
		animation.add("idle", [for (i in 0...7) i], 10);
		animation.add("run", [for (i in 7...13) i], 12);
		animation.add("attack_side", [for (i in 14...20) i], 14, false);
		animation.add("attack_down", [for (i in 21...27) i], 14, false);
		animation.add("attack_up", [for (i in 28...34) i], 14, false);
		animation.play("idle");
		scale.set(2, 2);
		setSize(80, 56);
		offset.set(56, 104);
		setScaledHp(28);
		touchDamage = 1;
		moveSpeed = 150;
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
			baseColor = 0xFFFFC090;
			color = baseColor;
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		if (attackCooldown > 0)
			attackCooldown -= elapsed;
		dashTimer -= elapsed;
		var d = distToTarget();
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				if (animation.name != "run") animation.play("run");
				if (dashTimer <= 0 && d > 200)
				{
					// torch dash: a fast straight rush that lays fire the whole way
					dashTimer = phase2 ? 3.0 : 4.5;
					moveToward(560);
					flixel.util.FlxTimer.wait(0.6, () -> if (state == CHASE) velocity.set(0, 0));
				}
				else if (velocity.x == 0 && velocity.y == 0 || dashTimer < (phase2 ? 2.4 : 3.9))
					moveToward(moveSpeed * (phase2 ? 1.3 : 1));
				if (d < 110 && attackCooldown <= 0)
				{
					state = ATTACK;
					didHit = false;
					velocity.set(0, 0);
					var dx = (target.x + target.width / 2) - (x + width / 2);
					var dy = (target.y + target.height / 2) - (y + height / 2);
					if (dx != 0) flipX = dx < 0;
					animation.play(Math.abs(dy) > Math.abs(dx) ? (dy > 0 ? "attack_down" : "attack_up") : "attack_side", true);
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					if (d < 140)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
				{
					attackCooldown = 0.8;
					state = CHASE;
				}
			case DYING:
		}
		// burning trail: a stationary flame every 0.25 s while moving
		trailTimer -= elapsed;
		if (trailTimer <= 0 && (velocity.x != 0 || velocity.y != 0))
		{
			trailTimer = 0.25;
			var f = EnemyShot.fire("fire", x + width / 2, y + height - 8, 0, 0, 0);
			if (f != null)
				f.setLife(phase2 ? 3.0 : 2.0);
		}
		super.update(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.6, {onComplete: _ -> kill()});
	}
}
