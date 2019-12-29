def _ruby_package_zip_impl(ctx):
    out_file = ctx.actions.declare_file("%s.zip" % ctx.attr.name)

    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [out_file],
        progress_message = "Generating bundle for %s" % (out_file.path),
        command = "PATH=/usr/local/bin:/usr/bin:/bin:/sbin:/usr/sbin:${PATH} bundle install --path vendor/bundle; zip -rv %s vendor/bundle $@" % (out_file.path),
        arguments = [s.path for s in ctx.files.srcs],
    )

    return [DefaultInfo(files = depset([out_file]))]

ruby_package_zip = rule(
    implementation = _ruby_package_zip_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
    },
)
