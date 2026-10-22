package entities;

/** Caves heavy (Golems free pack, 2x). golem.png: 13x5 @90x64 — idle(8), walk(10), attack(11), hurt(4), die(13). */
class Golem extends MeleeChaser
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/golem.png", true, 90, 64);
		animation.add("idle", [for (i in 0...8) i], 8);
		animation.add("walk", [for (i in 13...23) i], 10);
		animation.add("attack", [for (i in 26...37) i], 12, false);
		animation.add("die", [for (i in 52...65) i], 12, false);
		animation.play("idle");
		scale.set(2, 2);
		setSize(56, 34);
		offset.set(22, 64);
		hp = 8;
		moveSpeed = 80;
		setup(100, 6, 1.4, "walk", "attack", "die");
	}

	override function onSwing():Void
	{
		fx.Juice.shake(0.003, 0.15);
		if (distToTarget() < attackRange + 40)
			target.hurt2(2, this);
	}
}
