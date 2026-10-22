package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.WideButton;

/** Pick one of three profiles. A slot with a saved run offers Continue or New Run. */
class SlotSelectState extends FlxState
{
	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.mouse.load("assets/images/ui/cursor.png");
		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());

		var title = new FlxText(0, 60, FlxG.width, "CHOOSE A SAVE");
		title.setFormat(null, 36, FlxColor.WHITE, CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 4);
		add(title);

		for (i in 0...3)
			card(i + 1, 60 + i * 300);

		add(new WideButton(16, "Back", () -> FlxG.switchState(() -> new MenuState()), 16));
		nav = ui.MenuNav.collect(this, () -> FlxG.switchState(() -> new MenuState()));
	}

	/** Test hook: same as pressing Continue on a slot. */
	public function continueSlot(slot:Int):Void
	{
		SaveSlots.select(slot);
		RunState.resume();
		FlxG.switchState(() -> new PlayState());
	}

	function card(slot:Int, x:Float):Void
	{
		var s = SaveSlots.summary(slot);
		// the small paper sheet stretched taller so the text sits inside its border
		var sheet = new FlxSprite(x, 130, "assets/images/ui/paper_small.png");
		sheet.scale.y = 1.6;
		sheet.updateHitbox();
		sheet.setPosition(x, 130);
		add(sheet);
		var ink = FlxColor.fromRGB(74, 56, 38);
		var head = new FlxText(x, 166, 250, 'SAVE $slot');
		head.setFormat(null, 22, ink, CENTER);
		add(head);
		var body = new FlxText(x + 10, 210, 230, s.empty ? "empty" : (s.hasRun ? '${s.hero}\n${s.floor}' : "no run in progress") + '\nruns won: ${s.wins}');
		body.setFormat(null, 14, ink, CENTER);
		add(body);

		if (s.hasRun)
		{
			add(new WideButton(390, "Continue", () ->
			{
				SaveSlots.select(slot);
				RunState.resume();
				FlxG.switchState(() -> new PlayState());
			}, x - 3));
			add(new WideButton(460, "New Run", () ->
			{
				SaveSlots.select(slot);
				RunState.clearSaved();
				FlxG.switchState(() -> new CharSelectState());
			}, x - 3));
		}
		else
			add(new WideButton(390, s.empty ? "Start" : "New Run", () ->
			{
				SaveSlots.select(slot);
				FlxG.switchState(() -> new CharSelectState());
			}, x - 3));

		if (!s.empty)
		{
			var erase = new WideButton(s.hasRun ? 530 : 460, "Erase", () ->
			{
				SaveSlots.erase(slot);
				FlxG.switchState(() -> new SlotSelectState());
			}, x - 3);
			erase.color = FlxColor.fromRGB(230, 120, 110);
			add(erase);
		}
	}

	var nav:ui.MenuNav;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (nav != null)
			nav.update(elapsed);
	}
}
