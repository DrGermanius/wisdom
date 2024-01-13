const std = @import("std");
const hashcash = @import("hashcash.zig");
const net = std.net;
const thread = std.Thread;

const PORT = 63689;
const ADDR = "127.0.0.1";

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

pub fn main() !void {
    defer _ = gpa.deinit();
   
    var res = try hashcash.process("1:16:060408:anni@cypherspace.org:1:1QTjaYd7niiQA/sc:ePa");
    std.debug.print("{any}\n", .{res});
}

pub fn main1() !void {
    const client1_thread = try thread.spawn(.{}, client, .{});
    client1_thread.detach();

    const client2_thread = try thread.spawn(.{}, client, .{});
    client2_thread.detach();

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(net.Address.parseIp(ADDR, PORT) catch unreachable);
    std.debug.print("listening at {}\n", .{server.listen_address});

    while (true) {
        var conn = try server.accept();
        const handle = try thread.spawn(.{}, handle_accept, .{conn});
        handle.detach();
    }
}

fn handle_accept(conn: net.StreamServer.Connection) !void {
    std.debug.print("Connection received! {}.\n", .{conn.address});
    while (true) {
        std.time.sleep(std.time.ns_per_s * 1);
        const message = try conn.stream.reader().readAllAlloc(allocator, 1000);
        if (message.len == 0) { // bad stuff
            allocator.free(message);
            continue;
        }
        std.debug.print("{} says {s}\n", .{ conn.address, message });
        allocator.free(message);
    }
}

fn client() !void {
    std.time.sleep(std.time.ns_per_s * 4);

    const peer = try net.Address.parseIp(ADDR, PORT);
    const stream = try net.tcpConnectToAddress(peer);
    defer stream.close();

    // while (true) {
    try stream.writeAll("hello zig");
    std.debug.print("Sending  to peer, total written:  bytes\n", .{});
    // }
}