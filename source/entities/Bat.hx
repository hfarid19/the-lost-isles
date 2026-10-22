package entities;

import flixel.FlxG;

/** Caves flyer: the Enemy Pack Giant Bat sheet at 1x. giantbat.png: 7 cols @192 —
 * idle(6), move(4), attack(7). Hangs asleep until the hero is close, then weaves in and bites. */
class Bat extends Enemy
{
	static inline var BITE_RANGE:Float = 60;
	static inline var HIT_FRAME:Int = 3;

	var asleep:Bool = true;
	var wobble:Float = 0;
	var cooldown:Float = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/giantbat.png", true, 192, 192);
		animation.add("sleep", [0], 1);
		animation.add("fly", [for (i in 7...11) i], 14);
		animation.add("attack", [for (i in 14...21) i], 16, false);
		animation.play("sleep");
		setSize(48, 30);
		offset.set(72, 96);
		hp = 2;
		moveSpeed = 210;
		flying = true;
		alpha = 0.75; // dozing in the dark
		wobble = FlxG.random.float(0, 6);
	}

	function wake():Void
	{
		asleep = false;
		alpha = 1;
		state = CHASE;
		fx.Sfx.play("wing", 0.5, 0.2);
		animation.play("fly");
	}

	override public function update(elapsed:Float):Void
	{
		if (cooldown > 0)
			cooldown -= elapsed;
		wobble += elapsed * 6;
		if (asleep)
		{
			velocity.set(0, 0);
			if (target != null && distToTarget() < 230)
				wake();
			updateCore(elapsed);
			return;
		}
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				if (distToTarget() < BITE_RANGE && cooldown <= 0)
				{
					state = ATTACK;
					didHit = false;
					velocity.set(0, 0);
					animation.play("attack", true);
				}
				else
				{
					if (animation.name != "fly")
						animation.play("fly");
					moveToward(moveSpeed);
					velocity.x += Math.cos(wobble) * 110;
					velocity.y += Math.sin(wobble * 1.4) * 110;
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					if (distToTarget() < BITE_RANGE + 20)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
				{
					cooldown = 1.0;
					state = CHASE;
				}
			case DYING:
		}
		updateCore(elapsed);
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (asleep)
			wake();
		super.takeHit(damage, source);
	}
}
