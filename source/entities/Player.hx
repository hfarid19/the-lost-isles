package entities;

import Constants.*;
import combat.Bow;
import combat.MeleeWeapon;
import combat.Weapon;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

enum PlayerKind
{
	Archer;
	Knight;
	Lancer;
	Monk;
	Panda;
}

class Player extends FlxSprite
{
	/** Chosen on the character select screen; persists across restarts. */
	public static var selectedKind:PlayerKind = Archer;

	/** Dev-console/URL toggle: player takes no damage. */
	public static var godMode:Bool = false;

	/** Dev-console toggle: hold the shield up without the key (Knight). */
	public static var debugBlock:Bool = false;

	public var kind(default, null):PlayerKind;
	public var hp:Int = PLAYER_MAX_HP;
	public var maxHp:Int = PLAYER_MAX_HP;
	public var weapon:Weapon;
	public var inputLocked:Bool = false;
	public var gold:Int = 0;
	public var bombs:Int = 1;
	public var keys:Int = 0;

	/** Passive items picked up this run (icon asset paths, shown on MY STUFF). */
	public var items:Array<String> = [];
	public var itemIds:Array<String> = [];

	/** Monk: room cleared -> heal half a heart with the heal animation and its glow. */
	public function monkHeal():Void
	{
		if (kind != Monk || !alive)
			return;
		if (hp < maxHp)
			hp++;
		animation.play("heal", true);
		var glow = new FlxSprite(x - 74, y - 128);
		glow.loadGraphic("assets/images/fx/heal_effect.png", true, 192, 192);
		glow.animation.add("go", [for (i in 0...11) i], 14, false);
		glow.animation.onFinish.add(_ -> glow.kill());
		glow.animation.play("go");
		FlxG.state.add(glow);
		fx.PackFx.play("heal", x + width / 2, y + height / 2 - 20);
		fx.Sfx.play("item", 0.5);
	}

	/** Knight only: holding SHIFT raises the shield — slow, can't attack,
	 * and immune only to damage arriving from the blocked direction.
	 * Attack inputs re-aim the shield while it's up. */
	public var blocking(default, null):Bool = false;

	/** Set by hurt2: the last hit was turned away by the shield. */
	public var lastDeflected(default, null):Bool = false;

	var blockDirX:Float = 1;
	var blockDirY:Float = 0;
	var aimInX:Float = 0;
	var aimInY:Float = 0;

	// modifiable stats (items will change these later)
	public var damage:Float = 1;
	public var fireCooldown:Float = BOW_COOLDOWN;
	public var arrowRange:Float = 360;
	public var speed:Float = PLAYER_SPEED;
	public var luck:Float = 0;

	/** Goblin Torch item: every hit ignites the enemy. */
	public var burnHits:Bool = false;
	// run items (see items/ItemPool)
	public var twinShot:Bool = false; // Twin Shot
	public var waterWalker:Bool = false; // Water Walker
	public var secondWind:Int = 0; // Second Wind: revives left
	public var goldBonus:Float = 1; // Gold Nose
	public var shopDiscount:Float = 1; // Merchant's Ledger
	public var campfireHeart:Bool = false; // Campfire Heart
	// active item (R): id, charge in room clears, clears needed for a full charge
	public var activeId:String = null;
	public var activeCharge:Int = 0;
	public var activeMax:Int = 0;
	public var bearClaw:Bool = false; // Bear Claw
	public var trollSkin:Bool = false; // Troll Skin
	public var harpoon:Bool = false; // Harpoon
	public var horns:Bool = false; // Minotaur Horns
	public var sheepHex:Bool = false; // Shaman Charm: 10 % of hits turn an enemy into a sheep
	public var blackCrown:Bool = false; // Black Crown: Troy's black units only land every other hit
	var crownTick:Bool = false;
	public var chargeDamage:Int = 3; // horns charge 3, panda roll 1
	var rollCooldown:Float = 0;
	public function activeReady(id:String):Bool
		return activeId == id && activeCharge >= activeMax;

	/** A room clear adds one charge to the active item. */
	public function chargeActive():Void
	{
		if (activeId != null && activeCharge < activeMax)
			activeCharge++;
	}

