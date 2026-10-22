package fx;

/** World-space point lights consumed by NormalMapShader-lit sprites.
 * Slot 0: player glow. Slot 1: boss glow. Slot 2: transient (explosions). */
class LightManager
{
	public static var lights:Array<{x:Float, y:Float, z:Float, radius:Float, r:Float, g:Float, b:Float}> = [
		{x: 0, y: 0, z: 80, radius: 0, r: 1.0, g: 0.95, b: 0.8},
		{x: 0, y: 0, z: 60, radius: 0, r: 1.0, g: 0.55, b: 0.3}, // boss ember glow
		{x: 0, y: 0, z: 90, radius: 0, r: 1.0, g: 0.7, b: 0.3},
	];

	public static var ambient:Float = 0.78;

	static var flashTime:Float = 0;

	public static function setLight(slot:Int, x:Float, y:Float, radius:Float):Void
	{
		var l = lights[slot];
		l.x = x;
		l.y = y;
		l.radius = radius;
	}

	public static function flash(x:Float, y:Float, radius:Float):Void
	{
		setLight(2, x, y, radius);
		flashTime = 0.35;
	}

	public static function update(elapsed:Float):Void
	{
		if (flashTime > 0)
		{
			flashTime -= elapsed;
			lights[2].radius *= Math.max(0, flashTime / 0.35);
			if (flashTime <= 0)
				lights[2].radius = 0;
		}
	}

	/** Push current lights into a shader instance. */
	public static function apply(shader:NormalMapShader):Void
	{
		shader.uAmbient.value = [ambient];
		inline function set(i:Int, pos:Dynamic, col:Dynamic)
		{
			var l = lights[i];
			pos.value = [l.x, l.y, l.z, l.radius];
			col.value = [l.r, l.g, l.b];
		}
		set(0, shader.uLight0, shader.uLightColor0);
		set(1, shader.uLight1, shader.uLightColor1);
		set(2, shader.uLight2, shader.uLightColor2);
	}
}
