#!/bin/bash

echo "========================================"
echo "View Kubernetes Logs"
echo "========================================"

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <component> [options]"
    echo ""
    echo "Components:"
    echo "  - mongodb   : MongoDB logs"
    echo "  - backend   : Backend API logs"
    echo "  - frontend  : Frontend Nginx logs"
    echo "  - all       : All components logs (last 20 lines each)"
    echo ""
    echo "Options:"
    echo "  -f, --follow    : Follow log output (like tail -f)"
    echo "  -p, --previous  : Show logs from previous pod instance"
    echo "  --tail=N        : Show last N lines (default: 50)"
    echo ""
    echo "Examples:"
    echo "  $0 backend              # Show last 50 lines from backend"
    echo "  $0 backend -f           # Follow backend logs"
    echo "  $0 backend --tail=100   # Show last 100 lines"
    echo "  $0 all                  # Show logs from all components"
    exit 1
fi

COMPONENT=$1
shift
OPTIONS="$@"

# Default tail lines
TAIL_LINES=50
if [[ "$OPTIONS" =~ --tail=([0-9]+) ]]; then
    TAIL_LINES="${BASH_REMATCH[1]}"
    OPTIONS=$(echo "$OPTIONS" | sed "s/--tail=[0-9]*//g")
fi

show_logs() {
    local deployment=$1
    local follow=$2
    local previous=$3
    
    echo "Fetching logs for: $deployment"
    echo "----------------------------------------"
    
    # Get pod name
    POD=$(kubectl get pods -n customer-app -l app=$deployment -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$POD" ]; then
        echo "❌ No pods found for deployment: $deployment"
        return 1
    fi
    
    echo "Pod: $POD"
    echo ""
    
    # Build kubectl command
    CMD="kubectl logs $POD -n customer-app --tail=$TAIL_LINES"
    
    if [ "$follow" = "true" ]; then
        CMD="$CMD -f"
    fi
    
    if [ "$previous" = "true" ]; then
        CMD="$CMD --previous"
    fi
    
    # Execute command
    eval $CMD
}

# Parse options
FOLLOW="false"
PREVIOUS="false"

if [[ "$OPTIONS" =~ -f|--follow ]]; then
    FOLLOW="true"
fi

if [[ "$OPTIONS" =~ -p|--previous ]]; then
    PREVIOUS="true"
fi

# Show logs based on component
case $COMPONENT in
    mongodb)
        show_logs "mongodb" "$FOLLOW" "$PREVIOUS"
        ;;
    backend)
        show_logs "backend" "$FOLLOW" "$PREVIOUS"
        ;;
    frontend)
        show_logs "frontend" "$FOLLOW" "$PREVIOUS"
        ;;
    all)
        if [ "$FOLLOW" = "true" ]; then
            echo "❌ Cannot follow logs from multiple components"
            echo "Use: $0 <component> -f to follow specific component"
            exit 1
        fi
        
        echo "=== MongoDB Logs (last 20 lines) ==="
        kubectl logs deployment/mongodb -n customer-app --tail=20 2>/dev/null || echo "No logs available"
        echo ""
        
        echo "=== Backend Logs (last 20 lines) ==="
        kubectl logs deployment/backend -n customer-app --tail=20 2>/dev/null || echo "No logs available"
        echo ""
        
        echo "=== Frontend Logs (last 20 lines) ==="
        kubectl logs deployment/frontend -n customer-app --tail=20 2>/dev/null || echo "No logs available"
        echo ""
        ;;
    *)
        echo "❌ Invalid component: $COMPONENT"
        echo "Valid options: mongodb, backend, frontend, all"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "💡 Tip: Use -f to follow logs in real-time"
echo "Example: $0 backend -f"
echo "========================================"