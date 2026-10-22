package ui;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/** "Label  [-] ■■■■■■■■□□ [+]  80%" slider row bound to a Settings key. */
class OptionRow extends FlxSpriteGroup
{
	var bar:PackBar;
	var pct:FlxText;
	var key:String;
	var signs:Array<FlxText> = [];

	public function new(y:Float, title:String, key:String)
	{
		super(0, y);
		this.key = key;
		var label = new FlxText(0, 4, 120, title, 16);
		label.setFormat(null, 16, FlxColor.WHITE, RIGHT);
		label.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 2);
		add(label);
		add(makeButton(136, "-", () -> change(-1)));
		bar = new PackBar(196, -17, 4, false);
		add(bar);
		add(makeButton(460, "+", () -> change(1)));
		for (t in signs)
			add(t);
		pct = new FlxText(524, 4, 60, "", 16);
		pct.setFormat(null, 16, FlxColor.WHITE, LEFT);
		pct.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 2);
		add(pct);
		refresh();
		x = (FlxG.width - 584) / 2;
	}

	function makeButton(bx:Float, text:String, onClick:Void->Void):FlxButton
	{
		// three stacked states (normal, hover, pressed) so FlxButton swaps the art itself;
		// the click stays on onUp, which is where FlxButton puts onClick
		var b = new FlxButton(bx, -14, "", onClick);
		b.loadGraphic("assets/images/ui/button_blue_states.png", true, 64, 64);
		var t = new FlxText(bx, -6, 64, text, 26);
		t.setFormat(null, 26, FlxColor.WHITE, CENTER);
		t.setBorderStyle(SHADOW, FlxColor.fromRGB(25, 60, 70), 2);
		signs.push(t);
		return b;
	}

	function change(dir:Int):Void
	{
		Settings.set(key, Settings.get(key) + dir * 0.1);
		refresh();
		fx.Sfx.play("ui", 0.6);
	}

	function refresh():Void
	{
		bar.setFraction(Settings.get(key));
		pct.text = Math.round(Settings.get(key) * 100) + "%";
	}
}
