const std = @import("std");

pub const Range = @This();

min: f64,
max: f64,

pub fn empty() Range {
    return .{ .min = std.math.inf(f64), .max = -std.math.inf(f64) };
}

pub fn universe() Range {
    return Range{};
}

pub fn size(r: Range) f64 {
    return r.max - r.min;
}

pub fn contains(r: Range, x: f64) bool {
    return (r.min <= x and x <= r.max);
}

pub fn surrounds(r: Range, x: f64) bool {
    return (r.min < x and x < r.max);
}
