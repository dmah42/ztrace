const std = @import("std");
const object = @import("object.zig");
const Box = @import("box.zig").Box;
const Camera = @import("camera.zig").Camera;
const Materials = @import("materials.zig").Materials;
const RotateY = @import("rotate.zig").RotateY;
const Sphere = @import("sphere.zig").Sphere;
const XZRect = @import("aarect.zig").XZRect;
const vec3 = @import("vec3.zig");

const Object = object.Object;
const Vec3 = vec3.Vec3;

pub const Scene = struct {
    pub const Type = enum {
        balls,
        cornell,
        pyramid,
    };

    camera: Camera,
    objects: std.ArrayList(Object),
    background: Vec3,
    light: Object,

    pub fn create(t: Type, alloc: *std.mem.Allocator, rand: *std.rand.Random) !Scene {
        return switch (t) {
            .balls => try createBalls(alloc, rand),
            .cornell => try createCornellBox(alloc, rand),
            .pyramid => try createPyramid(alloc, rand),
        };
    }

    fn createBalls(alloc: *std.mem.Allocator, rand: *std.rand.Random) !Scene {
        var objects = std.ArrayList(Object).init(alloc);

        try objects.append(object.asSphere(
            Sphere{ .center = Vec3.init(0, -1000, 0), .radius = 1000 },
            "ground",
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
                    const metalFac = rand.float(f32) * (1.0 - lambFac);
                    const dielectricFac = 1.0 - lambFac - metalFac;

                    try objects.append(object.asSphere(
                        Sphere{ .center = c, .radius = 0.2 },
                        "",
                        .{
                            .lambFac = lambFac,
                            .lamb = .{ .albedo = vec3.random(rand) },
                            .metalFac = metalFac,
                            .metal = .{ .albedo = vec3.random(rand), .fuzz = rand.float(f64) },
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
            "dielectric",
            .{
                .dielectricFac = 1.0,
                .dielectric = .{ .index = 1.5 },
            },
            Vec3.zero(),
        ));

        try objects.append(object.asSphere(
            Sphere{ .center = Vec3.init(-4, 1, 0), .radius = 1.0 },
            "lambertian",
            .{
                .lambFac = 1.0,
                .lamb = .{ .albedo = Vec3.init(0.4, 0.2, 0.1) },
            },
            Vec3.zero(),
        ));

        try objects.append(object.asSphere(
            Sphere{ .center = Vec3.init(4, 1, 0), .radius = 1.0 },
            "metal",
            .{
                .metalFac = 1.0,
                .metal = .{ .albedo = Vec3.init(0.7, 0.6, 0.5) },
            },
            Vec3.zero(),
        ));

        const light = object.asXZRect(
            XZRect{ .x0 = -4, .x1 = 4, .z0 = -4, .z1 = 4, .k = 4 },
            "light",
            .{},
            Vec3.init(5, 5, 5),
        );
        try objects.append(light);

        return Scene{
            .camera = Camera.init(
                Vec3.init(13, 2, 3),
                Vec3.zero(),
                Vec3.init(0, 1, 0),
                20.0,
                16.0 / 10.0,
                0.2,
                10.0,
            ),
            .objects = objects,
            .light = light,
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
        }, "right wall", green, Vec3.zero()));
        try objects.append(object.asYZRect(.{
            .y0 = 0.0,
            .y1 = 555.0,
            .z0 = 0.0,
            .z1 = 555.0,
            .k = 0.0,
        }, "left wall", red, Vec3.zero()));
        try objects.append(object.asXZRect(.{
            .x0 = 0.0,
            .x1 = 555.0,
            .z0 = 0.0,
            .z1 = 555.0,
            .k = 0.0,
        }, "floor", white, Vec3.zero()));
        try objects.append(object.asXZRect(.{
            .x0 = 0.0,
            .x1 = 555.0,
            .z0 = 0.0,
            .z1 = 555.0,
            .k = 555.0,
        }, "ceiling", white, Vec3.zero()));
        try objects.append(object.asXYRect(.{
            .x0 = 0.0,
            .x1 = 555.0,
            .y0 = 0.0,
            .y1 = 555.0,
            .k = 555.0,
        }, "back wall", white, Vec3.zero()));

        const light = object.asXZRect(.{
            .x0 = 213,
            .x1 = 343,
            .z0 = 227,
            .z1 = 332,
            .k = 554,
        }, "light", .{}, Vec3.init(15, 15, 15));
        try objects.append(light);

        var right_box = try alloc.create(Object);
        right_box.* = object.asBox(
            Box.init(Vec3.zero(), Vec3.init(165, 165, 165)),
            "right box",
            .{},
            Vec3.zero(),
        );

        var rotated_right_box = try alloc.create(Object);
        rotated_right_box.* = object.asRotateY(
            RotateY.init(right_box, -18),
            "rot right box",
            white,
            Vec3.zero(),
        );

        var translated_right_box = try alloc.create(Object);
        translated_right_box.* = object.asTranslate(.{
            .object = rotated_right_box,
            .offset = Vec3.init(130, 0, 65),
        }, "trans right box", white, Vec3.zero());
        try objects.append(translated_right_box.*);

        var left_box = try alloc.create(Object);
        left_box.* = object.asBox(
            Box.init(Vec3.zero(), Vec3.init(165, 330, 165)),
            "left box",
            .{},
            Vec3.zero(),
        );

        var rotated_left_box = try alloc.create(Object);
        rotated_left_box.* = object.asRotateY(RotateY.init(left_box, 15), "rot left box", .{}, Vec3.zero());

        const translated_left_box = try alloc.create(Object);
        translated_left_box.* = object.asTranslate(.{
            .object = rotated_left_box,
            .offset = Vec3.init(265, 0, 295),
        }, "trans left box", white, Vec3.zero());

        try objects.append(translated_left_box.*);

        return Scene{
            .camera = Camera.basic(
                Vec3.init(278, 278, -800),
                Vec3.init(278, 278, 0),
                40.0,
                1.2,
            ),
            .objects = objects,
            .background = Vec3.zero(),
            .light = light,
        };
    }

    fn createPyramid(alloc: *std.mem.Allocator, rand: *std.rand.Random) !Scene {
        var objects = std.ArrayList(Object).init(alloc);

        const radius = 20.0;
        const delta = 2 * radius / std.math.sqrt(2.0);

        const glass: Materials =
            .{
            .dielectricFac = 1.0,
            .dielectric = .{ .index = 1.5 },
        };

        try objects.append(object.asXZRect(
            .{
                .x0 = -1000,
                .x1 = 1000,
                .z0 = -1000,
                .z1 = 1000,
                .k = 0,
            },
            "ground",
            .{ .lambFac = 1.0, .lamb = .{ .albedo = Vec3.init(0.01, 0.1, 0.05) } },
            Vec3.zero(),
        ));

        var ball = try alloc.create(Object);
        ball.* = object.asSphere(
            .{
                .center = Vec3.init(0.0, radius, 0.0),
                .radius = radius,
            },
            "ball",
            .{},
            Vec3.zero(),
        );

        var front_ball = try alloc.create(Object);
        front_ball.* = object.asTranslate(
            .{
                .object = ball,
                .offset = Vec3.init(0, 0, -delta),
            },
            "front ball",
            glass,
            Vec3.zero(),
        );
        try objects.append(front_ball.*);

        var left_ball = try alloc.create(Object);
        left_ball.* = object.asTranslate(
            .{
                .object = ball,
                .offset = Vec3.init(-delta, 0, 0),
            },
            "left ball",
            glass,
            Vec3.zero(),
        );
        try objects.append(left_ball.*);

        var right_ball = try alloc.create(Object);
        right_ball.* = object.asTranslate(
            .{
                .object = ball,
                .offset = Vec3.init(delta, 0, 0),
            },
            "right ball",
            glass,
            Vec3.zero(),
        );
        try objects.append(right_ball.*);

        var top_ball = try alloc.create(Object);
        top_ball.* = object.asTranslate(
            .{
                .object = ball,
                .offset = Vec3.init(0, delta, 0),
            },
            "top ball",
            glass,
            Vec3.zero(),
        );
        try objects.append(top_ball.*);

        const light = object.asSphere(
            .{
                .center = Vec3.init(0, 200, -400),
                .radius = 2,
            },
            "light",
            .{},
            Vec3.init(0.8, 0.8, 0.7),
        );
        try objects.append(light);

        return Scene{
            .camera = Camera.basic(
                Vec3.init(0, 60, -150),
                Vec3.init(0, radius, 0),
                40.0,
                4.0 / 3.0,
            ),
            .objects = objects,
            .background = Vec3.init(0.0, 0.1, 0.2),
            .light = light,
        };
    }
};
