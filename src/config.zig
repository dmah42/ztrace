const Config = struct {
    samples: usize,
    width: usize,
    max_depth: u32,
};

pub fn hi_res() Config {
    return .{
        .samples = 500,
        .width = 1080,
        .max_depth = 10,
    };
}

pub fn test_render() Config {
    return .{
        .samples = 10,
        .width = 400,
        .max_depth = 2,
    };
}

pub fn low_res() Config {
    return .{
        .samples = 50,
        .width = 960,
        .max_depth = 5,
    };
}
