#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

if target.nil?
  puts "Error: Could not find target 'ClaudeCodeUI'"
  exit 1
end

puts "Found target: #{target.name}"
puts "Current build files count: #{target.source_build_phase.files.count}"

# Remove StarscreamWebSocketManager and test files
files_to_remove = []
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref
    path = build_file.file_ref.real_path.to_s rescue build_file.file_ref.path
    if path.include?('StarscreamWebSocketManager.swift') ||
       path.include?('StarscreamWebSocketTests.swift') ||
       path.include?('AliveMainFlowUITests.swift') ||
       path.include?('MajorFlowsUITests.swift')
      puts "Removing: #{path}"
      files_to_remove << build_file
    end
  end
end

files_to_remove.each { |f| target.source_build_phase.remove_build_file(f) }

puts "\nRemoved #{files_to_remove.count} files"
puts "Build files after removal: #{target.source_build_phase.files.count}"

# Save the project
project.save

puts "\nProject fixed! Now building should work."