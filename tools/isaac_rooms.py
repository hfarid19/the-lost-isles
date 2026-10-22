#!/usr/bin/env python3
"""Read The Binding of Isaac's room files (.stb, Afterbirth "STB1" format) and print every
1x1 room as an ASCII template in this project's legend, for browsing and for picking layouts.

Legend (same as gen_rooms.py): '.' water  '#' grass  'R' rock (solid)  'U' bush (destructible)
                               'T' melee spawn  'N' special/ranged spawn  'F' campfire  '=' pit->water
Isaac's 1x1 room is 15x9 with the wall ring, i.e. a 13x7 interior: the same as our island.

Usage:
  python3 tools/isaac_rooms.py <rooms dir> [stage-number]      dump every stage (or one) to tools/isaac_rooms/*.txt
  python3 tools/isaac_rooms.py <rooms dir> pick 01:12 04:31 ... print the chosen rooms as gen_rooms.py entries
"""
import struct, sys, os, re, glob

ROCK = {1000, 1001, 1002, 1003, 1008, 1009, 1010, 1011, 1900, 1901}   # rocks, blocks
SOFT = {1300, 1490, 1495, 1500, 1501}                                  # TNT, poops -> bushes
PIT = {3000, 3001, 3009}
SPIKE = {1930, 1931}
FIRE = {33}
FLYING = {13, 14, 18, 25, 26, 27, 28, 29, 30, 31, 32, 55, 60, 61, 62, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99}  # flies, hosts, hoppers, spiders, boils, spitters: ranged or airborne
# ids treated as bosses/non-regular (Isaac boss ids are mostly 10..300 too; we mark by room type instead)


def read_stb(path):
    data = open(path, "rb").read()
    hdr, count = struct.unpack_from("<4sI", data, 0)
    off = 8
    if hdr != b"STB1":
        raise SystemExit(f"{path}: not an Afterbirth STB ({hdr})")
    rooms = []
    for _ in range(count):
        rtype, variant, subtype, difficulty, nlen = struct.unpack_from("<IIIBH", data, off)
        off += struct.calcsize("<IIIBH")
        name = data[off:off + nlen].decode(errors="replace")
        off += nlen
        weight, w, h, shape, ndoors, nents = struct.unpack_from("<fBBBBH", data, off)
        off += struct.calcsize("<fBBBBH")
        doors = []
        for _ in range(ndoors):
            dx, dy, ex = struct.unpack_from("<hh?", data, off)
            off += 5
            doors.append((dx, dy, ex))
        ents = []
        for _ in range(nents):
            ex, ey, n = struct.unpack_from("<hhB", data, off)
            off += 5
            for _ in range(n):
                et, ev, es, ew = struct.unpack_from("<HHHf", data, off)
                off += 10
                ents.append((ex, ey, et, ev, es, ew))
        rooms.append(dict(type=rtype, variant=variant, subtype=subtype, difficulty=difficulty, name=name,
                          weight=weight, w=w, h=h, shape=shape, doors=doors, ents=ents))
    return rooms


SHAPES = {1: (13, 7, 1, 1), 4: (13, 14, 1, 2), 6: (26, 7, 2, 1), 8: (26, 14, 2, 2)}  # isaac interior w,h -> our cells


def to_ascii(room, max_enemies=99):
    """Isaac interior -> our island of cw x ch cells (15x9 each) with a water ring; one char per cell.
    Big rooms are padded by one grass cell on the far sides so they fill whole cells."""
    iw, ih, cw, ch = SHAPES[room["shape"]]
    W, H = cw * 15 - 2, ch * 9 - 2
    grid = [["#"] * W for _ in range(H)]
    ox, oy = (W - iw) // 2, (H - ih) // 2
    enemies = 0
    for ex, ey, et, ev, es, ew in room["ents"]:
        if not (0 <= ex < iw and 0 <= ey < ih):
            continue
        ex += ox
        ey += oy
        c = grid[ey][ex]
        if et in PIT:
            grid[ey][ex] = "."
        elif et in ROCK:
            grid[ey][ex] = "R"
        elif et in SOFT:
            grid[ey][ex] = "U"
        elif et in SPIKE:
            grid[ey][ex] = "R"
        elif et in FIRE:
            grid[ey][ex] = "F"
        elif 10 <= et < 1000 and c == "#" and enemies < max_enemies:
            grid[ey][ex] = "N" if et in FLYING else "T"
            enemies += 1
    rows = ["." * (W + 2)] + ["." + "".join(r) + "." for r in grid] + ["." * (W + 2)]
    return rows, enemies


def stage_name(path):
    return re.sub(r"\.stb$", "", os.path.basename(path))


def dump(rooms_dir, only=None):
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "isaac_rooms")
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    for path in sorted(glob.glob(os.path.join(rooms_dir, "*.stb"))):
        sname = stage_name(path)
        if only and not sname.startswith(only):
            continue
        rooms = read_stb(path)
        lines = []
        n = 0
        for r in rooms:
            if r["shape"] not in SHAPES or r["type"] != 1:  # rectangular, normal combat rooms only
                continue
            rows, enemies = to_ascii(r)
            n += 1
            _, _, cw, ch = SHAPES[r["shape"]]
            lines.append(f"## {sname[:2]}:{r['variant']}  \"{r['name']}\"  {cw}x{ch}  difficulty {r['difficulty']}  weight {r['weight']:.1f}  enemies {enemies}")
            lines.extend(rows)
            lines.append("")
        with open(os.path.join(out_dir, sname + ".txt"), "w") as f:
            f.write("\n".join(lines))
        print(f"{sname}: {n} normal 1x1 rooms (of {len(rooms)} total)")
        total += n
    print("total", total)


