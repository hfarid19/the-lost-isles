package entities;

/** Caves: a fire imp that spits a short flame burst. imp.png: 8x5 @192 —
 * idle(8), move(6), attackStart(4), attackLoop(4), attackEnd(4). */
class Imp extends MeleeChaser
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/imp.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...14) i], 12);
		animation.add("attack", [16, 17, 18, 19, 24, 25, 26, 27, 32, 33, 34, 35], 14, false);
		animation.play("idle");
		setSize(44, 30);
		offset.set(75, 122);
		hp = 3;
		moveSpeed = 150;
		setup(150, 4, 1.4);
	}

	/** Flame burst: three fire shots in a short cone. */
	override function onSwing():Void
	{
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		var a = Math.atan2(dy, dx);
		fx.Sfx.play("fire", 0.6);
		for (off in [-0.25, 0.0, 0.25])
			EnemyShot.fire("fire", x + width / 2, y + height / 2 - 10, Math.cos(a + off), Math.sin(a + off), 240);
	}
}
