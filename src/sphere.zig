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

    pub fn pdfValue(self: Sphere, origin: Vec3, v: Vec3) f64 {
        const maybeHit = self.intersect(Ray.init(origin, v), 0.0001, math.inf(f64));

        if (maybeHit) |hit| {
            const cos_theta_max = math.sqrt(1.0 - self.radius * self.radius / (self.center.sub(origin).lenSqr()));
            const solid_angle = 2 * math.pi * (1.0 - cos_theta_max);

            return 1.0 / solid_angle;
        }
        return 0.0;
    }

    pub fn random(self: Sphere, _rand: *rand.Random, origin: Vec3) Vec3 {
        const direction = self.center.sub(origin);
        const dist_sqr = direction.lenSqr();
        const uvw = ONB.buildFromW(direction);
        return uvw.local(random_to_sphere(self.radius, dist_sqr));
    }
};
