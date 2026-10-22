package entities;

/** Shark Waters turret (Enemy Pack Extra Pirate Tower, ground variant): a taller Cannon with
 * a slower gun and more planks to chew through. */
class PirateTower extends Cannon
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/pirate_tower.png");
		setSize(60, 36);
		offset.set(34, 150);
		hp = 6;
		timer = 2.6;
		reload = 3.4;
	}
}
