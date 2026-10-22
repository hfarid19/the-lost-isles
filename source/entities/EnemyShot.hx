package entities;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

/** Enemy projectiles: cannonballs and the shaman's bolts. PlayState overlaps them with the player. */
class EnemyShot extends FlxSprite
{
	public static var pool:FlxTypedGroup<EnemyShot>;

	/** Ground hazards (the torch goblin's fire trail, acid puddles): drawn under the actors. */
	public static var groundPool:FlxTypedGroup<EnemyShot>;

	public var kind(default, null):String = "ball";
	public var damage:Int = 1;

	var life:Float = 0;
	var puddle:Float = 0; // acid: seconds to linger once it stops

	public function new()
	{
		super();
	}

	public function setLife(seconds:Float):Void
		life = seconds;

	/** Acid glob: after 0.6 s of flight it drops and lingers as a puddle. */
	public function puddleOnStop(seconds:Float):Void
	{
		puddle = seconds;
		life = 0.6;
	}

	public static function fire(kind:String, fromX:Float, fromY:Float, dirX:Float, dirY:Float, speed:Float):EnemyShot
	{
		if (pool == null)
			return null;
		var onGround = speed == 0 && groundPool != null; // a stationary hazard
		var s = (onGround ? groundPool : pool).recycle(EnemyShot.new);
		s.kind = kind;
		switch (kind)
		{
			case "hex":
				s.loadGraphic("assets/images/fx/hex_bolt.png", true, 128, 128);
				s.animation.add("spin", [0, 1, 2], 10);
				s.animation.play("spin");
				s.color = 0xFFC8FF80; // the sheep hex glows green
				s.scale.set(1.2, 1.2);
			case "bolt":
				s.loadGraphic("assets/images/fx/hex_bolt.png", true, 128, 128);
				s.animation.add("spin", [0, 1, 2], 10);
				s.animation.play("spin");
				s.color = 0xFFFFFFFF;
				s.scale.set(0.8, 0.8);
			case "gnollbone":
				s.loadGraphic("assets/images/fx/gnoll_bone.png", true, 64, 64);
				s.animation.add("spin", [0, 1, 2, 3], 12);
				s.animation.play("spin");
				s.color = 0xFFFFFFFF;
				s.scale.set(1, 1);
			case "acid":
				s.loadGraphic("assets/images/fx/hex_bolt.png", true, 128, 128);
				s.animation.add("spin", [0, 1, 2], 10);
				s.animation.play("spin");
				s.color = 0xFF90FF60;
				s.scale.set(0.9, 0.9);
			case "acorn":
				s.loadGraphic("assets/images/fx/acorn.png", true, 64, 64);
				s.animation.add("spin", [0, 1, 2, 3], 12);
				s.animation.play("spin");
				s.color = 0xFFFFFFFF;
				s.scale.set(1, 1);
			case "harpoon":
				s.loadGraphic("assets/images/fx/harpoon.png");
				s.color = 0xFFFFFFFF;
				s.scale.set(1, 1);
				s.angle = Math.atan2(dirY, dirX) * 180 / Math.PI + 45; // the sprite points up-right
			case "flood":
				s.makeGraphic(64, 64, 0x9A56B8D0, false, "floodTile");
				s.color = 0xFFFFFFFF;
				s.scale.set(1, 1);
			case "arrow":
				s.loadGraphic("assets/images/fx/black_arrow.png");
				s.color = 0xFFFFFFFF;
				s.scale.set(1, 1);
				s.angle = Math.atan2(dirY, dirX) * 180 / Math.PI;
			case "fire":
				// fire.png: 7 frames @128; ground flame drawn small, hitbox at its base
				s.loadGraphic("assets/images/fx/fire.png", true, 128, 128);
				s.animation.add("burn", [0, 1, 2, 3, 4, 5, 6], 14);
				s.animation.play("burn");
				s.color = 0xFFFFFFFF;
				s.scale.set(0.55, 0.55);
			default:
				s.loadGraphic("assets/images/fx/cannon_ball.png");
				s.color = 0xFFFFFFFF;
				s.scale.set(1, 1);
		}
		s.setSize(24, 24);
		s.centerOffsets();
		if (kind == "flood")
		{
			s.setSize(56, 56);
			s.centerOffsets();
		}
		if (kind == "fire")
			s.offset.y += 22; // flame rises out of its hitbox instead of centring on it
		s.reset(fromX - 12, fromY - 12);
		s.velocity.set(dirX * speed, dirY * speed);
		s.life = 2.6;
		s.puddle = 0;
		s.angularVelocity = 0;
		return s;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		life -= elapsed;
		if (life <= 0)
		{
			if (puddle > 0)
			{
				// land: flatten into a lingering puddle
				velocity.set(0, 0);
				life = puddle;
				puddle = 0;
				scale.set(1.6, 0.7);
				alpha = 0.8;
				return;
			}
			alpha = 1;
			kill();
		}
	}
}
