package states;

import Constants.*;
import combat.Bow;
import entities.Arrow;
import entities.Dynamite;
import entities.Enemy;
import entities.Explosion;
import entities.Pickup;
import entities.Player;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup.FlxTypedGroup;
import ui.Hud;
import world.FloorGenerator;
import world.FloorMap;
import world.LdtkLoader;
import world.Room;
import world.RoomController;

class PlayState extends FlxState
{
	public var player:Player;

	var floor:FloorMap;
	var controller:RoomController;
	var playerShots:FlxTypedGroup<Arrow>;
	var enemies:FlxTypedGroup<Enemy>;
	var bombs:FlxTypedGroup<Dynamite>;
	var explosions:FlxTypedGroup<Explosion>;
	var pickups:FlxTypedGroup<Pickup>;
	var hud:Hud;
	var gameOverStarted:Bool = false;
	var solidProps:FlxTypedGroup<entities.Prop>;
	var softProps:FlxTypedGroup<entities.Prop>;
	var coins:FlxTypedGroup<entities.Coin>;
	var clouds:fx.Clouds;
	var meleeSwings:FlxTypedGroup<entities.MeleeSwing>;
	var console:ui.DevConsole;
	var dummy:entities.TrainingDummy;
	var masks:Array<flixel.FlxSprite>;

	function updateMasks():Void
	{
		var vis = controller.active != null && !controller.transitioning;
		for (m in masks)
			m.visible = vis;
		if (!vis)
			return;
		var room = controller.roomOf(controller.active);
		var rx = room.worldX - FlxG.camera.scroll.x;
		var ry = room.worldY - FlxG.camera.scroll.y;
		masks[0].setPosition(rx - 1024, ry - 1024); // above the room
		masks[1].setPosition(rx - 1024, ry + room.pxH); // below
		masks[2].setPosition(rx - 1024, ry - 32); // left
		masks[3].setPosition(rx + room.pxW, ry - 32); // right
	}
	var campfires:FlxTypedGroup<entities.Campfire>;
	var pedestals:FlxTypedGroup<entities.ItemPedestal>;
	var shopItems:FlxTypedGroup<entities.ShopItem>;
	var familiars:FlxTypedGroup<entities.Familiar>;
	var itemCard:ui.ItemCard;
	var bossCard:ui.BossCard;
	var floorMap:ui.FloorMapOverlay;
	var worldLayer:FlxTypedGroup<flixel.FlxSprite>;
	var playerGroup:FlxTypedGroup<Player>;

	/** Refill the depth-sorted layer from the ground-standing groups. */
	var rerollHintNode:world.FloorMap.RoomNode = null;

	/** Shaman Charm: one hit in ten turns a regular enemy into a harmless sheep. */
	function maybeHex(e:Enemy):Void
	{
		if (!player.sheepHex || !e.alive || e.harmless || e.isRealBoss() || e.flying || FlxG.random.int(0, 9) != 0)
			return;
		var sheep = new entities.Sheep(e.x + e.width / 2 - 20, e.y + e.height - 26);
		sheep.init(player);
		enemies.add(sheep);
		fx.PackFx.play("skull_smoke", e.x + e.width / 2, e.y + e.height / 2, 1.3);
		fx.Sfx.play("hex", 0.7);
		fx.Sfx.play("sheep", 0.6);
		e.kill();
	}
	var volumeText:flixel.text.FlxText;

	/** [ and ] keys: master volume down / up, shown briefly under the HUD. */
	function volumeKeys():Void
	{
		if (ui.DevConsole.open)
			return;
		var dir = FlxG.keys.justPressed.RBRACKET ? 1 : (FlxG.keys.justPressed.LBRACKET ? -1 : 0);
		if (dir == 0)
			return;
		showVolume(Settings.step(dir));
	}

	function showVolume(v:Float):Void
	{
		if (volumeText == null)
		{
			volumeText = new flixel.text.FlxText(0, 70, FlxG.width, "", 16);
			volumeText.setFormat(null, 16, flixel.util.FlxColor.WHITE, CENTER);
			volumeText.setBorderStyle(SHADOW, flixel.util.FlxColor.fromRGB(30, 40, 50), 2);
			volumeText.scrollFactor.set(0, 0);
			add(volumeText);
		}
		volumeText.text = "volume " + Math.round(v * 100) + "%";
		volumeText.alpha = 1;
		flixel.tweens.FlxTween.cancelTweensOf(volumeText);
		flixel.tweens.FlxTween.tween(volumeText, {alpha: 0}, 0.6, {startDelay: 1.2});
		fx.Sfx.play("ui", 0.6);
	}

	/** The untaken pedestal in the active room (treasure, boss drop, or secret), if any. */
	function roomPedestal():entities.ItemPedestal
	{
		if (controller.active == null)
			return null;
		var room = controller.roomOf(controller.active);
		var target:entities.ItemPedestal = null;
		pedestals.forEachAlive(pd ->
		{
			if (pd.x >= room.worldX && pd.x < room.worldX + room.pxW && pd.y >= room.worldY && pd.y < room.worldY + room.pxH)
				target = pd;
		});
		return target;
	}

	/** Lucky Coin: swap the room's untaken pedestal for a fresh draw (the old item returns to the pool).
	 * False when there is nothing to reroll. */
	function rerollPedestal():Bool
	{
		var target = roomPedestal();
		if (target == null)
			return false;
		var fresh = items.ItemPool.draw();
		if (fresh == null)
			return false;
		items.ItemPool.putBack(target.def);
		var np = new entities.ItemPedestal(target.x, target.y, fresh);
		target.kill();
		pedestals.add(np);
		player.activeCharge = 0;
		fx.PackFx.play("sparkle", np.x + np.width / 2, np.y - 20, 1.2);
		fx.Sfx.play("coin", 0.8);
		return true;
	}

	/** Set by the /packs console command: the next PlayState is the sprite-gallery floor. */
	public static var galleryNext:Bool = false;

	/** Debug gallery floor: fill each room with the next batch of preview sprites. */
	function buildGallery():Void
	{
		var order = [for (n in floor.nodes) if (n.owner == null) n];
		order.sort((a, b) -> (a.gy != b.gy) ? (a.gy - b.gy) : (a.gx - b.gx));
		for (i in 0...order.length)
		{
			var r = controller.roomOf(order[i]);
			add(fx.PackPreview.build(i, r.worldX, r.worldY, TILE));
		}
	}

	function sortWorld():Void
	{
		var m = worldLayer.members;
		m.resize(0);
		inline function take(g:FlxTypedGroup<Dynamic>):Void
			for (o in g.members)
				if (o != null && o.exists)
					m.push(cast o);
		take(softProps);
		take(solidProps);
		take(campfires);
		take(pedestals);
		take(shopItems);
		take(familiars);
		take(playerGroup);
		take(enemies);
		worldLayer.length = m.length;
		m.sort((a, b) ->
		{
			var ya = a.y + a.height, yb = b.y + b.height;
			return ya < yb ? -1 : (ya > yb ? 1 : 0);
		});
	}
	var mapHeld:Bool = false; // console toggle for the map
	var bossIntro:Bool = false; // play is frozen while the card shows

