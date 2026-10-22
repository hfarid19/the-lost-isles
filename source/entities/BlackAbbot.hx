package entities;

import flixel.FlxG;

/** Troy boss: a Black Monk that never attacks. It keeps an escort of knights and lancers,
 * raises a fresh one whenever the escort thins, and blinks away when the hero gets close.
 * Kill the escort faster than it prays, then run it down. */
class BlackAbbot extends BossBase
{
	var prayTimer:Float = 2.0;
	var blinkCooldown:Float = 0;
	var praying:Bool = false;
	var prayed:Bool = false;
	var phase2:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/chars/blackmonk.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 10);
		animation.add("run", [for (i in 11...15) i], 12);
		animation.add("heal", [for (i in 22...33) i], 14, false);
		animation.play("idle");
		scale.set(1.6, 1.6);
		setSize(56, 36);
		offset.set(68, 128);
		setScaledHp(22);
		touchDamage = 0;
		moveSpeed = 190;
	}

	function escort():Int
	{
		if (summonHost == null)
			return 0;
		var n = 0;
		summonHost.forEachAlive(e -> if (e != this && !e.harmless) n++);
		return n;
	}

	function raise():Void
	{
		if (summonHost == null)
			return;
		var e:Enemy = FlxG.random.bool(60) ? new BlackKnight(x - 60, y + 40) : new BlackLancer(x + 60, y + 40);
		e.init(target);
		summonHost.add(e);
		fx.PackFx.play("heal", e.x + e.width / 2, e.y + e.height / 2, 1.2);
		fx.Sfx.play("spell", 0.7);
	}

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
		if (escort() == 0 && prayTimer > 1.0)
			prayTimer = 1.0; // alone: pray sooner
		prayTimer -= elapsed;
		blinkCooldown -= elapsed;
		if (praying)
		{
			velocity.set(0, 0);
			if (!prayed && animation.curAnim != null && animation.curAnim.curFrame >= 6)
			{
				prayed = true;
				raise();
				if (phase2)
					raise();
			}
			if (animation.finished)
			{
				praying = false;
				prayTimer = phase2 ? 5.0 : 7.0;
			}
			updateCore(elapsed);
			return;
		}
		if (prayTimer <= 0 && escort() < (phase2 ? 4 : 3))
		{
			praying = true;
			prayed = false;
			animation.play("heal", true);
			updateCore(elapsed);
			return;
		}
		// keeps its distance; blinks away if cornered
		var d = distToTarget();
		if (d < 150 && blinkCooldown <= 0)
		{
			blinkCooldown = 2.5;
			fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2, 1.2);
			var a = FlxG.random.float(0, Math.PI * 2);
			var rx = Math.floor(x / Constants.ROOM_W) * Constants.ROOM_W, ry = Math.floor(y / Constants.ROOM_H) * Constants.ROOM_H;
			x = Math.max(rx + 90, Math.min(rx + Constants.ROOM_W - 150, target.x + Math.cos(a) * 260));
			y = Math.max(ry + 90, Math.min(ry + Constants.ROOM_H - 110, target.y + Math.sin(a) * 180));
			fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2, 1.2);
			fx.Sfx.play("blink", 0.7);
		}
		else if (d < 240)
		{
			var dx = (x + width / 2) - (target.x + target.width / 2), dy = (y + height / 2) - (target.y + target.height / 2);
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			velocity.set(dx / len * moveSpeed, dy / len * moveSpeed);
			flipX = dx < 0;
			if (animation.name != "run")
				animation.play("run");
		}
		else
		{
			velocity.set(0, 0);
			if (animation.name != "idle")
				animation.play("idle");
		}
		updateCore(elapsed);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("heal", x + width / 2, y + height / 2, 2.0);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.9, {onComplete: _ -> kill()});
	}
}
