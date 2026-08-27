package main
import "core:math"
import "core:math/linalg"

lighting :: proc(
	material: Material,
	light: Light,
	hit_point: vec4,
	eyev: vec4,
	normv: vec4,
	in_shadow: bool = false,
) -> Color {
	// combine the surface color with the light's color/intensity
	effective_color := material.color * light.intensity

	// find the direction to the light source from ray hit
	lightv := linalg.normalize(light.position - hit_point)

	//compute the ambient contribution
	ambient := effective_color * material.ambient

	/* light_dot_normal represents the cosine of the angle between the
       light vector and the normal vector. A negative number means the 
       light is on the other side of the surface. 
    */
	light_dot_normal := dot(lightv, normv)
	diffuse: Color
	specular: Color
	black := Color{0, 0, 0}
	if light_dot_normal < 0 || in_shadow {
		diffuse = black
		specular = black
	} else {
		// compute the diffuse contribution
		diffuse = effective_color * material.diffuse * light_dot_normal

		/* reflect_dot_eye represents the cosine of the angle between the 
           reflection vector and the eye vector. A negative number means the 
           light reflects away from the eye.
        */
		reflectv := reflect(-lightv, normv)
		reflect_dot_eye := dot(reflectv, eyev)
		if reflect_dot_eye <= 0 {
			specular = black
		} else {
			// compute the specular contribution
			factor := math.pow(reflect_dot_eye, material.shininess)
			specular = light.intensity * material.specular * factor
		}
	}
	return ambient + diffuse + specular
}
