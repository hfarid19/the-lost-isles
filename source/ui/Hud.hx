package ui;

import Constants.*;
import entities.Player;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import world.FloorMap;

/** Top strip HUD on its own camera: avatar + HP bar, counters on a carved
 * plaque, minimap. The boss bar lives on the MAIN camera (bottom center) —
 * PlayState adds `bossBar` separately after this group. */
class Hud extends FlxSpriteGroup
{
	public var hudCam(default, null):FlxCamera;
	public var bossBar(default, null):PackBar;
	/** Active item (R) slot: icon, key cap, and a charge bar; PlayState adds it after the group. */
	public var activeSlot(default, null):flixel.group.FlxSpriteGroup;
	var activeIcon:FlxSprite;
	var activeBarBase:FlxSprite;
	var activeBarFill:FlxSprite;
	var activeKey:FlxText;
	var activeShownId:String = null;
	var activeShownCharge:Int = -1;

	var player:Player;
	var floor:FloorMap;
	var hpBar:PackBar;
	var barMaxHp:Int = 0;
	// extra lives (Second Wind): icon + "x1" right after the HP bar
	var lifeIcon:FlxSprite;
	var lifeText:FlxText;
	var livesShown:Int = -1;
	var goldText:FlxText;
	var bombText:FlxText;
	var keyText:FlxText;
	var cells:Map<Int, FlxSprite> = new Map();
	var current:RoomNode;
	var boss:entities.BossBase;

	public function new(player:Player, floor:FloorMap)
	{
		super();
		this.player = player;
		this.floor = floor;

		hudCam = new FlxCamera(0, 0, FlxG.width, HUD_H);
		hudCam.bgColor = FlxColor.TRANSPARENT; // ocean shows through behind the banner
		FlxG.cameras.add(hudCam, false);
		camera = hudCam;
		scrollFactor.set(0, 0);

		// one carved plank spanning the whole top; everything sits on it
		add(new FlxSprite(0, 0, "assets/images/ui/hud_banner.png"));

		// portrait, on the ribbon's flat band (band ~x40..920, y6..46)
		var avatar = new FlxSprite(44, 7);
		avatar.loadGraphic(switch (Player.selectedKind)
		{
			case Knight: "assets/images/ui/avatar_knight.png";
			case Lancer: "assets/images/ui/avatar_lancer.png";
			case Monk: "assets/images/ui/avatar_monk.png";
			case Panda: "assets/images/ui/avatar_panda.png";
			default: "assets/images/ui/avatar_archer.png";
		});
		avatar.scale.set(0.165, 0.165);
		avatar.updateHitbox();
		add(avatar);

		// HP bar: one segment per heart (2 HP each) — hits chip half segments
		hpBar = new PackBar(96, -5, 3, false, Std.int(player.maxHp / 2));
		barMaxHp = player.maxHp;
		add(hpBar);
		lifeIcon = new FlxSprite(0, 9);
		lifeIcon.loadGraphic("assets/images/items/second_wind.png");
		lifeIcon.scale.set(0.5, 0.5);
		lifeIcon.updateHitbox();
		add(lifeIcon);
		lifeText = counterText(0, "");
		lifeText.size = 16;
		add(lifeText);
		refreshLives();

		// gold / bomb / key counters, right side of the band
		// (space left of them reserved for the HP bar to grow)
		var bag = new FlxSprite(600, 8);
		bag.loadGraphic("assets/images/pickups/goldbag.png");
		bag.scale.set(0.32, 0.32);
		bag.updateHitbox();
		add(bag);
		goldText = counterText(640, "0");
		add(goldText);
		var tnt = new FlxSprite(700, 5);
		tnt.loadGraphic("assets/images/fx/dynamite.png", true, 64, 64);
		tnt.animation.frameIndex = 0;
		tnt.scale.set(0.6, 0.6);
		tnt.updateHitbox();
		add(tnt);
		bombText = counterText(738, "1");
		add(bombText);
		var keyIcon = new FlxSprite(798, 10);
		keyIcon.loadGraphic("assets/images/ui/icon_key.png");
		keyIcon.scale.set(0.5, 0.5);
		keyIcon.updateHitbox();
		add(keyIcon);
		keyText = counterText(838, "0");
		add(keyText);

		// boss bar: main camera, bottom center, hidden until a boss appears
		bossBar = new PackBar(0, 0, 4, true);
		bossBar.camera = FlxG.camera;
		bossBar.scrollFactor.set(0, 0);
		bossBar.setPosition((FlxG.width - (4 * 64 + 48)) / 2, FlxG.height - 70);
		bossBar.visible = false;

		// active item slot: bottom-left corner of the play view (icon, R key cap, charge bar)
		activeSlot = new flixel.group.FlxSpriteGroup(18, FlxG.height - 96);
		activeSlot.camera = FlxG.camera;
		activeSlot.scrollFactor.set(0, 0);
		activeIcon = new FlxSprite(0, 0);
		activeSlot.add(activeIcon);
		activeKey = new FlxText(-18, -18, 100, "SPACE", 11);
		activeKey.wordWrap = false;
		activeKey.setFormat(null, 18, FlxColor.fromRGB(255, 225, 120), CENTER);
		activeKey.setBorderStyle(SHADOW, FlxColor.fromRGB(30, 40, 50), 2);
		activeSlot.add(activeKey);
		activeBarBase = new FlxSprite(0, 68);
		activeBarBase.makeGraphic(64, 10, FlxColor.fromRGB(30, 40, 50));
		activeSlot.add(activeBarBase);
		activeBarFill = new FlxSprite(1, 69);
		activeBarFill.makeGraphic(62, 8, FlxColor.fromRGB(255, 225, 120));
		activeSlot.add(activeBarFill);
		activeSlot.visible = false;

		// minimap hidden for now — call buildMinimap() to restore
	}

