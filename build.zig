const builtin = @import("builtin");
const std = @import("std");
pub fn addInstrumentedExe(
    b: *std.Build,
    obj: *std.Build.Step.Compile,
) std.Build.LazyPath {
    const pkg = b.dependencyFromBuildZig(
        @This(),
        .{},
    );
    const afl_cc = b.addSystemCommand(&.{
        b.findProgram(&.{"afl-cc"}, &.{}) catch
            @panic("Error: could not find 'afl-cc', which is required to build"),
        "-O3",
    });
    if (builtin.target.os.tag.isDarwin()) {
        afl_cc.addArg("-fuse-ld=lld");
    }
    afl_cc.addArg("-o");
    const fuzz_exe = afl_cc.addOutputFileArg(obj.name);
    afl_cc.addFileArg(pkg.path("afl.c"));
    afl_cc.addFileArg(obj.getEmittedLlvmBc());
    obj.bundle_ubsan_rt = true;
    obj.bundle_compiler_rt = true;
    obj.root_module.pic = true;
    afl_cc.addFileArg(obj.getEmittedBin());
    return fuzz_exe;
}
pub fn addFuzzerRun(
    b: *std.Build,
    exe: std.Build.LazyPath,
    corpus_dir: std.Build.LazyPath,
    output_dir: std.Build.LazyPath,
) *std.Build.Step.Run {
    const run = b.addSystemCommand(&.{
        b.findProgram(&.{"afl-fuzz"}, &.{}) catch
            @panic("Error: could not find 'afl-fuzz', which is required to run"),
        "-i",
    });
    run.addDirectoryArg(corpus_dir);
    run.addArgs(&.{"-o"});
    run.addDirectoryArg(output_dir);
    run.addArgs(&.{"--"});
    run.addFileArg(exe);
    return run;
}
pub fn build(b: *std.Build) !void {
    _ = b;
}
