const std = @import("std");
const cam = @import("camera.zig");
const hit = @import("hit.zig");
const ppm = @import("ppm.zig");
const ray = @import("ray.zig");
const rgb = @import("rgb.zig");
const sphere = @import("sphere.zig");
const vec3 = @import("vec3.zig");

pub const log_level: std.log.Level = .info;
const SAMPLES = 200;
const WIDTH = 600;
const MAX_DEPTH = 80;

fn lerp(a: vec3.Vec3, b: vec3.Vec3, t: f64) vec3.Vec3 {
    return a.mult(1.0 - t).add(b.mult(t));
}

fn random_vec3(rand: *std.rand.Random) vec3.Vec3 {
    return vec3.Vec3{
        .x = rand.float(f64),
        .y = rand.float(f64),
        .z = rand.float(f64),
    };
}

fn random_vec3_in_unit_sphere(rand: *std.rand.Random) vec3.Vec3 {
    while (true) {
        const v = random_vec3(rand);
        if (v.lenSqr() <= 1.0) return v;
    }
}

fn random_unit_vec3(rand: *std.rand.Random) vec3.Vec3 {
    return vec3.unit(random_vec3_in_unit_sphere(rand));
}

fn ray_color(rand: *std.rand.Random, r: ray.Ray, spheres: []sphere.Sphere, depth: u32) vec3.Vec3 {
    if (depth >= MAX_DEPTH) {
        return vec3.Vec3{};
    }

    const closest: f64 = 0.00001;
    var farthest: f64 = 1000.0;
    var nearestHit: ?hit.Hit = null;
    for (spheres) |sph| {
        const optHit = sph.intersect(r, closest, farthest);
        if (optHit) |h| {
            nearestHit = h;
            farthest = h.t;
        }
    }
    if (nearestHit) |h| {
        const target = h.n.add(random_unit_vec3(rand));
        const newRay = ray.Ray{ .origin = h.p, .direction = vec3.unit(target) };
        return ray_color(rand, newRay, spheres, depth + 1).mult(0.2); // multiplier is how much reflectance there is
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
    const rand = &std.rand.DefaultPrng.init(42).random;

    const camera = cam.Camera.init();

    const height = @floatToInt(i32, WIDTH / cam.aspect_ratio);

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

    var pixels: [WIDTH][height]rgb.RGB = undefined;

    var j: usize = 0;
    while (j < height) {
        if (j % 10 == 0) {
            std.log.info("rendering scanline {d} / {d}", .{j, height});
        }
        var i: usize = 0;
        while (i < WIDTH) {
            var sample: usize = 0;
            var pixelColour = vec3.Vec3{};
            while (sample < SAMPLES) {
                const u = (@intToFloat(f64, i) + rand.float(f64)) / @intToFloat(f64, WIDTH - 1);
                const v = (@intToFloat(f64, j) + rand.float(f64)) / @intToFloat(f64, height - 1);
                const r = camera.createRay(u, v);

                pixelColour = pixelColour.add(ray_color(rand, r, &spheres, 0));
                sample += 1;
            }
            pixels[i][j] = rgb.RGB.fromVec3(pixelColour.mult(1.0 / @intToFloat(f64, SAMPLES)).pow(1.0 / 2.2));

            i += 1;
        }
        j += 1;
    }

    try ppm.write(std.io.getStdOut().writer(), &pixels);

    std.log.info("all your pixels are belong to us.", .{});
}
