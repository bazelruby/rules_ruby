_DEFAULT_VERSION = "2.0.2"

def install_bundler(ctx, interpreter, install_bundler, dest, version = _DEFAULT_VERSION):
    args = ["env", "-i", interpreter, install_bundler, version, dest]
    environment = {"RUBYOPT": "--disable-gems"}

    result = ctx.execute(args, environment = environment)
    if result.return_code:
        message = "Failed to evaluate ruby snippet with {}: {}".format(
            interpreter,
            result.stderr,
        )
        fail(message)
