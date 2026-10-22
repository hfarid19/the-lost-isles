# The Lost Isles — Game Design

Living design doc. Sections marked **[built]** describe what the code already does; everything else is planned.

**Art rule (decided 2026-09-26):** everything that is not an item icon is Tiny Swords by Pixel Frog (Free Pack,
Update 010, Enemy Pack; all three extracted in the project folder). Item icons are the one exception: Admurin's
Premium item packs (32 px singles shown at 2x). Every other pack that was tried this year (Ninja Adventure, the
Forest Monsters artist, Pixel Crawler, Cute Fantasy, Tiny RPG, Cainos, the 80 Monster Packs, the Super Pixel
Effects Gigapack, the Blender renders) is out; section 2b lists what was swapped.

## 1. Pitch

A top-down roguelike in the shape of The Binding of Isaac: pick a hero, sail island to island through a run of
procedurally laid-out floors, clear rooms, collect items that stack into a build, kill the final boss.
Runs are short (20 to 30 min). Dying restarts the run. Progress between runs comes from unlocks, not stats.

## 2. Run structure

A run is a sequence of **levels**. Each level has **two floors** that share a theme and enemy roster; the second
floor is harder and ends in the level boss.

| # | Level | Floors | Theme and terrain | Enemies (general) | Boss pool (one rolled per floor) |
|---|-------|--------|-------------------|-------------------|----------------------------------|
| 1 | Plains | Plains I, Plains II | open grass fields ringed by water, a few water pits, sheep and fences | Torch Goblin, TNT Goblin, Spear Goblin, Pig (charges in a straight line, bounces off rocks) | Troll, Gnoll, Giant Torch Goblin |
| 2 | Forest | Forest I, Forest II | dense trees, bushes, dead trees, wooden fences | Gnome, Slingshot Gnome (acorns from range), Bumblebee, Snake (lunges, poison bite) | Bear (black, scaled up), Lizard, Spider |
| 3 | Goblin Camp | Camp I, Camp II | goblin huts, wooden fences, campfires, TNT crates, pig pens, cannons | Torch Goblin, TNT Goblin, Spear Goblin, Spear Goblin Elite (strong attack), Barrel Goblin, Pig Rider Spear Goblin, Pig, Cannon | Hex Shaman (transforms), Pig Rider Warlord, Goblin Hut (spawner) |
| 4 | Caves | Caves I, Caves II | dark, cave entrances, skull decorations | Skull, Imp (flame burst), Bat (the Giant Bat sheet at 1x: sleeps on walls, wakes when close), Thief (dashes in, steals gold, runs), Turtle (shell blocks frontal hits), Minotaur Guard (the heavy, Extra sheet) | Minotaur, Skull Guard, Giant Bat (scaled up) |
| — | Final: The Keep | one 2.5D floor | raised plateaus with cliff faces, stairs, a castle and towers (see below) | two waves drawn from every earlier level, plus tower archers | Black King (a giant Free Pack Black Warrior); the harder form adds the Black Champion |
| 5 | Mystic Bamboo Isle (unlock) **[built]** | Bamboo I, Bamboo II | the pink-tinted Free Pack tileset (Tilemap_color variants) with recoloured Update 010 trees as the canopy, still ponds | Panda Guard (Extra sheet, the line-holder), Thief, Snake, Turtle, Slingshot Gnome | Panda, Panda Guard |
| 6 | Shark Waters (unlock) **[built]** | Waters I, Waters II | mostly water: small islets joined by bridges, enemies attack from the sea | Paddle Shark, Harpoon Shark, Bomb Fish, Thief (on islets), Seahorse Boat riders, Turtle | Harpoon Shark, Paddle Shark, Bomb Fish |
| 7 | Troy (unlock) **[built]** | Troy I, Troy II | a fallen kingdom: black-stone castle walls, barracks, archery ranges, a monastery, towers as turrets | the four heroes as enemies, Free Pack Black Units: Black Knight (sword, guards), Black Spearman (lancer, 5-way thrusts), Black Archer (volleys), Black Monk (heals the others) | Black King (a giant Black Knight), Black Champion (Black Spearman on a Pig), Black Abbot (Black Monk, resurrects fallen enemies) |
| 8 | Gnome Mines (unlock) **[built]** | Mines I, Mines II | gnome huts and towers, gold mines, gold-stone-heavy rooms | Gnome, Slingshot Gnome, Turtle, Bat, Minotaur Guard | Gnome Tower (spawner), Giant Slingshot Gnome, Turtle Guard |

All enemies above are Enemy Pack, Update 010, or Free Pack sheets at their native 192 px frame (about 70 px
bodies); bosses are the same sheets scaled up. Enemy Pack sprites still unused anywhere: the Pirate Tower's
water variant.

## 2b. Art pass **[done 2026-09-26]**

Every foreign sprite was swapped; the old classes and sheets sit in `retired/` outside the build. Nothing in
`assets/images` is foreign now except the item icons and the pedestal.

