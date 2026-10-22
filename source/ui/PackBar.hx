package ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;

/** Health/boss bar assembled from the Tiny Swords 3-slice bar kits.
 * Base sheets are 5x1 @64 (frames 0=left cap, 2=middle, 4=right cap) with
 * the cap art flush toward the bar; fill sheets are one 64px segment. */
class PackBar extends FlxSpriteGroup
{
	// measured art bounds inside the 64px frames
	static inline var SMALL_CAP_W:Int = 15;
	static inline var BIG_CAP_W:Int = 24;

	var fillGroup:FlxSpriteGroup;
	var innerW:Float;
	var innerX:Float;

	public function new(x:Float, y:Float, middles:Int, big:Bool, segments:Int = 0)
	{
		super(x, y);
		var base = big ? "assets/images/ui/bigbar_base.png" : "assets/images/ui/smallbar_base.png";
		var fill = big ? "assets/images/ui/bigbar_fill.png" : "assets/images/ui/smallbar_fill.png";
		var capW = big ? BIG_CAP_W : SMALL_CAP_W;

		inline function piece(frame:Int, px:Float):FlxSprite
		{
			var s = new FlxSprite(px, 0);
			s.loadGraphic(base, true, 64, 64);
			s.animation.frameIndex = frame;
			return s;
		}

		// left cap art is right-flush in its frame: shift so art starts at 0
		add(piece(0, capW - 64));
		for (i in 0...middles)
			add(piece(2, capW + i * 64));
		add(piece(4, capW + middles * 64));

		fillGroup = new FlxSpriteGroup();
		if (big)
		{
			innerX = capW;
			innerW = middles * 64;
			for (i in 0...middles)
			{
				var f = new FlxSprite(innerX + i * 64, 0);
				f.loadGraphic(fill);
				fillGroup.add(f);
			}
		}
		else
		{
			// measured: the small frame's slot spans x10..(caps+middles+5), rows 30-35
			innerX = 10;
			innerW = capW + middles * 64 + 5 - innerX;
			var f = new FlxSprite(innerX, 30);
			f.makeGraphic(Std.int(innerW), 6, flixel.util.FlxColor.fromRGB(206, 62, 56));
			fillGroup.add(f);
		}
		add(fillGroup);

		// segment dividers: dark ticks splitting the fill into HP pips
		if (segments > 1)
			for (i in 1...segments)
			{
				var tick = new FlxSprite(innerX + innerW * i / segments - 1, big ? 20 : 29);
				tick.makeGraphic(2, big ? 24 : 8, flixel.util.FlxColor.fromRGB(22, 28, 46));
				add(tick);
			}
		setFraction(1);
	}

	public function setFraction(frac:Float):Void
	{
		frac = Math.max(0, Math.min(1, frac));
		// clip in group-local coordinates, over the inner segment run
		fillGroup.clipRect = FlxRect.get(0, 0, frac <= 0 ? 0 : innerX + innerW * frac, 64);
	}
}
