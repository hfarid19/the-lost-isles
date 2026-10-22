package entities;

import flixel.FlxG;

/** Caves flyer (Dark Fantasy Enemies free pack, 2x): sleeps until the hero is
 * close, wakes, then weaves in and bites. cavebat.png: 16x7 @64 —
 * idleFly(9), run(8), attack(8), hurt(5), die(12), sleep(3), wake(16). */
class CaveBat extends Enemy
{
	static inline var BITE_RANGE:Float = 56;
	static inline var HIT_FRAME:Int = 4;

	var asleep:Bool = true;
	var waking:Bool = false;
	var wobble:Float = 0;
	var cooldown:Float = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/cavebat.png", true, 64, 64);
		animation.add("fly", [for (i in 0...9) i], 14);
		animation.add("run", [for (i in 16...24) i], 14);
		animation.add("attack", [for (i in 32...40) i], 16, false);
		animation.add("hurt", [for (i in 48...53) i], 14, false);
		animation.add("die", [for (i in 64...76) i], 14, false);
		animation.add("sleep", [for (i in 80...83) i], 4);
		animation.add("wake", [for (i in 96...112) i], 16, false);
		animation.play("sleep");
		scale.set(2, 2);
		setSize(44, 30);
		offset.set(10, 17);
		hp = 2;
		moveSpeed = 210;
		flying = true;
		wobble = FlxG.random.float(0, 6);
	}

	override public function update(elapsed:Float):Void
	{
		if (cooldown > 0)
			cooldown -= elapsed;
		wobble += elapsed * 6;
		if (asleep)
		{
			velocity.set(0, 0);
			if (!waking && target != null && distToTarget() < 230)
			{
				waking = true;
				fx.Sfx.play("flap", 0.5);
				animation.play("wake", true);
			}
			if (waking && animation.finished)
			{
				asleep = false;
				state = CHASE;
				animation.play("fly");
			}
			super.update(elapsed);
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
		super.update(elapsed);
	}

	/** Getting hit wakes it instantly. */
	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (asleep)
		{
			asleep = false;
			waking = false;
			state = CHASE;
			animation.play("fly");
		}
		super.takeHit(damage, source);
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
