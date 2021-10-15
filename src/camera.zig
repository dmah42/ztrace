const math = @import("std").math;
const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;

pub const aspect_ratio: f64 = 16.0 / 9.0;

pub const Camera = struct {
    origin: Vec3,
    lower_left: Vec3,
    horiz: Vec3,
    vert: Vec3,

    pub fn init(from: Vec3, to: Vec3, up: Vec3, vfov: f64) Camera {
        const theta = vfov * math.pi / 180.0;
        const h = math.tan(theta / 2.0);
        const view_height = 2.0 * h;
        const view_width = aspect_ratio * view_height;

        const focal = 1.0;

        const w = vec3.unit(from.sub(to));
        const u = vec3.unit(vec3.cross(up, w));
        const v = vec3.cross(w, u);

        const origin = from;
        const horiz = u.mult(f64, view_width);
        const vert = v.mult(f64, view_height);

        const lower_left = origin.sub(horiz.mult(f64, 0.5))
            .sub(vert.mult(f64, 0.5))
            .sub(w.mult(f64, focal));

        return Camera{
            .origin = origin,
            .lower_left = lower_left,
            .horiz = horiz,
            .vert = vert,
        };
    }

    pub fn createRay(self: Camera, s: f64, t: f64) ray.Ray {
        return ray.Ray{
            .origin = self.origin,
            .direction = self.lower_left.add(self.horiz.mult(f64, s)).add(self.vert.mult(f64, t)).sub(self.origin),
        };
    }
};
