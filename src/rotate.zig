const math = @import("std").math;

const AABB = @import("aabb.zig").AABB;
const Hit = @import("hit.zig").Hit;
const Object = @import("object.zig").Object;
const Ray = @import("ray.zig").Ray;
const vec3 = @import("vec3.zig");

const Vec3 = vec3.Vec3;

pub const RotateY = struct {
    _object: *Object,
    _sin_theta: f64,
    _cos_theta: f64,
    _bbox: AABB,

    pub fn init(object: *Object, angle: f64) RotateY {
        const radians = angle * math.pi / 180.0;
        const sin_theta = math.sin(radians);
        const cos_theta = math.cos(radians);

        const bbox = object.bound();

        var min = Vec3.init(math.inf(f64), math.inf(f64), math.inf(f64));
        var max = Vec3.init(-math.inf(f64), -math.inf(f64), -math.inf(f64));

        var i: usize = 0;
        while (i < 2) {
            var j: usize = 0;
            while (j < 2) {
                var k: usize = 0;
                while (k < 2) {
                    const rhs = bbox.minimum.mult(
                        Vec3,
                        Vec3.init(1 - @intToFloat(f64, i), 1 - @intToFloat(f64, j), 1 - @intToFloat(f64, k)),
                    );
                    const lhs = bbox.maximum.mult(
                        Vec3,
                        Vec3.init(
                            @intToFloat(f64, i),
                            @intToFloat(f64, j),
                            @intToFloat(f64, k),
                        ),
                    );
                    const bbox_base = lhs.add(rhs);

                    const newx = cos_theta * bbox_base.x() + sin_theta * bbox_base.z();
                    const newz = -sin_theta * bbox_base.x() + cos_theta * bbox_base.z();

                    const tester = Vec3.init(newx, bbox_base.y(), newz);

                    min = vec3.minimum(min, tester);
                    max = vec3.maximum(max, tester);

                    k += 1;
                }
                j += 1;
            }
            i += 1;
        }

        return .{
            ._object = object,
            ._sin_theta = sin_theta,
            ._cos_theta = cos_theta,
            ._bbox = .{ .minimum = min, .maximum = max },
        };
    }

    pub fn bound(self: RotateY) AABB {
        return self._bbox;
    }

    pub fn intersect(self: RotateY, r: Ray, t_min: f64, t_max: f64) ?Hit {

        ///////////
        // TODO: matrix multiplication
        //origin[0] = cos_theta*origin[0] + 0*origin[1] - sin_theta*origin[2];
        //origin[1] = 0*origin[1] + 1*origin[1] + 0*origin[2];
        //origin[2] = sin_theta*origin[0] + 0*origin[1] + cos_theta*origin[2];

        const origin = Vec3.init(
            self._cos_theta * r.origin.x() - self._sin_theta * r.origin.z(),
            r.origin.y(),
            self._sin_theta * r.origin.x() + self._cos_theta * r.origin.z(),
        );

        const direction = Vec3.init(
            self._cos_theta * r.direction.x() - self._sin_theta * r.direction.z(),
            r.direction.y(),
            self._sin_theta * r.direction.x() + self._cos_theta * r.direction.z(),
        );

        const rotated_r = .{
            .origin = origin,
            .direction = direction,
        };

        const maybeHit = self._object.intersect(rotated_r, t_min, t_max);
        if (maybeHit) |hit| {
            var p = hit.p;
            var n = hit.n();

            p.v[0] = self._cos_theta * p.x() + self._sin_theta * p.z();
            p.v[2] = -self._sin_theta * p.x() + self._cos_theta * p.z();

            n.v[0] = self._cos_theta * n.x() + self._sin_theta * n.z();
            n.v[2] = -self._sin_theta * n.x() + self._cos_theta * n.z();

            var h = Hit{
                .o = self._object.*,
                .t = hit.t,
                .p = p,
                ._n = hit._n,
                ._ff = hit._ff,
            };
            h.set_normal(rotated_r, n);
            return h;
        }

        return null;
    }
};
