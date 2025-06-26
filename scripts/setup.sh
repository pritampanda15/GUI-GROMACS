#!/bin/bash

# GROMACS GUI Platform Setup Script
# This script sets up the development environment for the GROMACS GUI platform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check Python
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_success "Python found: $PYTHON_VERSION"
    else
        print_error "Python 3.8+ is required but not found"
        exit 1
    fi
    
    # Check Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION"
    else
        print_error "Node.js 16+ is required but not found"
        exit 1
    fi
    
    # Check npm
    if command_exists npm; then
        NPM_VERSION=$(npm --version)
        print_success "npm found: $NPM_VERSION"
    else
        print_error "npm is required but not found"
        exit 1
    fi
    
    # Check Docker (optional)
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_success "Docker found: $DOCKER_VERSION"
        DOCKER_AVAILABLE=true
    else
        print_warning "Docker not found - containerized deployment won't be available"
        DOCKER_AVAILABLE=false
    fi
    
    # Check GROMACS
    if command_exists gmx; then
        GMX_VERSION=$(gmx --version 2>&1 | head -n1 | cut -d' ' -f2)
        print_success "GROMACS found: $GMX_VERSION"
    else
        print_warning "GROMACS not found - please install GROMACS 2023+ for full functionality"
    fi
}

# Setup Python virtual environment
setup_backend() {
    print_status "Setting up backend environment..."
    
    cd backend
    
    # Create virtual environment
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip
    
    # Install requirements
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating .env file..."
        cp .env.example .env 2>/dev/null || cat > .env << EOF
# Database
DATABASE_URL=sqlite:///./gromacs_gui.db

# Redis (for production)
REDIS_URL=redis://localhost:6379

# GROMACS
GROMACS_BIN_PATH=/usr/local/gromacs/bin
GROMACS_FORCE_FIELDS_PATH=/usr/local/gromacs/share/gromacs/top

# API Settings
CORS_ORIGINS=http://localhost:3000

# Security
SECRET_KEY=your-secret-key-change-in-production
EOF
        print_success "Created .env file - please review and update as needed"
    fi
    
    # Create necessary directories
    mkdir -p uploads projects logs
    
    cd ..
    print_success "Backend setup completed"
}

# Setup frontend
setup_frontend() {
    print_status "Setting up frontend environment..."
    
    cd frontend
    
    # Install dependencies
    print_status "Installing Node.js dependencies..."
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating frontend .env file..."
        cat > .env << EOF
REACT_APP_API_URL=http://localhost:8000
REACT_APP_WS_URL=ws://localhost:8000
EOF
        print_success "Created frontend .env file"
    fi
    
    cd ..
    print_success "Frontend setup completed"
}

# Setup database
setup_database() {
    print_status "Setting up database..."
    
    cd backend
    source venv/bin/activate
    
    # Initialize database (if using Alembic)
    if [ -f "alembic.ini" ]; then
        print_status "Running database migrations..."
        alembic upgrade head
    else
        print_status "Creating database tables..."
        python -c "
from app.database import Base, engine
Base.metadata.create_all(bind=engine)
print('Database tables created successfully')
"
    fi
    
    cd ..
    print_success "Database setup completed"
}

# Create start scripts
create_start_scripts() {
    print_status "Creating startup scripts..."
    
    # Backend start script
    cat > scripts/start-backend.sh << 'EOF'
#!/bin/bash
cd backend
source venv/bin/activate
echo "Starting GROMACS GUI Backend..."
python -m app.main
EOF
    chmod +x scripts/start-backend.sh
    
    # Frontend start script
    cat > scripts/start-frontend.sh << 'EOF'
#!/bin/bash
cd frontend
echo "Starting GROMACS GUI Frontend..."
npm start
EOF
    chmod +x scripts/start-frontend.sh
    
    # Combined start script
    cat > scripts/start-dev.sh << 'EOF'
#!/bin/bash
echo "Starting GROMACS GUI Platform in development mode..."

# Function to kill background processes on exit
cleanup() {
    echo "Stopping services..."
    kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
    exit
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start backend
echo "Starting backend..."
cd backend
source venv/bin/activate
python -m app.main &
BACKEND_PID=$!
cd ..

# Wait a moment for backend to start
sleep 3

# Start frontend
echo "Starting frontend..."
cd frontend
npm start &
FRONTEND_PID=$!
cd ..

echo "Services started!"
echo "Backend: http://localhost:8000"
echo "Frontend: http://localhost:3000"
echo "Press Ctrl+C to stop all services"

# Wait for processes
wait $BACKEND_PID $FRONTEND_PID
EOF
    chmod +x scripts/start-dev.sh
    
    print_success "Startup scripts created"
}

# Main setup function
main() {
    echo "=================================================="
    echo "🧬 GROMACS GUI Platform Setup"
    echo "=================================================="
    echo
    
    # Create scripts directory if it doesn't exist
    mkdir -p scripts
    
    # Check requirements
    check_requirements
    echo
    
    # Setup backend
    setup_backend
    echo
    
    # Setup frontend
    setup_frontend
    echo
    
    # Setup database
    setup_database
    echo
    
    # Create start scripts
    create_start_scripts
    echo
    
    # Final instructions
    print_success "🎉 Setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Review and update configuration files:"
    echo "   - backend/.env"
    echo "   - frontend/.env"
    echo
    echo "2. Start the development environment:"
    echo "   ./scripts/start-dev.sh"
    echo
    echo "3. Or start services individually:"
    echo "   Backend:  ./scripts/start-backend.sh"
    echo "   Frontend: ./scripts/start-frontend.sh"
    echo
    
    if [ "$DOCKER_AVAILABLE" = true ]; then
        echo "4. Alternative: Use Docker Compose:"
        echo "   docker-compose up -d"
        echo
    fi
    
    echo "5. Access the application:"
    echo "   Frontend: http://localhost:3000"
    echo "   Backend API: http://localhost:8000"
    echo "   API Docs: http://localhost:8000/docs"
    echo
    print_success "Happy coding! 🚀"
}

# Run main function
main "$@"
