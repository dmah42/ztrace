const std = @import("std");
const hit = @import("hit.zig");
const ppm = @import("ppm.zig");
const ray = @import("ray.zig");
const rgb = @import("rgb.zig");
const sphere = @import("sphere.zig");
const vec3 = @import("vec3.zig");

fn lerp(a: vec3.Vec3, b: vec3.Vec3, t: f32) vec3.Vec3 {
    return a.mult(1.0 - t).add(b.mult(t));
}

fn ray_color(r: ray.Ray, spheres: []sphere.Sphere) rgb.RGB {
    var nearest: f32 = 100.0;
    var nearestHit: ?hit.Hit = null;
    for (spheres) |sph| {
        const optHit = sph.intersect(r, 0.0, nearest);
        if (optHit) |h| {
            nearestHit = h;
            nearest = h.t;
        }
    }
    if (nearestHit) |h| {
        return rgb.RGB.fromVec3(h.n.add(vec3.Vec3{ .x = 1, .y = 1, .z = 1 }).mult(0.5));
    }

    const unit = vec3.unit(r.direction);
    const t = 0.5 * (unit.y + 1.0);
    return rgb.RGB.fromVec3(lerp(vec3.Vec3{
        .x = 1.0,
        .y = 1.0,
        .z = 1.0,
    }, vec3.Vec3{
        .x = 0.5,
        .y = 0.7,
        .z = 1.0,
    }, t));
}

pub const log_level: std.log.Level = .info;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    // image dimensions
    const aspect = 16.0 / 9.0;
    const width = 400;
    const height = @floatToInt(i32, width / aspect);

    // camera
    const view_height = 2.0;
    const view_width = aspect * view_height;
    const focal = 1.0;

    const origin = vec3.Vec3{};
    const horiz = vec3.Vec3{ .x = view_width };
    const vert = vec3.Vec3{ .y = view_height };

    const lower_left = origin.sub(horiz.mult(0.5))
        .sub(vert.mult(0.5))
        .sub(vec3.Vec3{ .z = focal });

    // render
    var pixels: [width][height]rgb.RGB = undefined;

    var spheres = [_]sphere.Sphere{
        sphere.Sphere{
            .center = vec3.Vec3{ .x = 0.3, .z = -1.0 },
            .radius = 0.5,
        },
        sphere.Sphere{
            .center = vec3.Vec3{ .x = 0, .y = -100.5, .z = -1.0 },
            .radius = 100.0,
        },
    };

    var j: usize = 0;
    while (j < height) {
        std.log.info("scanlines remaining: {d}", .{j});
        var i: usize = 0;
        while (i < width) {
            const u = @intToFloat(f32, i) / @intToFloat(f32, width - 1);
            const v = @intToFloat(f32, j) / @intToFloat(f32, height - 1);
            const r = ray.Ray.init(origin, lower_left.add(horiz.mult(u)).add(vert.mult(v)).sub(origin));
            const pixel_color = ray_color(r, &spheres);

            pixels[i][j] = pixel_color;

            i += 1;
        }
        j += 1;
    }

    try ppm.write(stdout, &pixels);

    std.log.info("all your pixels are belong to us.", .{});
}
