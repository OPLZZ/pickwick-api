require "bundler/gem_tasks"

task default: 'test'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = FileList['test/unit/**/*_test.rb', 'test/integration/**/*_test.rb']
  test.verbose = true
end

desc 'Create elasticsearch indices; Use FORCE=true environment variable to recreate indices (all data will be removed).'
task :setup do
  require_relative 'lib/pickwick-api'

  begin

    if ENV["FORCE"]
      puts "[!] Deleting indices..."
      Pickwick::API::Models::Consumer.__elasticsearch__.delete_index!
      Pickwick::API::Models::Vacancy.__elasticsearch__.delete_index!
    end

    puts "[*] Creating indices..."

    Pickwick::API::Models::Consumer.__elasticsearch__.create_index!
    Pickwick::API::Models::Vacancy.__elasticsearch__.create_index!

    if ENV["CONSUMER_TOKEN"] && Pickwick::API::Models::Consumer.find_by_token(ENV["CONSUMER_TOKEN"]).nil?
      puts "[*] Creating default API consumer with token: `#{ENV["CONSUMER_TOKEN"]}`..."

      Pickwick::API::Models::Consumer.create name:        "Pickwick API Workers",
                                             description: "Official API consumer for feeders and enrichment workers",
                                             token:       ENV["CONSUMER_TOKEN"],
                                             permission:  { search: true, store: true }
    end

    puts "[*] DONE"
  rescue Exception => e
    puts "[!] Setup FAILED: #{e.message}\n\n#{e.backtrace.join("\n")}"
  end
end

namespace :test do
  Rake::TestTask.new(:units) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList["test/unit/**/*_test.rb"]
    test.verbose = true
  end
  Rake::TestTask.new(:integrations) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList["test/integration/**/*_test.rb"]
    test.verbose = true
  end
end
