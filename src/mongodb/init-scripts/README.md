# MongoDB Initialization Scripts

This directory contains scripts that automatically run when MongoDB container starts for the **first time**.

## 📁 Files

- `init-db.js` - Initializes the customerDB database with collections, indexes, and validation rules

## 🔄 How It Works

1. Scripts in this directory are automatically copied to `/docker-entrypoint-initdb.d/` in the MongoDB container
2. MongoDB executes all `.js` and `.sh` files in this directory on first startup
3. Scripts run **only once** when the database is empty

## 🗄️ What Gets Created

### Database
- **Name**: `customerDB`

### Collections
- **customers** - Main customer data collection
  - Schema validation enabled
  - Indexes on: name, country, age

### Indexes
```javascript
db.customers.createIndex({ name: 1 })
db.customers.createIndex({ country: 1 })
db.customers.createIndex({ age: 1 })
```

## 🔄 Re-running Init Scripts

If you need to re-run the initialization scripts:
```bash
# Stop and remove container
docker stop mongodb-customer
docker rm mongodb-customer

# Remove volume (this deletes all data!)
docker volume rm mongodb_data

# Start fresh
cd ../../.. && ./scripts/docker/run-all.sh
```

## ➕ Adding New Init Scripts

1. Create a new `.js` or `.sh` file in this directory
2. Name it with a number prefix for execution order:
   - `01-init-db.js`
   - `02-seed-data.js`
   - `03-create-users.js`

3. Rebuild the MongoDB image:
```bash
   cd ..
   ./build.sh
```

## 📝 Example: Adding Seed Data

Create `02-seed-data.js`:
```javascript
db = db.getSiblingDB('customerDB');

db.customers.insertMany([
  {
    name: "Sample Customer 1",
    address: "123 Main St",
    country: "USA",
    gender: "Male",
    age: 30
  },
  {
    name: "Sample Customer 2",
    address: "456 Elm St",
    country: "Canada",
    gender: "Female",
    age: 25
  }
]);

print('Seed data inserted successfully');
```

## ⚠️ Important Notes

- Init scripts run with **root privileges**
- Scripts must be idempotent (safe to run multiple times)
- Errors in init scripts will prevent MongoDB from starting
- Check logs if container fails to start: `docker logs mongodb-customer`

---

**Related**: See [MongoDB README](../README.md) for more information.
