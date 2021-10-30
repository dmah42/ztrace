const std = @import("std");
const cam = @import("camera.zig");
const cfg = @import("config.zig");
const object = @import("object.zig");
const ppm = @import("ppm.zig");
const scene = @import("scene.zig");
const vec3 = @import("vec3.zig");

const BVHNode = @import("bvhnode.zig").BVHNode;
const PDF = @import("pdf.zig").PDF;
const Ray = @import("ray.zig").Ray;
const RGB = @import("rgb.zig").RGB;

const Object = object.Object;
const Vec3 = vec3.Vec3;

pub const log_level: std.log.Level = .info;

const config = cfg.lo_res();

fn lerp(a: Vec3, b: Vec3, t: f64) Vec3 {
    return a.mult(f64, 1.0 - t).add(b.mult(f64, t));
}

fn rayColor(rand: *std.rand.Random, r: Ray, world: *BVHNode, light: Object, background: Vec3, depth: u32) Vec3 {
    if (depth >= config.max_depth) {
        return Vec3.zero();
    }

    const closest: f64 = 0.00001;
    const farthest: f64 = std.math.inf(f64);
    const optHit = world.intersect(r, closest, farthest);
    if (optHit) |h| {
        std.log.debug("hit object '{s}'", .{h.o.name});
        const scattered = h.o.materials.scatter(rand, r, h) catch |err| {
            return Vec3.init(1.0, 0.0, 1.0);
        };
        if (scattered) |s| {
            std.log.debug(".. scattering", .{});
            if (s.isSpecular()) {
                const color = rayColor(rand, s.ray_or_pdf.specular_ray, world, light, background, depth + 1).mult(Vec3, s.attenuation);
                std.log.debug(".. specular. returning {s}", .{color});
                return color;
            }

            const light_pdf = PDF.initHittable(&light, h.p);
            const mixture_pdf = PDF.initMixture(&light_pdf, &s.ray_or_pdf.pdf);

            const scattered_ray = Ray.init(h.p, mixture_pdf.generate(rand));
            const pdf_val = mixture_pdf.value(scattered_ray.direction);

            std.log.debug(".. scattering to {s} with pdf {d:.2}", .{ scattered_ray, pdf_val });

            const scattered_color = rayColor(rand, scattered_ray, world, light, background, depth + 1);

            const scattered_pdf = h.o.materials.scatteredPdf(rand, r, h, scattered_ray) catch |err| {
                return 0.0;
            } orelse return Vec3.init(1.0, 0.0, 1.0);

            std.log.debug(".. color from scattered ray {s} with pdf {d:.2}", .{ scattered_color, scattered_pdf });

            const inv_pdf = 1.0 / pdf_val;

            const color = h.o.emittance.add(scattered_color.mult(f64, scattered_pdf).mult(Vec3, s.attenuation).mult(f64, inv_pdf));
            std.log.debug(".. returning colour {s}", .{color});
            return color;
        }
        return h.o.emittance;
    }

    return background;
}

const UsageError = error{
    MissingExeName,
    UndefinedOutput,
    UnknownArg,
};

const Args = struct {
    exe_name: []const u8,
    output: []const u8,
};

fn parse_args(alloc: *std.mem.Allocator) !Args {
    var output: []const u8 = "image.ppm";
    var iter = std.process.args();

    const exe_name: []const u8 = if (iter.next(alloc)) |exe_name| try exe_name else return UsageError.MissingExeName;
    while (iter.next(alloc)) |arg| {
        const argument = try arg;
        defer alloc.free(argument);
        if (std.mem.eql(u8, argument, "--output") or std.mem.eql(u8, argument, "-o")) {
            if (iter.next(alloc)) |arg_value| {
                output = try arg_value;
            } else {
                return UsageError.UndefinedOutput;
            }
        } else {
            return UsageError.UnknownArg;
        }
    }
    return Args{
        .exe_name = exe_name,
        .output = output,
    };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const args: Args = parse_args(allocator) catch {
        std.log.err("usage: ztrace [--output|-o] <output_file>", .{});
        return;
    };
    std.log.info("running '{s}'", .{args.exe_name});
    std.log.info("outputting to '{s}'", .{args.output});

    const rand = &(std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    }).random);

    std.log.info("using config {s}", .{config});

    std.log.info("creating world", .{});
    const scn = try scene.createBalls(allocator, rand);
    defer scn.objects.deinit();

    std.log.info("{d} objects in the world", .{scn.objects.items.len});

    std.log.info("slicing up the world", .{});
    const world = try BVHNode.init(allocator, scn.objects.items, rand);

    const height = @floatToInt(usize, @intToFloat(f64, config.width) / scn.camera.aspect_ratio);
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

    var j: usize = 0;
    while (j < height) {
        if (j % 10 == 0) {
            if (j > 0) {
                const elapsed = @intToFloat(f32, std.time.milliTimestamp() - startTime);
                const remain = @intToFloat(f32, height - j) * (elapsed / @intToFloat(f32, j));
                if (remain > 60000) {
                    std.log.info(
                        "rendering line {d} / {d}: {d:.2} minutes remaining",
                        .{ j, height, remain / (60 * 1000) },
                    );
                } else {
                    std.log.info(
                        "rendering line {d} / {d}: {d:.2} seconds remaining",
                        .{ j, height, remain / 1000 },
                    );
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
                const r = scn.camera.createRay(rand, u, v);

                pixelColour = pixelColour.add(rayColor(rand, r, world, scn.light, scn.background, 0));
                sample += 1;
            }
            pixels[i][j] = RGB.fromVec3(pixelColour.mult(f64, 1.0 / @intToFloat(f64, config.samples)).pow(1.0 / 2.2));

            i += 1;
        }
        j += 1;
    }

    const file = try std.fs.cwd().createFile(args.output, .{});
    defer file.close();

    try ppm.write(file.writer(), pixels);

    std.log.info("all your pixels are belong to us.", .{});
}