| Was in the build | Source | Replacement (Tiny Swords) |
|------------------|--------|----------------------------|
| Mushroom (Forest) | Forest Monsters | Snake: same slot (slow chaser), its stun becomes a coil-up telegraph |
| Stump Flyer (Forest) | Flying Forest Enemies | Slingshot Gnome: ranged acorns instead of the hover smash |
| Skeleton (Caves) | Forest Monsters skeletons | Thief: the fast melee unit that also steals a coin on hit |
| Cave Bat (Caves) | Forest Monsters | the Giant Bat sheet at 1x, same sleep-and-wake behaviour |
| Golem (Caves) | Forest Monsters golems | Minotaur Guard (Extra): slow, 8 HP, wide swing |
| Green Dragon (Keep boss) | Ninja Adventure dragon parts | Black King: the Free Pack Black Warrior at 2x with the Knight's guard (see section 7) |
| Panda Cub, Bone Buddy familiars | Ninja Adventure 16 px, Cute Fantasy 32 px | the Enemy Pack Panda and Skull sheets at 0.5x (35 px bodies) |
| sparkle, smoke, impact, heal, coin burst (`fx/pack`) | Super Pixel Effects Gigapack | Free Pack `Particle FX` (Dust_01/02, Fire_01..03, Explosion_01/02) plus the Monk's heal effect; sparkle and coin burst are tints of those |
| Viking / Slime boss renders (`SlimeBoss`, `artsrc`) | Blender | retired with the rest |
| stone pedestal (`props/pedestal.png`) | Cainos | the one prop kept: it is item furniture and the packs have no stand. Swap only if a Tiny Swords stand gets drawn |

Rule of thumb for scale from here on: Tiny Swords sheets at 1x for regular enemies, 1.5x to 2x for bosses,
0.5x for familiars. No sprite from any other pack, at any scale.

Every floor ends in a **boss room**. The boss is rolled at random from the level's pool, and floor II never
repeats floor I's boss. Every boss drops a boss item and opens the boat.

**[built]** Floors are 8 rooms grown from a centre start room, boss, shop, and treasure rooms at dead ends, a
secret room every floor, and the start room never has a west door (the hero lands on its west shore). Boss HP
scales with floor and level (`setScaledHp`: base times 1 + 0.25 per floor + 0.35 per level). Every level's
boss pool is built (section 9b).

### Floor layout

Isaac-style grid growth from the start room. Every floor has:

- 1 start room (safe, training dummy on floor Plains I only)
- 5 to 8 combat rooms, growing with level number
- 1 treasure room (dead end, always present)
- 1 shop (dead end, needs a key; not on the final floor)
- 1 boss room (farthest dead end)
- 1 secret room on every floor **[built]**: a hidden island off one combat room, never beside the boss room,
  with gold and meat. The tell is a water rock just off the hidden door's shore and a shiver of dust when you
  enter the room; lean against that edge of the island for 3 s and the bridge appears, the room joins the map
  (hold TAB or M for the floor map)

Rooms are built from 15 by 9 tile cells at 64 px. Doors are bridges over water. Combat rooms lock their doors
until cleared. **[built]** Up to two combat rooms per floor fuse neighbouring cells into a big room: 2x1
(30 by 9), 1x2 (15 by 18) or 2x2 (30 by 18), Isaac's own big shapes. A big room has a door on every outer cell
edge that meets a neighbour, the camera scrolls inside it, and the map draws it as one block. Special rooms and
the Keep's elevation rooms stay single cells.

### Level transition: the boat

**[built for floors]** When a floor boss dies, a wooden rowing boat (Enemy Pack, Extra/Boat, 8-frame bobbing
idle) drifts up to the shore of the boss room and moors on the water tile at the middle of a side with no
door. The player walks onto it to leave.

- Floor I to Floor II: a short sail. Camera pans over open water, the next floor fades in.
- Level to level: a longer sail with the level name card ("Forest I"). Music changes.
- Optional stop: the boat docks at a **shop raft** once per run on the first change of level **[built]**: meat 10,
  bombs x2 13, key 13, one run item 30, no key needed, then sail on.

The boat is also the run start: the menu island's boat carries the chosen hero to Plains I.

**Caves are entered and left on foot.** When the Goblin Camp II boss dies, no boat comes; instead a cave mouth
(`Enemy Pack/Extra/Cave`, `Cave.aseprite`, 8-frame idle with an animated dark opening) rises out of the ground
at the dock cell. Walking into the opening fades to black and Caves I begins. The same happens between Caves I
and Caves II (a cave mouth leads deeper), and at the end of Caves II the exit cave mouth leads back into
daylight, where the boat waits. Cave transitions play a short rumble and a torch-lighting sound instead of the sail.

## 3. Heroes

The game starts with the Archer only. The other four unlock through play.