	/** Set for a frame when Second Wind fires, so the state can show the card. */
	public var revived:Bool = false;
	/** Minotaur Horns: pushing into a wall for 1 s launches a charge away from it. */
	public var charging(default, null):Bool = false;
	public var chargeHits:Array<Enemy> = [];
	var wallTimer:Float = 0;
	var chargeTimer:Float = 0;
	var chargeDirX:Float = 0;
	var chargeDirY:Float = 0;

	/** Hex Shaman's sheep hex: slow, drunk, and unable to attack for a few seconds. */
	public var sheepTimer(default, null):Float = 0;

	var sheep:FlxSprite;
	var drunkTimer:Float = 0;
	var drunkAngle:Float = 0;

	public function becomeSheep(seconds:Float):Void
	{
		if (!alive)
			return;
		sheepTimer = seconds;
		fx.Sfx.play("hex", 0.8);
		fx.Sfx.play("sheep", 0.6);
		if (sheep == null)
		{
			// HappySheep_Bouncing: 6 frames @128, body x43-86, feet at y86
			sheep = new FlxSprite();
			sheep.loadGraphic("assets/images/chars/sheep_bounce.png", true, 128, 128);
			sheep.animation.add("bounce", [for (i in 0...6) i], 10);
			sheep.animation.play("bounce");
		}
		fx.PackFx.play("smoke", x + width / 2, y + height / 2, 1.2);
	}

	var iframes:Float = 0;
	var shoveTimer:Float = 0;
	var stepTimer:Float = 0;

	/** A footstep every ~0.28 s while running: the level's surface, or wood on a
	 * bridge tile, with the Knight's armour clinking on top. */
	function footsteps(elapsed:Float):Void
	{
		if (velocity.x == 0 && velocity.y == 0)
		{
			stepTimer = 0.05;
			return;
		}
		stepTimer -= elapsed;
		if (stepTimer > 0)
			return;
		stepTimer = 0.28 * (Constants.PLAYER_SPEED / Math.max(200, speed));
		var onBridge = false;
		for (d in world.RoomController.allDoors)
			if (!d.locked && Math.abs(x + width / 2 - (d.room.worldX + d.cx * Constants.TILE + 32)) < 40
				&& Math.abs(y + height - (d.room.worldY + d.cy * Constants.TILE + 40)) < 40)
				onBridge = true;
		fx.Sfx.play(onBridge ? "step_wood" : world.LevelDefs.stepSound(), 0.35, 0.12, 0.1);
		if (kind == Knight)
			fx.Sfx.play("step_chain", 0.18, 0.12, 0.1);
	}

	/** Knockback that survives the movement code for `seconds`. */
	public function shove(vx:Float, vy:Float, seconds:Float = 0.2):Void
	{
		velocity.set(vx, vy);
		shoveTimer = seconds;
	}
	var lastAimX:Float = 1;
	var lastAimY:Float = 0;
	var moveDirX:Float = 0;
	var moveDirY:Float = 0;

