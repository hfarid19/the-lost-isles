package entities;

import flixel.FlxG;

/** Melee chaser. torch_red.png: 7x5 grid @192.
 * row0 idle(7f), row1 run(6f), row2 attack side(6f), row3 attack down(6f), row4 attack up(6f) */
class TorchGoblin extends Enemy
{
	static inline var ATTACK_RANGE:Float = 80;
	static inline var HIT_FRAME:Int = 3; // swing connects mid-animation

	var attackCooldown:Float = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/torch_red.png", true, 192, 192);
		animation.add("idle", [for (i in 0...7) i], 10);
		animation.add("run", [for (i in 7...13) i], 10);
		animation.add("attack_side", [for (i in 14...20) i], 14, false);
		animation.add("attack_down", [for (i in 21...27) i], 14, false);
		animation.add("attack_up", [for (i in 28...34) i], 14, false);
		animation.play("idle");
		setSize(44, 32);
		offset.set(74, 128);
		hp = 3;
		moveSpeed = 150;
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
				animation.play("run");
				chaseSmart(elapsed, moveSpeed);
				if (distToTarget() < ATTACK_RANGE && attackCooldown <= 0)
					startAttack();
			case ATTACK:
				velocity.set(0, 0);
				// connect the hit once, mid-swing, if still in range
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					if (distToTarget() < ATTACK_RANGE + 12)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
				{
					attackCooldown = 0.7;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}

	function startAttack():Void
	{
		state = ATTACK;
		didHit = false;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		if (dx != 0)
			flipX = dx < 0;
		var name = if (Math.abs(dy) > Math.abs(dx)) (dy > 0 ? "attack_down" : "attack_up") else "attack_side";
		animation.play(name, true);
	}
}
