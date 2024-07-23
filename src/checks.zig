const std = @import("std");
const builtin = @import("builtin");
const run = std.process.Child.run;
const tag = builtin.target.os.tag;

// Currently only supports linux and mac for automatically copying
pub fn ImplementedOs() bool {
    switch (tag) {
        .linux => {
            return true;
        },
        .macos => {
            return true;
        },
        else => {
            return false;
        },
    }
}

pub const Shell = enum { bash, zsh };
pub const ShellError = error{ShellNotFound};
// Check which shell we should use.
pub fn GetShell(allocator: std.mem.Allocator) !Shell {

    // check if bash exists
    const bash_proc = try run(.{ .allocator = allocator, .argv = &.{ "which", "bash" } });
    defer allocator.free(bash_proc.stderr);
    defer allocator.free(bash_proc.stdout);

    if (bash_proc.term.Exited == 0) {
        return Shell.bash;
    }

    // If there's no bash, we'll use zsh
    const zsh_proc = try run(.{ .allocator = allocator, .argv = &.{ "which", "zsh" } });
    defer allocator.free(zsh_proc.stderr);
    defer allocator.free(zsh_proc.stdout);

    if (zsh_proc.term.Exited == 0) {
        return Shell.zsh;
    }

    return ShellError.ShellNotFound;
}

pub fn CopyCommandAvailable(allocator: std.mem.Allocator) !bool {
    switch (tag) {
        .linux => {
            const proc = try run(.{ .allocator = allocator, .argv = &.{ "which", "xclip" } });
            defer allocator.free(proc.stdout);
            defer allocator.free(proc.stderr);

            if (proc.term.Exited == 0) {
                return true;
            } else {
                return false;
            }
        },
        .macos => {
            const proc = try run(.{ .allocator = allocator, .argv = &.{ "which", "pbcopy" } });
            defer allocator.free(proc.stdout);
            defer allocator.free(proc.stderr);

            if (proc.term.Exited == 0) {
                return true;
            } else {
                return false;
            }
        },
        else => {
            return false;
        },
    }
}
