package entities;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

enum PropKind
{
	Rock; // solid, indestructible
	Tree; // solid, indestructible, tall
	Bush; // solid, destructible by arrows + explosions
	WaterRock; // decorative, on water
	GoldStone; // solid, breaks only from explosions -> coins
	Deco; // decorative
	Hut; // solid merchant hut (shop room)
	Fence; // solid wooden fence segment (Goblin Camp)
	GoblinHut; // solid goblin hut (Goblin Camp)
	SkullSpike; // solid bone spike (Caves)
	Bones; // decorative bone pile (Caves)
	Castle; // solid castle on the Keep's summit
	BlackHouse; // Troy: solid house (3 variants)
	BlackBarracks; // Troy: solid; releases a Black Knight when the room is entered
	BlackMonastery; // Troy: solid, tall
	GnomeHut; // Gnome Mines: solid; releases a Gnome when the room is entered
}

class Prop extends FlxSprite
{
	public var kind(default, null):PropKind;
	public var blocking(default, null):Bool = false;

	/** Set for solid props: pathfinding cell to free when destroyed. */
	public var navRoom:world.Room;
	public var navCell:Int = -1;

	/** Set by PlayState: coins fly out of broken gold stones. */
	public static var coins:FlxTypedGroup<Coin>;
	/** Gold Nose item: multiplier on every coin drop (kept in step by ItemPool.give). */
	public static var goldBonus:Float = 1;

	var bushHp:Int = 2;

	/** x/y = tile world position (64px cell the prop stands on). */
	public function new(x:Float, y:Float, kind:PropKind, variant:Int = 1)
	{
		super();
		this.kind = kind;
		immovable = true;
		switch (kind)
		{
			case Rock:
				loadGraphic('assets/images/props/rock_$variant.png');
				setSize(48, 34);
				setPosition(x + 8, y + 24);
				offset.set(8, 26);
				blocking = true;
			case Tree:
				// tree.png: 4x3 grid @192; row0 = 4-frame sway, (0,2) = stump
				loadGraphic('assets/images/props/tree${world.LevelDefs.propSuffix()}.png', true, 192, 192);
				animation.add("sway", [0, 1, 2, 3], 4 + FlxG.random.int(0, 3));
				animation.play("sway");
				animation.curAnim.curFrame = FlxG.random.int(0, 3);
				setSize(44, 30);
				setPosition(x + 10, y + 28);
				offset.set(74, 148);
				blocking = true;
			case Bush:
				// bush_N.png: 8 frames @128, gentle sway
				loadGraphic('assets/images/props/bush${world.LevelDefs.propSuffix()}_$variant.png', true, 128, 128);
				animation.add("sway", [0, 1, 2, 3, 4, 5, 6, 7], 6);
				animation.play("sway");
				animation.curAnim.curFrame = FlxG.random.int(0, 7);
				setSize(52, 34);
				setPosition(x + 6, y + 24);
				offset.set(38, 62);
				blocking = true;
			case WaterRock:
				// waterrock_N.png: 16 frames @64, bobbing in water
				loadGraphic('assets/images/props/waterrock_$variant.png', true, 64, 64);
				animation.add("bob", [for (i in 0...16) i], 8);
				animation.play("bob");
				animation.curAnim.curFrame = FlxG.random.int(0, 15);
				setPosition(x, y);
				solid = false;
			case GoldStone:
				loadGraphic('assets/images/props/goldstone_$variant.png'); // 128x128
				setSize(64, 42);
				setPosition(x, y + 20);
				offset.set(32, 60);
				blocking = true;
			case Deco:
				loadGraphic('assets/images/props/deco_${variant < 10 ? "0" + variant : "" + variant}.png');
				setPosition(x, y);
				solid = false;
			case Hut:
				// fish_hut.png: 8 frames @192, animated; base centred on the tile
				loadGraphic("assets/images/props/fish_hut.png", true, 192, 192);
				animation.add("idle", [for (i in 0...8) i], 6);
				animation.play("idle");
				setSize(104, 40);
				setPosition(x - 20, y + 10);
				offset.set(44, 136);
				blocking = true;
			case Fence:
				// fence_tiles.png: 4x3 @64; frame 1 = a straight run
				loadGraphic("assets/images/props/fence_tiles.png", true, 64, 64);
				animation.frameIndex = 1;
				setSize(60, 22);
				setPosition(x + 2, y + 34);
				offset.set(2, 34);
				blocking = true;
			case GoblinHut:
				// goblin_hut.png: 16 smoke frames @192x256; hut body x26-170, base at y241
				loadGraphic("assets/images/props/goblin_hut.png", true, 192, 256);
				animation.add("smoke", [for (i in 0...16) i], 6);
				animation.play("smoke");
				setSize(120, 44);
				setPosition(x - 28, y + 14);
				offset.set(38, 192);
				blocking = true;
			case SkullSpike:
				loadGraphic('assets/images/props/skullspike_$variant.png'); // 64x128
				setSize(36, 24);
				setPosition(x + 14, y + 36);
				offset.set(14, 76);
				blocking = true;
			case Bones:
				loadGraphic('assets/images/props/bones_$variant.png');
				setPosition(x, y);
				solid = false;
			case BlackHouse:
				loadGraphic('assets/images/props/black_house$variant.png');
				setSize(90, 40);
				setPosition(x - 13, y + 24);
				offset.set(19, 132);
				blocking = true;
			case BlackBarracks:
				loadGraphic("assets/images/props/black_barracks.png");
				setSize(150, 44);
				setPosition(x - 43, y + 20);
				offset.set(21, 200);
				blocking = true;
			case BlackMonastery:
				loadGraphic("assets/images/props/black_monastery.png");
				setSize(120, 44);
				setPosition(x - 28, y + 20);
				offset.set(36, 264);
				blocking = true;
			case GnomeHut:
				loadGraphic("assets/images/props/gnome_hut.png");
				setSize(84, 36);
				setPosition(x - 10, y + 26);
				offset.set(22, 110);
				blocking = true;
			case Castle:
				// castle.png 320x256: keep, base ~y250; centred on its spawn tile, wide solid footprint
				loadGraphic("assets/images/props/castle.png");
				setSize(230, 70);
				setPosition(x - 83, y - 10);
				offset.set(45, 180);
				blocking = true;
		}
	}

