const std = @import("std");
const cam = @import("camera.zig");
const cfg = @import("config.zig");
const object = @import("object.zig");
const ppm = @import("ppm.zig");
const vec3 = @import("vec3.zig");

const BVHNode = @import("bvhnode.zig").BVHNode;
const Hit = @import("hit.zig").Hit;
const Materials = @import("materials.zig").Materials;
const Ray = @import("ray.zig").Ray;
const RGB = @import("rgb.zig").RGB;
const Sphere = @import("sphere.zig").Sphere;
const XYRect = @import("aarect.zig").XYRect;
const XZRect = @import("aarect.zig").XZRect;
const YZRect = @import("aarect.zig").YZRect;

const Camera = cam.Camera;
const Object = object.Object;
const Vec3 = vec3.Vec3;

pub const log_level: std.log.Level = .info;

const config = cfg.hi_res();

fn lerp(a: Vec3, b: Vec3, t: f64) Vec3 {
    return a.mult(f64, 1.0 - t).add(b.mult(f64, t));
}

fn ray_color(rand: *std.rand.Random, r: Ray, world: *BVHNode, background: Vec3, depth: u32) Vec3 {
    if (depth >= config.max_depth) {
        return Vec3.zero();
    }

    const closest: f64 = 0.00001;
    const farthest: f64 = 100000.0;
    const optHit = world.intersect(r, closest, farthest);
    if (optHit) |h| {
        const scattered = h.o.materials.scatter(rand, r, h) catch |err| {
            return Vec3.init(1.0, 0.0, 1.0);
        };
        if (scattered) |s| {
            return ray_color(rand, s.scatteredRay, world, background, depth + 1).mult(Vec3, s.attenuation);
        }
        return h.o.emittance;
    }

    return background;
}

const Scene = struct {
    camera: Camera,
    objects: std.ArrayList(Object),
    background: Vec3,
};

fn createSimpleLight(alloc: *std.mem.Allocator, rand: *std.rand.Random) !Scene {
    var objects = std.ArrayList(Object).init(alloc);

    try objects.append(object.asSphere(Sphere{
        .center = Vec3.init(0, -1000, 0),
        .radius = 1000,
    }, .{
        .lambFac = 1.0,
        .lamb = .{
            .albedo = Vec3.init(0.5, 0.5, 0.5),
        },
    }, Vec3.zero()));

    try objects.append(object.asSphere(Sphere{
        .center = Vec3.init(0, 2, 0),
        .radius = 2,
    }, .{
        .lambFac = 1.0,
        .lamb = .{
            .albedo = Vec3.init(0.8, 0.2, 0.6),
        },
    }, Vec3.zero()));

    try objects.append(object.asXYRect(
        XYRect{
            .x0 = -3,
            .x1 = -1,
            .y0 = 2,
            .y1 = 4,
            .k = 5,
        },
        .{},
        Vec3.init(1, 1, 1),
    ));

    try objects.append(object.asSphere(
        Sphere{
            .center = Vec3.init(2, 0.5, 3),
            .radius = 0.5,
        },
        .{},
        Vec3.init(1, 1, 1),
    ));

    return Scene{
        .camera = Camera.basic(Vec3.init(8, 3, 10), Vec3.init(0, 2, 0), 40.0),
        .objects = objects,
        .background = Vec3.init(0.0, 0.02, 0.04),
    };
}

fn createBalls(alloc: *std.mem.Allocator, rand: *std.rand.Random) !Scene {
    var objects = std.ArrayList(Object).init(alloc);

    try objects.append(object.asSphere(
        Sphere{ .center = Vec3.init(0, -1000, 0), .radius = 1000 },
        .{
            .lambFac = 1.0,
            .lamb = .{ .albedo = Vec3.init(0.5, 0.5, 0.5) },
        },
        Vec3.zero(),
    ));

    var a: i32 = -11;
    while (a < 11) {
        var b: i32 = -11;
        while (b < 11) {
            const c = Vec3.init(@intToFloat(f64, a) + 0.9 * rand.float(f64), 0.2, @intToFloat(f64, b) + 0.9 * rand.float(f64));
            if (c.sub(Vec3.init(4, 0.2, 0)).len() > 0.9) {
                const lambFac = rand.float(f32);
                const mirrorFac = rand.float(f32) * (1.0 - lambFac);
                const dielectricFac = 1.0 - lambFac - mirrorFac;

                try objects.append(object.asSphere(
                    Sphere{ .center = c, .radius = 0.2 },
                    .{
                        .lambFac = lambFac,
                        .lamb = .{ .albedo = vec3.random(rand) },
                        .mirrorFac = mirrorFac,
                        .mirror = .{ .albedo = vec3.random(rand), .fuzz = rand.float(f64) },
                        .dielectricFac = dielectricFac,
                        .dielectric = .{ .albedo = vec3.random(rand), .index = rand.float(f64) + 0.5 },
                    },
                    // TODO: random emitters?
                    Vec3.zero(),
                ));
            }
            b += 1;
        }
        a += 1;
    }

    try objects.append(object.asSphere(
        Sphere{ .center = Vec3.init(0, 1, 0), .radius = 1.0 },
        .{
            .dielectricFac = 1.0,
            .dielectric = .{ .index = 1.5 },
        },
        Vec3.zero(),
    ));

    try objects.append(object.asSphere(
        Sphere{ .center = Vec3.init(-4, 1, 0), .radius = 1.0 },
        .{
            .lambFac = 1.0,
            .lamb = .{ .albedo = Vec3.init(0.4, 0.2, 0.1) },
        },
        Vec3.zero(),
    ));

    try objects.append(object.asSphere(
        Sphere{ .center = Vec3.init(4, 1, 0), .radius = 1.0 },
        .{
            .mirrorFac = 1.0,
            .mirror = .{ .albedo = Vec3.init(0.7, 0.6, 0.5) },
        },
        Vec3.zero(),
    ));

    try objects.append(object.asXZRect(
        XZRect{ .x0 = -4, .x1 = 4, .z0 = -4, .z1 = 4, .k = 3 },
        .{},
        Vec3.init(1, 1, 1),
    ));

    return Scene{
        .camera = Camera.init(Vec3.init(13, 2, 3), Vec3.zero(), Vec3.init(0, 1, 0), 20.0, 0.2, 10.0),
        .objects = objects,
        .background = Vec3.init(0.1, 0.3, 0.5),
    };
}

