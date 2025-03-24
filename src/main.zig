const std = @import("std");

const cmd = @import("cmd.zig");
const util = @import("util.zig");

// TODO -- this should synchronize with [build.zig.zon] version but this isn't supported yet.
const version = "0.0.0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    const parsed_args = cmd.parse_args(allocator) catch |err| {
        switch (err) {
            // The parser library already prints out an appropriate error message here
            error.InvalidArguments => return,
            else => return err,
        }
    };
    defer parsed_args.deinit();

    if (parsed_args.options.version) {
        try stdout.print("{s}\n", .{version});
        return;
    }

    if (parsed_args.verb) |verb| {
        return switch (verb) {
            .help => |_| try cmd.print_help(parsed_args),
            .csv => |csv_args| try cmd.handle_csv(allocator, parsed_args, csv_args),
        };
    }

    // If no other option is matched, just print help
    try cmd.print_help(parsed_args);
}
