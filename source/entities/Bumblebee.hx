package entities;

import flixel.FlxG;

/** Forest flyer: ignores water and props, weaves toward the player and stings.
 * bumblebee.png: 11x3 grid @192 — idle(8), move(4), attack(11). */
class Bumblebee extends Enemy
{
	static inline var STING_RANGE:Float = 60;
	static inline var HIT_FRAME:Int = 5;

	var wobble:Float = 0;
	var cooldown:Float = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/bumblebee.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 12);
		animation.add("move", [for (i in 11...15) i], 14);
		animation.add("attack", [for (i in 22...33) i], 16, false);
		animation.play("idle");
		setSize(50, 40);
		offset.set(77, 80);
		hp = 2;
		moveSpeed = 200;
		flying = true;
		wobble = FlxG.random.float(0, 6);
	}

	override public function update(elapsed:Float):Void
	{
		if (cooldown > 0)
			cooldown -= elapsed;
		wobble += elapsed * 5;
		switch (state)
		{
			case IDLE:
				velocity.set(0, 0);
				if (target != null)
					state = CHASE;
			case CHASE:
				if (distToTarget() < STING_RANGE && cooldown <= 0)
				{
					state = ATTACK;
					didHit = false;
					velocity.set(0, 0);
					animation.play("attack", true);
					fx.Sfx.play("buzz", 0.5, 0.15, 0.3);
				}
				else
				{
					if (animation.name != "move")
						animation.play("move");
					moveToward(moveSpeed);
					// side-to-side weave so it is harder to line up a shot
					velocity.x += Math.cos(wobble) * 90;
					velocity.y += Math.sin(wobble * 1.3) * 90;
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					if (distToTarget() < STING_RANGE + 20)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
				{
					cooldown = 1.2;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}
}
