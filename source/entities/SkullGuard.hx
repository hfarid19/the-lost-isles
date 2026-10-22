package entities;

import flixel.FlxG;

/** Caves boss: an armoured skull that blinks around the room and raises skulls.
 * Its shield covers the front: hits from ahead clang off, so get behind it. It
 * only turns to face you every so often, which is the window to circle round.
 * skullguard.png: 7 frames @192 (one loop). */
class SkullGuard extends BossBase
{
	var phase2:Bool = false;
	var blinkTimer:Float = 2.5;
	var raiseTimer:Float = 5.0;
	var faceTimer:Float = 0; // it re-aims its shield only every 0.9 s
	var guardDir:Float = 1; // +1 right, -1 left

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/skullguard.png", true, 192, 192);
		animation.add("idle", [for (i in 0...7) i], 10);
		animation.play("idle");
		scale.set(1.6, 1.6);
		setSize(60, 40);
		offset.set(66, 90);
		setScaledHp(24);
		touchDamage = 1;
		moveSpeed = 210;
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
			baseColor = 0xFFC0B0FF;
			color = baseColor;
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		blinkTimer -= elapsed;
		raiseTimer -= elapsed;
		faceTimer -= elapsed;
		if (faceTimer <= 0)
		{
			faceTimer = phase2 ? 0.7 : 0.9;
			var dx = (target.x + target.width / 2) - (x + width / 2);
			if (dx != 0)
				guardDir = dx < 0 ? -1 : 1;
			flipX = guardDir < 0;
		}

		if (blinkTimer <= 0)
		{
			blinkTimer = phase2 ? 1.8 : 2.5;
			fx.Sfx.play("blink", 0.7);
			fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2, 1.4);
			// reappear a few tiles from the hero, inside the room
			var a = FlxG.random.float(0, Math.PI * 2);
			var nx = target.x + Math.cos(a) * 230, ny = target.y + Math.sin(a) * 160;
			var rx = Math.floor(x / Constants.ROOM_W) * Constants.ROOM_W, ry = Math.floor(y / Constants.ROOM_H) * Constants.ROOM_H;
			x = Math.max(rx + 80, Math.min(rx + Constants.ROOM_W - 140, nx));
			y = Math.max(ry + 80, Math.min(ry + Constants.ROOM_H - 100, ny));
			fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2, 1.4);
			faceTimer = 0; // it lands guardDir you
		}
		if (raiseTimer <= 0 && summonHost != null && summonHost.countLiving() < 5)
		{
			raiseTimer = phase2 ? 4.0 : 6.0;
			for (off in [-90.0, 90.0])
			{
				var s = new Skull(x + off, y);
				s.init(target);
				summonHost.add(s);
				fx.PackFx.play("skull_smoke", x + off + 22, y + 10, 0.9);
			}
		}
		// closes in fast, shield first
		if (distToTarget() > 60)
		{
			moveToward(moveSpeed * (phase2 ? 1.2 : 1));
			flipX = guardDir < 0; // moveToward flips to the target; the shield keeps its own guardDir
		}
		else
			velocity.set(0, 0);
		super.update(elapsed);
	}

	/** The shield covers the front: a hit whose source is ahead of it clangs off. */
	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (!dying && source != null)
		{
			var sx = (source.x + source.width / 2) - (x + width / 2);
			if (sx * guardDir > -10) // in front, or dead level with it
			{
				fx.PackFx.play("impact", x + width / 2 + guardDir * 30, y + height / 2, 0.8);
				fx.Sfx.play("parry", 0.5, 0.1, 0.2);
				return;
			}
		}
		super.takeHit(damage, source);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2, 2.2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.8, {onComplete: _ -> kill()});
	}
}
