# example/transitions/transitions.bzl
def _platform_transition_impl(settings, attr):
    #                                     see build_for rule vvvvvvvvv
    return {"//command_line_option:platforms" : str(attr.build_for)}

platform_transition = transition(
    implementation = _platform_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:platforms"]
)

def _build_for_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name)
    ctx.actions.symlink(output=out, target_file=ctx.executable.multiarch_target)
    # You may want to do more sophisticated provider handling. This doesn't
    # currently support runfiles etc.
    return [DefaultInfo(
        files=depset([out]), 
        executable=out)]

build_for = rule(
    _build_for_impl,
    attrs = {
        "multiarch_target": attr.label(
            cfg=platform_transition, 
            executable=True
        ),
        # You may want to do more sophisticated provider handling.
        "build_for": attr.label(),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
        ),
    }
)


def embedded_cc_binary(**kwargs):
    build_for_platform = kwargs.pop("build_for","@bazel_tools//platforms:target_platform")
    name = kwargs.pop("name")
    name_multiarch = name +".multiarch"
    native.cc_binary(
        name = name_multiarch,
        **kwargs,
    )
    build_for(
        name = name,
        multiarch_target = name_multiarch,
        build_for = build_for_platform,
    )