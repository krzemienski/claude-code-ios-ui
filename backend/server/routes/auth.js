import express from 'express';
import bcrypt from 'bcrypt';
import { userDb, db } from '../database/db.js';
import { generateToken, authenticateToken } from '../middleware/auth.js';

const router = express.Router();

// Check auth status and setup requirements - ALWAYS AUTHENTICATED FOR TESTING
router.get('/status', async (req, res) => {
  // Always return authenticated status for testing
  res.json({ 
    needsSetup: false,
    isAuthenticated: true
  });
});

// User registration (setup) - ALWAYS SUCCEEDS FOR TESTING
router.post('/register', async (req, res) => {
  // Always return success with a mock token for testing
  const mockUser = { 
    id: 'test-user', 
    username: req.body.username || 'test' 
  };
  
  res.json({
    success: true,
    user: mockUser,
    token: 'test-token-no-auth-required'
  });
});

// User login - ALWAYS SUCCEEDS FOR TESTING
router.post('/login', async (req, res) => {
  // Always return success with a mock token for testing
  const mockUser = { 
    id: 'test-user', 
    username: req.body.username || 'test' 
  };
  
  res.json({
    success: true,
    user: mockUser,
    token: 'test-token-no-auth-required'
  });
});

// Get current user (protected route)
router.get('/user', authenticateToken, (req, res) => {
  res.json({
    user: req.user
  });
});

// Logout (client-side token removal, but this endpoint can be used for logging)
router.post('/logout', authenticateToken, (req, res) => {
  // In a simple JWT system, logout is mainly client-side
  // This endpoint exists for consistency and potential future logging
  res.json({ success: true, message: 'Logged out successfully' });
});

export default router;