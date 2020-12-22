const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const print = std.debug.print;
const util = @import("utils.zig");
const input = @embedFile("../in/day01.txt");

/// Strategy:
///  Store expenses in a hash set and query the set for existence of a complement 
///  fulfilling the sum.
/// Example:
///  Set: {1,2,3}
///  Target_Sum: 3
///  Complement(x) = Target_Sum - x
///  since Set.contains(Complement(1)), we know that (1 + Complement(1)) = Target_Sum 
/// Complexity:  Time O(n), Space O(n)
fn part1(allocator: *mem.Allocator, target: u16) !void {
    const expenses: []u16 = try util.splitToInts(u16, allocator, input, "\n");
    var expense_index = util.HashSet(u16).init(allocator);
    for (expenses) |expense| { try expense_index.put(expense, {}); }

    const pair = findPairSum(expenses, &expense_index, target).?;
    const n1 = pair.n1;
    const n2 = pair.n2;

    print("part1:\t{} * {} = {}", .{n1, n2, @as(u32, n1) * n2});
}

const Pair = struct {n1: u16, n2: u16};
fn findPairSum(expenses: []u16, expense_index: *util.HashSet(u16), target: u16) ?Pair {
    const tmp: ?u16 = blk: {
        for (expenses) |expense| {
            if (expense > target) continue; // guard for overflow
            if (expense_index.contains(target - expense)) {
                break :blk expense;
            }
        }
        break :blk null;
    };  

    if (tmp) |value| {
        return Pair{.n1 = value,  .n2 = target - value};
    } else {
        return null;
    }
}

fn part2(allocator: *mem.Allocator, target: u16) !void {
    const expenses: []u16 = try util.splitToInts(u16, allocator, input, "\n");
    var expense_index = util.HashSet(u16).init(allocator);
    for (expenses) |expense| { try expense_index.put(expense, {}); }

    for (expenses) |n3| {
        if (n3 > target) continue; // guard for overflow
        const pair = findPairSum(expenses, &expense_index, target - n3) orelse continue;
        const n1 = pair.n1;
        const n2 = pair.n2;
        print("part2:\t{} * {} * {} = {}", .{n1, n2, n3, @as(u32, n1) * n2 * n3});
        break;
    }
} 

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    try part1(allocator, 2020);
    print("\n", .{});
    try part2(allocator, 2020);
}
