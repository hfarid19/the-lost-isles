package entities;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/** Floor boss: a giant black bear. bear_black.png: 9x3 grid @256
 * (recoloured Tiny Swords Enemy Pack bear).
 * row0 idle(8f), row1 run(5f), row2 attack(9f: rear up 2-5, claw swipe 6-8). */
class BearBoss extends BossBase
{
	public static inline var MAX_HP:Int = 30;

	static inline var SCALE:Float = 2.2;
	static inline var ATTACK_RANGE:Float = 150;
	static inline var HIT_RANGE:Float = 210;
	static inline var HIT_FRAME:Int = 6; // claw swipe connects here

	var summonTimer:Float = 6.0;
	var phase2:Bool = false;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/bear_black.png", true, 256, 256);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 9...14) i], 12, true);
		animation.add("attack", [for (i in 18...27) i], 12, false);
		animation.play("idle");
		scale.set(SCALE, SCALE);
		// hitbox sits on the bear's footprint (frame body spans x72-187, feet at y177)
		setSize(120, 50);
		offset.set(71, 186);
		setScaledHp(MAX_HP);
		touchDamage = 1;
		moveSpeed = 190;
	}

	override public function update(elapsed:Float):Void
	{
		if (!phase2 && hp <= maxHp / 2 && !dying)
		{
			phase2 = true;
			baseColor = 0xFFFFB0A0; // enraged: reddish tint
			color = baseColor;
		}

		if (dying)
		{
			velocity.set(0, 0);
			super.update(elapsed);
			return;
		}

		switch (state)
		{
			case IDLE:
				if (target != null)
					state = CHASE;
			case CHASE:
				if (distToTarget() < ATTACK_RANGE)
					startAttack();
				else
				{
					animation.play("run");
					moveToward(moveSpeed * (phase2 ? 1.5 : 1.0));
				}

				if (phase2)
				{
					summonTimer -= elapsed;
					if (summonTimer <= 0)
						summon();
				}
			case ATTACK:
				velocity.set(0, 0);
				if (animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME && !didHit)
				{
					didHit = true;
					fx.Juice.shake(0.004, 0.15); // paws slam down
					if (distToTarget() < HIT_RANGE)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
					state = CHASE;
			case DYING:
		}
		super.update(elapsed);
	}

	function startAttack():Void
	{
		state = ATTACK;
		didHit = false;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		if (dx != 0)
			flipX = dx < 0;
		animation.play("attack", true);
	}

	function summon():Void
	{
		summonTimer = 6.0;
		if (summonHost == null || summonHost.countLiving() > 4)
			return;
		for (off in [{x: -180.0, y: -120.0}, {x: 180.0, y: 120.0}])
		{
			var e = world.LevelDefs.spawnMelee(x + off.x, y + off.y);
			e.init(target);
			summonHost.add(e);
		}
	}

	/** No death sheet in the pack: collapse in place, then fade. */
	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("idle", true);
		animation.pause();
		fx.Juice.shake(0.006, 0.3);
		FlxTween.tween(scale, {y: SCALE * 0.35}, 0.5, {ease: FlxEase.quadIn});
		FlxTween.tween(this, {alpha: 0}, 0.7, {startDelay: 0.3, onComplete: _ -> kill()});
	}
}