	function teleportTo(kind:world.FloorMap.RoomKind, name:String):String
	{
		for (n in floor.nodes)
			if (n.kind == kind && n.owner == null)
			{
				// leave the old room's enemies behind, like a real door transition does
				for (e in enemies)
					e.kill();
				enemies.clear();
				var room = controller.roomOf(n);
				player.setPosition(room.worldX + 3 * TILE, room.worldY + 4 * TILE);
				controller.clampCamera(room);
				controller.activate(n);
				return 'teleported to $name room';
			}
		return 'no $name room on this floor';
	}

	function teleportToTreasure():String
	{
		for (n in floor.nodes)
			if (n.kind == Treasure)
			{
				for (e in enemies)
					e.kill();
				enemies.clear();
				var room = controller.roomOf(n);
				player.setPosition(room.worldX + 3 * TILE, room.worldY + 4 * TILE);
				controller.clampCamera(room);
				controller.activate(n);
				return "teleported to treasure room";
			}
		return "no treasure room on this floor";
	}

	function teleportToBoss():String
	{
		for (n in floor.nodes)
			if (n.kind == Boss)
			{
				for (e in enemies)
					e.kill();
				enemies.clear();
				var room = controller.roomOf(n);
				player.setPosition(room.worldX + 3 * TILE, room.worldY + 4 * TILE);
				controller.clampCamera(room);
				controller.activate(n);
				return "teleported to boss room";
			}
		return "no boss room on this floor";
	}

	function runCommand(cmd:String):String
	{
		var parts = StringTools.trim(cmd).split(" ");
		var arg = parts.length > 1 ? Std.parseInt(parts[1]) : null;
		return switch (parts[0])
		{
			case "/boss":
				teleportToBoss();
			case "/treasure":
				teleportToTreasure();
			case "/shop":
				teleportTo(Shop, "shop");
			case "/keys":
				player.keys = arg != null ? arg : 3;
				'keys: ${player.keys}';
			case "/next":
				startSail();
				"sailing to " + RunState.floorName();
			case "/volume":
				if (arg != null)
					Settings.setVolume(arg / 100);
				showVolume(Settings.volume);
				'volume ${Math.round(Settings.volume * 100)}%';
			case "/campfire":
				campfires.add(new entities.Campfire(player.x + 170, player.y + 10));
				"campfire lit";
			case "/resume":
				// debug: reload this floor from its checkpoint, as Continue on the slot screen would
				if (!RunState.hasSavedRun())
					"no saved run"
				else
				{
					RunState.resume();
					FlxG.resetState();
					"resuming " + RunState.floorName();
				}
			case "/packs":
				// rebuild this floor as the sprite gallery (downloaded monster / chest packs at 2x)
				galleryNext = true;
				FlxG.resetState();
				"sprite gallery";
			case "/floor":
				RunState.floorName() + (RunState.lastBoss != "" ? ' (boss: ${RunState.lastBoss})' : "");
			case "/combat":
				teleportTo(Normal, "combat");
			case "/spawn":
				var kind = parts.length > 1 ? parts[1] : "torch";
				var ex = player.x + 220, ey = player.y;
				var e:Enemy = switch (kind)
				{
					case "pig": new entities.Pig(ex, ey);
					case "gnome": new entities.Gnome(ex, ey);
					case "snake", "mushroom": new entities.Snake(ex, ey);
					case "bee": new entities.Bumblebee(ex, ey);
					case "slingshot", "flyer": new entities.SlingshotGnome(ex, ey);
					case "spear": new entities.SpearGoblin(ex, ey);
					case "elite": new entities.SpearGoblinElite(ex, ey);
					case "barrel": new entities.BarrelGoblin(ex, ey);
					case "cannon": new entities.Cannon(ex, ey);
					case "tnt": new entities.TntGoblin(ex, ey);
					case "thief", "skeleton": new entities.Thief(ex, ey);
					case "archer": new entities.BlackArcher(ex, ey);
					case "monk": new entities.BlackMonk(ex, ey, null);
					case "skull": new entities.Skull(ex, ey);
					case "imp": new entities.Imp(ex, ey);
					case "guard", "golem": new entities.MinoGuard(ex, ey);
					case "turtle": new entities.Turtle(ex, ey);
					case "pandaguard": new entities.PandaGuard(ex, ey);
					case "sheep": new entities.Sheep(ex, ey);
					case "harpoonshark": new entities.HarpoonShark(ex, ey);
					case "paddleshark": new entities.PaddleShark(ex, ey);
					case "bombfish": new entities.BombFish(ex, ey);
					case "tower": new entities.PirateTower(ex, ey);
					case "rider": new entities.SeahorseRider(ex, ey);
					case "knight": new entities.BlackKnight(ex, ey);
					case "lancer": new entities.BlackLancer(ex, ey);
					case "pawn": new entities.BlackPawn(ex, ey);
					case "blacktower": new entities.BlackTower(ex, ey);
					case "gnometower": new entities.GnomeTower(ex, ey);
					case "goldmine": new entities.GoldMine(ex, ey);
					case "bat": new entities.Bat(ex, ey);
					default: new entities.TorchGoblin(ex, ey);
				}
				e.init(player);
				e.nav = controller.roomOf(controller.active).navMap;
				enemies.add(e);
				'spawned $kind';
			case "/block":
				Player.debugBlock = !Player.debugBlock;
				Player.debugBlock ? "shield held" : "shield released";
			case "/bossname":
				world.LevelDefs.forceBoss = parts.length > 1 ? parts[1] : null;
				"next boss: " + world.LevelDefs.forceBoss;
			case "/sfxtest":
				var snd = FlxG.sound.play("assets/sounds/bow_shot_1.ogg", 1.0);
				var ex = openfl.utils.Assets.exists("assets/sounds/bow_shot_1.ogg");
				var raw = lime.utils.Assets.getAudioBuffer("assets/sounds/bow_shot_1.ogg");
				var lib = lime.utils.Assets.getLibrary("default");
				var t = lib != null ? Std.string(@:privateAccess lib.types.get("assets/sounds/bow_shot_1.ogg")) : "nolib";
				'exists=$ex type=$t buffer=${raw != null} sound=${snd != null} playing=${snd != null && snd.playing} vol=${FlxG.sound.volume} muted=${FlxG.sound.muted}';
			case "/map":
				mapHeld = !mapHeld;
				mapHeld ? "map shown" : "map hidden";
			case "/secret":
				teleportTo(Secret, "secret");
			case "/raft":
				RunState.save(player);
				FlxG.switchState(() -> new RaftState());
				"raft";
			case "/slots":
				FlxG.switchState(() -> new SlotSelectState());
				"save slots";
			case "/unlocks":
				Unlocks.status();
			case "/unlockall":
				Unlocks.unlockAll();
				Unlocks.status();
			case "/item":
				var def = parts.length > 1 ? items.ItemPool.byId(parts[1]) : items.ItemPool.draw();
				if (def == null)
					"no such item (ids: " + [for (d in items.ItemPool.all) d.id].join(", ") + ")";
				else
				{
					items.ItemPool.give(player, def);
					itemCard.show(def);
					'got ${def.name}';
				}
			case "/heal":
				player.hp = player.maxHp;
				"healed";
			case "/gold":
				player.gold += arg != null ? arg : 25;
				'gold: ${player.gold}';
			case "/bombs":
				player.bombs = arg != null ? arg : 99;
				'bombs: ${player.bombs}';
			case "/god":
				Player.godMode = !Player.godMode;
				Player.godMode ? "god mode ON" : "god mode OFF";
			case "/kill":
				enemies.forEachAlive(e -> e.slay());
				"room cleared";
			default:
				'unknown command: ${parts[0]}';
		}
	}

	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;

