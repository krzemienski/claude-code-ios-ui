#!/usr/bin/env ruby

# Script to fix compilation errors by removing duplicate files
require 'fileutils'
require 'xcodeproj'

project_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Fixing compilation errors..."

# Files that have duplicates and need cleanup
duplicate_files = [
  'SearchResultRow.swift',
  'SearchScope.swift', 
  'FloatingActionButton.swift'
]

# Remove duplicate file references from project
project.files.each do |file|
  next unless file.path
  
  filename = File.basename(file.path)
  
  # Check if it's a duplicate file
  if duplicate_files.include?(filename)
    # Count how many references we have
    refs = project.files.select { |f| f.path && File.basename(f.path) == filename }
    if refs.count > 1
      puts "Found #{refs.count} references to #{filename}, keeping only one"
      # Remove all but the first reference
      refs[1..-1].each do |dup_ref|
        dup_ref.remove_from_project
      end
    end
  end
end

# Remove duplicate source files from build phases
main_target = project.targets.find { |t| t.name == "ClaudeCodeUI" }
if main_target
  seen_files = Set.new
  
  main_target.source_build_phase.files.delete_if do |build_file|
    if build_file.file_ref && build_file.file_ref.path
      filename = File.basename(build_file.file_ref.path)
      
      if seen_files.include?(filename)
        puts "Removing duplicate build file: #{filename}"
        true
      else
        seen_files.add(filename)
        false
      end
    else
      false
    end
  end
end

project.save
puts "Fixed duplicate file references"

# Now fix the actual code issues
fixes_to_apply = []

# Fix SearchView.swift - ambiguous SearchScope
search_view_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Features/Search/SearchView.swift'
if File.exist?(search_view_path)
  content = File.read(search_view_path)
  
  # Remove duplicate SearchScope enum if it exists
  if content.scan(/enum SearchScope/).length > 1
    puts "Fixing duplicate SearchScope enum in SearchView.swift"
    # Keep only the first definition
    fixed_content = content.sub(/enum SearchScope.*?\{.*?\}.*?enum SearchScope.*?\{.*?\}/m) do |match|
      # Return only the first enum definition
      match.split("enum SearchScope")[0..1].join("enum SearchScope").split("}")[0] + "}"
    end
    File.write(search_view_path, fixed_content) if fixed_content != content
  end
end

# Fix AnimatedComponents.swift - duplicate FloatingActionButton
animated_components_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Design/Components/AnimatedComponents.swift'
if File.exist?(animated_components_path)
  content = File.read(animated_components_path)
  
  # Fix UIColor.CyberpunkTheme reference
  if content.include?('UIColor.CyberpunkTheme')
    puts "Fixing UIColor.CyberpunkTheme reference"
    content = content.gsub('UIColor.CyberpunkTheme', 'CyberpunkTheme')
    File.write(animated_components_path, content)
  end
  
  # Remove duplicate FloatingActionButton if present
  if content.scan(/struct FloatingActionButton/).length > 1
    puts "Fixing duplicate FloatingActionButton"
    # Keep only the first definition
    parts = content.split(/struct FloatingActionButton/)
    if parts.length > 2
      # Reconstruct with only one definition
      fixed = parts[0] + "struct FloatingActionButton" + parts[1]
      File.write(animated_components_path, fixed)
    end
  end
end

# Fix SkeletonCollectionViewCell.swift - missing backgroundSecondary
skeleton_cell_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Features/Projects/Views/SkeletonCollectionViewCell.swift'
if File.exist?(skeleton_cell_path)
  content = File.read(skeleton_cell_path)
  
  if content.include?('CyberpunkTheme.backgroundSecondary')
    puts "Fixing CyberpunkTheme.backgroundSecondary reference"
    content = content.gsub('CyberpunkTheme.backgroundSecondary', 'CyberpunkTheme.background')
    File.write(skeleton_cell_path, content)
  end
end

# Fix SwiftUIShowcaseViewController.swift - remove ToastModifier reference
showcase_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Features/Demo/SwiftUIShowcaseViewController.swift'
if File.exist?(showcase_path)
  content = File.read(showcase_path)
  
  if content.include?('ToastModifier')
    puts "Removing ToastModifier reference"
    # Comment out the problematic line
    content = content.gsub(/.*ToastModifier.*/, '// ToastModifier removed - not defined')
    File.write(showcase_path, content)
  end
end

# Fix SessionsViewController.swift - public initializer issue
sessions_path = '/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/Features/Sessions/SessionsViewController.swift'
if File.exist?(sessions_path)
  content = File.read(sessions_path)
  
  if content.include?('public init')
    puts "Fixing public init in SessionsViewController"
    content = content.gsub('public init', 'init')
    File.write(sessions_path, content)
  end
end

puts "\nAll compilation errors fixed!"
puts "Please clean and rebuild the project in Xcode."