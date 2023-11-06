/* Resources: See mandelbrot.glsl for shader code/general algorithm
 * https://andrewthall.org/papers/df64_qf128.pdf
 */

uniform float real_min;
uniform float imag_min;

uniform float real_diff;
uniform float imag_diff;

uniform float max_iterations;
uniform float inverse_max_iter;

struct float2 { float x; float y; };

float2 quickTwoSum(float a, float b) {
	float s = a + b;
	float e = b - (s - a);
	return float2(s, e);
}

float2 twoSum(float a, float b) {
	float s = a + b;
	float v = s - a;
	float e = (a - (s - v)) + (b - v);
	return float2(s, e);
}

float2 df64_add(float2 a, float2 b) {
	float2 s = twoSum(a.x, b.x);
	float2 t = twoSum(a.y, b.y);
	s.y += t.x;
	s = quickTwoSum(s.x, s.y);
	s.y += t.y;
	s = quickTwoSum(s.x, s.y);
	return s;
}

float2 split(float a) {
	const float split = 4097; // (1 << 12) + 1;
	float t = a * split;
	float a_hi = t - (t - a);
	float a_lo = a - a_hi;
	return float2(a_hi, a_lo);
}

float2 twoProd(float a, float b) {
	float p = a * b;
	float2 aS = split(a);
	float2 bS = split(b);
	float err = ((aS.x * bS.x - p) + aS.x * bS.y + aS.y * bS.x) + aS.y * bS.y;
	return float2(p, err);
}

float2 df64_mult(float2 a, float2 b) {
	float2 p;

	p = twoProd(a.x, b.x);
	p.y += a.x * b.y;
	p.y += a.y * b.x;
	p = quickTwoSum(p.x, p.y);
	return p;
}

bool df64_le(float2 a, float2 b) {
	return (a.x < b.x || (a.x == b.x && a.y <= b.y));
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	const float2 FOUR = float2(4.0, 0.0);
	int n = 0;
	float2 zr = float2(0.0, 0.0);
	float2 zi = float2(0.0, 0.0);
	float2 cr = df64_add(float2(real_min, 0.0), df64_mult(float2(screen_coords.x, 0.0), float2(real_diff, 0.0)));
	float2 ci = df64_add(float2(imag_min, 0.0), df64_mult(float2(screen_coords.y, 0.0), float2(imag_diff, 0.0)));
	while (df64_le(df64_add(df64_mult(zr, zr), df64_mult(zi, zi)), FOUR) && n < max_iterations) {
		float2 old_zr = zr;
		zr = df64_add(df64_mult(zr, zr), df64_mult(float2(-zi.x, -zi.y), zi));
		zi = df64_add(df64_mult(old_zr, zi), df64_mult(old_zr, zi));
		zr = df64_add(zr, cr);
		zi = df64_add(zi, ci);
		n += 1;
	}

	// vec4 pixel = Texel(texture, texture_coords ); //This is the current pixel color
	return vec4(
		1.0 - n * inverse_max_iter,
		0.8 - n * inverse_max_iter,
		1.0 - n * inverse_max_iter,
		1.0
	);
}
