package items;

import entities.Player;
import flixel.FlxG;

/** The run's item pool. `reset()` at run start; `draw()` hands out each item at most once. */
class ItemPool
{
	public static var all(default, null):Array<ItemDef> = [
		{
			id: "arrowheads", name: "Sharpened Arrowheads", caption: "+1 damage",
			icon: "assets/images/items/arrowheads.png",
			apply: p -> p.damage += 1
		},
		{
			id: "heavy_shot", name: "Heavy Shot", caption: "+2 damage, slower attacks",
			icon: "assets/images/items/heavy_shot.png",
			apply: p ->
			{
				p.damage += 2;
				p.fireCooldown *= 1.25;
			}
		},
		{
			id: "quiver_oil", name: "Quiver Oil", caption: "attacks 25% faster",
			icon: "assets/images/items/quiver_oil.png",
			apply: p -> p.fireCooldown *= 0.75
		},
		{
			id: "longbow_string", name: "Longbow String", caption: "+40% range",
			icon: "assets/images/items/longbow_string.png",
			apply: p -> p.arrowRange *= 1.4
		},
		{
			id: "boots", name: "Boots of the Thief", caption: "+20% move speed",
			icon: "assets/images/items/boots.png",
			apply: p -> p.speed *= 1.2
		},
		{
			id: "sheep_meat", name: "Sheep Meat", caption: "+1 max HP, full heal",
			icon: "assets/images/items/sheep_meat.png",
			apply: p ->
			{
				p.maxHp += 2; // HP is counted in half-hearts
				p.hp = p.maxHp;
			}
		},
		{
			id: "bomb_sack", name: "Bomb Sack", caption: "+5 bombs",
			icon: "assets/images/items/bomb_sack.png",
			apply: p -> p.bombs += 5
		},
		{
			id: "key_ring", name: "Key Ring", caption: "+2 keys",
			icon: "assets/images/items/key_ring.png",
			apply: p -> p.keys += 2
		},
		{
			id: "magic_mushroom", name: "Magic Mushroom", caption: "+1 HP, +1 damage, faster, and bigger",
			icon: "assets/images/items/magic_mushroom.png",
			apply: p ->
			{
				p.maxHp += 2;
				p.hp = p.maxHp;
				p.damage += 1;
				p.speed *= 1.1;
				p.scale.scale(1.2);
			}
		},
		{
			id: "panda_cub", name: "Panda Cub", caption: "a cub follows you and swipes anything that gets close",
			icon: "assets/images/items/panda_cub.png",
			apply: p -> entities.Familiar.spawn("panda"),
			familiar: "panda"
		},
		{
			id: "bone_buddy", name: "Bone Buddy", caption: "a little skeleton follows you and throws bones",
			icon: "assets/images/items/bone_buddy.png",
			apply: p -> entities.Familiar.spawn("bone"),
			familiar: "bone"
		},
		{
			id: "goblin_torch", name: "Goblin Torch", caption: "your attacks set enemies on fire",
			icon: "assets/images/items/goblin_torch.png",
			apply: p -> p.burnHits = true
		},
		{
			id: "twin_shot", name: "Twin Shot", caption: "two shots or swings in a narrow spread",
			icon: "assets/images/items/twin_shot.png",
			apply: p -> p.twinShot = true
		},
		{
			id: "water_walker", name: "Water Walker", caption: "wade across one-tile water pits",
			icon: "assets/images/items/water_walker.png",
			apply: p -> p.waterWalker = true
		},
		{
			id: "second_wind", name: "Second Wind", caption: "get back up once with 1\u00bd hearts",
			icon: "assets/images/items/second_wind.png",
			apply: p -> p.secondWind += 1
		},
		{
			id: "gold_nose", name: "Gold Nose", caption: "50% more gold from every drop",
			icon: "assets/images/items/gold_nose.png",
			apply: p -> p.goldBonus *= 1.5
		},
		{
			id: "merchants_ledger", name: "Merchant's Ledger", caption: "shop prices -30%",
			icon: "assets/images/items/merchants_ledger.png",
			apply: p -> p.shopDiscount *= 0.7
		},
		{
			id: "campfire_heart", name: "Campfire Heart", caption: "a campfire burns in every combat room",
			icon: "assets/images/items/campfire_heart.png",
			apply: p -> p.campfireHeart = true
		},
		{
			id: "lucky_coin", name: "Lucky Coin", caption: "SPACE rerolls an item on a pedestal; recharges over 3 rooms",
			icon: "assets/images/items/lucky_coin.png",
			apply: p -> {},
			active: 3
		},
	];

