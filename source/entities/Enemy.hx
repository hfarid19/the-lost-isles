package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

enum EnemyState
{
	IDLE;
	CHASE;
	ATTACK;
	DYING;
}

class Enemy extends FlxSprite
{
	public var hp:Int = 3;
	public var touchDamage:Int = 1;
	public var moveSpeed:Float = 120;

	/** Room pathfinding grid (water + solid props); null = chase directly. */
	public var nav:FlxTilemap;

	/** Flyers ignore water and props (their allowCollisions is NONE). */
	public var flying:Bool = false;
	/** Every enemy on the floor (set by PlayState), for units that look for comrades. */
	public static var all:flixel.group.FlxGroup.FlxTypedGroup<Enemy>;

	/** Sheep and the like: doesn't hold the room's doors shut. */
	public var harmless:Bool = false;

	/** Debug: kill outright, through shields, shells and submersion. */
	public function slay():Void
	{
		if (state == DYING)
			return;
		hp = 0;
		die();
	}

	/** A real boss (immune to the sheep hex and the harpoon's pull). */
	public function isRealBoss():Bool
		return false;

	/** Submerged sharks and the like can't be hit; arrows and swings pass through. */
	public function hittable():Bool
		return true;

	var state:EnemyState = IDLE;
	var target:Player;
	var navPath:Array<FlxPoint>;
	var repathTimer:Float = 0;
	var burnTime:Float = 0;
	var burnTick:Float = 0;
	var baseColor:FlxColor = FlxColor.WHITE;

	/** Shield-bounce skid: applied in update() after the subclass has set its own
	 * velocity, so the rebound survives the chase logic for a moment. */
	var skidTime:Float = 0;
	var skidX:Float = 0;
	var skidY:Float = 0;

	/** Bounced off the hero's raised shield: shoved back and briefly dazed.
	 * Chargers override this to end their charge. */
	public function onDeflected(p:Player):Void
	{
		if (skidTime > 0)
			return; // one bounce per contact
		var kx = (x + width / 2) - (p.x + p.width / 2);
		var ky = (y + height / 2) - (p.y + p.height / 2);
		var len = Math.max(1, Math.sqrt(kx * kx + ky * ky));
		skidX = kx / len * 520;
		skidY = ky / len * 520;
		skidTime = 0.45;
		fx.PackFx.play("impact", p.x + p.width / 2 + kx / len * 30, p.y + p.height / 2 + ky / len * 10, 0.9);
	}

	/** Set alight by a flaming arrow: damage over time + orange tint. */
	/** Harpoon item: reeled toward a point (bosses ignore it). */
	public function pullToward(px:Float, py:Float, speed:Float = 520):Void
	{
		if (state == DYING || isRealBoss())
			return;
		var dx = px - (x + width / 2), dy = py - (y + height / 2);
		var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
		skidTime = 0.22;
		skidX = dx / len * speed;
		skidY = dy / len * speed;
	}

	public function ignite():Void
	{
		if (state == DYING)
			return;
		burnTime = 2.0;
		burnTick = 0.66;
	}

	override public function update(elapsed:Float):Void
		updateCore(elapsed);

	/** The shared per-frame work (skid, burn, physics); subclasses that run their own
	 * loop instead of a parent's call this directly. */
	function updateCore(elapsed:Float):Void
	{
		if (skidTime > 0)
		{
			skidTime -= elapsed;
			velocity.set(skidX, skidY);
			skidX *= Math.pow(0.03, elapsed);
			skidY *= Math.pow(0.03, elapsed);
		}
		if (burnTime > 0)
		{
			burnTime -= elapsed;
			burnTick -= elapsed;
			color = 0xFFFFAA55;
			if (burnTick <= 0)
			{
				burnTick = 0.66;
				takeHit(1);
			}
			if (burnTime <= 0)
				color = baseColor;
		}
		super.update(elapsed);
	}

	public function init(target:Player):Void
	{
		this.target = target;
	}

	/** What dealt the last hit (explosion, arrow, player, ...). */
	public var lastHitSource:FlxSprite;

	public function takeHit(damage:Int, ?source:FlxSprite):Void
	{
		if (state == DYING)
			return;
		lastHitSource = source;
		hp -= damage;
		fx.PackFx.play("impact", x + width / 2, y + height / 2 - 10);
		fx.Sfx.play(source != null && Std.isOfType(source, Arrow) ? "arrow_hit" : (source != null && Std.isOfType(source, Player) ? "sword_hit" : "enemy_hit"), 0.6);
		// white flash
		color = FlxColor.WHITE;
		setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);
		new FlxTimer().start(0.08, _ -> setColorTransform());
		if (source != null)
		{
			var kx = (x + width / 2) - (source.x + source.width / 2);
			var ky = (y + height / 2) - (source.y + source.height / 2);
			var len = Math.max(1, Math.sqrt(kx * kx + ky * ky));
			velocity.set(kx / len * 260, ky / len * 260);
		}
		if (hp <= 0)
			die();
	}

	function die():Void
	{
		if (!harmless)
			RunState.kills++;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		fx.PackFx.play("smoke", x + width / 2, y + height / 2 - 12, 1.3);
		fx.Sfx.play("enemy_die", 0.6);
		flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.4, {onComplete: _ -> kill()});
	}

	inline function distToTarget():Float
	{
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		return Math.sqrt(dx * dx + dy * dy);
	}

	function moveToward(speed:Float):Void
	{
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		var len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
		velocity.set(dx / len * speed, dy / len * speed);
		if (dx != 0)
			flipX = dx < 0;
	}

	/** A* chase over the room's nav grid; falls back to a straight beeline
	 * when there is no grid or no path. */
	function chaseSmart(elapsed:Float, speed:Float):Void
	{
		if (nav == null)
		{
			moveToward(speed);
			return;
		}
		repathTimer -= elapsed;
		if (repathTimer <= 0)
		{
			repathTimer = 0.4;
			var from = FlxPoint.get(x + width / 2, y + height / 2);
			var to = FlxPoint.get(target.x + target.width / 2, target.y + target.height / 2);
			navPath = nav.findPath(from, to);
			// drop the first node (our own cell) so we don't backtrack
			if (navPath != null && navPath.length > 1)
				navPath.shift();
		}
		if (navPath == null || navPath.length == 0)
		{
			moveToward(speed);
			return;
		}
		var wp = navPath[0];
		var dx = wp.x - (x + width / 2);
		var dy = wp.y - (y + height / 2);
		var len = Math.sqrt(dx * dx + dy * dy);
		if (len < 12)
		{
			navPath.shift();
			if (navPath.length == 0)
			{
				moveToward(speed);
				return;
			}
			wp = navPath[0];
			dx = wp.x - (x + width / 2);
			dy = wp.y - (y + height / 2);
			len = Math.max(1, Math.sqrt(dx * dx + dy * dy));
		}
		velocity.set(dx / len * speed, dy / len * speed);
		if (dx != 0)
			flipX = dx < 0;
	}
}
