const std = @import("std");
const hit = @import("hit.zig");
const ray = @import("ray.zig");
const vec3 = @import("vec3.zig");

pub const Sphere = struct {
    center: vec3.Vec3,
    radius: f32,

    pub fn intersect(self: Sphere, r: ray.Ray, t_min: f32, t_max: f32) ?hit.Hit {
        const oc = r.origin.sub(self.center);
        const a = r.direction.lenSqr();
        const half_b = oc.dot(r.direction);
        const c = oc.lenSqr() - self.radius * self.radius;
        const disc = half_b * half_b - a * c;

        if (disc < 0.0) {
            return null;
        }

        const sqrt_disc = std.math.sqrt(disc);

        // Nearest root in acceptable range
        var root = (-half_b - sqrt_disc) / a;
        if (root < t_min or root > t_max) {
            root = (-half_b + sqrt_disc) / a;
            if (root < t_min or root > t_max)
                return null;
        }

        return hit.Hit{
            .t = root,
            .p = r.at(root),
            .n = r.at(root).sub(self.center).mult(1.0 / self.radius),
        };
    }
};