| Hero | Sprite source | Weapon | HP | Speed | Trait | Unlock condition |
|------|---------------|--------|----|-------|-------|------------------|
| Archer | Knights/Archer **[built]** | bow, 0.52 s cooldown, arrows light on campfires | 6 | 340 | ranged, fragile | available from the start |
| Knight | Knights/Warrior **[built]** | sword, 2 dmg, short reach | 6 | 370 | can guard (hold to block, slows to 35 %) | beat any Plains boss once |
| Lancer | Free Pack/Lancer **[built]** | spear, 2 dmg, 130 px reach, thrusts in 5 directions | 6 | 340 | pierces lines of enemies | beat any Forest boss once |
| Monk **[built]** | Free Pack/Monk | palm strikes, very fast, 1 dmg, heals half a heart per cleared room | 8 | 360 | no ranged option, best sustain | finish a run without buying from a shop |
| Panda **[built]** | Enemy Pack/Panda (Idle, Run, Attack sheets) | paw swipe, 3 dmg, slow 0.7 s cooldown | 10 | 300 | tanky bruiser; Shift / LB rolls 0.35 s, untouchable, bowling small enemies over for 1 | defeat the Panda boss on the Mystic Bamboo Isle |

Hero unlocks are announced in play with the hero's avatar card and on the select screen.

## 4. Rooms

**[built]** Combat rooms are square islands. Each rolls one obstacle style: 2 to 3 destructible bushes, 2 to 3
indestructible rocks or trees, or a small mix. Water rocks and decorative tufts are cosmetic. Some rooms have a
campfire that lights arrows.

Per-level variation, keeping rooms simple:

- **Forest**: trees replace rocks as the indestructible obstacle; dead trees are destructible; wooden fences
  make short walls.
- **Shark Waters** **[built]**: the water-enemy level. Rooms are islets joined by sandbars over open water; the
  player is never far from the sea. Sharks and bomb fish swim in the water and can only be hit while surfaced.
  Melee heroes fight at the shoreline; ranged heroes shoot over water. Pirate towers (`Extra/Pirate Tower`,
  ground variant) shoot cannonballs until destroyed. Seahorse Boat riders circle on the water, always hittable.
- **Goblin Camp** **[built]**: Goblin Huts (Enemy Pack `Extra/Goblin Hut`) as indestructible blocks; wooden
  fences as short walls; campfires in most rooms (arrows light on them). **Cannons** (`Extra/Cannon`): a
  stationary turret that fires a slow cannonball at the player every 3 s; destroyed with 3 hits or one bomb.
- **Troy** **[built]**: the mirror-match level. Enemies are the hero classes recoloured black (`Free Pack/Units/
  Black Units`). Rooms are courtyards: Black Buildings (`Barracks`, `Monastery`, three `House` variants) as large
  indestructible blocks; a Black Tower shoots arrows until destroyed; a Barracks releases one Black Knight when
  the room is entered. Black Monks stay behind the line and heal, so the room design pushes the player to reach
  them first. The Black Pawn appears as a fleeing villager who drops gold if caught.
- **Gnome Mines** **[built]**: the gold level. **Gold Mines** (Update 010 `Resources/Gold Mine`, active and
  destroyed states) spawn a Gnome every 8 s until bombed; a bombed mine bursts into 8 to 12 coins. Gnome Huts
  release a gnome on entry, Gnome Towers sling acorns. Extra gold stones in every room.
- **Caves**: the packs have no indoor tileset, so "indoors" is faked with what exists (see below).

### The Keep: the 2.5D final level

Reference: `artsrc/reference/tiny_swords_elevation_promo.png` (the Tiny Swords promo). The final level, reached
after the base levels and any unlocked ones, drops the flat-island look for **elevation**: grass plateaus stacked
on stone cliff faces, connected by stairs and bridges, with a castle on the top tier.

Assets, all in Update 010:

- `Terrain/Ground/Tilemap_Elevation.png`: cliff tops and 2-tile-tall cliff faces, autotiled like the flat grass.
- `Terrain/Ground/Shadows.png`: the soft drop shadow a plateau casts on the tier below.
- `Terrain/Bridge/Bridge_All.png`: stairs and bridges between tiers.
- `Factions/Knights/Buildings`: Castle, Tower, and House (blue) for the summit and the villages on the lower tiers.
- `Resources/Trees` and the Deco tufts for the wooded edges; sheep from `Resources/Sheep` wander the low tier.

Rules:

- Tiers: water level (bridges, starting boat), the lower plateau (villages, most fights), and the summit
  (castle courtyard, boss arena). A cliff edge is a wall from below and a one-way drop from above (dropping
  costs nothing, but there is no way back up except the stairs).
- Stairs are the only upward path and are choke points.
- Draw order follows tier: lower tiers draw first, then their cliff faces, then the tier above.
- Rooms are bigger than the standard 15 by 9: Keep rooms are 23 by 13, scrolled by the camera.
- Only this level uses elevation in the base game.

### Building indoor-feeling rooms (Caves)

Nothing in the three packs is an interior tileset, but four assets combine into a convincing cave:

- **Cliff tiles**: `Tiny Swords (Update 010)/Terrain/Ground/Tilemap_Elevation.png` used as the room's floor
  (cliff top) and as thick stone walls (cliff face, 2 tiles tall) around the edge.
- **Void instead of water**: a near-black backdrop. The stone walls sit on black, so the space outside the room
  reads as unlit rock.
- **Darkness overlay**: a black overlay over the whole room with a soft circular hole around the player and
  around light sources (`fx/LightManager` tracks the player light and a boss light).
