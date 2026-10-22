package entities;

import flixel.group.FlxGroup.FlxTypedGroup;

/** Shared boss surface: scaled HP pool for the HUD bar and a host group for summons. */
class BossBase extends Enemy
{
	public var maxHp(default, null):Int = 30;
	public var summonHost:FlxTypedGroup<Enemy>;
	var dying:Bool = false;
	/** Boss classes that also serve as regular units (Panda Guard, the sharks) turn this off. */
	public var regularUnit:Bool = false;

	override public function isRealBoss():Bool
		return !regularUnit;

	/** Base HP scaled by depth: +25 % per floor of the run plus +35 % per level
	 * (Plains I 1x, Forest I about 1.9x, Caves I about 3.6x, the Keep about 4.4x). */
	function setScaledHp(base:Int):Void
	{
		maxHp = Std.int(base * (1 + 0.25 * RunState.floorNumber() + 0.35 * RunState.level));
		hp = maxHp;
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (dying)
			return;
		super.takeHit(damage, source);
		if (hp <= 0)
			fx.Sfx.play("stomp", 0.9); // boss down
	}
}
