package ui;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/** Gamepad / keyboard focus for a screen's buttons: d-pad or stick moves the highlight to the
 * nearest button in that direction, A (Enter) presses it, B (Escape) presses `back` if given.
 * Buttons are collected from the state, including those inside sprite groups. */
class MenuNav
{
	var buttons:Array<FlxButton> = [];
	var sel:Int = -1;
	var back:Void->Void;
	var repeat:Float = 0;

	public static function collect(state:FlxState, ?back:Void->Void):MenuNav
	{
		var nav = new MenuNav();
		nav.back = back;
		gather(cast state.members, nav.buttons);
		return nav;
	}

	static function gather(members:Array<Dynamic>, into:Array<FlxButton>):Void
	{
		for (m in members)
		{
			if (m == null)
				continue;
			if (Std.isOfType(m, FlxButton))
				into.push(cast m);
			else if (Std.isOfType(m, FlxSpriteGroup))
			{
				var g:FlxSpriteGroup = cast m;
				gather(cast g.group.members, into);
			}
			else if (Std.isOfType(m, FlxTypedGroup))
			{
				var g:FlxTypedGroup<Dynamic> = cast m;
				gather(cast g.members, into);
			}
		}
	}

	function new() {}

	function highlight(i:Int):Void
	{
		if (sel >= 0 && sel < buttons.length)
			buttons[sel].color = FlxColor.WHITE;
		sel = i;
		if (sel >= 0 && sel < buttons.length)
			buttons[sel].color = FlxColor.fromRGB(255, 230, 140);
	}

	function move(dx:Float, dy:Float):Void
	{
		var live = [for (b in buttons) if (b.exists && b.visible && b.active) b];
		if (live.length == 0)
			return;
		if (sel < 0 || !buttons[sel].exists)
		{
			highlight(buttons.indexOf(live[0]));
			return;
		}
		var cur = buttons[sel];
		var cx = cur.x + cur.width / 2, cy = cur.y + cur.height / 2;
		var best:FlxButton = null, bestScore = 1e12;
		for (b in live)
		{
			if (b == cur)
				continue;
			var bx = b.x + b.width / 2 - cx, by = b.y + b.height / 2 - cy;
			var along = bx * dx + by * dy;
			if (along <= 8)
				continue;
			var across = Math.abs(bx * dy - by * dx);
			var score = along + across * 2.5;
			if (score < bestScore)
			{
				bestScore = score;
				best = b;
			}
		}
		if (best != null)
			highlight(buttons.indexOf(best));
	}

	public function update(elapsed:Float):Void
	{
		if (repeat > 0)
			repeat -= elapsed;
		if (Input.menuUp) move(0, -1);
		else if (Input.menuDown) move(0, 1);
		else if (Input.menuLeft) move(-1, 0);
		else if (Input.menuRight) move(1, 0);
		if (Input.confirm && sel >= 0 && sel < buttons.length && buttons[sel].exists)
		{
			var b = buttons[sel];
			if (b.onUp != null && b.onUp.callback != null)
				b.onUp.callback();
		}
		if (Input.back && back != null)
			back();
		// the mouse takes the highlight away when it moves
		if (FlxG.mouse.justMoved && sel >= 0)
			highlight(-1);
	}
}
