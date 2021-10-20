const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;
const XYRect = @import("aarect.zig").XYRect;
const XZRect = @import("aarect.zig").XZRect;
const YZRect = @import("aarect.zig").YZRect;

pub const Box = struct {
    minimum: Vec3,
    maximum: Vec3,

    _left: YZRect = undefined,
    _right: YZRect = undefined,
    _top: XZRect = undefined,
    _bottom: XZRect = undefined,
    _front: XYRect = undefined,
    _back: XYRect = undefined,

    pub fn init(min: Vec3, max: Vec3) Box {
        return .{
            .minimum = min,
            .maximum = max,
            ._left = .{ .y0 = min.y(), .y1 = max.y(), .z0 = min.z(), .z1 = max.z(), .k = min.x() },
            ._right = .{ .y0 = min.y(), .y1 = max.y(), .z0 = min.z(), .z1 = max.z(), .k = max.x() },
            ._top = .{ .x0 = min.x(), .x1 = max.x(), .z0 = min.z(), .z1 = max.z(), .k = max.y() },
            ._bottom = .{ .x0 = min.x(), .x1 = max.x(), .z0 = min.z(), .z1 = max.z(), .k = min.y() },
            ._front = .{ .x0 = min.x(), .x1 = max.x(), .y0 = min.y(), .y1 = max.y(), .k = min.z() },
            ._back = .{ .x0 = min.x(), .x1 = max.x(), .y0 = min.y(), .y1 = max.y(), .k = max.z() },
        };
    }

    pub fn bound(self: Box) AABB {
        return .{
            .minimum = self.minimum,
            .maximum = self.maximum,
        };
    }

    pub fn intersect(self: Box, r: Ray, t_min: f64, t_max: f64) ?Hit {
        var hit: ?Hit = undefined;
        var farthest = t_max;
        var maybeHit = self._left.intersect(r, t_min, farthest);
        if (maybeHit) |h| {
            hit = maybeHit;
            farthest = h.t;
        }
        maybeHit = self._right.intersect(r, t_min, farthest);
        if (maybeHit) |h| {
            hit = maybeHit;
            farthest = h.t;
        }
        maybeHit = self._top.intersect(r, t_min, farthest);
        if (maybeHit) |h| {
            hit = maybeHit;
            farthest = h.t;
        }
        maybeHit = self._bottom.intersect(r, t_min, farthest);
        if (maybeHit) |h| {
            hit = maybeHit;
            farthest = h.t;
        }
        maybeHit = self._front.intersect(r, t_min, farthest);
        if (maybeHit) |h| {
            hit = maybeHit;
            farthest = h.t;
        }
        maybeHit = self._back.intersect(r, t_min, farthest);
        if (maybeHit) |h| {
            hit = maybeHit;
            farthest = h.t;
        }
        return hit;
    }
};
