package main

import "core:math"
import "core:math/linalg"
import "core:testing"
import rl "vendor:raylib"

test_scene :: proc() -> Scene {
	scene := Scene {
		shapes = make([dynamic]Shape),
		light  = point_light(point(-10, 10, -10), Color{1, 1, 1}),
	}

	s1 := make_sphere()
	s2 := make_sphere()

	s1.material.color = {0.8, 1.0, 0.6}
	s1.material.diffuse = 0.7
	s1.material.specular = 0.2
	s2.transform = scale(0.5, 0.5, 0.5)

	append(&scene.shapes, s1)
	append(&scene.shapes, s2)
	return scene
}

@(test)
render_world_with_a_camera :: proc(t: ^testing.T) {
	w := test_scene()
	c := new_camera(11, 11, math.PI / 2.0)
	from := point(0, 0, -5)
	to := point(0, 0, 0)
	up := vector(0, 1, 0)
	c.transform = view_transform(from, to, up)
	image: []rl.Color
	image = make([]rl.Color, 11 * 11)
	render(c, w, &image)
	index := 5 * 11 + 5
	rendered_color := Color {
		f32(image[index].r) / 255,
		f32(image[index].g) / 255,
		f32(image[index].b) / 255,
	}
	//
	testing.expect_value(t, nearly_equals(rendered_color, Color{0.38066, 0.47583, 0.2855}), true)
	testing.expect_value(t, rendered_color, Color{0.38066, 0.47583, 0.2855})

}

@(test)
ray_through_center_of_canvas :: proc(t: ^testing.T) {
	c := new_camera(201, 101, math.PI / 2.0)
	r := ray_for_pixel(c, 100, 50)
	testing.expect_value(t, nearly_equals(r.origin, point(0, 0, 0)), true)
	testing.expect_value(t, nearly_equals(r.direction, vector(0, 0, -1)), true)
}

@(test)
ray_through_corner_of_canvas :: proc(t: ^testing.T) {
	c := new_camera(201, 101, math.PI / 2.0)
	r := ray_for_pixel(c, 0, 0)
	testing.expect_value(t, nearly_equals(r.origin, point(0, 0, 0)), true)
	testing.expect_value(t, nearly_equals(r.direction, vector(0.66519, 0.33259, -0.66851)), true)
}

@(test)
ray_when_camera_is_transformed :: proc(t: ^testing.T) {
	sqrt2over2 := math.sqrt_f32(2) / 2
	c := new_camera(201, 101, math.PI / 2.0)
	c.transform = rot_y(math.PI / 4.0) * translate(0, -2, 5)
	r := ray_for_pixel(c, 100, 50)
	testing.expect_value(t, nearly_equals(r.origin, point(0, 2, -5)), true)
	testing.expect_value(t, nearly_equals(r.direction, vector(sqrt2over2, 0, -sqrt2over2)), true)
}

@(test)
pixel_size_horizontal_canvas :: proc(t: ^testing.T) {
	c := new_camera(200, 125, math.PI / 2.0)
	testing.expect_value(t, c.pixel_size, 0.01)
}
//e
@(test)
pixel_size_vertical_canvas :: proc(t: ^testing.T) {
	c := new_camera(125, 200, math.PI / 2.0)
	testing.expect_value(t, c.pixel_size, 0.01)
}

@(test)
view_transform_default :: proc(t: ^testing.T) {
	from := point(0, 0, 0)
	to := point(0, 0, -1)
	up := vector(0, 1, 0)
	v := view_transform(from, to, up)
	testing.expect_value(t, v, identity_matrix())
}

@(test)
view_transform_positive_z :: proc(t: ^testing.T) {
	from := point(0, 0, 0)
	to := point(0, 0, 1)
	up := vector(0, 1, 0)
	v := view_transform(from, to, up)
	testing.expect_value(t, v, scale(-1, 1, -1))
}

