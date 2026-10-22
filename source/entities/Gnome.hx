package entities;

import flixel.FlxG;

/** Forest melee chaser. gnome.png: 8x3 grid @192 — idle(8), run(6), attack(7). */
class Gnome extends Enemy
{
	static inline var ATTACK_RANGE:Float = 70;
	static inline var HIT_FRAME:Int = 3;

	var attackCooldown:Float = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/gnome.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...14) i], 12);
		animation.add("attack", [for (i in 16...23) i], 14, false);
		animation.play("idle");
		setSize(44, 30);
		offset.set(68, 97);
		hp = 2;
		moveSpeed = 175;
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
					if (animation.name != "run")
						animation.play("run");
					chaseSmart(elapsed, moveSpeed);
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					if (distToTarget() < ATTACK_RANGE + 20)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
				{
					attackCooldown = 0.6;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}
}
