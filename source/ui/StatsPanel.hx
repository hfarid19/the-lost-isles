package ui;

import entities.Player;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/** Isaac-style stat readout down the left edge: pack icon + number.
 * Lives on the main camera, pinned to the screen. */
class StatsPanel extends FlxSpriteGroup
{
	var player:Player;
	var values:Array<FlxText> = [];

	public function new(player:Player)
	{
		super();
		this.player = player;
		camera = FlxG.camera;
		scrollFactor.set(0, 0);

		var y = 84.0;
		inline function row(icon:FlxSprite):FlxText
		{
			// normalize icon to ~26px tall, left-aligned at x=10
			var s = 26 / icon.frameHeight;
			icon.scale.set(s, s);
			icon.updateHitbox();
			icon.setPosition(10 + (26 - icon.width) / 2, y);
			add(icon);
			var t = new FlxText(44, y + 4, 90, "", 13);
			t.setBorderStyle(SHADOW, FlxColor.fromRGB(20, 40, 50), 2);
			add(t);
			values.push(t);
			y += 34;
			return t;
		}

		var sword = new FlxSprite();
		sword.loadGraphic("assets/images/ui/icon_sword.png"); // damage
		row(sword);

		var flame = new FlxSprite();
		flame.loadGraphic("assets/images/fx/fire.png", true, 64, 64); // fire rate
		flame.animation.frameIndex = 0;
		row(flame);

		var arrow = new FlxSprite();
		arrow.loadGraphic("assets/images/fx/arrow.png", true, 64, 64); // range
		arrow.animation.frameIndex = 0;
		row(arrow);

		var cloud = new FlxSprite();
		cloud.loadGraphic("assets/images/vfx/cloud_01.png"); // speed (wind)
		row(cloud);

		var shroom = new FlxSprite();
		shroom.loadGraphic("assets/images/props/deco_02.png"); // luck
		row(shroom);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		values[0].text = fmt(player.damage);
		values[1].text = fmt(1 / player.fireCooldown);
		values[2].text = Std.string(Std.int(player.arrowRange));
		values[3].text = Std.string(Std.int(player.speed));
		values[4].text = fmt(player.luck);
	}

	static inline function fmt(v:Float):String
		return Std.string(Math.round(v * 10) / 10);
}
