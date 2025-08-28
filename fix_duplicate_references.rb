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
puts "\nAnalyzing current files in project..."

# Find all skeleton-related files
skeleton_files = []
project.files.each do |file_ref|
  next unless file_ref.path
  if file_ref.path.downcase.include?('skeleton')
    skeleton_files << file_ref
    puts "  Found: #{file_ref.path} (UUID: #{file_ref.uuid})"
  end
end

puts "\n#{skeleton_files.count} skeleton-related files found"

# Remove LoadingSkeletonView from build phase if it's incorrectly mapped
puts "\nChecking for duplicate or incorrect references..."
main_target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path
    file_path = build_file.file_ref.path
    
    # Check if LoadingSkeletonView is incorrectly mapped to SkeletonView
    if file_path == "LoadingSkeletonView.swift" || file_path.include?("LoadingSkeletonView")
      puts "  Found LoadingSkeletonView reference: #{file_path}"
      
      # Check the actual file location
      actual_path = "Design/Components/LoadingSkeletonView.swift"
      full_path = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/#{actual_path}"
      
      if File.exist?(full_path)
        puts "    File exists at: #{actual_path}"
        build_file.file_ref.path = actual_path
        puts "    ✓ Updated path to: #{actual_path}"
      end
    elsif file_path == "Design/Components/SkeletonView.swift"
      # This is the correct SkeletonView
      puts "  Found correct SkeletonView at: #{file_path}"
      
      # Verify the actual file exists
      full_path = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/#{file_path}"
      if File.exist?(full_path)
        puts "    ✓ File exists and is correctly referenced"
      else
        puts "    ✗ WARNING: File doesn't exist at expected location!"
      end
    end
  end
end

# Remove duplicates from build phase
puts "\nRemoving duplicate entries from build phase..."
seen_paths = Set.new
duplicates_removed = []

main_target.source_build_phase.files.to_a.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path
    path = build_file.file_ref.path
    
    if seen_paths.include?(path)
      puts "  Removing duplicate: #{path}"
      main_target.source_build_phase.remove_build_file(build_file)
      duplicates_removed << path
    else
      seen_paths.add(path)
    end
  end
end

# Save the project
puts "\nSaving project..."
project.save

puts "\n" + "="*50
puts "Summary:"
puts "  Files analyzed: #{skeleton_files.count}"
puts "  Duplicates removed: #{duplicates_removed.count}"
puts "  Duplicates: #{duplicates_removed.uniq.join(', ')}" unless duplicates_removed.empty?
puts "="*50

puts "\nDone! Try building again."