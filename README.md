# libexpat zig

[Expat](https://libexpat.github.io/), packaged for the Zig build system.

## Using

```zig
const dep = b.dependency("libexpat", .{ .target = target, .optimize = optimize });
exe.root_module.linkLibrary(dep.artifact("expat"));
```
