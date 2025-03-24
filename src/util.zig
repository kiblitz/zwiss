const std = @import("std");

pub fn process_lines(allocator: std.mem.Allocator, filepath: []const u8, f: fn ([]const u8) void) !void {
    const file = std.fs.cwd().openFile(filepath, .{ .mode = .read_only }) catch |err| {
        switch (err) {
            error.FileNotFound => return std.debug.print(
                \\{s}
                \\file: {s}
                \\
                \\
            , .{ error_as_string(error.FileNotFound), filepath }),
            else => return err,
        }
    };
    defer file.close();

    var buf_stream = std.io.bufferedReader(file.reader());
    const in_stream = buf_stream.reader().any();

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    while (true) {
        in_stream.streamUntilDelimiter(buf.writer(), '\n', undefined) catch |err|
            switch (err) {
                error.EndOfStream => return,
                else => return err,
            };

        f(buf.items);
        buf.clearRetainingCapacity();
    }
}

pub fn error_as_string(comptime err: anyerror) []const u8 {
    return "error: " ++ @errorName(err);
}