@(test)
view_transform_translate :: proc(t: ^testing.T) {
	from := point(0, 0, 8)
	to := point(0, 0, 0)
	up := vector(0, 1, 0)
	v := view_transform(from, to, up)
	testing.expect_value(t, v, translate(0, 0, -8))
}

@(test)
view_transform_arbitrary :: proc(t: ^testing.T) {
	from := point(1, 3, 2)
	to := point(4, -2, 8)
	up := vector(1, 1, 0)
	v := view_transform(from, to, up)
	m := matrix[4, 4]f32{
		-0.50709, 0.50709, 0.67612, -2.36643,
		0.76772, 0.60609, 0.12122, -2.82843,
		-0.35857, 0.59761, -0.71714, 0.00000,
		0.00000, 0.00000, 0.00000, 1.00000,
	}
	testing.expect_value(t, v, m)
}

@(test)
color_with_an_intersection_behind_ray :: proc(t: ^testing.T) {
	scene := test_scene()
	scene.shapes[0].material.ambient = 1
	scene.shapes[1].material.ambient = 1
	r := Ray {
		origin    = point(0, 0, 0.75),
		direction = vector(0, 0, -1),
	}
	c := color_at(scene, r)
	testing.expect_value(t, nearly_equals(c, scene.shapes[1].material.color), true)
}

@(test)
color_when_ray_hits :: proc(t: ^testing.T) {
	scene := test_scene()
	r := Ray {
		origin    = point(0, 0, -5),
		direction = vector(0, 0, 1),
	}
	c := color_at(scene, r)
	testing.expect_value(t, nearly_equals(c, Color{0.38066, 0.47583, 0.2855}), true)
}

@(test)
color_when_ray_misses :: proc(t: ^testing.T) {
	scene := test_scene()
	r := Ray {
		origin    = point(0, 0, -5),
		direction = vector(0, 1, 0),
	}
	c := color_at(scene, r)
	testing.expect_value(t, nearly_equals(c, Color{0, 0, 0}), true)
}

@(test)
shading_an_intersection :: proc(t: ^testing.T) {
	scene := test_scene()
	r := Ray {
		origin    = point(0, 0, -5),
		direction = vector(0, 0, 1),
	}
	shape := scene.shapes[0]
	i := intersection(shape, 4)
	comps := prepare_computations(i, r)
	c := shade_hit(scene, comps)
	testing.expect_value(t, nearly_equals(c, Color{0.38066, 0.47583, 0.2855}), true)
}

@(test)
shading_an_intersection_from_the_inside :: proc(t: ^testing.T) {
	scene := test_scene()
	r := Ray {
		origin    = point(0, 0, 0),
		direction = vector(0, 0, 1),
	}
	scene.light = point_light(point(0, 0.25, 0), Color{1, 1, 1})
	shape := scene.shapes[1]
	i := intersection(shape, 0.5)
	comps := prepare_computations(i, r)
	c := shade_hit(scene, comps)
	testing.expect_value(t, nearly_equals(c, Color{0.90498, 0.90498, 0.90498}), true)
}

@(test)
hit_when_intersection_outside :: proc(t: ^testing.T) {
	r := Ray {
		origin    = point(0, 0, -5),
		direction = vector(0, 0, 1),
	}
	shape := make_sphere()
	i := intersection(shape, 4)
	comps := prepare_computations(i, r)
	testing.expect_value(t, comps.inside, false)
}

@(test)
hit_when_intersection_inside :: proc(t: ^testing.T) {
	r := Ray {
		origin    = point(0, 0, 0),
		direction = vector(0, 0, 1),
	}
	shape := make_sphere()
	i := intersection(shape, 1)
	comps := prepare_computations(i, r)
	testing.expect_value(t, comps.point, point(0, 0, 1))
	testing.expect_value(t, comps.eyev, vector(0, 0, -1))
	testing.expect_value(t, comps.inside, true)
	testing.expect_value(t, comps.normv, vector(0, 0, -1))

}

