const std = @import("std");
const cam = @import("camera.zig");
const hit = @import("hit.zig");
const ppm = @import("ppm.zig");
const ray = @import("ray.zig");
const rgb = @import("rgb.zig");
const sphere = @import("sphere.zig");
const vec3 = @import("vec3.zig");

pub const log_level: std.log.Level = .info;
const samples = 50;
const width = 400;
const stdout = std.io.getStdOut().writer();

fn lerp(a: vec3.Vec3, b: vec3.Vec3, t: f32) vec3.Vec3 {
    return a.mult(1.0 - t).add(b.mult(t));
}

fn ray_color(r: ray.Ray, spheres: []sphere.Sphere) vec3.Vec3 {
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
        return h.n.add(vec3.Vec3{ .x = 1, .y = 1, .z = 1 }).mult(0.5);
    }

    const unit = vec3.unit(r.direction);
    const t = 0.5 * (unit.y + 1.0);
    return lerp(vec3.Vec3{
        .x = 1.0,
        .y = 1.0,
        .z = 1.0,
    }, vec3.Vec3{
        .x = 0.5,
        .y = 0.7,
        .z = 1.0,
    }, t);
}

pub fn main() !void {
    const rand = &std.rand.DefaultPrng.init(0).random;

    const camera = cam.Camera.init();

    const height = @floatToInt(i32, width / cam.aspect_ratio);

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

    var pixels: [width][height]rgb.RGB = undefined;

    var j: usize = 0;
    while (j < height) {
        std.log.info("render scanlines remaining: {d}", .{j});
        var i: usize = 0;
        while (i < width) {

            var sample: usize = 0;
            var pixelColour = vec3.Vec3{};
            while (sample < samples) {
                const u = (@intToFloat(f32, i) + rand.float(f32)) / @intToFloat(f32, width - 1);
                const v = (@intToFloat(f32, j) + rand.float(f32)) / @intToFloat(f32, height - 1);
                const r = camera.createRay(u, v);

                pixelColour = pixelColour.add(ray_color(r, &spheres));
                sample += 1;
            }
            pixels[i][j] = rgb.RGB.fromVec3(pixelColour.mult(1.0 / @intToFloat(f32, samples)));

            i += 1;
        }
        j += 1;
    }

    try ppm.write(stdout, &pixels);

    std.log.info("all your pixels are belong to us.", .{});
}
