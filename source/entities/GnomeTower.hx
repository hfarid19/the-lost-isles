package entities;

/** Gnome Mines turret (Enemy Pack Extra Gnome Tower): slings acorns from the top. */
class GnomeTower extends Cannon
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/props/gnome_tower.png");
		setSize(60, 36);
		offset.set(34, 196);
		hp = 5;
		timer = 1.8;
		reload = 2.4;
		shotKind = "acorn";
		shotSpeed = 330;
	}
}