fn createCornellBox(alloc: *std.mem.Allocator, rand: *std.rand.Random) !Scene {
    var objects = std.ArrayList(Object).init(alloc);

    const red: Materials = .{ .lambFac = 1.0, .lamb = .{ .albedo = Vec3.init(0.65, 0.05, 0.05) } };
    const white: Materials = .{ .lambFac = 1.0, .lamb = .{ .albedo = Vec3.init(0.73, 0.73, 0.73) } };
    const green: Materials = .{ .lambFac = 1.0, .lamb = .{ .albedo = Vec3.init(0.12, 0.45, 0.15) } };

    try objects.append(object.asYZRect(.{
        .y0 = 0.0,
        .y1 = 555.0,
        .z0 = 0.0,
        .z1 = 555.0,
        .k = 555.0,
    }, green, Vec3.zero()));
    try objects.append(object.asYZRect(.{
        .y0 = 0.0,
        .y1 = 555.0,
        .z0 = 0.0,
        .z1 = 555.0,
        .k = 0.0,
    }, red, Vec3.zero()));
    try objects.append(object.asXZRect(.{
        .x0 = 0.0,
        .x1 = 555.0,
        .z0 = 0.0,
        .z1 = 555.0,
        .k = 0.0,
    }, white, Vec3.zero()));
    try objects.append(object.asXZRect(.{
        .x0 = 0.0,
        .x1 = 555.0,
        .z0 = 0.0,
        .z1 = 555.0,
        .k = 555.0,
    }, white, Vec3.zero()));
    try objects.append(object.asXYRect(.{
        .x0 = 0.0,
        .x1 = 555.0,
        .y0 = 0.0,
        .y1 = 555.0,
        .k = 555.0,
    }, white, Vec3.zero()));

    try objects.append(object.asXZRect(.{
        .x0 = 213,
        .x1 = 343,
        .z0 = 227,
        .z1 = 332,
        .k = 554,
    }, .{}, Vec3.init(15, 15, 15)));

    return Scene{
        .camera = Camera.basic(
            Vec3.init(278, 278, -800),
            Vec3.init(278, 278, 0),
            40.0,
            1.0,
        ),
        .objects = objects,
        .background = Vec3.zero(),
    };
}

pub fn main() !void {
    const rand = &(std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    }).random);

    std.log.info("using config {s}", .{config});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    std.log.info("creating world", .{});
    const scene = try createCornellBox(allocator, rand);
    defer scene.objects.deinit();

    std.log.info("{d} objects in the world", .{scene.objects.items.len});

    std.log.info("slicing up the world", .{});
    const world = try BVHNode.init(allocator, scene.objects.items, rand);

    const height = @floatToInt(usize, @intToFloat(f64, config.width) / scene.camera.aspect_ratio);
    var pixels: [][]RGB = try allocator.alloc([]RGB, config.width);
    var pj: usize = 0;
    while (pj < height) {
        var pi: usize = 0;
        while (pi < config.width) {
            pixels[pi] = try allocator.alloc(RGB, height);
            pi += 1;
        }
        pj += 1;
    }
    std.log.info("ready to throw some pixels!", .{});

    const startTime = std.time.milliTimestamp();

    var maxColour: Vec3 = undefined;

    // const test_ray = Ray{
    //     .origin = Vec3.init(278, 278, -800),
    //     .direction = vec3.unit(Vec3.init(230, 278, 0).sub(Vec3.init(278, 278, -800))),
    // };

    // const test_colour = ray_color(rand, test_ray, world, scene.background, 0);

    // std.log.debug("test ray output: {s}", test_colour);

    var j: usize = 0;
    while (j < height) {
        if (j % 10 == 0) {
            std.log.info("rendering scanline {d} / {d}", .{ j, height });
            if (j > 0) {
                const elapsed = @intToFloat(f32, std.time.milliTimestamp() - startTime);
                const remain = @intToFloat(f32, height - j) * (elapsed / @intToFloat(f32, j));
                if (remain > 60000) {
                    std.log.info(".. {d:.3} minutes remaining", .{remain / (60 * 1000)});
                } else {
                    std.log.info(".. {d:.3} seconds remaining", .{remain / 1000});
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
                const r = scene.camera.createRay(rand, u, v);

                pixelColour = pixelColour.add(ray_color(rand, r, world, scene.background, 0));
                sample += 1;
            }
            pixels[i][j] = RGB.fromVec3(pixelColour.mult(f64, 1.0 / @intToFloat(f64, config.samples)).pow(1.0 / 2.2));

            i += 1;
        }
        j += 1;
    }

    try ppm.write(std.io.getStdOut().writer(), pixels);

    std.log.info("all your pixels are belong to us.", .{});
}
