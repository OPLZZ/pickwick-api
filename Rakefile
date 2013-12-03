require "bundler/gem_tasks"

task default: 'test'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = FileList['test/unit/**/*_test.rb', 'test/functional/**/*_test.rb']
  test.verbose = true
end

namespace :test do
  Rake::TestTask.new(:units) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList["test/unit/**/*_test.rb"]
    test.verbose = true
  end
  Rake::TestTask.new(:functionals) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList["test/functional/**/*_test.rb"]
    test.verbose = true
  end
end
