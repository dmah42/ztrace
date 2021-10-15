const std = @import("std");

const hit = @import("hit.zig");
const ray = @import("ray.zig");
const s = @import("scattered.zig");
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;

pub const Lambertian = struct {
    albedo: Vec3 = Vec3.zero(),

    pub fn scatter(self: Lambertian, rand: *std.rand.Random, r: ray.Ray, h: hit.Hit) ?s.Scattered {
        var target = h.n.add(vec3.random_unit(rand));
        if (target.near_zero()) {
            target = h.n;
        }
        return s.Scattered{
            .attenuation = self.albedo,
            .scatteredRay = ray.Ray{ .origin = h.p, .direction = vec3.unit(target) },
        };
    }
};

pub const Mirror = struct {
    albedo: Vec3 = Vec3.zero(),

    pub fn scatter(self: Mirror, rand: *std.rand.Random, r: ray.Ray, h: hit.Hit) ?s.Scattered {
        const reflected = vec3.unit(r.direction).reflect(h.n);
        if (reflected.dot(h.n) > 0) {
            return s.Scattered{
                .attenuation = self.albedo,
                .scatteredRay = ray.Ray{.origin = h.p, .direction = reflected},
            };
        }
        return null;
    }
};

pub const Materials = struct {
    lambFac: f32 = 0.0,
    lamb: Lambertian = .{},

    mirrorFac: f32 = 0.0,
    mirror: Mirror = .{},

    pub fn scatter(self: Materials, rand: *std.rand.Random, r: ray.Ray, h: hit.Hit) !?s.Scattered {
        const total = self.lambFac + self.mirrorFac;

        if (total > 1.0) {
            return error.Overflow;
        }

        if (total < 1.0) {
            return error.Underflow;
        }

        const res = rand.float(f64) * total;
        if (res < self.lambFac) {
            return self.lamb.scatter(rand, r, h);
        }
        return self.mirror.scatter(rand, r, h);
    }
};