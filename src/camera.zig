const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");

pub const aspect_ratio: f64 = 16.0 / 9.0;

pub const Camera = struct {
    origin: vec3.Vec3,
    lower_left: vec3.Vec3,
    horiz: vec3.Vec3,
    vert: vec3.Vec3,

    pub fn init() Camera {
        const view_height = 2.0;
        const view_width = aspect_ratio * view_height;
        const focal = 1.0;

        const origin = vec3.Vec3{};
        const horiz = vec3.Vec3{ .x = view_width };
        const vert = vec3.Vec3{ .y = view_height };

        const lower_left = origin.sub(horiz.mult(0.5))
            .sub(vert.mult(0.5))
            .sub(vec3.Vec3{ .z = focal });

        return Camera {
            .origin = origin,
            .lower_left = lower_left,
            .horiz = horiz,
            .vert = vert,
        };
    }

    pub fn createRay(self: Camera, u: f64, v: f64) ray.Ray {
        return ray.Ray{
            .origin = self.origin,
            .direction = self.lower_left.add(self.horiz.mult(u)).add(self.vert.mult(v)).sub(self.origin),
        };
    }
};