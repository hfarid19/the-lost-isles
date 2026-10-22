# Sound effect catalogue

Three packs in Downloads. Files copied into the game live in `assets/sounds/` as OGG (html5 and native both
play OGG; WAVs from FilmCow get converted on import). Playback goes through `fx/Sfx.hx`, which picks a random
variant from a family and pitches it a little so repeats don't sound identical.

| Pack | Files | Format | Licence | Fit |
|------|-------|--------|---------|-----|
| Free Fantasy SFX Pack by TomMusic | 408 (204 OGG + 204 WAV) | 44.1 kHz stereo OGG | free; readme asks nothing, credit appreciated | **Core pack.** Game-ready fantasy combat, doors, footsteps, spells, torches, plus ambience loops. |
| FilmCow Recorded SFX | 3816 | 48 kHz mono 24-bit WAV | FilmCow's free-for-any-use library | **Foley.** Raw recordings; the physical ones (wood, rocks, splashes, cloth, punches, screams) cover props and enemies. Most of it is household junk. |
| FilmCow Designed SFX | 239 | WAV | same | **Mostly unusable.** Sci-fi: lasers, robots, aliens. A few stingers and thumps work for bosses. |

## Wired in now (`assets/sounds/`)

| Game event | Family | Source |
|------------|--------|--------|
| Archer shoots | `bow_shot` | TomMusic Bow Attack 1-2 |
| Arrow hits enemy | `arrow_hit` | TomMusic Bow Impact Hit 1-3 |
| Arrow hits rock, tree, hut | `arrow_block` | TomMusic Bow Blocked 1-3 |
| Knight swing, Lancer thrust | `sword_swing` | TomMusic Sword Attack 1-3 |
| Melee hits enemy | `sword_hit` | TomMusic Sword Impact Hit 1-3 |
| Knight shield deflects | `parry` | TomMusic Sword Parry 1-3 |
| Player takes damage | `player_hurt` | FilmCow oof 1-6 |
| Player dies | `player_die` | FilmCow scream 1-3 |
| Enemy takes damage | `enemy_hit` | FilmCow punch flesh 1-6 |
| Enemy dies | `enemy_die` | FilmCow body fall 1-4 |
| Bomb planted | `fuse` | TomMusic Light Torch 1 |
| Explosion | `explosion` | TomMusic Rock Meteor Throw 1-2 |
| Bush chopped | `bush` | TomMusic chop 1-4 |
| Gold stone breaks | `stone_break` | TomMusic mine 1-5 |
| Coin picked up | `coin` | FilmCow glass ding 1-4 |
| Item pedestal taken | `item` | TomMusic Firebuff 1 |
| Meat eaten | `eat` | FilmCow gulp 1-3 |
| Key picked up / spent | `key` | TomMusic Lock Unlock |
| Shop purchase | `buy` | TomMusic Chest Open 1 |
| Can't afford | `deny` | FilmCow clicky button 1 |
| Door locks (room entered) | `door_lock` | FilmCow rock 1-3 (the barricade rocks drop in) |
| Doors unlock (room cleared) | `door_open` | FilmCow rocks handle 1-3 (rocks roll aside) |
| Boat docks / sail | `boat` | FilmCow water splashing small 1-3 |
| Cave mouth rises | `rumble` | FilmCow rumbling 1-3 |
| Campfire lights an arrow | `torch` | TomMusic Torch Attack Strike 1-2 |
| Boss stomp / slam | `stomp` | FilmCow big distant thump 1-3 (Designed) |
| Boss charge wind-up | `snort` | FilmCow gas canister shaking 1-2 |
| Hex Shaman bolt / sheep hex | `spell` | TomMusic Spell Impact 1-3 / Ice Freeze 1 |
| Fire breath, imp flame, fire trail | `fire` | TomMusic Firespray 1-2 |
| Cannon fires | `cannon` | FilmCow gun fired no bullets 1-3 |
| Acid glob lands | `acid` | FilmCow squishy and wet 1-3 |
| Skull Guard blink | `blink` | TomMusic Ice Throw 1 |
| Sheep hex bleat | `sheep` | two synthesized bleats (ffmpeg vibrato sine stack), sheep_1-2 |
| UI button | `ui` | FilmCow button pressed 1-3 |
| Floor name card | `stinger` | FilmCow deep sci fi stinger 1 (Designed) |
| Shark surfaces / dies | `splash` | FilmCow splash 14-15, water splashing small 26 |
| Shark dives | `bubble` | FilmCow bubbles 4-5 |
| Bumblebee attack | `buzz` | FilmCow air duster 4, 5, 8 |
| Minotaur Guard swing | `golem_step` | FilmCow metal hit floor large 4-5, medium 4 |
| Bat wakes | `wing` | FilmCow flag 4-6 |
| Boat casts off | `rope` | FilmCow rope let go 1-3 |
| Boss phase 2 (King, Panda) | `roar` | FilmCow Designed space horn 2, 4, 5 |

