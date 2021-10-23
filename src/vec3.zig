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

    pub fn negate(self: Vec3) Vec3 {
        return .{ .v = .{ -self.v[0], -self.v[1], -self.v[2] } };
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

    pub fn inverse(self: Vec3) Vec3 {
        return .{ .v = .{
            1.0 / self.v[0],
            1.0 / self.v[1],
            1.0 / self.v[2],
        } };
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

    pub fn clamp(self: Vec3, min: f64, max: f64) Vec3 {
        return .{ .v = .{
            math.clamp(self.v[0], min, max),
            math.clamp(self.v[1], min, max),
            math.clamp(self.v[2], min, max),
        } };
    }
};

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return .{ .v = .{
        u.y() * v.z() - u.z() * v.y(),
        u.z() * v.x() - u.x() * v.z(),
        u.x() * v.y() - u.y() * v.x(),
    } };
}

pub fn unit(v: Vec3) Vec3 {
    return v.mult(f64, 1.0 / v.len());
}

pub fn random(_rand: *rand.Random) Vec3 {
    return .{
        .v = .{
            _rand.float(f64) * 2.0 - 1.0,
            _rand.float(f64) * 2.0 - 1.0,
            _rand.float(f64) * 2.0 - 1.0,
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

pub fn random_in_unit_disc(_rand: *rand.Random) Vec3 {
    while (true) {
        const v = Vec3.init(_rand.float(f64) * 2.0 - 1.0, _rand.float(f64) * 2.0 - 1.0, 0.0);
        if (v.lenSqr() < 1.0) return v;
    }
}

pub fn random_cosine_direction(_rand: *rand.Random) Vec3 {
    const r1 = _rand.float(f64);
    const r2 = _rand.float(f64);
    const z = math.sqrt(1 - r2);

    const phi = 2 * math.pi * r1;
    const x = math.cos(phi) * math.sqrt(r2);
    const y = math.sin(phi) * math.sqrt(r2);

    return Vec3.init(x, y, z);
}

pub fn randomToSphere(_rand: *rand.Random, radius: f64, distance_squared: f64) Vec3 {
    const r1 = _rand.float(f64);
    const r2 = _rand.float(f64);
    const z = 1.0 + r2 * (math.sqrt(1.0 - radius * radius / distance_squared) - 1.0);

    const phi = 2 * math.pi * r1;
    const x = math.cos(phi) * math.sqrt(1 - z * z);
    const y = math.sin(phi) * math.sqrt(1 - z * z);

    return Vec3.init(x, y, z);
}

pub fn minimum(a: Vec3, b: Vec3) Vec3 {
    return .{ .v = .{
        math.min(a.v[0], b.v[0]),
        math.min(a.v[1], b.v[1]),
        math.min(a.v[2], b.v[2]),
    } };
}

pub fn maximum(a: Vec3, b: Vec3) Vec3 {
    return .{ .v = .{
        math.max(a.v[0], b.v[0]),
        math.max(a.v[1], b.v[1]),
        math.max(a.v[2], b.v[2]),
    } };
}
