package entities;

import flixel.FlxG;

/** Goblin Camp: hides in a barrel, walks up, then pops out and explodes.
 * barrel_red.png: 6x6 @128 — row0 hidden(1), row1 peek out(6), row2 hidden(1), row3 duck back(6),
 * row4 lit fuse(3), row5 explode(3). */
class BarrelGoblin extends Enemy
{
	var fuse:Float = -1;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/barrel_red.png", true, 128, 128);
		animation.add("idle", [0], 1);
		animation.add("walk", [6, 7, 8, 9, 10, 11], 10);
		animation.add("pop", [24, 25, 26, 30, 31, 32], 8, false);
		animation.play("idle");
		setSize(40, 30);
		offset.set(44, 84);
		hp = 3;
		moveSpeed = 90;
	}

	override public function update(elapsed:Float):Void
	{
		if (fuse >= 0)
		{
			fuse -= elapsed;
			velocity.set(0, 0);
			color = (Std.int(fuse * 10) % 2 == 0) ? 0xFFFF9090 : baseColor;
			if (fuse <= 0)
			{
				if (Dynamite.explosions != null)
					Dynamite.explosions.recycle(Explosion.new).boom(x + width / 2, y + height / 2);
				kill();
			}
			super.update(elapsed);
			return;
		}
		switch (state)
		{
			case IDLE:
				velocity.set(0, 0);
				if (target != null && distToTarget() < 500)
					state = CHASE;
			case CHASE:
				if (distToTarget() < 90)
				{
					state = ATTACK;
					velocity.set(0, 0);
					animation.play("pop", true);
					fuse = 0.9;
				}
				else
				{
					if (animation.name != "walk")
						animation.play("walk");
					chaseSmart(elapsed, moveSpeed);
				}
			case ATTACK:
			case DYING:
		}
		super.update(elapsed);
	}

	/** Killed before it pops: still goes off, so keep your distance. */
	override function die():Void
	{
		if (fuse < 0)
		{
			state = DYING;
			fuse = 0.3;
			animation.play("pop", true);
			return;
		}
		super.die();
	}
}
