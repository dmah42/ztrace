const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;
const Vec3 = @import("vec3.zig").Vec3;

pub const Hit = struct {
    o: Sphere,
    t: f64,
    p: Vec3,
    _n: Vec3 = undefined,
    _ff: bool = undefined,

    pub fn n(self: Hit) Vec3 { return self._n; }
    pub fn ff(self: Hit) bool { return self._ff; }

    pub fn set_normal(self: *Hit, r: Ray, norm: Vec3) void {
        self._ff = r.direction.dot(norm) < 0;
        self._n = if (self._ff) norm else norm.negate();
    }
};