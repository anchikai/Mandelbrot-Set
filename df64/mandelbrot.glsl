/* Resources: See mandelbrot.glsl for shader code/general algorithm
 * https://andrewthall.org/papers/df64_qf128.pdf
 */

uniform float real_min_hi;
uniform float real_min_lo;
uniform float imag_min_hi;
uniform float imag_min_lo;

uniform float real_diff_hi;
uniform float real_diff_lo;
uniform float imag_diff_hi;
uniform float imag_diff_lo;

uniform float max_iterations;
uniform float inverse_max_iter;

struct float2 { float hi; float lo; };

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
	float2 s = twoSum(a.hi, b.hi);
	float2 t = twoSum(a.lo, b.lo);
	s.lo += t.hi;
	s = quickTwoSum(s.hi, s.lo);
	s.lo += t.lo;
	s = quickTwoSum(s.hi, s.lo);
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
	float err = aS.lo * bS.lo + (
		(aS.hi * bS.hi - p)
		+ aS.hi * bS.lo
		+ aS.lo * bS.hi
	);
	return float2(p, err);
}

float2 df64_mult(float2 a, float2 b) {
	float2 p;

	p = twoProd(a.hi, b.hi);
	p.lo += a.hi * b.lo;
	p.lo += a.lo * b.hi;
	p = quickTwoSum(p.hi, p.lo);
	return p;
}

bool df64_le(float2 a, float2 b) {
	return (a.hi == b.hi && a.lo <= b.lo || a.hi < b.hi);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	const float2 FOUR = float2(4.0, 0.0);
	int n = 0;
	float2 zr = float2(0.0, 0.0);
	float2 zi = float2(0.0, 0.0);
	float2 cr = df64_add(float2(real_min_hi, real_min_lo), df64_mult(float2(screen_coords.x, 0.0), float2(real_diff_hi, real_diff_lo)));
	float2 ci = df64_add(float2(imag_min_hi, imag_min_lo), df64_mult(float2(screen_coords.y, 0.0), float2(imag_diff_hi, imag_diff_lo)));
	while (df64_le(df64_add(df64_mult(zr, zr), df64_mult(zi, zi)), FOUR) && n < max_iterations) {
		float2 old_zr = zr;
		zr = df64_add(df64_mult(zr, zr), df64_mult(float2(-zi.hi, -zi.lo), zi));
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
