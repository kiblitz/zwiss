const std = @import("std");
const argsParser = @import("args");

const util = @import("util.zig");

const ArgParseSpec = struct {
    help: bool = false,
    version: bool = false,

    pub const shorthands: struct { h: []const u8, v: []const u8 } =
        .{ .h = "help", .v = "version" };

    pub const meta: struct {
        full_text: []const u8,
        usage_summary: []const u8,
        option_docs: struct {
            help: []const u8,
            version: []const u8,
        },
    } = .{
        .usage_summary = "[<options>] [<command>] ...",
        .full_text =
        \\A collection of useful cli tools written in zig
        \\
        \\Commands:
        \\  help
        \\  csv
        ,
        .option_docs = .{
            .help = "show the help dialog",
            .version = "zwiss version",
        },
    };
};

const ArgParseVerb = union(enum) {
    help: ArgParseHelpSpec,
    csv: ArgParseCsvSpec,
};

const ArgParseHelpSpec = struct {
    pub const meta = ArgParseSpec.meta;
};
const ArgParseCsvSpec = struct {
    pub const meta: struct {
        full_text: []const u8,
        usage_summary: []const u8,
        option_docs: struct {
            help: []const u8,
            version: []const u8,
        },
    } = .{
        .usage_summary = "csv <filepath> [<options>]",
        .full_text =
        \\A collection of useful csv cli tools written in zig
        ,
        .option_docs = .{
            .help = "show the help dialog",
            .version = "zwiss version",
        },
    };
};

const WhichCommand = enum {
    toplevel,
    csv,
};

pub fn parse_args(allocator: std.mem.Allocator) !argsParser.ParseArgsResult(
    ArgParseSpec,
    ArgParseVerb,
) {
    return argsParser.parseWithVerbForCurrentProcess(
        ArgParseSpec,
        ArgParseVerb,
        allocator,
        .print,
    );
}

pub fn handle_csv(allocator: std.mem.Allocator, parsed_args: argsParser.ParseArgsResult(ArgParseSpec, ArgParseVerb), csv_args: ArgParseCsvSpec) !void {
    _ = csv_args;

    if (parsed_args.options.help) {
        try internal_print_help(.csv, parsed_args);
        return;
    }

    const debug_print = struct {
        fn call(line: []const u8) void {
            std.debug.print(">> {s}\n", .{line});
        }
    }.call;

    if (parsed_args.positionals.len != 1) {
        std.debug.print(
            \\{s}
            \\expected: 1 [filepath]
            \\got: {d}
            \\
            \\
        , .{ util.error_as_string(error.UnexpectedArgsPositionalCount), parsed_args.positionals.len });
        try internal_print_help(.csv, parsed_args);
        return;
    }

    const filepath = parsed_args.positionals[0];
    try util.process_lines(allocator, filepath, debug_print);
}

fn internal_print_help(which_command: WhichCommand, parsed_args: argsParser.ParseArgsResult(ArgParseSpec, ArgParseVerb)) !void {
    if (parsed_args.executable_name) |executable_name| {
        const context = .{ .executable_name = executable_name };

        const print_command_help = struct {
            fn call(comptime Spec: type, closure: *const @TypeOf(context)) !void {
                try argsParser.printHelp(Spec, closure.executable_name, std.io.getStdOut().writer());
            }
        }.call;

        switch (which_command) {
            .toplevel => try print_command_help(ArgParseSpec, &context),
            .csv => try print_command_help(ArgParseCsvSpec, &context),
        }
    }
}

pub fn print_help(parsed_args: argsParser.ParseArgsResult(ArgParseSpec, ArgParseVerb)) !void {
    try internal_print_help(.toplevel, parsed_args);
}
