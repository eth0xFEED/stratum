# Copyright 2018-present Open Networking Foundation
# SPDX-License-Identifier: Apache-2.0

licenses(["notice"])  # Apache v2


package(
    default_visibility = [ "//visibility:public" ],
)

load(
    "@com_github_stratum_stratum//bazel/rules:proto_rule.bzl",
    "wrapped_proto_library",
)

PREFIX = "github.com/openconfig/ygot/proto/"

wrapped_proto_library(
    name = "ywrapper_proto",
    srcs = ["proto/ywrapper/ywrapper.proto"],
    new_proto_dir = PREFIX,
    proto_source_root = "proto/",
)

wrapped_proto_library(
    name = "yext_proto",
    srcs = ["proto/yext/yext.proto"],
    deps = ["@com_google_protobuf//:descriptor_proto"],
    new_proto_dir = PREFIX,
    proto_source_root = "proto/",
)

cc_proto_library(
    name = "ywrapper_cc_proto",
    deps = [":ywrapper_proto"]
)

cc_proto_library(
    name = "yext_cc_proto",
    deps = [":yext_proto"]
)

# load("@rules_proto//proto:defs.bzl", "proto_library")
# load("@io_bazel_rules_go//proto:def.bzl", "go_proto_library")
# go_proto_library(
#     name = "ywrapper_go_proto",
#     protos = [":ywrapper_proto"]
# )

# go_proto_library(
#     name = "yext_go_proto",
#     protos = [":yext_proto"]
# )
