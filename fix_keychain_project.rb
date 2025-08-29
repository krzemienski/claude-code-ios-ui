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

# Remove any incorrect KeychainManager references
build_phase = target.source_build_phase
build_phase.files.select { |f| 
  f.file_ref && f.file_ref.path && f.file_ref.path.include?('KeychainManager.swift')
}.each do |file|
  puts "Removing incorrect reference: #{file.file_ref.path}"
  build_phase.remove_file_reference(file.file_ref)
end

# Find Core/Security group
main_group = project.main_group
core_group = main_group['Core']
security_group = core_group['Security'] if core_group

if security_group
  # Remove any existing KeychainManager file references
  security_group.files.select { |f| f.path && f.path.include?('KeychainManager.swift') }.each do |file|
    puts "Removing file reference: #{file.path}"
    file.remove_from_project
  end
  
  # Add the correct file reference
  file_ref = security_group.new_reference('KeychainManager.swift')
  puts "Added correct file reference for KeychainManager.swift"
  
  # Add to build phase
  build_phase.add_file_reference(file_ref)
  puts "Added KeychainManager.swift to build phase"
end

# Save the project
project.save
puts "Project saved successfully!"