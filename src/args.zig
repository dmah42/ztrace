const std = @import("std");
const Config = @import("config.zig").Config;

pub const UsageError = error{
    MissingExeName,
    UndefinedOutput,
    UndefinedConfig,
    UnknownConfig,
    UnknownArg,
};

pub const Args = struct {
    exe_name: []const u8,
    output: []const u8,
    config: Config,

    fn parseConfig(cfg: []const u8) !Config {
        if (std.mem.eql(u8, cfg, "tst")) {
            return .tst;
        } else if (std.mem.eql(u8, cfg, "low")) {
            return .low;
        } else if (std.mem.eql(u8, cfg, "hi")) {
            return .hi;
        } else if (std.mem.eql(u8, cfg, "xhi")) {
            return .xhi;
        }
        return UsageError.UnknownConfig;
    }

    pub fn parse(alloc: *std.mem.Allocator) !Args {
        var output: []const u8 = "image.ppm";
        var config: []const u8 = "tst";
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
            } else if (std.mem.eql(u8, argument, "--config") or std.mem.eql(u8, argument, "-c")) {
                if (iter.next(alloc)) |arg_value| {
                    config = try arg_value;
                } else {
                    return UsageError.UndefinedConfig;
                }
            } else if (std.mem.eql(u8, argument, "--help") or std.mem.eql(u8, argument, "-h")) {
                std.log.info("Usage: {s} {s}", .{ exe_name, usage() });
                std.os.exit(0);
            } else {
                return UsageError.UnknownArg;
            }
        }

        return Args{
            .exe_name = exe_name,
            .output = output,
            .config = try parseConfig(config),
        };
    }

    pub fn usage() []const u8 {
        return "[--output|-o <output_file>] [--config|-c 'tst|low|hi|xhi']";
    }
};
