const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const progs = [_]struct {
        name: []const u8,
        source: []const u8,
    }{
        .{ .name = "fib", .source = "fib.zig" },
        .{ .name = "lucas", .source = "lucas.zig" },
    };

    for (progs) |prog| {
        const exe = b.addExecutable(.{
            .name = prog.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(prog.source),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.linkSystemLibrary("gmp", .{});

        b.installArtifact(exe);
    }
}