	/** Mirror the hero's active item into the slot (cheap: only rebuilds when something changed). */
	function refreshActive():Void
	{
		if (player.activeId == null)
		{
			activeSlot.visible = false;
			activeShownId = null;
			return;
		}
		if (player.activeId != activeShownId)
		{
			activeShownId = player.activeId;
			var def = items.ItemPool.byId(player.activeId);
			activeIcon.loadGraphic(def.icon);
			activeIcon.scale.set(1, 1);
			activeIcon.updateHitbox();
			activeIcon.setPosition(activeSlot.x, activeSlot.y);
			// one tick per room of charge
			activeBarBase.makeGraphic(64, 10, FlxColor.fromRGB(30, 40, 50), true);
			for (i in 1...player.activeMax)
				flixel.util.FlxSpriteUtil.drawRect(activeBarBase, Std.int(64 * i / player.activeMax) - 1, 0, 2, 10, FlxColor.fromRGB(30, 40, 50));
			activeSlot.visible = true;
			activeShownCharge = -1;
		}
		if (player.activeCharge != activeShownCharge)
		{
			activeShownCharge = player.activeCharge;
			var ready = player.activeCharge >= player.activeMax;
			var frac = player.activeMax > 0 ? player.activeCharge / player.activeMax : 1;
			activeBarFill.visible = frac > 0;
			if (frac > 0)
				activeBarFill.makeGraphic(Std.int(Math.max(1, 62 * frac)), 8, ready ? FlxColor.fromRGB(255, 225, 120) : FlxColor.fromRGB(120, 200, 120), true);
			// ticks between rooms of charge
			for (i in 1...player.activeMax)
			{
				var tx = Std.int(64 * i / player.activeMax) - 1 - 1;
				if (tx < activeBarFill.width)
					flixel.util.FlxSpriteUtil.drawRect(activeBarFill, tx, 0, 2, 8, FlxColor.fromRGB(30, 40, 50));
			}
			activeIcon.alpha = ready ? 1 : 0.45;
			activeKey.color = ready ? FlxColor.fromRGB(255, 225, 120) : FlxColor.fromRGB(150, 150, 150);
		}
	}

	/** Second Wind lives sit just past the HP bar's right cap. */
	function refreshLives():Void
	{
		livesShown = player.secondWind;
		var show = player.secondWind > 0;
		lifeIcon.visible = show;
		lifeText.visible = show;
		if (!show)
			return;
		var barEnd = hpBar.x + hpBar.width + 4;
		lifeIcon.setPosition(barEnd, 9);
		lifeText.setPosition(barEnd + 30, 14);
		lifeText.text = "x" + player.secondWind;
	}

