package fx;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

/** Rain streaks pinned to the screen, plus lightning flashes in a storm. */
class Weather extends FlxTypedGroup<FlxSprite>
{
	public var storm(default, null):Bool;

	var flashTimer:Float = 0;

	public function new(storm:Bool)
	{
		super();
		this.storm = storm;
		var n = storm ? 140 : 80;
		for (i in 0...n)
		{
			var d = new FlxSprite();
			d.makeGraphic(2, storm ? 18 : 12, FlxColor.fromRGBFloat(0.85, 0.92, 1, storm ? 0.55 : 0.4), false, storm ? "rainS" : "rainL");
			d.scrollFactor.set(0, 0);
			d.angle = storm ? 18 : 10;
			d.setPosition(FlxG.random.float(0, FlxG.width), FlxG.random.float(0, FlxG.height));
			d.velocity.set(storm ? -220 : -110, storm ? 820 : 560);
			add(d);
		}
		flashTimer = FlxG.random.float(4, 9);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		forEachAlive(d ->
		{
			if (d.y > FlxG.height)
			{
				d.y = -20;
				d.x = FlxG.random.float(0, FlxG.width + 120);
			}
			if (d.x < -20)
				d.x = FlxG.width + 10;
		});
		if (storm)
		{
			flashTimer -= elapsed;
			if (flashTimer <= 0)
			{
				flashTimer = FlxG.random.float(5, 12);
				fx.Juice.flash(FlxColor.fromRGBFloat(1, 1, 1, 0.35), 0.12);
				flixel.util.FlxTimer.wait(FlxG.random.float(0.3, 0.9), () -> fx.Sfx.play("stomp", 0.5, 0.2));
			}
		}
	}
}
