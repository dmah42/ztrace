const vec3 = @import("vec3.zig");

pub const Ray = struct {
    origin: vec3.Vec3,
    direction: vec3.Vec3,

    pub fn init(origin: vec3.Vec3, direction: vec3.Vec3) Ray {
        return .{.origin = origin, .direction = direction, };
    } 

    pub fn at(self: Ray, t: f64) vec3.Vec3 {
        return self.origin.add(self.direction.mult(f64, t));
    }
};