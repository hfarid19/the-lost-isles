package entities;

import flixel.FlxG;

/** Troy villager (Free Pack Black Pawn). blackpawn.png: 8 cols @192 — idle(8), run(6).
 * Harmless: runs from the hero and drops a few coins if caught. */
class BlackPawn extends Enemy
{
	var wander:Float = 0;
	var wx:Float = 0;
	var wy:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/blackpawn.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 8...14) i], 14);
		animation.play("idle");
		setSize(40, 30);
		offset.set(76, 105);
		hp = 1;
		touchDamage = 0;
		moveSpeed = 200;
		harmless = true;
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
			wander = FlxG.random.float(0.6, 1.4);
			var a = FlxG.random.float(0, Math.PI * 2);
			wx = Math.cos(a) * 0.4;
			wy = Math.sin(a) * 0.4;
		}
		var speed = moveSpeed * 0.5;
		if (target != null && distToTarget() < 260)
		{
			var dx = (x + width / 2) - (target.x + target.width / 2), dy = (y + height / 2) - (target.y + target.height / 2);
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			wx = dx / len;
			wy = dy / len;
			speed = moveSpeed;
		}
		velocity.set(wx * speed, wy * speed);
		if (wx != 0)
			flipX = wx < 0;
		if (animation.name != "run")
			animation.play("run");
		updateCore(elapsed);
	}

	override function die():Void
	{
		if (Prop.coins != null)
			for (i in 0...Math.round(3 * Prop.goldBonus))
				Prop.coins.recycle(Coin.new).drop(x + width / 2, y + height / 2);
		super.die();
	}
}
