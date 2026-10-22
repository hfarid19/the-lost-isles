package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

/** Isaac-style boss intro: the room dims, the boss portrait slides onto the
 * paper panel with its name and a gag caption, play freezes for ~2 s, any key
 * skips. Names and captions live in the table below so they are easy to rewrite. */
class BossCard extends FlxSpriteGroup
{
	static var cards:Map<String, {name:String, caption:String}> = [
		"troll" => {name: "THE TROLL", caption: "Has never once read the comments."},
		"gnoll" => {name: "THE GNOLL", caption: "Half dog, half problem."},
		"bigtorch" => {name: "BIG TORCH", caption: "Compensating for something."},
		"bear" => {name: "THE BEAR", caption: "Woke up on the wrong side of the forest."},
		"lizard" => {name: "THE LIZARD", caption: "Cold-blooded. Colder personality."},
		"spider" => {name: "THE SPIDER", caption: "Eight legs, zero chill."},
		"shaman" => {name: "HEX SHAMAN", caption: "Turned his last therapist into a sheep."},
		"warlord" => {name: "PIG RIDER WARLORD", caption: "This little piggy went to war."},
		"hut" => {name: "THE HUT", caption: "Home is where the hoard is."},
		"minotaur" => {name: "THE MINOTAUR", caption: "Lost in a maze of his own bad decisions."},
		"skullguard" => {name: "SKULL GUARD", caption: "Dead inside. Also outside."},
		"giantbat" => {name: "THE GIANT BAT", caption: "Afraid of the light. Also of you, but hiding it."},
		"blackking" => {name: "THE BLACK KING", caption: "Heavy is the head. Heavier is the armour."},
		"panda" => {name: "THE PANDA", caption: "Eats, shoots, and leaves. Mostly eats."},
		"harpoonshark" => {name: "HARPOON SHARK", caption: "Jaws, but with a day job."},
		"paddleshark" => {name: "PADDLE SHARK", caption: "Brought a paddle to a sword fight."},
		"bombfish" => {name: "BOMB FISH", caption: "Sushi with a short fuse."},
		"blackcaptain" => {name: "THE BLACK CAPTAIN", caption: "Follows orders. Gives worse ones."},
		"blackchampion" => {name: "THE BLACK CHAMPION", caption: "Brought a lance to a pig fight."},
		"blackabbot" => {name: "THE BLACK ABBOT", caption: "Prays for you. Preys on you."},
		"gnometower" => {name: "THE GNOME TOWER", caption: "Small hats, tall problems."},
		"giantslingshot" => {name: "GIANT SLINGSHOT", caption: "Nuts about you."},
		"turtleguard" => {name: "TURTLE GUARD", caption: "Slow to anger. Slower to leave."},
		"pandaguard" => {name: "PANDA GUARD", caption: "Bamboo in, nothing out."},
	];

	public var showing(default, null):Bool = false;

	var dim:FlxSprite;
	var panel:FlxSprite;
	var portrait:FlxSprite;
	var nameText:FlxText;
	var captionText:FlxText;
	var timer:Float = 0;
	var onDone:Void->Void;

	public function new()
	{
		super();
		scrollFactor.set(0, 0);
		dim = new FlxSprite();
		dim.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGBFloat(0, 0, 0, 0.6), false, "bossDim");
		add(dim);
		panel = new FlxSprite(0, 0, "assets/images/ui/paper_panel.png"); // 460x470
		add(panel);
		portrait = new FlxSprite();
		add(portrait);
		var ink = FlxColor.fromRGB(74, 56, 38);
		nameText = new FlxText(0, 0, 420, "", 30);
		nameText.setFormat(null, 30, ink, CENTER);
		add(nameText);
		captionText = new FlxText(0, 0, 400, "", 14);
		captionText.setFormat(null, 14, ink, CENTER);
		captionText.wordWrap = true;
		add(captionText);
		visible = false;
	}

	/** Show the card for `id` (the boss pool id); freezes the game until done. */
	public function show(id:String, done:Void->Void):Void
	{
		var c = cards.get(id);
		if (c == null)
		{
			done();
			return;
		}
		onDone = done;
		showing = true;
		visible = true;
		// met before: a quick nod instead of the full intro
		timer = Unlocks.bossSeen(id) ? 0.9 : 2.4;
		Unlocks.markBossSeen(id);
		var px = (FlxG.width - panel.width) / 2;
		panel.setPosition(px, 60);
		portrait.loadGraphic('assets/images/avatars/$id.png');
		portrait.scale.set(0.9, 0.9);
		portrait.updateHitbox();
		portrait.setPosition(FlxG.width + 40, 92); // slides in from the right
		nameText.setPosition(px + 20, 330);
		nameText.text = c.name;
		captionText.setPosition(px + 30, 380);
		captionText.text = c.caption;
		dim.alpha = 0;
		panel.alpha = 0;
		nameText.alpha = 0;
		captionText.alpha = 0;
		FlxTween.tween(dim, {alpha: 1}, 0.25);
		FlxTween.tween(panel, {alpha: 1}, 0.25);
		FlxTween.tween(portrait, {x: (FlxG.width - portrait.width) / 2}, 0.45, {ease: FlxEase.backOut});
		FlxTween.tween(nameText, {alpha: 1}, 0.3, {startDelay: 0.35});
		FlxTween.tween(captionText, {alpha: 1}, 0.3, {startDelay: 0.55});
		fx.Sfx.play("stinger", 0.8);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!showing)
			return;
		timer -= elapsed;
		if (timer <= 0 || FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed)
			hide();
	}

	function hide():Void
	{
		showing = false;
		FlxTween.tween(this, {alpha: 0}, 0.25, {onComplete: _ ->
		{
			visible = false;
			alpha = 1;
			if (onDone != null)
				onDone();
		}});
	}
}
