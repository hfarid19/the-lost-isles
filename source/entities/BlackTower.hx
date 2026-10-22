package entities;

/** Troy turret (Free Pack Black Tower): an archer post that looses an arrow every few seconds. */
class BlackTower extends Cannon
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/black_tower.png");
		setSize(60, 36);
		offset.set(34, 200);
		hp = 6;
		timer = 2.0;
		reload = 2.6;
		shotKind = "arrow";
		shotSpeed = 420;
	}
}
