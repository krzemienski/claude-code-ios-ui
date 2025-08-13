#!/usr/bin/env python3
"""
Script to add missing Swift files to the Xcode project
"""
import os
import re
import uuid
import sys

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def find_swift_files(root_dir):
    """Find all Swift files in the project"""
    swift_files = []
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Skip hidden directories and build directories
        dirnames[:] = [d for d in dirnames if not d.startswith('.') and d != 'Build']
        for filename in filenames:
            if filename.endswith('.swift'):
                full_path = os.path.join(dirpath, filename)
                relative_path = os.path.relpath(full_path, root_dir)
                swift_files.append((filename, relative_path))
    return swift_files

def is_file_in_project(pbxproj_content, filename):
    """Check if a file is already in the project"""
    return filename in pbxproj_content

def add_files_to_project(pbxproj_path, swift_files):
    """Add missing Swift files to the Xcode project"""
    
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Find the main group ID and target ID
    main_group_match = re.search(r'mainGroup = ([A-F0-9]{24});', content)
    if not main_group_match:
        print("Could not find main group")
        return
    main_group_id = main_group_match.group(1)
    
    # Find the sources build phase
    sources_match = re.search(r'/\* Sources \*/ = \{\s+isa = PBXSourcesBuildPhase;[^}]+files = \([^)]+\);', content, re.DOTALL)
    if not sources_match:
        print("Could not find sources build phase")
        return
    
    # Track what we need to add
    files_to_add = []
    file_refs_to_add = []
    build_files_to_add = []
    
    for filename, relative_path in swift_files:
        if not is_file_in_project(content, filename):
            print(f"Adding {filename} to project...")
            
            # Generate UUIDs
            file_ref_id = generate_uuid()
            build_file_id = generate_uuid()
            
            # Create PBXFileReference
            file_ref = f"\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{filename}\"; sourceTree = \"<group>\"; }};"
            file_refs_to_add.append(file_ref)
            
            # Create PBXBuildFile
            build_file = f"\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};"
            build_files_to_add.append(build_file)
            
            # Track for adding to groups and build phases
            files_to_add.append((file_ref_id, build_file_id, filename))
    
    if not files_to_add:
        print("No files to add")
        return
    
    # Add PBXFileReferences
    file_ref_section = re.search(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', content, re.DOTALL)
    if file_ref_section:
        new_refs = '\n'.join(file_refs_to_add)
        content = content.replace(file_ref_section.group(0), 
                                  f"/* Begin PBXFileReference section */\n{file_ref_section.group(1)}{new_refs}\n/* End PBXFileReference section */")
    
    # Add PBXBuildFiles
    build_file_section = re.search(r'/\* Begin PBXBuildFile section \*/(.*?)/\* End PBXBuildFile section \*/', content, re.DOTALL)
    if build_file_section:
        new_builds = '\n'.join(build_files_to_add)
        content = content.replace(build_file_section.group(0),
                                  f"/* Begin PBXBuildFile section */\n{build_file_section.group(1)}{new_builds}\n/* End PBXBuildFile section */")
    
    # Add to main group children
    main_group_section = re.search(rf'{main_group_id}[^{{]*{{[^}}]*children = \(([^)]*)\);', content, re.DOTALL)
    if main_group_section:
        children = main_group_section.group(1)
        new_children = []
        for file_ref_id, _, filename in files_to_add:
            new_children.append(f"\t\t\t\t{file_ref_id} /* {filename} */,")
        
        new_children_str = '\n'.join(new_children)
        updated_children = f"{children}\n{new_children_str}"
        
        old_section = main_group_section.group(0)
        new_section = old_section.replace(children, updated_children)
        content = content.replace(old_section, new_section)
    
    # Add to sources build phase
    sources_section = re.search(r'(/\* Sources \*/ = \{[^}]+files = \()([^)]+)(\);)', content, re.DOTALL)
    if sources_section:
        files_list = sources_section.group(2)
        new_sources = []
        for _, build_file_id, filename in files_to_add:
            new_sources.append(f"\t\t\t\t{build_file_id} /* {filename} in Sources */,")
        
        new_sources_str = '\n'.join(new_sources)
        updated_files = f"{files_list}\n{new_sources_str}"
        
        content = content[:sources_section.start(2)] + updated_files + content[sources_section.end(2):]
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print(f"Added {len(files_to_add)} files to the project")

if __name__ == "__main__":
    project_dir = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS"
    pbxproj_path = os.path.join(project_dir, "ClaudeCodeUI.xcodeproj", "project.pbxproj")
    
    # Find all Swift files
    swift_files = find_swift_files(project_dir)
    print(f"Found {len(swift_files)} Swift files")
    
    # Add missing files to project
    add_files_to_project(pbxproj_path, swift_files)
    print("Done!")