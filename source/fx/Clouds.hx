package fx;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxRect;

/** Drifting clouds: dark shadow blobs on the ground + soft white puffs on top.
 * Add `shadows` low in the draw order (over ground) and `puffs` last (over world). */
class Clouds
{
	public var shadows(default, null):FlxTypedGroup<CloudPuff> = new FlxTypedGroup();
	public var puffs(default, null):FlxTypedGroup<CloudPuff> = new FlxTypedGroup();

	public function new(bounds:FlxRect, count:Int = 8)
	{
		for (i in 0...count)
		{
			var variant = FlxG.random.int(1, 6);
			var puff = new CloudPuff('assets/images/vfx/cloud_0$variant.png', bounds, false);
			var shadow = new CloudPuff('assets/images/vfx/cloud_0$variant.png', bounds, true);
			shadow.leader = puff;
			puffs.add(puff);
			shadows.add(shadow);
		}
	}
}

class CloudPuff extends FlxSprite
{
	public var leader:CloudPuff; // shadows follow their cloud

	var bounds:FlxRect;

	public function new(graphicPath:String, bounds:FlxRect, isShadow:Bool)
	{
		super();
		this.bounds = bounds;
		loadGraphic(graphicPath);
		var s = FlxG.random.float(0.5, 0.9);
		scale.set(s, s);
		flipX = FlxG.random.bool();
		solid = false;
		if (isShadow)
		{
			color = 0xFF000000;
			alpha = 0.13;
		}
		else
		{
			alpha = 0.85;
			setPosition(FlxG.random.float(bounds.x, bounds.right), FlxG.random.float(bounds.y, bounds.bottom));
			velocity.set(FlxG.random.float(9, 22), FlxG.random.float(2, 7));
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (leader != null)
		{
			// shadow trails its cloud toward the ground
			setPosition(leader.x + 26, leader.y + 78);
			scale.copyFrom(leader.scale);
			flipX = leader.flipX;
		}
		else
		{
			// wrap around the floor's bounding box
			if (x > bounds.right + 100) x = bounds.x - width - 60;
			if (y > bounds.bottom + 100) y = bounds.y - height - 60;
		}
	}
}
