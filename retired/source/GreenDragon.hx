package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

/** Final boss: a segmented dragon (Ninja Adventure parts at 2x). The head is
 * the enemy (only it takes damage); body segments trail its path and hurt on
 * touch. It flies figure-eights over the arena; at half HP it lands every few
 * seconds to breathe fire in a spread. */
class GreenDragon extends BossBase
{
	/** Body segments, wings and tail; PlayState adds this under the head and overlaps the hero with it. */
	public var parts(default, null):FlxTypedGroup<FlxSprite>;

	var segs:Array<FlxSprite> = [];
	var wings:Array<FlxSprite> = [];
	var history:Array<{x:Float, y:Float}> = [];
	var t:Float = 0;
	var cx:Float;
	var cy:Float;
	var phase2:Bool = false;
	var landTimer:Float = 6.0;
	var landed:Float = 0;
	var breath:Float = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/dragon_head.png");
		scale.set(2, 2);
		setSize(60, 50);
		offset.set(-8, -2);
		setScaledHp(30);
		touchDamage = 1;
		flying = true;
		cx = x;
		cy = y;

		parts = new FlxTypedGroup<FlxSprite>();
		for (i in 0...2)
		{
			var w = new FlxSprite(0, 0, "assets/images/boss/dragon_wing.png");
			w.scale.set(2, 2);
			w.flipX = i == 1;
			wings.push(w);
			parts.add(w);
		}
		for (p in ["body1", "body2", "body1", "body2", "bodyend"])
		{
			var s = new FlxSprite(0, 0, 'assets/images/boss/dragon_$p.png');
			s.scale.set(2, 2);
			s.updateHitbox();
			segs.push(s);
			parts.add(s);
		}
		for (i in 0...80)
			history.push({x: x, y: y});
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
			baseColor = 0xFFFFC0A0;
			color = baseColor;
		}
		if (target == null)
		{
			super.update(elapsed);
			return;
		}

		if (landed > 0)
		{
			// grounded: breathe fire at the hero in a 3-way spread
			landed -= elapsed;
			velocity.set(0, 0);
			breath -= elapsed;
			if (breath <= 0)
			{
				breath = 0.28;
				fx.Sfx.play("fire", 0.6, 0.08, 0.2);
				var dx = (target.x + target.width / 2) - (x + width / 2);
				var dy = (target.y + target.height / 2) - (y + height / 2);
				var a = Math.atan2(dy, dx);
				for (off in [-0.35, 0.0, 0.35])
					EnemyShot.fire("fire", x + width / 2, y + height / 2, Math.cos(a + off), Math.sin(a + off), 300);
			}
		}
		else
		{
			// figure-eight over the arena; faster in phase 2
			t += elapsed * (phase2 ? 0.9 : 0.65);
			var tx = cx + Math.sin(t) * 380;
			var ty = cy + Math.sin(t * 2) * 150;
			velocity.set((tx - x) * 3, (ty - y) * 3);
			flipX = velocity.x < 0;
			if (phase2)
			{
				landTimer -= elapsed;
				if (landTimer <= 0)
				{
					landTimer = 7.0;
					landed = 2.6;
					breath = 0.3;
				}
			}
		}
		super.update(elapsed);

		// trail: segments sample the head's past positions
		history.unshift({x: x + width / 2, y: y + height / 2});
		history.pop();
		for (i in 0...segs.length)
		{
			var h = history[Std.int(Math.min(history.length - 1, (i + 1) * 9))];
			var s = segs[i];
			s.setPosition(h.x - s.width / 2, h.y - s.height / 2);
		}
		var flap = 1 + Math.sin(FlxG.game.ticks / 90) * 0.25;
		for (i in 0...2)
		{
			var w = wings[i];
			var h = history[9];
			w.scale.set(2, 2 * flap);
			w.updateHitbox();
			w.setPosition(h.x + (i == 0 ? -w.width - 6 : 6), h.y - w.height / 2 - 20);
		}
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.Juice.shake(0.008, 0.6);
		fx.PackFx.play("skull_smoke", x + width / 2, y + height / 2, 2.5);
		for (s in segs)
			flixel.tweens.FlxTween.tween(s, {alpha: 0}, 0.9);
		for (w in wings)
			flixel.tweens.FlxTween.tween(w, {alpha: 0}, 0.9);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 1.0, {onComplete: _ -> kill()});
	}
}
