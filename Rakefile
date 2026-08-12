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

desc 'Write the word list, the leet table and the limits into the JavaScript port'
task :javascript do
  $LOAD_PATH.unshift(File.expand_path('lib', __dir__))
  require 'password_strength'
  require 'password_strength/javascript_source'

  PasswordStrength::JavascriptSource.write
  puts "Wrote #{PasswordStrength::JavascriptSource::PATH}"
end

task default: %i[test test_js rubocop]
