const std = @import("std");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

pub const InputResults = struct { input: []const u8, slackmoji: []const u8, spacer: []const u8 };

// Caller in charge of freeing memory
pub fn GetInputs(allocator: std.mem.Allocator) !InputResults {
    try stdout.writeAll("\n\u{001b}[1;42mO\u{001b}[0mbnoxious");
    try stdout.writeAll("\n\u{001b}[1;42mS\u{001b}[0mlack");
    try stdout.writeAll("\n\u{001b}[1;42mP\u{001b}[0merson\n\n");
    try stdout.writeAll("What would you like to obnoxiously send?  \u{1F440}\n");
    const input = try stdin.readUntilDelimiterAlloc(
        allocator,
        '\n',
        512,
    );

    try stdout.writeAll("\nWhich slackmoji would you like to use?\nExamples:(:rocket:, :white_check_mark:)\n");
    const slackmoji = try stdin.readUntilDelimiterAlloc(allocator, '\n', 64);

    try stdout.writeAll("\nWhich spacer slackmoji would you like to use?\n(Leave blank to use :spacer:)\n");
    var spacer = try stdin.readUntilDelimiterAlloc(allocator, '\n', 64);
    if (spacer.len == 0) {
        spacer = try allocator.dupe(u8, ":spacer:");
    }
    return .{ .input = input, .slackmoji = slackmoji, .spacer = spacer };
}
