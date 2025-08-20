#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }
raise "Target 'ClaudeCodeUI' not found" unless target

# Debug: Print main group structure
puts "Main group children:"
project.main_group.children.each do |child|
  puts "  - #{child.name} (#{child.class})"
end

# Find the ClaudeCodeUI group (usually the first group)
main_app_group = project.main_group.children.find { |g| g.name == 'ClaudeCodeUI' && g.is_a?(Xcodeproj::Project::Object::PBXGroup) }
raise "Main app group not found" unless main_app_group

# Find the Features group
features_group = main_app_group.children.find { |g| g.name == 'Features' && g.is_a?(Xcodeproj::Project::Object::PBXGroup) }
raise "Features group not found" unless features_group

# Add PlaceholderViewControllers.swift if it doesn't exist
placeholder_path = 'ClaudeCodeUI-iOS/Features/PlaceholderViewControllers.swift'
file_ref = features_group.files.find { |f| f.path == 'PlaceholderViewControllers.swift' }

unless file_ref
  file_ref = features_group.new_file('PlaceholderViewControllers.swift')
  target.source_build_phase.add_file_reference(file_ref)
  puts "Added PlaceholderViewControllers.swift to project"
end

# Find Core/Navigation group
core_group = main_app_group.children.find { |g| g.name == 'Core' && g.is_a?(Xcodeproj::Project::Object::PBXGroup) }
raise "Core group not found" unless core_group

navigation_group = core_group.children.find { |g| g.name == 'Navigation' && g.is_a?(Xcodeproj::Project::Object::PBXGroup) }
raise "Navigation group not found" unless navigation_group

# Check if MainTabBarController.swift is in the project
main_tab_bar = navigation_group.files.find { |f| f.path == 'MainTabBarController.swift' }

unless main_tab_bar
  main_tab_bar = navigation_group.new_file('MainTabBarController.swift')
  target.source_build_phase.add_file_reference(main_tab_bar)
  puts "Added MainTabBarController.swift to project"
else
  puts "MainTabBarController.swift already in project"
end

# Remove duplicate MainTabBarController from Features/Main if it exists
features_main_group = features_group.children.find { |g| g.name == 'Main' && g.is_a?(Xcodeproj::Project::Object::PBXGroup) }
if features_main_group
  duplicate = features_main_group.files.find { |f| f.path&.include?('MainTabBarController.swift') }
  if duplicate
    # Remove from build phase first
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == duplicate
        target.source_build_phase.remove_file_reference(build_file.file_ref)
      end
    end
    # Then remove from project
    duplicate.remove_from_project
    puts "Removed duplicate MainTabBarController from Features/Main"
  end
end

# Save the project
project.save
puts "Project saved successfully!"