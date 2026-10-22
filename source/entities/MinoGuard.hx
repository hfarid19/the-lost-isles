package entities;

/** Caves heavy (Enemy Pack Extra Minotaur Guard): one 11-frame loop @320. Slow, 8 HP,
 * a wide shoulder charge as its swing. */
class MinoGuard extends MeleeChaser
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/minoguard.png", true, 320, 320);
		animation.add("idle", [for (i in 0...11) i], 10);
		animation.add("run", [for (i in 0...11) i], 14);
		animation.add("attack", [for (i in 0...11) i], 22, false);
		animation.play("idle");
		setSize(80, 40);
		offset.set(120, 175);
		hp = 8;
		moveSpeed = 95;
		touchDamage = 1;
		setup(100, 4, 1.2);
	}

	override function onSwing():Void
	{
		if (distToTarget() < attackRange + 30 && target.hurt2(touchDamage, this))
		{
			var dx = (target.x + target.width / 2) - (x + width / 2);
			target.shove(dx < 0 ? -420 : 420, 0, 0.2);
		}
		fx.Juice.shake(0.003, 0.12);
		fx.Sfx.play("golem_step", 0.7, 0.1);
	}
}
