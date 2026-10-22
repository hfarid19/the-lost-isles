package entities;

import flixel.FlxG;

/** Final boss (The Keep): the Free Pack Black Warrior at 2x. blackking.png: 8 cols @192 —
 * idle(8), run(8..13), attack1(16..19), attack2(24..27), guard(32..37).
 * Its shield covers the front: hits from ahead clang off unless it is mid-swing, so the
 * fight is flanking and baiting swings. Every few seconds it braces and charges the hero.
 * At half HP it calls two Black Archers to the corners and a Black Monk that heals it. */
class BlackKing extends BossBase
{
	static inline var SWING_RANGE:Float = 120;

	var guardDir:Float = 1;
	var faceTimer:Float = 0;
	var attacking:Bool = false;
	var didHit:Bool = false;
	var swingAlt:Bool = false;
	var cooldown:Float = 0.8;
	var chargeTimer:Float = 5.0;
	var bracing:Float = 0;
	var charging:Float = 0;
	var chargeX:Float = 0;
	var chargeY:Float = 0;
	var phase2:Bool = false;

	var captain:Bool;

	public function new(x:Float, y:Float, captain:Bool = false)
	{
		super(x, y);
		this.captain = captain;
		loadGraphic("assets/images/boss/blackking.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...14) i], 12);
		animation.add("attack1", [for (i in 16...20) i], 14, false);
		animation.add("attack2", [for (i in 24...28) i], 14, false);
		animation.add("guard", [for (i in 32...38) i], 12);
		animation.play("idle");
		scale.set(2, 2);
		setSize(80, 40);
		offset.set(67, 138);
		setScaledHp(36);
		if (captain)
		{
			scale.set(1.6, 1.6);
			setSize(64, 36);
			offset.set(75, 128);
			setScaledHp(26);
			moveSpeed = 165;
		}
		touchDamage = 1;
		moveSpeed = 150;
	}

	override public function update(elapsed:Float):Void
	{
		if (dying || target == null)
		{
			velocity.set(0, 0);
			updateCore(elapsed);
			return;
		}
		if (!phase2 && hp <= maxHp / 2)
		{
			phase2 = true;
			baseColor = 0xFFFFC8C8;
			color = baseColor;
			if (!captain)
				callCourt();
		}
		cooldown -= elapsed;
		chargeTimer -= elapsed;
		faceTimer -= elapsed;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		if (faceTimer <= 0 && !attacking && charging <= 0)
		{
			faceTimer = 0.5;
			if (dx != 0)
				guardDir = dx < 0 ? -1 : 1;
			flipX = guardDir < 0;
		}

		if (bracing > 0)
		{
			// wind-up: plants its feet behind the shield, then launches
			bracing -= elapsed;
			velocity.set(0, 0);
			if (bracing <= 0)
			{
				var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
				chargeX = dx / len;
				chargeY = dy / len;
				charging = 0.55;
				guardDir = chargeX < 0 ? -1 : 1;
				flipX = guardDir < 0;
				animation.play("run");
				fx.Sfx.play("snort", 0.9);
				fx.Juice.shake(0.004, 0.2);
			}
			updateCore(elapsed);
			return;
		}
		if (charging > 0)
		{
			charging -= elapsed;
			velocity.set(chargeX * 640, chargeY * 640);
			if (Std.int(charging * 20) != Std.int((charging + elapsed) * 20))
				fx.PackFx.play("smoke", x + width / 2 - chargeX * 30, y + height, 0.8);
			if (charging <= 0)
			{
				velocity.set(0, 0);
				cooldown = 0.6;
			}
			updateCore(elapsed);
			return;
		}
		if (attacking)
		{
			velocity.set(0, 0);
			if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= 2)
			{
				didHit = true;
				// a wide arc in front of the shield
				if (distToTarget() < SWING_RANGE + 40 && dx * guardDir > -30)
				{
					if (target.hurt2(1, this))
						target.shove(guardDir * 380, dy > 0 ? 120 : -120, 0.2);
				}
				fx.Sfx.play("sword_swing", 0.8);
			}
			if (animation.finished)
			{
				attacking = false;
				cooldown = phase2 ? 0.7 : 1.0;
			}
			updateCore(elapsed);
			return;
		}
		if (chargeTimer <= 0 && distToTarget() > 200)
		{
			chargeTimer = phase2 ? 4.0 : 5.5;
			bracing = 0.6;
			animation.play("guard");
			updateCore(elapsed);
			return;
		}
		if (distToTarget() < SWING_RANGE && cooldown <= 0)
		{
			attacking = true;
			didHit = false;
			swingAlt = !swingAlt;
			velocity.set(0, 0);
			animation.play(swingAlt ? "attack2" : "attack1", true);
		}
		else
		{
			if (animation.name != "run")
				animation.play("run");
			chaseSmart(elapsed, moveSpeed * (phase2 ? 1.15 : 1));
			flipX = guardDir < 0; // the shield keeps its own facing
		}
		updateCore(elapsed);
	}

	/** Phase 2: archers to the flanks, a monk at its back. */
	function callCourt():Void
	{
		if (summonHost == null)
			return;
		for (off in [-220.0, 220.0])
		{
			var a = new BlackArcher(x + off, y - 40);
			a.init(target);
			summonHost.add(a);
			fx.PackFx.play("smoke", x + off + 20, y + 10, 1.2);
		}
		var m = new BlackMonk(x - guardDir * 90, y + 20, this);
		m.init(target);
		summonHost.add(m);
		fx.PackFx.play("heal", x + width / 2, y, 1.4);
		fx.Sfx.play("roar", 0.8);
	}

	/** The shield covers the front unless it is swinging or charging. */
	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (!dying && !attacking && charging <= 0 && source != null)
		{
			var sx = (source.x + source.width / 2) - (x + width / 2);
			if (sx * guardDir > -10)
			{
				fx.PackFx.play("impact", x + width / 2 + guardDir * 40, y + height / 2 - 20, 0.9);
				fx.Sfx.play("parry", 0.5, 0.1, 0.2);
				return;
			}
		}
		super.takeHit(damage, source);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("idle");
		fx.PackFx.play("impact", x + width / 2, y + height / 2, 2.5);
		fx.Juice.shake(0.006, 0.4);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 1.0, {onComplete: _ -> kill()});
	}
}
