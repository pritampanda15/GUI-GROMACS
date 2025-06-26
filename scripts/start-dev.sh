#!/bin/bash

# GROMACS GUI Platform - Development Startup Script
# This script starts both backend and frontend services for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print colored output
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

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if port is available
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Kill process using specific port
kill_port() {
    local port=$1
    local pids=$(lsof -ti :$port)
    if [ ! -z "$pids" ]; then
        print_warning "Killing processes using port $port: $pids"
        echo $pids | xargs kill -9 2>/dev/null || true
        sleep 2
    fi
}

# Cleanup function
cleanup() {
    print_header "\n🛑 Shutting down services..."
    
    if [ ! -z "$BACKEND_PID" ]; then
        print_status "Stopping backend (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$FRONTEND_PID" ]; then
        print_status "Stopping frontend (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    # Kill any remaining processes on our ports
    kill_port 8000
    kill_port 3000
    
    print_success "Services stopped successfully"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM EXIT

# Main function
main() {
    print_header "=================================================="
    print_header "🧬 GROMACS GUI Platform - Development Mode"
    print_header "=================================================="
    echo
    
    # Check if we're in the correct directory
    if [ ! -f "docker-compose.yml" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
        print_error "Please run this script from the project root directory"
        print_error "Current directory: $(pwd)"
        exit 1
    fi
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists python3; then
        print_error "Python 3 is required but not found"
        exit 1
    fi
    
    if ! command_exists node; then
        print_error "Node.js is required but not found"
        exit 1
    fi
    
    if ! command_exists npm; then
        print_error "npm is required but not found"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
    echo
    
    # Check if ports are available
    print_status "Checking port availability..."
    
    if ! check_port 8000; then
        print_warning "Port 8000 is in use"
        kill_port 8000
    fi
    
    if ! check_port 3000; then
        print_warning "Port 3000 is in use"
        kill_port 3000
    fi
    
    print_success "Ports are available"
    echo
    
    # Check backend setup
    print_status "Checking backend setup..."
    
    if [ ! -d "backend/venv" ]; then
        print_error "Backend virtual environment not found"
        print_error "Please run './scripts/setup.sh' first"
        exit 1
    fi
    
    if [ ! -f "backend/.env" ]; then
        print_warning "Backend .env file not found, creating default..."
        cp backend/.env.example backend/.env 2>/dev/null || {
            cat > backend/.env << EOF
DATABASE_URL=sqlite:///./gromacs_gui.db
REDIS_URL=redis://localhost:6379
CORS_ORIGINS=http://localhost:3000
DEBUG=true
MOCK_GROMACS=true
EOF
        }
    fi
    
    # Check frontend setup
    print_status "Checking frontend setup..."
    
    if [ ! -d "frontend/node_modules" ]; then
        print_error "Frontend dependencies not found"
        print_error "Please run './scripts/setup.sh' first"
        exit 1
    fi
    
    if [ ! -f "frontend/.env" ]; then
        print_warning "Frontend .env file not found, creating default..."
        cat > frontend/.env << EOF
REACT_APP_API_URL=http://localhost:8000
REACT_APP_WS_URL=ws://localhost:8000
EOF
    fi
    
    print_success "Setup checks completed"
    echo
    
    # Start backend
    print_header "🔙 Starting Backend Server..."
    
    cd backend
    
    # Activate virtual environment and start server
    (
        source venv/bin/activate
        print_status "Activated Python virtual environment"
        print_status "Starting FastAPI server on http://localhost:8000"
        
        # Create necessary directories
        mkdir -p uploads projects logs
        
        # Start the backend server
        python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --log-level info
    ) &
    
    BACKEND_PID=$!
    cd ..
    
    # Wait for backend to start
    print_status "Waiting for backend to start..."
    sleep 5
    
    # Check if backend is running
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        print_error "Backend failed to start"
        exit 1
    fi
    
    # Test backend health
    for i in {1..10}; do
        if curl -s http://localhost:8000/ >/dev/null 2>&1; then
            print_success "Backend is running and responsive"
            break
        fi
        if [ $i -eq 10 ]; then
            print_error "Backend is not responding after 30 seconds"
            exit 1
        fi
        sleep 3
    done
    
    echo
    
    # Start frontend
    print_header "🔗 Starting Frontend Server..."
    
    cd frontend
    
    print_status "Starting React development server on http://localhost:3000"
    
    # Start the frontend server
    (
        # Suppress the automatic browser opening
        export BROWSER=none
        npm start
    ) &
    
    FRONTEND_PID=$!
    cd ..
    
    # Wait for frontend to start
    print_status "Waiting for frontend to start..."
    sleep 10
    
    # Check if frontend is running
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        print_error "Frontend failed to start"
        exit 1
    fi
    
    # Test frontend health
    for i in {1..15}; do
        if curl -s http://localhost:3000/ >/dev/null 2>&1; then
            print_success "Frontend is running and responsive"
            break
        fi
        if [ $i -eq 15 ]; then
            print_error "Frontend is not responding after 45 seconds"
            exit 1
        fi
        sleep 3
    done
    
    echo
    
    # Success message
    print_header "🎉 GROMACS GUI Platform Started Successfully!"
    echo
    print_success "Services are running:"
    echo -e "${CYAN}  Frontend (Web Interface): ${NC}http://localhost:3000"
    echo -e "${CYAN}  Backend API:              ${NC}http://localhost:8000"
    echo -e "${CYAN}  API Documentation:        ${NC}http://localhost:8000/docs"
    echo -e "${CYAN}  Interactive API:          ${NC}http://localhost:8000/redoc"
    echo
    
    print_status "Process IDs:"
    echo -e "  Backend PID:  ${BACKEND_PID}"
    echo -e "  Frontend PID: ${FRONTEND_PID}"
    echo
    
    print_warning "Press Ctrl+C to stop all services"
    echo
    
    # Optional: Open browser
    if command_exists open; then
        # macOS
        print_status "Opening browser..."
        open http://localhost:3000
    elif command_exists xdg-open; then
        # Linux
        print_status "Opening browser..."
        xdg-open http://localhost:3000
    elif command_exists start; then
        # Windows
        print_status "Opening browser..."
        start http://localhost:3000
    fi
    
    # Monitor processes
    print_status "Monitoring services... (Ctrl+C to stop)"
    echo
    
    # Wait for processes and monitor their health
    while true; do
        # Check if backend is still running
        if ! kill -0 $BACKEND_PID 2>/dev/null; then
            print_error "Backend process died unexpectedly"
            break
        fi
        
        # Check if frontend is still running
        if ! kill -0 $FRONTEND_PID 2>/dev/null; then
            print_error "Frontend process died unexpectedly"
            break
        fi
        
        # Show a heartbeat every 30 seconds
        sleep 30
        echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} Services running normally..."
    done
}

# Handle script arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "GROMACS GUI Platform Development Startup Script"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  help, -h, --help    Show this help message"
        echo "  check               Check prerequisites only"
        echo "  kill                Kill any running services"
        echo
        echo "This script starts both backend and frontend services for development."
        echo "Make sure you have run './scripts/setup.sh' first."
        echo
        exit 0
        ;;
    "check")
        print_status "Checking prerequisites only..."
        
        # Check commands
        for cmd in python3 node npm; do
            if command_exists $cmd; then
                print_success "$cmd: $(which $cmd)"
            else
                print_error "$cmd: not found"
            fi
        done
        
        # Check directories
        for dir in backend frontend backend/venv frontend/node_modules; do
            if [ -d "$dir" ]; then
                print_success "$dir: exists"
            else
                print_error "$dir: not found"
            fi
        done
        
        exit 0
        ;;
    "kill")
        print_status "Killing any running services..."
        kill_port 8000
        kill_port 3000
        print_success "Done"
        exit 0
        ;;
    "")
        # Default: run main function
        main
        ;;
    *)
        print_error "Unknown option: $1"
        print_error "Use '$0 help' for usage information"
        exit 1
        ;;
esac
