package entities;

/** Bamboo Isle tank (Enemy Pack Turtle). turtle.png: 10 cols @320 — idle(10), walk(7), attack(10).
 * Slow, 5 HP; the shell turns hits from the front, so circle round or bomb it. */
class Turtle extends MeleeChaser
{
	var guardDir:Float = 1;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/turtle.png", true, 320, 320);
		animation.add("idle", [for (i in 0...10) i], 10);
		animation.add("walk", [for (i in 10...17) i], 10);
		animation.add("attack", [for (i in 20...30) i], 14, false);
		animation.play("idle");
		setSize(80, 36);
		offset.set(86, 172);
		hp = 5;
		moveSpeed = 85;
		touchDamage = 1;
		setup(96, 5, 1.1, "walk");
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (target != null)
		{
			var dx = (target.x + target.width / 2) - (x + width / 2);
			if (dx != 0)
				guardDir = dx < 0 ? -1 : 1;
		}
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (state != DYING && state != ATTACK && source != null && !Std.isOfType(source, Explosion))
		{
			var sx = (source.x + source.width / 2) - (x + width / 2);
			if (sx * guardDir > -10)
			{
				fx.PackFx.play("impact", x + width / 2 + guardDir * 30, y + height / 2, 0.6);
				fx.Sfx.play("parry", 0.4, 0.1, 0.2);
				return;
			}
		}
		super.takeHit(damage, source);
	}
}
