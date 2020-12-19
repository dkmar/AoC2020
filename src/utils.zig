const std = @import("std");
const mem = std.mem;
const fmt = std.fmt;

pub fn splitToInts(comptime T: type, allocator: *mem.Allocator, 
                   buffer: []const u8, delim: []const u8) ![]T {
    var ints = std.ArrayList(T).init(allocator);
    errdefer ints.deinit();

    var it = mem.split(buffer, delim);
    while (it.next()) |field| {
        if (field.len == 0) continue;
        const int = try fmt.parseInt(T, field, 10);
        try ints.append(int);
    }

    return ints.toOwnedSlice();
}

test "split ints" {
    var allocator = std.testing.allocator;

    const txt = "123\n456\n";
    const ints = try splitToInts(u16, allocator, txt, "\n");
    defer allocator.free(ints);

    std.testing.expectEqualSlices(u16, &[_]u16 {123, 456}, ints);
}