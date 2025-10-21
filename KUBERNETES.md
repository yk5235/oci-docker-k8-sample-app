# Kubernetes Deployment Guide - Simplified 3-Tier Application

Complete guide for deploying the Customer Management Application to Kubernetes (OKE) - Simplified version without persistent storage.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Steps](#deployment-steps)
- [Accessing the Application](#accessing-the-application)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## 📖 Overview

This simplified deployment showcases a 3-tier application on Kubernetes:

**Architecture:**
```
Internet → Load Balancer → Frontend (Nginx) → Backend (Node.js) → MongoDB (Ephemeral)
```

**Key Features:**
- Simple deployment without persistent volumes
- Showcases 3-tier application architecture
- Uses OCI Container Registry
- Kubernetes Services and Deployments
- ConfigMaps for configuration
- Resource limits and health checks

**Simplifications:**
- MongoDB uses ephemeral storage (data lost on pod restart)
- No StatefulSets or PersistentVolumeClaims
- Suitable for demo and testing purposes

---

## 📋 Prerequisites

### Required Tools
- OKE cluster deployed (using Terraform from this repository)
- `kubectl` installed and configured
- `docker` installed
- Access to OCI Container Registry
- OCI CLI installed and configured

### Verify Prerequisites
```bash
# Check kubectl
kubectl version --client

# Check OCI CLI
oci --version

# Check Docker
docker --version

# Verify cluster access
kubectl get nodes
```

---

## 📁 Project Structure

```
customer-management-app/
├── k8s/                                    # Kubernetes manifests
│   ├── namespace.yaml                      # Namespace definition
│   ├── mongodb/                            # MongoDB deployment
│   │   ├── deployment.yaml                 # MongoDB Deployment (ephemeral)
│   │   └── service.yaml                    # MongoDB ClusterIP Service
│   ├── backend/                            # Backend deployment
│   │   ├── configmap.yaml                  # Backend configuration
│   │   ├── deployment.yaml                 # Backend Deployment
│   │   └── service.yaml                    # Backend ClusterIP Service
│   ├── frontend/                           # Frontend deployment
│   │   ├── configmap.yaml                  # Nginx configuration
│   │   ├── deployment.yaml                 # Frontend Deployment
│   │   └── service.yaml                    # Frontend LoadBalancer Service
│   └── ingress.yaml                        # Optional: Ingress configuration
│
├── scripts/
│   └── k8s/                                # Kubernetes deployment scripts
│       ├── 01-setup-registry.sh            # Setup OCI Registry
│       ├── 02-build-and-push.sh            # Build and push images
│       ├── 03-deploy-all.sh                # Deploy all resources
│       ├── 04-get-status.sh                # Check deployment status
│       ├── 05-get-access-info.sh           # Get access information
│       ├── 06-test-api.sh                  # Test the API
│       ├── 07-scale-deployment.sh          # Scale deployments
│       ├── 08-update-deployment.sh         # Update deployments
│       ├── 09-view-logs.sh                 # View logs
│       └── 10-cleanup.sh                   # Clean up resources
│
├── src/                                    # Application source (unchanged)
│   ├── backend/
│   ├── frontend/
│   └── mongodb/
│
├── docker/                                 # Docker configs (unchanged)
├── terraform/                              # Terraform configs (unchanged)
├── KUBERNETES.md                           # This file
└── README.md                               # Main README
```

---

## 🚀 Deployment Steps

### Step 1: Setup OCI Container Registry

```bash
# Run the registry setup script
./scripts/k8s/01-setup-registry.sh

# This will:
# - Create repository in OCI Registry
# - Configure Docker authentication
# - Set up image pull secrets in Kubernetes
```

### Step 2: Build and Push Docker Images

```bash
# Build and push all images to OCI Registry
./scripts/k8s/02-build-and-push.sh

# This will:
# - Build MongoDB, Backend, Frontend images
# - Tag images for OCI Registry
# - Push images to registry
# - Verify uploads
```

### Step 3: Deploy to Kubernetes

```bash
# Deploy all resources
./scripts/k8s/03-deploy-all.sh

# This will deploy in order:
# 1. Namespace
# 2. ConfigMaps
# 3. MongoDB Deployment and Service
# 4. Backend Deployment and Service
# 5. Frontend Deployment and Service
```

### Step 4: Verify Deployment

```bash
# Check deployment status
./scripts/k8s/04-get-status.sh

# Get access information
./scripts/k8s/05-get-access-info.sh
```

**Expected Output:**
```
✓ Namespace: customer-app (Active)
✓ MongoDB: 1/1 pods running
✓ Backend: 2/2 pods running
✓ Frontend: 2/2 pods running

Access Information:
- Frontend URL: http://<EXTERNAL-IP>
- Backend API: http://<EXTERNAL-IP>/api
```

---

## 🌐 Accessing the Application

### Get External IP

```bash
# Get LoadBalancer external IP
kubectl get svc frontend-service -n customer-app

# Or use the script
./scripts/k8s/05-get-access-info.sh
```

### Access Points

**Frontend Web UI:**
```
http://<EXTERNAL-IP>
```

**Backend API:**
```
http://<EXTERNAL-IP>/api/customers
http://<EXTERNAL-IP>/api/health
```

### Access from Browser

1. Open browser and navigate to `http://<EXTERNAL-IP>`
2. You should see the Customer Management interface
3. Test CRUD operations through the UI

---

## 🧪 Testing

### Run Automated Tests

```bash
# Test the API endpoints
./scripts/k8s/06-test-api.sh
```

### Manual API Testing

```bash
# Get the external IP
FRONTEND_URL=$(kubectl get svc frontend-service -n customer-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Health check
curl http://${FRONTEND_URL}/api/health

# Create customer
curl -X POST http://${FRONTEND_URL}/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "address": "123 Main St",
    "country": "USA",
    "gender": "Male",
    "age": 30
  }'

# Get all customers
curl http://${FRONTEND_URL}/api/customers

# Update customer (replace <id>)
curl -X PATCH http://${FRONTEND_URL}/api/customers/<id> \
  -H "Content-Type: application/json" \
  -d '{"age": 31}'

# Delete customer (replace <id>)
curl -X DELETE http://${FRONTEND_URL}/api/customers/<id>
```

---

## 📊 Monitoring

### View Logs

```bash
# View all logs
./scripts/k8s/09-view-logs.sh

# View specific component logs
kubectl logs -f deployment/mongodb -n customer-app
kubectl logs -f deployment/backend -n customer-app
kubectl logs -f deployment/frontend -n customer-app

# View logs from specific pod
kubectl logs -f <pod-name> -n customer-app
```

### Check Pod Status

```bash
# Get pod details
kubectl get pods -n customer-app -o wide

# Describe pod for troubleshooting
kubectl describe pod <pod-name> -n customer-app

# Get pod events
kubectl get events -n customer-app --sort-by='.lastTimestamp'
```

### Resource Usage

```bash
# Get resource usage
kubectl top nodes
kubectl top pods -n customer-app

# Check resource limits
kubectl describe deployment backend -n customer-app | grep -A 5 "Limits"
```

---

## 🔧 Management Operations

### Scaling

```bash
# Scale using script
./scripts/k8s/07-scale-deployment.sh backend 3

# Manual scaling
kubectl scale deployment backend -n customer-app --replicas=3
kubectl scale deployment frontend -n customer-app --replicas=4
```

### Updating Deployments

```bash
# Update to new image version
./scripts/k8s/08-update-deployment.sh

# Manual update
kubectl set image deployment/backend backend=<region>.ocir.io/<namespace>/backend-customer:v2 -n customer-app

# Check rollout status
kubectl rollout status deployment/backend -n customer-app

# Rollback if needed
kubectl rollout undo deployment/backend -n customer-app
```

### Restart Deployments

```bash
# Restart all pods in a deployment
kubectl rollout restart deployment/backend -n customer-app
kubectl rollout restart deployment/frontend -n customer-app
kubectl rollout restart deployment/mongodb -n customer-app
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Pods Not Starting

**Symptoms:** Pods in `Pending`, `CrashLoopBackOff`, or `ImagePullBackOff` state

**Diagnosis:**
```bash
kubectl get pods -n customer-app
kubectl describe pod <pod-name> -n customer-app
kubectl logs <pod-name> -n customer-app
```

**Solutions:**

**ImagePullBackOff:**
```bash
# Check image pull secret
kubectl get secret oci-registry-secret -n customer-app

# Recreate secret if needed
./scripts/k8s/01-setup-registry.sh
```

**CrashLoopBackOff:**
```bash
# Check application logs
kubectl logs <pod-name> -n customer-app --previous

# Check environment variables
kubectl exec <pod-name> -n customer-app -- env | grep MONGO
```

#### 2. Backend Cannot Connect to MongoDB

**Symptoms:** Backend logs show MongoDB connection errors

**Diagnosis:**
```bash
# Check MongoDB is running
kubectl get pods -n customer-app | grep mongodb

# Check MongoDB service
kubectl get svc mongodb-service -n customer-app

# Test connectivity from backend pod
kubectl exec -it <backend-pod> -n customer-app -- nc -zv mongodb-service 27017
```

**Solutions:**
```bash
# Restart MongoDB
kubectl rollout restart deployment/mongodb -n customer-app

# Check MongoDB logs
kubectl logs deployment/mongodb -n customer-app

# Verify environment variables
kubectl describe deployment backend -n customer-app | grep -A 10 "Environment"
```

#### 3. Frontend Cannot Reach Backend

**Symptoms:** 502 Bad Gateway or connection refused errors in browser

**Diagnosis:**
```bash
# Check backend service
kubectl get svc backend-service -n customer-app

# Check backend pods
kubectl get pods -n customer-app | grep backend

# Test backend health
kubectl exec -it <frontend-pod> -n customer-app -- wget -q -O- http://backend-service:3000/health
```

**Solutions:**
```bash
# Restart backend
kubectl rollout restart deployment/backend -n customer-app

# Check frontend nginx config
kubectl get configmap frontend-nginx-config -n customer-app -o yaml
```

#### 4. Cannot Access Application from Internet

**Symptoms:** LoadBalancer external IP is pending or connection timeout

**Diagnosis:**
```bash
# Check LoadBalancer service
kubectl get svc frontend-service -n customer-app

# Check OCI Load Balancer in console
# OCI Console → Networking → Load Balancers
```

**Solutions:**
```bash
# Wait for LoadBalancer provisioning (can take 2-3 minutes)
kubectl get svc frontend-service -n customer-app -w

# Check security lists allow traffic on port 80
# Verify OKE cluster security lists in OCI Console

# Check if using private subnet (LoadBalancer won't get public IP)
# Review Terraform networking configuration
```

#### 5. Data Loss After Pod Restart

**Expected Behavior:** This is normal for ephemeral MongoDB deployment

**Explanation:**
- MongoDB uses emptyDir volume (ephemeral storage)
- Data is lost when pod restarts
- This is intentional for this simplified demo

**For Production:**
- Use StatefulSet with PersistentVolumeClaims
- See production deployment guide for persistent storage setup

---

## 🧹 Cleanup

### Remove All Resources

```bash
# Run cleanup script
./scripts/k8s/10-cleanup.sh

# This will:
# 1. Delete all deployments and services
# 2. Delete configmaps
# 3. Delete namespace
# 4. Optionally remove images from OCI Registry
```

### Manual Cleanup

```bash
# Delete namespace (removes everything)
kubectl delete namespace customer-app

# Delete images from OCI Registry (optional)
# Use OCI Console → Developer Services → Container Registry
```

### Verify Cleanup

```bash
# Check namespace is gone
kubectl get namespaces | grep customer-app

# Check LoadBalancer is deleted
# OCI Console → Networking → Load Balancers
```

---

## 📝 Important Notes

### Ephemeral Storage Limitations

⚠️ **Data Persistence:** MongoDB data is stored in ephemeral storage (`emptyDir`). Data will be **lost** when:
- Pod restarts
- Pod is rescheduled to another node
- Deployment is updated
- Node fails

**Use Cases:**
- ✅ Demo and testing environments
- ✅ Development environments
- ✅ CI/CD pipelines
- ✅ Learning Kubernetes
- ❌ Production environments (use StatefulSet with persistent volumes)

### Resource Limits

Default resource allocations:
```yaml
MongoDB:  500m CPU, 512Mi memory
Backend:  200m CPU, 256Mi memory
Frontend: 100m CPU, 128Mi memory
```

Adjust in deployment YAML files if needed.

### Security Considerations

**For Production:**
- Change default MongoDB credentials
- Use Kubernetes Secrets for sensitive data
- Implement Network Policies
- Enable Pod Security Policies
- Use private container registry with authentication
- Implement RBAC

---

## 🎯 Next Steps

### For Production Deployment

1. **Add Persistent Storage:**
   - Convert MongoDB to StatefulSet
   - Use OCI Block Volumes for persistence
   - Implement backup strategy

2. **Enhance Security:**
   - Use Kubernetes Secrets
   - Implement Network Policies
   - Enable TLS/SSL
   - Use private registry

3. **Implement Monitoring:**
   - Deploy Prometheus and Grafana
   - Configure alerting
   - Set up log aggregation

4. **Add CI/CD:**
   - Automate build and deployment
   - Implement GitOps with ArgoCD
   - Add automated testing

5. **High Availability:**
   - Multiple replicas with pod anti-affinity
   - Configure horizontal pod autoscaling
   - Multi-region deployment

---

## 📚 Additional Resources

- [OKE Documentation](https://docs.oracle.com/en-us/iaas/Content/ContEng/home.htm)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [OCI Container Registry](https://docs.oracle.com/en-us/iaas/Content/Registry/home.htm)

---

**Version:** 1.0.0 (Simplified Kubernetes Deployment)
**Last Updated:** January 2025