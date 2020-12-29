const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const input = @embedFile("../in/day06.txt");

fn part1(it: *mem.SplitIterator) void {
    var sum: u16 = 0;
    while (it.next()) |group| {
        sum += countYesAnswers(group);
    }
    print("part1: {}\n", .{sum});
}

fn part2(it: *mem.SplitIterator) void {
    var sum: usize = 0;
    while (it.next()) |group| {
        sum += countAnswerConsensus(group);
    }
    print("part2: {}\n", .{sum});
}

pub fn main() !void {
    var it = mem.split(input, "\n\n");
    var it2 = it;
    part1(&it);
    part2(&it2);
}

/// Counts the # of distinct answered questions for a group
fn countYesAnswers(group: []const u8) u16 {
    var seen = [_]bool{false} ** 26;
    var count: u16 = 0;
    for (group) |answer| {
        if (std.ascii.isLower(answer) and !seen[answer - 'a']) {
            count += 1;
            seen[answer - 'a'] = true;
        }
    }
    return count;
}

/// Counts the number of questions with consensus between all members of a group
fn countAnswerConsensus(group: []const u8) usize {
    var n_members: u8 = 0;
    var tallies = [_]u8{0} ** 26;
    var it = mem.tokenize(group, " \n");
    while (it.next()) |member| : (n_members += 1) {
        for (member) |answer| {
            tallies[answer - 'a'] += 1; 
        }
    }
    return mem.count(u8, &tallies, &[_]u8{n_members});
}