#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

if target.nil?
  puts "Error: Could not find target 'ClaudeCodeUI'"
  exit 1
end

# Find or create the Core/Security group
main_group = project.main_group
core_group = main_group['Core'] || main_group.new_group('Core')
security_group = core_group['Security'] || core_group.new_group('Security')

# Add KeychainManager.swift file with correct path
file_name = 'KeychainManager.swift'
file_ref = security_group.find_file_by_path(file_name)

if file_ref.nil?
  file_ref = security_group.new_file(file_name)
  puts "Added file reference for KeychainManager.swift"
else
  puts "File reference for KeychainManager.swift already exists"
end

# Add to build phase
build_phase = target.source_build_phase
existing_file = build_phase.files.find { |f| f.file_ref && f.file_ref.path == 'KeychainManager.swift' }

if existing_file.nil?
  build_phase.add_file_reference(file_ref)
  puts "Added KeychainManager.swift to build phase"
else
  puts "KeychainManager.swift already in build phase"
end

# Save the project
project.save
puts "Project saved successfully!"