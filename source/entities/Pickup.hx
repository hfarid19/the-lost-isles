package entities;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

enum PickupType
{
	Meat;
	Gold;
	Bomb;
	Key;
}

class Pickup extends FlxSprite
{
	/** Set by PlayState so enemies can drop pickups mid-run. */
	public static var group:flixel.group.FlxGroup.FlxTypedGroup<Pickup>;

	public var type(default, null):PickupType;

	public function new(x:Float, y:Float, type:PickupType)
	{
		super(x, y);
		this.type = type;
		switch (type)
		{
			case Meat:
				loadGraphic("assets/images/pickups/meat.png");
				scale.set(0.5, 0.5);
			case Gold:
				loadGraphic("assets/images/pickups/gold.png");
				scale.set(0.5, 0.5);
			case Bomb:
				loadGraphic("assets/images/fx/dynamite.png", true, 64, 64);
				animation.frameIndex = 0;
				scale.set(0.85, 0.85);
			case Key:
				loadGraphic("assets/images/ui/icon_key.png");
				scale.set(0.7, 0.7);
		}
		updateHitbox();
		FlxTween.tween(this, {y: y - 8}, 0.8, {type: PINGPONG, ease: FlxEase.quadInOut});
	}
}
