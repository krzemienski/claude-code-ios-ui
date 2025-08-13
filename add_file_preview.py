#!/usr/bin/env python3
"""Script to add FilePreviewViewController to Xcode project"""

import re
import uuid

def generate_xcode_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_file_preview():
    project_file = "/Users/nick/Documents/claude-code-ios-ui/ClaudeCodeUI-iOS/ClaudeCodeUI.xcodeproj/project.pbxproj"
    
    # Read the project file
    with open(project_file, 'r') as f:
        content = f.read()
    
    # Generate UUID for FilePreviewViewController
    file_preview_uuid = generate_xcode_uuid()
    file_preview_build_uuid = generate_xcode_uuid()
    
    # Find where to insert the file reference
    # Look for FileExplorerViewController.swift reference
    file_ref_pattern = r'(6DC926D40F67449184C94AA8 /\* FileExplorerViewController\.swift \*/ = {isa = PBXFileReference[^}]+};\n)'
    
    # Create the new file reference
    new_file_ref = f'\t\t{file_preview_uuid} /* FilePreviewViewController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FilePreviewViewController.swift; sourceTree = "<group>"; }};\n'
    
    # Insert the file reference
    content = re.sub(file_ref_pattern, r'\1' + new_file_ref, content)
    
    # Find where to add the build file
    # Look for FileExplorerViewController build file
    build_file_pattern = r'([A-F0-9]+ /\* FileExplorerViewController\.swift in Sources \*/ = {isa = PBXBuildFile[^}]+};\n)'
    
    # Create the new build file
    new_build_file = f'\t\t{file_preview_build_uuid} /* FilePreviewViewController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_preview_uuid} /* FilePreviewViewController.swift */; }};\n'
    
    # Insert the build file
    content = re.sub(build_file_pattern, r'\1' + new_build_file, content)
    
    # Find the FileExplorer group and add FilePreviewViewController
    # Look for FileExplorer group with FileExplorerViewController
    file_explorer_pattern = r'(6DC926D40F67449184C94AA8 /\* FileExplorerViewController\.swift \*/,)'
    
    # Add FilePreviewViewController to the group
    new_file_ref_in_group = f'\n\t\t\t\t{file_preview_uuid} /* FilePreviewViewController.swift */,'
    
    # Insert in the FileExplorer group
    content = re.sub(file_explorer_pattern, r'\1' + new_file_ref_in_group, content)
    
    # Find the Sources build phase and add the file
    # Look for the Sources build phase containing FileExplorerViewController
    sources_pattern = r'([A-F0-9]+ /\* FileExplorerViewController\.swift in Sources \*/,)'
    
    # Add the build file reference to Sources
    new_source_ref = f'\n\t\t\t\t{file_preview_build_uuid} /* FilePreviewViewController.swift in Sources */,'
    
    # Insert in the Sources build phase
    content = re.sub(sources_pattern, r'\1' + new_source_ref, content)
    
    # Write the modified content back
    with open(project_file, 'w') as f:
        f.write(content)
    
    print(f"Successfully added FilePreviewViewController.swift to Xcode project")
    print(f"File reference UUID: {file_preview_uuid}")
    print(f"Build file UUID: {file_preview_build_uuid}")

if __name__ == "__main__":
    add_file_preview()