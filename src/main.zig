const std = @import("std");
const cam = @import("camera.zig");
const cfg = @import("config.zig");
const ppm = @import("ppm.zig");
const rgb = @import("rgb.zig");
const vec3 = @import("vec3.zig");
const Hit = @import("hit.zig").Hit;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;

const Camera = cam.Camera;
const Vec3 = vec3.Vec3;

pub const log_level: std.log.Level = .info;

const config = cfg.hi_res();

fn lerp(a: Vec3, b: Vec3, t: f64) Vec3 {
    return a.mult(f64, 1.0 - t).add(b.mult(f64, t));
}

fn ray_color(rand: *std.rand.Random, r: Ray, spheres: []Sphere, depth: u32) Vec3 {
    if (depth >= config.max_depth) {
        return Vec3.zero();
    }

    const closest: f64 = 0.00001;
    var farthest: f64 = 1000.0;
    var nearestHit: ?Hit = null;
    for (spheres) |sph| {
        const optHit = sph.intersect(r, closest, farthest);
        if (optHit) |h| {
            nearestHit = h;
            farthest = h.t;
        }
    }
    if (nearestHit) |h| {
        const scattered = h.o.materials.scatter(rand, r, h) catch |err| {
            return Vec3.init(1.0, 0.0, 1.0);
        };
        if (scattered) |s| {
            return ray_color(rand, s.scatteredRay, spheres, depth + 1).mult(Vec3, s.attenuation);
        }
        return Vec3.zero();
    }

    const unit = vec3.unit(r.direction);
    const t = 0.5 * (unit.y() + 1.0);
    return lerp(Vec3.init(1.0, 1.0, 1.0), Vec3.init(0.5, 0.7, 1.0), t);
}

pub fn main() !void {
    // const rand = &std.rand.DefaultPrng.init(42).random;
    const rand = &(std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    }).random);

    const camera = Camera.init(Vec3.init(13, 2, 3), Vec3.zero(), Vec3.init(0,1,0), 20.0, 0.2, 10.0);

    const height = @floatToInt(usize, @intToFloat(f64, config.width) / cam.aspect_ratio);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    var world = std.ArrayList(Sphere).init(&arena.allocator);
    defer world.deinit();

    const ground = Sphere{
        .center = Vec3.init(0, -1000, 0),
        .radius = 1000,
        .materials = .{ .lambFac = 1.0, .lamb = .{
            .albedo = Vec3.init(0.5, 0.5, 0.5),
        } },
    };
    try world.append(ground);

    var a: i32 = -11;
    while (a < 11) {
        var b: i32 = -11;
        while (b < 11) {
            const c = Vec3.init(
                @intToFloat(f64, a) + 0.9 * rand.float(f64),
                0.2,
                @intToFloat(f64, b) + 0.9 * rand.float(f64)
            );
            if (c.sub(Vec3.init(4, 0.2, 0)).len() > 0.9) {
                const lambFac = rand.float(f32);
                const mirrorFac = rand.float(f32) * (1.0 - lambFac);
                const dielectricFac = 1.0 - lambFac - mirrorFac;

                const s = Sphere{
                    .center = c,
                    .radius = 0.2,
                    .materials = . {
                        .lambFac = lambFac,
                        .lamb = .{ .albedo = vec3.random(rand) },
                        .mirrorFac = mirrorFac,
                        .mirror = .{
                            .albedo = vec3.random(rand),
                            .fuzz = rand.float(f64),
                        },
                        .dielectricFac = dielectricFac,
                        .dielectric = .{
                            .albedo = vec3.random(rand),
                            .index = rand.float(f64) + 0.5,
                        },
                    },
                };
                std.log.debug("{s}", .{s});
                try world.append(s);
            }
            b += 1;
        }
        a += 1;
    }

    const d = Sphere{
        .center = Vec3.init(0, 1, 0),
        .radius = 1.0,
        .materials = .{
            .dielectricFac = 1.0,
            .dielectric = .{ .index = 1.5 },
        },
    };

    const l = Sphere{
        .center = Vec3.init(-4, 1, 0),
        .radius = 1.0,
        .materials = .{
            .lambFac = 1.0,
            .lamb = .{
                .albedo = Vec3.init(0.4, 0.2, 0.1),
            },
        },
    };

    const m = Sphere{
        .center = Vec3.init(4, 1, 0),
        .radius = 1.0,
        .materials = .{
            .mirrorFac = 1.0,
            .mirror = .{
                .albedo = Vec3.init(0.7, 0.6, 0.5),
            },
        },
    };

    try world.append(d);
    try world.append(l);
    try world.append(m);

    std.log.info("{d} spheres in the world", .{world.items.len});

    var pixels: [config.width][height]rgb.RGB = undefined;

    const startTime = std.time.milliTimestamp();

    var j: usize = 0;
    while (j < height) {
        if (j % 10 == 0) {
            std.log.info("rendering scanline {d} / {d}", .{ j, height });
            if (j > 0) {
                const elapsed = @intToFloat(f32, std.time.milliTimestamp() - startTime);
                const remain = @intToFloat(f32, height - j) * (elapsed / @intToFloat(f32, j));
                if (remain > 60) {
                    std.log.info(".. {d} minutes remaining", .{remain / (60 * 1000)});
                } else {
                    std.log.info(".. {d} seconds remaining", .{remain / 1000});
                }
            }
        }
        var i: usize = 0;
        while (i < config.width) {
            var sample: usize = 0;
            var pixelColour = Vec3.zero();
            while (sample < config.samples) {
                const u = (@intToFloat(f64, i) + rand.float(f64)) / @intToFloat(f64, config.width - 1);
                const v = (@intToFloat(f64, j) + rand.float(f64)) / @intToFloat(f64, height - 1);
                const r = camera.createRay(rand, u, v);

                pixelColour = pixelColour.add(ray_color(rand, r, world.items, 0));
                sample += 1;
            }
            pixels[i][j] = rgb.RGB.fromVec3(pixelColour.mult(f64, 1.0 / @intToFloat(f64, config.samples)).pow(1.0 / 2.2));

            i += 1;
        }
        j += 1;
    }

    try ppm.write(std.io.getStdOut().writer(), &pixels);

    std.log.info("all your pixels are belong to us.", .{});
}
