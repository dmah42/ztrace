const vec3 = @import("vec3.zig");

pub const RGB = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn fromVec3(v: vec3.Vec3) RGB {
        const ir = @floatToInt(u8, 255.0 * v.x);
        const ig = @floatToInt(u8, 255.0 * v.y);
        const ib = @floatToInt(u8, 255.0 * v.z);
        return .{.r = ir, .g = ig, .b = ib};
    }
};