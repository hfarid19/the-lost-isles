package entities;

import flixel.FlxG;
import flixel.util.FlxDirectionFlags;

/** Caves boss. Walks and swings up close; every few seconds it charges in a
 * straight line and stuns itself when it hits a wall — the window to hit it.
 * minotaur.png: 16x3 @320 — idle(16), walk(8), attack(12). */
class Minotaur extends BossBase
{
	static inline var SWING_RANGE:Float = 130;
	static inline var HIT_FRAME:Int = 6;

	var chargeTimer:Float = 2.5;
	var charging:Float = 0;
	var windup:Float = 0; // pawing the ground before the sprint
	var chargeDirX:Float = 1;
	var chargeDirY:Float = 0;
	var stunned:Float = 0;
	var didHit:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/minotaur.png", true, 320, 320);
		animation.add("idle", [for (i in 0...16) i], 12);
		animation.add("walk", [for (i in 16...24) i], 12);
		animation.add("attack", [for (i in 32...44) i], 14, false);
		animation.play("idle");
		scale.set(1.3, 1.3);
		setSize(90, 50);
		offset.set(79, 180);
		setScaledHp(36);
		touchDamage = 1;
		moveSpeed = 150;
	}

	override public function update(elapsed:Float):Void
	{
		if (dying)
		{
			velocity.set(0, 0);
			super.update(elapsed);
			return;
		}
		if (!phase2 && hp <= maxHp / 2)
		{
			phase2 = true;
			baseColor = 0xFFFFB0A0;
			color = baseColor;
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		if (stunned > 0)
		{
			stunned -= elapsed;
			velocity.set(0, 0);
			if (animation.name != "idle") animation.play("idle");
			super.update(elapsed);
			return;
		}
		if (windup > 0)
		{
			// telegraph: stand still, face the hero, shake, then sprint the locked line
			windup -= elapsed;
			velocity.set(0, 0);
			var dx = (target.x + target.width / 2) - (x + width / 2);
			flipX = dx < 0;
			if (animation.name != "idle") animation.play("idle");
			x += (Math.random() - 0.5) * 3;
			if (windup <= 0)
			{
				var dy = (target.y + target.height / 2) - (y + height / 2);
				var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
				chargeDirX = dx / len;
				chargeDirY = dy / len;
				charging = 1.4;
				fx.PackFx.play("smoke", x + width / 2, y + height, 1.2);
			}
			super.update(elapsed);
			return;
		}
		if (charging > 0)
		{
			charging -= elapsed;
			var spd = phase2 ? 640 : 540;
			velocity.set(chargeDirX * spd, chargeDirY * spd);
			flipX = chargeDirX < 0;
			if (animation.name != "walk") animation.play("walk");
			animation.curAnim.frameRate = 24;
			if (touching != FlxDirectionFlags.NONE)
			{
				charging = 0;
				stunned = 1.6;
				velocity.set(0, 0);
				fx.Juice.shake(0.006, 0.25);
				fx.Sfx.play("crash", 0.9);
				fx.PackFx.play("impact", x + width / 2, y + height / 2, 1.5);
			}
			else if (charging <= 0)
			{
				velocity.set(0, 0);
				animation.curAnim.frameRate = 12;
			}
			super.update(elapsed);
			return;
		}
		chargeTimer -= elapsed;
		var d = distToTarget();
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				if (chargeTimer <= 0 && d > 120)
				{
					chargeTimer = phase2 ? 2.4 : 3.5;
					windup = 0.55;
					velocity.set(0, 0);
					fx.Juice.shake(0.002, 0.4);
					fx.Sfx.play("snort", 0.8);
				}
				else if (d < SWING_RANGE)
				{
					state = ATTACK;
					didHit = false;
					velocity.set(0, 0);
					var dx = (target.x + target.width / 2) - (x + width / 2);
					if (dx != 0) flipX = dx < 0;
					animation.play("attack", true);
				}
				else
				{
					if (animation.name != "walk") animation.play("walk");
					moveToward(moveSpeed * (phase2 ? 1.3 : 1.0));
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= HIT_FRAME)
				{
					didHit = true;
					fx.Juice.shake(0.004, 0.15);
					if (d < SWING_RANGE + 40)
						target.hurt2(touchDamage, this);
				}
				if (animation.finished)
					state = CHASE;
			case DYING:
		}
		super.update(elapsed);
	}

	/** A raised shield stops the charge like a wall: rebound and stun. */
	override public function onDeflected(p:Player):Void
	{
		super.onDeflected(p);
		if (charging > 0)
		{
			charging = 0;
			stunned = 1.6;
			fx.Sfx.play("crash", 0.9);
			fx.Juice.shake(0.006, 0.25);
		}
	}

	/** Stunned against a wall it takes double damage. */
	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (stunned > 0)
			damage *= 2;
		super.takeHit(damage, source);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("idle");
		fx.Juice.shake(0.006, 0.3);
		flixel.tweens.FlxTween.tween(scale, {y: 1.3 * 0.35}, 0.5, {ease: flixel.tweens.FlxEase.quadIn});
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.7, {startDelay: 0.3, onComplete: _ -> kill()});
	}
}
