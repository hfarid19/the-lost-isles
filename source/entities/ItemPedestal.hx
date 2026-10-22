package entities;

import flixel.FlxSprite;
import items.ItemDef;

/** Treasure-room pedestal: the Cainos stone stand (2x) with the item icon floating over it.
 * One sprite (the rock is the hitbox); the icon is drawn by hand so overlap
 * callbacks always receive the pedestal itself. */
class ItemPedestal extends FlxSprite
{
	public var def(default, null):ItemDef;

	/** Set by PlayState so drops can spawn pedestals mid-run. */
	public static var group:flixel.group.FlxGroup.FlxTypedGroup<ItemPedestal>;

	var icon:FlxSprite;
	var shadow:FlxSprite;
	var bob:Float = 0;

	/** x/y = tile world position of the cell the pedestal stands on. */
	public function new(x:Float, y:Float, def:ItemDef)
	{
		super(x, y, "assets/images/props/pedestal.png");
		this.def = def;
		icon = new FlxSprite(0, 0, def.icon);
		icon.scale.set(0.75, 0.75);
		icon.updateHitbox();
		// soft ellipse on the stand's top, shrinks as the item floats higher
		shadow = new FlxSprite();
		shadow.makeGraphic(36, 12, flixel.util.FlxColor.TRANSPARENT, false, "pedestalShadow");
		flixel.util.FlxSpriteUtil.drawEllipse(shadow, 0, 0, 36, 12, flixel.util.FlxColor.fromRGB(22, 28, 46));
		shadow.alpha = 0.35;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		bob += elapsed * 3;
		var lift = Math.sin(bob) * 5; // -5 (low) .. +5 (high)
		icon.x = x + (width - icon.width) / 2;
		icon.y = y - 40 - lift;
		icon.update(elapsed);
		var k = 1 - (lift + 5) / 10 * 0.3; // 1.0 low .. 0.7 high
		shadow.scale.set(k, k);
		shadow.alpha = 0.2 + 0.15 * k;
		shadow.x = x + (width - 36) / 2;
		shadow.y = y + 6;
	}

	override public function draw():Void
	{
		super.draw();
		shadow.cameras = cameras;
		shadow.draw();
		icon.cameras = cameras;
		icon.draw();
	}
}
