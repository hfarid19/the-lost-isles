#!/usr/bin/env python3
"""Generate assets/levels/rooms.ldtk (LDtk 1.5.3) from ASCII room templates.

Legend:  '.' water   '#' grass
Entities (placed on grass): P player, T torch goblin, N tnt goblin,
                            B boss, M meat pickup, G gold pickup, I item pedestal
Rooms are 15x9 tiles @64px. Outer ring is water; door cells are
(7,0) N, (14,4) E, (7,8) S, (0,4) W — kept water here, bridged at runtime.
"""
import json, uuid, os, sys

TILE = 64
W, H = 15, 9

ROOMS = {
    # First floor: every room is a plain square island. Rooms differ only in
    # where enemies stand; Room_Pits adds four 2x2 water pits.
    "Room_Start": [
        "...............",
        ".#############.",
        ".#############.",
        ".#############.",
        ".######P######.",
        ".#############.",
        ".#############.",
        ".#############.",
        "...............",
    ],
    "Room_Boss": [
        "...............",
        ".#############.",
        ".#############.",
        ".#############.",
        ".######B######.",
        ".#############.",
        ".#############.",
        ".#############.",
        "...............",
    ],
    "Room_Treasure": [
        "...............",
        ".#############.",
        ".#############.",
        ".#############.",
        ".######I######.",
        ".#############.",
        ".#############.",
        ".#############.",
        "...............",
    ],
    "Room_Keep": [
        "...............",
        ".#############.",
        ".#############.",
        ".#############.",
        ".#############.",
        ".######B######.",
        ".###T#####T###.",
        ".######P######.",
        "...............",
    ],
    "Room_Secret": [
        "...............",
        "...............",
        "....#######....",
        "....#G#G#G#....",
        ".#############.",
        "....#M###M#....",
        "....#######....",
        "...............",
        "...............",
    ],
    "Room_Shop": [
        "...............",
        ".#############.",
        ".###H#########.",
        ".#############.",
        ".#############.",
        ".####S##S##S##.",
        ".#############.",
        ".#############.",
        "...............",
    ],
    "Room_A": [
        "...............",
        ".#############.",
        ".##T#######T##.",
        ".#############.",
        ".#############.",
        ".#############.",
        ".#############.",
        ".#############.",
        "...............",
    ],
    "Room_B": [
        "...............",
        ".#############.",
        ".#############.",
        ".###T#####T###.",
        ".#############.",
        ".######N######.",
        ".#############.",
        ".#############.",
        "...............",
    ],
    "Room_C": [
        "...............",
        ".#############.",
        ".##N#######N##.",
        ".#############.",
        ".#############.",
        ".#############.",
        ".######T######.",
        ".#############.",
        "...............",
    ],
    "Room_D": [
        "...............",
        ".#############.",
        ".#############.",
        ".####T###T####.",
        ".#############.",
        ".####T###T####.",
        ".#############.",
        ".#############.",
        "...............",
    ],
    "Room_E": [
        "...............",
        ".#############.",
        ".##T#######N##.",
        ".#############.",
        ".#############.",
        ".#############.",
        ".##N#######T##.",
        ".#############.",
        "...............",
    ],
    "Room_Pits": [
        "...............",
        ".#############.",
        ".##..#####..##.",
        ".#T..##N##..T#.",
        ".#############.",
        ".##..#####..##.",
        ".##..##T##..##.",
        ".#############.",
        "...............",
    ],
}

ENTITY_DEFS = [
    ("PlayerSpawn", "#00E436"), ("TorchSpawn", "#FF3838"), ("TntSpawn", "#FF8426"),
    ("BossSpawn", "#BE4A2F"), ("MeatSpawn", "#F5999F"), ("GoldSpawn", "#F4B41B"),
    ("ItemSpawn", "#B58BFF"), ("HutSpawn", "#8B5A2B"), ("ShopSpawn", "#3FB8AF"),
    ("CastleSpawn", "#7FA8C8"), ("RockSpawn", "#8A8A8A"), ("BushSpawn", "#3C7A32"), ("FireSpawn", "#FF7A1E"),
]
ENT_CHAR = {"P": "PlayerSpawn", "T": "TorchSpawn", "N": "TntSpawn",
            "B": "BossSpawn", "M": "MeatSpawn", "G": "GoldSpawn", "I": "ItemSpawn",
            "H": "HutSpawn", "S": "ShopSpawn", "C": "CastleSpawn",
            "R": "RockSpawn", "U": "BushSpawn", "F": "FireSpawn"}  # U = bush ('B' is the boss)
