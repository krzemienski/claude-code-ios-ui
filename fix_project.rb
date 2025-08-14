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

puts "📦 Fixing ClaudeCodeUI project..."

# Get the main group
main_group = project.main_group

# Find or create the Core/Services group
core_group = main_group.find_subpath('Core', true)
services_group = core_group.find_subpath('Services', true)

# Add DIContainer.swift if it doesn't exist
di_container_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Services/DIContainer.swift'
if File.exist?(di_container_path)
  # Check if file is already in project
  existing_file = services_group.files.find { |f| f.path == 'DIContainer.swift' }
  
  if existing_file.nil?
    puts "✅ Adding DIContainer.swift to project..."
    file_ref = services_group.new_file(di_container_path)
    target.add_file_references([file_ref])
  else
    puts "✅ DIContainer.swift already in project"
  end
else
  puts "❌ DIContainer.swift not found at expected path"
end

# Add other missing Service files
service_files = [
  'CacheManager.swift',
  'Logger.swift',
  'AppError.swift',
  'ErrorHandlingService.swift',
  'SettingsExportManager.swift'
]

service_files.each do |filename|
  file_path = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Services/#{filename}"
  if File.exist?(file_path)
    existing_file = services_group.files.find { |f| f.path == filename }
    if existing_file.nil?
      puts "✅ Adding #{filename} to project..."
      file_ref = services_group.new_file(file_path)
      target.add_file_references([file_ref])
    end
  end
end

# Clean up any dangling references
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