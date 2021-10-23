const PDF = @import("pdf.zig").PDF;
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec3.zig").Vec3;

pub const Scattered = struct {
    const RayOrPdfTag = enum {
        specular_ray,
        pdf,
    };

    const RayOrPdf = union(RayOrPdfTag) {
        specular_ray: Ray,
        pdf: PDF,
    };

    attenuation: Vec3,
    ray_or_pdf: RayOrPdf,

    pub fn initPdf(albedo: Vec3, pdf: PDF) Scattered {
        return .{
            .attenuation = albedo,
            .ray_or_pdf = .{
                .pdf = pdf,
            },
        };
    }

    pub fn initSpecularRay(albedo: Vec3, ray: Ray) Scattered {
        return .{
            .attenuation = albedo,
            .ray_or_pdf = .{
                .specular_ray = ray,
            },
        };
    }

    pub fn isSpecular(self: Scattered) bool {
        return self.ray_or_pdf == .specular_ray;
    }
};
