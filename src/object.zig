const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Materials = @import("materials.zig").Materials;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;
const Vec3 = @import("vec3.zig").Vec3;
const XYRect = @import("xyrect.zig").XYRect;

pub const Object = struct {
    const TypeTag = enum {
        sphere,
        xyrect,
    };

    const Type = union(TypeTag) {
        sphere: Sphere,
        xyrect: XYRect,
    };

    t: Type,
    materials: Materials,
    emittance: Vec3 = Vec3.zero(),

    pub fn bound(self: Object) AABB {
        return switch (self.t) {
            .sphere => |*s| s.bound(),
            .xyrect => |*r| r.bound(),
        };
    }

    pub fn intersect(self: Object, ray: Ray, t_min: f64, t_max: f64) ?Hit {
        var maybeHit = switch (self.t) {
            .sphere => |*s| s.intersect(ray, t_min, t_max),
            .xyrect => |*r| r.intersect(ray, t_min, t_max),
        };
        if (maybeHit) |hit| {
            return Hit{
                .o = self,
                .t = hit.t,
                .p = hit.p,
                ._n = hit._n,
                ._ff = hit._ff,
            };
        }
        return null;
    }
};

pub fn asSphere(s: Sphere, m: Materials, e: Vec3) Object {
    return Object{
        .t = .{
            .sphere = s,
        },
        .materials = m,
        .emittance = e,
    };
}

pub fn asXYRect(r: XYRect, m: Materials, e: Vec3) Object {
    return Object{
        .t = .{
            .xyrect = r,
        },
        .materials = m,
        .emittance = e,
    };
}