		#if html5
		// Debug: ?seed=N pins the floor layout for reproducible runs
		var m = ~/[?&]seed=(\d+)/;
		if (m.match(js.Browser.location.search))
			FlxG.random.initialSeed = Std.parseInt(m.matched(1));
		#end
		ui.DevConsole.open = false; // static; must not leak across restarts
		#if html5
		world.RoomController.debugAutoClear = js.Browser.location.search.indexOf("clear") >= 0;
		Player.godMode = js.Browser.location.search.indexOf("god") >= 0;
		#end
		#if html5
		if (js.Browser.location.search.indexOf("debuglog") >= 0)
		{
			js.Browser.window.setInterval(() ->
			{
				js.Browser.console.log('RAWTICK ticks=${FlxG.game.ticks} focus=${js.Browser.document.hasFocus()} autoPause=${FlxG.autoPause}');
			}, 1000);
			js.Browser.window.addEventListener("error", (e:Dynamic) -> js.Browser.console.log('WINERR ${e.message} @${e.filename}:${e.lineno}:${e.colno} ${e.error != null ? Std.string(e.error.stack).substr(0, 600) : ""}'));
			js.Browser.window.addEventListener("unhandledrejection", (e:Dynamic) -> js.Browser.console.log('WINREJ ${e.reason}'));
		}
		#end
		// debug URL flags only shape a FRESH run; later floors of the same run ignore them
		var freshRun = !RunState.active;
		if (freshRun)
			RunState.reset();
		#if html5
		if (freshRun)
		{
			// debug: ?bamboo unlocks everything (incl. the Bamboo Isle) so ?level=5 reaches it
			if (js.Browser.location.search.indexOf("bamboo") >= 0)
			{
				Unlocks.unlockAll();
				RunState.buildLevels();
			}
			var lm = ~/[?&]level=(\d+)/;
			if (lm.match(js.Browser.location.search))
				RunState.level = Std.int(Math.min(RunState.levels.length - 1, Std.parseInt(lm.matched(1)) - 1));
			var fm = ~/[?&]floor=(\d+)/;
			if (fm.match(js.Browser.location.search))
				RunState.floor = Std.int(Math.min(RunState.levels[RunState.level].floors - 1, Std.parseInt(fm.matched(1)) - 1));
		}
		#end
		if (RunState.resumeSeed != 0)
		{
			FlxG.random.initialSeed = RunState.resumeSeed; // rebuild the saved floor
			RunState.resumeSeed = 0;
		}
		#if !html5
		if (Sys.getEnv("SFXPROBE") != null)
			flixel.util.FlxTimer.wait(1.0, () -> Sys.println("SFXPROBE " + runCommand("/sfxtest")));
		#end
		world.LevelDefs.applyRoomSize(); // 15x9 islands, 23x13 in the Keep
		// weather: rolled once per floor (kept in the checkpoint); none underground
		if (RunState.resumeSeed == 0 && !world.LevelDefs.isIndoor())
			RunState.weather = FlxG.random.int(0, 99) < 12 ? 2 : (FlxG.random.int(0, 99) < 25 ? 1 : 0);
		if (world.LevelDefs.isIndoor())
			RunState.weather = 0;
		var ambName = switch (world.LevelDefs.id())
		{
			case "forest": RunState.floor == 0 ? "forest" : "forest_night";
			case "bamboo": "forest";
			case "waters", "troy": "sea";
			case "mines": "cave";
			case "caves": "cave";
			case "keep": "sea";
			default: "beach";
		};
		fx.Sfx.ambient(ambName + (RunState.weather == 2 ? "_storm" : (RunState.weather == 1 ? "_rain" : "")));
		// three loops for now: calm harbour on the Plains, brighter on the Forest and Camp, foggy in the dark
		fx.Sfx.music(switch (world.LevelDefs.id())
		{
			case "plains": "silent_harbor";
			case "forest", "camp", "bamboo": "hidden_booty";
			default: "foggy_shores";
		});
		runSeed = FlxG.random.initialSeed;
		trace('Floor seed: $runSeed (${RunState.floorName()})');
		#if html5
		world.RoomController.gallery = galleryNext || js.Browser.location.search.indexOf("packs") >= 0;
		#else
		world.RoomController.gallery = galleryNext || Sys.getEnv("PACKS") != null; // PACKS=1 <binary> boots the sprite gallery
		#end
		galleryNext = false;
		floor = world.RoomController.gallery ? FloorGenerator.gallery(fx.PackPreview.roomsNeeded()) : FloorGenerator.generate();
		trace("\n" + floor.toAscii());

		var indoor = world.LevelDefs.isIndoor();
		add(new FlxBackdrop(indoor ? "assets/images/tiles/void.png" : "assets/images/tiles/water.png"));
		if (!indoor)
			add(new fx.WaterSplashes());

		playerShots = new FlxTypedGroup<Arrow>(40);
		Bow.pool = playerShots;
		meleeSwings = new FlxTypedGroup<entities.MeleeSwing>(8);
		combat.MeleeWeapon.swings = meleeSwings;
		bombs = new FlxTypedGroup<Dynamite>(16);
		entities.TntGoblin.bombs = bombs;
		Dynamite.pool = bombs;
		explosions = new FlxTypedGroup<Explosion>(16);
		Dynamite.explosions = explosions;
		enemyShots = new FlxTypedGroup<entities.EnemyShot>(24);
		entities.EnemyShot.pool = enemyShots;
		groundShots = new FlxTypedGroup<entities.EnemyShot>(40);
		entities.EnemyShot.groundPool = groundShots;
		enemies = new FlxTypedGroup<Enemy>();
		pickups = new FlxTypedGroup<Pickup>();
		Pickup.group = pickups;
		solidProps = new FlxTypedGroup<entities.Prop>();
		softProps = new FlxTypedGroup<entities.Prop>();
		coins = new FlxTypedGroup<entities.Coin>(32);
		entities.Prop.coins = coins;
		pedestals = new FlxTypedGroup<entities.ItemPedestal>();
		entities.ItemPedestal.group = pedestals;
		shopItems = new FlxTypedGroup<entities.ShopItem>();
		if (RunState.floorNumber() == 0 || freshRun)
			items.ItemPool.reset(); // the pool persists across the run's floors (debug boots start fresh)