@(test)
intersect_scene_with_ray :: proc(t: ^testing.T) {
	scene := test_scene()
	r := Ray{point(0, 0, -5), vector(0, 0, 1)}
	xs := intersect_scene(scene, r)
	testing.expect_value(t, len(xs), 4)
	testing.expect_value(t, xs[0].t, 4)
	testing.expect_value(t, xs[1].t, 4.5)
	testing.expect_value(t, xs[2].t, 5.5)
	testing.expect_value(t, xs[3].t, 6)
}

@(test)
lighting_tests :: proc(t: ^testing.T) {
	m := material()
	p := point(0, 0, 0)
	lighting_eye_between_light_and_surface(t, m, p)
	lighting_eye_between_light_and_surface_eye_45(t, m, p)
	lighting_eye_opposite_surface_light_45(t, m, p)
	lighting_eye_inpath_reflection_vector(t, m, p)
	lighting_light_behind_surface(t, m, p)
}

lighting_eye_between_light_and_surface :: proc(t: ^testing.T, m: Material, p: vec4) {
	eyev := vector(0, 0, -1)
	normv := vector(0, 0, -1)
	light := point_light(point(0, 0, -10), Color{1, 1, 1})
	result := lighting(m, light, p, eyev, normv)
	testing.expect_value(t, nearly_equals(result, Color{1.9, 1.9, 1.9}), true)
}

lighting_eye_between_light_and_surface_eye_45 :: proc(t: ^testing.T, m: Material, p: vec4) {
	x := math.sqrt_f32(2) / 2
	eyev := vector(0, x, -x)
	normv := vector(0, 0, -1)
	light := point_light(point(0, 0, -10), Color{1, 1, 1})
	result := lighting(m, light, p, eyev, normv)
	testing.expect_value(t, nearly_equals(result, Color{1, 1, 1}), true)
}

lighting_eye_opposite_surface_light_45 :: proc(t: ^testing.T, m: Material, p: vec4) {
	eyev := vector(0, 0, -1)
	normv := vector(0, 0, -1)
	light := point_light(point(0, 10, -10), Color{1, 1, 1})
	result := lighting(m, light, p, eyev, normv)
	testing.expect_value(t, nearly_equals(result, Color{0.7364, 0.7364, 0.7364}), true)
}

lighting_eye_inpath_reflection_vector :: proc(t: ^testing.T, m: Material, p: vec4) {
	x := math.sqrt_f32(2) / 2
	eyev := vector(0, -x, -x)
	normv := vector(0, 0, -1)
	light := point_light(point(0, 10, -10), Color{1, 1, 1})
	result := lighting(m, light, p, eyev, normv)
	testing.expect_value(t, nearly_equals(result, Color{1.6364, 1.6364, 1.6364}), true)
}

lighting_light_behind_surface :: proc(t: ^testing.T, m: Material, p: vec4) {
	eyev := vector(0, 0, -1)
	normv := vector(0, 0, -1)
	light := point_light(point(0, 0, 10), Color{1, 1, 1})
	result := lighting(m, light, p, eyev, normv)
	testing.expect_value(t, nearly_equals(result, Color{0.1, 0.1, 0.1}), true)
}
@(test)
sphere_normal_at_x :: proc(t: ^testing.T) {
	s := make_sphere(18)
	n := normal_at(s, point(1.0, 0.0, 0.0))
	testing.expect_value(t, n, vector(1.0, 0.0, 0.0))
}

@(test)
sphere_normal_at_y :: proc(t: ^testing.T) {
	s := make_sphere(24)
	n := normal_at(s, point(0.0, 1.0, 0.0))
	testing.expect_value(t, n, vector(0.0, 1.0, 0.0))
}

@(test)
sphere_normal_at_z :: proc(t: ^testing.T) {
	s := make_sphere(30)
	n := normal_at(s, point(0.0, 0.0, 1.0))
	testing.expect_value(t, n, vector(0.0, 0.0, 1.0))
}

@(test)
sphere_normal_at_nonaxial :: proc(t: ^testing.T) {
	s := make_sphere(36)
	x := math.sqrt_f32(3.0) / 3.0
	n := normal_at(s, point(x, x, x))
	testing.expect_value(t, nearly_equals(n, vector(x, x, x)), true)
}

