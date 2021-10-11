const vec3 = @import("vec3.zig");

pub const Hit = struct {
    t: f32,
    p: vec3.Vec3,
    n: vec3.Vec3,
};