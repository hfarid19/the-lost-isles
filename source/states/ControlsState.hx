package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.WideButton;

/** Key rebinding: pick an action, press the new key. Stored in Settings. */
class ControlsState extends FlxState
{
	static var actions = [
		{key: "up", title: "Move up"}, {key: "down", title: "Move down"}, {key: "left", title: "Move left"}, {key: "right", title: "Move right"},
		{key: "aimUp", title: "Aim up"}, {key: "aimDown", title: "Aim down"}, {key: "aimLeft", title: "Aim left"}, {key: "aimRight", title: "Aim right"},
		{key: "bomb", title: "Bomb"}, {key: "active", title: "Use item"}, {key: "block", title: "Block / roll"}, {key: "map", title: "Map"},
	];
	var rows:Array<{btn:WideButton, key:String, title:String}> = [];
	var listening:String = null;
	var hint:FlxText;
	var nav:ui.MenuNav;

	override public function create():Void
	{
		super.create();
		Settings.load();
		FlxG.mouse.visible = true;
		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());
		var title = new FlxText(0, 24, FlxG.width, "CONTROLS");
		title.setFormat(null, 36, FlxColor.WHITE, CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 4);
		add(title);
		for (i in 0...actions.length)
		{
			var a = actions[i];
			var col = i % 2, row = Std.int(i / 2);
			var entry = {btn: null, key: a.key, title: a.title};
			var b = new WideButton(90 + row * 62, "", () ->
			{
				listening = entry.key;
				relabel();
			}, 190 + col * 324);
			b.scale.set(1.15, 0.72);
			b.updateHitbox();
			b.label.fieldWidth = Std.int(b.width);
			b.label.size = 14;
			b.labelOffsets[0].set(0, 12);
			b.labelOffsets[1].set(0, 12);
			b.labelOffsets[2].set(0, 16);
			entry.btn = b;
			rows.push(entry);
			add(b);
		}
		hint = new FlxText(0, 472, FlxG.width, "Pad: left stick moves, right stick aims and fires, X bomb, Y item, LB/RB block, Back map, Start pause", 12);
		hint.setFormat(null, 12, FlxColor.WHITE, CENTER);
		hint.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 2);
		add(hint);
		add(new WideButton(500, "Reset to defaults", () ->
		{
			Settings.resetBinds();
			relabel();
		}, 180));
		add(new WideButton(500, "Back", () -> FlxG.switchState(() -> new OptionsState()), 524));
		relabel();
		nav = ui.MenuNav.collect(this, () -> FlxG.switchState(() -> new OptionsState()));
	}

	function relabel():Void
	{
		for (r in rows)
			r.btn.text = r.title + ": " + (listening == r.key ? "press a key..." : keyName(Settings.bind(r.key)));
	}

	static function keyName(code:Int):String
	{
		var n = FlxKey.toStringMap.get(code);
		return n == null ? Std.string(code) : n;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (listening != null)
		{
			var k = FlxG.keys.firstJustPressed();
			if (k == FlxKey.ESCAPE)
				listening = null;
			else if (k > 0)
			{
				Settings.setBind(listening, k);
				listening = null;
			}
			if (listening == null)
				relabel();
			return;
		}
		nav.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(() -> new OptionsState());
	}
}
