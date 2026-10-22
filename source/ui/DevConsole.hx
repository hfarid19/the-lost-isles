package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/** Minimal dev console: backtick toggles, type /commands, ENTER runs.
 * PlayState supplies onCommand and reads `open` to gate player input. */
class DevConsole extends FlxSpriteGroup
{
	/** True while the console is capturing keyboard input. */
	public static var open:Bool = false;

	public var onCommand:String->String;

	var inputText:FlxText;
	var resultText:FlxText;
	var buffer:String = "";
	var caretTimer:Float = 0;

	static inline var HEIGHT:Int = 58;

	public function new()
	{
		super();
		camera = FlxG.camera;
		scrollFactor.set(0, 0);

		var bg = new FlxSprite(0, FlxG.height - HEIGHT);
		bg.makeGraphic(FlxG.width, HEIGHT, FlxColor.fromRGBFloat(0.05, 0.07, 0.11, 0.88));
		add(bg);

		resultText = new FlxText(10, FlxG.height - HEIGHT + 4, FlxG.width - 20, "", 12);
		resultText.color = FlxColor.fromRGB(150, 200, 160);
		add(resultText);

		inputText = new FlxText(10, FlxG.height - 26, FlxG.width - 20, "> ", 14);
		add(inputText);

		visible = false;
	}

	public function toggle():Void
	{
		open = !open;
		visible = open;
		buffer = "";
		if (open)
			resultText.text = "commands: /boss /heal /gold N /bombs N /god /kill";
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!open)
		{
			if (FlxG.keys.justPressed.GRAVEACCENT)
				toggle();
			return;
		}

		if (FlxG.keys.justPressed.GRAVEACCENT || FlxG.keys.justPressed.ESCAPE)
		{
			toggle();
			return;
		}

		// text entry: letters, digits, space, slash, minus, backspace
		for (i in 0...26)
			if (FlxG.keys.checkStatus(FlxKey.A + i, JUST_PRESSED))
				buffer += String.fromCharCode("a".code + i);
		for (i in 0...10)
			if (FlxG.keys.checkStatus(FlxKey.ZERO + i, JUST_PRESSED))
				buffer += Std.string(i);
		if (FlxG.keys.justPressed.SPACE)
			buffer += " ";
		if (FlxG.keys.justPressed.SLASH)
			buffer += "/";
		if (FlxG.keys.justPressed.MINUS)
			buffer += "-";
		if (FlxG.keys.justPressed.BACKSPACE && buffer.length > 0)
			buffer = buffer.substr(0, buffer.length - 1);

		if (FlxG.keys.justPressed.ENTER && buffer.length > 0)
		{
			resultText.text = onCommand != null ? onCommand(buffer) : "no handler";
			buffer = "";
		}

		caretTimer += elapsed;
		var caret = (caretTimer % 0.8) < 0.4 ? "_" : " ";
		inputText.text = "> " + buffer + caret;
	}
}
