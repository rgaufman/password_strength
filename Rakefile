# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs += %w[test lib]
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

desc 'Run the JavaScript tests through the Node test runner'
task :test_js do
  sh 'node --test "test/js/*.test.mjs"'
end

task default: %i[test test_js rubocop]
