package entities;

import flixel.FlxG;

/** Forest canopy enemy from the Flying Forest Enemies pack, drawn at 2x. Hovers
 * over obstacles, lines up above the player, then smashes down: start (dive),
 * loop (grounded — the window to hit it hard), end (rise).
 * stumpflyer.png: 17x7 grid @64 — idle(8), fly(8), smashStart(12), smashLoop(3), smashEnd(8), hit(4), die(17). */
class StumpFlyer extends Enemy
{
	var cooldown:Float = 0;
	var loops:Int = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/stumpflyer.png", true, 64, 64);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("fly", [for (i in 17...25) i], 12);
		animation.add("smash_start", [for (i in 34...46) i], 16, false);
		animation.add("smash_loop", [for (i in 51...54) i], 12, false);
		animation.add("smash_end", [for (i in 68...76) i], 14, false);
		animation.add("hit", [for (i in 85...89) i], 14, false);
		animation.add("die", [for (i in 102...119) i], 14, false);
		animation.play("idle");
		scale.set(2, 2);
		setSize(50, 36);
		offset.set(6, 46);
		hp = 5;
		moveSpeed = 150;
		flying = true;
	}

	override public function update(elapsed:Float):Void
	{
		if (cooldown > 0)
			cooldown -= elapsed;
		switch (state)
		{
			case IDLE:
				velocity.set(0, 0);
				if (target != null)
					state = CHASE;
			case CHASE:
				var dx = (target.x + target.width / 2) - (x + width / 2);
				var dy = (target.y + target.height / 2) - (y + height / 2);
				if (Math.abs(dx) < 30 && Math.abs(dy) < 30 && cooldown <= 0)
				{
					state = ATTACK;
					didHit = false;
					loops = 0;
					velocity.set(0, 0);
					animation.play("smash_start", true);
				}
				else
				{
					if (animation.name != "fly")
						animation.play("fly");
					moveToward(moveSpeed);
				}
			case ATTACK:
				velocity.set(0, 0);
				if (animation.finished)
				{
					if (animation.name == "smash_start")
					{
						animation.play("smash_loop", true);
						if (!didHit && distToTarget() < 70)
						{
							didHit = true;
							target.hurt2(touchDamage, this);
							fx.Juice.shake(0.003, 0.12);
						}
					}
					else if (animation.name == "smash_loop")
					{
						loops++;
						if (loops < 3)
							animation.play("smash_loop", true);
						else
							animation.play("smash_end", true);
					}
					else if (animation.name == "smash_end")
					{
						cooldown = 1.5;
						state = CHASE;
					}
				}
			case DYING:
		}
		super.update(elapsed);
	}

	/** Grounded (smash loop) it takes double damage. */
	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (state == ATTACK && animation.name == "smash_loop")
			damage *= 2;
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
