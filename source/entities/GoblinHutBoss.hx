package entities;

import flixel.FlxG;

/** Goblin Camp boss: a fortified hut that cannot be hurt. It sends six waves,
 * 5, 6, 7, 8, 9, then 10 goblins; survive the last and the hut collapses.
 * The boss bar counts the waves left. goblin_hut.png: 16 smoke frames @192x256. */
class GoblinHutBoss extends BossBase
{
	static inline var WAVES:Int = 6;

	var wave:Int = 0; // waves sent so far
	var gap:Float = 1.5; // pause before the next wave once the field is clear
	var announced:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/goblin_hut.png", true, 192, 256);
		animation.add("smoke", [for (i in 0...16) i], 6);
		animation.play("smoke");
		setSize(120, 50);
		offset.set(38, 186);
		immovable = true;
		moves = false;
		maxHp = WAVES;
		hp = WAVES; // one pip per wave
		touchDamage = 0;
	}

	/** Living goblins on the field, not counting the hut itself. */
	function fieldCount():Int
	{
		if (summonHost == null)
			return 0;
		var n = 0;
		summonHost.forEachAlive(e -> if (e != this && !e.harmless) n++);
		return n;
	}

	function sendWave():Void
	{
		wave++;
		var n = 4 + wave; // 5..10
		var cx = x + width / 2, cy = y + height;
		for (i in 0...n)
		{
			// fan out in front of the hut, a little staggered so they don't stack
			var a = -Math.PI * 0.15 + (Math.PI * 1.3) * i / Math.max(1, n - 1);
			var r = 120 + (i % 2) * 60;
			var ex = cx + Math.cos(a) * r, ey = cy + Math.abs(Math.sin(a)) * r * 0.6 + 10;
			var e:Enemy = switch (FlxG.random.int(0, 9))
			{
				case 0, 1, 2, 3: new SpearGoblin(ex, ey);
				case 4, 5, 6: new TorchGoblin(ex, ey);
				case 7: new BarrelGoblin(ex, ey);
				case 8: wave >= 4 ? new SpearGoblinElite(ex, ey) : new SpearGoblin(ex, ey);
				default: new Pig(ex, ey);
			}
			e.init(target);
			summonHost.add(e);
			fx.PackFx.play("smoke", ex + 20, ey + 10, 0.8);
		}
		fx.Sfx.play("door_lock", 0.7);
		fx.Juice.shake(0.003, 0.2);
	}

	override public function update(elapsed:Float):Void
	{
		if (dying || target == null)
		{
			super.update(elapsed);
			return;
		}
		if (fieldCount() == 0)
		{
			gap -= elapsed;
			if (gap <= 0)
			{
				if (wave >= WAVES)
				{
					hp = 0;
					die();
				}
				else
				{
					if (wave > 0)
						hp = WAVES - wave; // a wave survived: one pip off the bar
					sendWave();
					gap = 2.0;
				}
			}
		}
		else
			gap = 1.5;
		super.update(elapsed);
	}

	/** Nothing hurts it: the goblins are the fight. */
	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (dying)
			return;
		fx.PackFx.play("impact", x + width / 2, y + height / 2 - 30, 0.7);
		velocity.set(0, 0);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		fx.Juice.shake(0.008, 0.5);
		fx.PackFx.play("smoke", x + width / 2, y - 40, 2.5);
		fx.Sfx.play("stomp", 0.9);
		if (Dynamite.explosions != null)
			Dynamite.explosions.recycle(Explosion.new).boom(x + width / 2, y + height / 2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.9, {onComplete: _ -> kill()});
	}
}
