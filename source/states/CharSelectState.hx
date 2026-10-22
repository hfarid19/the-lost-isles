package states;

import entities.Player;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.WideButton;

class CharSelectState extends FlxState
{
	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.mouse.load("assets/images/ui/cursor.png");
		FlxG.camera.bgColor = FlxColor.fromRGB(71, 171, 169);
		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());

		// same living ocean as the title screen: bobbing wave-rocks + clouds
		for (i in 0...7)
		{
			var rock = new FlxSprite(FlxG.random.float(40, FlxG.width - 100), FlxG.random.float(40, FlxG.height - 100));
			rock.loadGraphic('assets/images/props/waterrock_${FlxG.random.int(1, 4)}.png', true, 64, 64);
			rock.animation.add("bob", [for (f in 0...16) f], 8);
			rock.animation.play("bob");
			rock.animation.curAnim.curFrame = FlxG.random.int(0, 15);
			add(rock);
		}
		var clouds = new fx.Clouds(flixel.math.FlxRect.get(-250, -250, FlxG.width + 500, FlxG.height + 500), 6);
		add(clouds.shadows);
		add(clouds.puffs);

		var title = new FlxText(0, 70, FlxG.width, "CHOOSE YOUR HERO");
		title.setFormat(null, 36, FlxColor.WHITE, CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 4);
		add(title);

		card(4, "assets/images/ui/avatar_archer.png",
			"assets/images/chars/archer_blue.png", 192, 6,
			"Archer", () -> pick(Archer), true, "");
		card(194, "assets/images/ui/avatar_knight.png",
			"assets/images/chars/warrior_full.png", 192, 6,
			"Knight", () -> pick(Knight), Unlocks.isUnlocked(Knight), "Beat the Plains boss");
		card(384, "assets/images/ui/avatar_lancer.png",
			"assets/images/chars/lancer_blue.png", 320, 12,
			"Lancer", () -> pick(Lancer), Unlocks.isUnlocked(Lancer), "Beat the Forest boss");
		card(574, "assets/images/ui/avatar_monk.png",
			"assets/images/chars/monk_blue.png", 192, 6,
			"Monk", () -> pick(Monk), Unlocks.isUnlocked(Monk), "Win a run without shopping");
		card(764, "assets/images/ui/avatar_panda.png",
			"assets/images/chars/panda_hero.png", 256, 10,
			"Panda", () -> pick(Panda), Unlocks.isUnlocked(Panda), "Beat the Panda on the Bamboo Isle");
		nav = ui.MenuNav.collect(this, () -> FlxG.switchState(() -> new SlotSelectState()));
	}

	function card(x:Float, avatarPath:String, charPath:String, frameW:Int, idleFrames:Int, name:String, onPick:Void->Void,
			unlocked:Bool, hint:String):Void
	{
		var avatar = new FlxSprite(x + 24, 150);
		avatar.loadGraphic(avatarPath);
		avatar.scale.set(0.55, 0.55);
		avatar.updateHitbox();
		add(avatar);

		// the character itself, idling next to its portrait
		var pad = (frameW - 192) / 2;
		var who = new FlxSprite(x + 8 - pad, 236 - pad);
		who.loadGraphic(charPath, true, frameW, frameW);
		who.animation.add("idle", [for (i in 0...idleFrames) i], 10);
		who.animation.play("idle");
		add(who);

		if (unlocked)
		{
			var b = new WideButton(470, name, onPick, x - 36);
			b.scale.set(0.72, 1);
			add(b);
			return;
		}
		// locked: silhouette, greyed portrait, and the condition under the name
		avatar.color = FlxColor.fromRGB(70, 80, 90);
		who.color = FlxColor.fromRGB(30, 40, 50);
		var b = new WideButton(470, name + " (locked)", () -> {}, x - 36);
		b.scale.set(0.72, 1);
		b.label.size = 14;
		b.color = FlxColor.fromRGB(110, 120, 130);
		add(b);
		var t = new FlxText(x - 4, 548, 190, hint, 11);
		t.setFormat(null, 11, FlxColor.WHITE, CENTER);
		t.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 2);
		add(t);
	}

	function pick(kind:PlayerKind):Void
	{
		Player.selectedKind = kind;
		RunState.reset();
		FlxG.switchState(() -> new PlayState());
	}

	var nav:ui.MenuNav;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (nav != null)
			nav.update(elapsed);
	}
}
