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

puts "📦 Comprehensive fix for ClaudeCodeUI project..."
puts "=" * 50

# Step 1: Add TerminalOutput.swift to project
puts "✅ Step 1: Adding missing model files..."
main_group = project.main_group
core_group = main_group.find_subpath('Core', true)
data_group = core_group.find_subpath('Data', true)
models_group = data_group.find_subpath('Models', true)

terminal_output_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Data/Models/TerminalOutput.swift'
if File.exist?(terminal_output_path)
  existing_file = models_group.files.find { |f| f.path == 'TerminalOutput.swift' }
  if existing_file.nil?
    puts "  ✅ Adding TerminalOutput.swift to project..."
    file_ref = models_group.new_file(terminal_output_path)
    target.add_file_references([file_ref])
  else
    puts "  ✅ TerminalOutput.swift already in project"
  end
else
  puts "  ❌ TerminalOutput.swift not found on disk"
end

# Step 2: Ensure all service files are included
puts "\n✅ Step 2: Verifying all service files..."
services_group = core_group.find_subpath('Services', true)

service_files = [
  'DIContainer.swift',
  'ErrorHandlingService.swift',
  'CacheManager.swift',
  'Logger.swift',
  'SettingsExportManager.swift'
]

service_files.each do |filename|
  file_path = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Services/#{filename}"
  if File.exist?(file_path)
    existing_file = services_group.files.find { |f| f.path == filename }
    if existing_file.nil?
      puts "  ✅ Adding #{filename} to project..."
      file_ref = services_group.new_file(file_path)
      target.add_file_references([file_ref])
    else
      puts "  ✅ #{filename} already in project"
    end
  else
    puts "  ⚠️ #{filename} not found on disk"
  end
end

# Step 3: Ensure all network files are included
puts "\n✅ Step 3: Verifying network files..."
network_group = core_group.find_subpath('Network', true)

network_files = [
  'APIClient.swift',
  'WebSocketManager.swift'
]

network_files.each do |filename|
  file_path = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Network/#{filename}"
  if File.exist?(file_path)
    existing_file = network_group.files.find { |f| f.path == filename }
    if existing_file.nil?
      puts "  ✅ Adding #{filename} to project..."
      file_ref = network_group.new_file(file_path)
      target.add_file_references([file_ref])
    else
      puts "  ✅ #{filename} already in project"
    end
  else
    puts "  ⚠️ #{filename} not found on disk"
  end
end

# Step 4: Clean up dangling references
puts "\n✅ Step 4: Cleaning up dangling references..."
cleaned_count = 0
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref.nil? || build_file.file_ref.real_path.nil? || !File.exist?(build_file.file_ref.real_path.to_s)
    puts "  Removing dangling reference: #{build_file.display_name}"
    build_file.remove_from_project
    cleaned_count += 1
  end
end
puts "  Cleaned #{cleaned_count} dangling references"

# Save the project
project.save
puts "\n✅ Project structure fixed and saved!"

# Now fix the Swift code issues
puts "\n📝 Step 5: Fixing Swift code issues..."

# Fix Settings.swift - add missing properties
settings_file = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Core/Data/Models/Settings.swift'
if File.exist?(settings_file)
  settings_content = File.read(settings_file)
  
  # Check if properties are missing and add them
  if !settings_content.include?('webSocketReconnectDelay')
    puts "  ✅ Adding missing WebSocket properties to Settings..."
    
    # Find the line with "var apiTimeout" and add after it
    settings_content.gsub!(/(\s+var apiTimeout: TimeInterval)/, 
      "\\1\n    var webSocketReconnectDelay: TimeInterval\n    var maxReconnectAttempts: Int")
    
    # Add initialization in init method
    settings_content.gsub!(/(self\.apiTimeout = 30\.0)/, 
      "\\1\n        self.webSocketReconnectDelay = 2.0\n        self.maxReconnectAttempts = 5")
    
    File.write(settings_file, settings_content)
    puts "  ✅ Settings.swift updated with WebSocket properties"
  else
    puts "  ✅ Settings.swift already has WebSocket properties"
  end
end

puts "\n🎉 Comprehensive fix complete!"
puts "   - All model files added to project"
puts "   - All service files verified"
puts "   - Settings.swift updated with missing properties"
puts "   - Dangling references cleaned"
puts "\nNext steps:"
puts "   1. Build the project to check for remaining issues"
puts "   2. Fix any remaining API method issues in APIClient"
puts "   3. Fix Main Actor isolation issues in DIContainer"