@(test)
normal_is_normalized :: proc(t: ^testing.T) {
	s := make_sphere(43)
	x := math.sqrt_f32(3.0) / 3.0
	n := linalg.normalize(normal_at(s, point(x, x, x)))
	testing.expect_value(t, nearly_equals(n, vector(x, x, x)), true)
}

@(test)
normal_at_translated :: proc(t: ^testing.T) {
	s := make_sphere(56)
	s.transform = translate(0.0, 1.0, 0.0)
	n := normal_at(s, point(0.0, 1.70711, -0.70711))
	testing.expect_value(t, nearly_equals(n, vector(0.0, 0.70711, -0.70711)), true)
}

@(test)
normal_at_transformed :: proc(t: ^testing.T) {
	s := make_sphere(64)
	s.transform = scale(1.0, 0.5, 1.0) * rot_z(math.PI / 5.0)
	x := math.sqrt_f32(2.0) / 2.0
	n := normal_at(s, point(0.0, x, -x))
	testing.expect_value(t, nearly_equals(n, vector(0.0, 0.97014, -0.24254)), true)
}


@(test)
ray_translated :: proc(t: ^testing.T) {
	r := Ray {
		origin    = point(1.0, 2.0, 3.0),
		direction = vector(0.0, 1.0, 0.0),
	}
	m := translate(3.0, 4.0, 5.0)
	r2 := transform(r, m)
	testing.expect_value(t, r2.origin, point(4.0, 6.0, 8.0))
	testing.expect_value(t, r2.direction, vector(0.0, 1.0, 0.0))
}

@(test)
ray_scaled :: proc(t: ^testing.T) {
	r := Ray {
		origin    = point(1.0, 2.0, 3.0),
		direction = vector(0.0, 1.0, 0.0),
	}
	m := scale(2.0, 3.0, 4.0)
	r2 := transform(r, m)
	testing.expect_value(t, r2.origin, point(2.0, 6.0, 12.0))
	testing.expect_value(t, r2.direction, vector(0.0, 3.0, 0.0))
}

@(test)
ray_position_at_distances :: proc(t: ^testing.T) {
	r := Ray {
		origin    = point(2.0, 3.0, 4.0),
		direction = vector(1.0, 0.0, 0.0),
	}

	testing.expect_value(t, position(r, 0.0), point(2.0, 3.0, 4.0))

	testing.expect_value(t, position(r, 1.0), point(3.0, 3.0, 4.0))

	testing.expect_value(t, position(r, -1.0), point(1.0, 3.0, 4.0))

	testing.expect_value(t, position(r, 2.5), point(4.5, 3.0, 4.0))
}


@(test)
intersection_stores_t_and_shape :: proc(t: ^testing.T) {
	shape := make_sphere(91)
	i := intersection(shape, 3.5)

	testing.expect_value(t, i.t, f32(3.5))
	testing.expect(t, i.shape == shape, "intersection did not retain the owning shape pointer")
}

@(test)
intersecting_a_scaled_sphere_with_a_ray :: proc(t: ^testing.T) {
	shape := make_sphere(104)
	sphere := &shape.data.(Sphere)

	r := Ray {
		origin    = point(0.0, 0.0, -5.0),
		direction = vector(0.0, 0.0, 1.0),
	}
	shape.transform = scale(2.0, 2.0, 2.0)
	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)
	testing.expect_value(t, len(xs), 2)
	testing.expect_value(t, xs[0].t, f32(3.0))
	testing.expect_value(t, xs[1].t, f32(7.0))
}

@(test)
intersecting_a_translated_sphere_with_a_ray :: proc(t: ^testing.T) {
	shape := make_sphere(123)
	sphere := &shape.data.(Sphere)

	r := Ray {
		origin    = point(0.0, 0.0, -5.0),
		direction = vector(0.0, 0.0, 1.0),
	}
	shape.transform = translate(5.0, 0.0, 0.0)
	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)

	testing.expect_value(t, len(xs), 0)
}

