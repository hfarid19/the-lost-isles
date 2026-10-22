package entities;

/** Config-driven melee enemy: chase, swing once in range, cool down. Subclasses
 * load a sheet and call setup(); the shared loop handles the rest. */
class MeleeChaser extends Enemy
{
	var attackRange:Float = 70;
	var hitFrame:Int = 3;
	var cooldownTime:Float = 0.7;
	var attackAnim:String = "attack";
	var runAnim:String = "run";
	var attackCooldown:Float = 0;
	var didHit:Bool = false;
	var dieAnim:String = null;

	function setup(range:Float, hitFrame:Int, cooldown:Float, ?run:String, ?attack:String, ?die:String):Void
	{
		attackRange = range;
		this.hitFrame = hitFrame;
		cooldownTime = cooldown;
		if (run != null) runAnim = run;
		if (attack != null) attackAnim = attack;
		dieAnim = die;
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
				if (distToTarget() < attackRange && attackCooldown <= 0)
				{
					state = ATTACK;
					didHit = false;
					velocity.set(0, 0);
					var dx = (target.x + target.width / 2) - (x + width / 2);
					if (dx != 0)
						flipX = dx < 0;
					animation.play(attackAnim, true);
				}
				else
				{
					if (animation.name != runAnim)
						animation.play(runAnim);
					chaseSmart(elapsed, moveSpeed);
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= hitFrame)
				{
					didHit = true;
					onSwing();
				}
				if (animation.finished)
				{
					attackCooldown = cooldownTime;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}

	/** The swing connects: default is a single melee hit if still in reach. */
	function onSwing():Void
	{
		if (distToTarget() < attackRange + 24)
			target.hurt2(touchDamage, this);
	}

	override function die():Void
	{
		if (dieAnim == null)
		{
			super.die();
			return;
		}
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.Sfx.play("enemy_die", 0.6);
		animation.play(dieAnim, true);
		animation.onFinish.addOnce(_ -> kill());
	}
}
