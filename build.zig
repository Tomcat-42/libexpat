const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "Library linkage type") orelse .static;

    const upstream = b.dependency("upstream", .{});
    const lib_dir = upstream.path("expat/lib");
    const os = target.result.os.tag;

    const config_h = b.addConfigHeader(.{ .style = .blank, .include_path = "expat_config.h" }, .{
        .BYTEORDER = @as(i64, if (target.result.cpu.arch.endian() == .big) 4321 else 1234),
        .HAVE_ARC4RANDOM_BUF = opt(os.isBSD() or os == .macos),
        .HAVE_ARC4RANDOM = opt(os.isBSD() or os == .macos),
        .HAVE_GETRANDOM = opt(os == .linux),
        .HAVE_SYSCALL_GETRANDOM = opt(os == .linux),
        .XML_CONTEXT_BYTES = @as(i64, 1024),
        .XML_DEV_URANDOM = opt(os != .windows),
        .XML_DTD = opt(true),
        .XML_GE = @as(i64, 1),
        .XML_NS = opt(true),
    });

    const mod = b.createModule(.{ .target = target, .optimize = optimize, .link_libc = true });
    mod.addConfigHeader(config_h);
    mod.addIncludePath(lib_dir);
    mod.addCSourceFiles(.{ .root = lib_dir, .files = &.{ "xmlparse.c", "xmlrole.c", "xmltok.c" }, .flags = &(.{
        "-std=c99", "-fvisibility=hidden", "-DHAVE_EXPAT_CONFIG_H",
    } ++ .{if (linkage == .dynamic) "-DXML_ENABLE_VISIBILITY=1" else ""}) });

    const lib = b.addLibrary(.{ .name = "expat", .root_module = mod, .linkage = linkage });
    inline for (.{ "expat.h", "expat_external.h" }) |h| lib.installHeader(lib_dir.path(b, h), h);
    b.installArtifact(lib);
}

inline fn opt(v: bool) ?bool {
    return if (v) true else null;
}
