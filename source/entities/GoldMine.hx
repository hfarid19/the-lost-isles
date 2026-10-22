package entities;

import flixel.FlxG;

/** Gnome Mines (Update 010 Gold Mine): an active mine sends a Gnome out every 8 s while up to
 * three of its gnomes are on the field. Only a blast closes it: it bursts into coins and
 * switches to the ruined sprite. It never holds the doors shut. */
class GoldMine extends Enemy
{
	public static var host:flixel.group.FlxGroup.FlxTypedGroup<Enemy>;
	var timer:Float = 3.0;
	var spawned:Array<Enemy> = [];

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/goldmine_active.png");
		setSize(120, 40);
		offset.set(36, 86);
		immovable = true;
		moves = false;
		hp = 1;
		touchDamage = 0;
		harmless = true;
	}

	override public function update(elapsed:Float):Void
	{
		if (state != DYING && target != null && host != null)
		{
			timer -= elapsed;
			spawned = spawned.filter(e -> e.alive);
			if (timer <= 0 && spawned.length < 3)
			{
				timer = 8.0;
				var g = new Gnome(x + width / 2 - 20 + FlxG.random.float(-30, 30), y + height + 10);
				g.init(target);
				host.add(g);
				spawned.push(g);
				fx.PackFx.play("smoke", g.x + 20, g.y + 10, 0.9);
				fx.Sfx.play("door_open", 0.3);
			}
		}
		updateCore(elapsed);
	}

	/** Arrows and swings bounce off; only explosions close it. */
	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (state == DYING)
			return;
		if (source == null || !Std.isOfType(source, Explosion))
		{
			fx.Sfx.play("arrow_block", 0.4);
			return;
		}
		hp = 0;
		die();
	}

	override function die():Void
	{
		state = DYING;
		solid = false;
		loadGraphic("assets/images/props/goldmine_destroyed.png");
		fx.Sfx.play("stone_break", 0.9);
		fx.PackFx.play("coin_burst", x + width / 2, y + height / 2, 1.4);
		if (Prop.coins != null)
			for (i in 0...Math.round(FlxG.random.int(8, 12) * Prop.goldBonus))
				Prop.coins.recycle(Coin.new).drop(x + width / 2, y + height / 2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0.6}, 0.5);
		flixel.util.FlxTimer.wait(1.5, () -> kill());
	}
}
