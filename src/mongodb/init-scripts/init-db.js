// Initialize database and create collections
db = db.getSiblingDB('customerDB');

// Create customers collection with validation
db.createCollection('customers', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'address', 'country', 'gender', 'age'],
      properties: {
        name: {
          bsonType: 'string',
          description: 'Customer name is required'
        },
        address: {
          bsonType: 'string',
          description: 'Customer address is required'
        },
        country: {
          bsonType: 'string',
          description: 'Customer country is required'
        },
        gender: {
          bsonType: 'string',
          description: 'Customer gender is required'
        },
        age: {
          bsonType: 'int',
          minimum: 0,
          maximum: 150,
          description: 'Customer age must be between 0 and 150'
        }
      }
    }
  }
});

// Create indexes for better query performance
db.customers.createIndex({ name: 1 });
db.customers.createIndex({ country: 1 });
db.customers.createIndex({ age: 1 });

print('Database initialization complete');