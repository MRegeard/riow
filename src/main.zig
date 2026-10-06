const std = @import("std");
const Io = std.Io;

const riowlib = @import("riowlib");
const geom = riowlib.geom;
const Vec3 = geom.Vec3;
const Point3 = geom.Point3;
const Color = Vec3;
const Ray = riowlib.Ray;
const objects = riowlib.objects;
const Object = objects.Object;
const Hit = objects.Hit;
const Camera = riowlib.Camera;
const material = riowlib.material;

// Material
const material_ground = material.Material.init(.lambertian, Color.init(0.8, 0.8, 0.0), .{});
const material_center = material.Material.init(.lambertian, Color.init(0.1, 0.2, 0.5), .{});
//const material_left = material.Material.init(.metal, Color.init(0.8, 0.8, 0.8), .{ .metal_fuzz = 0.3 });
const material_left = material.Material.init(.dielectric, Color.init(1.0, 1.0, 1.0), .{.refraction_index = 1.5});
const material_bubble = material.Material.init(.dielectric, Color.init(1.0, 1.0, 1.0), .{.refraction_index = 1.0 / 1.5});
const material_right = material.Material.init(.metal, Color.init(0.8, 0.6, 0.2), .{ .metal_fuzz = 1.0 });

// Objects
const sphere_ground = Object{ .sphere = .init(Point3.init(0.0, -100.5, -1.0), 100, @constCast(&material_ground)) };
const sphere_center = Object{ .sphere = .init(Point3.init(0.0, 0.0, -1.2), 0.5, @constCast(&material_center)) };
const sphere_left = Object{ .sphere = .init(Point3.init(-1.0, 0.0, -1.0), 0.5, @constCast(&material_left)) };
const  sphere_bubble = Object{ .sphere = .init(Point3.init(-1.0, 0.0, -1.0), 0.4, @constCast(&material_bubble))};
const sphere_right = Object{ .sphere = .init(Point3.init(1.0, 0, -1.0), 0.5, @constCast(&material_right)) };

// World
const world: [5]Object = .{ sphere_ground, sphere_left, sphere_center, sphere_bubble, sphere_right };

const camera: Camera = .init(16.0 / 9.0, 400, 100, 50);

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const allocator: std.mem.Allocator = arena.allocator();
    defer arena.deinit();

    var threaded: Io.Threaded = .init(allocator, .{});
    const io: Io = threaded.io();

    var file_writer_buffer: [4096]u8 = undefined;
    const file = try Io.Dir.cwd().createFile(io, "data/image.ppm", .{});
    defer file.close(io);
    var file_writer: Io.File.Writer = file.writer(io, &file_writer_buffer);
    var fwriter: *Io.Writer = &file_writer.interface;

    var progess_buffer: [1024]u8 = undefined;
//    const stdout_writer_buffer: []u8 = try allocator.alloc(u8, 256);
    const stdout: Io.File = .stdout();
    var stdout_writer: Io.File.Writer = stdout.writer(io, &progess_buffer);
    var owriter: *Io.Writer = &stdout_writer.interface;


    const progress = std.Progress.start(io, .{
        .draw_buffer = &progess_buffer,
        .estimated_total_items = camera.image_height,
        .root_name = "Scanlines",
    });

    try camera.render(fwriter, progress, @constCast(&world));

    try fwriter.flush();
    try owriter.writeAll("\rDone.                      \n");
    try owriter.flush();
}
