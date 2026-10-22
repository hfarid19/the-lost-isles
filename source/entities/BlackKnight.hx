package entities;

/** Troy line infantry (Free Pack Black Warrior). blackknight.png: 8 cols @192 —
 * idle(8), run(6), attack1(4), attack2(4), guard(6). Its shield turns hits from the front
 * unless it is mid-swing. */
class BlackKnight extends MeleeChaser
{
	var guardDir:Float = 1;
	var alt:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/blackknight.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...14) i], 12);
		animation.add("attack1", [for (i in 16...20) i], 14, false);
		animation.add("attack2", [for (i in 24...28) i], 14, false);
		animation.play("idle");
		setSize(44, 32);
		offset.set(74, 105);
		hp = 5;
		moveSpeed = 150;
		touchDamage = 1;
		setup(84, 2, 0.9, "run", "attack1");
	}

	override public function update(elapsed:Float):Void
	{
		if (target != null && state != ATTACK)
		{
			var dx = (target.x + target.width / 2) - (x + width / 2);
			if (dx != 0)
				guardDir = dx < 0 ? -1 : 1;
			alt = !alt;
			attackAnim = alt ? "attack1" : "attack2";
		}
		super.update(elapsed);
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (state != DYING && state != ATTACK && source != null && !Std.isOfType(source, Explosion))
		{
			var sx = (source.x + source.width / 2) - (x + width / 2);
			if (sx * guardDir > -10)
			{
				fx.PackFx.play("impact", x + width / 2 + guardDir * 28, y + height / 2 - 6, 0.6);
				fx.Sfx.play("parry", 0.4, 0.1, 0.2);
				return;
			}
		}
		super.takeHit(damage, source);
	}
}
