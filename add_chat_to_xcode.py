#!/usr/bin/env python3
"""Script to add ChatViewController.swift to Xcode project"""

import re
import uuid

def generate_xcode_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_chat_view_controller():
    project_file = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUIDs for the new references
    chat_vc_uuid = generate_xcode_uuid()
    chat_vc_build_uuid = generate_xcode_uuid()
    
    # Find where to insert the file reference
    # Look for the last swift file reference in the PBXFileReference section
    file_ref_pattern = r'(1D1A2B732C60A1230001A234 /\* FileNode\.swift \*/ = {isa = PBXFileReference[^}]+};\n)'
    
    # Create the new file reference
    new_file_ref = f'\t\t{chat_vc_uuid} /* ChatViewController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ChatViewController.swift; sourceTree = "<group>"; }};\n'
    
    # Insert the file reference
    content = re.sub(file_ref_pattern, r'\1' + new_file_ref, content)
    
    # Find where to add the build file
    # Look for the last build file entry
    build_file_pattern = r'(1D1A2B722C60A1230001A234 /\* FileNode\.swift in Sources \*/ = {isa = PBXBuildFile[^}]+};\n)'
    
    # Create the new build file
    new_build_file = f'\t\t{chat_vc_build_uuid} /* ChatViewController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {chat_vc_uuid} /* ChatViewController.swift */; }};\n'
    
    # Insert the build file
    content = re.sub(build_file_pattern, r'\1' + new_build_file, content)
    
    # Find the Features group and add ChatViewController to the Chat folder
    # Look for where Chat folder should be in the Features group
    features_pattern = r'(/\* Features \*/ = {\s+isa = PBXGroup;\s+children = \(\s+)'
    
    # We need to find if there's already a Chat group
    # If not, we'll need to create it
    chat_group_uuid = generate_xcode_uuid()
    
    # Create Chat group
    chat_group = f'\t\t\t\t{chat_group_uuid} /* Chat */,\n'
    
    # Insert Chat group reference in Features
    content = re.sub(features_pattern, r'\1' + chat_group, content)
    
    # Now add the Chat group definition
    # Find where to add it (after the last group definition)
    groups_end_pattern = r'(/\* End PBXGroup section \*/)'
    
    chat_group_def = f'''\t\t{chat_group_uuid} /* Chat */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{chat_vc_uuid} /* ChatViewController.swift */,
\t\t\t);
\t\t\tpath = Chat;
\t\t\tsourceTree = "<group>";
\t\t}};
'''
    
    # Insert the group definition
    content = re.sub(groups_end_pattern, chat_group_def + r'\n\1', content)
    
    # Find the Sources build phase and add the file
    # Look for the Sources build phase files section
    sources_pattern = r'(/\* Sources \*/ = {\s+isa = PBXSourcesBuildPhase;\s+buildActionMask = \d+;\s+files = \([^)]+)'
    
    # Add the build file reference to Sources
    new_source_ref = f'\t\t\t\t{chat_vc_build_uuid} /* ChatViewController.swift in Sources */,\n'
    
    # Insert in the Sources build phase
    def add_to_sources(match):
        return match.group(1) + new_source_ref
    
    content = re.sub(sources_pattern, add_to_sources, content, count=1)
    
    # Write the modified content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Successfully added ChatViewController.swift to Xcode project")
    print(f"File reference UUID: {chat_vc_uuid}")
    print(f"Build file UUID: {chat_vc_build_uuid}")
    print(f"Chat group UUID: {chat_group_uuid}")

if __name__ == "__main__":
    add_chat_view_controller()