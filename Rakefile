# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rake/clean'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
  t.warning = false
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[test rubocop]

def install_gems_for_examples
  sh 'cd bin; bundle install; cd -'
end

# Example
desc 'Start example environment'
task :example do
  install_gems_for_examples
  sh 'bundle exec --gemfile=bin/Gemfile bin/example'
end

# Quarto
namespace :quarto do
  qmd_dir = 'doc/qmd'
  notebook_dir = 'doc/notebook'

  directory notebook_dir

  qmd_files = FileList["#{qmd_dir}/*.qmd"]
  qmd_files.exclude('~*.qmd')
  notebooks = qmd_files.pathmap('%{qmd,notebook}p').ext('.ipynb')

  qmd_files.zip(notebooks).each do |qmd, notebook|
    file notebook => notebook_dir
    file notebook => qmd do
      sh "quarto convert #{qmd} -o #{notebook}"
    end
  end

  desc 'Convert qmd to ipynb files'
  task convert: notebooks
  file notebooks => notebook_dir

  desc 'test to execute notebooks'
  task test: notebooks do
    install_gems_for_examples
    notebooks.each do |notebook|
      quarto_options = '--execute-daemon-restart --execute'
      sh "bundle exec --gemfile=bin/Gemfile quarto render #{notebook} #{quarto_options}"
    end
  end
end

desc 'Start jupyter lab'
task jupyter: 'quarto:convert' do
  install_gems_for_examples

  jupyter_options =
    "--notebook-dir='doc/notebook' --NotebookApp.token=''"
  sh "bundle exec --gemfile=bin/Gemfile jupyter lab #{jupyter_options}"
end

CLEAN << 'doc/notebook'
