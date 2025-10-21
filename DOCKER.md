# Docker Deployment Guide

Complete guide for deploying the Customer Management Application using Docker.

## 📋 Prerequisites

- Docker 20.10+ installed
- Docker Compose 1.29+ installed
- 4GB RAM available
- Ports 80, 3000, 27017 available

### Verify Prerequisites
```bash
docker --version
docker-compose --version
docker ps
```

## 🚀 Quick Start

### Method 1: Docker Compose (Recommended)
```bash
# Start all services
./scripts/docker/start-with-compose.sh

# Or manually:
cd docker
docker-compose up -d
```

### Method 2: Individual Containers
```bash
# Build all images
./scripts/docker/build-all.sh

# Run all containers
./scripts/docker/run-all.sh
```

## 📦 Module-by-Module Deployment

### Step 1: MongoDB
```bash
cd src/mongodb
./build.sh
./run.sh
cd ../..

# Verify
docker ps | grep mongodb-customer
docker logs mongodb-customer
```

### Step 2: Backend
```bash
cd src/backend
./build.sh
./run.sh
cd ../..

# Verify
docker ps | grep backend-customer
curl http://localhost:3000/health
```

### Step 3: Frontend
```bash
cd src/frontend
./build.sh
./run.sh
cd ../..

# Verify
docker ps | grep frontend-customer
curl http://localhost
```

## 🔧 Docker Compose Usage

### Start Services
```bash
cd docker
docker-compose up -d
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
```

### Stop Services
```bash
docker-compose stop
```

### Restart Services
```bash
docker-compose restart
```

### Remove Everything
```bash
docker-compose down

# Remove volumes too (deletes data)
docker-compose down -v
```

## 🧪 Testing

### Run Test Script
```bash
./scripts/docker/test-api.sh
```

### Manual API Testing
```bash
# Health check
curl http://localhost:3000/health

# Create customer
curl -X POST http://localhost:3000/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jane Smith",
    "address": "456 Elm St",
    "country": "Canada",
    "gender": "Female",
    "age": 25
  }'

# Get all customers
curl http://localhost:3000/customers

# Get specific customer (replace ID)
curl http://localhost:3000/customers/65f8a1b2c3d4e5f6a7b8c9d0

# Update customer (replace ID)
curl -X PATCH http://localhost:3000/customers/65f8a1b2c3d4e5f6a7b8c9d0 \
  -H "Content-Type: application/json" \
  -d '{"age": 26}'

# Delete customer (replace ID)
curl -X DELETE http://localhost:3000/customers/65f8a1b2c3d4e5f6a7b8c9d0
```

## 🔍 Monitoring & Debugging

### View Container Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### View Logs
```bash
docker logs -f mongodb-customer
docker logs -f backend-customer
docker logs -f frontend-customer
```

### Execute into Container
```bash
docker exec -it mongodb-customer mongosh
docker exec -it backend-customer sh
docker exec -it frontend-customer sh
```

### Check Resource Usage
```bash
docker stats
```

## 🛠️ Troubleshooting

### Backend Can't Connect to MongoDB

**Symptoms**: Backend logs show connection errors

**Solution**:
```bash
# Check if MongoDB is running
docker ps | grep mongodb-customer

# Check MongoDB logs
docker logs mongodb-customer

# Get MongoDB IP
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mongodb-customer

# Restart backend
docker restart backend-customer
```

### Frontend Can't Reach Backend

**Symptoms**: 404 errors in browser console

**Solution**:
```bash
# Check backend is running
curl http://localhost:3000/health

# Check nginx configuration
docker exec frontend-customer cat /etc/nginx/conf.d/default.conf

# Restart frontend
docker restart frontend-customer
```

### Port Already in Use

**Symptoms**: Error binding to port

**Solution**:
```bash
# Find what's using the port
sudo lsof -i :80
sudo lsof -i :3000
sudo lsof -i :27017

# Stop the conflicting service or change port in docker-compose.yaml
```

### Container Keeps Restarting

**Symptoms**: Container status shows "Restarting"

**Solution**:
```bash
# Check logs
docker logs <container-name>

# Check last 50 lines
docker logs --tail 50 <container-name>

# Run interactively to see error
docker run -it <image-name> sh
```

### Data Lost After Restart

**Symptoms**: Customer data disappears

**Solution**:
```bash
# Check if volume exists
docker volume ls | grep mongodb

# MongoDB data should persist in volume
# If missing, volume might have been deleted
# Avoid using: docker-compose down -v
```

## 🗄️ Data Management

### Backup MongoDB Data
```bash
# Create backup
docker exec mongodb-customer mongodump \
  --username=mongo \
  --password=password \
  --authenticationDatabase=admin \
  --db=customerDB \
  --archive=/tmp/backup.archive

# Copy backup from container
docker cp mongodb-customer:/tmp/backup.archive ./backup-$(date +%Y%m%d).archive
```

### Restore MongoDB Data
```bash
# Copy backup to container
docker cp ./backup-20241016.archive mongodb-customer:/tmp/restore.archive

# Restore
docker exec mongodb-customer mongorestore \
  --username=mongo \
  --password=password \
  --authenticationDatabase=admin \
  --archive=/tmp/restore.archive
```

### View MongoDB Data
```bash
# Connect to MongoDB shell
docker exec -it mongodb-customer mongosh -u mongo -p password --authenticationDatabase admin

# Inside mongosh:
use customerDB
db.customers.find().pretty()
db.customers.countDocuments()
```

## 🔐 Security Considerations

### For Production

1. **Change default credentials**:
```yaml
   # docker/docker-compose.yaml
   environment:
     MONGO_INITDB_ROOT_USERNAME: <strong-username>
     MONGO_INITDB_ROOT_PASSWORD: <strong-password>
```

2. **Use environment files**:
```bash
   echo "MONGO_PASSWORD=<your-secure-password>" > .env
   # Add .env to .gitignore
```

3. **Enable TLS/SSL**

4. **Limit network exposure**:
```yaml
   # Don't expose MongoDB port
   # ports:
   #   - "27017:27017"  # Comment this out
```

## 🎯 Best Practices

1. **Use Docker Compose for development**
2. **Individual containers for learning/debugging**
3. **Always check logs when troubleshooting**
4. **Back up MongoDB data regularly**
5. **Don't commit sensitive data to Git**
6. **Use tagged versions for images (not :latest) in production**

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [MongoDB Docker Image](https://hub.docker.com/_/mongo)
- [Node.js Docker Image](https://hub.docker.com/_/node)
- [Nginx Docker Image](https://hub.docker.com/_/nginx)

---

**Next Steps**: See [KUBERNETES.md](KUBERNETES.md) for Kubernetes deployment.
