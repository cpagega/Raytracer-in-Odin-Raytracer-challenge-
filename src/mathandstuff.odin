package main
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

vec4 :: [4]f32
Color :: [3]f32
point :: proc(x, y, z: f32) -> vec4 {
	return vec4{x, y, z, 1.0}
}

vector :: proc(x, y, z: f32) -> vec4 {
	return vec4{x, y, z, 0.0}
}

to_rgba :: proc(c: Color) -> rl.Color {
	return {
		u8(math.round(clamp(c.r, 0.0, 1.0) * 255.0)),
		u8(math.round(clamp(c.g, 0.0, 1.0) * 255.0)),
		u8(math.round(clamp(c.b, 0.0, 1.0) * 255.0)),
		255,
	}
}

nearly_equals :: proc {
	nearly_equals_vec4,
	nearly_equals_color,
}

nearly_equals_vec4 :: proc(a, b: vec4, epsilon: f32 = 1e-4) -> bool {
	for i in 0 ..< len(a) {
		if abs(a[i] - b[i]) > epsilon {
			return false
		}
	}
	return true
}

nearly_equals_color :: proc(a, b: Color, epsilon: f32 = 1e-4) -> bool {
	for i in 0 ..< len(a) {
		if abs(a[i] - b[i]) > epsilon {
			return false
		}
	}
	return true
}

view_transform :: proc(from, to, up: vec4) -> matrix[4, 4]f32 {
	forward := linalg.normalize(to - from)
	upn := linalg.normalize(up)
	left := cross(forward, upn)
	true_up := cross(left, forward)
	orientation := matrix[4, 4]f32{
		left.x, left.y, left.z, 0,
		true_up.x, true_up.y, true_up.z, 0,
		-forward.x, -forward.y, -forward.z, 0,
		0, 0, 0, 1,
	}
	return orientation * translate(-from.x, -from.y, -from.z)
}

/* reflects a vector around a normal vector */
reflect :: proc(v, normal: vec4) -> vec4 {
	return v - normal * 2 * dot(v, normal)
}

identity_matrix :: proc() -> matrix[4, 4]f32 {
	return matrix[4, 4]f32{
		1.0, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
	}
}

translate :: proc(x, y, z: f32) -> matrix[4, 4]f32 {
	return matrix[4, 4]f32{
		1.0, 0.0, 0.0, x,
		0.0, 1.0, 0.0, y,
		0.0, 0.0, 1.0, z,
		0.0, 0.0, 0.0, 1.0,
	}
}

rot_x :: proc(angle: f32) -> matrix[4, 4]f32 {
	s := math.sin(angle)
	c := math.cos(angle)
	return matrix[4, 4]f32{
		1.0, 0.0, 0.0, 0.0,
		0.0, c, -s, 0.0,
		0.0, s, c, 0.0,
		0.0, 0.0, 0.0, 1.0,
	}
}

rot_y :: proc(angle: f32) -> matrix[4, 4]f32 {
	s := math.sin(angle)
	c := math.cos(angle)
	return matrix[4, 4]f32{
		c, 0.0, s, 0.0,
		0.0, 1.0, 0.0, 0.0,
		-s, 0.0, c, 0.0,
		0.0, 0.0, 0.0, 1.0,
	}
}

rot_z :: proc(angle: f32) -> matrix[4, 4]f32 {
	s := math.sin(angle)
	c := math.cos(angle)
	return matrix[4, 4]f32{
		c, -s, 0.0, 0.0,
		s, c, 0.0, 0.0,
		0.0, 0.0, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
	}
}

scale :: proc(x, y, z: f32) -> matrix[4, 4]f32 {
	return matrix[4, 4]f32{
		x, 0.0, 0.0, 0.0,
		0.0, y, 0.0, 0.0,
		0.0, 0.0, z, 0.0,
		0.0, 0.0, 0.0, 1.0,
	}
}

shear :: proc(xy, xz, yx, yz, zx, zy: f32) -> matrix[4, 4]f32 {
	return matrix[4, 4]f32{
		1.0, yx, zx, 0.0,
		xy, 1.0, zy, 0.0,
		xz, yz, 1.0, 0.0,
		0.0, 0.0, 0.0, 1.0,
	}
}


dot :: proc(a, b: vec4) -> f32 {
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
}

cross :: proc(a, b: vec4) -> vec4 {
	return vector(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
}
