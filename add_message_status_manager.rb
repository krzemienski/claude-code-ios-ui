#!/usr/bin/env ruby

require 'xcodeproj'
require 'securerandom'

# Open the project
project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }
unless target
  puts "Target 'ClaudeCodeUI' not found"
  exit 1
end

# Find the Chat group
main_group = project.main_group
features_group = main_group.find_subpath('Features', true)
chat_group = features_group.find_subpath('Chat', true)

unless chat_group
  puts "Chat group not found"
  exit 1
end

# Path to the file
file_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Features/Chat/MessageStatusManager.swift'

# Check if file already exists in project
existing_file = chat_group.files.find { |f| f.path == 'MessageStatusManager.swift' }
if existing_file
  puts "MessageStatusManager.swift already exists in project"
else
  # Add the file reference to the Chat group
  file_ref = chat_group.new_reference(file_path)
  file_ref.name = 'MessageStatusManager.swift'
  
  # Add the file to the target's compile sources build phase
  target.source_build_phase.add_file_reference(file_ref)
  
  puts "Added MessageStatusManager.swift to project"
end

# Save the project
project.save

puts "Project saved successfully"