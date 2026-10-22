package entities;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxColor;

/** Short-lived invisible melee hurtbox. Each target is hit at most once
 * per swing (overlap fires every frame while alive). */
class MeleeSwing extends FlxSprite
{
	public var damage:Int = 2;

	var life:Float = 0;
	var hitList:Array<FlxBasic> = [];
	var twin:MeleeSwing;

	public function new()
	{
		super();
		makeGraphic(76, 76, FlxColor.TRANSPARENT);
		visible = false;
	}

	/** dist = how far from the owner the hurtbox centers; w/h = its size. */
	public function strike(owner:Player, aimX:Float, aimY:Float, dist:Float = 56, w:Float = 76, h:Float = 76):Void
	{
		setSize(w, h);
		var cx = owner.x + owner.width / 2 + aimX * dist;
		var cy = owner.y + owner.height / 2 + aimY * dist;
		reset(cx - w / 2, cy - h / 2);
		damage = Std.int(owner.damage);
		life = 0.18;
		hitList.resize(0);
		twin = null;
	}

	/** Twin Shot: the second swing shares the first's hit list, so it widens the arc instead of doubling damage. */
	public function link(other:MeleeSwing):Void
	{
		twin = other;
		other.twin = this;
	}

	public function hasHit(b:FlxBasic):Bool
		return hitList.indexOf(b) >= 0 || (twin != null && twin.hitList.indexOf(b) >= 0);

	public function markHit(b:FlxBasic):Void
		hitList.push(b);

	override public function update(elapsed:Float):Void
	{
		life -= elapsed;
		if (life <= 0)
			kill();
		super.update(elapsed);
	}
}
