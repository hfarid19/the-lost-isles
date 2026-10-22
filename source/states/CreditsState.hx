package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.WideButton;

/** Who made what, and how to play. */
class CreditsState extends FlxState
{
	var nav:ui.MenuNav;

	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;
		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());
		var title = new FlxText(0, 24, FlxG.width, "CREDITS");
		title.setFormat(null, 36, FlxColor.WHITE, CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 4);
		add(title);
		var body = new FlxText(80, 90, FlxG.width - 160, "Art: Tiny Swords by Pixel Frog (Free Pack, Update 010, Enemy Pack)\n"
			+ "Item icons: Admurin's Premium item packs\n"
			+ "Sound: Free Fantasy SFX Pack by TomMusic, FilmCow Recorded and Designed SFX\n"
			+ "Music: Pirate Music Pack Vol. 2 by alkakrab\n"
			+ "Room layouts: adapted from The Binding of Isaac: Rebirth (Nicalis / Edmund McMillen), for reference only\n"
			+ "Made with HaxeFlixel\n\n"
			+ "HOW TO PLAY\n"
			+ "Move: WASD    Aim and attack: arrow keys or mouse    Bomb: E    Use item: Space\n"
			+ "Block (Knight) / roll (Panda): Shift    Map: hold Tab    Pause: Escape\n"
			+ "Keys open shops. Lean on a hidden wall for 3 s to open a secret room.\n"
			+ "Every boss drops an item. Beat the Keep to unlock new islands.", 14);
		body.setFormat(null, 14, FlxColor.WHITE, CENTER);
		body.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 2);
		add(body);
		add(new WideButton(520, "Back", () -> FlxG.switchState(() -> new MenuState())));
		nav = ui.MenuNav.collect(this, () -> FlxG.switchState(() -> new MenuState()));
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		nav.update(elapsed);
	}
}
