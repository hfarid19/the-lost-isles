package states;

import entities.Player;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.WideButton;

/** The floating shop between levels: the boat pulls up to a raft with a fish
 * hut on it. Once per run. Prices run 5 gold over the island shops, no key needed. */
class RaftState extends FlxState
{
	var hero:Player; // an off-screen Player carrying the run's stats
	var goldText:FlxText;
	var stock:Array<{btn:WideButton, price:Int, label:String, buy:Void->Void}> = [];

	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;
		FlxG.mouse.load("assets/images/ui/cursor.png");
		RunState.raftUsed = true;
		fx.Sfx.ambient("sea");
		add(new FlxBackdrop("assets/images/tiles/water.png"));
		add(new fx.WaterSplashes());

		// the raft: a plank square with the fish hut on it, our boat moored alongside
		for (i in 0...5)
			for (j in 0...3)
			{
				var plank = new FlxSprite(300 + i * 64, 120 + j * 64);
				plank.loadGraphic("assets/images/tiles/bridge_all.png", true, 64, 64);
				plank.animation.frameIndex = 1;
				add(plank);
			}
		var hut = new FlxSprite(420, 60);
		hut.loadGraphic("assets/images/props/fish_hut.png", true, 192, 192);
		hut.animation.add("idle", [for (i in 0...8) i], 6);
		hut.animation.play("idle");
		add(hut);
		var boat = new FlxSprite(60, 130);
		boat.loadGraphic("assets/images/props/boat.png", true, 256, 256);
		boat.animation.add("idle", [for (i in 0...8) i], 8);
		boat.animation.play("idle");
		add(boat);
		var rider = new FlxSprite();
		var big = Player.selectedKind == Lancer;
		rider.loadGraphic(switch (Player.selectedKind)
		{
			case Knight: "assets/images/chars/warrior_full.png";
			case Lancer: "assets/images/chars/lancer_blue.png";
			case Monk: "assets/images/chars/monk_blue.png";
			default: "assets/images/chars/archer_blue.png";
		}, true, big ? 320 : 192, big ? 320 : 192);
		rider.animation.add("idle", [for (i in 0...6) i], 10);
		rider.animation.play("idle");
		rider.scale.set(0.8, 0.8);
		rider.setPosition(boat.x + 128 - rider.width / 2, boat.y + 122 - rider.height / 2);
		add(rider);

		hero = new Player(-500, -500);
		RunState.apply(hero);

		var title = new FlxText(0, 24, FlxG.width, "SHOP RAFT");
		title.setFormat(null, 30, FlxColor.WHITE, CENTER);
		title.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 60, 80), 4);
		add(title);
		goldText = new FlxText(0, 330, FlxG.width, "");
		goldText.setFormat(null, 18, FlxColor.fromRGB(255, 225, 120), CENTER);
		goldText.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 40, 50), 3);
		add(goldText);

		var def = items.ItemPool.draw();
		var offers:Array<{label:String, price:Int, buy:Void->Void}> = [
			{label: "Meat", price: 10, buy: () -> hero.hp = Std.int(Math.min(hero.maxHp, hero.hp + 2))},
			{label: "Bombs x2", price: 13, buy: () -> hero.bombs += 2},
			{label: "Key", price: 13, buy: () -> hero.keys += 1},
		];
		if (def != null)
			offers.push({label: def.name, price: 30, buy: () -> items.ItemPool.give(hero, def)});
		for (i in 0...offers.length)
		{
			var o = offers[i];
			o.price = Std.int(Math.max(1, Math.round(o.price * hero.shopDiscount))); // Merchant's Ledger
			var entry:{btn:WideButton, price:Int, label:String, buy:Void->Void} = {btn: null, price: o.price, label: o.label, buy: o.buy};
			var b = new WideButton(370 + i * 52, '${o.label}  -  ${o.price}g', () ->
			{
				if (hero.gold < entry.price)
				{
					fx.Sfx.play("deny", 0.5);
					return;
				}
				hero.gold -= entry.price;
				RunState.boughtSomething = true;
				entry.buy();
				fx.Sfx.play("buy", 0.8);
				entry.btn.active = false;
				entry.btn.alpha = 0.4;
				refresh();
			});
			entry.btn = b;
			b.scale.set(1.5, 0.7);
			b.updateHitbox(); // hitbox = the squashed art, so rows 52px apart don't overlap
			b.screenCenter(X);
			b.label.fieldWidth = Std.int(b.width);
			b.labelOffsets[0].set(0, 12);
			b.labelOffsets[1].set(0, 12);
			b.labelOffsets[2].set(0, 16);
			b.label.size = 15;
			add(b);
			stock.push(entry);
		}
		add(new WideButton(580, "Sail on", () ->
		{
			RunState.save(hero);
			FlxG.camera.fade(FlxColor.BLACK, 0.5, false, () -> FlxG.switchState(() -> new SailState()));
		}));
		refresh();
		FlxG.camera.fade(FlxColor.BLACK, 0.4, true);
		nav = ui.MenuNav.collect(this, null);
	}

	function refresh():Void
	{
		goldText.text = 'Gold: ${hero.gold}    HP: ${hero.hp}/${hero.maxHp}    Bombs: ${hero.bombs}    Keys: ${hero.keys}';
		for (s in stock)
			if (s.btn.active)
				s.btn.color = hero.gold < s.price ? FlxColor.fromRGB(150, 110, 110) : FlxColor.WHITE;
	}

	var nav:ui.MenuNav;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (nav != null)
			nav.update(elapsed);
	}
}
