package main

import "core:math"
import "core:math/linalg"

Plane :: struct {
	id: uint,
}

Sphere :: struct {
	id: uint,
}

Shape :: struct {
	//TODO: consider switching to an enum and moving id to shape
	data:      union {
		Sphere,
		Plane,
	},
	transform: matrix[4, 4]f32,
	material:  Material,
}

intersection :: proc(shape: Shape, t: f32) -> Intersection {
	i: Intersection
	i.t = t
	i.shape = shape
	return i
}

/*Intersect a unit sphere with a transformed ray*/
intersect_sphere :: proc(s: ^Sphere, owner: Shape, r: Ray, xs: ^[dynamic]Intersection) {
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
	append(xs, intersection(owner, t1))
	append(xs, intersection(owner, t2))
}

intersect :: proc(shape: Shape, r: Ray, xs: ^[dynamic]Intersection) {
	#partial switch &data in shape.data {
	case Sphere:
		m := linalg.inverse(shape.transform)
		trans_r := transform(r, m)
		intersect_sphere(&data, shape, trans_r, xs)
	}
}

transform :: proc(r: Ray, m: matrix[4, 4]f32) -> Ray {
	temp := Ray {
		origin    = m * r.origin,
		direction = m * r.direction,
	}
	return temp
}

make_sphere :: proc(id: uint = 1) -> Shape {
	shape: Shape
	shape.data = Sphere {
		id = id,
	}
	shape.transform = identity_matrix()
	shape.material = material()
	return shape
}

normal_at :: proc(s: Shape, p: vec4) -> vec4 {
	inverse_t := linalg.inverse(s.transform)
	object_point := inverse_t * p
	object_normal := object_point - point(0.0, 0.0, 0.0)
	world_normal := linalg.transpose(inverse_t) * object_normal
	world_normal.w = 0.0
	return linalg.normalize(world_normal)
}
