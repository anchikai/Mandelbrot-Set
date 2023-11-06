/* Resources:
 * https://blogs.love2d.org/content/beginners-guide-shaders
 * https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.1.20.pdf
 *
 * For this document, you need to use `#pragma language glsl3`
 * https://registry.khronos.org/OpenGL/specs/gl/GLSLangSpec.3.30.pdf
 *
 * https://love2d.org/wiki/love.graphics.newShader
 */

uniform float real_min;
uniform float imag_min;

uniform float real_diff;
uniform float imag_diff;

uniform float max_iterations;
uniform float inverse_max_iter;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
	int n = 0;
	number zr = 0.0;
	number zi = 0.0;
	number cr = real_min + screen_coords.x * real_diff;
	number ci = imag_min + screen_coords.y * imag_diff;
	while (zr * zr + zi * zi <= 4 && n < max_iterations) {
		number old_zr = zr;
		number old_zi = zi;
		zr = old_zr * old_zr - old_zi * old_zi;
		zi = old_zr * old_zi + old_zr * old_zi;
		zr = zr + cr;
		zi = zi + ci;
		n = n + 1;
	}

	// vec4 pixel = Texel(texture, texture_coords ); //This is the current pixel color
	return vec4(
		1.0 - n * inverse_max_iter,
		0.8 - n * inverse_max_iter,
		1.0 - n * inverse_max_iter,
		1.0
	);
}
