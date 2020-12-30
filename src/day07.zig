const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const input = @embedFile("../in/day07.txt");

const AdjacencyList = std.hash_map.StringHashMap(Bag1);
const List          = std.ArrayList([]const u8);
const Queue         = std.fifo.LinearFifo([]const u8, .Dynamic);
const Bag1 = struct {
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
    
    try part2(allocator);
}

const Bag = struct {
    const NestedBag = struct {color: []const u8, quantity: u3};
    color: []const u8,
    contains: []NestedBag
};

fn part2(ally: *mem.Allocator) !void {
    const bags = try parse(ally);
    var map = std.StringHashMap(Bag).init(ally);
    for (bags) |bag| try map.put(bag.color, bag);

    var next_bag: []const u8 = "shiny gold";
    
    const counter = struct {
        bag_map: std.StringHashMap(Bag),
        pub fn countBags(self: @This(), src: []const u8) u16 {
            var count: u16 = 0;
            const inner = self.bag_map.get(src) orelse unreachable;
            for (inner.contains) |nested_bag| {
                count += nested_bag.quantity 
                       + nested_bag.quantity * self.countBags(nested_bag.color);
            }
            return count;
        }
    };

    const c = counter{.bag_map = map};
    const total = c.countBags("shiny gold");

    print("part2: {}\n", .{total});
}

/// Example:
/// --------
/// 'light violet bags contain 3 pale beige bags, 2 mirrored silver bags.'
fn parse(ally: *mem.Allocator) ![]Bag {
    var bags = std.ArrayList(Bag).init(ally);
    errdefer bags.deinit();

    var it = mem.tokenize(input, ".\n"); 
    while (it.next()) |rule| {
        const main_bag = parseBagBlk: {
            const end = mem.indexOf(u8, rule, " bags") orelse unreachable;
            break :parseBagBlk rule[0..end];
        };
        const nested_bags = parseNestedBlk: {
            var list = std.ArrayList(Bag.NestedBag).init(ally);
            if (mem.eql(u8, rule[main_bag.len..], " bags contain no other bags")) {
                break :parseNestedBlk list.toOwnedSlice(); // []NestedBag
            }
            var nested_it = mem.split(rule[main_bag.len+14..], ", ");
            while (nested_it.next()) |bag_info| {
                const quantity = try std.fmt.parseUnsigned(u3, bag_info[0..1], 10);
                const end_offset = 4 + @as(usize, @boolToInt(quantity > 1)); // _bag[s]
                try list.append(Bag.NestedBag{
                    .quantity = quantity,
                    .color = bag_info[2..bag_info.len-end_offset]
                });
            }
            break :parseNestedBlk list.toOwnedSlice(); // []NestedBag
        };
        try bags.append(Bag{.color = main_bag, .contains = nested_bags});
    }

    return bags.toOwnedSlice(); // []Bag
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
            try graph.put(v, Bag1{.edges = List.init(allocator)});
        }

        // assemble inversion
        for (edges) |e| {
            const res = try graph.getOrPutValue(e, Bag1{.edges = List.init(allocator)});
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

