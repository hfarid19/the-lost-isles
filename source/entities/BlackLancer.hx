package entities;

/** Troy spearman (Free Pack Black Lancer). blacklancer.png: 12 cols @320 —
 * idle(12), run(6), thrust right(3), up(3), down(3). Long reach, picks the thrust by angle. */
class BlackLancer extends MeleeChaser
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/blacklancer.png", true, 320, 320);
		animation.add("idle", [for (i in 0...12) i], 10);
		animation.add("run", [for (i in 12...18) i], 12);
		animation.add("atk_right", [24, 25, 26], 12, false);
		animation.add("atk_up", [36, 37, 38], 12, false);
		animation.add("atk_down", [48, 49, 50], 12, false);
		animation.play("idle");
		setSize(44, 32);
		offset.set(138, 166);
		hp = 4;
		moveSpeed = 160;
		touchDamage = 1;
		setup(124, 1, 1.0, "run", "atk_right");
	}

	override public function update(elapsed:Float):Void
	{
		if (target != null && state != ATTACK)
		{
			var dx = (target.x + target.width / 2) - (x + width / 2);
			var dy = (target.y + target.height / 2) - (y + height / 2);
			attackAnim = Math.abs(dy) > Math.abs(dx) * 1.5 ? (dy < 0 ? "atk_up" : "atk_down") : "atk_right";
		}
		super.update(elapsed);
	}

	override function onSwing():Void
	{
		if (distToTarget() < attackRange + 30 && target.hurt2(touchDamage, this))
		{
			var dx = (target.x + target.width / 2) - (x + width / 2);
			target.shove(dx < 0 ? -300 : 300, 0, 0.15);
		}
	}
}
