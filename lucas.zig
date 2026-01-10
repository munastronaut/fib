const std = @import("std");
const builtin = @import("builtin");

const c = @cImport({
    @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("stdio.h");
    @cInclude("gmp.h");
});

const phi = (1 + std.math.sqrt(5)) / 2;
const log2_phi: f64 = std.math.log2(phi);

pub fn main() !void {
    const allocator = std.heap.smp_allocator;

    var stdout_buffer: [4096]u8 = undefined;
    var stderr_buffer: [4096]u8 = undefined;

    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len != 2) {
        try stderr.writeAll("Usage: lucas <number>\n");
        try stderr.flush();
        std.process.exit(1);
    }

    const number_arg = std.mem.trim(u8, args[1], &std.ascii.whitespace);

    if (std.ascii.startsWithIgnoreCase(number_arg, "-")) {
        try stderr.writeAll("Error: Input must be a nonnegative integer\n");
        try stderr.flush();
        std.process.exit(1);
    }

    const n = std.fmt.parseInt(u64, number_arg, 10) catch |err| switch (err) {
        error.InvalidCharacter => {
            try stderr.writeAll("Error: Could not parse number input\n");
            try stderr.flush();
            std.process.exit(1);
        },
        error.Overflow => {
            try stderr.writeAll("Error: Number cannot fit in range of u64\n");
            try stderr.flush();
            std.process.exit(1);
        },
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
    defer c.mpz_clears(&a, &b, &t1, &t2, &t_a, c.NULL);

    var i: u6 = if (n == 0) 0 else @intCast(64 - @clz(n));

    const start = try std.time.Instant.now();

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

    const end = try std.time.Instant.now();
    const elapsed_seconds = @as(f64, @floatFromInt(end.since(start))) / std.time.ns_per_s;

    const c_stdout = if (builtin.os.tag == .windows)
        c.__acrt_iob_func(1)
    else
        c.stdout;

    try stdout.print("L_{d} = ", .{n});
    try stdout.flush();

    _ = c.mpz_out_str(c_stdout, 10, &a);

    try stdout.writeByte('\n');
    try stdout.print("Calculation time: {d} seconds\n", .{elapsed_seconds});
    try stdout.flush();
}
