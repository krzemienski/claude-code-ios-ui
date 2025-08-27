#!/usr/bin/env ruby

# Script to properly setup UI test target
require 'xcodeproj'

project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Setting up UI Tests target..."

# Check if UI test target exists
ui_test_target = project.targets.find { |t| t.name == "ClaudeCodeUIUITests" }

if ui_test_target.nil?
  puts "Creating UI Tests target..."
  
  # Get main app target
  main_target = project.targets.find { |t| t.name == "ClaudeCodeUI" }
  
  # Create UI test target
  ui_test_target = project.new_target(:ui_test_bundle, 'ClaudeCodeUIUITests', :ios, '17.0')
  
  # Set the test target's host application
  ui_test_target.add_dependency(main_target)
  
  # Configure build settings
  ui_test_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.claudecode.ui.uitests'
    config.build_settings['TEST_TARGET_NAME'] = 'ClaudeCodeUI'
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  end
  
  puts "UI Tests target created"
end

# Create or find UI tests group
ui_tests_group = project.main_group['ClaudeCodeUIUITests']
if ui_tests_group.nil?
  ui_tests_group = project.main_group.new_group('ClaudeCodeUIUITests', 'ClaudeCodeUIUITests')
  puts "Created ClaudeCodeUIUITests group"
end

# Find the UI test files in the file system
ui_test_files_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUIUITests'
if Dir.exist?(ui_test_files_path)
  Dir.glob("#{ui_test_files_path}/*.swift").each do |file_path|
    filename = File.basename(file_path)
    
    # Check if file reference already exists
    file_ref = ui_tests_group.files.find { |f| f.path == filename }
    
    if file_ref.nil?
      # Add file reference to the group
      file_ref = ui_tests_group.new_file(file_path)
      puts "Added file reference: #{filename}"
    end
    
    # Check if file is in the UI test target's build phase
    already_in_target = ui_test_target.source_build_phase.files.any? do |build_file|
      build_file.file_ref == file_ref
    end
    
    unless already_in_target
      ui_test_target.add_file_references([file_ref])
      puts "Added #{filename} to UI test target"
    end
  end
end

# Remove UI test files from main app target (double check)
main_target = project.targets.find { |t| t.name == "ClaudeCodeUI" }
if main_target
  main_target.source_build_phase.files.delete_if do |file|
    if file.file_ref && file.file_ref.path
      filename = File.basename(file.file_ref.path)
      is_ui_test = filename.include?('UITest') || filename.include?('UITests')
      puts "Removed #{filename} from main target" if is_ui_test
      is_ui_test
    end
  end
end

# Save the project
project.save
puts "\nUI Tests target setup complete!"
puts "The UI test files are now properly organized in the ClaudeCodeUIUITests target."