	/** Boss items: dropped by a level's boss, never in the treasure pool. */
	public static var bosses(default, null):Array<ItemDef> = [
		{
			id: "troll_skin", name: "Troll Skin", caption: "explosions can't hurt you, fire can't burn you",
			icon: "assets/images/items/troll_skin.png",
			apply: p -> p.trollSkin = true
		},
		{
			id: "bear_claw", name: "Bear Claw", caption: "melee hits knock enemies back twice as far",
			icon: "assets/images/items/bear_claw.png",
			apply: p -> p.bearClaw = true
		},
		{
			id: "minotaur_horns", name: "Minotaur Horns", caption: "push against a wall for 1 s to charge across the room",
			icon: "assets/images/items/minotaur_horns.png",
			apply: p -> p.horns = true
		},
		{
			id: "shaman_charm", name: "Shaman Charm", caption: "1 in 10 hits turns an enemy into a sheep",
			icon: "assets/images/items/shaman_charm.png",
			apply: p -> p.sheepHex = true
		},
		{
			id: "black_crown", name: "Black Crown", caption: "Troy's black units only land every other blow",
			icon: "assets/images/items/black_crown.png",
			apply: p -> p.blackCrown = true
		},
		{
			id: "harpoon", name: "Harpoon", caption: "your hits reel small enemies in",
			icon: "assets/images/items/harpoon.png",
			apply: p -> p.harpoon = true
		},
	];

	/** Which boss item each level's boss guards (levels without one drop a pool item instead). */
	static var bossItemOf:Map<String, String> = ["plains" => "troll_skin", "forest" => "bear_claw", "camp" => "shaman_charm", "caves" => "minotaur_horns", "waters" => "harpoon", "troy" => "black_crown"];

	/** The pedestal a beaten boss leaves behind: the level's boss item if the hero doesn't own it yet, else a pool item. */
	public static function bossDrop(levelId:String, p:Player):ItemDef
	{
		var id = bossItemOf.get(levelId);
		if (id != null && p.itemIds.indexOf(id) < 0)
			return byId(id);
		return draw();
	}

	/** Lucky Coin reroll: an undrawn item goes back into the bag. */
	public static function putBack(def:ItemDef):Void
	{
		if (def != null && bosses.indexOf(def) < 0 && remaining.indexOf(def) < 0)
			remaining.insert(FlxG.random.int(0, remaining.length), def);
	}

	static var remaining:Array<ItemDef> = [];

	public static function reset():Void
	{
		remaining = all.copy();
		FlxG.random.shuffle(remaining);
	}

	/** Next unseen item this run, or null when the pool is exhausted. */
	public static function draw():ItemDef
	{
		if (remaining.length == 0)
			return null;
		return remaining.pop();
	}

	/** Ids still undrawn this run (for the run save). */
	public static function remainingIds():Array<String>
		return [for (d in remaining) d.id];

	public static function setRemaining(ids:Array<String>):Void
		remaining = [for (id in ids) byId(id)].filter(d -> d != null);

	public static function byId(id:String):ItemDef
	{
		for (d in all)
			if (d.id == id)
				return d;
		for (d in bosses)
			if (d.id == id)
				return d;
		return null;
	}

	/** Apply an item to the player and record it for the pause screen. */
	public static function give(p:Player, def:ItemDef):Void
	{
		if (def.active != null)
		{
			// active items live in the R slot; the one already there goes back into the bag
			var old = byId(p.activeId);
			if (old != null)
			{
				p.items.remove(old.icon);
				p.itemIds.remove(old.id);
				putBack(old);
			}
			p.activeId = def.id;
			p.activeMax = def.active;
			p.activeCharge = def.active; // arrives charged
		}
		def.apply(p);
		p.items.push(def.icon);
		p.itemIds.push(def.id);
		RunState.itemsTaken++;
		entities.Prop.goldBonus = p.goldBonus;
	}

	/** New floor: bring back the followers the hero already owns. */
	public static function respawnFamiliars(p:Player):Void
	{
		for (id in p.itemIds)
		{
			var d = byId(id);
			if (d != null && d.familiar != null)
				entities.Familiar.spawn(d.familiar);
		}
	}
}
