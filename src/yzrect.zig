const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Materials = @import("materials.zig").Materials;
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;

pub const YZRect = struct {
    y0: f64,
    y1: f64,

    z0: f64,
    z1: f64,

    k: f64,

    pub fn bound(self: YZRect) AABB {
        return .{
            .minimum = Vec3.init(self.k - 0.0001, self.y0, self.z0),
            .maximum = Vec3.init(self.k + 0.0001, self.y1, self.z1),
        };
    }

    pub fn intersect(self: YZRect, r: Ray, t_min: f64, t_max: f64) ?Hit {
        const t = (self.k - r.origin.x()) / r.direction.x();
        if (t < t_min or t > t_max) {
            return null;
        }

        const yz = r.at(t);
        if (yz.y() < self.y0 or yz.y() > self.y1 or yz.z() < self.z0 or yz.z() > self.z1) {
            return null;
        }

        var h = Hit{
            .t = t,
            .p = yz,
        };
        h.set_normal(r, Vec3.init(1, 0, 0));
        return h;
    }
};