	var swingAlt:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		kind = selectedKind;
		if (kind == Archer)
		{
			// archer_blue.png: 8x7 grid @192
			// row 0 idle(6f), row 1 run(6f), rows 2-6 shoot: up/updiag/side/downdiag/down (8f)
			loadGraphic("assets/images/chars/archer_blue.png", true, 192, 192);
			animation.add("idle", [for (i in 0...6) i], 10);
			animation.add("run", [for (i in 8...14) i], 10);
			animation.add("shoot_up", [for (i in 16...24) i], 20, false);
			animation.add("shoot_updiag", [for (i in 24...32) i], 20, false);
			animation.add("shoot_side", [for (i in 32...40) i], 20, false);
			animation.add("shoot_downdiag", [for (i in 40...48) i], 20, false);
			animation.add("shoot_down", [for (i in 48...56) i], 20, false);
			weapon = new Bow();
		}
		else if (kind == Knight)
		{
			// warrior_full.png: 6x9 grid @192
			// rows: idle, run, side1, side2, down1, down2, up1, up2, guard (6f each)
			loadGraphic("assets/images/chars/warrior_full.png", true, 192, 192);
			animation.add("idle", [for (i in 0...6) i], 10);
			animation.add("run", [for (i in 6...12) i], 10);
			animation.add("atk_side", [for (i in 12...18) i], 18, false);
			animation.add("atk_side2", [for (i in 18...24) i], 18, false);
			animation.add("atk_down", [for (i in 24...30) i], 18, false);
			animation.add("atk_up", [for (i in 36...42) i], 18, false);
			animation.add("guard", [for (i in 48...54) i], 10);
			weapon = new MeleeWeapon();
			damage = 2;
			fireCooldown = 0.45;
			arrowRange = 80; // melee reach
			speed = 370;
		}
		else if (kind == Panda)
		{
			// panda_hero.png: 13x3 grid @256 — idle(10), run(6), attack(13)
			loadGraphic("assets/images/chars/panda_hero.png", true, 256, 256);
			animation.add("idle", [for (i in 0...10) i], 10);
			animation.add("run", [for (i in 13...19) i], 12);
			animation.add("atk_side", [for (i in 26...39) i], 26, false);
			weapon = new combat.PawWeapon();
			damage = 3;
			fireCooldown = 0.7;
			arrowRange = 70;
			speed = 300;
			maxHp = 10;
			hp = 10;
		}
		else if (kind == Monk)
		{
			// monk_blue.png: 11x3 grid @192 — idle(6), run(4), heal(11); the first
			// heal frames double as a quick palm strike
			loadGraphic("assets/images/chars/monk_blue.png", true, 192, 192);
			animation.add("idle", [for (i in 0...6) i], 10);
			animation.add("run", [for (i in 11...15) i], 12);
			animation.add("atk_side", [22, 23, 24, 25], 22, false);
			animation.add("heal", [for (i in 22...33) i], 14, false);
			weapon = new combat.FistWeapon();
			damage = 1;
			fireCooldown = 0.28;
			arrowRange = 60;
			speed = 360;
			maxHp = 8;
			hp = 8;
		}
		animation.play("idle");

		if (kind == Lancer)
		{
			// lancer_blue.png: 12x7 @320 — idle(12), run(6), then 3f thrusts:
			// down, downright, right, upright, up
			loadGraphic("assets/images/chars/lancer_blue.png", true, 320, 320);
			animation.add("idle", [for (i in 0...12) i], 10);
			animation.add("run", [for (i in 12...18) i], 10);
			animation.add("atk_down", [24, 25, 26], 14, false);
			animation.add("atk_downright", [36, 37, 38], 14, false);
			animation.add("atk_right", [48, 49, 50], 14, false);
			animation.add("atk_upright", [60, 61, 62], 14, false);
			animation.add("atk_up", [72, 73, 74], 14, false);
			animation.play("idle");
			weapon = new combat.SpearWeapon();
			damage = 2;
			fireCooldown = 0.55;
			arrowRange = 130; // spear reach
			speed = 340;
			setSize(44, 32);
			offset.set(127, 165);
			return;
		}

