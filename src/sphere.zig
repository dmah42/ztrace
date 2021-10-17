const std = @import("std");
const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const mat = @import("materials.zig");
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;

pub const Sphere = struct {
    center: Vec3,
    radius: f64,

    pub fn bound(self: Sphere) AABB {
        return .{
            .minimum = self.center.sub(Vec3.init(self.radius, self.radius, self.radius)),
            .maximum = self.center.add(Vec3.init(self.radius, self.radius, self.radius)),
        };
    }

    pub fn intersect(self: Sphere, r: Ray, t_min: f64, t_max: f64) ?Hit {
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

        var h = Hit{
            .t = root,
            .p = r.at(root),
        };
        h.set_normal(r, r.at(root).sub(self.center).mult(f64, 1.0 / self.radius));
        return h;
    }
};