	static function counterText(x:Float, s:String):FlxText
	{
		var t = new FlxText(x, 14, 60, s, 20);
		t.setBorderStyle(SHADOW, FlxColor.fromRGB(60, 45, 25), 2);
		return t;
	}

	function buildMinimap():Void
	{
		var minX = 99, minY = 99, maxX = -1, maxY = -1;
		for (n in floor.nodes)
		{
			if (n.gx < minX) minX = n.gx;
			if (n.gy < minY) minY = n.gy;
			if (n.gx > maxX) maxX = n.gx;
			if (n.gy > maxY) maxY = n.gy;
		}
		var cw = 14, ch = 9, gap = 2;
		var w = (maxX - minX + 1) * (cw + gap);
		var h = (maxY - minY + 1) * (ch + gap);
		var x0 = FlxG.width - w - 24;
		var y0 = Std.int((HUD_H - h) / 2);

		for (n in floor.nodes)
		{
			var cell = new FlxSprite(x0 + (n.gx - minX) * (cw + gap), y0 + (n.gy - minY) * (ch + gap));
			cell.makeGraphic(cw, ch, FlxColor.fromRGB(70, 76, 90));
			add(cell);
			cells.set(floor.key(n.gx, n.gy), cell);
		}
	}

	public function setCurrentRoom(node:RoomNode):Void
	{
		current = node;
	}

	public function setBoss(boss:entities.BossBase):Void
	{
		this.boss = boss;
		bossBar.visible = true;
	}

	override public function update(elapsed:Float):Void
	{
		refreshActive();
		super.update(elapsed);
		if (player.maxHp != barMaxHp)
		{
			// max HP changed: rebuild the bar one middle piece per heart (capped so it
			// never runs into the counters), with a pip per heart
			barMaxHp = player.maxHp;
			remove(hpBar, true);
			hpBar.destroy();
			var hearts = Std.int(Math.ceil(player.maxHp / 2));
			hpBar = new PackBar(96, -5, Std.int(Math.min(6, Math.max(3, hearts))), false, hearts);
			insert(2, hpBar);
		}
		hpBar.setFraction(player.hp / player.maxHp);
		if (player.secondWind != livesShown || player.maxHp != barMaxHp)
			refreshLives();
		goldText.text = Std.string(player.gold);
		bombText.text = Std.string(player.bombs);
		keyText.text = Std.string(player.keys);

		if (boss != null && bossBar.visible)
		{
			bossBar.setFraction(boss.hp / boss.maxHp);
			if (!boss.alive)
				bossBar.visible = false;
		}

		for (key => cell in cells)
		{
			var n = floor.nodes.get(key);
			cell.color = if (current != null && n == current) FlxColor.WHITE
			else if (n.kind == Boss && (n.visited || isAdjacentToVisited(n))) FlxColor.fromRGB(190, 60, 60)
			else if (n.kind == Treasure && (n.visited || isAdjacentToVisited(n))) FlxColor.fromRGB(220, 180, 60)
			else if (n.kind == Shop && (n.visited || isAdjacentToVisited(n))) FlxColor.fromRGB(70, 190, 170)
			else if (n.kind == Secret) FlxColor.fromRGB(180, 140, 220)
			else if (n.visited) FlxColor.fromRGB(150, 156, 170)
			else if (isAdjacentToVisited(n)) FlxColor.fromRGB(90, 96, 110)
			else FlxColor.fromRGB(45, 50, 62);
			cell.visible = n.kind == Secret ? (n.visited || n.revealed) : (n.visited || isAdjacentToVisited(n));
		}
	}

	function isAdjacentToVisited(n:RoomNode):Bool
	{
		for (d in [[0, -1], [1, 0], [0, 1], [-1, 0]])
		{
			var m = floor.get(n.gx + d[0], n.gy + d[1]);
			if (m != null && m.visited)
				return true;
		}
		return false;
	}
}