		if (kind == Panda)
		{
			setSize(56, 32);
			offset.set(97, 140);
			return;
		}
		setSize(44, 32);
		offset.set(74, 128);
	}

	/** Panda: Shift / LB rolls forward for a moment, untouchable, bowling small enemies over. */
	function tryRoll():Void
	{
		if (rollCooldown > 0 || charging)
			return;
		var mx = Input.moveX, my = Input.moveY;
		if (mx == 0 && my == 0)
		{
			mx = flipX ? -1 : 1;
			my = 0;
		}
		var len = Math.max(1e-6, Math.sqrt(mx * mx + my * my));
		chargeDirX = mx / len;
		chargeDirY = my / len;
		chargeTimer = 0.35;
		charging = true;
		chargeDamage = 1;
		chargeHits = [];
		rollCooldown = 0.9;
		flipX = chargeDirX < 0;
		fx.Sfx.play("swipe", 0.5, 0.2);
		fx.PackFx.play("smoke", x + width / 2, y + height, 0.8);
	}

	override public function update(elapsed:Float):Void
	{
		if (iframes > 0)
			iframes -= elapsed;
		if (rollCooldown > 0)
			rollCooldown -= elapsed;
		if (kind == Panda && chargeTimer > 0)
		{
			// mid-roll: reuse the horns charge motion at roll speed
			chargeTimer -= elapsed;
			velocity.set(chargeDirX * 620, chargeDirY * 620);
			if (chargeTimer <= 0)
			{
				charging = false;
				velocity.set(0, 0);
			}
			weapon.update(elapsed);
			super.update(elapsed);
			return;
		}
		if (kind == Panda && Input.block && !inputLocked && !ui.DevConsole.open)
			tryRoll();
		weapon.update(elapsed);
		if (sheepTimer > 0)
		{
			sheepTimer -= elapsed;
			if (sheepTimer <= 0)
				fx.PackFx.play("smoke", x + width / 2, y + height / 2, 1.2);
			if (!inputLocked && !ui.DevConsole.open)
				move();
			else
				velocity.set(0, 0);
			sheep.update(elapsed);
			super.update(elapsed);
			return;
		}

		var wasBlocking = blocking;
		blocking = kind == Knight && (Input.block || debugBlock) && !inputLocked && !ui.DevConsole.open;
		if (blocking && !wasBlocking)
		{
			// shield starts toward the last aim (or current facing)
			var len = Math.sqrt(lastAimX * lastAimX + lastAimY * lastAimY);
			if (len > 0)
			{
				blockDirX = lastAimX / len;
				blockDirY = lastAimY / len;
			}
			else
			{
				blockDirX = flipX ? -1 : 1;
				blockDirY = 0;
			}
		}

		if (!inputLocked && !ui.DevConsole.open)
		{
			move();
			footsteps(elapsed);
			if (horns)
				updateHorns(elapsed);
			if (blocking)
			{
				// attack inputs steer the shield instead of attacking
				if (readAimInput())
				{
					var len = Math.max(1e-6, Math.sqrt(aimInX * aimInX + aimInY * aimInY));
					blockDirX = aimInX / len;
					blockDirY = aimInY / len;
					lastAimX = blockDirX;
					lastAimY = blockDirY;
				}
				if (blockDirX != 0)
					flipX = blockDirX < 0;
				animation.play("guard");
			}
			else
			{
				aimAndFire();
				if (Input.bomb)
					throwBomb();
			}
		}
		else
			velocity.set(0, 0);

		super.update(elapsed);
	}

	var elapsed:Float = 0;

	/** Minotaur Horns: lean into a wall for a second, then charge away from it through anything in the way. */
	function updateHorns(dt:Float):Void
	{
		if (chargeTimer > 0)
		{
			chargeTimer -= dt;
			velocity.set(chargeDirX * 720, chargeDirY * 720);
			if (Std.int(chargeTimer * 20) != Std.int((chargeTimer + dt) * 20))
				fx.PackFx.play("smoke", x + width / 2 - chargeDirX * 20, y + height - 8, 0.6);
			if (chargeTimer <= 0)
			{
				charging = false;
				velocity.set(0, 0);
			}
			return;
		}
		var dx = Input.moveX > 0.3 ? 1 : (Input.moveX < -0.3 ? -1 : 0);
		var dy = Input.moveY > 0.3 ? 1 : (Input.moveY < -0.3 ? -1 : 0);
		// wasTouching holds last frame's wall contacts
		var pushing = (dx > 0 && wasTouching.has(RIGHT)) || (dx < 0 && wasTouching.has(LEFT)) || (dy > 0 && wasTouching.has(DOWN))
			|| (dy < 0 && wasTouching.has(UP));
		if (!pushing || shoveTimer > 0)
		{
			wallTimer = 0;
			return;
		}
		var before = wallTimer;
		wallTimer += dt;
		if (wallTimer > 0.25 && Std.int(wallTimer * 6) != Std.int(before * 6))
			fx.PackFx.play("smoke", x + width / 2 - dx * 18, y + height - 6, 0.45);
		if (wallTimer >= 1.0)
		{
			wallTimer = 0;
			var len = Math.sqrt(dx * dx + dy * dy);
			chargeDirX = -dx / len;
			chargeDirY = -dy / len;
			chargeTimer = 0.5;
			charging = true;
			chargeDamage = 3;
			chargeHits = [];
			flipX = chargeDirX < 0;
			fx.Sfx.play("snort", 0.9);
			fx.Juice.shake(0.004, 0.2);
		}
	}

	function move():Void
	{
		elapsed = FlxG.elapsed;
		var vx = 0.0, vy = 0.0;
		vx = Input.moveX;
		vy = Input.moveY;

		if (shoveTimer > 0)
		{
			// being shoved: keep the knockback velocity, just bleed it off
			shoveTimer -= elapsed;
			velocity.scale(Math.pow(0.02, elapsed));
			if (!blocking && animation.name != "run" && !isShootAnim())
				animation.play("run");
			return;
		}
		var eff = blocking ? speed * 0.35 : speed;
		if (sheepTimer > 0)
		{
			// drunk sheep: 40 % speed and a new random heading offset every 0.3 s
			eff = speed * 0.4;
			drunkTimer -= elapsed;
			if (drunkTimer <= 0)
			{
				drunkTimer = 0.3;
				drunkAngle = FlxG.random.float(-1.05, 1.05); // +-60 degrees
			}
			var c = Math.cos(drunkAngle), s = Math.sin(drunkAngle);
			var rx = vx * c - vy * s, ry = vx * s + vy * c;
			vx = rx;
			vy = ry;
		}
		if (vx != 0 || vy != 0)
		{
			// facing is owned by aiming/attacking, never by movement
			var len = Math.sqrt(vx * vx + vy * vy);
			moveDirX = vx / len;
			moveDirY = vy / len;
			velocity.set(vx / len * eff, vy / len * eff);
			if (!blocking && (animation.finished || (animation.name != "run" && !isShootAnim())))
				animation.play("run");
		}
		else
		{
			velocity.set(0, 0);
			if (!blocking && (animation.finished || (animation.name != "idle" && !isShootAnim())))
				animation.play("idle");
		}
	}

	inline function isShootAnim():Bool
		return animation.name != null
			&& (StringTools.startsWith(animation.name, "shoot") || StringTools.startsWith(animation.name, "atk"))
			&& !animation.finished;

	/** Reads aim keys/mouse into aimInX/aimInY; true when actively aiming. */
	function readAimInput():Bool
	{
		aimInX = 0;
		aimInY = 0;
		// arrow keys combine: UP+RIGHT etc. give true diagonals
		aimInX = Input.aimX;
		aimInY = Input.aimY;
		if (aimInX != 0 && aimInY != 0)
		{
			aimInX *= 0.7071;
			aimInY *= 0.7071;
		}
		if (aimInX == 0 && aimInY == 0)
		{
			var pa = Input.padAim(); // right stick
			if (pa != null)
			{
				aimInX = pa.x;
				aimInY = pa.y;
			}
		}
		if (aimInX == 0 && aimInY == 0 && FlxG.mouse.pressed)
		{
			var m = FlxG.mouse.getWorldPosition();
			var cx = x + width / 2, cy = y + height / 2;
			var dx = m.x - cx, dy = m.y - cy;
			var len = Math.sqrt(dx * dx + dy * dy);
			if (len > 4)
			{
				aimInX = dx / len;
				aimInY = dy / len;
			}
			m.put();
		}
		return aimInX != 0 || aimInY != 0;
	}

	function aimAndFire():Void
	{
		if (!readAimInput())
			return;
		var aimX = aimInX, aimY = aimInY;

		if (aimX != 0 || aimY != 0)
		{
			lastAimX = aimX;
			lastAimY = aimY;
			if (aimX != 0)
				flipX = aimX < 0; // face the shot, and keep facing it after
			if (weapon.tryFire(this, aimX, aimY))
				playShootAnim(aimX, aimY);
		}
	}

	/** E: plant a dynamite at the player's feet, 2s fuse — then run. */
	function throwBomb():Void
	{
		if (bombs <= 0 || entities.Dynamite.pool == null)
			return;
		bombs--;
		fx.Sfx.play("fuse", 0.6);
		entities.Dynamite.pool.recycle(entities.Dynamite.new).plant(x + width / 2, y + height / 2);
	}

	function playShootAnim(aimX:Float, aimY:Float):Void
	{
		if (aimX != 0)
			flipX = aimX < 0;
		var angle = Math.atan2(aimY, Math.abs(aimX)); // -PI/2 (up) .. PI/2 (down)
		if (kind == Lancer)
		{
			var name = if (angle < -1.2) "atk_up"
				else if (angle < -0.35) "atk_upright"
				else if (angle < 0.35) "atk_right"
				else if (angle < 1.2) "atk_downright"
				else "atk_down";
			animation.play(name, true);
			return;
		}
		if (kind == Monk || kind == Panda)
		{
			animation.play("atk_side", true);
			return;
		}
		if (kind == Knight)
		{
			var name = if (angle < -0.9) "atk_up"
				else if (angle > 0.9) "atk_down"
				else (swingAlt ? "atk_side2" : "atk_side");
			swingAlt = !swingAlt;
			animation.play(name, true);
			return;
		}
		var name = if (angle < -1.2) "shoot_up"
			else if (angle < -0.4) "shoot_updiag"
			else if (angle < 0.4) "shoot_side"
			else if (angle < 1.2) "shoot_downdiag"
			else "shoot_down";
		animation.play(name, true);
	}

	override public function draw():Void
	{
		if (sheepTimer > 0 && sheep != null)
		{
			sheep.setPosition(x - 42, y - 54);
			sheep.flipX = flipX;
			sheep.cameras = cameras;
			sheep.draw();
			return;
		}
		super.draw();
	}

	/** Returns true if damage was applied (not in i-frames). */
	public function hurt2(damage:Int, ?source:FlxSprite):Bool
	{
		lastDeflected = false;
		// the shield only stops damage arriving from the blocked direction
		if (blocking && source != null)
		{
			var sx = (source.x + source.width / 2) - (x + width / 2);
			var sy = (source.y + source.height / 2) - (y + height / 2);
			var len = Math.sqrt(sx * sx + sy * sy);
			if (len > 0 && (sx / len * blockDirX + sy / len * blockDirY) > 0.35)
			{
				lastDeflected = true;
				fx.Sfx.play("parry", 0.8, 0.08, 0.15);
				return false; // deflected
			}
		}
		if (godMode || iframes > 0 || !alive || charging)
			return false;
		if (blackCrown && damage > 0 && source != null && Std.isOfType(source, Enemy) && Type.getClassName(Type.getClass(source)).indexOf("entities.Black") == 0)
		{
			// the crown: their every other blow glances off
			crownTick = !crownTick;
			if (crownTick)
			{
				fx.Sfx.play("parry", 0.6, 0.1, 0.2);
				iframes = 0.3;
				return false;
			}
		}
		hp -= damage;
		RunState.damageTaken += damage;
		if (damage > 0)
			RunState.lastHitBy = RunState.describe(source);
		sheepTimer = 0; // a hit breaks the hex
		if (hp <= 0 && secondWind > 0)
		{
			// Second Wind: the lethal hit is survived, one life spent
			secondWind--;
			hp = 3;
			revived = true;
			iframes = 2.0;
			flixel.effects.FlxFlicker.flicker(this, 2.0, 0.06);
			fx.PackFx.play("heal", x + width / 2, y + height / 2 - 20, 1.4);
			fx.Sfx.play("fanfare", 0.9);
			fx.Juice.shake(0.003, 0.15);
			return true;
		}
		fx.Juice.shake(0.003, 0.15);
		fx.Sfx.play(hp <= 0 ? "player_die" : "player_hurt", 0.8);
		if (hp <= 0)
		{
			// lethal hit: no i-frame flicker, just drop
			alive = false;
			velocity.set(0, 0);
			inputLocked = true;
			flixel.effects.FlxFlicker.stopFlickering(this);
			visible = true;
			return true;
		}
		iframes = PLAYER_IFRAMES;
		flixel.effects.FlxFlicker.flicker(this, PLAYER_IFRAMES, 0.06);
		if (source != null)
		{
			var kx = (x + width / 2) - (source.x + source.width / 2);
			var ky = (y + height / 2) - (source.y + source.height / 2);
			var len = Math.max(1, Math.sqrt(kx * kx + ky * ky));
			shove(kx / len * 400, ky / len * 400, 0.18);
		}
		return true;
	}
}
