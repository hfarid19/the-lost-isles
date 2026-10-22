package entities;

import flixel.FlxG;

/** Stationary turret (Enemy Pack Extra/Cannon): lobs a cannonball at the hero every
 * 3 s. Counts as an enemy so the room stays locked until it is destroyed. */
class Cannon extends Enemy
{
	var timer:Float = 2.0;
	var reload:Float = 3.0;
	var shotKind:String = "ball";
	var shotSpeed:Float = 260;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/cannon.png");
		setSize(44, 36);
		offset.set(46, 49);
		immovable = true;
		moves = false;
		hp = 4;
		touchDamage = 0;
	}

	override public function update(elapsed:Float):Void
	{
		if (target != null && state != DYING)
		{
			var dx = (target.x + target.width / 2) - (x + width / 2);
			flipX = dx < 0;
			timer -= elapsed;
			if (timer <= 0)
			{
				timer = reload;
				var dy = (target.y + target.height / 2) - (y + height / 2);
				var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
				EnemyShot.fire(shotKind, x + width / 2 + (flipX ? -20 : 20), y + 6, dx / len, dy / len, shotSpeed);
				fx.Sfx.play(shotKind == "ball" ? "cannon" : (shotKind == "arrow" ? "bow_shot" : "throw"), 0.7);
				fx.PackFx.play("smoke", x + width / 2 + (flipX ? -26 : 26), y + 4, 0.8);
				fx.Juice.shake(0.002, 0.1);
			}
		}
		super.update(elapsed);
	}
}
