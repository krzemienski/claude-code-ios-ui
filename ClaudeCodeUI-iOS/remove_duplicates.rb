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

# Track files by their base name to find duplicates
file_map = {}
duplicates_to_remove = []

target.source_build_phase.files.each do |build_file|
  if build_file.file_ref
    path = build_file.file_ref.real_path.to_s rescue build_file.file_ref.path
    basename = File.basename(path)
    
    # Skip test files and files in Sources directory (prefer Core directory)
    if path.include?('/Sources/') || 
       path.include?('/Tests/') || 
       path.include?('UITests/') || 
       path.include?('IntegrationTests/')
      puts "Removing duplicate/test file: #{path}"
      duplicates_to_remove << build_file
    elsif file_map[basename]
      # We have a duplicate - keep the one not in Sources
      existing_path = file_map[basename][:path]
      if existing_path.include?('/Sources/')
        # Remove the existing one, keep the new one
        duplicates_to_remove << file_map[basename][:build_file]
        file_map[basename] = { build_file: build_file, path: path }
        puts "Removing duplicate (preferring non-Sources): #{existing_path}"
      else
        # Remove the new one
        duplicates_to_remove << build_file
        puts "Removing duplicate: #{path}"
      end
    else
      file_map[basename] = { build_file: build_file, path: path }
    end
  end
end

# Remove all duplicates and test files
puts "\nRemoving #{duplicates_to_remove.count} duplicate/test files..."
duplicates_to_remove.each { |f| target.source_build_phase.remove_build_file(f) }

puts "Build files after removal: #{target.source_build_phase.files.count}"

# Save the project
project.save

puts "\nDuplicates removed successfully!"
puts "Now try building again."