package world;

import Constants.*;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

/** A doorway between two rooms: bridge sprite over the water gap + a rock
 * barricade shown while the room is locked. */
class Door extends FlxSpriteGroup
{
	public var dir(default, null):Int; // FloorMap.N/E/S/W
	public var room(default, null):Room;
	public var cx(default, null):Int;
	public var cy(default, null):Int;
	/** The grid cell of the room this door sits on, and the room it leads to. */
	public var cell:FloorMap.RoomNode;
	public var target:FloorMap.RoomNode;
	public var locked(default, null):Bool = true;

	/** Leads into (or out of) the shop: stays barred until a key is spent. */
	public var keyed(default, null):Bool = false;
	public var keyOpen:Bool = false;

	/** Hidden wall into a secret room: invisible and shut until a bomb opens it. */
	public var secret(default, null):Bool = false;
	public var revealed:Bool = false;

	/** Seconds the player has spent leaning on this hidden wall. */
	public var lean:Float = 0;
	var leanPuff:Float = 0;

	var bridge:FlxSprite;
	var rock:FlxSprite;
	var keyIcon:FlxSprite;

	public function new(room:Room, dir:Int, cx:Int, cy:Int)
	{
		super();
		this.room = room;
		this.dir = dir;
		this.cx = cx;
		this.cy = cy;
		var px = room.worldX + cx * TILE;
		var py = room.worldY + cy * TILE;

		bridge = new FlxSprite(px, py);
		bridge.loadGraphic("assets/images/tiles/bridge_all.png", true, 64, 64);
		bridge.animation.frameIndex = (dir == FloorMap.N || dir == FloorMap.S) ? 6 : 1;
		add(bridge);

		rock = new FlxSprite(px + 8, py + 8);
		rock.loadGraphic("assets/images/tiles/rocks_01.png");
		rock.setGraphicSize(48, 48);
		rock.updateHitbox();
		add(rock);

		setLocked(true);
	}

	public function setSecret():Void
	{
		secret = true;
		bridge.visible = false;
		rock.visible = false;
	}

	/** Player pressed against the hidden wall: count up to LEAN_TIME, then open. */
	public static inline var LEAN_TIME:Float = 3.0;

	/** Returns true on the frame the wall gives way. */
	public function leanOn(elapsed:Float, leaning:Bool):Bool
	{
		if (revealed)
			return false;
		if (!leaning)
		{
			lean = Math.max(0, lean - elapsed * 2); // let go and it settles back
			return false;
		}
		lean += elapsed;
		leanPuff -= elapsed;
		if (leanPuff <= 0)
		{
			// the wall shivers: dust off the rock, a little louder as it gives
			leanPuff = 0.7 - 0.15 * (lean / LEAN_TIME);
			fx.PackFx.play("smoke", room.worldX + cx * TILE + TILE / 2 + flixel.FlxG.random.float(-14, 14),
				room.worldY + cy * TILE + TILE / 2 + flixel.FlxG.random.float(-8, 8), 0.5 + 0.4 * (lean / LEAN_TIME));
			fx.Sfx.play("door_open", 0.25 + 0.25 * (lean / LEAN_TIME), 0.1, 0.3);
			fx.Juice.shake(0.001 + 0.002 * (lean / LEAN_TIME), 0.1);
		}
		if (lean >= LEAN_TIME)
		{
			reveal();
			return true;
		}
		return false;
	}

	/** Pressed right up against the wall: within a tile of the hidden door cell. */
	public function leaningOn(p:flixel.FlxObject):Bool
	{
		var dx = (p.x + p.width / 2) - (room.worldX + cx * TILE + TILE / 2);
		var dy = (p.y + p.height / 2) - (room.worldY + cy * TILE + TILE / 2);
		return dx * dx + dy * dy < 78 * 78;
	}

	/** The hidden wall gives way for good. */
	public function reveal():Void
	{
		if (revealed)
			return;
		revealed = true;
		bridge.visible = true;
		fx.PackFx.play("smoke", room.worldX + cx * TILE + TILE / 2, room.worldY + cy * TILE + TILE / 2, 1.6);
		fx.Sfx.play("stone_break", 0.9);
		fx.Juice.shake(0.005, 0.25);
	}

	public function setKeyed():Void
	{
		keyed = true;
		keyIcon = new FlxSprite(rock.x + 8, rock.y + 6, "assets/images/ui/icon_key.png");
		keyIcon.setGraphicSize(32, 32);
		keyIcon.updateHitbox();
		add(keyIcon);
	}

	/** Player centre within reach of the barred tile (used to spend a key). */
	public function nearPlayer(p:flixel.FlxObject):Bool
	{
		var dx = (p.x + p.width / 2) - (room.worldX + cx * TILE + TILE / 2);
		var dy = (p.y + p.height / 2) - (room.worldY + cy * TILE + TILE / 2);
		return dx * dx + dy * dy < 90 * 90;
	}

	public function setLocked(value:Bool):Void
	{
		locked = value;
		rock.visible = value && !(secret && !revealed);
		if (secret && !revealed)
			bridge.visible = false;
		if (keyIcon != null)
			keyIcon.visible = value && !keyOpen;
		if (!value)
			room.carve(cx, cy);
		// while locked the collision tile stays solid — no carve needed
	}

	/** Trigger: player center near the door tile — generous across the door,
	 * tight along the exit axis (walls stop the player anywhere else on the edge). */
	public function overlapsPlayer(p:flixel.FlxObject):Bool
	{
		if (locked)
			return false;
		var px = room.worldX + cx * TILE;
		var py = room.worldY + cy * TILE;
		var cxp = p.x + p.width / 2;
		var cyp = p.y + p.height / 2;
		var vertical = dir == FloorMap.N || dir == FloorMap.S;
		if (vertical)
			return cxp > px - 56 && cxp < px + TILE + 56 && cyp > py - 24 && cyp < py + TILE + 24;
		return cyp > py - 56 && cyp < py + TILE + 56 && cxp > px - 24 && cxp < px + TILE + 24;
	}
}
