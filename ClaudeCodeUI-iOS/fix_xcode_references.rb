#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

if target.nil?
  puts "Error: Could not find ClaudeCodeUI target"
  exit 1
end

puts "Found target: #{target.name}"

# Files that need to be moved/updated
files_to_fix = {
  # Files that moved from UI/Components to Design/Components
  'Design/Components/NoDataView.swift' => 'UI/Components/NoDataView.swift',
  'Design/Components/SkeletonView.swift' => 'UI/Components/SkeletonView.swift',
}

# New files that need to be added
new_files = [
  'Features/Chat/ChatAnimationManager.swift',
  'Features/Search/SearchFiltersView.swift',
  'UI/Components/CyberpunkButton.swift',
  'UI/Components/LoadingStateManager.swift'
]

# Helper function to find or create group
def find_or_create_group(project, path_components)
  group = project.main_group
  
  path_components.each do |component|
    next_group = group.children.find { |g| g.path == component || g.name == component }
    if next_group.nil?
      next_group = group.new_group(component)
      next_group.path = component
    end
    group = next_group
  end
  
  group
end

# Remove old references and add new ones for moved files
puts "\n=== Fixing moved files ==="
files_to_fix.each do |new_path, old_path|
  # Find and remove old reference
  old_file_ref = nil
  project.files.each do |file_ref|
    if file_ref.real_path.to_s.include?(old_path)
      puts "Found old reference: #{file_ref.real_path}"
      old_file_ref = file_ref
      break
    end
  end
  
  if old_file_ref
    # Remove from build phase
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == old_file_ref
        puts "Removing from build phase: #{old_path}"
        target.source_build_phase.remove_build_file(build_file)
      end
    end
    
    # Remove the file reference
    old_file_ref.remove_from_project
    puts "Removed old reference: #{old_path}"
  end
  
  # Check if new file already exists
  new_file_exists = project.files.any? { |f| f.real_path.to_s.include?(new_path) }
  
  if !new_file_exists && File.exist?(new_path)
    # Add new reference
    path_components = new_path.split('/')
    file_name = path_components.pop
    group = find_or_create_group(project, path_components)
    
    file_ref = group.new_reference(new_path)
    file_ref.name = file_name
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added new reference: #{new_path}"
  elsif new_file_exists
    puts "File already in project: #{new_path}"
  else
    puts "Warning: File does not exist: #{new_path}"
  end
end

# Add new files
puts "\n=== Adding new files ==="
new_files.each do |file_path|
  # Check if file already exists in project
  file_exists = project.files.any? { |f| f.real_path.to_s.include?(file_path) }
  
  if !file_exists && File.exist?(file_path)
    path_components = file_path.split('/')
    file_name = path_components.pop
    group = find_or_create_group(project, path_components)
    
    file_ref = group.new_reference(file_path)
    file_ref.name = file_name
    target.source_build_phase.add_file_reference(file_ref)
    puts "Added: #{file_path}"
  elsif file_exists
    puts "Already in project: #{file_path}"
  else
    puts "Warning: File does not exist: #{file_path}"
  end
end

# Clean up any duplicate or invalid references
puts "\n=== Cleaning up duplicates and invalid references ==="
files_to_remove = []
seen_paths = Set.new

project.files.each do |file_ref|
  path = file_ref.real_path.to_s
  
  # Check for duplicates
  if seen_paths.include?(path)
    files_to_remove << file_ref
    puts "Found duplicate: #{path}"
  elsif !File.exist?(path) && path.include?('.swift')
    # Check if it's a moved file
    if path.include?('UI/Components/NoDataView.swift') || path.include?('UI/Components/SkeletonView.swift')
      files_to_remove << file_ref
      puts "Found old reference to remove: #{path}"
    end
  end
  
  seen_paths.add(path)
end

# Remove duplicates and invalid references
files_to_remove.each do |file_ref|
  # Remove from build phase
  target.source_build_phase.files.each do |build_file|
    if build_file.file_ref == file_ref
      target.source_build_phase.remove_build_file(build_file)
    end
  end
  
  # Remove the file reference
  file_ref.remove_from_project
  puts "Removed: #{file_ref.real_path}"
end

# Save the project
project.save
puts "\n=== Project saved successfully ==="
puts "Fixed #{files_to_fix.count} moved files"
puts "Added #{new_files.count} new files"
puts "Removed #{files_to_remove.count} duplicate/invalid references"