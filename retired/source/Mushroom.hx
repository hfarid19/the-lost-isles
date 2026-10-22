package entities;

import flixel.FlxG;

/** Forest melee bruiser from the Forest Monsters pack, drawn at 2x.
 * mushroom.png: 15x5 grid @80x64 — idle(7), run(8), attack(10), hit(5), die(15). */
class Mushroom extends Enemy
{
	static inline var ATTACK_RANGE:Float = 74;
	static inline var HIT_FRAME:Int = 5;

	var attackCooldown:Float = 0;
	var didHit:Bool = false;
	var stunned:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/mushroom.png", true, 80, 64);
		animation.add("idle", [for (i in 0...7) i], 10);
		animation.add("run", [for (i in 15...23) i], 12);
		animation.add("attack", [for (i in 30...40) i], 14, false);
		animation.add("hit", [for (i in 45...50) i], 14, false);
		animation.add("die", [for (i in 60...75) i], 14, false);
		animation.play("idle");
		scale.set(2, 2);
		setSize(44, 30);
		offset.set(18, 66);
		hp = 4;
		moveSpeed = 130;
	}

	/** Explosions daze it instead of just hurting it. */
	public function stun(seconds:Float):Void
	{
		if (state == DYING)
			return;
		stunned = seconds;
		velocity.set(0, 0);
		animation.play("hit", true);
	}

	override public function update(elapsed:Float):Void
	{
		if (attackCooldown > 0)
			attackCooldown -= elapsed;
		if (stunned > 0)
		{
			stunned -= elapsed;
			velocity.set(0, 0);
			super.update(elapsed);
			return;
		}
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
					if (animation.name != "run")
						animation.play("run");
					chaseSmart(elapsed, moveSpeed);
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					if (distToTarget() < ATTACK_RANGE + 24)
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
		// blown up: 1 in 100 leaves a Magic Mushroom behind
		if (lastHitSource != null && Std.isOfType(lastHitSource, Explosion) && FlxG.random.int(0, 99) == 0
			&& ItemPedestal.group != null)
		{
			var def = items.ItemPool.byId("magic_mushroom");
			if (def != null)
			{
				ItemPedestal.group.add(new ItemPedestal(x, y, def));
				fx.PackFx.play("sparkle", x + width / 2, y, 1.4);
			}
		}
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("die", true);
		animation.onFinish.addOnce(_ -> kill());
	}
}
