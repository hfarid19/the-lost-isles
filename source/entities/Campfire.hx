package entities;

import flixel.FlxSprite;
import flixel.util.FlxTimer;

/** The user's hand-made campfire (Fire wood.aseprite): burns until hit
 * three times (arrows, swings, or blasts), dimming with each hit. */
class Campfire extends FlxSprite
{
	public var hitsLeft(default, null):Int = 3;

	/** Set by RoomController: pathfinding cell freed when the fire goes out. */
	public var navRoom:world.Room;
	public var navCell:Int = -1;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		// campfire.png: 16 frames @128 — Normal 0-6, 1hit 11-14, 2hits 7-10, Out 15
		loadGraphic("assets/images/props/campfire.png", true, 128, 128);
		animation.add("fire3", [0, 1, 2, 3, 4, 5, 6], 10);
		animation.add("fire2", [11, 12, 13, 14], 10);
		animation.add("fire1", [7, 8, 9, 10], 10);
		animation.add("out", [15], 1);
		animation.play("fire3");
		setSize(56, 28);
		offset.set(36, 96);
		immovable = true;
		moves = false;
	}

	/** Returns true if the hit connected (fire still burning). */
	public function takeHit(damage:Int = 1):Bool
	{
		if (hitsLeft <= 0)
			return false;
		hitsLeft -= damage;
		if (hitsLeft < 0)
			hitsLeft = 0;
		setColorTransform(1, 1, 1, 1, 255, 255, 255, 0);
		new FlxTimer().start(0.07, _ -> setColorTransform());
		animation.play(switch (hitsLeft)
		{
			case 3: "fire3";
			case 2: "fire2";
			case 1: "fire1";
			default: "out";
		});
		if (hitsLeft == 0)
		{
			solid = false; // cold ashes: walkable
			if (navRoom != null && navCell >= 0)
				navRoom.freeNavCell(navCell);
		}
		return true;
	}
}
