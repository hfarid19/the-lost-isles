package entities;

/** Keep healer (Free Pack Black Monk). blackmonk.png: 11 cols @192 — idle(6), run(4), heal(11).
 * Never attacks: shadows its ward and heals it every few seconds until killed. */
class BlackMonk extends Enemy
{
	public var ward:Enemy;
	var healTimer:Float = 2.0;
	var healing:Bool = false;
	var healed:Bool = false;

	public function new(x:Float, y:Float, ward:Enemy)
	{
		super(x, y);
		this.ward = ward;
		loadGraphic("assets/images/chars/blackmonk.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 10);
		animation.add("run", [for (i in 11...15) i], 12);
		animation.add("heal", [for (i in 22...33) i], 14, false);
		animation.play("idle");
		setSize(40, 32);
		offset.set(76, 102);
		hp = 4;
		moveSpeed = 170;
		touchDamage = 0;
	}

	override public function update(elapsed:Float):Void
	{
		if (state == DYING)
		{
			updateCore(elapsed);
			return;
		}
		if ((ward == null || !ward.alive) && Enemy.all != null)
		{
			// pick the nearest living comrade to tend
			var best:Enemy = null, bd = 1e12;
			Enemy.all.forEachAlive(e ->
			{
				if (e == this || e.harmless || Std.isOfType(e, BlackMonk))
					return;
				var dx = e.x - x, dy = e.y - y, d = dx * dx + dy * dy;
				if (d < bd)
				{
					bd = d;
					best = e;
				}
			});
			ward = best;
		}
		if (ward == null || !ward.alive)
		{
			// nothing left to tend: keep away from the hero
			velocity.set(0, 0);
			if (target != null && distToTarget() < 220)
			{
				var dx = (x + width / 2) - (target.x + target.width / 2), dy = (y + height / 2) - (target.y + target.height / 2);
				var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
				velocity.set(dx / len * moveSpeed, dy / len * moveSpeed);
				flipX = dx < 0;
				if (animation.name != "run")
					animation.play("run");
			}
			else if (animation.name != "idle")
				animation.play("idle");
			updateCore(elapsed);
			return;
		}
		healTimer -= elapsed;
		var dx = (ward.x + ward.width / 2) - (x + width / 2), dy = (ward.y + ward.height / 2) - (y + height / 2);
		var d = Math.sqrt(dx * dx + dy * dy);
		if (healing)
		{
			velocity.set(0, 0);
			if (!healed && animation.curAnim != null && animation.curAnim.curFrame >= 6)
			{
				healed = true;
				ward.hp = Std.int(Math.min(ward.hp + 2, Std.isOfType(ward, BossBase) ? cast(ward, BossBase).maxHp : ward.hp + 2));
				fx.PackFx.play("heal", ward.x + ward.width / 2, ward.y + ward.height / 2 - 20, 1.2);
				fx.Sfx.play("item", 0.4);
			}
			if (animation.finished)
			{
				healing = false;
				healTimer = 3.0;
			}
			updateCore(elapsed);
			return;
		}
		if (d > 120)
		{
			var len = Math.max(1, d);
			velocity.set(dx / len * moveSpeed, dy / len * moveSpeed);
			flipX = dx < 0;
			if (animation.name != "run")
				animation.play("run");
		}
		else
		{
			velocity.set(0, 0);
			if (healTimer <= 0)
			{
				healing = true;
				healed = false;
				animation.play("heal", true);
			}
			else if (animation.name != "idle")
				animation.play("idle");
		}
		updateCore(elapsed);
	}
}
