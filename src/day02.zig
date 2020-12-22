const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const fmt = std.fmt;
const util = @import("utils.zig");
const input = @embedFile("../in/day02.txt");

fn part1() void {
    var eligible_passwords: usize = 0;
    var it = InputParser(input, "- : \n");
    while (it.next()) |line| {
        const char_count = mem.count(u8, line.password, &[_]u8{line.char});
        if (char_count <= line.hi and char_count >= line.lo) {
            eligible_passwords += 1;
        }
    }
    print("part1:\n# eligible passwords: {}\n", .{eligible_passwords});
}

fn part2() void {
    var eligible_passwords: usize = 0;
    var it = InputParser(input, "- : \n");
    while (it.next()) |line| {
        const first = line.lo - 1;
        const second = line.hi - 1;
        if (util.xor(line.password[first] == line.char, 
                     line.password[second] == line.char)) {
            eligible_passwords += 1;
        }
    }
    print("part2:\n# eligible passwords: {}\n", .{eligible_passwords});
}

pub fn main() !void {
    part1();
    part2();
}

fn InputParser(buffer: []const u8, delimiter_bytes: []const u8) LineIterator {
    return LineIterator{
        .token_it = mem.TokenIterator{
            .buffer = buffer,
            .delimiter_bytes = delimiter_bytes,
            .index = 0
        }
    };
}

const ConstrainedPassword = struct {
    lo: u8,
    hi: u8,
    char: u8,
    password: []const u8
};

const LineIterator = struct {
    token_it: mem.TokenIterator,

    pub fn next(self: *LineIterator) ?ConstrainedPassword {
        const lo =  self.token_it.next() orelse return null;
        const hi =  self.token_it.next() orelse return null;

        return ConstrainedPassword{
            .lo = fmt.parseInt(u8, lo, 10) catch { return null; },
            .hi = fmt.parseInt(u8, hi, 10) catch { return null; },
            .char = (self.token_it.next().?)[0],
            .password = self.token_it.next().?,
        };
    }
};