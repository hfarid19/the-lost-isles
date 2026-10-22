package fx;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

/** One-shot effects, all Tiny Swords: Free Pack Particle FX (dust, explosion) and the
 * Monk's heal sparkle. Sheets are single-row strips in assets/images/fx/ts. */
class PackFx
{
	static var defs:Map<String, {path:String, fw:Int, fh:Int, n:Int, color:Int, base:Float}> = [
		"smoke" => {path: "assets/images/fx/ts/dust2.png", fw: 64, fh: 64, n: 10, color: 0xFFFFFFFF, base: 1.0},
		"skull_smoke" => {path: "assets/images/fx/ts/dust1.png", fw: 64, fh: 64, n: 8, color: 0xFFC8A0FF, base: 1.1},
		"impact" => {path: "assets/images/fx/ts/explosion1.png", fw: 192, fh: 192, n: 8, color: 0xFFFFFFFF, base: 0.35},
		"heal" => {path: "assets/images/fx/ts/heal.png", fw: 192, fh: 192, n: 11, color: 0xFFFFFFFF, base: 0.7},
		"sparkle" => {path: "assets/images/fx/ts/heal.png", fw: 192, fh: 192, n: 11, color: 0xFFFFE080, base: 0.7},
		"coin_burst" => {path: "assets/images/fx/ts/dust2.png", fw: 64, fh: 64, n: 10, color: 0xFFFFD860, base: 1.2}
	];

	/** Added to the state by PlayState, above the actors. */
	public static var pool:FlxTypedGroup<PackFxSprite>;

	public static function play(name:String, cx:Float, cy:Float, scale:Float = 1, fps:Int = 15, angle:Float = 0):Void
	{
		if (pool == null)
			return;
		var d = defs.get(name);
		if (d == null)
			return;
		var s = pool.recycle(PackFxSprite.new);
		s.loadGraphic(d.path, true, d.fw, d.fh);
		s.animation.add("fx", [for (i in 0...d.n) i], fps, false);
		s.scale.set(scale * d.base, scale * d.base);
		s.color = d.color;
		s.angle = angle;
		s.reset(cx - d.fw / 2, cy - d.fh / 2);
		s.animation.play("fx", true);
	}
}

class PackFxSprite extends FlxSprite
{
	public function new()
	{
		super();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (animation.finished)
			kill();
	}
}
