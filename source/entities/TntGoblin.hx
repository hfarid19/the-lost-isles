package entities;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;

/** Ranged lobber. tnt_red.png: 7x3 grid @192.
 * row0 idle(6f), row1 throw(7f), row2 run(6f) */
class TntGoblin extends Enemy
{
	public static var bombs:FlxTypedGroup<Dynamite>;

	static inline var MIN_DIST:Float = 200;
	static inline var MAX_DIST:Float = 350;
	static inline var THROW_FRAME:Int = 4;

	var throwTimer:Float = 1.2;
	var didThrow:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/tnt_red.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 10);
		animation.add("throw", [for (i in 7...14) i], 14, false);
		animation.add("run", [for (i in 14...20) i], 10);
		animation.play("idle");
		setSize(44, 32);
		offset.set(74, 128);
		hp = 2;
		moveSpeed = 110;
	}

	override public function update(elapsed:Float):Void
	{
		switch (state)
		{
			case IDLE:
				velocity.set(0, 0);
				if (target != null && distToTarget() < 600)
					state = CHASE;
			case CHASE:
				var d = distToTarget();
				if (d < MIN_DIST)
				{
					animation.play("run");
					moveToward(-moveSpeed); // back away
				}
				else if (d > MAX_DIST)
				{
					animation.play("run");
					chaseSmart(elapsed, moveSpeed);
				}
				else
				{
					velocity.set(0, 0);
					animation.play("idle");
					throwTimer -= elapsed;
					if (throwTimer <= 0)
						startThrow();
				}
			case ATTACK:
				velocity.set(0, 0);
				if (!didThrow && animation.curAnim != null && animation.curAnim.curFrame >= THROW_FRAME)
				{
					didThrow = true;
					if (bombs != null)
						bombs.recycle(Dynamite.new)
							.lob(x + width / 2, y + height / 2 - 60,
								target.x + target.width / 2, target.y + target.height / 2);
				}
				if (animation.finished)
				{
					throwTimer = 2.2;
					state = CHASE;
				}
			case DYING:
		}
		super.update(elapsed);
	}

	function startThrow():Void
	{
		state = ATTACK;
		didThrow = false;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		if (dx != 0)
			flipX = dx < 0;
		animation.play("throw", true);
	}
}
