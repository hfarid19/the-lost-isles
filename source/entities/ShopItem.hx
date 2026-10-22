package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import entities.Pickup.PickupType;
import items.ItemDef;

/** Goods on the shop floor: a pickup or a run item with a price tag drawn
 * underneath. PlayState overlaps the player with it and calls tryBuy(). */
class ShopItem extends FlxSprite
{
	public var price(default, null):Int;
	public var pickupType(default, null):Null<PickupType>;
	public var pickupCount(default, null):Int = 1;
	public var itemDef(default, null):ItemDef;

	var tag:FlxText;
	var coin:FlxSprite;
	var bob:Float = 0;

	/** x/y = tile world position. Exactly one of pickup / def is set. */
	public function new(x:Float, y:Float, price:Int, ?pickup:PickupType, count:Int = 1, ?def:ItemDef)
	{
		super();
		this.price = price;
		pickupType = pickup;
		pickupCount = count;
		itemDef = def;
		if (def != null)
		{
			loadGraphic(def.icon);
			scale.set(0.75, 0.75);
		}
		else
			switch (pickup)
			{
				case Meat:
					loadGraphic("assets/images/pickups/meat.png");
					scale.set(0.6, 0.6);
				case Bomb:
					loadGraphic("assets/images/fx/dynamite.png", true, 64, 64);
					animation.frameIndex = 0;
					scale.set(0.9, 0.9);
				case Key:
					loadGraphic("assets/images/ui/icon_key.png");
					scale.set(0.8, 0.8);
				case Gold:
					loadGraphic("assets/images/pickups/gold.png");
					scale.set(0.5, 0.5);
			}
		updateHitbox();
		setPosition(x + 32 - width / 2, y + 28 - height / 2);

		coin = new FlxSprite(0, 0, "assets/images/pickups/gold.png");
		coin.scale.set(0.22, 0.22);
		coin.updateHitbox();
		tag = new FlxText(0, 0, 60, Std.string(price), 13);
		tag.setBorderStyle(SHADOW, FlxColor.fromRGB(20, 40, 50), 2);
	}

	/** Returns the label used on the item card. */
	public function label():String
		return itemDef != null ? itemDef.name : switch (pickupType)
		{
			case Meat: "Meat";
			case Bomb: 'Bombs x$pickupCount';
			case Key: "Key";
			case Gold: "Gold";
		};

	/** Deducts gold and applies the goods; false when the player can't afford it. */
	public function tryBuy(p:Player):Bool
	{
		if (p.gold < price)
		{
			fx.Sfx.play("deny", 0.5, 0, 0.6);
			return false;
		}
		p.gold -= price;
		RunState.boughtSomething = true;
		fx.Sfx.play("buy", 0.8);
		if (itemDef != null)
			items.ItemPool.give(p, itemDef);
		else
			switch (pickupType)
			{
				case Meat: p.hp = Std.int(Math.min(p.maxHp, p.hp + 2));
				case Bomb: p.bombs += pickupCount;
				case Key: p.keys += pickupCount;
				case Gold:
			}
		kill();
		return true;
	}

	/** PlayState passes the player so unaffordable tags read red. */
	public var shopper:Player;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		bob += elapsed * 2.5;
		var cx = x + width / 2;
		var base = y + height + 6;
		coin.setPosition(cx - 22, base + 2);
		tag.setPosition(cx - 4, base);
		tag.color = (shopper != null && shopper.gold < price) ? FlxColor.fromRGB(230, 90, 80) : FlxColor.WHITE;
		coin.update(elapsed);
	}

	override public function draw():Void
	{
		super.draw();
		coin.cameras = cameras;
		coin.draw();
		tag.cameras = cameras;
		tag.draw();
	}
}
