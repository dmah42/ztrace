const sphere = @import("sphere.zig");
const vec3 = @import("vec3.zig");

pub const Hit = struct {
    o: sphere.Sphere,
    t: f64,
    p: vec3.Vec3,
    n: vec3.Vec3,
};