# lowercase = the same entity standing on a raised plateau cell
RAISED_ENT = {k.lower(): v for k, v in ENT_CHAR.items()}

# Keep rooms: 23x13, '^' raised plateau, '/' stair (a ground cell under a plateau edge)
KEEP_ROOMS = {
    "Keep_Start": [
        ".......................",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".##########P##########.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".......................",
    ],
    "Keep_Boss": [
        ".......................",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".#^^^^^^^^^c^^^^^^^^^#.",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".#^^^^^^^^^b^^^^^^^^^#.",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".####///#####///######.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".......................",
    ],
    "Keep_Treasure": [
        ".......................",
        ".#####################.",
        ".#####################.",
        ".######^^^^^^^^^######.",
        ".######^^^^i^^^^######.",
        ".######^^^^^^^^^######.",
        ".#########/#/#########.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".......................",
    ],
    "Keep_Secret": [
        ".......................",
        ".......................",
        ".......................",
        "......###########......",
        "......#G##G##G##G#.....",
        "......###########......",
        ".#####################.",
        "......###########......",
        "......#M#######M#......",
        "......###########......",
        ".......................",
        ".......................",
        ".......................",
    ],
    "Keep_Shop": [
        ".......................",
        ".#####################.",
        ".###H#################.",
        ".#############^^^^^^^#.",
        ".#############^s^s^s^#.",
        ".#############^^^^^^^#.",
        ".#############/#######.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".......................",
    ],
    "Keep_A": [
        ".......................",
        ".#####################.",
        ".#^^^^^^#######^^^^^^#.",
        ".#^^t^^^#######^^^t^^#.",
        ".#^^^^^^#######^^^^^^#.",
        ".#///#################.",
        ".##############T######.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#######N#####N#######.",
        ".#####################.",
        ".......................",
    ],
    "Keep_B": [
        ".......................",
        ".#####################.",
        ".####T#########T######.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".#^^^^n^^^^^^^^^n^^^^#.",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".########//#//########.",
        ".......................",
    ],
    "Keep_C": [
        ".......................",
        ".#####################.",
        ".########^^^^^########.",
        ".########^^n^^########.",
        ".########^^^^^########.",
        ".####T###/###/###T####.",
        ".#####################.",
        ".#####################.",
        ".########^^^^^########.",
        ".########^^t^^########.",
        ".########^^^^^########.",
        ".#########/#/#########.",
        ".......................",
    ],
    "Keep_D": [
        ".......................",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".#^^^^^^^^^^^^^^^^^^^#.",
        ".#^^n^^^^^^^^^^^^^n^^#.",
        ".#///#############///#.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####################.",
        ".#####T#######T#######.",
        ".#####################.",
        ".......................",
    ],
}
ROOMS.update(KEEP_ROOMS)

# Shark Waters: islets joined by sandbars; enemies attack from the water around them
WATER_ROOMS = {
    "Water_A": [
        "...............",
        ".....###.......",
        ".###.#T#..###..",
        ".#T########N#..",
        ".###...###..#..",
        "..#....#N#..#..",
        "..######T####..",
        "......###......",
        "...............",
    ],
    "Water_B": [
        "...............",
        "..###..#..###..",
        "..#T####..#T#..",
        "..##.....##.#..",
        ".####..######..",
        "..##..###..##..",
        "..#N####..#T#..",
        "..###..#..###..",
        "...............",
    ],
    "Water_C": [
        "...............",
        ".#####.#.#####.",
        ".#T#########T#.",
        ".#####.#.#####.",
        "..#.........#..",
        ".#####.#.#####.",
        ".#N#########N#.",
        ".#####.#.#####.",
        "...............",
    ],
    "Water_D": [
        "...............",
        "....#..#..#....",
        "..#####T#####..",
        "..#T#..#..#N#..",
        ".############..",
        "..#N#..#..#T#..",
        "..###########..",
        "....#..#..#....",
        "...............",
    ],
}
ROOMS.update(WATER_ROOMS)

# Isaac imports: generated by `tools/isaac_rooms.py export` into tools/isaac_templates.py
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from isaac_templates import ISAAC_ROOMS
ROOMS.update(ISAAC_ROOMS)

