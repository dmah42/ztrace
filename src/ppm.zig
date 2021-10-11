const std = @import("std");
const rgb = @import("rgb.zig");

pub fn write(writer: std.fs.File.Writer, pixels: anytype) !void {
    const width = pixels.len;
    const height = pixels[0].len;
        
    std.log.info("writing ppm: {d} x {d}", .{width, height});

    _ = try writer.write("P3\n");
    try writer.print("{d} {d}\n", .{width, height});
    _ = try writer.write("255\n");

    var j:i32 = height - 1;
    while(j >= 0) {
        var i:usize = 0;
        while (i < width) {
            const pixel = pixels[i][@intCast(usize, j)];

            std.log.debug(".. writing pixel {d}, {d}: {s}", .{i, j, pixel});
            try writer.print("{d} {d} {d}\n", .{pixel.r, pixel.g, pixel.b});

            i += 1;
        }
        j -= 1;
    }
}