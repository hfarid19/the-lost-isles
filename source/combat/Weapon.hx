package combat;

import entities.Player;

interface Weapon
{
	public var cooldown(default, null):Float;
	public function tryFire(owner:Player, aimX:Float, aimY:Float):Bool;
	public function update(elapsed:Float):Void;
}