def iid():
    return str(uuid.uuid4())

UID = 100
def uid():
    global UID
    UID += 1
    return UID

TILESET_UID = 1
LAYER_ENT_UID, LAYER_COL_UID, LAYER_GND_UID, LAYER_HGT_UID = 2, 3, 4, 5

def entity_def(i, name, color):
    return {
        "identifier": name, "uid": 10 + i, "tags": [], "exportToToc": False,
        "allowOutOfBounds": False, "doc": None, "width": TILE, "height": TILE,
        "resizableX": False, "resizableY": False, "minWidth": None, "maxWidth": None,
        "minHeight": None, "maxHeight": None, "keepAspectRatio": False,
        "tileOpacity": 1, "fillOpacity": 1, "lineOpacity": 1, "hollow": False,
        "color": color, "renderMode": "Rectangle", "showName": True,
        "tilesetId": None, "tileRenderMode": "FitInside", "tileRect": None,
        "uiTileRect": None, "nineSliceBorders": [], "maxCount": 0,
        "limitScope": "PerLevel", "limitBehavior": "MoveLastOne",
        "pivotX": 0, "pivotY": 0, "fieldDefs": [],
    }

# Same 16-case NESW blob mapping as Room.hx MASK_TO_TILE (index = neighbor
# mask N=1,E=2,S=4,W=8; value = tileId in tilemap_flat, row*10+col).
MASK_TO_TILE = [33, 23, 30, 20, 3, 13, 0, 10, 32, 22, 31, 21, 2, 12, 1, 11]

def autotile_rules():
    rules = []
    for mask in range(16):
        # 3x3 pattern, row-major: [NW,N,NE,W,C,E,SW,S,SE]; 1=require grass,
        # -1=require not-grass, 0=any. Corners ignored, center must be grass.
        pat = [0] * 9
        pat[4] = 1
        pat[1] = 1 if mask & 1 else -1
        pat[5] = 1 if mask & 2 else -1
        pat[7] = 1 if mask & 4 else -1
        pat[3] = 1 if mask & 8 else -1
        rules.append({
            "uid": 300 + mask, "active": True, "size": 3,
            "tileRectsIds": [[MASK_TO_TILE[mask]]], "alpha": 1, "chance": 1,
            "breakOnMatch": True, "pattern": pat, "flipX": False, "flipY": False,
            "xModulo": 1, "yModulo": 1, "xOffset": 0, "yOffset": 0,
            "tileXOffset": 0, "tileYOffset": 0, "tileRandomXMin": 0,
            "tileRandomXMax": 0, "tileRandomYMin": 0, "tileRandomYMax": 0,
            "checker": "None", "pivotX": 0, "pivotY": 0,
            "outOfBoundsValue": None, "invalidated": True,
            "perlinActive": False, "perlinSeed": 100 + mask,
            "perlinScale": 0.2, "perlinOctaves": 2,
        })
    return [{"uid": 299, "name": "Grass blob", "active": True,
             "isOptional": False, "rules": rules, "usesWizard": False,
             "color": None, "icon": None, "biomeRequirementMode": 0,
             "requiredBiomeValues": []}]

def layer_def(identifier, luid, typ, intgrid_values=None):
    d = {
        "__type": typ, "identifier": identifier, "type": typ, "uid": luid,
        "doc": None, "uiColor": None, "gridSize": TILE, "guideGridWid": 0,
        "guideGridHei": 0, "displayOpacity": 1, "inactiveOpacity": 0.6,
        "hideInList": False, "hideFieldsWhenInactive": True, "canSelectWhenInactive": True,
        "renderInWorldView": True, "pxOffsetX": 0, "pxOffsetY": 0, "parallaxFactorX": 0,
        "parallaxFactorY": 0, "parallaxScaling": True, "requiredTags": [], "excludedTags": [],
        "autoTilesKilledByOtherLayerUid": None, "uiFilterTags": [], "useAsyncRender": False,
        "intGridValues": [], "intGridValuesGroups": [], "autoRuleGroups": [],
        "autoSourceLayerDefUid": None, "tilesetDefUid": None, "tilePivotX": 0, "tilePivotY": 0,
        "biomeFieldUid": None,
    }
    if intgrid_values:
        d["intGridValues"] = [
            {"value": v, "identifier": name, "color": color, "tile": None, "groupUid": 0}
            for (v, name, color) in intgrid_values
        ]
    return d

