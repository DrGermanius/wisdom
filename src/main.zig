const std = @import("std");
const net = std.net;
const Thread = std.Thread;

const PORT = 63689;
const ADDR = "127.0.0.1";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const handle = try Thread.spawn(.{}, client, .{});
    handle.detach();

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(net.Address.parseIp(ADDR, PORT) catch unreachable);
    std.debug.print("listening at {}\n", .{server.listen_address});

    var conn = try server.accept();
    defer conn.stream.close();
    std.debug.print("Connection received! {} is sending data.\n", .{conn.address});

    const message = try conn.stream.reader().readAllAlloc(allocator, 1000);
    defer allocator.free(message);

    std.debug.print("{} says {s}\n", .{ conn.address, message });

    while (true) {}
}

fn client() !void {
    std.time.sleep(std.time.ns_per_s * 4);

    const peer = try net.Address.parseIp(ADDR, PORT);
    const stream = try net.tcpConnectToAddress(peer);
    defer stream.close();

    // while (true) {
        try stream.writer().writeAll("hello zig");
        std.debug.print("Sending  to peer, total written:  bytes\n", .{});
    // }
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
