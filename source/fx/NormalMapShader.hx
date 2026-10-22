package fx;

import flixel.system.FlxAssets.FlxShader;

/**
 * Dead Cells-style dynamic lighting: diffuse sheet + camera-space normal sheet.
 * Frame mapping uniforms are updated per-frame by the owning sprite so the
 * fragment position can be reconstructed in world space.
 * Up to 3 point lights: uLightN = (worldX, worldY, height, radius).
 */
class NormalMapShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header

		uniform sampler2D uNormalTex;
		uniform vec4 uFrameUV;    // frame rect in atlas UV: x, y, w, h
		uniform vec4 uFrameWorld; // frame rect in world px: x, y, w, h
		uniform float uFlipX;     // 1.0 or -1.0
		uniform float uAmbient;
		uniform vec4 uLight0;
		uniform vec3 uLightColor0;
		uniform vec4 uLight1;
		uniform vec3 uLightColor1;
		uniform vec4 uLight2;
		uniform vec3 uLightColor2;

		vec3 shade(vec3 n, vec2 fragWorld, vec4 light, vec3 lightColor)
		{
			if (light.w <= 0.0) return vec3(0.0);
			vec3 L = vec3(light.xy - fragWorld, light.z);
			float dist = length(L);
			float atten = clamp(1.0 - dist / light.w, 0.0, 1.0);
			float diff = max(dot(n, normalize(vec3(L.x, -L.y, L.z))), 0.0);
			return lightColor * diff * atten * atten;
		}

		void main()
		{
			vec4 diffuse = flixel_texture2D(bitmap, openfl_TextureCoordv);
			if (diffuse.a < 0.01) { gl_FragColor = diffuse; return; }

			vec4 nrmSample = texture2D(uNormalTex, openfl_TextureCoordv);
			vec3 n = nrmSample.rgb * 2.0 - 1.0;
			n.x *= uFlipX;
			n = normalize(n);

			vec2 uvLocal = (openfl_TextureCoordv - uFrameUV.xy) / uFrameUV.zw;
			if (uFlipX < 0.0) uvLocal.x = 1.0 - uvLocal.x;
			vec2 fragWorld = uFrameWorld.xy + uvLocal * uFrameWorld.zw;

			vec3 light = vec3(uAmbient);
			light += shade(n, fragWorld, uLight0, uLightColor0);
			light += shade(n, fragWorld, uLight1, uLightColor1);
			light += shade(n, fragWorld, uLight2, uLightColor2);

			gl_FragColor = vec4(diffuse.rgb * light, diffuse.a);
		}')
	public function new()
	{
		super();
	}
}
