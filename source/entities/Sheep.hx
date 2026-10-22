package entities;

import flixel.FlxG;

/** What a hexed enemy becomes (Update 010 Happy Sheep). sheep.png: 8 cols @128 — idle(8), bounce(6).
 * Harmless: wanders, bolts from the hero, dies to one hit and sometimes leaves meat. */
class Sheep extends Enemy
{
	var wander:Float = 0;
	var wx:Float = 0;
	var wy:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/sheep.png", true, 128, 128);
		animation.add("idle", [for (i in 0...8) i], 8);
		animation.add("bounce", [for (i in 8...14) i], 12);
		animation.play("idle");
		setSize(40, 26);
		offset.set(44, 84);
		hp = 1;
		touchDamage = 0;
		moveSpeed = 70;
		harmless = true;
		solid = true;
	}

	override public function update(elapsed:Float):Void
	{
		if (state == DYING)
		{
			updateCore(elapsed);
			return;
		}
		wander -= elapsed;
		if (wander <= 0)
		{
			wander = FlxG.random.float(0.8, 1.8);
			if (FlxG.random.bool(35))
				wx = wy = 0;
			else
			{
				var a = FlxG.random.float(0, Math.PI * 2);
				wx = Math.cos(a);
				wy = Math.sin(a);
			}
		}
		var speed = moveSpeed;
		if (target != null && distToTarget() < 150)
		{
			// bolt away from the hero
			var dx = (x + width / 2) - (target.x + target.width / 2), dy = (y + height / 2) - (target.y + target.height / 2);
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			wx = dx / len;
			wy = dy / len;
			speed = 150;
		}
		velocity.set(wx * speed, wy * speed);
		if (wx != 0)
			flipX = wx < 0;
		var moving = wx != 0 || wy != 0;
		if (animation.name != (moving ? "bounce" : "idle"))
			animation.play(moving ? "bounce" : "idle");
		updateCore(elapsed);
	}

	override function die():Void
	{
		if (FlxG.random.bool(30) && Pickup.group != null)
			Pickup.group.add(new Pickup(x, y, Meat));
		fx.Sfx.play("sheep", 0.6);
		super.die();
	}
}
