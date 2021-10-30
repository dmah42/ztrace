pub const Config = enum {
    tst,
    low,
    hi,
    xhi,

    pub fn samples(self: Config) usize {
        return switch (self) {
            .tst => 10,
            .low => 100,
            .hi => 500,
            .xhi => 1000,
        };
    }

    pub fn width(self: Config) usize {
        return switch (self) {
            .tst => 400,
            .low => 800,
            .hi => 1024,
            .xhi => 1280,
        };
    }

    pub fn maxDepth(self: Config) usize {
        return switch (self) {
            .tst => 2,
            .low => 5,
            .hi => 10,
            .xhi => 20,
        };
    }
};