def grid_csv(rows, pred):
    return [1 if pred(c) else 0 for r in rows for c in r]

def layer_instance(level, identifier, luid, typ, csv=None, entities=None, tileset=False, w=None, h=None):
    return {
        "__identifier": identifier, "__type": typ, "__cWid": w or W, "__cHei": h or H,
        "__gridSize": TILE, "__opacity": 1, "__pxTotalOffsetX": 0, "__pxTotalOffsetY": 0,
        "__tilesetDefUid": TILESET_UID if tileset else None,
        "__tilesetRelPath": "../images/tiles/tilemap_flat.png" if tileset else None, "iid": iid(),
        "levelId": level, "layerDefUid": luid, "pxOffsetX": 0, "pxOffsetY": 0,
        "visible": True, "optionalRules": [], "intGridCsv": csv if csv is not None else [],
        "autoLayerTiles": [], "seed": 1, "overrideTilesetUid": None,
        "gridTiles": [], "entityInstances": entities if entities is not None else [],
    }

def entity_instance(name, defUid, cx, cy):
    return {
        "__identifier": name, "__grid": [cx, cy], "__pivot": [0, 0],
        "__tags": [], "__tile": None, "__smartColor": "#FFFFFF",
        "__worldX": None, "__worldY": None,
        "iid": iid(), "width": TILE, "height": TILE, "defUid": defUid,
        "px": [cx * TILE, cy * TILE], "fieldInstances": [],
    }

# Cells just inside each door (and one further) must be grass so bridges land
# on walkable ground: N(7,1..2)  W(1..2,4)  E(12..13,4)  S(7,6..7)
APPROACH = [(7, 1), (7, 2), (1, 4), (2, 4), (12, 4), (13, 4), (7, 6), (7, 7)]

def cell_size(w, h):
    return (23, 13) if (w, h) == (23, 13) else (15, 9)

