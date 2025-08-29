#!/usr/bin/env node

import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:3004';

// Test search endpoint
async function testSearch() {
  console.log('🧪 Testing search endpoint...\n');
  
  // Get list of projects first
  const projectsResponse = await fetch(`${BASE_URL}/api/projects`);
  const projects = await projectsResponse.json();
  
  if (projects.length === 0) {
    console.log('❌ No projects found');
    return;
  }
  
  // Find iOS project
  const iosProject = projects.find(p => 
    p.name.includes('claude-code-ios-ui') || 
    p.displayName?.includes('claude-code-ios-ui')
  );
  
  if (!iosProject) {
    console.log('⚠️ iOS project not found, using first project:', projects[0].name);
  }
  
  const projectName = iosProject?.name || projects[0].name;
  console.log(`📁 Using project: ${projectName}\n`);
  
  // Test cases
  const testCases = [
    {
      name: 'Search for APIClient in Swift files',
      body: {
        query: 'APIClient',
        scope: 'project',
        fileTypes: ['swift'],
        caseSensitive: false,
        useRegex: false
      }
    },
    {
      name: 'Search for WebSocket with case sensitivity',
      body: {
        query: 'WebSocket',
        scope: 'project',
        fileTypes: ['swift'],
        caseSensitive: true,
        useRegex: false
      }
    },
    {
      name: 'Search with regex pattern',
      body: {
        query: 'func\\s+\\w+\\s*\\(',
        scope: 'project',
        fileTypes: ['swift'],
        caseSensitive: false,
        useRegex: true,
        maxResults: 10
      }
    },
    {
      name: 'Search in all file types',
      body: {
        query: 'TODO',
        scope: 'project',
        fileTypes: [],
        caseSensitive: false,
        useRegex: false,
        maxResults: 20
      }
    }
  ];
  
  for (const testCase of testCases) {
    console.log(`\n🔍 Test: ${testCase.name}`);
    console.log('   Request:', JSON.stringify(testCase.body, null, 2));
    
    try {
      const startTime = Date.now();
      const response = await fetch(`${BASE_URL}/api/projects/${projectName}/search`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(testCase.body)
      });
      
      if (!response.ok) {
        console.log(`   ❌ Error: ${response.status} ${response.statusText}`);
        const errorText = await response.text();
        console.log(`   Response: ${errorText}`);
        continue;
      }
      
      const result = await response.json();
      const elapsed = Date.now() - startTime;
      
      console.log(`   ✅ Success!`);
      console.log(`   - Found ${result.totalCount} results`);
      console.log(`   - Search time: ${result.searchTime?.toFixed(3)}s`);
      console.log(`   - Total request time: ${elapsed}ms`);
      
      if (result.results && result.results.length > 0) {
        console.log(`   - First result: ${result.results[0].fileName}:${result.results[0].lineNumber}`);
        console.log(`     "${result.results[0].lineContent.trim()}"`);
      }
      
      if (result.truncated) {
        console.log(`   ⚠️ Results truncated at ${result.totalCount} items`);
      }
      
    } catch (error) {
      console.log(`   ❌ Error: ${error.message}`);
    }
  }
  
  // Test cache
  console.log('\n\n🔄 Testing cache performance...');
  const cacheTestBody = {
    query: 'SessionListViewController',
    scope: 'project',
    fileTypes: ['swift'],
    caseSensitive: false,
    useRegex: false
  };
  
  // First request (cold)
  const coldStart = Date.now();
  await fetch(`${BASE_URL}/api/projects/${projectName}/search`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(cacheTestBody)
  });
  const coldTime = Date.now() - coldStart;
  
  // Second request (cached)
  const warmStart = Date.now();
  await fetch(`${BASE_URL}/api/projects/${projectName}/search`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(cacheTestBody)
  });
  const warmTime = Date.now() - warmStart;
  
  console.log(`   Cold request: ${coldTime}ms`);
  console.log(`   Cached request: ${warmTime}ms`);
  console.log(`   Speed improvement: ${((coldTime - warmTime) / coldTime * 100).toFixed(1)}%`);
  
  console.log('\n\n✅ All tests completed!');
}

// Run tests
testSearch().catch(console.error);