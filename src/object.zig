const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;

pub const Object = struct {
    const TypeTag = enum {
        sphere,
    };

    const Type = union(TypeTag) {
        sphere: Sphere,
        // .rect
    };

    t: Type,

    pub fn bound(self: Object) AABB {
        return switch (self.t) {
            .sphere => |*s| s.bound(),
        };
    }

    pub fn intersect(self: Object, r: Ray, t_min: f64, t_max: f64) ?Hit {
        return switch (self.t) {
            .sphere => |*s| s.intersect(r, t_min, t_max),
        };
    }
};

pub fn asSphere(s: Sphere) Object {
    return Object{ .t = .{
        .sphere = s,
    } };
}
