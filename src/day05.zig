const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const math = std.math;
const input = @embedFile("../in/day05.txt");

pub fn main() !void {
    var max: u10 = 0;
    var it = mem.split(input, "\n");
    while (it.next()) |pass| max = math.max(max, seatID(pass));
    print("part1: {}", .{max});
}

inline fn seatID(boarding_pass: []const u8) u10 {
    var id: u10 = 0;
    for (boarding_pass) |char| {
        const value: u10 = switch (char) {
            'F','L' => 0,
            'B','R' => 1,
            else    => unreachable
        };
        id = (id << 1) | value;
    }
    return id;
}
