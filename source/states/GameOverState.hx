package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.WideButton;

class GameOverState extends FlxState
{
	var won:Bool;

	public function new(won:Bool = false)
	{
		super();
		this.won = won;
	}

	/** Test hook: same as the Restart button. */
	public function restart():Void
		FlxG.switchState(() -> new PlayState());

	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;
		RunState.active = false; // next PlayState starts a fresh run
		RunState.clearSaved();
		fx.Sfx.stopAmbient();
		fx.Sfx.stopMusic();
		fx.Sfx.play(won ? "fanfare" : "stinger", 0.9);
		var fresh = won ? Unlocks.onRunWon(RunState.boughtSomething) : [];

		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());

		var title = new FlxText(0, 170, FlxG.width, won ? "RUN COMPLETE" : "YOU DIED");
		title.setFormat(null, 40, won ? FlxColor.fromRGB(150, 255, 150) : FlxColor.fromRGB(255, 90, 90), CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 40, 50), 4);
		add(title);

		var sub = won ? 'Runs won: ${Unlocks.wins()}' + (fresh.length > 0 ? '   ${fresh.join(", ")} unlocked!' : "")
			: 'Slain by ${RunState.lastHitBy == "" ? "the sea" : RunState.lastHitBy} on ${RunState.floorName()}';
		var w = new FlxText(0, 226, FlxG.width, sub);
		w.setFormat(null, 20, FlxColor.WHITE, CENTER);
		w.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 40, 50), 3);
		add(w);
		var mins = Std.int(RunState.timeSec / 60), secs = Std.int(RunState.timeSec % 60);
		var hero = Std.string(entities.Player.selectedKind);
		var stats = new FlxText(0, 262, FlxG.width,
			'$hero   ${RunState.floorNumber() + 1} floors   ${mins}:${secs < 10 ? "0" : ""}$secs   ${RunState.kills} kills   ${RunState.damageTaken / 2} hearts lost   ${RunState.itemsTaken} items');
		stats.setFormat(null, 15, FlxColor.fromRGB(220, 230, 235), CENTER);
		stats.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 40, 50), 2);
		add(stats);
		add(new WideButton(320, "Restart", () -> FlxG.switchState(() -> new PlayState())));
		add(new WideButton(410, "Menu", () -> FlxG.switchState(() -> new MenuState())));
		// a restart from here is a fresh run in the same slot; the checkpoint is already cleared
		nav = ui.MenuNav.collect(this, null);
	}

	var nav:ui.MenuNav;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (nav != null)
			nav.update(elapsed);
	}
}
