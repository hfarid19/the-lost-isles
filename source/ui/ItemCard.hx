package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import items.ItemDef;

/** Isaac-style pickup card: item name and caption on the paper sheet,
 * drops in from the top of the screen and leaves after 2 s. */
class ItemCard extends FlxSpriteGroup
{
	static inline var SHOWN_Y:Float = 76;

	var name:FlxText;
	var caption:FlxText;
	var icon:FlxSprite;
	var timer:Float = 0;

	public function new()
	{
		super();
		scrollFactor.set(0, 0);
		var sheet = new FlxSprite(0, 0, "assets/images/ui/paper_small.png");
		add(sheet);
		var ink = FlxColor.fromRGB(74, 56, 38);
		icon = new FlxSprite(18, 40);
		add(icon);
		name = new FlxText(70, 30, 158, "", 14);
		name.setFormat(null, 14, ink, LEFT);
		name.wordWrap = true;
		add(name);
		caption = new FlxText(70, 62, 158, "", 11);
		caption.setFormat(null, 12, ink, LEFT);
		caption.wordWrap = true;
		add(caption);
		x = (FlxG.width - sheet.width) / 2;
		y = -sheet.height;
		visible = false;
	}

	public function show(def:ItemDef):Void
	{
		icon.loadGraphic(def.icon);
		var k = 44 / icon.frameHeight; // any icon size lands at 44 px
		icon.scale.set(k, k);
		icon.updateHitbox();
		icon.x = x + 18;
		icon.y = y + 44;
		name.text = def.name.toUpperCase();
		caption.text = def.caption;
		caption.y = name.y + name.height + 2; // caption sits under the name, however many lines
		visible = true;
		timer = 2.2;
		FlxTween.cancelTweensOf(this);
		FlxTween.tween(this, {y: SHOWN_Y}, 0.35, {ease: FlxEase.backOut});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (timer > 0)
		{
			timer -= elapsed;
			if (timer <= 0)
				FlxTween.tween(this, {y: -150}, 0.3, {ease: FlxEase.quadIn, onComplete: _ -> visible = false});
		}
	}
}
