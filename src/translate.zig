const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Object = @import("object.zig").Object;
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;

pub const Translate = struct {
    object: *Object,
    offset: Vec3,

    pub fn bound(self: Translate) AABB {
        const aabb = self.object.bound();
        return .{
            .minimum = aabb.minimum.add(self.offset),
            .maximum = aabb.maximum.add(self.offset),
        };
    }

    pub fn intersect(self: Translate, r: Ray, t_min: f64, t_max: f64) ?Hit {
        const translated_ray = Ray{
            .origin = r.origin.sub(self.offset),
            .direction = r.direction,
        };

        var maybeHit = self.object.intersect(translated_ray, t_min, t_max);
        if (maybeHit) |hit| {
            const p = hit.p.add(self.offset);
            var h = Hit{
                .o = self.object.*,
                .t = hit.t,
                .p = p,
                ._n = hit._n,
                ._ff = hit._ff,
            };
            return h;
        }
        return null;
    }
};
