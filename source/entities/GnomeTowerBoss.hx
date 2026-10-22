package entities;

import flixel.FlxG;

/** Gnome Mines boss: the Gnome Tower as a spawner. Can't be hurt; it sends five waves of
 * gnomes (3 to 7, slingshots from wave 3) and falls once the last wave is beaten. */
class GnomeTowerBoss extends BossBase
{
	static inline var WAVES:Int = 5;
	var wave:Int = 0;
	var gap:Float = 1.5;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/gnome_tower.png");
		scale.set(1.5, 1.5);
		setSize(80, 40);
		offset.set(24, 268);
		immovable = true;
		moves = false;
		hp = WAVES;
		maxHp = WAVES;
		touchDamage = 0;
	}

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
		var n = 2 + wave;
		var cx = x + width / 2, cy = y + height;
		for (i in 0...n)
		{
			var a = -Math.PI * 0.15 + (Math.PI * 1.3) * i / Math.max(1, n - 1);
			var r = 110 + (i % 2) * 60;
			var ex = cx + Math.cos(a) * r, ey = cy + Math.abs(Math.sin(a)) * r * 0.6 + 10;
			var e:Enemy = (wave >= 3 && i % 3 == 0) ? new SlingshotGnome(ex, ey) : new Gnome(ex, ey);
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
			updateCore(elapsed);
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
						hp = WAVES - wave;
					sendWave();
					gap = 2.0;
				}
			}
		}
		else
			gap = 1.5;
		updateCore(elapsed);
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (!dying)
			fx.Sfx.play("arrow_block", 0.4);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		fx.PackFx.play("smoke", x + width / 2, y + height / 2 - 60, 2.5);
		fx.Sfx.play("stone_break", 0.9);
		fx.Juice.shake(0.006, 0.4);
		flixel.tweens.FlxTween.tween(this, {alpha: 0, y: y + 40}, 1.0, {onComplete: _ -> kill()});
	}
}
