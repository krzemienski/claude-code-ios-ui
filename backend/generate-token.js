import jwt from 'jsonwebtoken';

const JWT_SECRET = 'claude-ui-dev-secret-change-in-production';

// Create token for demo user
const token = jwt.sign(
  { 
    userId: 2, 
    username: 'demo' 
  },
  JWT_SECRET
);

console.log('New JWT Token for demo user:');
console.log(token);
console.log('\nUse this token in the iOS app');