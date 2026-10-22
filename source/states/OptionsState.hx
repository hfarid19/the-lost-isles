package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.OptionRow;
import ui.WideButton;

/** Options off the title screen: audio sliders, display and control toggles. */
class OptionsState extends FlxState
{
	var toggles:Array<{btn:WideButton, key:String, title:String}> = [];

	override public function create():Void
	{
		super.create();
		Settings.load();
		FlxG.mouse.visible = true;
		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());

		var title = new FlxText(0, 28, FlxG.width, "OPTIONS");
		title.setFormat(null, 36, FlxColor.WHITE, CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 4);
		add(title);

		add(new OptionRow(110, "Master", "volume"));
		add(new OptionRow(170, "Music", "music"));
		add(new OptionRow(230, "Sounds", "sfx"));
		add(new OptionRow(290, "Ambience", "ambience"));

		#if !html5
		addToggle(190, 360, "Fullscreen", "fullscreen");
		#else
		addToggle(190, 360, "Fullscreen", null); // the browser owns the window
		#end
		addToggle(514, 360, "Screen shake", "shake");
		addToggle(190, 448, "Reduce flashing", "reduceFlash");
		addToggle(514, 448, "Gamepad", "gamepad");

		add(new WideButton(544, "Controls", () -> FlxG.switchState(() -> new ControlsState()), 180));
		add(new WideButton(544, "Back", () -> FlxG.switchState(() -> new MenuState()), 524));
		nav = ui.MenuNav.collect(this, () -> FlxG.switchState(() -> new MenuState()));
	}

	var nav:ui.MenuNav;

	function addToggle(x:Float, y:Float, title:String, key:String):Void
	{
		var entry = {btn: null, key: key, title: title};
		var b = new WideButton(y, "", () ->
		{
			if (key == null)
				return;
			Settings.toggle(key);
			relabel(entry);
		}, x);
		entry.btn = b;
		b.label.size = 16; // "Reduce flashing: Off" has to fit the 256px face
		if (key == null)
			b.alpha = 0.5;
		toggles.push(entry);
		relabel(entry);
		add(b);
	}

	function relabel(e:{btn:WideButton, key:String, title:String}):Void
		e.btn.text = e.title + ": " + (e.key == null ? "n/a" : (Settings.getFlag(e.key) ? "On" : "Off"));

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		nav.update(elapsed);
	}
}
