package entities;

import Constants.*;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/** The rowing boat that docks at the boss room after the kill. boat.png: 8 frames @256.
 * Hitbox = the water tile it is moored on; stepping onto it leaves the floor. */
class Boat extends FlxSprite
{
	public function new()
	{
		super();
		loadGraphic("assets/images/props/boat.png", true, 256, 256);
		animation.add("idle", [for (i in 0...8) i], 8);
		animation.play("idle");
		setSize(TILE, TILE);
		offset.set(96, 100); // art body x54-201, y74-184 in the frame
	}

	/** Drift in from off-shore and moor on the given tile of the room. */
	public function dock(room:world.Room, cx:Int, cy:Int, fromDir:Int):Void
	{
		var tx = room.worldX + cx * TILE;
		var ty = room.worldY + cy * TILE;
		var sx = tx, sy = ty;
		switch (fromDir)
		{
			case world.FloorMap.N: sy -= 220;
			case world.FloorMap.S: sy += 220;
			case world.FloorMap.E: sx += 300;
			default: sx -= 300;
		}
		reset(sx, sy);
		fx.Sfx.play("boat", 0.7);
		// the art is a side-on hull: turn it to face the way it drifts in
		angle = switch (fromDir)
		{
			case world.FloorMap.N: 90;
			case world.FloorMap.S: -90;
			default: 0;
		}
		flipX = fromDir == world.FloorMap.E;
		FlxTween.tween(this, {x: tx, y: ty}, 1.6, {ease: FlxEase.quadOut});
	}
}
