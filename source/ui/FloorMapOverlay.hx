package ui;

import Constants.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import world.FloorMap;

/** Full floor map on the paper panel (hold TAB or M): every room you have seen,
 * with the boss, shop, treasure and found secret rooms marked, and you as a dot. */
class FloorMapOverlay extends FlxSpriteGroup
{
	static inline var CW:Int = 44;
	static inline var CH:Int = 28;
	static inline var GAP:Int = 4;

	var floor:FloorMap;
	var panel:FlxSprite;
	var cells:Array<FlxSprite> = [];
	var labels:Array<FlxText> = [];
	var dot:FlxSprite;
	var built:Bool = false;

	public function new(floor:FloorMap)
	{
		super();
		this.floor = floor;
		scrollFactor.set(0, 0);
		panel = new FlxSprite(0, 0, "assets/images/ui/paper_panel.png");
		panel.setPosition((FlxG.width - panel.width) / 2, (FlxG.height - panel.height) / 2 + 20);
		add(panel);
		var title = new FlxText(panel.x, panel.y + 26, panel.width, "MAP");
		title.setFormat(null, 24, FlxColor.fromRGB(74, 56, 38), CENTER);
		add(title);
		dot = new FlxSprite();
		dot.makeGraphic(8, 8, FlxColor.WHITE, false, "mapDot");
		visible = false;
	}

	/** Rebuild the cells from the floor's current visited/revealed state. */
	public function refresh(current:RoomNode, player:flixel.FlxObject):Void
	{
		for (c in cells)
		{
			remove(c, true);
			c.destroy();
		}
		for (l in labels)
		{
			remove(l, true);
			l.destroy();
		}
		cells = [];
		labels = [];
		var minX = 99, minY = 99, maxX = -1, maxY = -1;
		for (n in floor.nodes)
		{
			if (!seen(n))
				continue;
			if (n.gx < minX) minX = n.gx;
			if (n.gy < minY) minY = n.gy;
			if (n.gx > maxX) maxX = n.gx;
			if (n.gy > maxY) maxY = n.gy;
		}
		var w = (maxX - minX + 1) * (CW + GAP), h = (maxY - minY + 1) * (CH + GAP);
		var x0 = panel.x + (panel.width - w) / 2, y0 = panel.y + 70 + (panel.height - 110 - h) / 2;
		var ink = FlxColor.fromRGB(74, 56, 38);
		for (cellNode in floor.nodes)
		{
			if (!seen(cellNode))
				continue;
			var n = cellNode.primary();
			var cx = x0 + (cellNode.gx - minX) * (CW + GAP), cy = y0 + (cellNode.gy - minY) * (CH + GAP);
			var cell = new FlxSprite(cx, cy);
			// big rooms: fill the gap between their cells so they read as one block
			if (cellNode.owner != null || n.cw > 1 || n.ch > 1)
				cell.makeGraphic(CW + (n.gx + n.cw - 1 > cellNode.gx ? GAP : 0), CH + (n.gy + n.ch - 1 > cellNode.gy ? GAP : 0), FlxColor.WHITE, false, 'mapBig${n.gx}_${n.gy}_${cellNode.gx}_${cellNode.gy}');
			var col = switch (n.kind)
			{
				case Boss: FlxColor.fromRGB(190, 60, 60);
				case Treasure: FlxColor.fromRGB(220, 180, 60);
				case Shop: FlxColor.fromRGB(70, 190, 170);
				case Secret: FlxColor.fromRGB(180, 140, 220);
				case Start: FlxColor.fromRGB(120, 170, 110);
				default: n.visited ? FlxColor.fromRGB(150, 156, 170) : FlxColor.fromRGB(95, 100, 115);
			};
			if (!n.visited && n.kind != Secret)
				col = col.getDarkened(0.35);
			if (cellNode.owner != null || n.cw > 1 || n.ch > 1)
				cell.color = col;
			else
				cell.makeGraphic(CW, CH, col, false, 'mapCell${n.kind}${n.visited}');
			add(cell);
			cells.push(cell);
			var glyph = switch (n.kind)
			{
				case Boss: "B";
				case Treasure: "T";
				case Shop: "$";
				case Secret: "?";
				case Start: "S";
				default: n.cleared ? "" : (n.visited ? "!" : "");
			};
			if (glyph != "" && cellNode.owner == null)
			{
				var t = new FlxText(cx, cy + 5, CW, glyph, 14);
				t.setFormat(null, 14, ink, CENTER);
				add(t);
				labels.push(t);
			}
			if (n == current && cellNode.owner == null)
			{
				var pw = CW * n.cw + GAP * (n.cw - 1), ph = CH * n.ch + GAP * (n.ch - 1);
				dot.setPosition(cx + pw / 2 - 4, cy + ph / 2 - 4);
			}
		}
		remove(dot, true);
		add(dot);
		built = true;
	}

	function seen(n:RoomNode):Bool
	{
		n = n.primary();
		if (n.kind == Secret)
			return n.visited || n.revealed;
		if (n.visited)
			return true;
		for (d in [[0, -1], [1, 0], [0, 1], [-1, 0]])
		{
			var m = floor.get(n.gx + d[0], n.gy + d[1]);
			if (m != null && m.visited)
				return true;
		}
		return false;
	}
}
