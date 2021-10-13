const std = @import("std");
const cam = @import("camera.zig");
const hit = @import("hit.zig");
const ppm = @import("ppm.zig");
const ray = @import("ray.zig");
const rgb = @import("rgb.zig");
const sphere = @import("sphere.zig");
const vec3 = @import("vec3.zig");

pub const log_level: std.log.Level = .info;
const SAMPLES = 1000;
const WIDTH = 1080;
const MAX_DEPTH = 10;

// const SAMPLES = 10;
// const WIDTH = 400;
// const MAX_DEPTH = 5;

fn lerp(a: vec3.Vec3, b: vec3.Vec3, t: f64) vec3.Vec3 {
    return a.mult(f64, 1.0 - t).add(b.mult(f64, t));
}

fn ray_color(rand: *std.rand.Random, r: ray.Ray, spheres: []sphere.Sphere, depth: u32) vec3.Vec3 {
    if (depth >= MAX_DEPTH) {
        return .{};
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
        // TODO: select the material based on probability
        const scattered = h.o.materials.scatter(rand, r, h) catch |err| {
            return .{ .x = 1.0, .z = 1.0 };
        };
        if (scattered) |s| {
            return ray_color(rand, s.scatteredRay, spheres, depth + 1).mult(vec3.Vec3, s.attenuation);
        }
        return .{};
    }

    const unit = vec3.unit(r.direction);
    const t = 0.5 * (unit.y + 1.0);
    return lerp(.{
        .x = 1.0,
        .y = 1.0,
        .z = 1.0,
    }, .{
        .x = 0.5,
        .y = 0.7,
        .z = 1.0,
    }, t);
}

pub fn main() !void {
    const rand = &std.rand.DefaultPrng.init(42).random;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    const camera = cam.Camera.init();

    const height = @floatToInt(i32, WIDTH / cam.aspect_ratio);

    var spheres = [_]sphere.Sphere{
        sphere.Sphere{
            .center = .{ .x = 0.3, .z = -1.0 },
            .radius = 0.5,
            .materials = .{ .lambFac = 1.0, .lamb = .{ .albedo = .{
                .x = 0.5,
                .y = 0.5,
                .z = 0.5,
            } } },
        },

        sphere.Sphere{
            .center = .{ .x = -0.6, .y = -0.2, .z = -1.2 },
            .radius = 0.3,
            .materials = .{
                .lambFac = 0.3,
                .lamb = .{ .albedo = .{
                    .x = 0.1,
                    .y = 0.5,
                    .z = 0.7,
                } },
                .mirrorFac = 0.7,
                .mirror = .{
                    .albedo = .{
                        .x = 1.0,
                        .y = 1.0,
                        .z = 1.0,
                    },
                },
            },
        },

        sphere.Sphere{
            .center = .{ .x = -0.15, .y = -0.4, .z = -0.7 },
            .radius = 0.1,
            .materials = .{
                .mirrorFac = 1.0,
                .mirror = .{
                    .albedo = .{
                        .x = 0.7,
                        .y = 0.0,
                        .z = 0.0,
                    },
                },
            },
        },

        // ground
        sphere.Sphere{
            .center = .{ .x = 0, .y = -100.5, .z = -1.0 },
            .radius = 100.0,
            .materials = .{ .lambFac = 1.0, .lamb = .{
                .albedo = .{
                    .x = 0.8,
                    .y = 0.2,
                    .z = 0.6,
                },
            } },
        },
    };

    var pixels: [WIDTH][height]rgb.RGB = undefined;

    var j: usize = 0;
    while (j < height) {
        if (j % 10 == 0) {
            std.log.info("rendering scanline {d} / {d}", .{ j, height });
        }
        var i: usize = 0;
        while (i < WIDTH) {
            var sample: usize = 0;
            var pixelColour: vec3.Vec3 = .{};
            while (sample < SAMPLES) {
                const u = (@intToFloat(f64, i) + rand.float(f64)) / @intToFloat(f64, WIDTH - 1);
                const v = (@intToFloat(f64, j) + rand.float(f64)) / @intToFloat(f64, height - 1);
                const r = camera.createRay(u, v);

                pixelColour = pixelColour.add(ray_color(rand, r, &spheres, 0));
                sample += 1;
            }
            pixels[i][j] = rgb.RGB.fromVec3(pixelColour.mult(f64, 1.0 / @intToFloat(f64, SAMPLES)).pow(1.0 / 2.2));

            i += 1;
        }
        j += 1;
    }

    try ppm.write(std.io.getStdOut().writer(), &pixels);

    std.log.info("all your pixels are belong to us.", .{});
}
