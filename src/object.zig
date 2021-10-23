const rand = @import("std").rand;

const AABB = @import("aabb.zig").AABB;
const Box = @import("box.zig").Box;
const Hit = @import("hit.zig").Hit;
const Materials = @import("materials.zig").Materials;
const Ray = @import("ray.zig").Ray;
const RotateY = @import("rotate.zig").RotateY;
const Sphere = @import("sphere.zig").Sphere;
const Translate = @import("translate.zig").Translate;
const Vec3 = @import("vec3.zig").Vec3;
const XYRect = @import("aarect.zig").XYRect;
const XZRect = @import("aarect.zig").XZRect;
const YZRect = @import("aarect.zig").YZRect;

pub const Object = struct {
    const TypeTag = enum {
        box,
        rotate_y,
        sphere,
        translate,
        xyrect,
        xzrect,
        yzrect,
    };

    const Type = union(TypeTag) {
        box: Box,
        rotate_y: RotateY,
        sphere: Sphere,
        translate: Translate,
        xyrect: XYRect,
        xzrect: XZRect,
        yzrect: YZRect,
    };

    name: [*:0]const u8,
    t: Type,
    materials: Materials,
    emittance: Vec3 = Vec3.zero(),

    pub fn bound(self: Object) AABB {
        return switch (self.t) {
            .box => |*b| b.bound(),
            .rotate_y => |*r| r.bound(),
            .sphere => |*s| s.bound(),
            .translate => |*t| t.bound(),
            .xyrect => |*r| r.bound(),
            .xzrect => |*r| r.bound(),
            .yzrect => |*r| r.bound(),
        };
    }

    pub fn intersect(self: Object, ray: Ray, t_min: f64, t_max: f64) ?Hit {
        var maybeHit = switch (self.t) {
            .box => |*b| b.intersect(ray, t_min, t_max),
            .rotate_y => |*r| r.intersect(ray, t_min, t_max),
            .sphere => |*s| s.intersect(ray, t_min, t_max),
            .translate => |*t| t.intersect(ray, t_min, t_max),
            .xyrect => |*r| r.intersect(ray, t_min, t_max),
            .xzrect => |*r| r.intersect(ray, t_min, t_max),
            .yzrect => |*r| r.intersect(ray, t_min, t_max),
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

    pub fn pdfValue(self: Object, origin: Vec3, v: Vec3) f64 {
        return switch (self.t) {
            .xyrect => |*r| r.pdfValue(origin, v),
            .xzrect => |*r| r.pdfValue(origin, v),
            .yzrect => |*r| r.pdfValue(origin, v),
            else => 0.0,
        };
    }

    pub fn random(self: Object, _rand: *rand.Random, origin: Vec3) Vec3 {
        return switch (self.t) {
            .xyrect => |*r| r.random(_rand, origin),
            .xzrect => |*r| r.random(_rand, origin),
            .yzrect => |*r| r.random(_rand, origin),
            else => Vec3.zero(),
        };
    }
};

pub fn asSphere(s: Sphere, name: [*:0]const u8, m: Materials, e: Vec3) Object {
    return Object{
        .name = name,
        .t = .{ .sphere = s },
        .materials = m,
        .emittance = e,
    };
}

pub fn asXYRect(r: XYRect, name: [*:0]const u8, m: Materials, e: Vec3) Object {
    return Object{
        .name = name,
        .t = .{ .xyrect = r },
        .materials = m,
        .emittance = e,
    };
}

pub fn asXZRect(r: XZRect, name: [*:0]const u8, m: Materials, e: Vec3) Object {
    return Object{
        .name = name,
        .t = .{ .xzrect = r },
        .materials = m,
        .emittance = e,
    };
}

pub fn asYZRect(r: YZRect, name: [*:0]const u8, m: Materials, e: Vec3) Object {
    return Object{
        .name = name,
        .t = .{ .yzrect = r },
        .materials = m,
        .emittance = e,
    };
}

pub fn asBox(b: Box, name: [*:0]const u8, m: Materials, e: Vec3) Object {
    return Object{
        .name = name,
        .t = .{ .box = b },
        .materials = m,
        .emittance = e,
    };
}

pub fn asRotateY(r: RotateY, name: [*:0]const u8, m: Materials, e: Vec3) Object {
    return Object{
        .name = name,
        .t = .{ .rotate_y = r },
        .materials = m,
        .emittance = e,
    };
}

pub fn asTranslate(t: Translate, name: [*:0]const u8, m: Materials, e: Vec3) Object {
    return Object{
        .name = name,
        .t = .{ .translate = t },
        .materials = m,
        .emittance = e,
    };
}
