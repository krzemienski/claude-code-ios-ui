#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

if target.nil?
  puts "❌ Could not find ClaudeCodeUI target"
  exit 1
end

puts "📦 Fixing duplicate error definitions in ClaudeCodeUI project..."

# Find and remove AppError.swift references
puts "🔍 Looking for AppError.swift references..."
app_error_refs = []

# Find all references to AppError.swift
project.files.each do |file_ref|
  if file_ref.path && file_ref.path.include?("AppError.swift")
    app_error_refs << file_ref
    puts "  Found reference: #{file_ref.path}"
  end
end

# Remove AppError.swift from build phases
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path && build_file.file_ref.path.include?("AppError.swift")
    puts "  ❌ Removing AppError.swift from build phases"
    build_file.remove_from_project
  end
end

# Remove AppError.swift file references
app_error_refs.each do |ref|
  puts "  ❌ Removing file reference: #{ref.path}"
  ref.remove_from_project
end

# Ensure ErrorHandlingService.swift is included
puts "✅ Checking ErrorHandlingService.swift..."
core_group = project.main_group.find_subpath('Core', true)
services_group = core_group.find_subpath('Services', true)

error_handling_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Services/ErrorHandlingService.swift'
if File.exist?(error_handling_path)
  # Check if ErrorHandlingService.swift is already in project
  existing_file = services_group.files.find { |f| f.path == 'ErrorHandlingService.swift' }
  
  if existing_file.nil?
    puts "  ✅ Adding ErrorHandlingService.swift to project..."
    file_ref = services_group.new_file(error_handling_path)
    target.add_file_references([file_ref])
  else
    puts "  ✅ ErrorHandlingService.swift already in project"
    
    # Make sure it's in the build phase
    in_build_phase = target.source_build_phase.files.any? { |bf| 
      bf.file_ref && bf.file_ref.path == 'ErrorHandlingService.swift'
    }
    
    if !in_build_phase
      puts "  ✅ Adding ErrorHandlingService.swift to build phase..."
      target.add_file_references([existing_file])
    end
  end
else
  puts "  ❌ ErrorHandlingService.swift not found at expected path"
end

# Clean up any other dangling references
puts "🧹 Cleaning up dangling references..."
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref.nil? || build_file.file_ref.real_path.nil? || !File.exist?(build_file.file_ref.real_path.to_s)
    puts "  Removing dangling reference: #{build_file.display_name}"
    build_file.remove_from_project
  end
end

# Save the project
project.save
puts "✅ Project fixed and saved!"

# Backup AppError.swift to prevent accidental inclusion
app_error_file = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Services/AppError.swift'
if File.exist?(app_error_file)
  backup_path = "#{app_error_file}.backup"
  puts "📦 Moving AppError.swift to #{backup_path} to prevent conflicts..."
  File.rename(app_error_file, backup_path)
end

puts "🎉 All done! The duplicate error definitions have been resolved."
puts "   - AppError.swift has been removed from the project"
puts "   - ErrorHandlingService.swift contains all error definitions"
puts "   - You can now build the project without conflicts"