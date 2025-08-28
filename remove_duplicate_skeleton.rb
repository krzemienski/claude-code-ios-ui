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
puts "\nAnalyzing SkeletonView files..."

# Find all SkeletonView references
skeleton_refs = []
project.files.each do |file_ref|
  next unless file_ref.path
  if file_ref.path.include?('SkeletonView.swift')
    skeleton_refs << {ref: file_ref, path: file_ref.path, uuid: file_ref.uuid}
    puts "  Found: #{file_ref.path} (UUID: #{file_ref.uuid})"
  end
end

# Remove the incorrect reference (the one without the full path)
puts "\nRemoving incorrect references..."
removed = []

skeleton_refs.each do |item|
  if item[:path] == "SkeletonView.swift"  # This is the incorrect one
    puts "  Removing incorrect reference: #{item[:path]}"
    
    # Remove from build phase
    build_file = main_target.source_build_phase.files.find { |bf| bf.file_ref == item[:ref] }
    if build_file
      main_target.source_build_phase.remove_build_file(build_file)
      puts "    ✓ Removed from build phase"
    end
    
    # Remove the file reference itself
    item[:ref].remove_from_project
    puts "    ✓ Removed from project"
    removed << item[:path]
  end
end

# Verify the correct one remains
puts "\nVerifying correct references..."
project.files.each do |file_ref|
  next unless file_ref.path
  if file_ref.path == "Design/Components/SkeletonView.swift"
    puts "  ✓ Correct SkeletonView.swift remains at: #{file_ref.path}"
    
    # Make sure it's in the build phase
    build_file = main_target.source_build_phase.files.find { |bf| bf.file_ref == file_ref }
    if build_file
      puts "    ✓ Is in build phase"
    else
      puts "    Adding to build phase..."
      main_target.add_file_references([file_ref])
      puts "    ✓ Added to build phase"
    end
  end
end

# Save the project
puts "\nSaving project..."
project.save

puts "\n" + "="*50
puts "Summary:"
puts "  Total SkeletonView references found: #{skeleton_refs.count}"
puts "  Incorrect references removed: #{removed.count}"
puts "  Removed: #{removed.join(', ')}" unless removed.empty?
puts "="*50

puts "\nDone! Try building again."