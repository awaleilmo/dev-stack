// MongoDB initialization script
// This runs on first container startup

db = db.getSiblingDB('app_mongo');

// Create application user with readWrite role
db.createUser({
  user: 'mongouser',
  pwd: 'mongopass',
  roles: [
    { role: 'readWrite', db: 'app_mongo' },
    { role: 'readWrite', db: 'app_mongo_dev' }
  ]
});

// Create indexes for common use cases
db.createCollection('users');
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ createdAt: -1 });

db.createCollection('sessions');
db.sessions.createIndex({ expires: 1 }, { expireAfterSeconds: 0 });

print('MongoDB initialization complete');