def pick(rooms_dir, picks):
    by_stage = {}
    for path in glob.glob(os.path.join(rooms_dir, "*.stb")):
        by_stage[stage_name(path)[:2]] = path
    for p in picks:
        st, var = p.split(":")
        rooms = read_stb(by_stage[st])
        for r in rooms:
            if r["shape"] in SHAPES and r["type"] == 1 and r["variant"] == int(var):
                rows, _ = to_ascii(r, 5 if r["shape"] == 1 else 8)
                print(f'    "Room_I{st}_{var}": [')
                for row in rows:
                    print(f'        "{row}",')
                print("    ],")


QUOTA = {1: 36, 6: 8, 4: 8, 8: 4}  # rooms per stage per shape


def usable(r):
    return r["type"] == 1 and r["shape"] in SHAPES and r["difficulty"] <= 12


def approaches_connect(rows):
    """Same rule as gen_rooms.py: every door approach must reach every other one without crossing water or rocks."""
    h, w = len(rows), len(rows[0])
    cw, ch = (23, 13) if (w, h) == (23, 13) else (15, 9)
    app = []
    for i in range(w // cw):
        cx = cw // 2 + cw * i
        app += [(cx, 1), (cx, 2), (cx, h - 3), (cx, h - 2)]
    for j in range(h // ch):
        cy = ch // 2 + ch * j
        app += [(1, cy), (2, cy), (w - 3, cy), (w - 2, cy)]
    grid = [list(r) for r in rows]
    for ax, ay in app:
        if grid[ay][ax] in ".RUF":
            grid[ay][ax] = "#"
    walk = {(x, y) for y in range(h) for x in range(w) if grid[y][x] not in ".R"}
    seen, queue = {app[0]}, [app[0]]
    while queue:
        cx, cy = queue.pop()
        for dx, dy in ((0, -1), (1, 0), (0, 1), (-1, 0)):
            n = (cx + dx, cy + dy)
            if n in walk and n not in seen:
                seen.add(n)
                queue.append(n)
    return all(a in seen for a in app)


def export(rooms_dir):
    """Every level's combat pool: pick a spread of rooms per stage and shape, write the
    gen_rooms templates (tools/isaac_templates.py) and the Haxe lookup (source/world/IsaacRooms.hx)."""
    here = os.path.dirname(os.path.abspath(__file__))
    tpl = ["# generated by isaac_rooms.py export -- do not edit", "ISAAC_ROOMS = {"]
    hx = ["package world;", "", "/** Generated by tools/isaac_rooms.py export: Isaac stage -> room templates per size. */",
          "class IsaacRooms", "{", "\tstatic var pools:Map<String, Array<String>> = ["]
    total = 0
    diff = []
    for path in sorted(glob.glob(os.path.join(rooms_dir, "*.stb"))):
        st = stage_name(path)[:2]
        if st not in {"01", "02", "03", "04", "05", "06", "07", "08", "09"}:
            continue
        rooms = [r for r in read_stb(path) if usable(r)]
        for shape, quota in QUOTA.items():
            cands = []
            for r in rooms:
                if r["shape"] != shape:
                    continue
                rows, enemies = to_ascii(r, 5 if shape == 1 else 8)
                if enemies < 1 or not approaches_connect(rows):
                    continue
                interior = "".join(row[1:-1] for row in rows[1:-1])
                if interior.count("R") > 0.3 * len(interior):
                    continue  # walled-in layouts built around Isaac's bombs
                cands.append((r, rows))
            step = max(1, len(cands) // quota)
            chosen = cands[::step][:quota]
            _, _, cw, ch = SHAPES[shape]
            names = []
            for r, rows in chosen:
                name = f"Room_I{st}_{r['variant']}"
                names.append(name)
                tpl.append(f'    "{name}": [')
                for row in rows:
                    tpl.append(f'        "{row}",')
                tpl.append("    ],")
            total += len(names)
            hx.append(f'\t\t"{st}:{cw}x{ch}" => [{", ".join(chr(34) + n + chr(34) for n in names)}],')
            for r, rows in chosen:
                diff.append(f'\t\t"Room_I{st}_{r["variant"]}" => {r["difficulty"]},')
    tpl.append("}")
    hx += ["\t];", "", "\t/** Isaac's own difficulty rating per room (1 easy .. 10+ hard). */",
           "\tpublic static var difficulty:Map<String, Int> = ["] + diff + ["\t];", "",
           "\tpublic static function get(stage:String, cw:Int, ch:Int):Array<String>",
           "\t\treturn pools.get(stage + \":\" + cw + \"x\" + ch);", "}"]
    open(os.path.join(here, "isaac_templates.py"), "w").write("\n".join(tpl) + "\n")
    open(os.path.join(here, "..", "source", "world", "IsaacRooms.hx"), "w").write("\n".join(hx) + "\n")
    print("exported", total, "rooms")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    if len(sys.argv) > 2 and sys.argv[2] == "export":
        export(sys.argv[1])
    elif len(sys.argv) > 2 and sys.argv[2] == "pick":
        pick(sys.argv[1], sys.argv[3:])
    else:
        dump(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
