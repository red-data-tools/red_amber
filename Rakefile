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
    notebooks.each do |notebook|
      quarto_options = '--execute-daemon-restart --execute'
      sh "bundle exec --gemfile=bin/Gemfile quarto render #{notebook} #{quarto_options}"
    end
  end
end

desc 'Start jupyter lab'
task jupyter: 'quarto:convert' do
  jupyter_options =
    "--notebook-dir='/workspaces/red_amber/doc/notebook' --NotebookApp.token=''"
  sh "bundle exec --gemfile=bin/Gemfile jupyter lab #{jupyter_options}"
end

CLEAN << 'doc/notebook'
