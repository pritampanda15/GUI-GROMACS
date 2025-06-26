#!/bin/bash

# Stable Manual Start Script for GROMACS GUI
# This version uses tmux/screen for more stable process management

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if tmux is available
if command -v tmux >/dev/null 2>&1; then
    SESSION_MANAGER="tmux"
elif command -v screen >/dev/null 2>&1; then
    SESSION_MANAGER="screen"
else
    print_warning "Neither tmux nor screen found. Installing tmux..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y tmux
    elif command -v brew >/dev/null 2>&1; then
        brew install tmux
    else
        print_error "Please install tmux or screen manually"
        exit 1
    fi
    SESSION_MANAGER="tmux"
fi

print_status "Using $SESSION_MANAGER for session management"

# Kill any existing sessions
if [ "$SESSION_MANAGER" = "tmux" ]; then
    tmux kill-session -t gromacs-backend 2>/dev/null || true
    tmux kill-session -t gromacs-frontend 2>/dev/null || true
else
    screen -S gromacs-backend -X quit 2>/dev/null || true
    screen -S gromacs-frontend -X quit 2>/dev/null || true
fi

# Kill processes on ports
print_status "Cleaning up ports..."
sudo pkill -f "uvicorn.*8000" 2>/dev/null || true
sudo pkill -f "webpack.*3000" 2>/dev/null || true
sleep 2

# Start backend in tmux/screen session
print_status "Starting backend server..."
if [ "$SESSION_MANAGER" = "tmux" ]; then
    tmux new-session -d -s gromacs-backend
    tmux send-keys -t gromacs-backend "cd backend" Enter
    tmux send-keys -t gromacs-backend "source venv/bin/activate" Enter
    tmux send-keys -t gromacs-backend "python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload" Enter
else
    screen -dmS gromacs-backend bash -c "cd backend && source venv/bin/activate && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
fi

# Wait for backend to start
print_status "Waiting for backend to initialize..."
for i in {1..30}; do
    if curl -s http://localhost:8000/ >/dev/null 2>&1; then
        print_success "Backend is running!"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Backend failed to start after 30 seconds"
        exit 1
    fi
    sleep 1
done

# Start frontend in tmux/screen session  
print_status "Starting frontend server..."
if [ "$SESSION_MANAGER" = "tmux" ]; then
    tmux new-session -d -s gromacs-frontend
    tmux send-keys -t gromacs-frontend "cd frontend" Enter
    tmux send-keys -t gromacs-frontend "export BROWSER=none" Enter
    tmux send-keys -t gromacs-frontend "npm start" Enter
else
    screen -dmS gromacs-frontend bash -c "cd frontend && export BROWSER=none && npm start"
fi

# Wait for frontend to start
print_status "Waiting for frontend to initialize..."
for i in {1..60}; do
    if curl -s http://localhost:3000/ >/dev/null 2>&1; then
        print_success "Frontend is running!"
        break
    fi
    if [ $i -eq 60 ]; then
        print_error "Frontend failed to start after 60 seconds"
        exit 1
    fi
    sleep 1
done

echo
print_success "🎉 GROMACS GUI Platform Started Successfully!"
echo
echo -e "${GREEN}Services are running in background sessions:${NC}"
echo -e "  Frontend: http://localhost:3000"
echo -e "  Backend:  http://localhost:8000"
echo -e "  API Docs: http://localhost:8000/docs"
echo
echo -e "${BLUE}To view logs:${NC}"
if [ "$SESSION_MANAGER" = "tmux" ]; then
    echo -e "  Backend:  tmux attach -t gromacs-backend"
    echo -e "  Frontend: tmux attach -t gromacs-frontend"
    echo -e "  (Press Ctrl+B then D to detach)"
else
    echo -e "  Backend:  screen -r gromacs-backend"
    echo -e "  Frontend: screen -r gromacs-frontend"
    echo -e "  (Press Ctrl+A then D to detach)"
fi
echo
echo -e "${BLUE}To stop services:${NC}"
echo -e "  ./scripts/stop-services.sh"
echo
echo -e "${BLUE}To check status:${NC}"
echo -e "  ./scripts/check-status.sh"

# Open browser
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open http://localhost:3000 >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
    open http://localhost:3000 >/dev/null 2>&1 &
fi