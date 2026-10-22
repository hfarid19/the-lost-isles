package items;

import entities.Player;

/** A passive run item: picked up from a treasure-room pedestal, applied once. */
typedef ItemDef =
{
	var id:String;
	var name:String;
	var caption:String; // one line shown under the name on pickup
	var icon:String; // 64x64 asset path
	var apply:Player->Void;
	@:optional var familiar:String; // spawns this follower (re-spawned on every floor)
	@:optional var active:Int; // active item: room clears needed to recharge (used with R)
}
