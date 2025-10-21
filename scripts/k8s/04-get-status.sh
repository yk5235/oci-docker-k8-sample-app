#!/bin/bash

echo "========================================"
echo "Kubernetes Deployment Status"
echo "========================================"

# Check if namespace exists
if ! kubectl get namespace customer-app &> /dev/null; then
    echo "❌ Namespace 'customer-app' does not exist"
    echo "Please run ./03-deploy-all.sh first"
    exit 1
fi

echo -e "\n📦 Namespace Status:"
kubectl get namespace customer-app

echo -e "\n🚀 Deployments:"
kubectl get deployments -n customer-app -o wide

echo -e "\n📊 Pods:"
kubectl get pods -n customer-app -o wide

echo -e "\n🌐 Services:"
kubectl get services -n customer-app -o wide

echo -e "\n📝 ConfigMaps:"
kubectl get configmaps -n customer-app

echo -e "\n🔐 Secrets:"
kubectl get secrets -n customer-app

echo -e "\n📈 Resource Usage:"
echo "Nodes:"
kubectl top nodes 2>/dev/null || echo "  Metrics server not available"

echo -e "\nPods:"
kubectl top pods -n customer-app 2>/dev/null || echo "  Metrics server not available"

echo -e "\n🔍 Pod Details:"
for pod in $(kubectl get pods -n customer-app -o jsonpath='{.items[*].metadata.name}'); do
    status=$(kubectl get pod $pod -n customer-app -o jsonpath='{.status.phase}')
    ready=$(kubectl get pod $pod -n customer-app -o jsonpath='{.status.containerStatuses[0].ready}')
    restarts=$(kubectl get pod $pod -n customer-app -o jsonpath='{.status.containerStatuses[0].restartCount}')
    
    if [ "$ready" = "true" ] && [ "$status" = "Running" ]; then
        echo "  ✓ $pod - $status (Restarts: $restarts)"
    else
        echo "  ⚠ $pod - $status (Ready: $ready, Restarts: $restarts)"
    fi
done

echo -e "\n⚡ Recent Events:"
kubectl get events -n customer-app --sort-by='.lastTimestamp' | tail -10

echo -e "\n========================================"
echo "Status Check Complete"
echo "========================================"