- **Cave props**: the Enemy Pack cave mouth as the doorway between levels, and `Extra/Skull decorations` (bone
  piles, skull spikes) as floor deco. Rocks stay the indestructible obstacle.
- **Palette**: the Free Pack ships five tinted grass tilesets; colour 5 is a cold teal that matches the cliff sheet.

Enemy spawns stay authored per template (T/N letters in `tools/gen_rooms.py`); props are scattered at run time
unless the template authors them itself (`R` rock, `U` bush, `F` campfire), in which case no random obstacles
are added.

### Isaac room library **[built]**

The Binding of Isaac's own room files are the reference for room design. They were unpacked from the Steam
install with its ResourceExtractor and kept in `artsrc/isaac_rooms/*.stb` (17 stages, 7,911 standard 1x1
combat rooms; Isaac's 13 by 7 interior is exactly our island). `tools/isaac_rooms.py artsrc/isaac_rooms` dumps
every stage to `tools/isaac_rooms/<stage>.txt` in our legend (rocks as R, pits as water, TNT and poop as U
bushes, fireplaces as campfires, enemies as T or N); `... pick 01:3 04:31` prints chosen rooms as template
entries. `... export` builds every level's pool: per Isaac stage 36 single rooms, 8 wide, 8 tall and 4 double
rooms, skipping layouts whose doors can't reach each other or that are more than 30 % rock, capped at 5 enemies
(8 in big rooms). Floor I of a level draws only layouts Isaac rates easy (difficulty 5 or less); floor II draws
any. On top of that each level caps the enemies a room spawns (Plains 3 then 4, Forest 4, the rest 5, plus 2 per
extra cell of a big room), keeping a random subset of the template's spawns.

**Every combat room in the island levels is an Isaac layout** (`Room_I<stage>_<variant>`, 504 templates):
Plains draws from the Basement, Forest from the Cellar, Goblin Camp from the Burning Basement, Caves from the
Caves, the Bamboo Isle from the Catacombs, Shark Waters from the Flooded Caves (pits become water), Troy from
the Depths, the Mines from the Dank Depths. Start, boss, treasure, shop, secret and Keep rooms are still ours.
The old hand-made `Room_A..E`, `Room_Pits` and `Water_*` stay in the file as fallbacks only.

## 5. Treasure rooms and items

Every floor has one treasure room, a square island with a single **pedestal** in the centre. Stepping on the
pedestal takes the item. Items are passive and stack for the whole run. The boss also drops one item from the
boss pool.

**[built]** 20 pool items plus 6 boss items, all icons from Admurin's Premium item packs (32 px singles at 2x,
`assets/images/items/`). Boss items never enter the treasure or shop pools: the level's boss leaves its item on a
pedestal when it dies (Plains: Troll Skin, Forest: Bear Claw, Goblin Camp: Shaman Charm, Caves: Minotaur Horns,
Shark Waters: Harpoon, Troy: Black Crown; the Bamboo Isle, the Mines and the Keep drop a pool item). Once the
hero owns the boss item, that boss drops a pool item instead; if the pool has run dry, meat and a purse of coins.
`/packs` in the console rebuilds the floor as a gallery of every item on pedestals. Twin Shot's second swing
shares the first swing's hit list, so on melee heroes it widens the arc instead of doubling damage.

| Category | Item | Effect |
|----------|------|--------|
| Damage | Sharpened Arrowheads | +1 damage |
| Damage | Goblin Torch | attacks set enemies on fire (2 s burn); lit arrows still chop campfires |
| Damage | Twin Shot | fire two projectiles or swings in a narrow spread |
| Damage | Heavy Shot | +2 damage, -20 % fire rate |
| Damage | Bear Claw (boss item, Forest) | melee hits knock enemies back twice as far |
| Fire rate | Quiver Oil | -25 % cooldown |
| Range | Longbow String | +40 % range |
| Movement | Boots of the Thief | +20 % move speed |
| Movement | Water Walker | wade across water pits (any water not joined to the sea) |
| Health | Sheep Meat | +1 max HP and full heal |
| Health | Second Wind | revive with 3 half-hearts; stacks, and the lives left show as an icon and "x1" right after the HP bar |
| Utility | Bomb Sack | +5 bombs |
| Utility | Key Ring | +2 keys |
| Utility | Gold Nose | 50 % more gold from every drop |
| Utility | Merchant's Ledger | shop prices -30 % |
| Special | Campfire Heart | a campfire on first entry to every combat room |
| Special | Magic Mushroom | +1 HP, +1 damage, faster, and bigger |
| Special | Shaman Charm (boss item, Goblin Camp) **[built]** | 1 in 10 hits turns a regular enemy into a harmless Update 010 sheep that wanders, bolts from you, and sometimes drops meat; sheep never hold the doors shut. Bosses, flyers and swimmers are immune |
| Special | Minotaur Horns (boss item, Caves) | push against a wall for 1 s to charge away from it; the charge bowls through enemies for 3 damage and can't be hurt |
| Special | Troll Skin (boss item, Plains) | explosions can't hurt you, fire can't burn you |
| Special | Harpoon (boss item, Shark Waters) **[built]** | hits reel non-boss enemies toward you |
| Special | Black Crown (boss item, Troy) **[built]** | Troy's black units only land every other blow on you |
| Active (Space) | Lucky Coin | press Space in any room with an untaken pedestal (treasure, boss drop, secret) to reroll it; recharges one tick per cleared room, full at 3. Active items sit in the Space slot at the bottom-left (icon, charge bar); picking up another active swaps it and returns the old one to the pool |

