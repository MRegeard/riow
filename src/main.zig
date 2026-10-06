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
const Object = objects.Object;
const Hit = objects.Hit;
const Camera = riowlib.Camera;

// World
const sphere1 = Object{ .sphere = .init(Point3.init(0, 0, -1), 0.5) };
const sphere2 = Object{ .sphere = .init(Point3.init(0, -100.5, -1), 100) };
const world: [2]Object = .{ sphere1, sphere2 };

const camera: Camera = .init(16.0 / 9.0, 400, 100, 50);

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

    try camera.render(fwriter, owriter, @constCast(&world));

    try fwriter.flush();
    try owriter.writeAll("\rDone.                      \n");
    try owriter.flush();
}
