#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'

puts "Opening project: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Get main target
main_target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

unless main_target
  puts "ERROR: Could not find main target 'ClaudeCodeUI'"
  exit 1
end

puts "Found main target: #{main_target.name}"

# Files to fix
files_to_fix = {
  'NoDataView.swift' => 'Design/Components/NoDataView.swift',
  'SkeletonView.swift' => 'Design/Components/SkeletonView.swift'
}

# Track what we do
fixed_files = []
not_found = []

# Process each file
files_to_fix.each do |filename, new_path|
  puts "\nLooking for #{filename}..."
  
  # Find the file reference
  file_ref = project.files.find { |f| f.path && f.path.include?(filename) }
  
  if file_ref
    old_path = file_ref.path
    puts "  Found at: #{old_path}"
    
    # Update the path
    file_ref.path = new_path
    puts "  Updated to: #{new_path}"
    
    # Verify the file is in the target
    build_file = main_target.source_build_phase.files.find { |bf| bf.file_ref == file_ref }
    if build_file
      puts "  ✓ File is in build phase"
    else
      puts "  Adding to build phase..."
      main_target.add_file_references([file_ref])
      puts "  ✓ Added to build phase"
    end
    
    fixed_files << filename
  else
    puts "  ✗ File not found in project"
    not_found << filename
  end
end

# Save the project
puts "\nSaving project..."
project.save

puts "\n" + "="*50
puts "Summary:"
puts "  Fixed: #{fixed_files.join(', ')}" unless fixed_files.empty?
puts "  Not found: #{not_found.join(', ')}" unless not_found.empty?
puts "="*50

if not_found.any?
  puts "\nFor files not found, you may need to add them manually:"
  not_found.each do |filename|
    actual_path = files_to_fix[filename]
    full_path = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/#{actual_path}"
    puts "  - #{filename} should be at: #{full_path}"
  end
end

puts "\nDone! Try building again."