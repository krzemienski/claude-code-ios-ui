#!/usr/bin/env ruby

require 'xcodeproj'

# Path to the Xcode project
project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'

puts "Opening project: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Get main target and UI test target
main_target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }
ui_test_target = project.targets.find { |t| t.name == 'ClaudeCodeUIUITests' }

unless main_target
  puts "ERROR: Could not find main target 'ClaudeCodeUI'"
  exit 1
end

unless ui_test_target
  puts "ERROR: Could not find UI test target 'ClaudeCodeUIUITests'"
  exit 1
end

puts "Found main target: #{main_target.name}"
puts "Found UI test target: #{ui_test_target.name}"

# Track changes
removed_from_main = []
moved_to_uitest = []
removed_files = []

# Function to remove file from all targets
def remove_from_all_targets(file_ref, project)
  project.targets.each do |target|
    build_file = target.source_build_phase.files.find { |bf| bf.file_ref == file_ref }
    if build_file
      target.source_build_phase.remove_build_file(build_file)
      puts "  Removed from target: #{target.name}"
    end
  end
end

# Process all files in the project
puts "\nProcessing files..."
project.files.each do |file_ref|
  next unless file_ref.path
  
  file_name = File.basename(file_ref.path)
  
  # Check if file should be removed entirely (backup files, non-compilable files)
  if file_name.end_with?('.bak', '.bak11', '.bak12', '.bak13', '.bak14', '.bak15', '.bak16', '.bak17') ||
     file_name.end_with?('.md', '.txt', '.rb', '.sh', '.png', '.backup', '_backup.swift', '_FIXED.swift', '_Part2.swift', '_Extension.swift')
    
    puts "Removing backup/non-source file: #{file_ref.path}"
    remove_from_all_targets(file_ref, project)
    
    # Remove from project navigator
    file_ref.remove_from_project
    removed_files << file_name
    next
  end
  
  # Check if this is a UI test file that should be in UI test target
  if file_name.include?('UITest') || file_name.include?('UITests')
    # Check if it's in the main target
    main_build_file = main_target.source_build_phase.files.find { |bf| bf.file_ref == file_ref }
    
    if main_build_file
      puts "Found UI test file in main target: #{file_ref.path}"
      
      # Remove from main target
      main_target.source_build_phase.remove_build_file(main_build_file)
      removed_from_main << file_name
      
      # Add to UI test target if not already there
      ui_test_build_file = ui_test_target.source_build_phase.files.find { |bf| bf.file_ref == file_ref }
      unless ui_test_build_file
        ui_test_target.add_file_references([file_ref])
        moved_to_uitest << file_name
        puts "  Moved to UI test target"
      end
    end
  end
  
  # Special handling for specific problem files mentioned
  if ['ChatViewController_Part2.swift', 'ChatViewController_Extension.swift', 
      'ChatViewController_FIXED.swift', 'ChatViewController_backup.swift',
      'ViewControllers.swift'].include?(file_name)
    
    # These should not be in any target
    puts "Removing problematic file from all targets: #{file_ref.path}"
    remove_from_all_targets(file_ref, project)
    
    # Remove the file reference entirely if it's a backup or duplicate
    if file_name.include?('_backup') || file_name.include?('_FIXED') || 
       file_name.include?('_Part2') || file_name.include?('_Extension')
      file_ref.remove_from_project
      removed_files << file_name
    end
  end
end

# Look for specific UI test files that need to be moved
ui_test_files = ['AliveMainFlowUITests.swift', 'MajorFlowsUITests.swift']
ui_test_files.each do |filename|
  file_ref = project.files.find { |f| f.path && f.path.include?(filename) }
  
  if file_ref
    # Remove from main target if present
    main_build_file = main_target.source_build_phase.files.find { |bf| bf.file_ref == file_ref }
    if main_build_file
      puts "Removing #{filename} from main target"
      main_target.source_build_phase.remove_build_file(main_build_file)
      removed_from_main << filename
    end
    
    # Ensure it's in UI test target
    ui_test_build_file = ui_test_target.source_build_phase.files.find { |bf| bf.file_ref == file_ref }
    unless ui_test_build_file
      puts "Adding #{filename} to UI test target"
      ui_test_target.add_file_references([file_ref])
      moved_to_uitest << filename
    end
  end
end

# Clean up any nil or broken references
puts "\nCleaning up broken references..."
project.groups.each do |group|
  group.children.select { |child| child.nil? || (child.respond_to?(:path) && child.path.nil?) }.each do |broken|
    group.children.delete(broken) if broken
  end
end

# Remove duplicate references in build phases
[main_target, ui_test_target].each do |target|
  if target && target.source_build_phase
    seen_files = Set.new
    duplicates = []
    
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref && build_file.file_ref.path
        if seen_files.include?(build_file.file_ref.path)
          duplicates << build_file
        else
          seen_files.add(build_file.file_ref.path)
        end
      end
    end
    
    duplicates.each do |dup|
      target.source_build_phase.remove_build_file(dup)
      puts "Removed duplicate from #{target.name}: #{dup.file_ref.path if dup.file_ref}"
    end
  end
end

# Save the project
puts "\nSaving project..."
project.save

# Print summary
puts "\n" + "="*60
puts "SUMMARY OF CHANGES:"
puts "="*60

if removed_from_main.any?
  puts "\nRemoved from main target:"
  removed_from_main.each { |f| puts "  - #{f}" }
end

if moved_to_uitest.any?
  puts "\nMoved to UI test target:"
  moved_to_uitest.each { |f| puts "  - #{f}" }
end

if removed_files.any?
  puts "\nRemoved from project entirely:"
  removed_files.each { |f| puts "  - #{f}" }
end

puts "\nProject cleanup complete!"
puts "Next steps:"
puts "1. Open Xcode and build the project"
puts "2. If there are still issues, check the build log for specific errors"