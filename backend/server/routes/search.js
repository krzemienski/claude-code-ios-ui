import express from 'express';
import { promises as fs } from 'fs';
import path from 'path';
import { extractProjectDirectory } from '../projects.js';
import { exec } from 'child_process';
import { promisify } from 'util';

const router = express.Router();
const execAsync = promisify(exec);

// Cache for search results (5 minutes TTL)
const searchCache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

// Helper to get cache key
function getCacheKey(projectName, query, scope, fileTypes) {
  return `${projectName}_${query}_${scope}_${(fileTypes || []).sort().join(',')}`;
}

// Helper to clean up old cache entries
function cleanupCache() {
  const now = Date.now();
  for (const [key, value] of searchCache.entries()) {
    if (now - value.timestamp > CACHE_TTL) {
      searchCache.delete(key);
    }
  }
}

// Helper function to get the actual project path
async function getActualProjectPath(projectName) {
  try {
    return await extractProjectDirectory(projectName);
  } catch (error) {
    console.error(`Error extracting project directory for ${projectName}:`, error);
    // Fallback to the old method
    return projectName.replace(/-/g, '/');
  }
}

// Helper to escape regex special characters for literal search
function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Helper to get file extension
function getFileExtension(filePath) {
  const ext = path.extname(filePath).slice(1);
  return ext || null;
}

// Search within a single file
async function searchInFile(filePath, query, useRegex, caseSensitive, contextLines = 2) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    const lines = content.split('\n');
    const results = [];
    
    // Create regex pattern
    let pattern;
    if (useRegex) {
      try {
        pattern = new RegExp(query, caseSensitive ? 'g' : 'gi');
      } catch (e) {
        // Invalid regex, fallback to literal search
        pattern = new RegExp(escapeRegex(query), caseSensitive ? 'g' : 'gi');
      }
    } else {
      pattern = new RegExp(escapeRegex(query), caseSensitive ? 'g' : 'gi');
    }
    
    // Search through lines
    lines.forEach((line, index) => {
      if (pattern.test(line)) {
        // Get context lines
        const startLine = Math.max(0, index - contextLines);
        const endLine = Math.min(lines.length - 1, index + contextLines);
        const contextBefore = lines.slice(startLine, index).join('\n');
        const contextAfter = lines.slice(index + 1, endLine + 1).join('\n');
        
        results.push({
          lineNumber: index + 1,
          lineContent: line,
          context: {
            before: contextBefore,
            after: contextAfter
          }
        });
      }
    });
    
    return results;
  } catch (error) {
    // File read error, skip this file
    return [];
  }
}

// Recursively get all files in a directory
async function getAllFiles(dirPath, fileTypes = [], maxDepth = 10, currentDepth = 0) {
  const files = [];
  
  if (currentDepth > maxDepth) {
    return files;
  }
  
  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    
    for (const entry of entries) {
      // Skip common build/dependency directories
      if (entry.name === 'node_modules' || 
          entry.name === '.git' ||
          entry.name === 'dist' ||
          entry.name === 'build' ||
          entry.name === '.next' ||
          entry.name === 'coverage' ||
          entry.name === '__pycache__' ||
          entry.name === '.pytest_cache' ||
          entry.name === 'venv' ||
          entry.name === '.venv') {
        continue;
      }
      
      const fullPath = path.join(dirPath, entry.name);
      
      if (entry.isDirectory()) {
        // Recursively search subdirectories
        const subFiles = await getAllFiles(fullPath, fileTypes, maxDepth, currentDepth + 1);
        files.push(...subFiles);
      } else if (entry.isFile()) {
        // Check if file matches type filter
        if (fileTypes.length > 0) {
          const ext = getFileExtension(entry.name);
          if (ext && fileTypes.includes(ext)) {
            files.push(fullPath);
          }
        } else {
          // No filter, include all text files (skip binary)
          const ext = getFileExtension(entry.name);
          const textExtensions = ['js', 'jsx', 'ts', 'tsx', 'py', 'java', 'c', 'cpp', 'h', 'hpp',
                                  'cs', 'rb', 'go', 'rs', 'php', 'swift', 'kt', 'scala', 'r',
                                  'md', 'txt', 'json', 'xml', 'yaml', 'yml', 'toml', 'ini',
                                  'cfg', 'conf', 'sh', 'bash', 'zsh', 'fish', 'ps1', 'bat',
                                  'html', 'css', 'scss', 'sass', 'less', 'vue', 'svelte'];
          
          if (!ext || textExtensions.includes(ext)) {
            files.push(fullPath);
          }
        }
      }
    }
  } catch (error) {
    console.error(`Error reading directory ${dirPath}:`, error);
  }
  
  return files;
}

