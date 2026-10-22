package entities;

import flixel.FlxG;

/** Caves cutpurse (Enemy Pack Thief). thief.png: 6 cols @192 — idle(6), run(6), attack(6).
 * Fast, fragile; a landed stab also pockets a coin, then it backs off for a moment. */
class Thief extends MeleeChaser
{
	var fleeTimer:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/thief.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 10);
		animation.add("run", [for (i in 6...12) i], 14);
		animation.add("attack", [for (i in 12...18) i], 16, false);
		animation.play("idle");
		setSize(44, 30);
		offset.set(71, 102);
		hp = 3;
		moveSpeed = 215;
		touchDamage = 1;
		setup(70, 3, 0.6);
	}

	override function onSwing():Void
	{
		if (distToTarget() < attackRange + 24 && target.hurt2(touchDamage, this))
		{
			if (target.gold > 0)
			{
				target.gold--;
				fx.Sfx.play("coin", 0.5, 0.2);
			}
			fleeTimer = 1.4;
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (fleeTimer > 0 && state == CHASE)
		{
			fleeTimer -= elapsed;
			// run the other way with the loot
			var dx = (x + width / 2) - (target.x + target.width / 2), dy = (y + height / 2) - (target.y + target.height / 2);
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			velocity.set(dx / len * moveSpeed, dy / len * moveSpeed);
			flipX = dx < 0;
			if (animation.name != "run")
				animation.play("run");
			updateCore(elapsed);
			return;
		}
		super.update(elapsed);
	}
}
