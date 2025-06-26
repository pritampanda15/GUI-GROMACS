#!/bin/bash

# Stop GROMACS GUI Services Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo -e "${BLUE}🛑 Stopping GROMACS GUI Platform...${NC}"

# Stop tmux sessions
if command -v tmux >/dev/null 2>&1; then
    print_status "Stopping tmux sessions..."
    tmux kill-session -t gromacs-backend 2>/dev/null && print_success "Backend session stopped" || print_warning "Backend session not found"
    tmux kill-session -t gromacs-frontend 2>/dev/null && print_success "Frontend session stopped" || print_warning "Frontend session not found"
fi

# Stop screen sessions
if command -v screen >/dev/null 2>&1; then
    print_status "Stopping screen sessions..."
    screen -S gromacs-backend -X quit 2>/dev/null && print_success "Backend session stopped" || print_warning "Backend session not found"
    screen -S gromacs-frontend -X quit 2>/dev/null && print_success "Frontend session stopped" || print_warning "Frontend session not found"
fi

# Kill processes by port
print_status "Killing processes on ports 8000 and 3000..."

# Backend (port 8000)
BACKEND_PIDS=$(lsof -ti:8000 2>/dev/null)
if [ ! -z "$BACKEND_PIDS" ]; then
    echo $BACKEND_PIDS | xargs kill -TERM 2>/dev/null
    sleep 2
    echo $BACKEND_PIDS | xargs kill -KILL 2>/dev/null || true
    print_success "Backend processes stopped"
else
    print_warning "No backend processes found on port 8000"
fi

# Frontend (port 3000)
FRONTEND_PIDS=$(lsof -ti:3000 2>/dev/null)
if [ ! -z "$FRONTEND_PIDS" ]; then
    echo $FRONTEND_PIDS | xargs kill -TERM 2>/dev/null
    sleep 2
    echo $FRONTEND_PIDS | xargs kill -KILL 2>/dev/null || true
    print_success "Frontend processes stopped"
else
    print_warning "No frontend processes found on port 3000"
fi

# Kill any remaining related processes
print_status "Cleaning up remaining processes..."
pkill -f "uvicorn.*app.main" 2>/dev/null || true
pkill -f "webpack.*frontend" 2>/dev/null || true
pkill -f "react-scripts" 2>/dev/null || true

print_success "🎉 All services stopped successfully!"

# Verify ports are free
sleep 1
if ! lsof -i:8000 >/dev/null 2>&1 && ! lsof -i:3000 >/dev/null 2>&1; then
    print_success "Ports 8000 and 3000 are now free"
else
    print_warning "Some processes may still be running. Check with: lsof -i:8000 -i:3000"
fi