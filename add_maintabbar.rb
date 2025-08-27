#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
file_to_add = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Navigation/MainTabBarController.swift'

puts "Opening project: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Get main target
main_target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

unless main_target
  puts "ERROR: Could not find main target 'ClaudeCodeUI'"
  exit 1
end

# First, check if MainTabBarController.swift exists in the project references
file_ref = project.files.find { |f| 
  f.path && (f.path == 'MainTabBarController.swift' || 
             f.path.end_with?('/MainTabBarController.swift') ||
             f.path.include?('Core/Navigation/MainTabBarController.swift'))
}

if !file_ref
  puts "MainTabBarController.swift not found in project references, adding it..."
  
  # Find the Navigation group
  main_group = project.main_group
  core_group = main_group.children.find { |g| g.name == 'Core' } || 
               main_group.children.find { |g| g.path == 'Core' }
  
  if core_group
    navigation_group = core_group.children.find { |g| g.name == 'Navigation' || g.path == 'Navigation' }
    
    if navigation_group
      # Add file reference to Navigation group
      file_ref = navigation_group.new_reference(file_to_add)
      puts "Added file reference to Navigation group"
    else
      # Create Navigation group and add file
      navigation_group = core_group.new_group('Navigation', 'Core/Navigation')
      file_ref = navigation_group.new_reference(file_to_add)
      puts "Created Navigation group and added file reference"
    end
  else
    # Create Core group structure
    core_group = main_group.new_group('Core', 'Core')
    navigation_group = core_group.new_group('Navigation', 'Core/Navigation')
    file_ref = navigation_group.new_reference(file_to_add)
    puts "Created Core/Navigation structure and added file reference"
  end
else
  puts "MainTabBarController.swift found in project references at: #{file_ref.path}"
end

# Check if it's in the main target's build phase
main_build_file = main_target.source_build_phase.files.find { |bf| 
  bf.file_ref && bf.file_ref.path && 
  (bf.file_ref.path.include?('MainTabBarController.swift') || 
   bf.file_ref == file_ref)
}

if main_build_file
  puts "MainTabBarController.swift is already in main target"
else
  puts "Adding MainTabBarController.swift to main target..."
  main_target.add_file_references([file_ref])
  puts "Successfully added to main target"
end

# Save the project
puts "\nSaving project..."
project.save

puts "\nProject updated successfully!"
puts "MainTabBarController.swift is now properly included in the main target."