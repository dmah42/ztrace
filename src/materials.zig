const std = @import("std");
const math = std.math;
const rand = std.rand;

const Hit = @import("hit.zig").Hit;
const Ray = @import("ray.zig").Ray;
const Scattered = @import("scattered.zig").Scattered;
const vec3 = @import("vec3.zig");
const Vec3 = vec3.Vec3;

pub const Lambertian = struct {
    albedo: Vec3 = Vec3.zero(),

    pub fn scatter(self: Lambertian, _rand: *rand.Random, r: Ray, h: Hit) ?Scattered {
        var target = h.n().add(vec3.random_unit(_rand));
        if (target.near_zero()) {
            target = h.n();
        }
        return Scattered{
            .attenuation = self.albedo,
            .scatteredRay = Ray{ .origin = h.p, .direction = vec3.unit(target) },
        };
    }
};

pub const Mirror = struct {
    albedo: Vec3 = Vec3.zero(),
    fuzz: f64 = 0.0,

    pub fn scatter(self: Mirror, _rand: *rand.Random, r: Ray, h: Hit) ?Scattered {
        const reflected = vec3.unit(r.direction).reflect(h.n());
        if (reflected.dot(h.n()) > 0) {
            return Scattered{
                .attenuation = self.albedo,
                .scatteredRay = Ray{ .origin = h.p, .direction = reflected.add(vec3.random_in_unit_sphere(_rand).mult(f64, self.fuzz)) },
            };
        }
        return null;
    }
};

pub const Dielectric = struct {
    albedo: Vec3 = Vec3.init(1.0, 1.0, 1.0),
    index: f64 = 1.0,

    fn refract(uv: Vec3, n: Vec3, cos_theta: f64, etai_over_etat: f64) Vec3 {
        const r_out_perp = uv.add(n.mult(f64, cos_theta)).mult(f64, etai_over_etat);
        const r_out_para = n.mult(f64, -math.sqrt(math.absFloat(1.0 - r_out_perp.lenSqr())));
        return r_out_perp.add(r_out_para);
    }

    // Use Schlick's approximation for reflectance.
    fn reflectance(cos_theta: f64, ratio: f64) f64 {
        var r0 = (1 - ratio) / (1 + ratio);
        r0 *= r0;
        return r0 + (1 - r0) * math.pow(f64, 1 - cos_theta, 5);
    }

    pub fn scatter(self: Dielectric, _rand: *rand.Random, r: Ray, h: Hit) ?Scattered {
        const ratio: f64 = if (h.ff()) 1.0 / self.index else self.index;

        const uv = vec3.unit(r.direction);

        const cos_theta = math.min(uv.negate().dot(h.n()), 1.0);
        const sin_theta = math.sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = ratio * sin_theta > 1.0;

        const direction = if (cannot_refract or reflectance(cos_theta, ratio) > _rand.float(f64)) uv.reflect(h.n()) else refract(uv, h.n(), cos_theta, ratio);

        return Scattered{ .attenuation = self.albedo, .scatteredRay = Ray{
            .origin = h.p,
            .direction = direction,
        } };
    }
};

pub const Materials = struct {
    lambFac: f32 = 0.0,
    lamb: Lambertian = .{},

    mirrorFac: f32 = 0.0,
    mirror: Mirror = .{},

    dielectricFac: f32 = 0.0,
    dielectric: Dielectric = .{},

    pub fn scatter(self: Materials, _rand: *rand.Random, r: Ray, h: Hit) !?Scattered {
        const total = self.lambFac + self.mirrorFac + self.dielectricFac;

        if (total > 1.0) {
            return error.Overflow;
        }

        if (total < 1.0) {
            return error.Underflow;
        }

        const res = _rand.float(f64) * total;
        if (res < self.lambFac) {
            return self.lamb.scatter(_rand, r, h);
        } else if (res < self.mirrorFac) {
            return self.mirror.scatter(_rand, r, h);
        }
        return self.dielectric.scatter(_rand, r, h);
    }
};
