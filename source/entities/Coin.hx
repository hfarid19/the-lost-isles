package entities;

import flixel.FlxG;
import flixel.FlxSprite;

/** Gold drop (money bag). Scatters on spawn, then sits until collected. */
class Coin extends FlxSprite
{
	public function new()
	{
		super();
		loadGraphic("assets/images/pickups/goldbag.png"); // 128x128
		scale.set(0.45, 0.45);
		updateHitbox();
		drag.set(400, 400);
	}

	public function drop(cx:Float, cy:Float):Void
	{
		reset(cx - width / 2, cy - height / 2);
		velocity.set(FlxG.random.float(-160, 160), FlxG.random.float(-160, 160));
	}
}
