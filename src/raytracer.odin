package main

import "core:math"
import "core:math/linalg"
import "core:slice"
import rl "vendor:raylib"

Camera :: struct {
	width:       f32,
	height:      f32,
	aspect:      f32,
	half_width:  f32,
	half_height: f32,
	fov:         f32,
	pixel_size:  f32,
	transform:   matrix[4, 4]f32,
}

Ray :: struct {
	origin:    vec4,
	direction: vec4,
}

Scene :: struct {
	shapes: [dynamic]Shape,
	light:  Light,
}

Intersection :: struct {
	t:     f32,
	shape: Shape,
}

Computations :: struct {
	t:      f32,
	shape:  Shape,
	point:  vec4,
	eyev:   vec4,
	normv:  vec4,
	inside: bool,
}

new_camera :: proc(width, height, fov: f32) -> Camera {
	temp: Camera
	temp.width = width
	temp.height = height
	temp.fov = fov
	temp.transform = identity_matrix()
	half_view := math.tan_f32(fov / 2.0)
	temp.aspect = width / height
	/* Divides the canvas in half depending on the aspect ratio */
	if temp.aspect >= 1 {
		temp.half_width = half_view
		temp.half_height = half_view / temp.aspect
	} else {
		temp.half_width = half_view * temp.aspect
		temp.half_height = half_view
	}
	temp.pixel_size = (temp.half_width * 2) / temp.width
	return temp
}

render :: proc(c: Camera, s: Scene, canvas: ^[]rl.Color) {
	for y in 0 ..< c.height {
		for x in 0 ..< c.width {
			ray := ray_for_pixel(c, x, y)
			color := color_at(s, ray)
			canvas[i32(y * c.width + x)] = to_rgba(color)
		}
	}
}

ray_for_pixel :: proc(c: Camera, px, py: f32) -> Ray {
	// off from the edge of the canvas to the pixel's center
	xoffset := (px + 0.5) * c.pixel_size
	yoffset := (py + 0.5) * c.pixel_size
	// untransformed coordinates of the pixel in world space
	// camera looks from -z, so +x is to the left
	worldx := c.half_width - xoffset
	worldy := c.half_height - yoffset
	// transform the canvas point and the origin using the camera matrix
	// compute the ray's direction vector
	// canvas is at z = -1
	i_transform := linalg.inverse(c.transform)
	pixel := i_transform * point(worldx, worldy, -1)
	origin := i_transform * point(0, 0, 0)
	direction := linalg.normalize(pixel - origin)
	return Ray{origin = origin, direction = direction}
}

prepare_computations :: proc(i: Intersection, r: Ray) -> Computations {
	comps: Computations
	comps.t = i.t
	comps.shape = i.shape
	comps.point = position(r, comps.t)
	comps.eyev = -r.direction
	comps.normv = normal_at(comps.shape, comps.point)
	if dot(comps.normv, comps.eyev) < 0 {
		comps.inside = true
		comps.normv = -comps.normv
	} else {
		comps.inside = false
	}
	return comps
}

// Passing a scene rather than a light because a scene can eventually support multiple light sources
shade_hit :: proc(scene: Scene, comps: Computations) -> Color {
	return lighting(comps.shape.material, scene.light, comps.point, comps.eyev, comps.normv)
}
// Right now color_at is the owner of interesections but we may need to rethink this when we get to reflections
color_at :: proc(scene: Scene, ray: Ray) -> Color {
	intersections := intersect_scene(scene, ray)
	defer delete(intersections)
	intersection, hit := hit(intersections)
	if !hit {
		return {0, 0, 0}
	}
	comps := prepare_computations(intersection, ray)
	return shade_hit(scene, comps)
}

intersect_scene :: proc(s: Scene, r: Ray) -> [dynamic]Intersection {
	intersections := make([dynamic]Intersection)
	for shape in s.shapes {
		intersect(shape, r, &intersections)
	}
	slice.sort_by(intersections[:], less_than)
	return intersections
}

// comparator function for sort_by
less_than :: proc(a, b: Intersection) -> bool {
	return a.t < b.t
}

// Find the position on a ray at time t
position :: proc(r: Ray, t: f32) -> vec4 {
	return r.origin + r.direction * t
}

// return the lowest nonnegative value in xs
hit :: proc(xs: [dynamic]Intersection) -> (Intersection, bool) {
	// Assume xs is sorted
	for x in xs {
		if x.t > 0.0 {
			return x, true
		}
	}
	return {}, false
}
