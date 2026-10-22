package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import entities.Player;

/** Between floors: the boat rows across open water while the next floor's
 * name card shows, then the run continues in a fresh PlayState. */
class SailState extends FlxState
{
	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = false;
		fx.Sfx.play("stinger", 0.7);
		if (RunState.caveWalk)
		{
			fx.Sfx.stopAmbient();
			fx.Sfx.play("rumble", 0.8);
			// into or out of the dark: a black screen, a rumble, the floor name
			FlxG.camera.bgColor = FlxColor.fromRGB(8, 6, 12);
			var name = new FlxText(0, 260, FlxG.width, RunState.floorName());
			name.setFormat(null, 44, FlxColor.fromRGB(220, 200, 170), CENTER);
			name.setBorderStyle(SHADOW, FlxColor.fromRGB(40, 20, 20), 4);
			name.alpha = 0;
			add(name);
			FlxTween.tween(name, {alpha: 1}, 0.8, {startDelay: 0.3});
			fx.Juice.shake(0.004, 1.2);
			new flixel.util.FlxTimer().start(2.6, _ -> FlxG.camera.fade(FlxColor.BLACK, 0.5, false, () -> FlxG.switchState(() -> new PlayState())));
			return;
		}
		fx.Sfx.ambient("sea");
		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());

		// the next floor's shore: a small island on the right the boat lands at
		var iw = 6, ih = 5;
		var ground = [for (i in 0...iw * ih) 1];
		var isle = new flixel.tile.FlxTilemap();
		isle.loadMapFromArray(world.Room.autotileGrid(ground, iw, ih), iw, ih,
			world.LevelDefs.tileset(), 64, 64, OFF, 1, 1, 0x40000000);
		var isleX = FlxG.width - iw * 64 + 40, isleY = 180;
		isle.setPosition(isleX, isleY);
		add(isle);

		var boat = new FlxSprite(-260, 240);
		boat.loadGraphic("assets/images/props/boat.png", true, 256, 256);
		boat.animation.add("idle", [for (i in 0...8) i], 8);
		boat.animation.play("idle");
		add(boat);
		var hero = new FlxSprite(0, 0);
		hero.loadGraphic(switch (entities.Player.selectedKind)
		{
			case Knight: "assets/images/chars/warrior_full.png";
			case Lancer: "assets/images/chars/lancer_blue.png";
			case Monk: "assets/images/chars/monk_blue.png";
			default: "assets/images/chars/archer_blue.png";
		}, true, entities.Player.selectedKind == Lancer ? 320 : 192, entities.Player.selectedKind == Lancer ? 320 : 192);
		hero.animation.add("idle", [for (i in 0...6) i], 10);
		hero.animation.play("idle");
		hero.scale.set(0.8, 0.8);
		add(hero);
		// sail up to the shore, bump, then the hero hops off onto the island
		var shoreX = isleX - 210;
		FlxTween.tween(boat, {x: shoreX}, 4.2, {ease: FlxEase.sineInOut, onComplete: _ ->
		{
			fx.Sfx.play("boat", 0.7);
			fx.Sfx.play("rope", 0.5);
			landed = true;
			var runFrom = switch (Player.selectedKind) { case Lancer: 12; case Knight: 6; case Monk: 11; default: 8; };
			var runTo = switch (Player.selectedKind) { case Lancer: 18; case Knight: 12; case Monk: 15; default: 14; };
			hero.animation.add("run", [for (i in runFrom...runTo) i], 10);
			hero.animation.play("run");
			hero.flipX = false;
			FlxTween.tween(hero, {x: isleX + 70, y: isleY + 96}, 0.9, {ease: FlxEase.quadOut, onComplete: _ ->
			{
				hero.animation.play("idle");
				fx.Sfx.play("land", 0.5);
			}});
		}});

		var name = new FlxText(0, 120, FlxG.width, RunState.floorName());
		name.setFormat(null, 44, FlxColor.WHITE, CENTER);
		name.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 40, 50), 4);
		name.alpha = 0;
		add(name);
		FlxTween.tween(name, {alpha: 1}, 0.6, {startDelay: 0.4});

		this.hero = hero;
		this.boat = boat;
		FlxG.camera.fade(FlxColor.BLACK, 0.4, true);
		new flixel.util.FlxTimer().start(5.8, _ -> FlxG.camera.fade(FlxColor.BLACK, 0.5, false, () -> FlxG.switchState(() -> new PlayState())));
	}

	var hero:FlxSprite;
	var boat:FlxSprite;
	var landed:Bool = false;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (boat == null || landed)
			return;
		// hero rides in the boat
		// seat the hero inside the hull (hull interior spans y100-150 of the 256 frame;
		// the hero's body sits around y95 of its own frame at 0.8x)
		hero.x = boat.x + 128 - hero.width / 2;
		hero.y = boat.y + 122 - hero.height / 2 + Math.sin(FlxG.game.ticks / 250) * 3;
	}
}
