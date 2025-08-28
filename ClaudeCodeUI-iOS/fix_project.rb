#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }

if target.nil?
  puts "Error: Could not find target 'ClaudeCodeUI'"
  exit 1
end

puts "Found target: #{target.name}"
puts "Current build files count: #{target.source_build_phase.files.count}"

# Remove incorrect references
files_to_remove = []
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref
    path = build_file.file_ref.real_path.to_s rescue build_file.file_ref.path
    if path.include?('UI/Components/Design/Components/NoDataView.swift') || 
       path.include?('UI/Components/Design/Components/SkeletonView.swift') ||
       path.include?('Design/Components/Design/Components/')
      puts "Removing incorrect reference: #{path}"
      files_to_remove << build_file
    end
  end
end

files_to_remove.each { |f| target.source_build_phase.remove_build_file(f) }

# Add correct references for NoDataView and SkeletonView
correct_files = [
  'Design/Components/NoDataView.swift',
  'Design/Components/SkeletonView.swift'
]

main_group = project.main_group

correct_files.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)
  if File.exist?(full_path)
    # Find or create the file reference
    file_ref = main_group.find_file_by_path(file_path)
    
    if file_ref.nil?
      # Create proper group structure
      path_components = file_path.split('/')
      current_group = main_group
      
      # Navigate/create groups
      path_components[0..-2].each do |component|
        subgroup = current_group.children.find { |child| child.path == component || child.name == component }
        if subgroup.nil? || !subgroup.is_a?(Xcodeproj::Project::Object::PBXGroup)
          subgroup = current_group.new_group(component, component)
        end
        current_group = subgroup
      end
      
      # Add the file
      file_ref = current_group.new_file(full_path)
      puts "Created new file reference for: #{file_path}"
    else
      puts "File reference already exists for: #{file_path}"
    end
    
    # Check if file is already in build phase
    already_in_build = target.source_build_phase.files.any? do |bf|
      bf.file_ref && bf.file_ref.real_path.to_s == full_path
    end
    
    unless already_in_build
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added to build phase: #{file_path}"
    else
      puts "Already in build phase: #{file_path}"
    end
  else
    puts "Warning: File does not exist: #{full_path}"
  end
end

# Now let's add ALL missing Swift files to the build phase
puts "\nScanning for all Swift files..."
all_swift_files = Dir.glob("**/*.swift").reject { |f| f.start_with?('.') || f.include?('/Tests/') || f.include?('Package.swift') }

puts "Found #{all_swift_files.count} Swift files total"

added_count = 0
all_swift_files.each do |file_path|
  full_path = File.join(Dir.pwd, file_path)
  
  # Check if file is already in build phase
  already_in_build = target.source_build_phase.files.any? do |bf|
    if bf.file_ref
      bf_path = bf.file_ref.real_path.to_s rescue bf.file_ref.path
      bf_path == full_path || bf_path.end_with?(file_path)
    end
  end
  
  unless already_in_build
    # Find or create the file reference
    file_ref = project.reference_for_path(full_path)
    
    if file_ref.nil?
      # Create proper group structure
      path_components = file_path.split('/')
      current_group = main_group
      
      # Navigate/create groups
      path_components[0..-2].each do |component|
        subgroup = current_group.children.find { |child| 
          child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
          (child.path == component || child.name == component)
        }
        if subgroup.nil?
          subgroup = current_group.new_group(component, component)
        end
        current_group = subgroup
      end
      
      # Add the file
      file_ref = current_group.new_file(full_path)
    end
    
    target.source_build_phase.add_file_reference(file_ref)
    added_count += 1
    puts "Added: #{file_path}"
  end
end

puts "\nAdded #{added_count} new files to build phase"
puts "Total build files after: #{target.source_build_phase.files.count}"

# Save the project
project.save

puts "\nProject fixed successfully!"
puts "Now try building again with:"
puts "xcodebuild -project ClaudeCodeUI.xcodeproj -scheme ClaudeCodeUI -destination 'platform=iOS Simulator,id=058A3C12-3207-436C-96D4-A92F1D5697DF' build"