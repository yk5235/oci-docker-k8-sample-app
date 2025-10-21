#!/bin/bash
set -e

echo "Stopping all customer containers..."
docker stop frontend-customer 2>/dev/null || echo "Frontend already stopped"
docker stop backend-customer 2>/dev/null || echo "Backend already stopped"
docker stop mongodb-customer 2>/dev/null || echo "MongoDB already stopped"
echo "All containers stopped"
