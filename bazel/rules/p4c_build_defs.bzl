# Copyright 2018-present Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

load("@bazel_tools//tools/cpp:toolchain_utils.bzl", "find_cpp_toolchain")

P4C_BUILD_DEFAULT_COPTS = [
    "-DCONFIG_PKGDATADIR=\\\"external/com_github_p4lang_p4c\\\"",
    # This is a bit of a hack, but will work if the binary is executed by Bazel
    # For a more comprehensive solution, we need to make p4c aware of Bazel, specifically:
    # https://github.com/bazelbuild/bazel/blob/master/tools/cpp/runfiles/runfiles_src.h
]

P4C_COMMON_DEPS = [
]

# The p4_bmv2_compile rule below runs the p4c_bmv2 compiler backend on P4_16
# sources.  The P4_16 code should be targeted to the P4 v1model.  This
# example BUILD rule compiles one of the p4lang/p4c test samples:
#
#   p4_bmv2_compile(
#       name = "p4c_bmv2_compile_test",
#       src = "testdata/p4_16_samples/key-bmv2.p4",
#       hdrs = [
#           "testdata/p4_16_samples/arith-inline-skeleton.p4",
#       ],
#       out_p4_info = "p4c_bmv2_test_p4_info.pb.txt",
#       out_p4_pipeline_json = "p4c_bmv2_test_p4_pipeline.pb.json",
#   )

def _generate_bmv2_config(ctx):
    """Preprocesses P4 sources and runs p4c on pre-processed P4 file."""

    # Preprocess all files and create 'p4_preprocessed_file'.
    p4_preprocessed_file = ctx.actions.declare_file(
        ctx.genfiles_dir.path + ctx.label.name + ".pp.p4",
    )
    cpp_toolchain = find_cpp_toolchain(ctx)
    gcc_args = ctx.actions.args()
    gcc_args.add("-E")
    gcc_args.add("-x")
    gcc_args.add("c")
    gcc_args.add(ctx.file.src.path)
    gcc_args.add("-I.")
    gcc_args.add("-I")
    gcc_args.add(ctx.file._model.dirname)
    gcc_args.add("-I")
    gcc_args.add(ctx.file._core.dirname)
    for hdr in ctx.files.hdrs:
        gcc_args.add("-I " + hdr.dirname)
    gcc_args.add("-o")
    gcc_args.add(p4_preprocessed_file.path)
    gcc_args.add_all(ctx.attr.copts)

    ctx.actions.run(
        arguments = [gcc_args],
        inputs = ([ctx.file.src] + ctx.files.hdrs + [ctx.file._model] +
                  [ctx.file._core]),
        outputs = [p4_preprocessed_file],
        progress_message = "Preprocessing...",
        executable = cpp_toolchain.compiler_executable,
    )

    # Run p4c on pre-processed P4_16 sources to obtain p4info and bmv2 config.
    gen_files = [
        ctx.outputs.out_p4_info,
        ctx.outputs.out_p4_pipeline_json,
    ]

    ctx.actions.run(
        arguments = [
            "--nocpp",
            "--p4v",
            "16",
            "--p4runtime-format",
            "text",
            "--p4runtime-file",
            gen_files[0].path,
            "-o",
            gen_files[1].path,
            p4_preprocessed_file.path,
        ],
        inputs = [p4_preprocessed_file],
        outputs = [gen_files[0], gen_files[1]],
        progress_message = "Compiling P4 sources to generate bmv2 config",
        executable = ctx.executable._p4c_bmv2,
    )

    return struct(files = depset(gen_files))

# Compiles P4_16 source into bmv2 target JSON configuration and p4info.
p4_bmv2_compile = rule(
    implementation = _generate_bmv2_config,
    fragments = ["cpp"],
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = True),
        "hdrs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "out_p4_info": attr.output(mandatory = True),
        "out_p4_pipeline_json": attr.output(mandatory = False),
        "copts": attr.string_list(),
        "_model": attr.label(
            allow_single_file = True,
            mandatory = False,
            default = Label("@com_github_p4lang_p4c//:p4include/v1model.p4"),
        ),
        "_core": attr.label(
            allow_single_file = True,
            mandatory = False,
            default = Label("@com_github_p4lang_p4c//:p4include/core.p4"),
        ),
        "_p4c_bmv2": attr.label(
            cfg = "target",
            executable = True,
            default = Label("@com_github_p4lang_p4c//:p4c_bmv2"),
        ),
        "_cc_toolchain": attr.label(default = Label("@bazel_tools//tools/cpp:current_cc_toolchain")),
    },
    output_to_genfiles = True,
)

def p4_tna_compile(name, src):
    """compiles bf-p4c tna programs
    """
    cmd = "bf-p4c --arch tna -g --create-graphs --verbose 2" + \
          " -o build_out/ " + \
          " --p4runtime-files build_out/p4info.pb.txt --p4runtime-force-std-externs " + \
          "$<"

    # $BF_P4C --arch tna -g --create-graphs --verbose 2 \
    #       -o ${output_dir} -I ${P4_SRC_DIR} \
    #       ${OTHER_PP_FLAGS} \
    #       ${p4c_flags} \
    #       --p4runtime-files ${output_dir}/p4info.pb.txt \
    #       --p4runtime-force-std-externs \
    #       ${DIR}/stratum_tna.p4


    native.genrule(
        name = name,
        srcs = [src],
        outs = [
            "build_out/bfrt.json",
            "build_out/events.json",
            "build_out/manifest.json",
            "build_out/p4info.pb.txt",
            "build_out/source.json", 
            "build_out/stratum_tna.conf", 
            "build_out/stratum_tna.p4pp",
            "build_out/pipe/tofino.bin", 
            "build_out/pipe/context.json", 
            "build_out/pipe/stratum_tna.dynhash.json",
            "build_out/pipe/stratum_tna.bfa",
            "build_out/pipe/stratum_tna.prim.json"
        ],
        # tools = ["//stratum/hal/bin/barefoot:bf_pipeline_builder"],
        cmd = cmd,
    )
