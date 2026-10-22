package entities;

import flixel.FlxG;

/** Shark Waters (Enemy Pack Bomb Fish). bombfish.png: 8 cols @192 — idle(8), run(6), shoot(7).
 * Surfaces and spits a lit bomb onto the islet where the hero stands (2 s fuse). */
class BombFish extends WaterEnemy
{
	public function new(x:Float, y:Float, boss:Bool = false)
	{
		super(x, y);
		loadGraphic("assets/images/chars/bombfish.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("swim", [for (i in 8...14) i], 12);
		animation.add("shoot", [for (i in 16...23) i], 14, false);
		setSize(52, 32);
		offset.set(60, 103);
		swimSpeed = 140;
		surfaceTime = 1.6;
		restTime = 3.0;
		moveSpeed = 140;
		setupWater(boss, 28, 4);
	}

	override function surface():Void
	{
		super.surface();
		animation.play("shoot", true);
	}

	override function surfacedUpdate(elapsed:Float):Void
	{
		velocity.set(0, 0);
		if (!attacked && animation.curAnim != null && animation.curAnim.curFrame >= 4)
		{
			attacked = true;
			if (Dynamite.pool != null)
			{
				var n = phase2 ? 3 : 1;
				for (i in 0...n)
				{
					var tx = target.x + target.width / 2 + (n > 1 ? FlxG.random.float(-90, 90) : FlxG.random.float(-30, 30));
					var ty = target.y + target.height / 2 + (n > 1 ? FlxG.random.float(-60, 60) : FlxG.random.float(-20, 20));
					Dynamite.pool.recycle(Dynamite.new).plant(tx, ty, 2.0);
				}
			}
			fx.Sfx.play("throw", 0.6);
			fx.Sfx.play("fuse", 0.6);
		}
		if (animation.finished && animation.name != "idle")
			animation.play("idle");
	}
}
