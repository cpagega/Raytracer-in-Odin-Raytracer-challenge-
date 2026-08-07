package main

Material :: struct {
	color:     Color,
	ambient:   f32,
	diffuse:   f32,
	specular:  f32,
	shininess: f32,
}

material :: proc(
	color: Color = {1.0, 1.0, 1.0},
	ambient: f32 = 0.1,
	diffuse: f32 = 0.9,
	specular: f32 = 0.9,
	shininess: f32 = 200.0,
) -> Material {
	return {
		color = color,
		ambient = ambient,
		diffuse = diffuse,
		specular = specular,
		shininess = shininess,
	}
}
