# frozen_string_literal: true

require_relative 'lib/red_amber/version'

Gem::Specification.new do |spec|
  spec.name = 'red_amber'
  spec.version = RedAmber::VERSION
  spec.authors = ['Hirokazu SUZUKI (heronshoes)']
  spec.email = ['heronshoes877@gmail.com']

  spec.summary = 'A data frame library for Rubyists'
  spec.description = 'RedAmber is a data frame library ' \
                     'inspired by Rover-df and powered by Red Arrow.'
  spec.homepage = 'https://github.com/red-data-tools/red_amber'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/red-data-tools/red_amber'
  spec.metadata['changelog_uri'] = 'https://github.com/red-data-tools/red_amber/blob/main/CHANGELOG.md'

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

  spec.add_dependency 'red-arrow', '>= 12.0.0'

  # Development dependency has gone to the Gemfile (rubygems/bundler#7237)

  spec.metadata['rubygems_mfa_required'] = 'true'
end
