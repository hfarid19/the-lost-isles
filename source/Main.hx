import flixel.FlxGame;
import openfl.display.Sprite;
import states.MenuState;
import states.PlayState;

class Main extends Sprite
{
	public function new()
	{
		super();
		flixel.FlxG.signals.preGameStart.add(() ->
		{
			flixel.FlxG.autoPause = false;
			// flixel's default mute/volume hotkeys (0, minus, plus) collide with the dev
			// console's typing and its saved mute flag persisted across launches: disable
			// them and force sound on
			flixel.FlxG.sound.muteKeys = [];
			flixel.FlxG.sound.volumeUpKeys = [];
			flixel.FlxG.sound.volumeDownKeys = [];
			flixel.FlxG.sound.muted = false;
			Settings.load(); // master volume from the options save
		});
		#if html5
		// Dev shortcut: ?play boots straight into a run
		var direct = js.Browser.location.search.indexOf("play") >= 0
			|| js.Browser.location.search.indexOf("bossroom") >= 0
			|| js.Browser.location.search.indexOf("treasure") >= 0
			|| js.Browser.location.search.indexOf("shop") >= 0
			|| js.Browser.location.search.indexOf("combat") >= 0
			|| js.Browser.location.search.indexOf("level=") >= 0
			|| js.Browser.location.search.indexOf("nextboss") >= 0
			|| js.Browser.location.search.indexOf("floor=") >= 0
			|| js.Browser.location.search.indexOf("packs") >= 0;
		var select = js.Browser.location.search.indexOf("select") >= 0; // debug: boot into hero select
		var slots = js.Browser.location.search.indexOf("slots") >= 0; // debug: boot into the save-slot screen
		var options = js.Browser.location.search.indexOf("options") >= 0; // debug: boot into the options screen
		// debug: ?hero=knight|lancer picks the hero for a direct boot
		var hm = ~/[?&]hero=(\w+)/;
		if (hm.match(js.Browser.location.search))
			entities.Player.selectedKind = switch (hm.matched(1)) { case "knight": Knight; case "lancer": Lancer; case "monk": Monk; case "panda": Panda; default: Archer; };
		addChild(new FlxGame(960, 640, options ? states.OptionsState : (slots ? states.SlotSelectState : (select ? states.CharSelectState : (direct ? PlayState : MenuState))), 60, 60, direct || select || slots || options));
		if (direct || select || slots || options)
			untyped js.Browser.window.__flx = flixel.FlxG; // headless-verification hook (tools/drive.py --evalat)
		#else
		// native debug: SFXPROBE env var boots straight into a run and prints a sound status line
		addChild(new FlxGame(960, 640, (Sys.getEnv("SFXPROBE") != null || Sys.getEnv("PACKS") != null) ? PlayState : MenuState, 60, 60, Sys.getEnv("SFXPROBE") != null || Sys.getEnv("PACKS") != null));
		#end
	}
}
