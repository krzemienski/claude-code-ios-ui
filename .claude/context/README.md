# Project Context Storage

This directory contains saved project context for the Claude Code iOS UI application, enabling better continuity across sessions and improved agent coordination.

## Current Context Files

### project-context-2025-01-12.json
- **Version**: 1.0.0
- **Created**: 2025-01-12
- **Purpose**: Comprehensive project state capture for debugging backend-iOS communication
- **Key Focus**: 
  - Project and session (chat) management
  - WebSocket real-time messaging
  - API endpoint verification
  - UI visualization testing

## Context Structure

Each context file contains:
1. **Project Overview** - Goals, architecture, dependencies
2. **Current State** - Features, work in progress, known issues
3. **Design Decisions** - Architecture patterns, API design, UI theme
4. **Code Patterns** - Conventions and best practices
5. **API Documentation** - All endpoints and protocols
6. **File Structure** - Key files and organization
7. **Testing Strategy** - Test scenarios and coverage
8. **Agent Coordination** - History and recommendations
9. **Future Roadmap** - Immediate, short-term, and long-term goals

## Usage

### Restoring Context
To restore context in a new session:
1. Read the latest context file
2. Use it to understand project state
3. Continue work based on saved decisions and patterns

### Updating Context
After significant changes:
1. Create a new timestamped context file
2. Include changes and new decisions
3. Reference previous context for continuity

### Context Versioning
- Files are named with ISO date format: `project-context-YYYY-MM-DD.json`
- Each file includes a version number
- Maintain backward compatibility when updating structure

## Agent Coordination

This context enables:
- **Debugger agents** - Understanding current issues and system state
- **Performance agents** - Baseline metrics and optimization targets
- **Test agents** - Test scenarios and coverage requirements
- **Architecture agents** - Design decisions and patterns
- **Context managers** - Maintaining project continuity

## Quick Reference

### Current Focus Areas
1. Backend-iOS communication debugging
2. Project listing functionality
3. Session/chat navigation within projects
4. Real-time message streaming
5. iOS app visualization and screenshots

### Key Technologies
- **iOS**: Swift 5.9, UIKit, SwiftUI, MVVM, SwiftData
- **Backend**: Node.js, Express, WebSocket, SQLite
- **Theme**: Cyberpunk (Cyan #00D9FF, Pink #FF006E)

### Critical Files
- Backend: `server.js`, `routes/chat.js`, `routes/projects.js`
- iOS: `APIClient.swift`, `WebSocketManager.swift`, `ProjectsViewController.swift`

## Maintenance

Update this context when:
- Major architectural decisions are made
- Significant features are completed
- New patterns are established
- Agent coordination strategies change
- Project direction shifts