package entities;

/** Gnome Mines boss (Enemy Pack Extra Turtle Guard). turtleguard.png: 6 cols @320 — in(6), out(3).
 * Tucked in its shell it crawls after you and can't be hurt; every few seconds it pops out
 * to bite, which is the window. Bloodied, it stays out for less time. */
class TurtleGuardBoss extends BossBase
{
	var hidden:Bool = true;
	var timer:Float = 3.0;
	var outTime:Float = 0;
	var didHit:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/turtleguard.png", true, 320, 320);
		animation.add("in", [for (i in 0...6) i], 8);
		animation.add("out", [6, 7, 8], 8, false);
		animation.play("in");
		scale.set(1.5, 1.5);
		setSize(110, 50);
		offset.set(105, 236);
		setScaledHp(30);
		touchDamage = 1;
		moveSpeed = 90;
	}

	override public function hittable():Bool
		return !hidden;

	override public function update(elapsed:Float):Void
	{
		if (dying || target == null)
		{
			velocity.set(0, 0);
			updateCore(elapsed);
			return;
		}
		if (!phase2 && hp <= maxHp / 2)
		{
			phase2 = true;
			baseColor = 0xFFFFC8C8;
			color = baseColor;
		}
		timer -= elapsed;
		if (hidden)
		{
			if (animation.name != "in")
				animation.play("in");
			chaseSmart(elapsed, moveSpeed * (phase2 ? 1.4 : 1));
			if (timer <= 0 && distToTarget() < 220)
			{
				hidden = false;
				outTime = phase2 ? 1.6 : 2.4;
				didHit = false;
				velocity.set(0, 0);
				animation.play("out", true);
				fx.Sfx.play("snort", 0.7);
			}
			updateCore(elapsed);
			return;
		}
		velocity.set(0, 0);
		outTime -= elapsed;
		if (!didHit && animation.curAnim != null && animation.curAnim.curFrame >= 2)
		{
			didHit = true;
			if (distToTarget() < 150)
			{
				var dx = (target.x + target.width / 2) - (x + width / 2);
				if (target.hurt2(1, this))
					target.shove(dx < 0 ? -420 : 420, 0, 0.25);
			}
			fx.Sfx.play("swipe", 0.8);
			fx.Juice.shake(0.003, 0.15);
		}
		if (outTime <= 0)
		{
			hidden = true;
			timer = phase2 ? 3.0 : 4.0;
			animation.play("in");
		}
		updateCore(elapsed);
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (hidden)
		{
			if (!dying)
			{
				fx.PackFx.play("impact", x + width / 2, y + height / 2 - 10, 0.7);
				fx.Sfx.play("parry", 0.4, 0.1, 0.2);
			}
			return;
		}
		super.takeHit(damage, source);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 2.2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.9, {onComplete: _ -> kill()});
	}
}
