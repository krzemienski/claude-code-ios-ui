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
  g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name == 'App'
end

puts "Using main app group: #{main_app_group.name || main_app_group.path || 'unnamed'}"

# Find or create Features group
features_group = main_app_group.children.find do |child|
  child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
  (child.name == 'Features' || child.path == 'Features')
end

if features_group.nil?
  # Create Features group
  features_group = main_app_group.new_group('Features', 'Features')
  puts "Created Features group"
else
  puts "Found existing Features group"
end

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

# Also ensure MainTabBarController is in the project
core_group = main_app_group.children.find do |child|
  child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
  (child.name == 'Core' || child.path == 'Core')
end

if core_group
  navigation_group = core_group.children.find do |child|
    child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
    (child.name == 'Navigation' || child.path == 'Navigation')
  end
  
  if navigation_group
    # Check if MainTabBarController.swift exists
    main_tab_file = navigation_group.files.find { |f| f.path == 'MainTabBarController.swift' }
    
    unless main_tab_file
      main_tab_file = navigation_group.new_file('MainTabBarController.swift')
      target.source_build_phase.add_file_reference(main_tab_file)
      puts "Added MainTabBarController.swift to project"
    else
      puts "MainTabBarController.swift already in project"
    end
  end
end

# Save the project
project.save
puts "Project saved successfully!"