	/** Arrow impact. Returns true if the arrow should die (hit something solid). */
	public function hitByArrow():Bool
	{
		switch (kind)
		{
			case Bush:
				bushHp--;
				if (bushHp <= 0)
					destroyWithPoof();
				else
					fx.Sfx.play("bush", 0.4);
				return true;
			case Rock, Tree, GoldStone, Hut, Fence, GoblinHut, SkullSpike, Castle, BlackHouse, BlackBarracks, BlackMonastery, GnomeHut:
				fx.Sfx.play("arrow_block", 0.5);
				return true;
			default:
				return false;
		}
	}

	public function hitByExplosion():Void
	{
		switch (kind)
		{
			case Bush:
				destroyWithPoof();
			case GoldStone:
				breakOpen();
			default:
		}
	}

	function destroyWithPoof():Void
	{
		fx.Sfx.play("bush", 0.7);
		spawnPoof(x + width / 2, y + height / 2);
		freeNav();
		kill();
	}

	function breakOpen():Void
	{
		fx.Sfx.play("stone_break", 0.8);
		spawnPoof(x + width / 2, y + height / 2);
		if (coins != null)
			for (i in 0...Math.round(FlxG.random.int(2, 4) * goldBonus))
			{
				var c = coins.recycle(Coin.new);
				c.drop(x + width / 2, y + height / 2);
			}
		freeNav();
		kill();
	}

	function freeNav():Void
	{
		if (navRoom != null && navCell >= 0)
			navRoom.freeNavCell(navCell);
	}

	static function spawnPoof(cx:Float, cy:Float):Void
	{
		var poof = new FlxSprite();
		poof.loadGraphic("assets/images/fx/dust.png", true, 64, 64);
		poof.animation.add("poof", [0, 1, 2, 3, 4, 5, 6, 7], 16, false);
		poof.animation.onFinish.add(_ -> poof.kill());
		poof.setPosition(cx - 32, cy - 40);
		poof.animation.play("poof");
		FlxG.state.add(poof);
	}
}
