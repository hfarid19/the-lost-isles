package entities;

import Constants.*;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/** Level exit into or out of the Caves: rises out of the ground on a grass tile
 * of the boss room. cave.png: 8 frames @192. Hitbox = the tile in front of it. */
class CaveMouth extends FlxSprite
{
	public function new()
	{
		super();
		loadGraphic("assets/images/props/cave.png", true, 192, 192);
		animation.add("idle", [for (i in 0...8) i], 8);
		animation.play("idle");
		setSize(TILE, 40);
		offset.set(64, 130);
		alpha = 0;
	}

	public function rise(room:world.Room, cx:Int, cy:Int):Void
	{
		reset(room.worldX + cx * TILE, room.worldY + cy * TILE + 12);
		scale.set(0.6, 0.6);
		FlxTween.tween(this, {alpha: 1}, 0.8);
		FlxTween.tween(scale, {x: 1, y: 1}, 0.8, {ease: FlxEase.backOut});
		fx.Juice.shake(0.004, 0.5);
		fx.Sfx.play("rumble", 0.8);
	}
}
