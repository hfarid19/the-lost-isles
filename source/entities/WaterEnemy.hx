package entities;

import flixel.FlxG;

/** Shark Waters base: lives in the water around the islets. Submerged it glides toward the
 * shore nearest the hero and can't be hit; it surfaces for a moment to attack, then dives.
 * Subclasses fill in `attack()` and its timing. As a boss it is bigger with a faster cycle. */
class WaterEnemy extends BossBase
{
	/** Set by PlayState: world point -> the room it is in (for water cells). */
	public static var roomAt:(Float, Float) -> world.Room;

	public var isBoss(default, null):Bool;
	public var submerged(default, null):Bool = true;

	var cycle:Float = 2.0; // time until the next surfacing
	var surfaced:Float = 0; // time left above water
	var goalX:Float = 0;
	var goalY:Float = 0;
	var hasGoal:Bool = false;
	var swimSpeed:Float = 150;
	var surfaceTime:Float = 1.6;
	var restTime:Float = 2.4;
	var attacked:Bool = false;
	var phase2:Bool = false;

	function setupWater(boss:Bool, baseHp:Int, regularHp:Int):Void
	{
		isBoss = boss;
		flying = true; // passes over water and islets alike
		if (boss)
		{
			scale.set(1.6, 1.6);
			setScaledHp(baseHp);
		}
		else
		{
			hp = regularHp;
			maxHp = regularHp;
			regularUnit = true;
		}
		dive();
	}

	override public function hittable():Bool
		return !submerged;

	function dive():Void
	{
		submerged = true;
		alpha = 0.35;
		touchDamage = 0;
		solid = false;
		hasGoal = false;
		cycle = isBoss ? restTime * 0.7 : restTime;
		if (animation.name != "swim")
			animation.play("swim");
		fx.Sfx.play("bubble", 0.5, 0.2, 0.2);
	}

	function surface():Void
	{
		submerged = false;
		alpha = 1;
		touchDamage = 1;
		solid = true;
		surfaced = surfaceTime;
		attacked = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height, 1.0);
		fx.Sfx.play("splash", 0.7, 0.15, 0.2);
		if (target != null)
			flipX = (target.x + target.width / 2) < (x + width / 2);
	}

	/** The water cell (centre) nearest the hero, so the surfacing spot is the shore beside them. */
	function pickShore():Void
	{
		if (roomAt == null || target == null)
			return;
		var room = roomAt(x + width / 2, y + height / 2);
		if (room == null)
			return;
		var px = target.x + target.width / 2, py = target.y + target.height / 2;
		var best = 1e12;
		var W = room.tw, H = room.th;
		for (cy in 0...H)
			for (cx in 0...W)
			{
				if (room.template.ground[cy * W + cx] == 1)
					continue;
				var wx = room.worldX + cx * Constants.TILE + Constants.TILE / 2;
				var wy = room.worldY + cy * Constants.TILE + Constants.TILE / 2;
				var d = (wx - px) * (wx - px) + (wy - py) * (wy - py);
				if (d < 90 * 90)
					continue; // not right under the hero
				if (d < best)
				{
					best = d;
					goalX = wx;
					goalY = wy;
				}
			}
		hasGoal = best < 1e12;
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
			baseColor = 0xFFFFC8C8;
			color = baseColor;
			onPhase2();
		}
		if (submerged)
		{
			cycle -= elapsed;
			if (!hasGoal || cycle < 0.6)
				pickShore();
			if (hasGoal)
			{
				var dx = goalX - (x + width / 2), dy = goalY - (y + height / 2);
				var len = Math.sqrt(dx * dx + dy * dy);
				if (len > 8)
				{
					velocity.set(dx / len * swimSpeed, dy / len * swimSpeed);
					flipX = dx < 0;
				}
				else
				{
					velocity.set(0, 0);
					if (cycle <= 0)
						surface();
				}
			}
			else
				velocity.set(0, 0);
			updateCore(elapsed);
			return;
		}
		surfaced -= elapsed;
		surfacedUpdate(elapsed);
		if (surfaced <= 0)
			dive();
		updateCore(elapsed);
	}

	/** Above water: subclasses attack here (once, via `attacked`). */
	function surfacedUpdate(elapsed:Float):Void {}

	function onPhase2():Void {}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (submerged)
			return;
		super.takeHit(damage, source);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, isBoss ? 2.0 : 1.2);
		fx.Sfx.play("splash", 0.9, 0.1);
		flixel.tweens.FlxTween.tween(this, {alpha: 0, y: y + 30}, 0.7, {onComplete: _ -> kill()});
	}
}
