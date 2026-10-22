package entities;

import Constants.*;
import flixel.FlxSprite;
import flixel.math.FlxAngle;

/** Player arrow. Flies over water; dies on lifetime or when leaving the room area. */
class Arrow extends FlxSprite
{
	public var damage:Int = 1;

	/** Lit by flying through a burning campfire; ignites what it hits. */
	public var flaming(default, null):Bool = false;
	/** Already chopped a campfire this flight (each arrow costs a fire one charge at most). */
	public var hitFire:Bool = false;

	var life:Float = 0;

	public function new()
	{
		super();
		// 64x128 sheet: frame 0 = flying arrow (points right), frame 1 = stuck-in-ground
		loadGraphic("assets/images/fx/arrow.png", true, 64, 64);
		animation.frameIndex = 0;
		setSize(16, 16);
		centerOffsets();
		// hitbox stays on the feet plane; graphic rides 32px higher so the
		// arrow visually leaves the bow (top-down depth cheat)
		offset.y += 32;
	}

	var isBone:Bool = false;

	/** Bone Buddy's throw: a spinning bone instead of an arrow. */
	public function fireBone(fromX:Float, fromY:Float, aimX:Float, aimY:Float, dmg:Int = 1, range:Float = 420):Void
	{
		fire(fromX, fromY, aimX, aimY, dmg, range);
		loadGraphic("assets/images/fx/bone.png");
		isBone = true;
		angle = 0;
		angularVelocity = 720;
		velocity.scale(0.75);
		life = range / (ARROW_SPEED * 0.75);
	}

	public function fire(fromX:Float, fromY:Float, aimX:Float, aimY:Float, dmg:Int = 1, range:Float = 360):Void
	{
		if (isBone)
		{
			loadGraphic("assets/images/fx/arrow.png", true, 64, 64);
			animation.frameIndex = 0;
			isBone = false;
		}
		angularVelocity = 0;
		reset(fromX - width / 2, fromY - height / 2);
		velocity.set(aimX * ARROW_SPEED, aimY * ARROW_SPEED);
		angle = FlxAngle.asDegrees(Math.atan2(aimY, aimX)); // graphic points right
		damage = dmg;
		life = range / ARROW_SPEED;
		flaming = false;
		hitFire = false;
		color = 0xFFFFFFFF;
	}

	public function ignite():Void
	{
		flaming = true;
		color = 0xFFFF9933; // burning tint
	}

	override public function update(elapsed:Float):Void
	{
		life -= elapsed;
		if (life <= 0)
			kill();
		super.update(elapsed);
	}
}
