const Config = struct {
    samples: usize,
    width: usize,
    max_depth: u32,
};

pub fn xhi_res() Config {
    return .{
        .samples = 1000,
        .width = 4096,
        .max_depth = 20,
    };
}

pub fn hi_res() Config {
    return .{
        .samples = 500,
        .width = 1024,
        .max_depth = 10,
    };
}

pub fn lo_res() Config {
    return .{
        .samples = 100,
        .width = 800,
        .max_depth = 5,
    };
}

pub fn test_render() Config {
    return .{
        .samples = 10,
        .width = 400,
        .max_depth = 2,
    };
}