### Familiars

Isaac-style followers: an item that spawns a small companion which trails the player (a smoothed follow, 40 px
behind, never blocks anything) and does one thing on its own. Under the art rule they are Tiny Swords sheets
drawn at **0.5x**: a 35 px body reads as a "baby" next to the 70 px hero.

| Familiar | Sprite (Enemy Pack at 0.5x) | Behaviour |
|----------|-----------------------------|-----------|
| Panda Cub **[built]** | Panda | swipes enemies that touch the player, 1 dmg |
| Bone Buddy **[built]** | Skull | fires a bone every 1.5 s at the nearest enemy, 1 dmg |
| Little Soldier | Update 010 Pawn | blocks one projectile per room, then hides for 5 s |
| Snake Charm | Snake | bites and poisons (1 dmg over 3 s) |
| Spider Egg | Spider | drops a web on hit enemies, slowing them |
| Bee Jar | Bumblebee | stings the nearest enemy every 2 s, 1 dmg |
| Pocket Turtle | Turtle | walks between the hero and the nearest shooter and soaks one shot per room |

Familiars stack (up to 4 on screen, in a conga line) and count as items for MY STUFF. Their pedestal icons come
from the Admurin packs like every other item (panda plushie, bone).

Item sprites **[built]**: Admurin Premium item-pack singles (32 px, shown at 2x) floating over the stone
pedestal. Each item shows a name card for 2 s on pickup. The pause screen's MY STUFF lists every icon owned.

Existing pickups **[built]**: meat (heal 1), gold, bombs, keys. Clearing a combat room has a 75 % chance to
drop a key, a gold burst, or a bomb; meat comes from the treasure room, secret rooms, and shops.

## 6. Shops

**[built]** A shop room is a dead end behind a locked door (costs one key; walk up to the barred door with a
key and it opens for the run). Inside, a merchant tent (Fish Hut from the Enemy Pack) with three to four items
on a table, priced in gold:

| Stock slot | Contents | Price |
|------------|----------|-------|
| 1 | meat (1 HP) | 5 |
| 2 | bomb ×2 or key ×1 | 8 |
| 3 | random item from the shop pool (any non-boss item) | 15 to 25 |
| 4 | floor 2 onward: second random item | 15 to 25 |

Gold comes from room-clear bursts and broken gold stones (Gold Nose adds 50 % to both). The floating **shop
raft** between levels uses the same stock but at +5 gold and no key needed. Merchant's Ledger takes 30 % off
every price, island or raft. The final floor has no shop.

## 6a. Options

**[built]** An Options screen off the title menu, saved in one shared options file independent of the save slots:

| Option | What it does |
|--------|--------------|
| Master, Music, Sounds, Ambience | four volume bars with - / + (master also on `[` / `]` in a run and `/volume N`) |
| Fullscreen | desktop only; the browser build shows it greyed out |
| Screen shake | every camera shake goes through `fx.Juice.shake`, which this switches off |
| Reduce flashing | no lightning flashes in storms and no explosion light bursts |
| Gamepad | first pad: left stick / d-pad move, right stick aims and fires, X bomb, Y active item (Space on keyboard), LB/RB block, Back map, Start pause. Every menu takes the d-pad or stick (nearest button in that direction), A confirms, B backs out |
| Controls | key rebinding for the twelve keyboard actions (move, aim, bomb, item, block/roll, map), stored with the options; Escape always pauses |

### Dev console **[built]**

