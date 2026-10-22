package entities;

import flixel.FlxG;

/** Caves boss: swoops across the chamber in arcs and screeches to call cave bats;
 * at half HP the swoops come faster. giantbat.png: 7x3 @192 — idle(6), move(4), attack(7). */
class GiantBat extends BossBase
{
	var phase2:Bool = false;
	var swoopTimer:Float = 1.5;
	var swooping:Float = 0;
	var screechTimer:Float = 6.0;
	var hitThisSwoop:Bool = false;
	var hover:Float = 0;
	var roomX:Float;
	var roomY:Float;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/giantbat.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 12);
		animation.add("move", [for (i in 7...11) i], 14);
		animation.add("attack", [for (i in 14...21) i], 16, false);
		animation.play("idle");
		scale.set(1.8, 1.8);
		setSize(90, 50);
		offset.set(51, 94);
		setScaledHp(26);
		touchDamage = 1;
		moveSpeed = 160;
		flying = true;
		roomX = Math.floor(x / Constants.ROOM_W) * Constants.ROOM_W;
		roomY = Math.floor(y / Constants.ROOM_H) * Constants.ROOM_H;
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
			baseColor = 0xFFD0B0FF;
			color = baseColor;
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}
		hover += elapsed * 3;
		swoopTimer -= elapsed;
		screechTimer -= elapsed;
		var d = distToTarget();
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		if (swooping > 0)
		{
			swooping -= elapsed;
			if (!hitThisSwoop && d < 80)
			{
				hitThisSwoop = true;
				target.hurt2(touchDamage, this);
			}
			if (swooping <= 0)
				velocity.set(0, 0);
		}
		else if (swoopTimer <= 0)
		{
			swoopTimer = phase2 ? 1.6 : 2.6;
			swooping = 0.7;
			hitThisSwoop = false;
			animation.play("attack", true);
			// aim past the hero so the arc carries through
			var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
			velocity.set(dx / len * 620, dy / len * 620);
			flipX = dx < 0;
		}
		else
		{
			// circle at mid range, bobbing
			if (animation.name != "move" && animation.finished) animation.play("move");
			var wantX = target.x + Math.cos(hover * 0.6) * 260 - width / 2;
			var wantY = target.y + Math.sin(hover * 0.6) * 140 - height / 2 - 40;
			// stay inside the chamber
			wantX = Math.max(roomX + 70, Math.min(roomX + Constants.ROOM_W - 70 - width, wantX));
			wantY = Math.max(roomY + 70, Math.min(roomY + Constants.ROOM_H - 60 - height, wantY));
			velocity.set((wantX - x) * 2.5, (wantY - y) * 2.5 + Math.sin(hover) * 40);
			flipX = velocity.x < 0;
		}
		if (screechTimer <= 0 && summonHost != null && summonHost.countLiving() < 5)
		{
			screechTimer = phase2 ? 5.0 : 7.0;
			fx.Juice.shake(0.003, 0.3);
			for (off in [-120.0, 120.0])
			{
				var b = new Bat(x + off, y);
				b.init(target);
				b.takeHit(0); // born awake
				summonHost.add(b);
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
		fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2, 2);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.8, {onComplete: _ -> kill()});
	}
}