// Main search endpoint
router.post('/:projectName/search', async (req, res) => {
  const { projectName } = req.params;
  const { 
    query, 
    scope = 'project',
    fileTypes = [],
    includeArchived = false,
    caseSensitive = false,
    useRegex = false,
    contextLines = 2,
    maxResults = 100
  } = req.body;
  
  // Validate input
  if (!query || typeof query !== 'string' || query.trim().length === 0) {
    return res.status(400).json({ 
      error: 'Search query is required and must be a non-empty string' 
    });
  }
  
  // Clean up cache periodically
  cleanupCache();
  
  // Check cache
  const cacheKey = getCacheKey(projectName, query, scope, fileTypes);
  const cached = searchCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    console.log('🎯 Returning cached search results');
    return res.json(cached.data);
  }
  
  try {
    const startTime = Date.now();
    
    // Get the actual project path
    const projectPath = await getActualProjectPath(projectName);
    
    // Verify project exists
    try {
      await fs.access(projectPath);
    } catch {
      return res.status(404).json({ 
        error: `Project path not found: ${projectPath}` 
      });
    }
    
    console.log(`🔍 Searching in project: ${projectPath}`);
    console.log(`   Query: "${query}", Regex: ${useRegex}, Case-sensitive: ${caseSensitive}`);
    console.log(`   File types: ${fileTypes.length > 0 ? fileTypes.join(', ') : 'all'}`);
    
    // Get all files to search
    const files = await getAllFiles(projectPath, fileTypes);
    console.log(`   Found ${files.length} files to search`);
    
    // Search in all files
    const allResults = [];
    let resultCount = 0;
    
    for (const filePath of files) {
      if (resultCount >= maxResults) {
        break;
      }
      
      const matches = await searchInFile(filePath, query, useRegex, caseSensitive, contextLines);
      
      for (const match of matches) {
        if (resultCount >= maxResults) {
          break;
        }
        
        const relativePath = path.relative(projectPath, filePath);
        
        allResults.push({
          fileName: path.basename(filePath),
          filePath: relativePath,
          absolutePath: filePath,
          lineNumber: match.lineNumber,
          lineContent: match.lineContent,
          context: `${match.context.before}\n${match.lineContent}\n${match.context.after}`,
          projectName: projectName
        });
        
        resultCount++;
      }
    }
    
    const searchTime = (Date.now() - startTime) / 1000;
    
    const response = {
      results: allResults,
      totalCount: allResults.length,
      searchTime: searchTime,
      truncated: resultCount >= maxResults,
      query: query,
      scope: scope,
      fileTypes: fileTypes
    };
    
    // Cache the results
    searchCache.set(cacheKey, {
      data: response,
      timestamp: Date.now()
    });
    
    console.log(`✅ Search completed: ${allResults.length} results in ${searchTime.toFixed(3)}s`);
    
    res.json(response);
    
  } catch (error) {
    console.error('❌ Search error:', error);
    res.status(500).json({ 
      error: error.message || 'Internal server error during search' 
    });
  }
});

// Clear cache endpoint (for testing/debugging)
router.post('/:projectName/search/clear-cache', async (req, res) => {
  searchCache.clear();
  res.json({ success: true, message: 'Search cache cleared' });
});

// Get search suggestions based on recent searches
router.get('/:projectName/search/suggestions', async (req, res) => {
  const { projectName } = req.params;
  
  // For now, return empty suggestions
  // This could be enhanced to track recent searches in a database
  res.json({
    suggestions: [],
    recent: []
  });
});

export default router;