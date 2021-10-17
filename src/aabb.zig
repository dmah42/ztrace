const std = @import("std");
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;

pub const AABB = struct {
    minimum: Vec3,
    maximum: Vec3,

    pub fn hit(self: AABB, r: Ray, _t_min: f64, _t_max: f64) bool {
        const inv_dir = r.direction.inverse();
        const delta_min = self.minimum.sub(r.origin).mult(Vec3, inv_dir);
        const delta_max = self.maximum.sub(r.origin).mult(Vec3, inv_dir);

        var t_min = _t_min;
        var t_max = _t_max;

        var a: usize = 0;
        while (a < 3) {
            const t0 = std.math.min(delta_min.v[a], delta_max.v[a]);
            const t1 = std.math.max(delta_min.v[a], delta_max.v[a]);

            t_min = std.math.max(t0, t_min);
            t_max = std.math.min(t1, t_max);

            if (t_max <= t_min) return false;

            // auto t0 = fmin((minimum[a] - r.origin()[a]) / r.direction()[a],
            //                (maximum[a] - r.origin()[a]) / r.direction()[a]);
            // auto t1 = fmax((minimum[a] - r.origin()[a]) / r.direction()[a],
            //                (maximum[a] - r.origin()[a]) / r.direction()[a]);
            // t_min = fmax(t0, t_min);
            // t_max = fmin(t1, t_max);
            // if (t_max <= t_min)
            //     return false;

            a += 1;
        }
        return true;
    }
};

pub fn surrounding(left: AABB, right: AABB) AABB {
    const min = Vec3.init(
        std.math.min(left.minimum.x(), right.minimum.x()),
        std.math.min(left.minimum.y(), right.minimum.y()),
        std.math.min(left.minimum.z(), right.minimum.z()),
    );
    const max = Vec3.init(
        std.math.max(left.maximum.x(), right.maximum.x()),
        std.math.max(left.maximum.y(), right.maximum.y()),
        std.math.max(left.maximum.z(), right.maximum.z()),
    );

    return .{ .minimum = min, .maximum = max };
}
