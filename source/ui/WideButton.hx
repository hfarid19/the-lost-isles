package ui;

import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/** Free Pack big blue button (9-slice baked to 256x80, 3 stacked states). */
class WideButton extends FlxButton
{
	public function new(y:Float, text:String, onClick:Void->Void, ?atX:Null<Float>)
	{
		super(0, y, text, () ->
		{
			fx.Sfx.play("ui", 0.6);
			onClick();
		});
		loadGraphic("assets/images/ui/button_big_states.png", true, 256, 80);
		label.fieldWidth = 256;
		label.setFormat(null, 20, FlxColor.WHITE, CENTER);
		label.setBorderStyle(SHADOW, FlxColor.fromRGB(25, 60, 70), 2);
		labelOffsets[0].set(0, 22);
		labelOffsets[1].set(0, 22);
		labelOffsets[2].set(0, 28); // pressed art sinks the face
		if (atX != null)
			x = atX;
		else
			screenCenter(X);
	}
}
