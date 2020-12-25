const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const math = std.math;
const input = @embedFile("../in/day05.txt");

pub fn main() !void {
    const max_seat_id = math.maxInt(u10);
    var seat_taken = [_]bool{false} ** max_seat_id;
    var min: u10 = max_seat_id;
    var max: u10 = 0;

    var it = mem.split(input, "\n");
    while (it.next()) |pass| {
        const seat_id = seatID(pass);
        min = math.min(min, seat_id);
        max = math.max(max, seat_id);
        seat_taken[seat_id] = true;
    }
    print("part1: {}\n", .{max});

    // find the only unoccupied seat
    const seat = blk: {
        var id: u10 = min;
        while (seat_taken[id]) id += 1;
        break :blk id;
    };
    print("part2: {}\n", .{seat});
}

// 127 = 0b1111111
//         BBBBBBB
//   0 = 0b0000000
//         FFFFFFF
// So if a given char of the code is 'B', then the corresponding bit is 1.
// And if a given char of the code is 'F', then the corresponding bit is 0.
// Same concept applies to 'R' and 'L' for the remaining three bits.
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