		// player at start room's PlayerSpawn
		var startTemplate = LdtkLoader.get(floor.start.templateId);
		var px = floor.start.gx * ROOM_W + 7 * TILE + 10;
		var py = floor.start.gy * ROOM_H + 4 * TILE + 16;
		for (s in startTemplate.spawns)
			if (s.kind == "PlayerSpawn")
			{
				px = floor.start.gx * ROOM_W + s.cx * TILE + 10;
				py = floor.start.gy * ROOM_H + s.cy * TILE + 16;
			}
		player = new Player(px, py);
		RunState.apply(player); // stats carried from the previous floor
		familiars = new FlxTypedGroup<entities.Familiar>();
		entities.Familiar.group = familiars;
		entities.Familiar.player = player;
		entities.Familiar.enemies = enemies;
		Enemy.all = enemies;
		entities.GoldMine.host = enemies;
		items.ItemPool.respawnFamiliars(player);
		RunState.persist(player, runSeed); // checkpoint: closing the game resumes this floor

		campfires = new FlxTypedGroup<entities.Campfire>();
		controller = new RoomController(floor, player, enemies, pickups);
		controller.onBossActivate = spawnBoss;
		entities.WaterEnemy.roomAt = (wx, wy) ->
		{
			var found:world.Room = null;
			for (r in controller.rooms)
				if (wx >= r.worldX && wx < r.worldX + r.pxW && wy >= r.worldY && wy < r.worldY + r.pxH)
					found = r;
			return found;
		};
		controller.solidProps = solidProps;
		controller.softProps = softProps;
		controller.campfires = campfires;
		controller.pedestals = pedestals;
		controller.shopItems = shopItems;
		controller.build();
		// draw order by feet: a rock two tiles above a tree sits behind its canopy
		solidProps.sort((order, a, b) -> flixel.util.FlxSort.byValues(order, a.y + a.height, b.y + b.height));

		for (room in controller.rooms)
			add(room.foam); // shoreline foam sits between water and ground
		tierWalls = new FlxTypedGroup<flixel.FlxObject>();
		for (room in controller.rooms)
		{
			add(room.groundMap);
			if (room.plateauMap != null)
			{
				add(room.plateauMap);
				for (w in room.tierWalls)
					tierWalls.add(w);
			}
			add(room.collisionMap);
			add(room.pitMap); // Water Walker variant; tilemaps only collide once they're in the state
		}
		add(tierWalls);

		// clouds drift over the whole floor
		var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9;
		for (n in floor.nodes)
		{
			minX = Math.min(minX, n.gx * ROOM_W);
			minY = Math.min(minY, n.gy * ROOM_H);
			maxX = Math.max(maxX, (n.gx + 1) * ROOM_W);
			maxY = Math.max(maxY, (n.gy + 1) * ROOM_H);
		}
		var roomCount = 0;
		for (_ in floor.nodes)
			roomCount++;
		clouds = new fx.Clouds(flixel.math.FlxRect.get(minX, minY, maxX - minX, maxY - minY), indoor ? 0 : roomCount * 2);
		if (!indoor)
			add(clouds.shadows);

		for (door in controller.doors)
			add(door);

		add(pickups);
		add(coins);
		add(groundShots); // fire trails and puddles lie on the ground, under everyone
		// everything standing on the ground draws from one layer sorted by feet, so a
		// hero in front of a tree or a scarecrow is drawn over it and behind it otherwise;
		// the source groups keep updating and colliding but no longer draw themselves
		playerGroup = new FlxTypedGroup<Player>();
		playerGroup.add(player);
		for (g in [cast(softProps, FlxTypedGroup<Dynamic>), solidProps, campfires, pedestals, shopItems, familiars, playerGroup, enemies])
			g.visible = false;
		add(softProps);
		add(solidProps);
		add(campfires);
		add(pedestals);
		add(shopItems);
		add(familiars);
		add(playerGroup);
		add(enemies);
		worldLayer = new FlxTypedGroup<flixel.FlxSprite>();
		worldLayer.active = false; // draw only; members are updated by their own groups
		add(worldLayer);
		add(bombs);
		add(playerShots);
		add(meleeSwings);
		add(enemyShots);
		add(explosions);
		fx.PackFx.pool = new FlxTypedGroup<fx.PackFx.PackFxSprite>(24);
		add(fx.PackFx.pool);
		if (!indoor)
			add(clouds.puffs);
		if (indoor)
		{
			// caves: darkness with a soft hole that follows the hero
			darkness = new flixel.FlxSprite(0, 0, "assets/images/fx/darkness.png");
			add(darkness);
		}
		if (RunState.weather > 0)
			add(new fx.Weather(RunState.weather == 2));


		// black surround: masks everything outside the active room so odd
		// window shapes (fullscreen) never reveal bridges-to-nowhere.
		// Full-size bitmaps: flixel culls by unscaled frame bounds, so
		// scaled-up tiny graphics get skipped.
		masks = [];
		inline function mkMask(w:Int, h:Int, key:String):Void
		{
			var m = new flixel.FlxSprite();
			m.makeGraphic(w, h, flixel.util.FlxColor.BLACK, false, key);
			m.scrollFactor.set(0, 0);
			add(m);
			masks.push(m);
		}
		mkMask(3584, 1024, "maskH");
		mkMask(3584, 1024, "maskH");
		mkMask(1024, 1088, "maskV");
		mkMask(1024, 1088, "maskV");

		hud = new Hud(player, floor);
		add(hud);
		add(hud.bossBar);
		add(hud.activeSlot);
		itemCard = new ui.ItemCard();
		add(itemCard);
		bossCard = new ui.BossCard();
		add(bossCard);
		floorMap = new ui.FloorMapOverlay(floor);
		add(floorMap);
		console = new ui.DevConsole();
		console.onCommand = runCommand;
		add(console);
		FlxG.mouse.load("assets/images/ui/cursor.png");

		// how you arrived: the boat moored on the start room's west shore, or the cave
		// mouth you walked out of on cave floors (both decorative)
		{
			var startRoom = controller.roomOf(floor.start);
			if (world.LevelDefs.isIndoor())
			{
				var mouth = new entities.CaveMouth();
				mouth.reset(startRoom.worldX + 1 * TILE, startRoom.worldY + DOOR_W_Y * TILE + 12);
				mouth.alpha = 1;
				mouth.scale.set(1, 1);
				insert(members.indexOf(pedestals), mouth);
			}
			else
			{
				var moored = new entities.Boat();
				moored.reset(startRoom.worldX + 0 * TILE - 20, startRoom.worldY + DOOR_W_Y * TILE);
				insert(members.indexOf(pedestals), moored);
			}
		}
		// training dummy: scarecrow right of the start-room spawn, first floor only
		if (RunState.floorNumber() == 0)
		{
			dummy = new entities.TrainingDummy(floor.start.gx * ROOM_W + 10 * TILE + 12,
				floor.start.gy * ROOM_H + 4 * TILE + 38);
			add(dummy);
			add(dummy.label());
		}

