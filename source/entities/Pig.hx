package entities;

import flixel.FlxG;

/** Plains and Camp charger: waits, then bolts in a straight line at the hero and
 * skids to a stop when it hits something. pig.png: 10x2 grid @192 — idle(10), run(4). */
class Pig extends Enemy
{
	var rest:Float = 1.2;
	var charge:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/pig.png", true, 192, 192);
		animation.add("idle", [for (i in 0...10) i], 10);
		animation.add("run", [for (i in 10...14) i], 14);
		animation.play("idle");
		setSize(48, 28);
		offset.set(71, 106);
		hp = 3;
		moveSpeed = 420;
	}

	/** Shield-bashed mid-charge: the charge ends and the pig skids back the way it came. */
	override public function onDeflected(p:Player):Void
	{
		super.onDeflected(p);
		charge = 0;
		rest = 1.4;
		animation.play("idle");
		fx.Juice.shake(0.003, 0.12);
	}

	override public function update(elapsed:Float):Void
	{
		switch (state)
		{
			case IDLE:
				velocity.set(0, 0);
				if (target != null)
					state = CHASE;
			case CHASE:
				if (charge > 0)
				{
					charge -= elapsed;
					// a wall or prop ends the charge early
					if (touching != flixel.util.FlxDirectionFlags.NONE)
						charge = 0;
					if (charge <= 0)
					{
						velocity.set(0, 0);
						animation.play("idle");
						rest = 1.0;
					}
				}
				else
				{
					rest -= elapsed;
					velocity.set(0, 0);
					if (rest <= 0 && distToTarget() < 520)
					{
						charge = 0.9;
						moveToward(moveSpeed); // locks the direction for the whole charge
						animation.play("run");
					}
				}
			case ATTACK:
			case DYING:
		}
		super.update(elapsed);
	}
}
