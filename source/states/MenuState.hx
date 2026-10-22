package states;

import Constants.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import ui.WideButton;
import world.Room;

class MenuState extends FlxState
{
	// decorative island under the Play button, 11x5 tiles
	static final ISLAND = [
		"....###....",
		".#########.",
		"###########",
		".#########.",
		"...#####...",
	];
	static inline var ISLE_X:Int = 128;
	static inline var ISLE_Y:Int = 300;

	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.mouse.load("assets/images/ui/cursor.png");
		FlxG.camera.bgColor = FlxColor.fromRGB(71, 171, 169);

		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());

		var iw = ISLAND[0].length, ih = ISLAND.length;
		var ground = [for (row in ISLAND) for (c in 0...iw) row.charAt(c) == "#" ? 1 : 0];

		// bobbing rocks with ripple animations read as open-water waves
		for (i in 0...7)
		{
			var rock = new FlxSprite(FlxG.random.float(40, FlxG.width - 100), FlxG.random.float(40, FlxG.height - 100));
			rock.loadGraphic('assets/images/props/waterrock_${FlxG.random.int(1, 4)}.png', true, 64, 64);
			rock.animation.add("bob", [for (f in 0...16) f], 8);
			rock.animation.play("bob");
			rock.animation.curAnim.curFrame = FlxG.random.int(0, 15);
			add(rock);
		}

		// island shoreline foam
		for (cy in 0...ih)
			for (cx in 0...iw)
			{
				if (ground[cy * iw + cx] != 1)
					continue;
				var shore = false;
				for (dy in -1...2)
					for (dx in -1...2)
					{
						var nx = cx + dx, ny = cy + dy;
						if (nx < 0 || ny < 0 || nx >= iw || ny >= ih || ground[ny * iw + nx] == 0)
							shore = true;
					}
				if (!shore)
					continue;
				var f = new FlxSprite(ISLE_X + cx * TILE - TILE, ISLE_Y + cy * TILE - TILE);
				f.loadGraphic("assets/images/vfx/water_foam.png", true, 192, 192);
				f.animation.add("foam", [for (i in 0...16) i], 10);
				f.animation.play("foam");
				add(f);
			}

		var isle = new FlxTilemap();
		isle.loadMapFromArray(Room.autotileGrid(ground, iw, ih), iw, ih,
			"assets/images/tiles/tilemap_flat.png", TILE, TILE, OFF, 1, 1, 0x40000000);
		isle.setPosition(ISLE_X, ISLE_Y);
		isle.solid = false;
		add(isle);

		// clouds cast shadows on the island, puffs drift over the water
		var clouds = new fx.Clouds(FlxRect.get(-250, -250, FlxG.width + 500, FlxG.height + 500), 6);
		add(clouds.shadows);

		// island dressing (purely decorative)
		addProp("assets/images/props/tree.png", ISLE_X + 8 * TILE - 64, ISLE_Y + 2 * TILE - 148, true);
		addProp("assets/images/props/bush_2.png", ISLE_X + 1 * TILE - 32, ISLE_Y + 2 * TILE - 48, false, 8, 128);
		addProp("assets/images/props/deco_08.png", ISLE_X + 2 * TILE, ISLE_Y + 3 * TILE - 8);
		addProp("assets/images/props/deco_14.png", ISLE_X + 8 * TILE, ISLE_Y + 3 * TILE + 6);

		add(clouds.puffs);

		var title = new FlxText(0, 110, FlxG.width, "THE LOST ISLES");
		title.setFormat(null, 48, FlxColor.WHITE, CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 4);
		add(title);

		var subtitle = new FlxText(0, 180, FlxG.width, "a tiny roguelite");
		subtitle.setFormat(null, 16, FlxColor.fromRGB(220, 235, 235), CENTER);
		add(subtitle);

		fx.Sfx.ambient("beach", 0.3);
		fx.Sfx.music("silent_harbor", 0.5);
		add(new WideButton(360, "Play", () -> FlxG.switchState(() -> new SlotSelectState())));
		add(new WideButton(444, "Options", () -> FlxG.switchState(() -> new OptionsState())));
		add(new WideButton(528, "Credits", () -> FlxG.switchState(() -> new CreditsState())));
		nav = ui.MenuNav.collect(this);
	}

	var nav:ui.MenuNav;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		nav.update(elapsed);
	}

	function addProp(path:String, x:Float, y:Float, ?animTree:Bool = false, ?frames:Int = 0, ?fw:Int = 0):Void
	{
		var s = new FlxSprite(x, y);
		if (animTree)
		{
			s.loadGraphic(path, true, 192, 192);
			s.animation.add("sway", [0, 1, 2, 3], 5);
			s.animation.play("sway");
		}
		else if (frames > 0)
		{
			s.loadGraphic(path, true, fw, fw);
			s.animation.add("sway", [for (i in 0...frames) i], 6);
			s.animation.play("sway");
		}
		else
			s.loadGraphic(path);
		add(s);
	}
}
