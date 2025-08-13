#!/usr/bin/env python3
"""Script to add FileExplorerViewController and TerminalViewController to Xcode project"""

import re
import uuid

def generate_xcode_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_view_controllers():
    project_file = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for FileExplorerViewController
    file_explorer_uuid = generate_xcode_uuid()
    file_explorer_build_uuid = generate_xcode_uuid()
    file_explorer_group_uuid = generate_xcode_uuid()
    
    # Generate UUIDs for TerminalViewController
    terminal_uuid = generate_xcode_uuid()
    terminal_build_uuid = generate_xcode_uuid()
    terminal_group_uuid = generate_xcode_uuid()
    
    # Find where to insert the file references
    # Look for the last swift file reference in the PBXFileReference section
    file_ref_pattern = r'(908A0FC3A7394AEDABD41BAE /\* ChatViewController\.swift \*/ = {isa = PBXFileReference[^}]+};\n)'
    
    # Create the new file references
    new_file_refs = f'''\t\t{file_explorer_uuid} /* FileExplorerViewController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileExplorerViewController.swift; sourceTree = "<group>"; }};
\t\t{terminal_uuid} /* TerminalViewController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TerminalViewController.swift; sourceTree = "<group>"; }};
'''
    
    # Insert the file references
    content = re.sub(file_ref_pattern, r'\1' + new_file_refs, content)
    
    # Find where to add the build files
    # Look for the last build file entry
    build_file_pattern = r'(704436B7DE1D469495491C6D /\* ChatViewController\.swift in Sources \*/ = {isa = PBXBuildFile[^}]+};\n)'
    
    # Create the new build files
    new_build_files = f'''\t\t{file_explorer_build_uuid} /* FileExplorerViewController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_explorer_uuid} /* FileExplorerViewController.swift */; }};
\t\t{terminal_build_uuid} /* TerminalViewController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {terminal_uuid} /* TerminalViewController.swift */; }};
'''
    
    # Insert the build files
    content = re.sub(build_file_pattern, r'\1' + new_build_files, content)
    
    # Find the Features group and add FileExplorer and Terminal groups
    features_pattern = r'(/\* Features \*/ = {\s+isa = PBXGroup;\s+children = \(\s+CAC97E9AD0264C45900DE34A /\* Chat \*/,)'
    
    # Create group references
    new_groups = f'''\t\t\t\t{file_explorer_group_uuid} /* FileExplorer */,
\t\t\t\t{terminal_group_uuid} /* Terminal */,'''
    
    # Insert group references in Features
    content = re.sub(features_pattern, r'\1\n' + new_groups, content)
    
    # Now add the group definitions
    # Find where to add them (before End PBXGroup section)
    groups_end_pattern = r'(/\* End PBXGroup section \*/)'
    
    groups_def = f'''\t\t{file_explorer_group_uuid} /* FileExplorer */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{file_explorer_uuid} /* FileExplorerViewController.swift */,
\t\t\t);
\t\t\tpath = FileExplorer;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{terminal_group_uuid} /* Terminal */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{terminal_uuid} /* TerminalViewController.swift */,
\t\t\t);
\t\t\tpath = Terminal;
\t\t\tsourceTree = "<group>";
\t\t}};
'''
    
    # Insert the group definitions
    content = re.sub(groups_end_pattern, groups_def + r'\n\1', content)
    
    # Find the Sources build phase and add the files
    # Look for the Sources build phase files section containing our Chat build file
    sources_pattern = r'(704436B7DE1D469495491C6D /\* ChatViewController\.swift in Sources \*/,)'
    
    # Add the build file references to Sources
    new_source_refs = f'''\n\t\t\t\t{file_explorer_build_uuid} /* FileExplorerViewController.swift in Sources */,
\t\t\t\t{terminal_build_uuid} /* TerminalViewController.swift in Sources */,'''
    
    # Insert in the Sources build phase
    content = re.sub(sources_pattern, r'\1' + new_source_refs, content)
    
    # Write the modified content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Successfully added FileExplorerViewController and TerminalViewController to Xcode project")
    print(f"FileExplorer UUID: {file_explorer_uuid}")
    print(f"Terminal UUID: {terminal_uuid}")

if __name__ == "__main__":
    add_view_controllers()