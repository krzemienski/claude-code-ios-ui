# Backend API Analysis & iOS Implementation Planning

## Project Overview
Conduct comprehensive analysis of Node.js backend server, document all API endpoints, identify gaps in iOS implementation, and create detailed fix tasks for @agent-ios-swift-expert to implement. The goal is a fully functional iOS app that properly uses ALL backend endpoints with correct authentication via localhost.

## Your Role vs @agent-ios-swift-expert Role
- **YOU**: Analyze, document, identify gaps, create detailed tasks
- **@agent-ios-swift-expert**: Implement fixes, test in simulator, verify with localhost

## Project Requirements
- **Complete backend analysis** - Document every endpoint
- **Thorough iOS gap analysis** - Find all missing/incorrect implementations  
- **Detailed task creation** - Clear implementation instructions for @agent-ios-swift-expert
- **Test criteria definition** - How to verify each fix works
- **Localhost verification** - All fixes must work with running backend

## Phase 1: Backend Node.js Server Analysis & Documentation

### Objective
Discover and document ALL API endpoints that exist in the Node.js backend server.

### Tasks
1. **Start the localhost backend server**:
   ```bash
   cd backend
   npm install
   npm start  # or npm run dev
   # Verify server is running (usually http://localhost:3000)
   ```

2. **Explore backend directory structure**:
   - Locate all route files (routes/, api/, controllers/)
   - Identify middleware (auth, validation, etc.)
   - Find database models/schemas
   - Review configuration files

3. **Map all API endpoints**:
   - Extract from Express/Fastify/Koa route definitions
   - Document REST endpoints (GET, POST, PUT, DELETE, PATCH)
   - Identify WebSocket connections if any
   - Note GraphQL schemas if applicable

4. **Document each endpoint** with:
   - Full endpoint path (e.g., `/api/v1/projects/:id/sessions`)
   - HTTP method
   - Required authentication (Bearer token, API key, etc.)
   - Request headers
   - Request body schema
   - Response structure
   - Error responses
   - Rate limiting rules

5. **Create working cURL examples** for every endpoint:
   ```bash
   # Example: Get all projects
   curl -X GET http://localhost:3000/api/v1/projects \
     -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     -H "Content-Type: application/json"
   
   # Example: Create new session
   curl -X POST http://localhost:3000/api/v1/projects/123/sessions \
     -H "Authorization: Bearer YOUR_TOKEN_HERE" \
     -H "Content-Type: application/json" \
     -d '{"name": "New Session", "metadata": {}}'
   ```

6. **Test each cURL locally** against running backend:
   - Execute each cURL command
   - Verify responses match documentation
   - Note any undocumented behaviors

7. **Save all documentation** to `@CLAUDE.md`

## Phase 2: iOS Swift App - ANALYZE AND CREATE FIX PLAN

### Objective
**IDENTIFY** all missing or incorrect API implementations and create detailed fix tasks for @agent-ios-swift-expert.

### Analysis Workflow for EVERY Backend Endpoint
1. **Check if endpoint is implemented in iOS**
2. **Document the gap/issue**:
   - Missing endpoint entirely
   - Incorrect implementation
   - Missing authentication
   - Wrong data models
3. **Create detailed fix task** for @agent-ios-swift-expert
4. **Include in task**:
   - Exact endpoint details
   - Current issue/gap
   - Required implementation
   - Test criteria

### Handoff to @agent-ios-swift-expert
After completing analysis and creating all tasks:
1. **Provide @agent-ios-swift-expert with**:
   - Complete @CLAUDE.md documentation
   - Full list of implementation tasks
   - Backend endpoint specifications
   - Authentication requirements
   - Test criteria for each fix

2. **@agent-ios-swift-expert will**:
   - Implement all missing endpoints
   - Fix all incorrect implementations
   - Add proper authentication
   - Create/update data models
   - Build and test each fix in simulator
   - Verify against localhost backend
   - Take screenshots of working features

### Implementation Checklist for @agent-ios-swift-expert
Each endpoint task should specify:
- [ ] Exact API endpoint path and method
- [ ] Required authentication details
- [ ] Request body structure (with examples)
- [ ] Expected response format
- [ ] Error cases to handle
- [ ] Where to implement in iOS codebase
- [ ] How to test with localhost backend
- [ ] Success criteria for verification

### Task Templates for Common Issues

1. **Missing API Endpoint Task**:
   ```
   Task: Implement [ENDPOINT_NAME] in iOS app
   Endpoint: [HTTP_METHOD] /api/v1/[path]
   Current Status: Not implemented
   Required Implementation:
   - Add method to [Service].swift
   - Include auth header: Bearer token
   - Request body: [specify structure]
   - Response type: [specify model]
   Test Criteria:
   - Function successfully calls localhost endpoint
   - Response data properly parsed
   - UI updates with data
   ```

