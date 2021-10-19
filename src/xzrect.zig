const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Materials = @import("materials.zig").Materials;
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;

pub const XZRect = struct {
    x0: f64,
    x1: f64,

    z0: f64,
    z1: f64,

    k: f64,

    pub fn bound(self: XZRect) AABB {
        return .{
            .minimum = Vec3.init(self.x0, self.k - 0.0001, self.z0),
            .maximum = Vec3.init(self.x1, self.k + 0.0001, self.z1),
        };
    }

    pub fn intersect(self: XZRect, r: Ray, t_min: f64, t_max: f64) ?Hit {
        const t = (self.k - r.origin.y()) / r.direction.y();
        if (t < t_min or t > t_max) {
            return null;
        }

        const xz = r.at(t);
        if (xz.x() < self.x0 or xz.x() > self.x1 or xz.z() < self.z0 or xz.z() > self.z1) {
            return null;
        }

        var h = Hit{
            .t = t,
            .p = xz,
        };
        h.set_normal(r, Vec3.init(0, 1, 0));
        return h;
    }
};
