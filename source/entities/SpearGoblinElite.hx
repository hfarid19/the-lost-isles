package entities;

/** Goblin Camp II onward: slower, tougher spear goblin with a long wind-up lunge.
 * speargoblin_elite.png: 8x3 @256 — idle(8), run(6), strong attack(8). */
class SpearGoblinElite extends MeleeChaser
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/speargoblin_elite.png", true, 256, 256);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...14) i], 10);
		animation.add("attack", [for (i in 16...24) i], 9, false); // slow = readable wind-up
		animation.play("idle");
		setSize(48, 32);
		offset.set(102, 144);
		color = 0xFFFFD8B0; // gilded tint marks the elite
		baseColor = color;
		hp = 6;
		moveSpeed = 120;
		setup(140, 5, 1.2);
	}

	/** The lunge carries it 3 tiles forward and pierces. */
	override function onSwing():Void
	{
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
		velocity.set(dx / len * 700, dy / len * 700);
		flixel.util.FlxTimer.wait(0.25, () -> if (state == ATTACK) velocity.set(0, 0));
		if (len < 200)
			target.hurt2(touchDamage, this);
	}
}
