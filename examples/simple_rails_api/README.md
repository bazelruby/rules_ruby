# Rails API App

This example is meant to be an example of how to structure a rails application in a `bazel`-ish way.

## Run the Example

To start the application run:

```
bazel run :server -- server
```

then call the `home_controller.rb#home` method with:

```
curl 127.0.0.1:3000
```

## Creating the examples
This application was created by running `rails new simple_rails_api --api`, adding the `BUILD` and `WORKSPACE` files, then executing the changes below.

### Deleting folders

This is a simple example app so we deleted a lot of the folders, e.g. `vendor` `public` `test` `tmp` `db` `lib` `log` folders.

### Bundler

Since we are importing the rails application, we do not want to run `bundler/setup` as this looks at the Gemfile provided. This means that any gem setup will have to be manual.

### Rails.root APP_PATH

Because the directory the application being started is in the bazel-bin folder (not the source directory) we need to change some config.

In `bin/rails` set:

```
APP_PATH = Dir.pwd + '/config/application'
```

and in `config/application.rb` add:

```
config.root = Dir.pwd
```

### Add simple home controller

Added a simple home controller to make sure everything was working correctly

