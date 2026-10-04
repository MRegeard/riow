//! By convention, root.zig is the root source file when making a package.
const std = @import("std");

pub const geom = @import("geom.zig");
pub const color = @import("color.zig");
pub const Ray = @import("ray.zig");