@(test)
ray_intersects_sphere_at_two_points :: proc(t: ^testing.T) {
	shape := make_sphere(141)
	sphere := &shape.data.(Sphere)

	r := Ray {
		origin    = point(0.0, 0.0, -5.0),
		direction = vector(0.0, 0.0, 1.0),
	}

	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)

	testing.expect_value(t, len(xs), 2)
	testing.expect_value(t, xs[0].t, f32(4.0))
	testing.expect_value(t, xs[1].t, f32(6.0))

	testing.expect(t, xs[0].shape == shape, "first intersection contains the wrong shape pointer")

	testing.expect(t, xs[1].shape == shape, "second intersection contains the wrong shape pointer")
}


@(test)
ray_intersects_sphere_at_tangent :: proc(t: ^testing.T) {
	shape := make_sphere(174)
	sphere := &shape.data.(Sphere)

	r := Ray {
		origin    = point(0.0, 1.0, -5.0),
		direction = vector(0.0, 0.0, 1.0),
	}

	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)

	testing.expect_value(t, len(xs), 2)
	testing.expect_value(t, xs[0].t, f32(5.0))
	testing.expect_value(t, xs[1].t, f32(5.0))
}


@(test)
ray_misses_sphere :: proc(t: ^testing.T) {
	shape := make_sphere(195)
	sphere := &shape.data.(Sphere)

	r := Ray {
		origin    = point(0.0, 2.0, -5.0),
		direction = vector(0.0, 0.0, 1.0),
	}

	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)

	testing.expect_value(t, len(xs), 0)
}


@(test)
ray_originates_inside_sphere :: proc(t: ^testing.T) {
	shape := make_sphere(214)
	sphere := &shape.data.(Sphere)

	r := Ray {
		origin    = point(0.0, 0.0, 0.0),
		direction = vector(0.0, 0.0, 1.0),
	}

	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)

	testing.expect_value(t, len(xs), 2)
	testing.expect_value(t, xs[0].t, f32(-1.0))
	testing.expect_value(t, xs[1].t, f32(1.0))
}


@(test)
sphere_is_behind_ray :: proc(t: ^testing.T) {
	shape := make_sphere(235)
	sphere := &shape.data.(Sphere)

	r := Ray {
		origin    = point(0.0, 0.0, 5.0),
		direction = vector(0.0, 0.0, 1.0),
	}

	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)

	testing.expect_value(t, len(xs), 2)
	testing.expect_value(t, xs[0].t, f32(-6.0))
	testing.expect_value(t, xs[1].t, f32(-4.0))
}


@(test)
generic_intersect_dispatches_to_sphere :: proc(t: ^testing.T) {
	shape := make_sphere(256)

	r := Ray {
		origin    = point(0.0, 0.0, -5.0),
		direction = vector(0.0, 0.0, 1.0),
	}

	xs := make([dynamic]Intersection)
	defer delete(xs)

	intersect(shape, r, &xs)

	testing.expect_value(t, len(xs), 2)
	testing.expect_value(t, xs[0].t, f32(4.0))
	testing.expect_value(t, xs[1].t, f32(6.0))

	testing.expect(t, xs[0].shape == shape, "generic intersect lost the owning Shape pointer")

	testing.expect(t, xs[1].shape == shape, "generic intersect lost the owning Shape pointer")
}

@(test)
vector_reflect_45 :: proc(t: ^testing.T) {
	r := reflect(vector(1.0, -1.0, 0.0), vector(0.0, 1.0, 0.0))
	testing.expect_value(t, nearly_equals(r, vector(1.0, 1.0, 0.0)), true)
}

@(test)
vector_reflect_slanted_surface :: proc(t: ^testing.T) {
	x := math.sqrt_f32(2.0) / 2.0
	r := reflect(vector(0.0, -1.0, 0.0), vector(x, x, 0))
	testing.expect_value(t, nearly_equals(r, vector(1.0, 0.0, 0.0)), true)
}
