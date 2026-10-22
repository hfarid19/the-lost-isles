package entities;

import Constants.*;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import fx.LightManager;
import fx.NormalMapShader;
import openfl.utils.Assets;

/** Pipeline-rendered boss. slime_diffuse/normal.png: 8x4 grid @192.
 * row0 idle(6f), row1 hop(8f), row2 attack(8f), row3 die(8f). */
class SlimeBoss extends Enemy
{
	public static inline var MAX_HP:Int = 30;

	public var summonHost:FlxTypedGroup<Enemy>;

	/** Soft ground ellipse, added to the state below the actors layer. */
	public var shadow(default, null):flixel.FlxSprite;

	var lightShader:NormalMapShader;
	var summonTimer:Float = 6.0;
	var attackAlt:Bool = false;
	var phase2:Bool = false;
	var dying:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		loadGraphic("assets/images/boss/viking_diffuse.png", true, 192, 192);
		animation.add("idle", [for (i in 0...6) i], 10);
		animation.add("hop", [for (i in 8...16) i], 12, true); // walk cycle
		animation.add("attack", [for (i in 16...24) i], 12, false); // axe swing
		animation.add("bash", [for (i in 24...32) i], 12, false); // shield bash
		animation.add("die", [for (i in 32...40) i], 10, false);
		animation.add("hop_up", [for (i in 40...48) i], 12, true); // walking north
		animation.add("attack_up", [for (i in 48...56) i], 12, false);
		animation.play("idle");
		scale.set(1.5, 1.5);
		setSize(68, 46);
		offset.set(62, 116);
		hp = MAX_HP;
		touchDamage = 1;
		moveSpeed = 220;

		shadow = new flixel.FlxSprite();
		shadow.makeGraphic(150, 54, flixel.util.FlxColor.TRANSPARENT, false, "bossShadow");
		flixel.util.FlxSpriteUtil.drawEllipse(shadow, 0, 0, 150, 54, flixel.util.FlxColor.fromRGB(22, 28, 46));
		shadow.alpha = 0.35;

		lightShader = new NormalMapShader();
		lightShader.uNormalTex.input = Assets.getBitmapData("assets/images/boss/viking_normal.png");
		#if !noshader
		shader = lightShader;
		#end
	}

	override public function update(elapsed:Float):Void
	{
		if (!phase2 && hp <= MAX_HP / 2 && !dying)
		{
			phase2 = true;
			baseColor = 0xFFFFB0A0; // reddish tint
			color = baseColor;
		}

		if (dying)
		{
			velocity.set(0, 0);
			super.update(elapsed);
			return;
		}

		switch (state)
		{
			case IDLE:
				if (target != null)
					state = CHASE;
			case CHASE:
				if (distToTarget() < 110)
					startAttack();
				else
				{
					animation.play(targetIsAbove() ? "hop_up" : "hop");
					moveToward(moveSpeed * (phase2 ? 1.4 : 1.0));
				}

				if (phase2)
				{
					summonTimer -= elapsed;
					if (summonTimer <= 0)
						summon();
				}
			case ATTACK:
				velocity.set(0, 0);
				if (animation.curAnim != null && animation.curAnim.curFrame == 4 && distToTarget() < 150)
				{
					if (target.hurt2(touchDamage, this) && animation.name == "bash")
						fx.Juice.shake(0.004, 0.15); // shield slam
				}
				if (animation.finished)
					state = CHASE;
			case DYING:
		}

		// boss inner glow follows the body (kept tight so it accents, not tints)
		LightManager.setLight(1, x + width / 2, y + height / 2, 180);
		super.update(elapsed);

		shadow.setPosition(x + width / 2 - 75, y + height - 56);
		shadow.alpha = 0.35 * alpha;
		shadow.visible = visible && exists;
	}

	/** Target mostly north of the boss -> use the back-facing rows. */
	function targetIsAbove():Bool
	{
		var dx = (target.x + target.width / 2) - (x + width / 2);
		var dy = (target.y + target.height / 2) - (y + height / 2);
		return dy < 0 && Math.abs(dy) > Math.abs(dx);
	}

	function startAttack():Void
	{
		state = ATTACK;
		var dx = (target.x + target.width / 2) - (x + width / 2);
		if (dx != 0)
			flipX = dx < 0;
		if (targetIsAbove())
			animation.play("attack_up", true);
		else
		{
			animation.play(attackAlt ? "bash" : "attack", true);
			attackAlt = !attackAlt;
		}
	}

	function summon():Void
	{
		summonTimer = 6.0;
		if (summonHost == null || summonHost.countLiving() > 4)
			return;
		for (off in [{x: -180.0, y: -120.0}, {x: 180.0, y: 120.0}])
		{
			var e = new TorchGoblin(x + off.x, y + off.y);
			e.init(target);
			summonHost.add(e);
		}
	}

	override public function takeHit(damage:Int, ?source:flixel.FlxSprite):Void
	{
		if (dying)
			return;
		super.takeHit(damage, source);
	}

	override function die():Void
	{
		dying = true;
		state = DYING;
		solid = false;
		velocity.set(0, 0);
		animation.play("die", true);
		LightManager.setLight(1, 0, 0, 0);
		animation.onFinish.addOnce(_ ->
		{
			flixel.tweens.FlxTween.tween(this, {alpha: 0}, 0.5, {onComplete: _ -> kill()});
		});
	}

	override public function draw():Void
	{
		// map current frame -> atlas UV + world rect for the shader
		var fr = frame;
		if (fr != null)
		{
			var bw = fr.parent.width;
			var bh = fr.parent.height;
			lightShader.uFrameUV.value = [fr.frame.x / bw, fr.frame.y / bh, fr.frame.width / bw, fr.frame.height / bh];
			// flixel scales around the frame center; reconstruct scaled top-left
			var wx = x - offset.x + fr.frame.width * (1 - scale.x) / 2;
			var wy = y - offset.y + fr.frame.height * (1 - scale.y) / 2;
			lightShader.uFrameWorld.value = [wx, wy, fr.frame.width * scale.x, fr.frame.height * scale.y];
			lightShader.uFlipX.value = [flipX ? -1.0 : 1.0];
			LightManager.apply(lightShader);
		}
		super.draw();
	}
}