## Ambience loops (TomMusic BGS Loops), one per level

| Level | Loop |
|-------|------|
| Plains | Beach |
| Forest | Forest Day (Forest Night on floor II) |
| Goblin Camp | Beach + Torch Loop under it |
| Caves | Cave |
| The Keep | Sea |
| Sail screen | Sea |
| Menu | Beach |

Rain and Storm variants drive the weather: each outdoor floor rolls clear, rain (25 %), or storm (12 %); the
ambience swaps to the matching variant, rain streaks fall over the screen, and storms add lightning flashes
with a distant thump for thunder.

## Music (`assets/music/`, Pirate Music Pack Vol. 2 by alkakrab)

The "10 tracks" download only contained three loops. Wired through `Sfx.music()`, which crossfades:

| Track | Used for |
|-------|----------|
| Silent Harbor | title screen, Plains |
| Hidden Booty | Forest, Goblin Camp |
| Foggy Shores | Caves, The Keep, every boss room |

Buy or download the rest of the pack (or the Takasu Pirate/Voyage pack) to give each level and the shop their
own track; add a row to the `music()` switch in PlayState per level.

## Not yet wired, good matches for planned content

| Planned thing | Family | Source |
|---------------|--------|--------|
| Footsteps (per level surface) | dirt / stone / water / wood | TomMusic Footsteps, 5 walk + 5 run each, plus chain-armour versions for the Knight |
| Wooden fence hit, crate | `wood_hit` | FilmCow wood hit 1-32, crate open |
| Treasure chest (Cainos chest) | `chest` | TomMusic Chest Open / Close |
| Shop door with key | `unlock` | TomMusic Lock Unlock, Door Open |
| Bat wake | `flap` | FilmCow umbrella opening |
| Skeleton rattle | `bones` | FilmCow rocks handle (low) |
| Troll club drag | `drag` | FilmCow metal dragged on floor |
| Minotaur wall stun | `crash` | FilmCow crashing through debris |
| Pig charge | `pig` | none; FilmCow rubber wobble as a joke placeholder |
| Panda cub swipe | `swipe` | FilmCow cleaver |
| Bone buddy throw | `throw` | FilmCow woosh 1-25 |
| Cliff drop (Keep) | `land` | TomMusic Dirt Land / Stone Land |
| Stairs (Keep) | `stairs` | TomMusic Stone Walk |
| Ice items / spells | `ice` | TomMusic Ice Barrage, Ice Wall, Ice Freeze |
| Water spells | `water` | TomMusic Waterspray, Wave Attack |
| Boss intro card | `stinger_big` | FilmCow Designed deep sci fi stinger 4-8, space horn |
| Level up / unlock toast | `fanfare` | none; TomMusic Firebuff 2 as a placeholder |
| Menu music | none in these packs; TomMusic sells music separately |

## Skip

FilmCow Designed's aliens, robots, lasers, computers, and "bug people" have no home in a fantasy island game.
FilmCow Recorded's office, kitchen, bathroom, car, and phone recordings likewise.
