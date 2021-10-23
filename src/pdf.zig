const math = @import("std").math;
const rand = @import("std").rand;
const Object = @import("object.zig").Object;
const ONB = @import("onb.zig").ONB;
const vec3 = @import("vec3.zig");

const Vec3 = vec3.Vec3;

const CosinePDF = struct {
    _uvw: ONB,

    pub fn init(w: Vec3) CosinePDF {
        return .{ ._uvw = ONB.init(w) };
    }

    pub fn value(self: CosinePDF, v: Vec3) f64 {
        const cos = vec3.unit(v).dot(self._uvw.w());
        return if (cos < 0) 0 else cos / math.pi;
    }

    pub fn generate(self: CosinePDF, _rand: *rand.Random) Vec3 {
        return self._uvw.local(vec3.random_cosine_direction(_rand));
    }
};

// TODO: figure out how to do multiple lights. maybe an object that is a list of objects...
// fn pdfValue(objects: []Object, origin: Vec3, v: Vec3) f64 {
//     const weight = 1.0 / objects.len;
//     var sum: f64 = 0.0;
//     for (objects) |object| {
//         sum += weight * object.pdfValue(origin, v);
//     }
//     return sum;
// }
//
// fn random(rand: *std.rand.Random, objects: []Object, origin: Vec3) Vec3 {
//     return objects[rand.intRangeLessThan(objects.len)].random(origin);
// }
//
const HittablePDF = struct {
    _hittable: *const Object,
    _origin: Vec3,

    pub fn init(hittable: *const Object, origin: Vec3) HittablePDF {
        return .{
            ._hittable = hittable,
            ._origin = origin,
        };
    }

    pub fn value(self: HittablePDF, direction: Vec3) f64 {
        return self._hittable.pdfValue(self._origin, direction);
    }

    pub fn generate(self: HittablePDF, _rand: *rand.Random) Vec3 {
        return self._hittable.random(_rand, self._origin);
    }
};

const MixturePDF = struct {
    p0: *const PDF,
    p1: *const PDF,

    pub fn value(self: MixturePDF, direction: Vec3) f64 {
        return 0.5 * self.p0.value(direction) + 0.5 * self.p1.value(direction);
    }

    pub fn generate(self: MixturePDF, _rand: *rand.Random) Vec3 {
        return if (_rand.float(f64) < 0.5) self.p0.generate(_rand) else self.p1.generate(_rand);
    }
};

pub const PDF = struct {
    const TypeTag = enum {
        cosine,
        hittable,
        mixture,
    };

    const Type = union(TypeTag) {
        cosine: CosinePDF,
        hittable: HittablePDF,
        mixture: MixturePDF,
    };

    t: Type,

    pub fn initCosine(w: Vec3) PDF {
        return .{ .t = .{ .cosine = CosinePDF.init(w) } };
    }

    pub fn initHittable(hittable: *const Object, origin: Vec3) PDF {
        return .{ .t = .{
            .hittable = HittablePDF.init(hittable, origin),
        } };
    }

    pub fn initMixture(p0: *const PDF, p1: *const PDF) PDF {
        return .{ .t = .{ .mixture = .{
            .p0 = p0,
            .p1 = p1,
        } } };
    }

    pub fn value(self: PDF, v: Vec3) f64 {
        return switch (self.t) {
            .cosine => |*pdf| return pdf.value(v),
            .hittable => |*pdf| return pdf.value(v),
            .mixture => |*pdf| return pdf.value(v),
        };
    }

    pub fn generate(self: PDF, _rand: *rand.Random) Vec3 {
        return switch (self.t) {
            .cosine => |*pdf| return pdf.generate(_rand),
            .hittable => |*pdf| return pdf.generate(_rand),
            .mixture => |*pdf| return pdf.generate(_rand),
        };
    }
};