		controller.clampCamera(controller.roomOf(floor.start));
		controller.activate(floor.start);
		sortWorld();

		// Debug: ?packs / PACKS=1 / the /packs console command: the sprite-gallery floor
		if (world.RoomController.gallery)
			buildGallery();
		#if html5
		if (freshRun)
		{
		// Debug: ?bossroom starts inside the boss room
		if (js.Browser.location.search.indexOf("bossroom") >= 0)
		{
			for (n in floor.nodes)
				if (n.kind == Boss)
				{
					var room = controller.roomOf(n);
					player.setPosition(room.worldX + 3 * TILE, room.worldY + 4 * TILE);
					controller.clampCamera(room);
					controller.activate(n);
				}
		}
		// Debug: ?treasure / ?shop start inside that room
		if (js.Browser.location.search.indexOf("treasure") >= 0)
			teleportToTreasure();
		if (js.Browser.location.search.indexOf("combat") >= 0)
			teleportTo(Normal, "combat");
		if (js.Browser.location.search.indexOf("shop") >= 0)
		{
			player.gold = 40;
			player.keys = 2;
			teleportTo(Shop, "shop");
		}
		// Debug: ?nextboss starts in the room adjacent to the boss room and
		// runs the real door transition into it after 1s
		if (js.Browser.location.search.indexOf("nextboss") >= 0)
		{
			for (n in floor.nodes)
				if (n.kind == Boss)
				{
					var dirs = [
						{d: world.FloorMap.N, dx: 0, dy: -1},
						{d: world.FloorMap.E, dx: 1, dy: 0},
						{d: world.FloorMap.S, dx: 0, dy: 1},
						{d: world.FloorMap.W, dx: -1, dy: 0}
					];
					for (v in dirs)
					{
						var nb = floor.get(n.gx + v.dx, n.gy + v.dy);
						if (nb == null)
							continue;
						var room = controller.roomOf(nb);
						player.setPosition(room.worldX + 7 * TILE, room.worldY + 4 * TILE);
						controller.clampCamera(room);
						controller.activate(nb);
						var into = switch (v.d) // door from neighbor toward boss
						{
							case world.FloorMap.N: world.FloorMap.S;
							case world.FloorMap.E: world.FloorMap.W;
							case world.FloorMap.S: world.FloorMap.N;
							default: world.FloorMap.E;
						};
						trace('nextboss: in room ${nb.gx},${nb.gy}, will transition dir=$into');
						flixel.util.FlxTimer.wait(1.0, () -> controller.transitionToward(n));
						break;
					}
					break;
				}
		}
		}
		#end
	}

	var boss:entities.BossBase;
	var won:Bool = false;
	var boat:entities.Boat;
	var caveMouth:entities.CaveMouth;
	var sailing:Bool = false;
	var enemyShots:FlxTypedGroup<entities.EnemyShot>;
	var groundShots:FlxTypedGroup<entities.EnemyShot>;
	var darkness:flixel.FlxSprite;
	/** One-way cliff edges from every plateau room: block from below, drop from above. */
	var tierWalls:FlxTypedGroup<flixel.FlxObject>;


	/** Boss down: moor the boat on a water tile of the boss room, on a side
	 * with no door, and carve that tile so the player can step aboard. */
	function dockBoat():Void
	{
		var node = controller.active;
		var room = controller.roomOf(node);
		var side = if (node.doors & world.FloorMap.S == 0) world.FloorMap.S
			else if (node.doors & world.FloorMap.N == 0) world.FloorMap.N
			else if (node.doors & world.FloorMap.E == 0) world.FloorMap.E
			else world.FloorMap.W;
		var cx = 7, cy = 4;
		switch (side)
		{
			case world.FloorMap.S: cy = ROOM_TH - 1;
			case world.FloorMap.N: cy = 0;
			case world.FloorMap.E: cx = ROOM_TW - 1;
			default: cx = 0;
		}
		// into or out of the caves: a cave mouth on the grass just inside that side
		var toLevel = RunState.floor + 1 >= RunState.levels[RunState.level].floors ? RunState.level + 1 : RunState.level;
		if (world.LevelDefs.caveTransition(RunState.level, toLevel))
		{
			var gx = cx, gy = cy;
			switch (side)
			{
				case world.FloorMap.S: gy = ROOM_TH - 2;
				case world.FloorMap.N: gy = 1;
				case world.FloorMap.E: gx = ROOM_TW - 2;
				default: gx = 1;
			}
			caveMouth = new entities.CaveMouth();
			caveMouth.rise(room, gx, gy);
			insert(members.indexOf(pedestals), caveMouth);
			return;
		}
		room.carve(cx, cy);
		boat = new entities.Boat();
		boat.dock(room, cx, cy, side);
		insert(members.indexOf(pedestals), boat); // under the actors, over the water
	}

	function startSail():Void
	{
		if (sailing)
			return;
		sailing = true;
		player.inputLocked = true;
		player.velocity.set(0, 0);
		RunState.save(player);
		var wasLevel = RunState.level;
		RunState.advance();
		var newLevel = RunState.level != wasLevel;
		var toRaft = newLevel && !RunState.raftUsed && !RunState.caveWalk && !RunState.isLastFloor();
		FlxG.camera.fade(flixel.util.FlxColor.BLACK, 0.6, false, () -> FlxG.switchState(() -> toRaft ? new RaftState() : new SailState()));
	}

	function spawnBoss():Void
	{
		var node = controller.active;
		var room = controller.roomOf(node);
		var bx = room.worldX + room.pxW / 2;
		var by = room.worldY + room.pxH / 2 - 40;
		for (s in room.template.spawns)
			if (s.kind == "BossSpawn")
			{
				bx = room.worldX + s.cx * TILE;
				by = room.worldY + s.cy * TILE;
			}
		fx.Sfx.music("foggy_shores", 0.5);
		boss = world.LevelDefs.spawnBoss(bx, by);
		boss.init(player);
		boss.summonHost = enemies;
		enemies.add(boss);
		hud.setBoss(boss);
		// intro card: freeze everything but the card until it leaves
		bossIntro = true;
		player.inputLocked = true;
		player.velocity.set(0, 0);
		bossCard.show(RunState.currentBoss, () ->
		{
			bossIntro = false;
			player.inputLocked = false;
		});
	}

	var paused:Bool = false;
	var pauseUI:flixel.group.FlxSpriteGroup;
	var pauseStats:Array<flixel.text.FlxText> = [];
	var pauseItems:Array<{btn:flixel.ui.FlxButton, cb:Void->Void}> = [];
	var pauseStuffIcons:Array<flixel.FlxSprite> = [];
	var pauseSel:Int = 0;
	var pausePointer:flixel.FlxSprite;
	var runSeed:Int = 0;

	function togglePause():Void
	{
		paused = !paused;
		if (pauseUI == null)
			buildPauseUI();
		if (paused)
			refreshPauseStats();
		pauseUI.visible = paused;
		// members of an invisible group still update; freeze them too
		pauseUI.active = paused;
	}

	function buildPauseUI():Void
	{
		pauseUI = new flixel.group.FlxSpriteGroup();
		pauseUI.scrollFactor.set(0, 0);

		var dim = new flixel.FlxSprite();
		dim.makeGraphic(FlxG.width, FlxG.height, flixel.util.FlxColor.fromRGBFloat(0, 0, 0, 0.55));
		pauseUI.add(dim);

		// Isaac-style parchment: title, stat readout, menu
		var panel = new flixel.FlxSprite(250, 60, "assets/images/ui/paper_panel.png");
		pauseUI.add(panel);

		var ink = flixel.util.FlxColor.fromRGB(74, 56, 38);
		var title = new flixel.text.FlxText(250, 92, 460, "PAUSED");
		title.setFormat(null, 34, ink, CENTER);
		pauseUI.add(title);

		var icons = [
			"assets/images/ui/icon_sword.png", // damage
			"assets/images/fx/fire.png", // fire rate
			"assets/images/fx/arrow.png", // range
			"assets/images/vfx/cloud_01.png", // speed
			"assets/images/props/deco_02.png", // luck
		];
		pauseStats = [];
		for (i in 0...icons.length)
		{
			var icon = new flixel.FlxSprite();
			if (icons[i].indexOf("fire") >= 0 || icons[i].indexOf("arrow") >= 0)
			{
				icon.loadGraphic(icons[i], true, 64, 64);
				icon.animation.frameIndex = 0;
			}
			else
				icon.loadGraphic(icons[i]);
			var s = 26 / icon.frameHeight;
			icon.scale.set(s, s);
			icon.updateHitbox();
			icon.setPosition(360 + (26 - icon.width) / 2, 152 + i * 36);
			pauseUI.add(icon);
			var t = new flixel.text.FlxText(410, 156 + i * 36, 160, "", 15);
			t.setFormat(null, 15, ink, LEFT);
			pauseUI.add(t);
			pauseStats.push(t);
		}

		// tilted side-sheet with the run seed, Isaac style
		var seedSheet = new flixel.FlxSprite(30, 130, "assets/images/ui/paper_small.png");
		seedSheet.angle = -5;
		pauseUI.add(seedSheet);
		var floorText = new flixel.text.FlxText(30, 148, 250, RunState.floorName());
		floorText.setFormat(null, 16, ink, CENTER);
		floorText.angle = -5;
		pauseUI.add(floorText);
		var seedText = new flixel.text.FlxText(30, 182, 250, '$runSeed');
		seedText.setFormat(null, 26, ink, CENTER);
		seedText.angle = -5;
		pauseUI.add(seedText);

		// "my stuff" sheet: consumables at a glance
		var stuffSheet = new flixel.FlxSprite(26, 300, "assets/images/ui/paper_stuff.png");
		stuffSheet.angle = 3;
		pauseUI.add(stuffSheet);
		var stuffTitle = new flixel.text.FlxText(26, 320, 250, "MY STUFF");
		stuffTitle.setFormat(null, 20, ink, CENTER);
		stuffTitle.angle = 3;
		pauseUI.add(stuffTitle);
		// items the player picks up render here as an icon grid (empty for now)

		// menu entries written in the same ink as the title
		pauseItems = [];
		inline function inkItem(y:Float, label:String, cb:Void->Void):Void
		{
			var idx = pauseItems.length;
			var b = new flixel.ui.FlxButton(300, y, "", cb);
			b.makeGraphic(360, 46, flixel.util.FlxColor.TRANSPARENT);
			b.label = new flixel.text.FlxText(0, 0, 360, label);
			b.label.setFormat(null, 26, ink, CENTER);
			for (o in b.labelOffsets)
				o.set(0, 8);
			b.onOver.callback = () -> pauseSel = idx;
			pauseUI.add(b);
			pauseItems.push({btn: b, cb: cb});
		}
		inkItem(360, "RESUME GAME", togglePause);
		inkItem(420, "EXIT GAME", () -> FlxG.switchState(() -> new MenuState()));

		// selection pointer: the pack arrow, inked
		pausePointer = new flixel.FlxSprite();
		pausePointer.loadGraphic("assets/images/fx/arrow.png", true, 64, 64);
		pausePointer.animation.frameIndex = 0;
		pausePointer.scale.set(0.55, 0.55);
		pausePointer.updateHitbox();
		pausePointer.color = ink;
		pauseUI.add(pausePointer);
		add(pauseUI);
	}

	function refreshPauseStats():Void
	{
		inline function fmt(v:Float):String
			return Std.string(Math.round(v * 10) / 10);
		pauseStats[0].text = fmt(player.damage);
		pauseStats[1].text = fmt(1 / player.fireCooldown) + "/s";
		pauseStats[2].text = Std.string(Std.int(player.arrowRange));
		pauseStats[3].text = Std.string(Std.int(player.speed));
		pauseStats[4].text = fmt(player.luck);

		// rebuild the MY STUFF item grid from what the player has collected
		for (s in pauseStuffIcons)
		{
			pauseUI.remove(s, true);
			s.destroy();
		}
		pauseStuffIcons = [];
		for (i in 0...player.items.length)
		{
			var icon = new flixel.FlxSprite();
			icon.loadGraphic(player.items[i]);
			var s = 30 / icon.frameHeight;
			icon.scale.set(s, s);
			icon.updateHitbox();
			icon.setPosition(78 + (i % 4) * 40, 360 + Std.int(i / 4) * 40);
			icon.angle = 3; // match the sheet's tilt
			pauseUI.add(icon);
			pauseStuffIcons.push(icon);
		}
	}

	override public function update(elapsed:Float):Void
	{
		if (!paused && !gameOverStarted)
			RunState.timeSec += elapsed;
		if (Input.pause && !ui.DevConsole.open)
			togglePause();
		// hold TAB or M for the floor map
		var wantMap = (Input.map || mapHeld) && !ui.DevConsole.open && !paused;
		if (wantMap && !floorMap.visible)
			floorMap.refresh(controller.active, player);
		floorMap.visible = wantMap;
		if (paused)
		{
			pauseUI.update(elapsed); // keep the buttons clickable
			var n = pauseItems.length;
			if (Input.menuUp)
				pauseSel = (pauseSel + n - 1) % n;
			if (Input.menuDown)
				pauseSel = (pauseSel + 1) % n;
			var b = pauseItems[pauseSel].btn;
			pausePointer.setPosition(b.x + 30, b.y + 8);
			if (Input.confirm)
				pauseItems[pauseSel].cb();
			return;
		}

		if (bossIntro)
		{
			bossCard.update(elapsed);
			hud.update(elapsed);
			sortWorld();
			return;
		}
		#if debug
		try
		{
			super.update(elapsed);
		}
		catch (e:Dynamic)
		{
			trace('UPDATE ERR: $e\n${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
			return;
		}
		#else
		super.update(elapsed);
		#end

		fx.LightManager.setLight(0, player.x + player.width / 2, player.y + player.height / 2, 220);
		fx.LightManager.update(elapsed);
		sortWorld();

		// hp check, not alive: leaving the boss room despawns (kills) the boss,
		// which must not count as a victory
		if (boss != null && boss.hp <= 0 && !won && !gameOverStarted)
		{
			won = true;
			// the boss leaves its level's boss item on a pedestal (a pool item once you own it)
			var drop = items.ItemPool.bossDrop(world.LevelDefs.id(), player);
			var spot = controller.snapToGrass(boss.x + boss.width / 2, boss.y + boss.height / 2);
			if (drop != null)
			{
				var ped = new entities.ItemPedestal(spot.x - 32, spot.y - 32, drop);
				pedestals.add(ped);
				fx.PackFx.play("sparkle", spot.x, spot.y - 20, 1.2);
			}
			else
			{
				// the pool ran dry late in a long run: meat and a purse instead
				pickups.add(new Pickup(spot.x - 16, spot.y - 16, Meat));
				if (entities.Prop.coins != null)
					for (i in 0...Math.round(6 * player.goldBonus))
						entities.Prop.coins.recycle(entities.Coin.new).drop(spot.x, spot.y);
			}
			// last floor of a level: permanent progress + hero unlock toast
			var fresh = Unlocks.onBossBeaten(RunState.currentBoss);
			if (RunState.floor == RunState.levels[RunState.level].floors - 1)
				fresh = fresh.concat(Unlocks.onLevelBeaten(world.LevelDefs.id()));
			for (hero in fresh)
			{
				fx.Sfx.play("fanfare", 0.9);
				itemCard.show({
					id: "unlock", name: hero + " unlocked", caption: "new hero on the select screen",
					icon: 'assets/images/ui/avatar_${hero.toLowerCase()}.png',
					apply: _ -> {}
				});
			}
			if (RunState.isLastFloor())
			{
				gameOverStarted = true;
				RunState.clearSaved();
				flixel.util.FlxTimer.wait(1.2, () -> FlxG.switchState(() -> new GameOverState(true)));
			}
			else
				flixel.util.FlxTimer.wait(1.0, dockBoat);
		}
		if (boat != null && !sailing && boat.alive && FlxG.overlap(player, boat))
			startSail();
		if (caveMouth != null && !sailing && caveMouth.alpha >= 1 && FlxG.overlap(player, caveMouth))
			startSail();
		if (darkness != null)
			darkness.setPosition(player.x + player.width / 2 - 960, player.y + player.height / 2 - 640);
		FlxG.overlap(player, groundShots, (p:Player, sh:entities.EnemyShot) ->
		{
			if (sh.alive && !(p.trollSkin && sh.kind == "fire"))
				p.hurt2(sh.damage, sh); // burning ground: hurts, but the hazard stays
		});
		FlxG.overlap(player, enemyShots, (p:Player, sh:entities.EnemyShot) ->
		{
			if (!sh.alive)
				return;
			if (sh.kind == "hex")
			{
				if (p.hurt2(0, sh) || true)
					p.becomeSheep(4.0);
			}
			else if (sh.kind == "harpoon")
			{
				if (p.hurt2(sh.damage, sh))
					p.shove(0, 0, 0.5); // pinned for half a second
			}
			else if (!(p.trollSkin && sh.kind == "fire"))
				p.hurt2(sh.damage, sh);
			sh.kill();
		});

		var activeRoom = controller.active != null ? controller.roomOf(controller.active) : null;
		if (tierWalls != null)
		{
			// one-way cliff: only bodies below the edge are stopped by it
			var oneWay = (o:flixel.FlxObject, w:flixel.FlxObject) -> !(Std.isOfType(o, Enemy) && cast(o, Enemy).flying)
				&& (o.y + o.height > w.y + w.height - 6) && flixel.FlxObject.separate(o, w);
			FlxG.overlap(player, tierWalls, null, oneWay);
			FlxG.overlap(enemies, tierWalls, null, oneWay);
		}
		if (activeRoom != null && !controller.transitioning)
		{
			FlxG.collide(player, player.waterWalker ? activeRoom.pitMap : activeRoom.collisionMap);
			FlxG.collide(player, solidProps);
			FlxG.collide(coins, activeRoom.collisionMap); // scattering coins stay on the island
			FlxG.collide(player, campfires);
			// a burning campfire hurts to touch: check a slightly grown box so brushing the
			// flames counts even though the solid collision keeps the bodies apart
			campfires.forEachAlive(c ->
			{
				if (c.hitsLeft <= 0)
					return;
				if (!player.trollSkin && player.x < c.x + c.width + 6 && player.x + player.width > c.x - 6
					&& player.y < c.y + c.height + 6 && player.y + player.height > c.y - 6)
					player.hurt2(1, c);
				// enemies that brush the flames catch fire too
				enemies.forEachAlive(e ->
				{
					if (e.x < c.x + c.width + 6 && e.x + e.width > c.x - 6 && e.y < c.y + c.height + 6 && e.y + e.height > c.y - 6)
						e.ignite();
				});
			});
			// flyers pass over water, props and fires; walkers are blocked by them
			var walkers = (e:flixel.FlxObject, o:flixel.FlxObject) -> !cast(e, Enemy).flying && flixel.FlxObject.separate(e, o);
			FlxG.overlap(enemies, activeRoom.collisionMap, null, walkers);
			FlxG.overlap(enemies, solidProps, null, walkers);
			FlxG.overlap(enemies, campfires, null, walkers);
		}

		// arrows fly THROUGH campfires: a burning one lights the arrow
		// (each ignition costs the fire one of its 3 charges)
		// the fire's collision box is just the logs; arrows count as hitting it
		// anywhere in the flames (the arrow graphic rides 32 px above its hitbox)
		playerShots.forEachAlive(a ->
		{
			var ax = a.x + a.width / 2, ay = a.y + a.height / 2 - 32;
			campfires.forEachAlive(c ->
			{
				if (a.hitFire || c.hitsLeft <= 0)
					return;
				if (ax > c.x - 10 && ax < c.x + c.width + 10 && ay > c.y - 72 && ay < c.y + c.height + 4)
					if (c.takeHit())
					{
						a.hitFire = true;
						if (!a.flaming) // Goblin Torch arrows are already lit; they still chop the fire
						{
							a.ignite();
							fx.Sfx.play("torch", 0.6);
						}
					}
			});
		});
		FlxG.overlap(meleeSwings, campfires, (s:entities.MeleeSwing, c:entities.Campfire) ->
		{
			if (!s.hasHit(c))
			{
				s.markHit(c);
				c.takeHit();
			}
		});
		FlxG.overlap(explosions, campfires, (ex:Explosion, c:entities.Campfire) ->
		{
			if (ex.damaging)
				c.takeHit(3); // a blast snuffs it outright
		});

		FlxG.overlap(playerShots, solidProps, (a:Arrow, p:entities.Prop) ->
		{
			if (p.hitByArrow())
				a.kill();
		});
		FlxG.overlap(meleeSwings, enemies, (s:entities.MeleeSwing, e:Enemy) ->
		{
			if (!s.hasHit(e) && e.hittable())
			{
				s.markHit(e);
				if (player.burnHits)
					e.ignite();
				e.takeHit(s.damage, player);
				if (player.bearClaw)
					e.velocity.scale(2); // Bear Claw: double knockback
				if (player.harpoon)
					e.pullToward(player.x + player.width / 2, player.y + player.height / 2);
				maybeHex(e);
			}
		});
		FlxG.overlap(meleeSwings, solidProps, (s:entities.MeleeSwing, p:entities.Prop) ->
		{
			if (!s.hasHit(p))
			{
				s.markHit(p);
				p.hitByArrow(); // bushes chop, rocks shrug
			}
		});

		if (dummy != null)
		{
			FlxG.collide(player, dummy);
			FlxG.overlap(playerShots, dummy, (a:Arrow, d:entities.TrainingDummy) ->
			{
				if (a.flaming)
					d.ignite();
				d.takeHit(a.damage, a);
				a.kill();
			});
			FlxG.overlap(meleeSwings, dummy, (s:entities.MeleeSwing, d:entities.TrainingDummy) ->
			{
				if (!s.hasHit(d))
				{
					s.markHit(d);
					d.takeHit(s.damage, player);
				}
			});
			FlxG.overlap(explosions, dummy, (ex:Explosion, d:entities.TrainingDummy) ->
			{
				if (ex.damaging)
					d.takeHit(1, ex);
			});
		}
		FlxG.overlap(explosions, solidProps, (ex:Explosion, p:entities.Prop) ->
		{
			if (ex.damaging && !ex.hasHit(p))
			{
				ex.markHit(p);
				p.hitByExplosion();
			}
		});
		FlxG.overlap(player, coins, (pl:Player, c:entities.Coin) ->
		{
			pl.gold++;
			c.kill();
		});
		FlxG.overlap(player, shopItems, (pl:Player, si:entities.ShopItem) ->
		{
			if (!si.alive)
				return;
			si.shopper = pl;
			var def = si.itemDef;
			if (si.tryBuy(pl))
			{
				fx.PackFx.play("coin_burst", si.x + si.width / 2, si.y + si.height / 2, 1, 15, 0);
				if (def != null)
					itemCard.show(def);
			}
		});
		FlxG.overlap(player, pedestals, (pl:Player, pd:entities.ItemPedestal) ->
		{
			if (!pd.alive)
				return;
			items.ItemPool.give(pl, pd.def);
			itemCard.show(pd.def);
			fx.PackFx.play("sparkle", pd.x + pd.width / 2, pd.y - 10, 1.6);
			pd.kill();
		});

		FlxG.overlap(playerShots, enemies, (a:Arrow, e:Enemy) ->
		{
			if (!e.hittable())
				return; // submerged: the arrow flies on over the water
			if (a.flaming)
				e.ignite();
			e.takeHit(a.damage, a);
			if (player.harpoon)
				e.pullToward(player.x + player.width / 2, player.y + player.height / 2);
			maybeHex(e);
			a.kill();
		});
		FlxG.overlap(player, enemies, (p:Player, e:Enemy) ->
		{
			if (p.charging)
			{
				// Minotaur Horns: the charge bowls through enemies, each hit once
				if (p.chargeHits.indexOf(e) < 0)
				{
					p.chargeHits.push(e);
					e.takeHit(p.chargeDamage, p);
					e.velocity.scale(1.6);
					maybeHex(e);
				}
				return;
			}
			if (e.touchDamage <= 0)
				return;
			if (!p.hurt2(e.touchDamage, e) && p.lastDeflected)
				e.onDeflected(p);
		});
		FlxG.overlap(player, explosions, (p:Player, ex:Explosion) ->
		{
			if (ex.damaging && !p.trollSkin) // Troll Skin: blasts do 1 less, i.e. nothing
				p.hurt2(1, ex);
		});
		FlxG.overlap(enemies, explosions, (e:Enemy, ex:Explosion) ->
		{
			if (ex.damaging && !ex.hasHit(e) && e.hittable())
			{
				ex.markHit(e);
				e.takeHit(3, ex); // one blast = 3 damage, once
				if (Std.isOfType(e, entities.Snake))
					cast(e, entities.Snake).stun(2.0);
			}
		});
		FlxG.overlap(player, pickups, (p:Player, pk:Pickup) ->
		{
			switch (pk.type)
			{
				case Meat:
					if (p.hp < p.maxHp)
					{
						p.hp = Std.int(Math.min(p.maxHp, p.hp + 2));
						fx.PackFx.play("heal", p.x + p.width / 2, p.y + p.height / 2 - 20);
						pk.kill();
					}
				case Gold:
					pk.kill();
				case Bomb:
					p.bombs++;
					pk.kill();
				case Key:
					p.keys++;
					pk.kill();
			}
		});

		controller.refreshLocks();
		controller.leanOnWalls(elapsed);
		controller.checkTransition();
		updateMasks();
		hud.setCurrentRoom(controller.active);

		volumeKeys();
		if (player.revived)
		{
			player.revived = false;
			itemCard.show({id: "second_wind", name: "Second Wind", caption: "back on your feet", icon: "assets/images/items/second_wind.png", apply: _ -> {}});
		}
		if (player.activeId == "lucky_coin" && !ui.DevConsole.open)
		{
			// hint once per room that has an untaken pedestal while the coin is charged
			if (player.activeReady("lucky_coin") && rerollHintNode != controller.active && roomPedestal() != null)
			{
				rerollHintNode = controller.active;
				itemCard.show({id: "lucky_coin", name: "Lucky Coin", caption: "press SPACE to reroll the item", icon: "assets/images/items/lucky_coin.png", apply: _ -> {}});
			}
			if (Input.active && (!player.activeReady("lucky_coin") || !rerollPedestal()))
				fx.Sfx.play("deny", 0.4);
		}
		if (!player.alive && !gameOverStarted)
		{
			gameOverStarted = true;
			RunState.clearSaved();
			flixel.util.FlxTimer.wait(0.8, () -> FlxG.switchState(() -> new GameOverState(false)));
		}

		#if html5
		// Headless-verification hook: ?autofire makes the archer shoot right.
		if (js.Browser.location.search.indexOf("autofire") >= 0)
			if (player.weapon.tryFire(player, 1, 0))
				@:privateAccess player.playShootAnim(1, 0);

		debugClock += elapsed;
		if (debugClock >= 1 && js.Browser.location.search.indexOf("debuglog") >= 0)
		{
			debugClock = 0;
			trace('t=${Math.round(FlxG.game.ticks / 1000)}s room=${controller.active != null ? '${controller.active.gx},${controller.active.gy} ${controller.active.templateId} cleared=${controller.active.cleared}' : "?"} p=(${Math.round(player.x)},${Math.round(player.y)}) enemies=${enemies.countLiving()} playerHp=${player.hp}${boss != null ? ' bossHp=${boss.hp}' : ""}');
		}
		#end
	}

	var debugClock:Float = 0;
}
