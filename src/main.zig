const std = @import("std");

const ArgParseError = error{
    ExpectedFilepath,
};

const Args = struct {
    filepath: []const u8,
};

fn get_args(allocator: std.mem.Allocator) !Args {
    var args_iterator = try std.process.ArgIterator.initWithAllocator(allocator);
    defer args_iterator.deinit();

    // Skip executable
    _ = args_iterator.next();

    if (args_iterator.next()) |filepath| {
        return Args{
            .filepath = filepath,
        };
    }

    return error.ExpectedFilepath;
}

fn process_lines(allocator: std.mem.Allocator, filepath: []const u8, f: fn ([]const u8) void) anyerror!void {
    const file = try std.fs.cwd().openFile(filepath, .{ .mode = .read_only });
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try get_args(allocator);
    std.debug.print("(filename {s})\n", .{args.filepath});

    const debug_print = struct {
        fn call(line: []const u8) void {
            std.debug.print(">> {s}\n", .{line});
        }
    }.call;

    try process_lines(allocator, args.filepath, debug_print);
}
