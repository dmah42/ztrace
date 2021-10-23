const std = @import("std");
const vec3 = @import("vec3.zig");

const math = std.math;
const Vec3 = vec3.Vec3;

pub const ONB = struct {
    _axis: [3]Vec3 = undefined,

    pub fn u(self: ONB) Vec3 {
        return self._axis[0];
    }
    pub fn v(self: ONB) Vec3 {
        return self._axis[1];
    }
    pub fn w(self: ONB) Vec3 {
        return self._axis[2];
    }

    pub fn local(self: ONB, a: Vec3) Vec3 {
        const scaled_u = self.u().mult(f64, a.x());
        const scaled_v = self.v().mult(f64, a.y());
        const scaled_w = self.w().mult(f64, a.z());

        return scaled_u.add(scaled_v).add(scaled_w);
    }

    pub fn init(n: Vec3) ONB {
        const ww = vec3.unit(n);
        const a = if (math.fabs(ww.x()) > 0.9) Vec3.init(0, 1, 0) else Vec3.init(1, 0, 0);
        const vv = vec3.unit(vec3.cross(ww, a));
        const uu = vec3.cross(ww, vv);

        const axes = [3]Vec3{ uu, vv, ww };
        return .{ ._axis = axes };
    }
};
