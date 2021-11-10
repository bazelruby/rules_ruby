# Changelog

## [v0.6.0](https://github.com/bazelruby/rules_ruby/tree/v0.6.0) (2021-11-09)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.5.2...v0.6.0)

**Merged pull requests:**

- Bump nokogiri from 1.11.7 to 1.12.5 in /examples/simple\_rails\_api [\#120](https://github.com/bazelruby/rules_ruby/pull/120) ([dependabot[bot]](https://github.com/apps/dependabot))
- Upstream changes from Selenium's fork [\#118](https://github.com/bazelruby/rules_ruby/pull/118) ([p0deje](https://github.com/p0deje))
- Bump puma from 4.3.8 to 4.3.9 in /examples/simple\_rails\_api [\#117](https://github.com/bazelruby/rules_ruby/pull/117) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump nokogiri from 1.11.7 to 1.12.5 in /examples/simple\_rails\_api [\#116](https://github.com/bazelruby/rules_ruby/pull/116) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump Ruby primary to 3.0.2 & Add sdk versions: 2.5.9, 2.6.8, 2.7.3, 2.7.4, 3.0.2 [\#114](https://github.com/bazelruby/rules_ruby/pull/114) ([kigster](https://github.com/kigster))

## [v0.5.2](https://github.com/bazelruby/rules_ruby/tree/v0.5.2) (2021-07-09)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.5.1...v0.5.2)

**Closed issues:**

- require\_paths attribute does not work [\#97](https://github.com/bazelruby/rules_ruby/issues/97)
- google-protobuf and grpc gems fail [\#86](https://github.com/bazelruby/rules_ruby/issues/86)
- Ruby Gem isn't including generated files [\#85](https://github.com/bazelruby/rules_ruby/issues/85)

**Merged pull requests:**

- Add `includes` option to `ruby_bundle` rule for per-gem load path customization [\#102](https://github.com/bazelruby/rules_ruby/pull/102) ([mmizutani](https://github.com/mmizutani))

## [v0.5.1](https://github.com/bazelruby/rules_ruby/tree/v0.5.1) (2021-07-08)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.5.0...v0.5.1)

**Closed issues:**

- `ruby_bundle` should support local gems [\#62](https://github.com/bazelruby/rules_ruby/issues/62)

**Merged pull requests:**

- feat: Support mapping the vendor cache from workspace [\#92](https://github.com/bazelruby/rules_ruby/pull/92) ([russell](https://github.com/russell))

## [v0.5.0](https://github.com/bazelruby/rules_ruby/tree/v0.5.0) (2021-07-08)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.4.1...v0.5.0)

**Closed issues:**

- ruby\_binary - how to package up runfiles dir [\#101](https://github.com/bazelruby/rules_ruby/issues/101)
- bin/setup Failure [\#95](https://github.com/bazelruby/rules_ruby/issues/95)
- `warning: string literal in condition` from generated wrapper [\#87](https://github.com/bazelruby/rules_ruby/issues/87)
- Setup script attempts to delete ~/.rbenv if rbenv is installed with Homebrew [\#81](https://github.com/bazelruby/rules_ruby/issues/81)
- ruby\_rspec specs argument not resolved [\#79](https://github.com/bazelruby/rules_ruby/issues/79)
- ruby\_test and ruby\_rspec rules use system ruby [\#63](https://github.com/bazelruby/rules_ruby/issues/63)

**Merged pull requests:**

- Adding  makefile for auto-generating PDF [\#106](https://github.com/bazelruby/rules_ruby/pull/106) ([kigster](https://github.com/kigster))
- Massive upgrade of everything at once ;-\) [\#105](https://github.com/bazelruby/rules_ruby/pull/105) ([kigster](https://github.com/kigster))
- Support ruby 3 [\#103](https://github.com/bazelruby/rules_ruby/pull/103) ([mmizutani](https://github.com/mmizutani))
- Bump nokogiri from 1.11.2 to 1.11.5 in /examples/simple\_rails\_api [\#99](https://github.com/bazelruby/rules_ruby/pull/99) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump nokogiri from 1.10.10 to 1.11.2 in /examples/simple\_rails\_api [\#94](https://github.com/bazelruby/rules_ruby/pull/94) ([dependabot[bot]](https://github.com/apps/dependabot))
- Update README.md [\#93](https://github.com/bazelruby/rules_ruby/pull/93) ([JustusFT](https://github.com/JustusFT))
- Fix warning due to string literal in condition [\#91](https://github.com/bazelruby/rules_ruby/pull/91) ([russell](https://github.com/russell))
- Add description for how to configure ASDF [\#90](https://github.com/bazelruby/rules_ruby/pull/90) ([russell](https://github.com/russell))
- Remove print statements from ruby\_runtime.bzl [\#84](https://github.com/bazelruby/rules_ruby/pull/84) ([adzenith](https://github.com/adzenith))
- Document path argument to ruby\_test [\#80](https://github.com/bazelruby/rules_ruby/pull/80) ([sayrer](https://github.com/sayrer))

## [v0.4.1](https://github.com/bazelruby/rules_ruby/tree/v0.4.1) (2020-08-10)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.4.0...v0.4.1)

## [v0.4.0](https://github.com/bazelruby/rules_ruby/tree/v0.4.0) (2020-08-04)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.3.0...v0.4.0)

**Closed issues:**

- private method `define\_method' called for Dir:Class \(NoMethodError\) [\#74](https://github.com/bazelruby/rules_ruby/issues/74)

**Merged pull requests:**

- Version vandidate 0.4.0 — upgrade Rubies + Setup [\#77](https://github.com/bazelruby/rules_ruby/pull/77) ([kigster](https://github.com/kigster))
- Upgrading Gemfiles [\#76](https://github.com/bazelruby/rules_ruby/pull/76) ([kigster](https://github.com/kigster))
- Ruby 2.3 compatibility for binary\_wrapper [\#75](https://github.com/bazelruby/rules_ruby/pull/75) ([lalten](https://github.com/lalten))
- Bump puma from 4.3.3 to 4.3.5 in /examples/simple\_rails\_api [\#71](https://github.com/bazelruby/rules_ruby/pull/71) ([dependabot[bot]](https://github.com/apps/dependabot))
- Bump puma from 4.3.1 to 4.3.3 in /examples/simple\_rails\_api [\#70](https://github.com/bazelruby/rules_ruby/pull/70) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v0.3.0](https://github.com/bazelruby/rules_ruby/tree/v0.3.0) (2020-03-03)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.2.0...v0.3.0)

**Closed issues:**

- 🐛 "Could not create symlink... \(File exists\)"  [\#54](https://github.com/bazelruby/rules_ruby/issues/54)
- When using a local ruby installation it includes the local `LOAD_PATH` [\#44](https://github.com/bazelruby/rules_ruby/issues/44)
- \[Cleanup\] Pretty sure `eval` is never used in `repository_context` [\#43](https://github.com/bazelruby/rules_ruby/issues/43)
- Importing a bundle gem adds all gems onto the load path \(although they are not there\) [\#42](https://github.com/bazelruby/rules_ruby/issues/42)
- Support Ruby Lambda with the Gemfile full of dependencies. [\#33](https://github.com/bazelruby/rules_ruby/issues/33)
- Support AWS Ruby Lambda with Bazel Rules [\#27](https://github.com/bazelruby/rules_ruby/issues/27)
- Want to understand better why native extensions are failing on CircleCI [\#24](https://github.com/bazelruby/rules_ruby/issues/24)
- First class support for Ruby RSpec gem with Bazel [\#19](https://github.com/bazelruby/rules_ruby/issues/19)
- Use sorbets Ruby 2.6 build instead of host [\#9](https://github.com/bazelruby/rules_ruby/issues/9)

**Merged pull requests:**

- Renaming the repo to @bazelruby\_rules\_ruby [\#69](https://github.com/bazelruby/rules_ruby/pull/69) ([kigster](https://github.com/kigster))
- Fixing outdated rule names in the README [\#68](https://github.com/bazelruby/rules_ruby/pull/68) ([kigster](https://github.com/kigster))
- Adding method Dir.children when it's not found. [\#67](https://github.com/bazelruby/rules_ruby/pull/67) ([kigster](https://github.com/kigster))
- Merging select features from Coinbase upstream branch [\#66](https://github.com/bazelruby/rules_ruby/pull/66) ([kigster](https://github.com/kigster))
- Upgrade Bazel and Bazelist; add ruby 2.7.0 [\#65](https://github.com/bazelruby/rules_ruby/pull/65) ([kigster](https://github.com/kigster))
- Bump nokogiri from 1.10.7 to 1.10.8 in /examples/simple\_rails\_api [\#64](https://github.com/bazelruby/rules_ruby/pull/64) ([dependabot[bot]](https://github.com/apps/dependabot))
- This PR refactors bundle steps and :bin generation [\#61](https://github.com/bazelruby/rules_ruby/pull/61) ([kigster](https://github.com/kigster))
- Adds ruby\_rspec and refactors the ruby\_bundle rule, plus some more [\#60](https://github.com/bazelruby/rules_ruby/pull/60) ([kigster](https://github.com/kigster))

## [v0.2.0](https://github.com/bazelruby/rules_ruby/tree/v0.2.0) (2019-12-31)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/v0.1.0...v0.2.0)

**Fixed bugs:**

- Make `rules_ruby/examples` a deeper tree structure and ensure CircleCI integration pass [\#10](https://github.com/bazelruby/rules_ruby/issues/10)

**Closed issues:**

- Ability to package all files related to a bazel target in a zip file [\#29](https://github.com/bazelruby/rules_ruby/issues/29)
- Build rules\_ruby on CircleCI using workflows \(in addition to Travis\) [\#26](https://github.com/bazelruby/rules_ruby/issues/26)
- Restore functionality that supported symlinking an existing Ruby interpreter [\#21](https://github.com/bazelruby/rules_ruby/issues/21)
- Move ruby files under ruby\_rules/examples into a mini-mono repo [\#8](https://github.com/bazelruby/rules_ruby/issues/8)

**Merged pull requests:**

- Fixing brittle Host Ruby version detection. [\#56](https://github.com/bazelruby/rules_ruby/pull/56) ([kigster](https://github.com/kigster))
- Upgrading Bazel version to 2.0.0 [\#53](https://github.com/bazelruby/rules_ruby/pull/53) ([kigster](https://github.com/kigster))
- Renaming and making consistent all scripts [\#52](https://github.com/bazelruby/rules_ruby/pull/52) ([kigster](https://github.com/kigster))
- Adding auto-fix buildifier and auto-fix rubocop [\#50](https://github.com/bazelruby/rules_ruby/pull/50) ([kigster](https://github.com/kigster))
- Bump rack from 2.0.7 to 2.0.8 in /examples/simple\_rails\_api [\#49](https://github.com/bazelruby/rules_ruby/pull/49) ([dependabot[bot]](https://github.com/apps/dependabot))
- Deprecate ruby/def.bzl + spelling + v0.1.2 [\#48](https://github.com/bazelruby/rules_ruby/pull/48) ([kigster](https://github.com/kigster))
- Speed up CircleCI/Travis ensure \*correctness\* with builds [\#46](https://github.com/bazelruby/rules_ruby/pull/46) ([kigster](https://github.com/kigster))
- \[Feature\] example rails server running [\#41](https://github.com/bazelruby/rules_ruby/pull/41) ([grahamjenson](https://github.com/grahamjenson))
- \[Fix\] rubocop builds [\#40](https://github.com/bazelruby/rules_ruby/pull/40) ([grahamjenson](https://github.com/grahamjenson))
- Adding CircleCI + upgrade Rubocop [\#39](https://github.com/bazelruby/rules_ruby/pull/39) ([kigster](https://github.com/kigster))
- \[Fix\] no spaces in files bug, remove deprecated code, remove host [\#38](https://github.com/bazelruby/rules_ruby/pull/38) ([grahamjenson](https://github.com/grahamjenson))
- Sight facelift to shell files: [\#35](https://github.com/bazelruby/rules_ruby/pull/35) ([kigster](https://github.com/kigster))
- \[Feature\] install ruby if none exists [\#34](https://github.com/bazelruby/rules_ruby/pull/34) ([grahamjenson](https://github.com/grahamjenson))
- Add `files` to DefaultInfo of the ruby\_library [\#32](https://github.com/bazelruby/rules_ruby/pull/32) ([kigster](https://github.com/kigster))
- Upgrade Bazel version to 1.2.1 + use bin/setup\(s\) [\#31](https://github.com/bazelruby/rules_ruby/pull/31) ([kigster](https://github.com/kigster))
- Fixing Gemfile bundle dependency and bin/setup [\#30](https://github.com/bazelruby/rules_ruby/pull/30) ([kigster](https://github.com/kigster))
- Expose rake, erb and other commands as sh\_binary [\#28](https://github.com/bazelruby/rules_ruby/pull/28) ([yugui](https://github.com/yugui))
- Reorganize sections in README [\#23](https://github.com/bazelruby/rules_ruby/pull/23) ([yugui](https://github.com/yugui))
- Run ruby\_binary with the interpreter in a SDK again [\#22](https://github.com/bazelruby/rules_ruby/pull/22) ([yugui](https://github.com/yugui))
- Upgrade bundler [\#18](https://github.com/bazelruby/rules_ruby/pull/18) ([yugui](https://github.com/yugui))
- Make ruby\_binary compatible with container [\#17](https://github.com/bazelruby/rules_ruby/pull/17) ([yugui](https://github.com/yugui))
- Fix errors in the simple\_script example [\#16](https://github.com/bazelruby/rules_ruby/pull/16) ([yugui](https://github.com/yugui))
- Adding relaxed-rubocop and fixing styling issues [\#15](https://github.com/bazelruby/rules_ruby/pull/15) ([grahamjenson](https://github.com/grahamjenson))

## [v0.1.0](https://github.com/bazelruby/rules_ruby/tree/v0.1.0) (2019-11-20)

[Full Changelog](https://github.com/bazelruby/rules_ruby/compare/59deebc086f9c64a4626e2c98d7aa9c746d0d382...v0.1.0)

**Fixed bugs:**

- Unable to run `bazel build //...:all` [\#3](https://github.com/bazelruby/rules_ruby/issues/3)

**Merged pull requests:**

- Ignore examples/ because it is an independent workspace to test rules\_ruby [\#5](https://github.com/bazelruby/rules_ruby/pull/5) ([yugui](https://github.com/yugui))
- Updating the remote reference to match the Org [\#4](https://github.com/bazelruby/rules_ruby/pull/4) ([kigster](https://github.com/kigster))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