def approach_cells(w, h):
    """Door approach cells on every cell edge of a (possibly multi-cell) room."""
    cw, ch = cell_size(w, h)
    out = []
    for i in range(w // cw):
        cx = cw // 2 + cw * i
        out += [(cx, 1), (cx, 2), (cx, h - 3), (cx, h - 2)]
    for j in range(h // ch):
        cy = ch // 2 + ch * j
        out += [(1, cy), (2, cy), (w - 3, cy), (w - 2, cy)]
    return out

def build():
    ent_uid = {name: 10 + i for i, (name, _) in enumerate(ENTITY_DEFS)}
    levels = []
    wx = 0
    for li, (name, rows) in enumerate(ROOMS.items()):
        h = len(rows); w = len(rows[0])
        assert all(len(r) == w for r in rows), name
        rows = [list(r) for r in rows]
        for (ax, ay) in approach_cells(w, h):
            if rows[ay][ax] in ".RUF":
                rows[ay][ax] = "#"
        rows = ["".join(r) for r in rows]

        # every door approach must reach every other one (flood fill on non-water)
        walkable = {(x, y) for y in range(h) for x in range(w) if rows[y][x] not in ".R"}
        start = approach_cells(w, h)[0]
        seen, queue = {start}, [start]
        while queue:
            cx, cy = queue.pop()
            for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
                n = (cx + dx, cy + dy)
                if n in walkable and n not in seen:
                    seen.add(n)
                    queue.append(n)
        unreachable = [c for c in approach_cells(w, h) if c not in seen]
        assert not unreachable, f"{name}: door approaches unreachable: {unreachable}"
        luid_level = 50 + li
        ents = []
        for cy, row in enumerate(rows):
            for cx, ch in enumerate(row):
                if ch in ENT_CHAR:
                    ents.append(entity_instance(ENT_CHAR[ch], ent_uid[ENT_CHAR[ch]], cx, cy))
                elif ch in RAISED_ENT:
                    ents.append(entity_instance(RAISED_ENT[ch], ent_uid[RAISED_ENT[ch]], cx, cy))
        ground = grid_csv(rows, lambda c: c != ".")
        collision = grid_csv(rows, lambda c: c == ".")
        raised = [2 if c == "/" else (1 if (c == "^" or c in RAISED_ENT) else 0) for r in rows for c in r]
        layers = [
            layer_instance(luid_level, "Entities", LAYER_ENT_UID, "Entities", entities=ents, w=w, h=h),
            layer_instance(luid_level, "Collision", LAYER_COL_UID, "IntGrid", csv=collision, w=w, h=h),
            layer_instance(luid_level, "Ground", LAYER_GND_UID, "IntGrid", csv=ground, tileset=True, w=w, h=h),
        ]
        if any(raised):
            layers.append(layer_instance(luid_level, "Height", LAYER_HGT_UID, "IntGrid", csv=raised, w=w, h=h))
        levels.append({
            "identifier": name, "iid": iid(), "uid": luid_level,
            "worldX": wx, "worldY": 0,
            "worldDepth": 0, "pxWid": w * TILE, "pxHei": h * TILE,
            "__bgColor": "#47ABA9", "bgColor": None, "useAutoIdentifier": False,
            "bgRelPath": None, "bgPos": None, "bgPivotX": 0.5, "bgPivotY": 0.5,
            "__smartColor": "#ADADB5", "__bgPos": None, "externalRelPath": None,
            "fieldInstances": [],
            "layerInstances": layers,
            "__neighbours": [],
        })
        wx += w * TILE + TILE

    doc = {
        "__header__": {
            "fileType": "LDtk Project JSON", "app": "LDtk", "doc": "https://ldtk.io/json",
            "schema": "https://ldtk.io/files/JSON_SCHEMA.json",
            "appAuthor": "Sebastien 'deepnight' Benard", "appVersion": "1.5.3",
            "url": "https://ldtk.io",
        },
        "iid": iid(), "jsonVersion": "1.5.3", "appBuildId": 473703,
        "nextUid": 500, "identifierStyle": "Capitalize", "toc": [],
        "worldLayout": "Free",
        "worldGridWidth": W * TILE, "worldGridHeight": H * TILE,
        "defaultLevelWidth": W * TILE, "defaultLevelHeight": H * TILE,
        "defaultPivotX": 0, "defaultPivotY": 0, "defaultGridSize": TILE,
        "defaultEntityWidth": TILE, "defaultEntityHeight": TILE,
        "bgColor": "#40465B", "defaultLevelBgColor": "#47ABA9",
        "minifyJson": False, "externalLevels": False, "exportTiled": False,
        "simplifiedExport": False, "imageExportMode": "None", "exportLevelBg": True,
        "pngFilePattern": None, "backupOnSave": False, "backupLimit": 10,
        "backupRelPath": None, "levelNamePattern": "Level_%idx", "tutorialDesc": None,
        "customCommands": [], "flags": [],
        "defs": {
            "layers": [
                layer_def("Entities", LAYER_ENT_UID, "Entities"),
                layer_def("Collision", LAYER_COL_UID, "IntGrid",
                          [(1, "Solid", "#1E6F8E")]),
                layer_def("Height", LAYER_HGT_UID, "IntGrid",
                          [(1, "Raised", "#8FB8B0"), (2, "Stair", "#C8A870")]),
                dict(layer_def("Ground", LAYER_GND_UID, "IntGrid",
                               [(1, "Grass", "#3CA370")]),
                     tilesetDefUid=TILESET_UID,
                     autoRuleGroups=autotile_rules()),
            ],
            "entities": [entity_def(i, n, c) for i, (n, c) in enumerate(ENTITY_DEFS)],
            "tilesets": [{
                "__cWid": 10, "__cHei": 4, "identifier": "Tilemap_flat",
                "uid": TILESET_UID, "relPath": "../images/tiles/tilemap_flat.png",
                "embedAtlas": None, "pxWid": 640, "pxHei": 256, "tileGridSize": TILE,
                "spacing": 0, "padding": 0, "tags": [], "tagsSourceEnumUid": None,
                "enumTags": [], "customData": [], "savedSelections": [],
                "cachedPixelData": {"opaqueTiles": "", "averageColors": ""},
            }],
            "enums": [], "externalEnums": [], "levelFields": [],
        },
        "levels": levels,
        "worlds": [], "dummyWorldIid": iid(),
    }
    return doc

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "assets", "levels", "rooms.ldtk")
    with open(out, "w") as f:
        json.dump(build(), f, separators=(",", ":"))
    print("wrote", os.path.abspath(out), os.path.getsize(out), "bytes")
