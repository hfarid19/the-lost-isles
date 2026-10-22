package entities;

import flixel.FlxG;

/** Goblin Camp boss. Keeps its distance, throws bolts, and casts the sheep hex
 * from range; at half HP it starts calling goblins.
 * hexshaman.png: 11x4 @192 — idle(8), run(4), attack(10), transform(11). */
class HexShaman extends BossBase
{
	var boltTimer:Float = 2.0;
	var hexTimer:Float = 4.0;
	var summonTimer:Float = 8.0;
	var casting:String = null; // "bolt" | "hex" while the cast anim plays
	var castFired:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/hexshaman.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 10);
		animation.add("run", [for (i in 11...15) i], 12);
		animation.add("attack", [for (i in 22...32) i], 14, false);
		animation.add("transform", [for (i in 33...44) i], 12, false);
		animation.play("idle");
		scale.set(1.3, 1.3);
		setSize(50, 34);
		offset.set(67, 103);
		setScaledHp(24);
		touchDamage = 1;
		moveSpeed = 170;
	}

	function faceTarget():Void
	{
		var dx = (target.x + target.width / 2) - (x + width / 2);
		if (dx != 0)
			flipX = dx < 0;
	}

	function shoot(kind:String, speed:Float):Void
	{
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
		EnemyShot.fire(kind, x + width / 2, y + height / 2 - 20, dx / len, dy / len, speed);
	}

	override public function update(elapsed:Float):Void
	{
		if (dying)
		{
			velocity.set(0, 0);
			super.update(elapsed);
			return;
		}
		if (!phase2 && hp <= maxHp / 2)
		{
			phase2 = true;
			baseColor = 0xFFD0FFB0;
			color = baseColor;
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		boltTimer -= elapsed;
		hexTimer -= elapsed;
		if (phase2)
			summonTimer -= elapsed;
		var d = distToTarget();

		if (casting != null)
		{
			velocity.set(0, 0);
			var f = animation.curAnim != null ? animation.curAnim.curFrame : 0;
			if (!castFired && f >= 5)
			{
				castFired = true;
				if (casting == "bolt")
				{
					shoot("bolt", 300);
					fx.Sfx.play("spell", 0.6);
				}
				else
				{
					shoot("hex", 150);
					fx.Sfx.play("blink", 0.7);
				}
			}
			if (animation.finished)
				casting = null;
		}
		else if (hexTimer <= 0 && d > 240)
		{
			hexTimer = 6.0;
			casting = "hex";
			castFired = false;
			faceTarget();
			animation.play("transform", true);
		}
		else if (boltTimer <= 0)
		{
			boltTimer = phase2 ? 1.6 : 2.2;
			casting = "bolt";
			castFired = false;
			faceTarget();
			animation.play("attack", true);
		}
		else
		{
			// hold the middle distance: back off when crowded, close in when far
			if (d < 200)
			{
				moveToward(-moveSpeed);
				faceTarget();
				if (animation.name != "run") animation.play("run");
			}
			else if (d > 380)
			{
				moveToward(moveSpeed);
				if (animation.name != "run") animation.play("run");
			}
			else
			{
				velocity.set(0, 0);
				faceTarget();
				if (animation.name != "idle") animation.play("idle");
			}
		}

		if (phase2 && summonTimer <= 0)
		{
			summonTimer = 8.0;
			if (summonHost != null && summonHost.countLiving() < 5)
				for (off in [{x: -150.0, y: 0.0}, {x: 150.0, y: 0.0}])
				{
					var e = world.LevelDefs.spawnMelee(x + off.x, y + off.y);
					e.init(target);
					summonHost.add(e);
					fx.PackFx.play("smoke", x + off.x + 20, y + off.y + 10);
				}
		}
		super.update(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("idle");
		fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2 - 20, 2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.8, {onComplete: _ -> kill()});
	}
}
