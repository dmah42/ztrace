const math = @import("std").math;
const rand = @import("std").rand;
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

    pub fn pdfValue(self: XYRect, origin: Vec3, v: Vec3) f64 {
        const maybeHit = self.intersect(Ray.init(origin, v), 0.0001, math.inf(f64));

        if (maybeHit) |hit| {
            const area = (self.x1 - self.x0) * (self.y1 - self.y0);
            const distSqr = hit.t * hit.t * v.lenSqr();
            const cosine = math.fabs(v.dot(hit.n()) / v.len());
            return distSqr / (cosine * area);
        }
        return 0.0;
    }

    pub fn random(self: XYRect, _rand: *rand.Random, origin: Vec3) Vec3 {
        const randomPt = Vec3.init(
            _rand.float(f64) * (self.x1 - self.x0) + self.x0,
            _rand.float(f64) * (self.y1 - self.y0) + self.y0,
            self.k,
        );
        return randomPt.sub(origin);
    }
};

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

    pub fn pdfValue(self: XZRect, origin: Vec3, v: Vec3) f64 {
        const maybeHit = self.intersect(Ray.init(origin, v), 0.0001, math.inf(f64));

        if (maybeHit) |hit| {
            const area = (self.x1 - self.x0) * (self.z1 - self.z0);
            const distSqr = hit.t * hit.t * v.lenSqr();
            const cosine = math.fabs(v.dot(hit.n()) / v.len());
            return distSqr / (cosine * area);
        }
        return 0.0;
    }

    pub fn random(self: XZRect, _rand: *rand.Random, origin: Vec3) Vec3 {
        const randomPt = Vec3.init(
            _rand.float(f64) * (self.x1 - self.x0) + self.x0,
            self.k,
            _rand.float(f64) * (self.z1 - self.z0) + self.z0,
        );
        return randomPt.sub(origin);
    }
};

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

    pub fn pdfValue(self: YZRect, origin: Vec3, v: Vec3) f64 {
        const maybeHit = self.intersect(Ray.init(origin, v), 0.0001, math.inf(f64));

        if (maybeHit) |hit| {
            const area = (self.y1 - self.y0) * (self.z1 - self.z0);
            const distSqr = hit.t * hit.t * v.lenSqr();
            const cosine = math.fabs(v.dot(hit.n()) / v.len());
            return distSqr / (cosine * area);
        }
        return 0.0;
    }

    pub fn random(self: YZRect, _rand: *rand.Random, origin: Vec3) Vec3 {
        const randomPt = Vec3.init(
            self.k,
            _rand.float(f64) * (self.y1 - self.y0) + self.y0,
            _rand.float(f64) * (self.z1 - self.z0) + self.z0,
        );
        return randomPt.sub(origin);
    }
};