2. **Authentication Issue Task**:
   ```
   Task: Fix missing auth on [ENDPOINT_NAME]
   Current Issue: 401 Unauthorized errors
   Required Fix:
   - Add Authorization header
   - Format: "Bearer [token]"
   - Token source: Keychain/UserDefaults
   Test: Endpoint returns 200 OK
   ```

3. **Incorrect Endpoint Path Task**:
   ```
   Task: Update incorrect endpoint path
   Current Path: /old/path
   Correct Path: /api/v1/correct/path
   File Location: [Service].swift line [X]
   Test: Verify endpoint reaches backend
   ```

## Phase 3: End-to-End Testing (For @agent-ios-swift-expert)

### Objective
@agent-ios-swift-expert will validate the COMPLETE WORKING application after implementing all fixes.

### Test Protocol for @agent-ios-swift-expert
1. **Prerequisites**:
   - Localhost backend is running
   - All iOS code fixes are implemented
   - App builds without errors

2. **Complete Flow Test**:
   - Launch app in iOS Simulator
   - Test authentication with localhost
   - Verify every API endpoint works
   - Test full user journey
   - Capture screenshots of success

3. **Validation Checklist**:
   - [ ] Login/Authentication works
   - [ ] All GET endpoints load data
   - [ ] All POST endpoints create data
   - [ ] All PUT/PATCH endpoints update data
   - [ ] All DELETE endpoints remove data
   - [ ] WebSocket connections work (if any)
   - [ ] Data persists correctly
   - [ ] Error handling works properly

## Your Deliverables (For Handoff to @agent-ios-swift-expert)

1. **@CLAUDE.md Documentation**:
   - Complete backend API reference
   - Every endpoint with cURL examples
   - Authentication flow details
   - Response/error examples
   - Setup instructions for localhost

2. **Detailed Task List** (150+ tasks):
   - Specific implementation tasks for each gap
   - Clear success criteria
   - Test instructions
   - Priority ordering

3. **Gap Analysis Report**:
   - Endpoints missing in iOS
   - Incorrect implementations found
   - Authentication issues identified
   - Data model mismatches

4. **Handoff Package** for @agent-ios-swift-expert:
   - All documentation
   - Prioritized task list
   - Test credentials
   - Localhost setup verified
   - Expected outcomes defined

## @agent-ios-swift-expert's Deliverables

1. **WORKING iOS APP** with:
   - All endpoints properly implemented
   - Complete authentication flow
   - Error handling
   - Localhost backend integration

2. **Test Evidence**:
   - Screenshots of every working feature
   - API call success verification
   - Full flow completion proof

3. **Implementation Summary**:
   - Code changes made
   - Issues resolved
   - Any remaining concerns

## Execution Instructions

1. **Start localhost backend first**
2. **Analyze backend endpoints thoroughly**
3. **Document all endpoints in @CLAUDE.md**
4. **Test all endpoints with cURL**
5. **Analyze iOS codebase for gaps**
6. **Create comprehensive fix tasks**
7. **Hand off to @agent-ios-swift-expert with**:
   - Complete endpoint documentation
   - Detailed implementation tasks
   - Test criteria for each endpoint
8. **@agent-ios-swift-expert executes**:
   - Implements all fixes
   - Tests in simulator with localhost
   - Verifies each endpoint works
   - Provides screenshot evidence

## Planning & Task Management Requirements

### Sequential Thinking Process
Generate **200 sequential thoughts** covering:
- Backend endpoint analysis (thoughts 1-50)
- iOS implementation gap analysis (thoughts 51-100)
- Task creation for @agent-ios-swift-expert (thoughts 101-150)
- Test planning and verification strategy (thoughts 151-200)

### Task Creation for @agent-ios-swift-expert
Create **150+ detailed to-dos** organized as:

1. **Endpoint Implementation Tasks** (80-100 tasks)
   ```
   Task: Implement GET /api/v1/projects endpoint
   - Current: Not implemented in iOS
   - Required: Add to ProjectService.swift
   - Auth: Bearer token required
   - Response: Array of Project objects
   - Test: Load projects list, verify against backend
   ```

2. **Authentication Fix Tasks** (20-30 tasks)
   ```
   Task: Add auth header to all API calls
   - Current: Some endpoints missing auth
   - Required: Add Bearer token to headers
   - Test: Verify 401 errors resolved
   ```

3. **Testing & Verification Tasks** (30-40 tasks)
   ```
   Task: Test full project → session flow
   - Steps: Login → List projects → Select → View sessions
   - Verify: All data loads from localhost
   - Screenshot: Each successful step
   ```

