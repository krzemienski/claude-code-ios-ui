#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }
raise "Target 'ClaudeCodeUI' not found" unless target

# Find the main app group
main_app_group = project.main_group.children.find do |g| 
  g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name != 'Products'
end

puts "Using main app group: #{main_app_group.name || main_app_group.path || 'unnamed'}"

# Find Features group
features_group = main_app_group.children.find do |child|
  child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
  (child.name == 'Features' || child.path == 'Features')
end

if features_group
  puts "Found Features group"
  
  # Check if PlaceholderViewControllers.swift already exists
  placeholder_file = features_group.files.find { |f| f.path == 'PlaceholderViewControllers.swift' }
  
  unless placeholder_file
    # Add PlaceholderViewControllers.swift to Features group
    placeholder_file = features_group.new_file('PlaceholderViewControllers.swift')
    target.source_build_phase.add_file_reference(placeholder_file)
    puts "Added PlaceholderViewControllers.swift to project"
  else
    puts "PlaceholderViewControllers.swift already in project"
  end
else
  puts "ERROR: Features group not found!"
end

# Save the project
project.save
puts "Project saved successfully!"