Backtick opens it in a run. Commands: `/boss` `/treasure` `/shop` `/combat` `/secret` `/next` `/floor` `/item [id]`
`/heal` `/gold` `/bombs` `/keys` `/god` `/kill` (slays through shields, shells and submersion) `/unlocks`
`/unlockall` `/slots` `/raft` `/map` `/block` `/bossname <id>` `/spawn <kind>` (pig, gnome, snake, bee, slingshot,
spear, elite, barrel, cannon, tnt, thief, skull, imp, guard, bat, torch, archer, monk, turtle, pandaguard, sheep,
harpoonshark, paddleshark, bombfish, tower, rider, knight, lancer, pawn, blacktower, gnometower, goldmine)
`/campfire` `/packs` (rebuilds the floor as the item gallery) `/resume` (reload this floor's checkpoint)
`/volume N` `/sfxtest`. The browser build also takes URL flags (`?play`, `?bossroom`, `?treasure`, `?shop`,
`?combat`, `?level=N`, `?floor=N`, `?hero=`, `?god`, `?seed=N`, `?bamboo` (unlocks every extra level), `?packs`,
`?options`, `?select`, `?slots`); the Mac binary boots the gallery with `PACKS=1`.

## 6b. UI kit

The game's own paper panels stay for the HUD and pause menu. The Update 010 UI kit fills the rest:

- **Ribbons** (blue, red, yellow): the level name card during the boat sail or cave walk ("FOREST I"), and
  the boss name on the intro card.
- **Banners** (carved, horizontal, vertical, with connectors): the shop price tags and the item name card on
  pickup.
- **Buttons** (blue and red, regular and pressed, 3- and 9-slice): the menu, character select, and the
  game-over and victory screens.
- **Icons** (10 icons, regular, pressed, and disabled states): shop stock slots and the unlock screen, with the
  disabled state for locked heroes and levels.
- **Pointers**: the shop and menu cursor.

## 7. Bosses

Each boss has two phases split at half HP and a summon or hazard in phase 2. **[built]** HP scales from a per-boss
base by 1 + 0.25 per floor + 0.35 per level, and a beaten boss leaves its level's boss item on a pedestal
(section 5).

### Boss intro card **[built]** (`ui/BossCard.hx`; portraits in `assets/images/avatars`)

Entering a boss room freezes play and shows an intro card, Isaac-style, with a Borderlands-style gag caption
under the name. Every Enemy Pack enemy ships a 256 px avatar portrait; the Black units' portraits are cut from
their sheets. The card plays in full (2.4 s) the first time a boss is met and as a 0.9 s nod afterwards, per
save slot. Any key skips it. The boss HP bar appears when the card leaves.

| Boss | Name line | Caption |
|------|-----------|---------|
| Troll | THE TROLL | Has never once read the comments. |
| Gnoll | THE GNOLL | Half dog, half problem. |
| Giant Torch Goblin | BIG TORCH | Compensating for something. |
| Bear | THE BEAR | Woke up on the wrong side of the forest. |
| Lizard | THE LIZARD | Cold-blooded. Colder personality. |
| Spider | THE SPIDER | Eight legs, zero chill. |
| Harpoon Shark | HARPOON SHARK | Jaws, but with a day job. |
| Paddle Shark | PADDLE SHARK | Brought a paddle to a sword fight. |
| Bomb Fish | BOMB FISH | Sushi with a short fuse. |
| Minotaur | THE MINOTAUR | Lost in a maze of his own bad decisions. |
| Skull Guard | SKULL GUARD | Dead inside. Also outside. |
| Giant Bat | THE GIANT BAT | Afraid of the light. Also of you, but hiding it. |
| Hex Shaman | HEX SHAMAN | Turned his last therapist into a sheep. |
| Pig Rider Warlord | PIG RIDER WARLORD | This little piggy went to war. |
| Goblin Hut | THE HUT | Home is where the hoard is. |
| Panda | THE PANDA | Eats, shoots, and leaves. Mostly eats. |
| Panda Guard | PANDA GUARD | Bamboo in, nothing out. |
| Black King (Keep) | THE BLACK KING | Heavy is the head. Heavier is the armour. |
| Black Captain | THE BLACK CAPTAIN | Follows orders. Gives worse ones. |
| Black Champion | THE BLACK CHAMPION | Brought a lance to a pig fight. |
| Black Abbot | THE BLACK ABBOT | Prays for you. Preys on you. |
| Gnome Tower | THE GNOME TOWER | Small hats, tall problems. |
| Giant Slingshot | GIANT SLINGSHOT | Nuts about you. |
| Turtle Guard | TURTLE GUARD | Slow to anger. Slower to leave. |

Captions live in one table in code (`ui/BossCard.hx`) so they are easy to rewrite.

- **Troll (Plains)**: slow, directional club slam, stomp shockwave that shoves you to the arena edge.
- **Gnoll (Plains)**: bone thrower, hops away, 3-bone fan.
- **Giant Torch Goblin (Plains)**: a 2x torch goblin that leaves burning trails and torch-dashes.
- **Bear (Forest)**: chase, rear-up claw slam, enrage at half HP.
- **Lizard (Forest)**: spits acid globs that puddle, sheds a decoy tail at half HP.
- **Spider (Forest)**: dashes, spawns spiderlings in phase 2.
- **Harpoon Shark (Shark Waters)**: surfaces by the shore and throws a harpoon that pins the hero for half a
  second; two harpoons once bloodied.
- **Paddle Shark (Shark Waters)**: surfaces by the shore, leaps onto the islet and paddle-slams, then dives;
  bloodied it leaps twice and each slam floods a row of tiles with water for 3 s.
- **Bomb Fish (Shark Waters)**: surfaces and spits a lit bomb where the hero stands (2 s fuse); three bloodied.
- **Hex Shaman (Goblin Camp)**: keeps distance; its signature attack is the **sheep hex**: a slow, visible spell
  bolt that turns the player into a sheep for 4 s (40 % speed, drunk steering, no attacks; damage ends it early).
- **Pig Rider Warlord (Goblin Camp)**: mounted charges, then on foot as an elite with the strong-attack thrust.
- **Goblin Hut (Goblin Camp)**: a fortified hut that cannot be hurt; six waves of 5 to 10 goblins, survive them
  all and it collapses.
- **Minotaur (Caves)**: telegraphed charge across the chamber, stuns itself on the stone walls.
- **Skull Guard (Caves)**: fast, blinks around the room, shield blocks everything from the front and it only
  re-aims every 0.9 s, raises skulls.
- **Giant Bat (Caves)**: swoops in arcs and screeches to call bats.
- **Panda (Mystic Bamboo Isle)**: two-hit combo, a wall-bouncing roll, calls two Panda Guards at half HP.
  Beating it unlocks the Panda as a hero.
- **Panda Guard (Mystic Bamboo Isle)**: armoured, slower, blocks frontal hits; only a blast opens it up (2 s);
  calls a second guard at half HP.
- **Black King (Final, The Keep)**: the Free Pack Black Warrior at 2x holding the summit courtyard. Its shield
  blocks everything from the front unless it is mid-swing, so the fight is flanking and baiting swings. Every few
  seconds it braces and charges. Phase 2 it calls two Black Archers and a Black Monk that heals it until killed.
  The harder form (after 9 wins) adds the Black Champion.
- **Black Captain (Troy)**: the King's shield and charge at 1.6x, no court.
- **Black Champion (Troy)**: the Black Lancer at 2x; long thrusts and lance charges across the courtyard,
  faster and charging twice as often once bloodied.
- **Black Abbot (Troy)**: a Black Monk that never attacks; it keeps an escort of knights and lancers, raises a
  fresh one whenever the escort thins, and blinks away when the hero gets close.
- **Gnome Tower (Gnome Mines)**: a spawner; five waves of gnomes (slingshots from wave 3), falls after the last.
- **Giant Slingshot (Gnome Mines)**: a Slingshot Gnome at 2x that kites and fires a three-acorn fan (five bloodied).
- **Turtle Guard (Gnome Mines)**: tucked in its shell it crawls after you and can't be hurt; every few seconds it
  pops out to bite, which is the window.

## 8. Meta progression (Isaac-style unlocks)

Runs are tracked in a small save file per slot. Unlocks are permanent.

| Unlock | Condition |
|--------|-----------|
| Knight, Lancer, Monk | see section 3 |
| Level 5, Mystic Bamboo Isle **[built]** | beat the final boss once; unlocked levels slot in after the Caves, before the Keep |
| Panda hero **[built]** | defeat the Panda boss (level 5) |
| Level 6, Shark Waters **[built]** | beat the final boss 3 times |
| Level 7, Troy **[built]** | beat the final boss 5 times |
| Level 8, Gnome Mines **[built]** | beat the final boss 7 times |
| Black King's harder form | beat the final boss 9 times |
| New items enter the pool | beat a run with each hero (one batch of items per hero) |
| Secret rooms | always on (every floor has one; the unlock was dropped) |

Beating the final boss ends the run with a victory screen and the tally of wins.

## 9. Difficulty curve

- Enemy count per combat room: the template's spawns under the level's cap (section 4), +1 from floor II on.
- Enemy HP: base values (torch goblin 3) times 1.0 on levels 1 to 2, 1.5 on levels 3 to 4, 2.0 after.
- Player damage grows only through items, so item pickup is mandatory, not optional.

## 9b. Built bosses and enemies (code status)

All levels roll from a pool of three bosses (one for the Keep), never repeating the previous floor's boss:

| Level | Bosses built | Regular enemies built | Art status |
|-------|--------------|------------------------|------------|
| Plains | Troll, Gnoll, Giant Torch Goblin | Torch Goblin, TNT Goblin, Pig | all Tiny Swords |
| Forest | Bear, Lizard, Spider | Gnome, Bumblebee, Snake, Slingshot Gnome | all Tiny Swords |
| Goblin Camp | Hex Shaman, Pig Rider Warlord, Goblin Hut | Spear Goblin, Spear Goblin Elite (floor II), Torch Goblin, Barrel Goblin, Pig, Cannon, TNT Goblin | all Tiny Swords |
| Caves | Minotaur, Skull Guard, Giant Bat | Skull, Imp, Thief, Minotaur Guard, Bat, Turtle | all Tiny Swords |
| The Keep | Black King | mixed wave from every level | all Tiny Swords |
| Mystic Bamboo Isle | Panda, Panda Guard | Thief, Snake, Turtle, Panda Guard, Bumblebee, Slingshot Gnome | all Tiny Swords, blossom-tinted tiles and trees |
| Shark Waters | Harpoon Shark, Paddle Shark, Bomb Fish | the same three as regulars (submerged and unhittable until they surface), Seahorse Boat riders (harpoon and bomb variants, always on the water), Pirate Tower turret; Thief, Snake, Turtle on the islets | all Tiny Swords; Isaac Flooded Caves layouts |
| Troy | Black Captain, Black Champion, Black Abbot | Black Knight (front shield), Black Lancer (3-way thrusts), Black Archer, Black Monk (heals the nearest unit), Black Pawn (flees, drops gold), Black Tower turret; Barracks release a knight on entry | all Tiny Swords, grey stone courtyards |
| Gnome Mines | Gnome Tower, Giant Slingshot, Turtle Guard | Gnome, Slingshot Gnome, Turtle, Minotaur Guard, Bat, Gnome Tower turret, Gold Mine, Gnome Hut releases a gnome on entry | all Tiny Swords, gold-tinted tiles, extra gold stones |

Boss HP scales by 1 + 0.25 per floor + 0.35 per level. Saves: three profile slots, each with its own unlocks and a
run checkpoint written at the start of every floor (level list, level, floor, boss history, seed, item pool,
stats, active item charge, weather, run summary); dying or winning clears the checkpoint. Bombs deal 3 damage
once per target. Room clears drop a key, gold burst, or bomb 75 % of the time. Outdoor floors roll clear, rain,
or storm weather with matching ambience.

## 10. Open questions

- Should the Monk's heal be per cleared room or per floor? Per room may be too strong.
- The Mystic Bamboo Isle has no bamboo in Tiny Swords: the canopy is recoloured Update 010 trees on a
  blossom-tinted tileset; bamboo walls become dense tree lines unless a cluster gets drawn in Aseprite.
- The item pedestal is the last non-Tiny-Swords prop. Keep it as item furniture, or draw a stand?

## 11. Implementation order

1. Treasure room pedestal and the first 8 items. **[built]**
1b. Familiars: follower class plus the first two (Panda Cub, Bone Buddy). **[built]**
2. Shop room, key-locked door, gold prices. **[built]**
3. Boat transition and the two-floor structure with the floor counter. **[built]**
4. Forest level. **[built]**
5. Save file and hero unlocks. **[built]**
6. Goblin Camp and Caves. **[built]**
7. The Keep: elevation tiles and tiered collision, then the final boss. **[built]** A full generated floor like
   the others, but with 23x13 rooms the camera scrolls inside. Each room template carries a Height layer: raised
   plateaus, cliff faces that block from below and let you drop off from above, and stairs as the only way up.
8. Sound, music, weather, secret rooms, map, saves with three slots, boss intro cards, boss HP scaling. **[built]**
9. Items: the 20-item pool, boss items with boss-drop pedestals, the Space active-item slot (Lucky Coin),
   extra lives on the HUD, the `/packs` gallery. **[built]**
10. Options screen: four volume bars, fullscreen, screen shake, reduce flashing, gamepad. **[built]**

## 12. Next steps — all eight done on 2026-09-26; what is left is listed under 13

1. **Tiny Swords art pass** (section 2b). **[done]**
2. **Playtest tuning pass**: boss HP curve gentler, Twin Shot on melee widens instead of doubling. **[done]**
3. **Shaman Charm**. **[done]**
4. **Mystic Bamboo Isle and the Panda hero**. **[done]**
5. **Shark Waters** with the Harpoon boss item live. **[done]**
6. **Troy and the Gnome Mines**; Black Crown and the Gold Mine spawner. **[done]**
7. **Controls and menus**: gamepad navigation on every screen; key rebinding. **[done]**
8. **Audio**: seven more FilmCow families (splash, bubble, buzz, golem step, wing, rope, roar). **[done]**

### Finishing touches **[built]**

Credits screen off the title menu (art, icons, sound, music, Isaac layouts, controls). Boss intro cards play
in full the first time a boss is met and as a 0.9 s nod afterwards. The game-over screen shows a run summary
(hero, floors, time, kills, hearts lost, items) and on death who or what killed you and where.

### Bug pass 2026-09-26 **[done]**

Headless sweep over every level with two seeds each: enter every room, clear it, kill the boss, sail on, resume
the checkpoint. Fixed: the bush template letter had replaced the boss marker (boss rooms spawned a bush); sheep
and pawns counted toward the Goblin Hut and Gnome Tower waves; Panda Guards and sharks used as regular units
were immune to the sheep hex and the harpoon like real bosses; flyers and swimmers could be hexed into a sheep
mid-air or mid-water; the spawn cap used a map keyed by anonymous objects (unsafe on the Mac build); a boss whose
pool item ran out dropped nothing (now meat and a purse); `/kill` could not kill shielded, shelled or submerged
bosses (now `slay()`); debug boots into a later level started with an empty item pool.

## 13. What is left

- **Playtesting.** Every level and boss above was verified headlessly (rooms build, enemies spawn and cycle,
  bosses reach phase 2, items apply, doors of big rooms connect), not by a human. The numbers (boss HP curve,
  enemy caps, Twin Shot, prices, the recharge of 3 rooms) are first guesses.
- **Gamepad hardware.** The bindings are wired but no controller was plugged in during this session.
- **Music.** Still three loops; a track per level and a shop track need the rest of the pirate pack.
- **Room file.** 3.2 MB after compacting; drop the fallback hand-made rooms if it needs to shrink further.
- **Sheep bleat.** Now two synthesized bleats (ffmpeg, vibrato sine stack); replace with a recording if one turns up.
- The Pirate Tower's water variant is unused. Troy's Archery range and the Black Pawn as a hero-class enemy were
  folded into the Black Tower turret and the fleeing villager.
