package entities;

import flixel.FlxG;

/** Bamboo Isle armoured guard (Enemy Pack Extra Panda Guard): one 8-frame loop @256.
 * Blocks everything from the front; a blast stuns it and opens it up for 2 s.
 * As a boss it is bigger, tougher, and calls a second guard at half HP. */
class PandaGuard extends BossBase
{
	public var isBoss(default, null):Bool;
	var guardDir:Float = 1;
	var stunned:Float = 0;
	var cooldown:Float = 0;
	var swinging:Bool = false;
	var didHit:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float, boss:Bool = false)
	{
		super(x, y);
		isBoss = boss;
		loadGraphic("assets/images/chars/pandaguard.png", true, 256, 256);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("attack", [for (i in 0...8) i], 20, false);
		animation.play("idle");
		setSize(52, 32);
		offset.set(103, 140);
		if (boss)
		{
			scale.set(1.5, 1.5);
			setSize(78, 40);
			offset.set(89, 172);
			setScaledHp(30);
			moveSpeed = 120;
		}
		else
		{
			hp = 6;
			maxHp = 6;
			moveSpeed = 100;
			regularUnit = true;
		}
		touchDamage = 1;
	}

	override public function update(elapsed:Float):Void
	{
		if (dying || target == null)
		{
			velocity.set(0, 0);
			updateCore(elapsed);
			return;
		}
		if (isBoss && !phase2 && hp <= maxHp / 2)
		{
			phase2 = true;
			if (summonHost != null)
			{
				var g = new PandaGuard(x - 120, y, false);
				g.init(target);
				summonHost.add(g);
				fx.PackFx.play("smoke", x - 100, y + 10, 1.3);
			}
		}
		cooldown -= elapsed;
		if (stunned > 0)
		{
			stunned -= elapsed;
			velocity.set(0, 0);
			color = 0xFFFFFFA0;
			if (stunned <= 0)
				color = baseColor;
			updateCore(elapsed);
			return;
		}
		var dx = (target.x + target.width / 2) - (x + width / 2);
		if (!swinging && dx != 0)
		{
			guardDir = dx < 0 ? -1 : 1;
			flipX = guardDir < 0;
		}
		if (swinging)
		{
			velocity.set(0, 0);
			if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= 4)
			{
				didHit = true;
				if (distToTarget() < 120 && target.hurt2(touchDamage, this))
					target.shove(guardDir * 360, 0, 0.2);
				fx.Sfx.play("sword_swing", 0.6);
			}
			if (animation.finished)
			{
				swinging = false;
				cooldown = 1.0;
			}
			updateCore(elapsed);
			return;
		}
		if (distToTarget() < 100 && cooldown <= 0)
		{
			swinging = true;
			didHit = false;
			velocity.set(0, 0);
			animation.play("attack", true);
		}
		else
		{
			chaseSmart(elapsed, moveSpeed);
			flipX = guardDir < 0;
		}
		updateCore(elapsed);
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (dying)
			return;
		if (source != null && Std.isOfType(source, Explosion))
		{
			stunned = 2.0;
			super.takeHit(damage, source);
			return;
		}
		if (stunned <= 0 && !swinging && source != null)
		{
			var sx = (source.x + source.width / 2) - (x + width / 2);
			if (sx * guardDir > -10)
			{
				fx.PackFx.play("impact", x + width / 2 + guardDir * 34, y + height / 2 - 10, 0.7);
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
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, isBoss ? 2.0 : 1.2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.6, {onComplete: _ -> kill()});
	}
}
