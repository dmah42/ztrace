const Config = struct {
    samples: usize,
    width: usize,
    max_depth: u32,
};

pub fn hi_res() Config {
    return .{
        .samples = 1000,
        .width = 1080,
        .max_depth = 10,
    };
}

pub fn test_render() Config {
    return .{
        .samples = 10,
        .width = 400,
        .max_depth = 5,
    };
}

pub fn low_res() Config {
    return .{
        .samples = 100,
        .width = 1080,
        .max_depth = 5,
    };
}
