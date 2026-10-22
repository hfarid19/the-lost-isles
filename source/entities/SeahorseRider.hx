package entities;

import flixel.FlxG;

/** Shark Waters (Enemy Pack Extra Seahorse Boat, 8 frames @192): a shark on a seahorse boat that
 * circles the islet on the water, never diving, and throws a harpoon or drops a lit bomb every
 * few seconds. Always hittable, unlike the swimmers. */
class SeahorseRider extends Enemy
{
	public var bomber(default, null):Bool;
	var goalX:Float = 0;
	var goalY:Float = 0;
	var hasGoal:Bool = false;
	var shootTimer:Float = 2.0;

	public function new(x:Float, y:Float, ?bomber:Bool)
	{
		super(x, y);
		this.bomber = bomber == null ? FlxG.random.bool(40) : bomber;
		loadGraphic(this.bomber ? "assets/images/chars/seahorse_bomb.png" : "assets/images/chars/seahorse_harpoon.png", true, 192, 192);
		animation.add("ride", [for (i in 0...8) i], 10);
		animation.play("ride");
		setSize(70, 40);
		offset.set(60, 110);
		hp = 5;
		moveSpeed = 120;
		flying = true; // rides the water, ignores the islet's collision
		touchDamage = 1;
	}

	/** A random water cell of the room, away from the hero. */
	function pickGoal():Void
	{
		if (WaterEnemy.roomAt == null || target == null)
			return;
		var room = WaterEnemy.roomAt(x + width / 2, y + height / 2);
		if (room == null)
			return;
		var cells = [];
		for (cy in 0...room.th)
			for (cx in 0...room.tw)
				if (room.template.ground[cy * room.tw + cx] != 1)
					cells.push({cx: cx, cy: cy});
		if (cells.length == 0)
			return;
		for (i in 0...6)
		{
			var c = cells[FlxG.random.int(0, cells.length - 1)];
			var wx = room.worldX + c.cx * Constants.TILE + 32, wy = room.worldY + c.cy * Constants.TILE + 32;
			var dx = wx - (target.x + target.width / 2), dy = wy - (target.y + target.height / 2);
			if (dx * dx + dy * dy > 200 * 200 || i == 5)
			{
				goalX = wx;
				goalY = wy;
				hasGoal = true;
				return;
			}
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (state == DYING || target == null)
		{
			velocity.set(0, 0);
			updateCore(elapsed);
			return;
		}
		shootTimer -= elapsed;
		if (!hasGoal)
			pickGoal();
		if (hasGoal)
		{
			var dx = goalX - (x + width / 2), dy = goalY - (y + height / 2);
			var len = Math.sqrt(dx * dx + dy * dy);
			if (len < 10)
				hasGoal = false;
			else
			{
				velocity.set(dx / len * moveSpeed, dy / len * moveSpeed);
				flipX = dx < 0;
			}
		}
		else
			velocity.set(0, 0);
		if (shootTimer <= 0 && distToTarget() < 480)
		{
			shootTimer = bomber ? 3.2 : 2.6;
			var cx = x + width / 2, cy = y + height / 2 - 10;
			var tx = target.x + target.width / 2 - cx, ty = target.y + target.height / 2 - cy;
			var len = Math.max(1, Math.sqrt(tx * tx + ty * ty));
			if (bomber)
			{
				if (Dynamite.pool != null)
					Dynamite.pool.recycle(Dynamite.new).plant(target.x + target.width / 2 + FlxG.random.float(-40, 40), target.y + target.height / 2 + FlxG.random.float(-30, 30), 2.0);
				fx.Sfx.play("fuse", 0.6);
			}
			else
			{
				EnemyShot.fire("harpoon", cx, cy, tx / len, ty / len, 420);
				fx.Sfx.play("throw", 0.6);
			}
		}
		updateCore(elapsed);
	}

	override function die():Void
	{
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 1.3);
		fx.Sfx.play("splash", 0.8, 0.1);
		super.die();
	}
}
