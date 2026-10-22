package entities;

/** Caves sword skeleton (Skeletons free pack, 2x). skeleton.png: 10x5 @96x64 —
 * idle(8), walk(10), attack(10), hurt(5), die(13). Slow, tough, wide swing. */
class Skeleton extends Enemy
{
	static inline var ATTACK_RANGE:Float = 84;
	static inline var HIT_FRAME:Int = 5;

	var attackCooldown:Float = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/skeleton.png", true, 96, 64);
		// atlas is 13 columns wide (the die row is the longest)
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("walk", [for (i in 13...23) i], 12);
		animation.add("attack", [for (i in 26...36) i], 14, false);
		animation.add("hurt", [for (i in 39...44) i], 14, false);
		animation.add("die", [for (i in 52...65) i], 14, false);
		animation.play("idle");
		scale.set(2, 2);
		setSize(40, 30);
		offset.set(34, 66);
		hp = 5;
		moveSpeed = 110;
	}

	override public function update(elapsed:Float):Void
	{
		if (attackCooldown > 0)
			attackCooldown -= elapsed;
		switch (state)
		{
			case IDLE:
				velocity.set(0, 0);
				if (target != null && distToTarget() < 600)
					state = CHASE;
			case CHASE:
				if (distToTarget() < ATTACK_RANGE && attackCooldown <= 0)
				{
					state = ATTACK;
					didHit = false;
					velocity.set(0, 0);
					var dx = (target.x + target.width / 2) - (x + width / 2);
					if (dx != 0)
						flipX = dx < 0;
					animation.play("attack", true);
				}
				else
				{
					if (animation.name != "walk")
						animation.play("walk");
					chaseSmart(elapsed, moveSpeed);
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					if (distToTarget() < ATTACK_RANGE + 30)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
				{
					attackCooldown = 0.9;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}

	override function die():Void
	{
		fx.Sfx.play("enemy_die", 0.6);
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("die", true);
		animation.onFinish.addOnce(_ -> kill());
	}
}
