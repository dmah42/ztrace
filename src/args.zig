const std = @import("std");

pub const UsageError = error{
    MissingExeName,
    UndefinedOutput,
    UnknownArg,
};

pub const Args = struct {
    exe_name: []const u8,
    output: []const u8,

    pub fn parse(alloc: *std.mem.Allocator) !Args {
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
};
