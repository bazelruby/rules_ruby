# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../ruby/private/rubygems/gem_install'

RSpec.shared_examples 'gem installer' do |gem_tuple, gem_home = Dir.pwd, expected_authors = [], valid = true|
  subject(:gem_install) {
    RulesRuby::GemInstall.new(name: gem_tuple.name,
                              version: gem_tuple.version,
                              gem_home: gem_home,
                              debug: ENV['DEBUG'])
  }

  if valid
    context "Gem #{gem_tuple.name} version #{gem_tuple.version} should be valid" do
      let(:gem_name) { gem_tuple.name }
      let(:gem_version) { gem_tuple.version }

      its(:name) { is_expected.to eq gem_tuple.name }
      its(:version) { is_expected.to eq gem_tuple.version }
      its(:'rubygems_sources.first.uri') { is_expected.to eq URI('https://rubygems.org/') }

      describe 'gem specification' do
        # this performs an actual fetch of the specification
        subject(:gemspec) { gem_install.fetch_gemspec }

        its(:class) { should eq Gem::Specification }
        its(:spec_name) { should eq "#{gem_name}-#{gem_version}.gemspec" }

        its(:authors) { should match_array expected_authors }

        its(:spec_name) { is_expected.to eq gem_install.fetch_gemspec.spec_name }

        describe 'extract gem' do
          before { expect(gem_install.download_and_extract!).to be_truthy }

          subject(:gemspec_path) { File.expand_path('./', gem_install.gemspec_file) }

          it('should be an existing file') { expect(File.exist?(gemspec_path)).to be_truthy }

          it { is_expected.to end_with("#{gem_name}.gemspec") }

          it 'should have gem.require_paths()' do
            expect(gem_install.gemspec.require_paths).to_not be_empty
          end
        end
      end
    end
  else
    context "Attempting to download an invalid gem #{gem_tuple.name} version #{gem_tuple.version}" do
      it 'should raise GemNotFoundError' do
        expect { gem_install.download_and_extract! }.to raise_error(::RulesRuby::GemNotFoundError)
      end
    end
  end
end

module RulesRuby
  class << self
    attr_accessor :temp_dir
  end

  self.temp_dir = "/tmp/gem-home.#{Process.pid}"

  RSpec.describe GemInstall do
    before(:all) { FileUtils.rm_rf(RulesRuby.temp_dir) if Dir.exist?(RulesRuby.temp_dir) }

    context 'A valid an existing public gem' do
      it_should_behave_like 'gem installer',
                            ::Gem::NameTuple.new('sym', '2.8.0'),
                            RulesRuby.temp_dir,
                            ['Konstantin Gredeskoul'],
                            true
    end

    context 'An invalid or non-existent public gem' do
      it_should_behave_like 'gem installer',
                            ::Gem::NameTuple.new('XXXXXXXXXXXXXXX', '1100.3.4000'),
                            RulesRuby.temp_dir,
                            ['Konstantin Gredeskoul'],
                            false
    end
  end
end
