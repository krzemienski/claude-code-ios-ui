import jwt from 'jsonwebtoken';

// Match the JWT_SECRET from backend/server/middleware/auth.js
const JWT_SECRET = process.env.JWT_SECRET || 'claude-ui-dev-secret-change-in-production';

// Create token for demo user (userId 2 from database)
const token = jwt.sign(
  { 
    userId: 2, 
    username: 'demo' 
  },
  JWT_SECRET
  // No expiration - token lasts forever
);

console.log('JWT Secret being used:', JWT_SECRET);
console.log('\nNew JWT Token for demo user (ID: 2):');
console.log(token);
console.log('\nToken payload:', { userId: 2, username: 'demo' });
console.log('\nUse this token in the iOS app');