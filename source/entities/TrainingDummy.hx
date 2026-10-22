package entities;

import flixel.text.FlxText;
import flixel.util.FlxColor;

/** Scarecrow in the start room: soaks hits with feedback, never dies,
 * never fights back. Lives in its own group so it can't lock doors. */
class TrainingDummy extends Enemy
{
	var hits:Int = 0;
	var hitLabel:FlxText;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/deco_18.png"); // scarecrow, 192x192 (art x54-140, y48-168)
		setSize(56, 28);
		offset.set(69, 140);
		immovable = true;
		moves = false; // ignore knockback velocity from takeHit
		hp = 999999;

		hitLabel = new FlxText(0, 0, 80, "", 12);
		hitLabel.alignment = CENTER;
		hitLabel.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 40, 50), 2);
	}

	/** PlayState adds this above the dummy. */
	public function label():FlxText
		return hitLabel;

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		super.takeHit(damage, source);
		hp = 999999;
		hits += damage;
		hitLabel.text = Std.string(hits);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		hitLabel.setPosition(x + width / 2 - 40, y - offset.y + 30);
	}
}
