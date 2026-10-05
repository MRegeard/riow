const std = @import("std");
const Io = std.Io;

const riowlib = @import("riowlib");
const geom = riowlib.geom;
const Vec3 = geom.Vec3;
const Point3 = geom.Point3;
const color = riowlib.color;
const Color = color.Color;
const Ray = riowlib.Ray;
const objects = riowlib.objects;
const Hittable = objects.Hittable;
const Hit = objects.Hit;

// Image
const aspect_ratio: f64 = 16.0 / 9.0;
const image_width = 400;
const image_width_f64: f64 = @floatFromInt(image_width);

const image_h_f64: f64 = image_width / aspect_ratio;
const image_height: comptime_int = if (image_h_f64 < 1) 1 else @intFromFloat(image_h_f64);
const image_height_f64: f64 = @floatFromInt(image_height);

// Camera
const focal_length: f64 = 1.0;
const viewport_height: f64 = 2.0;
const viewport_width: f64 = viewport_height * (image_width_f64 / image_height_f64);
const camera_center: Point3 = .zeroes();

// Calculate the horizontal and vertical vector across the viewport edges.
const viewport_u: Vec3 = .init(viewport_width, 0, 0);
const viewport_v: Vec3 = .init(0, -viewport_height, 0);

// Calculate associated delta vectors from pixel to pixel.
const pixel_delta_u: Vec3 = viewport_u.scale(1 / image_width_f64);
const pixel_delta_v: Vec3 = viewport_v.scale(1 / image_height_f64);

// Calculate location of the upper left pixel.
const viewport_upper_left = blk: {
    const viewport_u_half = viewport_u.scale(0.5);
    const viewport_v_half = viewport_v.scale(0.5);
    const focal_length_vec: Vec3 = .init(0, 0, focal_length);
    const res = camera_center.sub(focal_length_vec).sub(viewport_u_half).sub(viewport_v_half);
    break :blk res;
};
const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

// World
const sphere1 = Hittable{ .sphere = .init(Point3.init(0, 0 , -1), 0.5)};
const sphere2 = Hittable{ .sphere = .init(Point3.init(0, -100.5, -1), 100)};
const world: [2]Hittable = .{ sphere1, sphere2 };

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const allocator: std.mem.Allocator = arena.allocator();
    defer arena.deinit();

    var threaded: Io.Threaded = .init(allocator, .{});
    const io: Io = threaded.io();

    const file_writer_buffer: []u8 = try allocator.alloc(u8, 1024);
    const file = try Io.Dir.cwd().createFile(io, "data/image.ppm", .{});
    defer file.close(io);
    var file_writer: Io.File.Writer = file.writer(io, file_writer_buffer);
    var fwriter: *Io.Writer = &file_writer.interface;

    const stdout_writer_buffer: []u8 = try allocator.alloc(u8, 256);
    const stdout: Io.File = .stdout();
    var stdout_writer: Io.File.Writer = stdout.writer(io, stdout_writer_buffer);
    var owriter: *Io.Writer = &stdout_writer.interface;

    try fwriter.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        //TODO: Use std.Progess later.
        try owriter.print("\rScanlines remaining: {d}", .{image_height - j});
        try owriter.flush();
        for (0..image_width) |i| {
            const i_f64: f64 = @floatFromInt(i);
            const j_f64: f64 = @floatFromInt(j);
            const pixel_center = pixel00_loc.add(pixel_delta_u.scale(i_f64)).add(pixel_delta_v.scale(j_f64));
            const ray_direction = pixel_center.sub(camera_center);
            const ray: Ray = .{ .origin = camera_center, .direction = ray_direction };
            const pixel_color: Color = color.rayColor(ray, @constCast(&world));
            try color.writeColor(fwriter, pixel_color);
        }
    }

    try fwriter.flush();
    try owriter.writeAll("\rDone.                      \n");
    try owriter.flush();
}

