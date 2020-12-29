const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const input = @embedFile("../in/day07.txt");

const AdjacencyList = std.hash_map.StringHashMap(Bag);
const List          = std.ArrayList([]const u8);
const Queue         = std.fifo.LinearFifo([]const u8, .Dynamic);
const Bag = struct {
    is_connected: bool = false,
    edges: List
};

/// Strategy:
/// 1. Parse input into an inverted digraph (represented by an adjacency list)
/// - inverted bc it means we can start searching from the shiny gold bag and it also
///   guarantees that (when searching) we only visit nodes connected to the shiny gold bag.
/// 2. Find the number of nodes connected to the shiny gold bag 
/// - use BFS so that walking cycles can be prevented by only adding disconnected nodes to the frontier
/// - (TODO think harder about whether DFS could even have this issue)
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = &arena.allocator;

    var graph = try buildInvertedGraph(allocator);

    const count = try countConnectedNodes(allocator, graph);
    print("part1: {}\n", .{count});
}

fn buildInvertedGraph(allocator: *mem.Allocator) !AdjacencyList {
    var graph = AdjacencyList.init(allocator);
    try graph.ensureCapacity(500);
    errdefer graph.deinit();

    var it = mem.split(input, "\n");
    while (it.next()) |rule| {
        const v = blk: {
            const end = mem.indexOf(u8, rule, "bags") orelse continue;
            break :blk rule[0..end-1];
        };

        const edges = blk: {
            var list = List.init(allocator);
            var offset: usize = v.len;
            while (indexOfDigit(rule[offset..])) |idx| {
                const begin = idx+offset+2;
                const end = if (mem.indexOf(u8, rule[begin..], "bag")) |res| res+begin else continue;
                try list.append(rule[begin..end-1]);
                offset = end+3;
            }
            break :blk list.toOwnedSlice();
        };

        // ensure that an entry will exist for each vertex.
        if (!graph.contains(v)) {
            try graph.put(v, Bag{.edges = List.init(allocator)});
        }

        // assemble inversion
        for (edges) |e| {
            const res = try graph.getOrPutValue(e, Bag{.edges = List.init(allocator)});
            try res.value.edges.append(v);
        }
    }

    return graph;
}

fn countConnectedNodes(allocator: *mem.Allocator, graph: AdjacencyList) !usize {
    var count: usize = 0;

    // bfs
    var frontier = Queue.init(allocator);
    defer frontier.deinit();
    try frontier.writeItem("shiny gold");

    while (frontier.readItem()) |v_color| {
        const v = graph.get(v_color) orelse unreachable;
        for (v.edges.items) |u_color| {
            const u = graph.getEntry(u_color) orelse unreachable;
            if (u.value.is_connected) continue;
            u.value.is_connected = true;
            try frontier.writeItem(u_color);
            count += 1;
        }
    }

    return count;
}

fn indexOfDigit(slice: []const u8) ?usize {
    for (slice) |c, i| {
        if (std.ascii.isDigit(c)) return i;
    }
    return null;
}

