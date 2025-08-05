# Backend Analysis - ClaudeCodeUI

## Overview
This document contains a comprehensive analysis of the claudecodeui backend implementation for reference when building the iOS application.

## Server Structure
- Main server file: `server/index.js`
- Claude CLI integration: `server/claude-cli.js`
- Projects management: `server/projects.js`
- Database: SQLite-based session storage
- Middleware: Authentication and error handling
- Routes: RESTful API endpoints

## Key Technologies
- Express.js for HTTP server
- WebSocket (ws library) for real-time communication
- SQLite for session persistence
- Child process spawning for Claude CLI

## Port Configuration
- Default port: 3001
- WebSocket path: /ws
- API base path: /api

---

## Detailed Analysis