## Handoff Documentation for @agent-ios-swift-expert

### What You'll Provide:
1. **@CLAUDE.md** with:
   - Every backend endpoint documented
   - cURL examples that work
   - Authentication flow explained
   - Expected responses

2. **Task List** with:
   - Specific implementation requirements
   - Exact code locations to modify
   - Test criteria for success
   - Priority order for fixes

3. **Testing Protocol**:
   - Localhost backend connection details
   - Test user credentials
   - Step-by-step verification process
   - Required screenshots

### What @agent-ios-swift-expert Will Deliver:
1. **WORKING iOS APP** with all endpoints implemented
2. **Screenshot evidence** of each working feature
3. **Code changes summary** for each fix
4. **Verification** that all endpoints work with localhost

## Workflow Summary

```
Phase 1: Backend Analysis (You)
    ↓
Document all endpoints in @CLAUDE.md
    ↓
Phase 2: iOS Gap Analysis (You)
    ↓
Create detailed fix tasks
    ↓
Hand off to @agent-ios-swift-expert
    ↓
Phase 3: Implementation (@agent-ios-swift-expert)
    ↓
Phase 4: Verification (@agent-ios-swift-expert)
    ↓
Delivery: Working iOS app with localhost backend
```

## REMEMBER: 
- You ANALYZE and DOCUMENT
- You CREATE DETAILED TASKS
- @agent-ios-swift-expert IMPLEMENTS and FIXES
- Everything must work with LOCALHOST BACKEND

## Phase 3: End-to-End Testing Protocol

### Objective
Validate complete application flow with emphasis on data persistence.

### Test Sequence
1. **Launch application** on iOS Simulator
2. **Navigate to projects list**
   - Verify all project names display correctly
   - Confirm project metadata loads
3. **Select a project** that contains sessions
4. **View sessions list**
   - Verify session names and timestamps
   - Confirm session metadata
5. **Select a session** with existing message history
6. **Verify historical messages**:
   - All previous messages load
   - Correct sender attribution
   - Proper timestamp display
   - Message formatting preserved
7. **Send new message** (Message 1):
   - Type and send message
   - Observe real-time streaming response
   - Wait for complete response
   - Verify UI updates correctly
8. **Send follow-up message** (Message 2):
   - Ensure conversation context maintained
   - Verify streaming works again
   - Wait for complete response
9. **Exit session** (navigate back)
10. **Re-enter same session**:
    - Verify Message 1 & 2 persist
    - Confirm all messages in correct order
    - Check timestamps are preserved
11. **Force quit app** and relaunch
12. **Navigate back to same session**:
    - Verify complete persistence after app restart

### Validation Points
- Screenshot each major step
- Document any data loss or inconsistencies
- Note response times and performance
- Record any error messages or crashes

## Planning & Task Management Requirements

### Sequential Thinking Process
Generate **200 sequential thoughts** covering:
- Architecture analysis (thoughts 1-50)
- API endpoint mapping (thoughts 51-100)
- Testing strategy (thoughts 101-150)
- Implementation planning (thoughts 151-200)

### Task Creation
Create **150+ detailed to-dos** organized by:
1. **API Documentation Tasks** (40-50 tasks)
   - One task per endpoint discovered
   - Subtasks for headers, body, response

2. **Code Analysis Tasks** (40-50 tasks)
   - File-by-file analysis tasks
   - Compliance verification tasks
   - Refactoring recommendations

3. **Testing Tasks** (50-60 tasks)
   - Step-by-step test execution
   - Screenshot capture tasks
   - Validation checkpoints

4. **Bug Fix & Improvement Tasks** (20-30 tasks)
   - Based on discovered issues
   - Performance optimizations
   - Security enhancements

## Deliverables

1. **@CLAUDE.md file** containing:
   - Complete API documentation
   - cURL examples for every endpoint
   - Authentication flow diagram
   - Troubleshooting guide

2. **Test Results Report** including:
   - Screenshot evidence of complete flow
   - Performance metrics
   - Bug report with severity levels
   - Data persistence validation results

3. **Code Compliance Report** with:
   - File-by-file analysis results
   - Recommendations for improvements
   - Security vulnerability assessment
   - Best practices adherence score

4. **Working iOS Simulator Build** demonstrating:
   - Complete application flow
   - Proper data persistence
   - Real-time message streaming
   - Error handling capabilities

## Execution Notes

- Begin with complete codebase analysis
- Document findings incrementally in @CLAUDE.md
- Test on iOS Simulator (iPhone 15 Pro recommended)
- Capture screenshots at each validation point
- Focus on data persistence across all operations
- Ensure authentication works throughout entire flow