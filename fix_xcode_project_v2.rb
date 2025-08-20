#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }
raise "Target 'ClaudeCodeUI' not found" unless target

# Function to find group by path
def find_group_by_path(parent, path_components)
  return parent if path_components.empty?
  
  name = path_components.first
  remaining = path_components[1..-1]
  
  child = parent.children.find do |c| 
    c.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
    (c.name == name || c.path == name || (c.name.nil? && c.path.nil? && c.children.any? { |cc| cc.name == name }))
  end
  
  return nil unless child
  find_group_by_path(child, remaining)
end

# Find the main app group - usually the first non-Products group
main_app_group = project.main_group.children.find do |g| 
  g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name != 'Products'
end

# If still not found, use the first group
main_app_group ||= project.main_group.children.first

puts "Using main app group: #{main_app_group.name || main_app_group.path || 'unnamed'}"

# Try to find Features group
features_group = nil
main_app_group.children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
    if child.name == 'Features' || child.path == 'Features'
      features_group = child
      break
    end
  end
end

if features_group
  puts "Found Features group"
  
  # Add PlaceholderViewControllers.swift if it doesn't exist
  placeholder_file = features_group.files.find { |f| f.path == 'PlaceholderViewControllers.swift' }
  
  unless placeholder_file
    placeholder_file = features_group.new_file('PlaceholderViewControllers.swift')
    target.source_build_phase.add_file_reference(placeholder_file)
    puts "Added PlaceholderViewControllers.swift to project"
  else
    puts "PlaceholderViewControllers.swift already in project"
  end
else
  puts "Features group not found"
end

# Try to find Core/Navigation group
core_group = nil
main_app_group.children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
    if child.name == 'Core' || child.path == 'Core'
      core_group = child
      break
    end
  end
end

if core_group
  puts "Found Core group"
  
  navigation_group = nil
  core_group.children.each do |child|
    if child.is_a?(Xcodeproj::Project::Object::PBXGroup)
      if child.name == 'Navigation' || child.path == 'Navigation'
        navigation_group = child
        break
      end
    end
  end
  
  if navigation_group
    puts "Found Navigation group"
    
    # Check if MainTabBarController.swift is in the project
    main_tab_bar = navigation_group.files.find { |f| f.path == 'MainTabBarController.swift' }
    
    unless main_tab_bar
      main_tab_bar = navigation_group.new_file('MainTabBarController.swift')
      target.source_build_phase.add_file_reference(main_tab_bar)
      puts "Added MainTabBarController.swift to project"
    else
      puts "MainTabBarController.swift already in project"
    end
  else
    puts "Navigation group not found"
  end
else
  puts "Core group not found"
end

# Save the project
project.save
puts "Project saved successfully!"