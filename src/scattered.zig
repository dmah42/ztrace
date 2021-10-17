const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");

pub const Scattered = struct {
    attenuation: vec3.Vec3,
    scatteredRay: ray.Ray,
};
