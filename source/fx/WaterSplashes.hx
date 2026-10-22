package fx;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

/** Ambient ocean life: random one-shot splashes anywhere in the current view.
 * Add just above the water backdrop — land drawn later hides them, so they
 * only ever read as happening in open water. */
class WaterSplashes extends FlxTypedGroup<FlxSprite>
{
	var timer:Float = 0;

	public function new()
	{
		super(12);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		forEachAlive(s ->
		{
			if (s.animation.finished)
				s.kill();
		});
		timer -= elapsed;
		if (timer <= 0)
		{
			timer = FlxG.random.float(0.5, 1.6);
			spawn();
		}
	}

	function spawn():Void
	{
		var s = recycle(FlxSprite);
		s.loadGraphic("assets/images/vfx/water_splash.png", true, 192, 192);
		s.animation.add("fx", [0, 1, 2, 3, 4, 5, 6, 7, 8], 12, false);
		var scl = FlxG.random.float(0.5, 0.9);
		s.scale.set(scl, scl);
		s.reset(FlxG.camera.scroll.x + FlxG.random.float(-60, FlxG.width - 130),
			FlxG.camera.scroll.y + FlxG.random.float(-60, FlxG.height - 130));
		s.animation.play("fx", true);
	}
}
