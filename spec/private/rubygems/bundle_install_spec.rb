# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

module RulesRuby
  GEM_HOME = Tempfile.new("/tmp/bazel-dir.#{Process.pid}").path.freeze
  SPEC_HOME = Dir.pwd.freeze

  RSpec.describe BundleInstall do
    let(:gem_home) { ::RulesRuby::GEM_HOME }
    let(:pwd) { ::RulesRuby::SPEC_HOME }

    before(:all) do
      FileUtils.rm_rf(::RulesRuby::GEM_HOME )
      FileUtils.mkdir_p(::RulesRuby::GEM_HOME )
      Dir.chdir(::RulesRuby::GEM_HOME )
    end

    after(:all) do
      Dir.chdir(::RulesRuby::SPEC_HOME)
      # FileUtils.rm_rf(::RulesRuby::GEM_HOME )
    end

    let(:gemfile_lock) { File.expand_path('../Gemfile.lock', __FILE__) }
    let(:output_file) { '/tmp/BUILD.bazel' }
    let(:repo_name) { 'test' }
    let(:workspace_name) { 'test_bazel_workspace_name' }

    let(:attrs) { Attributes.new(gemfile_lock, workspace_name, repo_name, { parallel: ['app/**/*.rb'] }, output_file) }

    subject(:bundle_install) { described_class.new(attrs) }

    its(:ruby_major_version) { should eq RulesRuby.canonical_version(RUBY_VERSION) }

    its(:bundler_build_file) { should_not be_empty }

    context 'generating build file' do
      before { FileUtils.rm_f(output_file) }
      before { bundle_install.generate! }

      subject { output_file }

      it 'should be an existing file' do
        expect(File.exist?(output_file)).to be_truthy
      end
    end
  end
end
