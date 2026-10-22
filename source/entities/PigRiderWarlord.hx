package entities;

import flixel.FlxG;

/** Goblin Camp boss: a spear goblin on a war pig. Charges in straight lines and
 * spears on contact; at half HP the pig bolts off (it becomes a free-roaming Pig
 * enemy) and the rider fights on foot as an elite with the strong lunge.
 * pigrider.png: 8x3 @256 — idle(8), run(4), attack(7). */
class PigRiderWarlord extends BossBase
{
	var phase2:Bool = false;
	var chargeTimer:Float = 2.0;
	var charging:Float = 0;
	var windup:Float = 0;
	var dirX:Float = 1;
	var dirY:Float = 0;
	var hitThisCharge:Bool = false;
	var swingCooldown:Float = 0;
	var didHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/pigrider.png", true, 256, 256);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...12) i], 14);
		animation.add("attack", [for (i in 16...23) i], 14, false);
		animation.play("idle");
		scale.set(1.4, 1.4);
		setSize(70, 40);
		offset.set(93, 138);
		setScaledHp(30);
		touchDamage = 1;
		moveSpeed = 150;
	}

	function dismount():Void
	{
		phase2 = true;
		baseColor = 0xFFFFD8B0;
		color = baseColor;
		// the pig runs off and keeps charging on its own
		if (summonHost != null)
		{
			var pig = new Pig(x, y + 10);
			pig.init(target);
			summonHost.add(pig);
		}
		// on foot: the elite spear goblin sheet, same hitbox
		loadGraphic("assets/images/chars/speargoblin_elite.png", true, 256, 256);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...14) i], 12);
		animation.add("attack", [for (i in 16...24) i], 11, false);
		animation.play("idle");
		scale.set(1.4, 1.4);
		setSize(70, 40);
		offset.set(93, 138);
		moveSpeed = 200;
		fx.PackFx.play("smoke", x + width / 2, y + height, 1.5);
	}

	override public function onDeflected(p:Player):Void
	{
		super.onDeflected(p);
		charging = 0;
		chargeTimer = 2.0;
		animation.play("idle");
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
			dismount();
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		if (swingCooldown > 0)
			swingCooldown -= elapsed;
		var d = distToTarget();
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);

		if (!phase2)
		{
			// mounted: wind up, then charge the locked line
			chargeTimer -= elapsed;
			if (windup > 0)
			{
				windup -= elapsed;
				velocity.set(0, 0);
				flipX = dx < 0;
				if (windup <= 0)
				{
					var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
					dirX = dx / len;
					dirY = dy / len;
					charging = 1.1;
					hitThisCharge = false;
					animation.play("run");
				}
			}
			else if (charging > 0)
			{
				charging -= elapsed;
				velocity.set(dirX * 560, dirY * 560);
				flipX = dirX < 0;
				if (!hitThisCharge && d < 80)
				{
					hitThisCharge = true;
					target.hurt2(touchDamage, this);
				}
				if (touching != flixel.util.FlxDirectionFlags.NONE || charging <= 0)
				{
					charging = 0;
					velocity.set(0, 0);
					animation.play("idle");
				}
			}
			else if (chargeTimer <= 0)
			{
				chargeTimer = 2.8;
				windup = 0.5;
				velocity.set(0, 0);
				animation.play("attack", true);
			}
			else
			{
				if (animation.name != "run") animation.play("run");
				moveToward(moveSpeed);
			}
			super.update(elapsed);
			return;
		}

		// on foot: elite lunge
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				if (d < 150 && swingCooldown <= 0)
				{
					state = ATTACK;
					didHit = false;
					velocity.set(0, 0);
					flipX = dx < 0;
					animation.play("attack", true);
				}
				else
				{
					if (animation.name != "run") animation.play("run");
					moveToward(moveSpeed);
				}
			case ATTACK:
				if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= 5)
				{
					didHit = true;
					var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
					velocity.set(dx / len * 700, dy / len * 700);
					flixel.util.FlxTimer.wait(0.25, () -> if (state == ATTACK) velocity.set(0, 0));
					if (d < 220)
						target.hurt2(touchDamage, this);
				}
				else if (!didHit)
					velocity.set(0, 0);
				if (animation.finished)
				{
					swingCooldown = 1.0;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 1.8);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.8, {onComplete: _ -> kill()});
	}
}
