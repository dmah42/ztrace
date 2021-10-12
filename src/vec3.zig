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
            return Vec3{
                .x = self.x * v,
                .y = self.y * v,
                .z = self.z * v,
            };
        } else if (@TypeOf(v) == Vec3) {
            return Vec3{
                .x = self.x * v.x,
                .y = self.y * v.y,
                .z = self.z * v.z,
            };
        }
    }

    pub fn add(self: Vec3, o: Vec3) Vec3 {
        return Vec3{
            .x = self.x + o.x,
            .y = self.y + o.y,
            .z = self.z + o.z,
        };
    }

    pub fn sub(self: Vec3, o: Vec3) Vec3 {
        return Vec3{
            .x = self.x - o.x,
            .y = self.y - o.y,
            .z = self.z - o.z,
        };
    }

    pub fn pow(self: Vec3, p: f64) Vec3 {
        return Vec3{
            .x = std.math.pow(f64, self.x, p),
            .y = std.math.pow(f64, self.y, p),
            .z = std.math.pow(f64, self.z, p),
        };
    }
};

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return Vec3.init(u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x);
}

pub fn unit(v: Vec3) Vec3 {
    return v.mult(f64, 1.0 / v.len());
}
