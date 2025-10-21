# Customer Management Application

Full-stack customer management application with MongoDB, Node.js, and React. Supports both Docker and Kubernetes deployment.

## 🏗️ Architecture
```
Frontend (React + Nginx) → Backend (Node.js + Express) → MongoDB
     Port 80                    Port 3000                Port 27017
```

## 📁 Repository Structure
```
customer-management-app/
├── src/                      # Application source code
│   ├── backend/             # Node.js/Express API
│   ├── frontend/            # React application
│   └── mongodb/             # MongoDB with init scripts
├── docker/                   # Docker Compose configuration
│   └── docker-compose.yaml
├── k8s/                      # Kubernetes manifests
├── scripts/                  # Deployment automation scripts
│   ├── docker/              # Docker deployment scripts
│   └── k8s/                 # Kubernetes deployment scripts
├── docs/                     # Additional documentation
├── DOCKER.md                # Docker deployment guide
└── KUBERNETES.md            # Kubernetes deployment guide
```

## 🚀 Quick Start

### Option 1: Docker Compose (Recommended for Local Development)
```bash
# Start all services
./scripts/docker/start-with-compose.sh

# Or manually:
cd docker
docker-compose up -d

# Access the application
# Frontend: http://localhost
# Backend:  http://localhost:3000
```

### Option 2: Individual Docker Containers
```bash
# Build all images
./scripts/docker/build-all.sh

# Run all containers
./scripts/docker/run-all.sh

# Test the API
./scripts/docker/test-api.sh

# Stop all containers
./scripts/docker/stop-all.sh
```

### Option 3: Kubernetes Deployment

See [KUBERNETES.md](KUBERNETES.md) for detailed Kubernetes deployment instructions.

## 🧪 Testing

### Quick Test
```bash
./scripts/docker/test-api.sh
```

### Manual Testing
```bash
# Health check
curl http://localhost:3000/health

# Create customer
curl -X POST http://localhost:3000/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "address": "123 Main St",
    "country": "USA",
    "gender": "Male",
    "age": 30
  }'

# Get all customers
curl http://localhost:3000/customers
```

### Browser Testing
Open http://localhost in your browser to use the web interface.

## 📊 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/customers` | Get all customers |
| GET | `/customers/:id` | Get customer by ID |
| POST | `/customers` | Create new customer |
| PATCH | `/customers/:id` | Update customer |
| DELETE | `/customers/:id` | Delete customer |

## 🛠️ Tech Stack

- **Frontend**: React 17, Nginx
- **Backend**: Node.js 16, Express
- **Database**: MongoDB 5.0
- **Containerization**: Docker, Docker Compose
- **Orchestration**: Kubernetes

## 📚 Detailed Documentation

- [Docker Deployment Guide](DOCKER.md) - Complete Docker deployment instructions
- [Kubernetes Deployment Guide](KUBERNETES.md) - Complete Kubernetes deployment instructions

## 🔧 Management Commands
```bash
# Build all images
./scripts/docker/build-all.sh

# Start with Docker Compose
./scripts/docker/start-with-compose.sh

# Start individual containers
./scripts/docker/run-all.sh

# Stop all containers
./scripts/docker/stop-all.sh

# Clean up everything
./scripts/docker/clean-all.sh

# Test API
./scripts/docker/test-api.sh
```

## 🌐 Access Points

- **Frontend**: http://localhost (port 80)
- **Backend API**: http://localhost:3000
- **MongoDB**: localhost:27017

## 🗄️ Database Schema
```javascript
{
  name: String (required, 2-100 chars),
  address: String (required, 5-200 chars),
  country: String (required, 2-50 chars),
  gender: String (required, enum: ['Male', 'Female', 'Other']),
  age: Number (required, 0-150),
  createdAt: Date (auto),
  updatedAt: Date (auto)
}
```

## 🐳 Docker Images

- `mongodb-customer:latest` - MongoDB 5.0 with initialization scripts
- `backend-customer:latest` - Node.js 16 Alpine with Express API
- `frontend-customer:latest` - React app served by Nginx Alpine

## 🔒 Default Credentials (Development Only)

- **MongoDB Username**: mongo
- **MongoDB Password**: password
- **Database**: customerDB

⚠️ **Warning**: Change these credentials for production deployment!

## 🛠️ Troubleshooting

### Backend can't connect to MongoDB
```bash
docker logs backend-customer
docker logs mongodb-customer
docker restart backend-customer
```

### Port already in use
```bash
sudo lsof -i :80    # Frontend
sudo lsof -i :3000  # Backend
sudo lsof -i :27017 # MongoDB
```

### Container keeps restarting
```bash
docker logs <container-name>
docker inspect <container-name>
```

## 🎯 Roadmap

- [x] Docker deployment
- [x] Docker Compose orchestration
- [ ] Kubernetes deployment
- [ ] CI/CD pipeline
- [ ] Authentication & authorization
- [ ] Monitoring and logging
- [ ] Automated backups

## 📄 License

ISC

## 👨‍💻 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For issues and questions, please open an issue in the repository.

---

**Version**: 1.0.0 (Docker Deployment)
