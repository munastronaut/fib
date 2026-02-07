const std = @import("std");
const Io = std.Io;
const process = std.process;
const Init = process.Init;
const ascii = std.ascii;
const mem = std.mem;
const fmt = std.fmt;
const builtin = @import("builtin");

const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("gmp.h");
});

const log2_phi: f64 = std.math.log2(std.math.phi);

pub fn main(init: Init) !void {
    const allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(allocator);

    var stdout_buffer: [4096]u8 = undefined;
    var stderr_buffer: [4096]u8 = undefined;

    var stdout_writer = Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_writer = Io.File.stderr().writer(init.io, &stderr_buffer);
    const stderr = &stderr_writer.interface;

    if (args.len != 2) {
        try stdout.print("Usage: {s} <number>\n", .{args[0]});
        try stdout.flush();
        process.exit(1);
    }

    const number_arg = mem.trim(u8, args[1], &ascii.whitespace);

    if (ascii.startsWithIgnoreCase(number_arg, "-")) {
        try stderr.writeAll("Error: Input must be a nonnegative integer\n");
        try stderr.flush();
        process.exit(1);
    }

    const n = fmt.parseInt(u64, number_arg, 10) catch |err| {
        switch (err) {
            error.InvalidCharacter => try stderr.writeAll("Error: Could not parse number input\n"),
            error.Overflow => try stderr.writeAll("Error: Number cannot fit in range of u64\n"),
        }
        try stderr.flush();
        process.exit(1);
    };

    const bits: c_ulong = @as(c_ulong, @intFromFloat(@as(f64, @floatFromInt(n)) * log2_phi)) + 2;

    var a: c.mpz_t = undefined;
    var b: c.mpz_t = undefined;
    var t1: c.mpz_t = undefined;
    var t2: c.mpz_t = undefined;
    var t_a: c.mpz_t = undefined;
    c.mpz_init2(&a, bits);
    c.mpz_init2(&b, bits);
    c.mpz_init2(&t1, bits);
    c.mpz_init2(&t2, bits);
    c.mpz_init2(&t_a, bits);
    c.mpz_set_ui(&a, 2);
    c.mpz_set_ui(&b, 1);
    defer c.mpz_clears(&a, &b, &t1, &t2, &t_a, @as(?*c.FILE, null));

    var i: u6 = if (n == 0) 0 else @intCast(64 - @clz(n));

    const start = Io.Clock.awake.now(init.io);

    while (i > 0) {
        i -= 1;

        c.mpz_mul(&t1, &a, &a);
        c.mpz_mul(&t2, &a, &b);

        if ((n >> (i + 1)) & 1 != 0) {
            c.mpz_add_ui(&t_a, &t1, 2);
            c.mpz_add_ui(&b, &t2, 1);
        } else {
            c.mpz_sub_ui(&t_a, &t1, 2);
            c.mpz_sub_ui(&b, &t2, 1);
        }

        c.mpz_swap(&a, &t_a);

        if ((n >> i) & 1 != 0) {
            c.mpz_add(&t1, &a, &b);
            c.mpz_swap(&a, &b);
            c.mpz_swap(&b, &t1);
        }
    }

    const end = Io.Clock.awake.now(init.io);
    const duration = start.durationTo(end).toNanoseconds();

    try stdout.print("L_{d} = ", .{n});
    try stdout.flush();

    _ = c.mpz_out_str(@as(?*c.FILE, null), 10, &a);
    _ = c.fflush(@as(?*c.FILE, null));

    try stdout.writeByte('\n');
    try stdout.writeAll("Calculation time: ");
    try stdout.printDuration(@as(i64, @intCast(duration)), .{});
    try stdout.writeByte('\n');
    try stdout.flush();
}
