const math = @import("std").math;
const rand = @import("std").rand;
const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;

pub const aspect_ratio: f64 = 16.0 / 9.0;

pub const Camera = struct {
    origin: Vec3,
    lower_left: Vec3,
    horiz: Vec3,
    vert: Vec3,
    lens_radius: f64,
    u: Vec3,
    v: Vec3,
    w: Vec3,

    pub fn basic(from: Vec3, to: Vec3, vfov: f64) Camera {
        return init(from, to, Vec3.init(0.0,1.0,0.0), vfov, 0.0, to.sub(from).len());
    }

    pub fn aperture(from: Vec3, to: Vec3, vfov: f64, a: f64) Camera {
        return init(from, to, Vec3.init(0.0,1.0,0.0), vfov, a, to.sub(from).len());
    }

    pub fn init(from: Vec3, to: Vec3, up: Vec3, vfov: f64, a: f64, focus_dist: f64) Camera {
        const theta = vfov * math.pi / 180.0;
        const h = math.tan(theta / 2.0);
        const view_height = 2.0 * h;
        const view_width = aspect_ratio * view_height;

        const w = vec3.unit(from.sub(to));
        const u = vec3.unit(vec3.cross(up, w));
        const v = vec3.cross(w, u);

        const origin = from;
        const horiz = u.mult(f64, view_width).mult(f64, focus_dist);
        const vert = v.mult(f64, view_height).mult(f64, focus_dist);

        const lower_left = origin.sub(horiz.mult(f64, 0.5))
            .sub(vert.mult(f64, 0.5))
            .sub(w.mult(f64, focus_dist));

        return Camera{
            .origin = origin,
            .lower_left = lower_left,
            .horiz = horiz,
            .vert = vert,
            .lens_radius = a / 2.0,
            .u = u,
            .v = v,
            .w = w,
        };
    }

    pub fn createRay(self: Camera, _rand: *rand.Random, s: f64, t: f64) ray.Ray {
        const rd = vec3.random_in_unit_disc(_rand).mult(f64, self.lens_radius);
        const offset = self.u.mult(f64, rd.x()).add(self.v.mult(f64, rd.y()));

        return ray.Ray{
            .origin = self.origin.add(offset),
            .direction = self.lower_left.add(self.horiz.mult(f64, s)).add(self.vert.mult(f64, t)).sub(self.origin).sub(offset),
        };
    }
};
