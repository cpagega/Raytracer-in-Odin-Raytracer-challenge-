package main

import "core:math"
import "core:math/linalg"

Shape_Kind :: enum {
	Sphere,
	Plane,
}
Shape :: struct {
	kind:            Shape_Kind,
	transform:       matrix[4, 4]f32,
	material:        Material,
	id:              uint,
	local_normal_at: proc(s: Shape, p: vec4) -> vec4,
	local_intersect: proc(s: Shape, r: Ray, xs: ^[dynamic]Intersection),
}

intersection :: proc(shape: Shape, t: f32) -> Intersection {
	i: Intersection
	i.t = t
	i.shape = shape
	return i
}

/*Intersect a unit sphere with a transformed ray*/
intersect_sphere :: proc(s: Shape, r: Ray, xs: ^[dynamic]Intersection) {
	sphere_to_ray := r.origin - point(0.0, 0.0, 0.0)
	a := dot(r.direction, r.direction)
	b := 2 * dot(r.direction, sphere_to_ray)
	c := dot(sphere_to_ray, sphere_to_ray) - 1
	discriminant := b * b - 4 * a * c
	if discriminant < 0 {
		return
	}
	t1 := (-b - math.sqrt(discriminant)) / (2 * a)
	t2 := (-b + math.sqrt(discriminant)) / (2 * a)
	append(xs, intersection(s, t1))
	append(xs, intersection(s, t2))
}
// Intersect xz plane
intersect_plane :: proc(s: Shape, r: Ray, xs: ^[dynamic]Intersection) {
	if math.abs(r.direction.y) < 1E-5 {
		return
	}
	t := -r.origin.y / r.direction.y
	append(xs, intersection(s, t))
}

intersect :: proc(shape: Shape, r: Ray, xs: ^[dynamic]Intersection) {
	// before intersecting a shape, the ray is transformed based on the shapes characteristics into object space
	transformed_ray := ray_to_object_space(r, shape.transform)
	shape.local_intersect(shape, transformed_ray, xs)
}

ray_to_object_space :: proc(r: Ray, m: matrix[4, 4]f32) -> Ray {
	inverse_m := linalg.inverse(m)
	return transform(r, inverse_m)
}

// Applies a shape's transform matrix  to a Ray
transform :: proc(r: Ray, m: matrix[4, 4]f32) -> Ray {
	temp := Ray {
		origin    = m * r.origin,
		direction = m * r.direction,
	}
	return temp
}

// this is  just to keep some old test cases from breaking, make shape should be used otherwise
make_sphere :: proc(id: uint = 1) -> Shape {
	return make_shape(.Sphere)
}

make_shape :: proc(kind: Shape_Kind, id: uint = 1) -> Shape {
	shape: Shape
	shape.kind = kind
	shape.id = id
	shape.transform = identity_matrix()
	shape.material = material()
	#partial switch kind {
	case .Sphere:
		shape.local_intersect = intersect_sphere
		shape.local_normal_at = normal_at_sphere
	case .Plane:
		shape.local_intersect = intersect_plane
		shape.local_normal_at = normal_at_plane
	}
	return shape
}

normal_at_sphere :: proc(s: Shape, p: vec4) -> vec4 {
	return p - point(0.0, 0.0, 0.0)
}

normal_at_plane :: proc(s: Shape, p: vec4) -> vec4 {
	return vector(0, 1, 0)
}

normal_at :: proc(s: Shape, p: vec4) -> vec4 {
	inverse_transform := linalg.inverse(s.transform)
	local_point := inverse_transform * p
	local_normal: vec4
	local_normal = s.local_normal_at(s, local_point)
	world_normal := linalg.transpose(inverse_transform) * local_normal
	world_normal.w = 0.0
	return linalg.normalize(world_normal)
}
