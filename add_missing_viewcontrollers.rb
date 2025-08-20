#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'ClaudeCodeUI' }
raise "Target 'ClaudeCodeUI' not found" unless target

# Find the main app group
main_app_group = project.main_group.children.find do |g| 
  g.is_a?(Xcodeproj::Project::Object::PBXGroup) && g.name != 'Products'
end

puts "Using main app group: #{main_app_group.name || main_app_group.path || 'unnamed'}"

# Find Features group
features_group = main_app_group.children.find do |child|
  child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
  (child.name == 'Features' || child.path == 'Features')
end

if features_group
  puts "Found Features group"
  
  # Add Search folder and files
  search_group = features_group.children.find do |child|
    child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
    (child.name == 'Search' || child.path == 'Search')
  end
  
  if search_group
    puts "Found Search group"
    
    # Check and add SearchViewController.swift
    search_vc = search_group.files.find { |f| f.path == 'SearchViewController.swift' }
    unless search_vc
      search_vc = search_group.new_file('SearchViewController.swift')
      target.source_build_phase.add_file_reference(search_vc)
      puts "Added SearchViewController.swift to project"
    else
      puts "SearchViewController.swift already in project"
    end
    
    # Check and add SearchView.swift
    search_view = search_group.files.find { |f| f.path == 'SearchView.swift' }
    unless search_view
      search_view = search_group.new_file('SearchView.swift')
      target.source_build_phase.add_file_reference(search_view)
      puts "Added SearchView.swift to project"
    else
      puts "SearchView.swift already in project"
    end
    
    # Check and add SearchViewModel.swift
    search_vm = search_group.files.find { |f| f.path == 'SearchViewModel.swift' }
    unless search_vm
      search_vm = search_group.new_file('SearchViewModel.swift')
      target.source_build_phase.add_file_reference(search_vm)
      puts "Added SearchViewModel.swift to project"
    else
      puts "SearchViewModel.swift already in project"
    end
    
    # Check and add SearchResultsView.swift
    search_results = search_group.files.find { |f| f.path == 'SearchResultsView.swift' }
    unless search_results
      search_results = search_group.new_file('SearchResultsView.swift')
      target.source_build_phase.add_file_reference(search_results)
      puts "Added SearchResultsView.swift to project"
    else
      puts "SearchResultsView.swift already in project"
    end
  else
    # Create Search group if it doesn't exist
    search_group = features_group.new_group('Search', 'Search')
    puts "Created Search group"
    
    # Add all Search files
    ['SearchViewController.swift', 'SearchView.swift', 'SearchViewModel.swift', 'SearchResultsView.swift'].each do |file|
      file_ref = search_group.new_file(file)
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added #{file} to project"
    end
  end
  
  # Add Git folder and files
  git_group = features_group.children.find do |child|
    child.is_a?(Xcodeproj::Project::Object::PBXGroup) && 
    (child.name == 'Git' || child.path == 'Git')
  end
  
  if git_group
    puts "Found Git group"
    
    # Check and add GitViewController.swift
    git_vc = git_group.files.find { |f| f.path == 'GitViewController.swift' }
    unless git_vc
      git_vc = git_group.new_file('GitViewController.swift')
      target.source_build_phase.add_file_reference(git_vc)
      puts "Added GitViewController.swift to project"
    else
      puts "GitViewController.swift already in project"
    end
    
    # Check and add GitViewModel.swift
    git_vm = git_group.files.find { |f| f.path == 'GitViewModel.swift' }
    unless git_vm
      git_vm = git_group.new_file('GitViewModel.swift')
      target.source_build_phase.add_file_reference(git_vm)
      puts "Added GitViewModel.swift to project"
    else
      puts "GitViewModel.swift already in project"
    end
  else
    # Create Git group if it doesn't exist
    git_group = features_group.new_group('Git', 'Git')
    puts "Created Git group"
    
    # Add all Git files
    ['GitViewController.swift', 'GitViewModel.swift'].each do |file|
      file_ref = git_group.new_file(file)
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added #{file} to project"
    end
  end
  
else
  puts "ERROR: Features group not found!"
end

# Save the project
project.save
puts "Project saved successfully!"