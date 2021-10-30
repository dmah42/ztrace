const math = @import("std").math;
const Vec3 = @import("vec3.zig").Vec3;

pub const RGB = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn fromVec3(v: Vec3) RGB {
        const scaled = v.mult(f64, 255.0);
        const ir = @floatToInt(u8, scaled.x());
        const ig = @floatToInt(u8, scaled.y());
        const ib = @floatToInt(u8, scaled.z());
        return .{ .r = ir, .g = ig, .b = ib };
    }
};
