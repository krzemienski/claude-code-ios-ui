#!/usr/bin/env ruby
require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
main_target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

# Get the UI/Components group
ui_group = project.main_group.find_subpath('UI/Components', true)

if ui_group.nil?
  puts "❌ Could not find UI/Components group"
  exit 1
end

# Files to add
files_to_add = [
  'NoDataView.swift'
]

files_to_add.each do |filename|
  file_path = "UI/Components/#{filename}"
  full_path = "ClaudeCodeUI-iOS/#{file_path}"
  
  # Check if file exists in filesystem
  unless File.exist?(full_path)
    puts "⚠️ File does not exist: #{full_path}"
    next
  end
  
  # Check if already in project
  existing_ref = ui_group.files.find { |f| f.path == filename }
  if existing_ref
    puts "✓ #{filename} already in project"
    next
  end
  
  # Add file reference to the project
  file_ref = ui_group.new_reference(filename)
  
  # Add to build phase
  main_target.add_file_references([file_ref])
  
  puts "✅ Added #{filename} to project and build phase"
end

# Save the project
project.save

puts "✅ Project file updated successfully"