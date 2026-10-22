package fx;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.FlxBasic;

/** Debug (?packs / PACKS=1 / the /packs console command): a gallery floor with every run item
 * (treasure pool, then boss items) on real pedestals, twelve to a room. */
class PackPreview
{
	public static inline var PER_ROOM:Int = 12;

	static function defs():Array<items.ItemDef>
		return items.ItemPool.all.concat(items.ItemPool.bosses);

	public static function roomsNeeded():Int
		return Math.ceil(defs().length / PER_ROOM);

	public static function build(index:Int, roomX:Float, roomY:Float, tile:Int):FlxTypedGroup<FlxBasic>
	{
		var g = new FlxTypedGroup<FlxBasic>();
		var all = defs();
		var from = index * PER_ROOM;
		for (i in from...Std.int(Math.min(all.length, from + PER_ROOM)))
		{
			var d = all[i];
			var k = i - from, col = k % 6, row = Std.int(k / 6);
			var px = roomX + tile * (1.5 + col * 2.05);
			var py = roomY + tile * (2.5 + row * 3.0);
			var ped = new entities.ItemPedestal(px, py, d);
			g.add(ped);
			var boss = items.ItemPool.bosses.indexOf(d) >= 0;
			g.add(label(px + ped.width / 2, py + ped.height + 4, d.name + (boss ? " (boss)" : "")));
		}
		return g;
	}

	static function label(cx:Float, y:Float, text:String):FlxText
	{
		var t = new FlxText(0, y, 200, text, 10);
		t.alignment = CENTER;
		t.setBorderStyle(OUTLINE, 0xff000000, 1);
		t.x = cx - 100;
		return t;
	}
}
