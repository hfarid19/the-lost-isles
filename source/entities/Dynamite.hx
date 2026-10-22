package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

/** Lobbed bomb: flies on a faked arc to a target point, fuses, then explodes. */
class Dynamite extends FlxSprite
{
	public static var explosions:FlxTypedGroup<Explosion>;

	/** Shared bomb pool (enemy throws and player E-bombs). Set by PlayState. */
	public static var pool:FlxTypedGroup<Dynamite>;

	static inline var FLIGHT:Float = 0.7;
	static inline var FUSE:Float = 0.5;

	var t:Float = 0;
	var startX:Float = 0;
	var startY:Float = 0;
	var endX:Float = 0;
	var endY:Float = 0;
	var fusing:Bool = false;
	var fuse:Float = 0;

	public function new()
	{
		super();
		// dynamite.png: 6 frames @64, lit stick spin
		loadGraphic("assets/images/fx/dynamite.png", true, 64, 64);
		animation.add("spin", [0, 1, 2, 3, 4, 5], 12);
		setSize(24, 24);
		centerOffsets();
	}

	public function lob(fromX:Float, fromY:Float, toX:Float, toY:Float):Void
	{
		reset(fromX, fromY);
		angle = 0;
		color = 0xFFFFFFFF;
		fuseTotal = FUSE;
		animation.resume();
		startX = fromX;
		startY = fromY;
		endX = toX;
		endY = toY;
		t = 0;
		fusing = false;
		fuse = FUSE;
		animation.play("spin");
	}

	var fuseTotal:Float = 2.0;
	var sparkTimer:Float = 0;

	/** Player bomb: set down in place with a long fuse (no arc). */
	public function plant(cx:Float, cy:Float, fuseTime:Float = 2.0):Void
	{
		reset(cx - width / 2, cy - height / 2);
		fusing = true;
		fuse = fuseTime;
		fuseTotal = fuseTime;
		animation.play("spin");
		animation.pause();
		animation.frameIndex = 0; // planted: upright, lit
		color = 0xFFFFFFFF;
		sparkTimer = 0;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!fusing)
		{
			t += elapsed / FLIGHT;
			if (t >= 1)
			{
				t = 1;
				fusing = true;
			}
			var arc = -140 * Math.sin(t * Math.PI); // fake height
			x = startX + (endX - startX) * t;
			y = startY + (endY - startY) * t + arc;
		}
		else
		{
			fuse -= elapsed;
			// on the ground: the fuse sparks, and the stick flashes red faster and faster
			var frac = Math.max(0, fuse / fuseTotal);
			var rate = 2 + (1 - frac) * 14; // flashes per second
			var on = Std.int(FlxG.game.ticks / (500 / rate)) % 2 == 0;
			color = on && !animation.curAnim.finished ? 0xFFFF7060 : 0xFFFFFFFF;
			var wobble = Math.sin(FlxG.game.ticks / 40) * (1 - frac) * 6;
			angle = wobble;
			sparkTimer -= elapsed;
			if (sparkTimer <= 0)
			{
				sparkTimer = 0.12 + frac * 0.2;
				fx.PackFx.play("sparkle", x + width / 2 + 6, y - 6, 0.35, 15);
			}
			if (fuse <= 0)
			{
				angle = 0;
				color = 0xFFFFFFFF;
				if (explosions != null)
					explosions.recycle(Explosion.new).boom(x + width / 2, y + height / 2);
				kill();
			}
		}
	}
}
