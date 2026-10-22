package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

/** Isaac-style follower: trails the hero (or the previous familiar) in a conga
 * line and does one thing on its own. Tiny Swords sheets baked at 0.5x. */
class Familiar extends FlxSprite
{
	/** Set by PlayState each floor; familiars are re-spawned from the item list. */
	public static var group:FlxTypedGroup<Familiar>;
	public static var enemies:FlxTypedGroup<Enemy>;
	public static var player:Player;

	public var kind(default, null):String;

	var leader:FlxSprite;
	var timer:Float = 0;

	public static function spawn(kind:String):Familiar
	{
		if (group == null || player == null)
			return null;
		var f = new Familiar(kind);
		// follow the last familiar in line, or the hero
		var last:FlxSprite = player;
		group.forEachAlive(o -> last = o);
		f.leader = last;
		f.setPosition(last.x, last.y + 20);
		group.add(f);
		return f;
	}

	function new(kind:String)
	{
		super();
		this.kind = kind;
		switch (kind)
		{
			case "panda":
				// Enemy Pack Panda baked at 0.5x: 10 cols @128 — idle(10), run(6)
				loadGraphic("assets/images/chars/fam_panda.png", true, 128, 128);
				animation.add("idle", [for (i in 0...10) i], 10);
				animation.add("run", [for (i in 10...16) i], 12);
				setSize(54, 40);
				offset.set(36, 46);
			default:
				// Enemy Pack Skull baked at 0.5x: 8 cols @96 — idle(8), run(6)
				loadGraphic("assets/images/chars/fam_skull.png", true, 96, 96);
				animation.add("idle", [for (i in 0...8) i], 10);
				animation.add("run", [for (i in 8...14) i], 12);
				setSize(36, 36);
				offset.set(30, 29);
		}
		animation.play("idle");
		timer = FlxG.random.float(0, 1);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (leader == null || !leader.alive)
			leader = player;
		// smoothed follow: stay ~36 px behind the leader's centre
		var lx = leader.x + leader.width / 2 - width / 2;
		var ly = leader.y + leader.height / 2 - height / 2 + 26;
		var dx = lx - x, dy = ly - y;
		var dist = Math.sqrt(dx * dx + dy * dy);
		if (dist > 36)
		{
			var k = Math.min(1, elapsed * 6);
			x += dx * k;
			y += dy * k;
			if (animation.name != "run")
				animation.play("run");
		}
		else if (animation.name != "idle")
			animation.play("idle");
		if (dx != 0)
			flipX = dx < 0;

		timer -= elapsed;
		if (timer > 0 || enemies == null)
			return;
		switch (kind)
		{
			case "panda": // swipes any enemy that gets close to the hero
				timer = 1.0;
				var pcx = player.x + player.width / 2, pcy = player.y + player.height / 2;
				enemies.forEachAlive(e ->
				{
					var ex = e.x + e.width / 2 - pcx, ey = e.y + e.height / 2 - pcy;
					if (ex * ex + ey * ey < 60 * 60 && timer > 0.99)
					{
						e.takeHit(1, this);
						fx.Sfx.play("swipe", 0.5);
						fx.PackFx.play("impact", e.x + e.width / 2, e.y + e.height / 2, 0.7);
						timer = 1.0;
					}
				});
			default: // bone buddy: lobs a bone at the nearest enemy every 1.5 s
				timer = 1.5;
				var best:Enemy = null, bd = 1e9;
				enemies.forEachAlive(e ->
				{
					var ex = e.x - x, ey = e.y - y;
					var d = ex * ex + ey * ey;
					if (d < bd)
					{
						bd = d;
						best = e;
					}
				});
				if (best != null && bd < 420 * 420 && combat.Bow.pool != null)
				{
					var ex = best.x + best.width / 2 - (x + width / 2), ey = best.y + best.height / 2 - (y + height / 2);
					var len = Math.max(1, Math.sqrt(ex * ex + ey * ey));
					var a = combat.Bow.pool.recycle(Arrow.new);
					a.fireBone(x + width / 2, y + height / 2, ex / len, ey / len, 1, 420);
					fx.Sfx.play("throw", 0.4);
				}
		}
	}
}
