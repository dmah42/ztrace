const std = @import("std");

pub const Vec3 = struct {
    x: f64 = 0.0,
    y: f64 = 0.0,
    z: f64 = 0.0,

    pub fn dot(self: Vec3, other: Vec3) f64 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn lenSqr(self: Vec3) f64 {
        return self.dot(self);
    }

    pub fn len(self: Vec3) f64 {
        return std.math.sqrt(self.lenSqr());
    }

    pub fn mult(self: Vec3, comptime T: type, v: T) Vec3 {
        if (@TypeOf(v) == f64) {
            return .{
                .x = self.x * v,
                .y = self.y * v,
                .z = self.z * v,
            };
        } else if (@TypeOf(v) == Vec3) {
            return .{
                .x = self.x * v.x,
                .y = self.y * v.y,
                .z = self.z * v.z,
            };
        }
    }

    pub fn add(self: Vec3, o: Vec3) Vec3 {
        return .{
            .x = self.x + o.x,
            .y = self.y + o.y,
            .z = self.z + o.z,
        };
    }

    pub fn sub(self: Vec3, o: Vec3) Vec3 {
        return .{
            .x = self.x - o.x,
            .y = self.y - o.y,
            .z = self.z - o.z,
        };
    }

    pub fn pow(self: Vec3, p: f64) Vec3 {
        return .{
            .x = std.math.pow(f64, self.x, p),
            .y = std.math.pow(f64, self.y, p),
            .z = std.math.pow(f64, self.z, p),
        };
    }

    pub fn near_zero(self: Vec3) bool {
        const EPSILON = 1e-8;
        return (std.math.fabs(self.x) < EPSILON) and
               (std.math.fabs(self.y) < EPSILON) and
               (std.math.fabs(self.z) < EPSILON);
    }

    pub fn reflect(self: Vec3, n: Vec3) Vec3 {
        // v - 2 * dot(v, n) * n
        return self.sub(n.mult(f64, 2 * self.dot(n)));
    }
};

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return .{ .x = u.y * v.z - u.z * v.y, .y = u.z * v.x - u.x * v.z, .z = u.x * v.y - u.y * v.x };
}

pub fn unit(v: Vec3) Vec3 {
    return v.mult(f64, 1.0 / v.len());
}

pub fn random(rand: *std.rand.Random) Vec3 {
    return .{
        .x = rand.float(f64),
        .y = rand.float(f64),
        .z = rand.float(f64),
    };
}

pub fn random_in_unit_sphere(rand: *std.rand.Random) Vec3 {
    while (true) {
        const v = random(rand);
        if (v.lenSqr() <= 1.0) return v;
    }
}

pub fn random_unit(rand: *std.rand.Random) Vec3 {
    return unit(random_in_unit_sphere(rand));
}
