const math = @import("std").math;
const ray = @import("ray.zig");
const Vec3 = @import("vec3.zig").Vec3;

pub const aspect_ratio: f64 = 16.0 / 9.0;

pub const Camera = struct {
    origin: Vec3,
    lower_left: Vec3,
    horiz: Vec3,
    vert: Vec3,

    pub fn init(vfov: f64) Camera {
        const theta = vfov * math.pi / 180.0;
        const h = math.tan(theta / 2.0);
        const view_height = 2.0 * h;
        const view_width = aspect_ratio * view_height;

        const focal = 1.0;

        const origin = Vec3.zero();
        const horiz = Vec3.init(view_width, 0.0, 0.0);
        const vert = Vec3.init(0.0, view_height, 0.0);

        const lower_left = origin.sub(horiz.mult(f64, 0.5))
            .sub(vert.mult(f64, 0.5))
            .sub(Vec3.init(0.0, 0.0, focal));

        return Camera{
            .origin = origin,
            .lower_left = lower_left,
            .horiz = horiz,
            .vert = vert,
        };
    }

    pub fn createRay(self: Camera, u: f64, v: f64) ray.Ray {
        return ray.Ray{
            .origin = self.origin,
            .direction = self.lower_left.add(self.horiz.mult(f64, u)).add(self.vert.mult(f64, v)).sub(self.origin),
        };
    }
};
