const std = @import("std");

pub const Vec3 = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }

    pub fn lenSqr(self: Vec3) f32 {
        return self.dot(self);
    }

    pub fn len(self: Vec3) f32 {
        return std.math.sqrt(self.lenSqr());
    }

    pub fn mult(self: Vec3, f: f32) Vec3 {
        return Vec3 { .x = self.x * f, .y = self.y * f, .z = self.z * f, };
    }

    pub fn add(self: Vec3, o: Vec3) Vec3 {
        return Vec3 {.x = self.x + o.x, .y = self.y + o.y, .z = self.z + o.z, };
    }

    pub fn sub(self: Vec3, o: Vec3) Vec3 {
        return Vec3 {.x = self.x - o.x, .y = self.y - o.y, .z = self.z - o.z, };
    }
};

pub fn cross(u: Vec3, v: Vec3) Vec3 {
    return Vec3.init(u.y * v.z - u.z * v.y,
                     u.z * v.x - u.x * v.z,
                     u.x * v.y - u.y * v.x);
}

pub fn unit(v: Vec3) Vec3 {
    return v.mult(1.0/v.len());
}
