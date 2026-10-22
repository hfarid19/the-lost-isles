package entities;

/** Forest chaser (Enemy Pack Snake). snake.png: 8 cols @192 — idle(8), run(8), attack(6).
 * Slow and tough; a blast coils it up (stun) instead of only hurting it. */
class Snake extends MeleeChaser
{
	var stunned:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/snake.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...16) i], 12);
		animation.add("attack", [for (i in 16...22) i], 14, false);
		animation.play("idle");
		setSize(56, 28);
		offset.set(68, 95);
		hp = 4;
		moveSpeed = 130;
		touchDamage = 1;
		setup(76, 3, 0.9);
	}

	/** Explosions daze it. */
	public function stun(seconds:Float):Void
	{
		if (state == DYING)
			return;
		stunned = seconds;
		velocity.set(0, 0);
		animation.play("idle", true);
	}

	override public function update(elapsed:Float):Void
	{
		if (stunned > 0)
		{
			stunned -= elapsed;
			velocity.set(0, 0);
			color = 0xFFFFFFB0;
			if (stunned <= 0)
				color = baseColor;
			updateCore(elapsed);
			return;
		}
		super.update(elapsed);
	}
}
