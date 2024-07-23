const std = @import("std");
const chars = @import("./chars.zig");
const check = @import("./checks.zig");
const input = @import("./inputs.zig");
const builtin = @import("builtin");
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const tag = builtin.target.os.tag;
const run = std.process.Child.run;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Run pre-checks first
    var copyable = false;
    copyable = check.ImplementedOs();
    copyable = try check.CopyCommandAvailable(allocator);
    var shell = std.ArrayList(u8).init(allocator);
    defer shell.deinit();
    var copy_command = std.ArrayList(u8).init(allocator);
    defer copy_command.deinit();
    if (copyable) {
        switch (try check.GetShell(allocator)) {
            .bash => {
                try shell.appendSlice("bash");
            },
            .zsh => {
                try shell.appendSlice("zsh");
            },
        }

        switch (tag) {
            .linux => {
                try copy_command.appendSlice(" | xclip -selection clipboard &> /dev/null");
            },
            .macos => {
                try copy_command.appendSlice(" | pbcopy");
            },
            else => {
                unreachable;
            },
        }
    }

    // Create character map
    var map = std.AutoHashMap(u8, [chars.ROWS_SIZE][chars.COLUMNS_SIZE]u8).init(allocator);
    defer map.deinit();
    try chars.GetCharsMap(&map);

    // Create Row ArrayLists
    var rows: [chars.ROWS_SIZE]std.ArrayList(u8) = undefined;
    for (0..chars.ROWS_SIZE) |num| {
        rows[num] = std.ArrayList(u8).init(allocator);
    }
    defer deinitRows(&rows);

    // Get user input
    const inputs = try input.GetInputs(allocator);
    defer allocator.free(inputs.input);
    defer allocator.free(inputs.slackmoji);
    defer allocator.free(inputs.spacer);

    for (inputs.input) |char| {
        const letter = map.get(char) orelse null;

        if (letter == null) {
            std.debug.print("\n\n[!] Character '{c}' is not available for slackmoji art. Sorry!\n", .{char});
            std.process.exit(1);
        } else {
            for (0..chars.ROWS_SIZE) |i| {
                const letterRow = letter.?[i];
                try rows[i].appendSlice(try replacer(letterRow, inputs.slackmoji, inputs.spacer));
                try rows[i].appendSlice(inputs.spacer);
                try rows[i].appendSlice(" ");
            }
        }
    }

    // Create the final string for printing
    var command_string = std.ArrayList(u8).init(allocator);
    if (copyable) {
        try command_string.appendSlice("echo \"");
        for (0..chars.ROWS_SIZE) |i| {
            try command_string.appendSlice(rows[i].items);
            try command_string.appendSlice("\n");
        }
        try command_string.appendSlice("\"");
        try command_string.appendSlice(copy_command.items);

        const proc = try run(.{
            .allocator = allocator,
            .argv = &.{ shell.items, "-c", command_string.items },
        });
        defer allocator.free(proc.stdout);
        defer allocator.free(proc.stderr);
        std.debug.print("{s}{s}", .{ proc.stdout, proc.stderr });
        try stdout.writeAll("\u{1FAE1}  slackmoji strings copied to your clipboard and ready to be pasted into Slack\n");
    } else {
        try stdout.writeAll("\u{1F643}  copy command not found, so we'll just print what we would have copied to your clipboard\n\n");
        for (0..chars.ROWS_SIZE) |i| {
            try command_string.appendSlice(rows[i].items);
            try command_string.appendSlice("\n");
        }
        try stdout.writeAll(command_string.items);
    }
}

fn deinitRows(rows: *[chars.ROWS_SIZE]std.ArrayList(u8)) void {
    for (rows) |row| {
        row.deinit();
    }
}

// Replace rows with slackmoji character
fn replacer(row: [chars.COLUMNS_SIZE]u8, slackmoji: []const u8, spacer: []const u8) ![]u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var rowString = std.ArrayList(u8).init(allocator);
    defer rowString.deinit();

    for (row) |i| {
        switch (i) {
            '.' => {
                try rowString.appendSlice(spacer);
                try rowString.appendSlice(" ");
            },
            'X' => {
                try rowString.appendSlice(slackmoji);
                try rowString.appendSlice(" ");
            },
            else => {
                unreachable;
            },
        }
    }

    return try rowString.toOwnedSlice();
}

test "tests" {
    _ = @import("./chars.zig");
}
