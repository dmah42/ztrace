const math = @import("std").math;
const meta = @import("std").meta;
const rand = @import("std").rand;

const Vector = meta.Vector;

pub const Vec3 = struct {
    v: Vector(3, f64),

    pub fn x(self: Vec3) f64 {
        return self.v[0];
    }
    pub fn y(self: Vec3) f64 {
        return self.v[1];
    }
    pub fn z(self: Vec3) f64 {
        return self.v[2];
    }

    pub fn init(_x: f64, _y: f64, _z: f64) Vec3 {
        return .{ .v = .{
            _x,
            _y,
            _z,
        } };
    }

    pub fn zero() Vec3 {
        return .{ .v = .{ 0.0, 0.0, 0.0 } };
    }

    pub fn dot(self: Vec3, other: Vec3) f64 {
        const vv = self.v * other.v;
        return vv[0] + vv[1] + vv[2];
    }

    pub fn lenSqr(self: Vec3) f64 {
        return self.dot(self);
    }

    pub fn len(self: Vec3) f64 {
        return math.sqrt(self.lenSqr());
    }

    pub fn mult(self: Vec3, comptime T: type, v: T) Vec3 {
        if (@TypeOf(v) == f64) {
            return .{ .v = self.v * @splat(3, v) };
        } else if (@TypeOf(v) == Vec3) {
            return .{ .v = self.v * v.v };
        }
    }

    pub fn add(self: Vec3, o: Vec3) Vec3 {
        return .{ .v = self.v + o.v };
    }

    pub fn sub(self: Vec3, o: Vec3) Vec3 {
        return .{ .v = self.v - o.v };
    }

    pub fn pow(self: Vec3, p: f64) Vec3 {
        return .{
            .v = .{
                math.pow(f64, self.v[0], p),
                math.pow(f64, self.v[1], p),
                math.pow(f64, self.v[2], p),
            },
        };
    }

    pub fn near_zero(self: Vec3) bool {
        const EPSILON = 1e-8;
        return (math.fabs(self.v[0]) < EPSILON) and
            (math.fabs(self.v[1]) < EPSILON) and
            (math.fabs(self.v[2]) < EPSILON);
    }

    pub fn reflect(self: Vec3, n: Vec3) Vec3 {
        // v - 2 * dot(v, n) * n
        return self.sub(n.mult(f64, 2 * self.dot(n)));
    }
};

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return .{ .v = .{
        u[1] * v[2] - u[2] * v[1],
        u[2] * v[0] - u[0] * v[2],
        u[0] * v[1] - u[1] * v[0],
    } };
}

pub fn unit(v: Vec3) Vec3 {
    return v.mult(f64, 1.0 / v.len());
}

pub fn random(_rand: *rand.Random) Vec3 {
    return .{
        .v = .{
            _rand.float(f64),
            _rand.float(f64),
            _rand.float(f64),
        },
    };
}

pub fn random_in_unit_sphere(_rand: *rand.Random) Vec3 {
    while (true) {
        const v = random(_rand);
        if (v.lenSqr() <= 1.0) return v;
    }
}

pub fn random_unit(_rand: *rand.Random) Vec3 {
    return unit(random_in_unit_sphere(_rand));
}