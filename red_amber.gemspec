# frozen_string_literal: true

require_relative 'lib/red_amber/version'

Gem::Specification.new do |spec|
  spec.name = 'red_amber'
  spec.version = RedAmber::VERSION
  spec.authors = ['Hirokazu SUZUKI (heronshoes)']
  spec.email = ['63298319+heronshoes@users.noreply.github.com']

  spec.summary = 'Simple data frames for Ruby'
  spec.description = 'Powered by Red Arrow and Rover-df like API'
  spec.homepage = 'https://github.com/heronshoes/red_amber'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7'

  spec.metadata['allowed_push_host'] = "Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/heronshoes/red_amber'
  spec.metadata['changelog_uri'] = 'https://github.com/heronshoes/red_amber/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) ||
        f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'red-arrow', '~> 7.0.0'
  spec.add_dependency 'red-parquet', '~> 7.0.0'
  spec.add_dependency 'rover-df', '~> 0.3.0'

  # Development dependency has gone to the Gemfile (rubygems/bundler#7237)

  spec.metadata['rubygems_mfa_required'] = 'true'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
