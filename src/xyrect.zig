const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Materials = @import("materials.zig").Materials;
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;

pub const XYRect = struct {
    x0: f64,
    x1: f64,

    y0: f64,
    y1: f64,

    k: f64,

    pub fn bound(self: XYRect) AABB {
        return .{
            .minimum = Vec3.init(self.x0, self.y0, self.k - 0.0001),
            .maximum = Vec3.init(self.x1, self.y1, self.k + 0.0001),
        };
    }

    pub fn intersect(self: XYRect, r: Ray, t_min: f64, t_max: f64) ?Hit {
        const t = (self.k - r.origin.z()) / r.direction.z();
        if (t < t_min or t > t_max) {
            return null;
        }

        const xy = r.at(t);
        if (xy.x() < self.x0 or xy.x() > self.x1 or xy.y() < self.y0 or xy.y() > self.y1) {
            return null;
        }

        var h = Hit{
            .t = t,
            .p = xy,
        };
        h.set_normal(r, Vec3.init(0, 0, 1));
        return h;
    }
};
