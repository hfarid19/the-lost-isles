package entities;

import flixel.FlxG;

/** Plains boss. Slow walker; a long wind-up then a club slam that sends out a
 * shockwave ring; the recovery after the slam is the window to hit it (2x damage).
 * troll.png: 12x6 @384 — idle(12), walk(10), windup(5), attack(6), recovery(10), dead(10). */
class Troll extends BossBase
{
	static inline var STOMP_RADIUS:Float = 300; // the ring stops here: the arena edge is safe

	var phase2:Bool = false;
	var recovering:Bool = false;
	var slammed:Bool = false;
	var stomping:Bool = false; // this attack is a stomp, not a club swing
	var swings:Int = 0;
	var ring:flixel.FlxSprite;
	var ringR:Float = -1; // current shockwave radius, -1 = none
	var ringHit:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/troll.png", true, 384, 384);
		animation.add("idle", [for (i in 0...12) i], 10);
		animation.add("walk", [for (i in 12...22) i], 10);
		animation.add("windup", [for (i in 24...29) i], 8, false);
		animation.add("attack", [for (i in 36...42) i], 14, false);
		animation.add("recovery", [for (i in 48...58) i], 10, false);
		animation.add("dead", [for (i in 60...70) i], 10, false);
		animation.play("idle");
		setSize(110, 50);
		offset.set(137, 247);
		setScaledHp(34);
		touchDamage = 1;
		moveSpeed = 95;

		ring = new flixel.FlxSprite();
		ring.makeGraphic(128, 128, flixel.util.FlxColor.TRANSPARENT, false, "trollRing");
		flixel.util.FlxSpriteUtil.drawCircle(ring, 64, 64, 60, flixel.util.FlxColor.TRANSPARENT, {thickness: 6, color: flixel.util.FlxColor.fromRGB(230, 200, 120)});
		ring.alpha = 0;
	}

	/** Expanding shockwave: when its edge passes the hero it hits once and shoves them outward. */
	function updateRing(elapsed:Float):Void
	{
		if (ringR < 0)
			return;
		var prev = ringR;
		ringR += elapsed * 460;
		var cx = x + width / 2, cy = y + height - 10;
		var dx = (target.x + target.width / 2) - cx;
		var dy = (target.y + target.height / 2) - cy;
		var dist = Math.sqrt(dx * dx + dy * dy);
		if (!ringHit && dist > prev && dist <= ringR && dist < STOMP_RADIUS)
		{
			ringHit = true;
			var len = Math.max(1, dist);
			target.hurt2(1, this);
			target.shove(dx / len * 900, dy / len * 900, 0.45); // shoved even during i-frames
		}
		var k = ringR / 60;
		ring.scale.set(k, k * 0.6); // squashed: it runs along the ground
		ring.alpha = 0.9 * (1 - ringR / STOMP_RADIUS);
		ring.setPosition(cx - 64, cy - 64);
		if (ringR >= STOMP_RADIUS)
		{
			ringR = -1;
			ring.alpha = 0;
		}
	}

	override public function draw():Void
	{
		if (ringR >= 0)
		{
			ring.cameras = cameras;
			ring.draw();
		}
		super.draw();
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
		updateRing(elapsed);
		var d = distToTarget();
		switch (state)
		{
			case IDLE:
				state = CHASE;
			case CHASE:
				// every third attack (every second in phase 2) is a stomp, usable from further away
				var wantStomp = (swings % (phase2 ? 2 : 3)) == (phase2 ? 1 : 2);
				if (d < 170 || (wantStomp && d < STOMP_RADIUS - 40))
				{
					state = ATTACK;
					slammed = false;
					recovering = false;
					stomping = wantStomp;
					swings++;
					velocity.set(0, 0);
					var dx = (target.x + target.width / 2) - (x + width / 2);
					if (dx != 0) flipX = dx < 0;
					animation.play("windup", true);
				}
				else
				{
					if (animation.name != "walk") animation.play("walk");
					moveToward(moveSpeed * (phase2 ? 1.35 : 1));
				}
			case ATTACK:
				velocity.set(0, 0);
				if (animation.finished)
				{
					if (animation.name == "windup")
						animation.play("attack", true);
					else if (animation.name == "attack")
					{
						animation.play("recovery", true);
						recovering = true;
					}
					else if (animation.name == "recovery")
					{
						recovering = false;
						state = CHASE;
					}
				}
				if (animation.name == "attack" && !slammed && animation.curAnim.curFrame >= 3 && stomping)
				{
					// stomp: the ring does the hitting
					slammed = true;
					fx.Juice.shake(0.01, 0.35);
					fx.Sfx.play("stomp", 1.0);
					fx.PackFx.play("smoke", x + width / 2, y + height - 6, 1.6);
					ringR = 0;
					ringHit = false;
				}
				else if (animation.name == "attack" && !slammed && animation.curAnim.curFrame >= 3)
				{
					slammed = true;
					fx.Juice.shake(0.008, 0.3);
					fx.Sfx.play("stomp", 0.8);
					fx.PackFx.play("impact", x + width / 2, y + height, 2.2);
					// the club lands in front of the troll: hit only the ground ahead of it,
					// a wide but shallow arc, never behind or well above its shoulders
					var hdx = (target.x + target.width / 2) - (x + width / 2);
					var hdy = (target.y + target.height / 2) - (y + height / 2);
					var facing = flipX ? -1 : 1;
					var ahead = hdx * facing;
					if (ahead > -30 && ahead < (phase2 ? 260 : 210) && Math.abs(hdy) < 110)
						target.hurt2(1, this);
					if (phase2)
					{
						var dx = (target.x + target.width / 2) - (x + width / 2);
						var dy = (target.y + target.height / 2) - (y + height / 2);
						var a = Math.atan2(dy, dx);
						for (off in [-0.4, 0.0, 0.4])
							EnemyShot.fire("ball", x + width / 2, y + height - 10, Math.cos(a + off), Math.sin(a + off), 220);
					}
				}
			case DYING:
		}
		super.update(elapsed);
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (recovering)
			damage *= 2;
		super.takeHit(damage, source);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("dead", true);
		fx.Juice.shake(0.006, 0.4);
		animation.onFinish.addOnce(_ -> flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.6, {onComplete: _ -> kill()}));
	}
}
