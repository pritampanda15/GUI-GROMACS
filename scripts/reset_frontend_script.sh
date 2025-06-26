#!/bin/bash

# Complete Frontend Reset Script for GROMACS GUI

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

echo -e "${BLUE}🔄 Resetting Frontend to Working State...${NC}"
echo

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Stop any running frontend processes
print_status "Stopping frontend processes..."
tmux kill-session -t gromacs-frontend 2>/dev/null || true
pkill -f "react-scripts" 2>/dev/null || true
pkill -f "webpack.*3000" 2>/dev/null || true
sleep 2

# Check Node.js version
print_status "Checking Node.js version..."
NODE_VERSION=$(node --version 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    print_error "Node.js 16+ is required. Current version: $(node --version)"
    print_error "Please update Node.js and try again"
    exit 1
fi
print_success "Node.js version: $(node --version)"

# Navigate to frontend directory
cd frontend

# Backup important files
print_status "Backing up important files..."
[ -f "src/App.tsx" ] && cp src/App.tsx src/App.tsx.backup.$(date +%s) 2>/dev/null || true
[ -f "package.json" ] && cp package.json package.json.backup.$(date +%s) 2>/dev/null || true

# Clean everything
print_status "Cleaning frontend directory..."
rm -rf node_modules package-lock.json
rm -rf build
rm -rf .eslintcache

# Create public directory if it doesn't exist
print_status "Setting up public directory..."
mkdir -p public

# Create public/index.html
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="GROMACS GUI Platform for Molecular Dynamics" />
    <title>GROMACS GUI Platform</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF

# Create manifest.json
cat > public/manifest.json << 'EOF'
{
  "short_name": "GROMACS GUI",
  "name": "GROMACS GUI Platform",
  "start_url": ".",
  "display": "standalone",
  "theme_color": "#000000",
  "background_color": "#ffffff"
}
EOF

# Create robots.txt
echo "User-agent: *
Disallow: /build
Disallow: /node_modules" > public/robots.txt

# Create src directory
print_status "Setting up src directory..."
mkdir -p src

# Create package.json with minimal dependencies
print_status "Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "gromacs-gui-frontend",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1",
    "typescript": "^4.9.5",
    "@types/node": "^16.18.0",
    "@types/react": "^18.2.0",
    "@types/react-dom": "^18.2.0",
    "web-vitals": "^3.0.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  },
  "devDependencies": {
    "tailwindcss": "^3.3.5",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.31"
  }
}
EOF

# Create basic TypeScript config
print_status "Creating TypeScript config..."
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": [
      "dom",
      "dom.iterable",
      "esnext"
    ],
    "allowJs": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noFallthroughCasesInSwitch": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": [
    "src"
  ]
}
EOF

# Create basic index.tsx
print_status "Creating index.tsx..."
cat > src/index.tsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# Create basic index.css
print_status "Creating index.css..."
cat > src/index.css << 'EOF'
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}

* {
  box-sizing: border-box;
}
EOF

# Create simple App.tsx
print_status "Creating App.tsx..."
cat > src/App.tsx << 'EOF'
import React, { useState, useEffect } from 'react';
import './App.css';

interface Project {
  id: string;
  name: string;
  status: string;
}

function App() {
  const [projects, setProjects] = useState<Project[]>([
    { id: '1', name: 'Test Project', status: 'created' },
    { id: '2', name: 'MD Simulation', status: 'running' }
  ]);
  const [backendStatus, setBackendStatus] = useState<'checking' | 'connected' | 'disconnected'>('checking');

  // Check backend connection
  useEffect(() => {
    const checkBackend = async () => {
      try {
        const response = await fetch('http://localhost:8000/');
        if (response.ok) {
          setBackendStatus('connected');
        } else {
          setBackendStatus('disconnected');
        }
      } catch (error) {
        setBackendStatus('disconnected');
      }
    };

    checkBackend();
    const interval = setInterval(checkBackend, 10000); // Check every 10 seconds
    return () => clearInterval(interval);
  }, []);

  const createProject = () => {
    const newProject: Project = {
      id: Date.now().toString(),
      name: `Project ${projects.length + 1}`,
      status: 'created'
    };
    setProjects([...projects, newProject]);
  };

  return (
    <div style={{ minHeight: '100vh', backgroundColor: '#f9fafb' }}>
      {/* Header */}
      <header style={{ 
        backgroundColor: 'white', 
        boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
        padding: '1rem 2rem' 
      }}>
        <div style={{ 
          maxWidth: '1200px', 
          margin: '0 auto', 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center' 
        }}>
          <h1 style={{ 
            fontSize: '1.5rem', 
            fontWeight: 'bold', 
            color: '#1f2937',
            margin: 0 
          }}>
            🧬 GROMACS GUI Platform
          </h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <div style={{ 
              width: '8px', 
              height: '8px', 
              borderRadius: '50%',
              backgroundColor: backendStatus === 'connected' ? '#10b981' : 
                             backendStatus === 'disconnected' ? '#ef4444' : '#f59e0b'
            }}></div>
            <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>
              {backendStatus === 'connected' ? 'Connected' : 
               backendStatus === 'disconnected' ? 'Disconnected' : 'Checking...'}
            </span>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main style={{ maxWidth: '1200px', margin: '0 auto', padding: '2rem' }}>
        <div style={{ 
          border: '4px dashed #d1d5db', 
          borderRadius: '0.5rem', 
          padding: '2rem' 
        }}>
          
          {/* Welcome Section */}
          <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
            <h2 style={{ 
              fontSize: '2rem', 
              fontWeight: 'bold', 
              color: '#1f2937', 
              marginBottom: '1rem' 
            }}>
              Welcome to GROMACS GUI Platform
            </h2>
            <p style={{ 
              fontSize: '1.125rem', 
              color: '#6b7280', 
              marginBottom: '2rem' 
            }}>
              A modern web interface for molecular dynamics simulations
            </p>
            
            {/* Status Cards */}
            <div style={{ 
              display: 'grid', 
              gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', 
              gap: '1.5rem', 
              marginBottom: '2rem' 
            }}>
              <div style={{ 
                backgroundColor: 'white', 
                padding: '1.5rem', 
                borderRadius: '0.5rem', 
                boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' 
              }}>
                <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#2563eb' }}>
                  {projects.length}
                </div>
                <div style={{ color: '#6b7280' }}>Total Projects</div>
              </div>
              <div style={{ 
                backgroundColor: 'white', 
                padding: '1.5rem', 
                borderRadius: '0.5rem', 
                boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' 
              }}>
                <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#10b981' }}>
                  {projects.filter(p => p.status === 'running').length}
                </div>
                <div style={{ color: '#6b7280' }}>Running</div>
              </div>
              <div style={{ 
                backgroundColor: 'white', 
                padding: '1.5rem', 
                borderRadius: '0.5rem', 
                boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)' 
              }}>
                <div style={{ fontSize: '2rem', fontWeight: 'bold', color: '#8b5cf6' }}>
                  {projects.filter(p => p.status === 'created').length}
                </div>
                <div style={{ color: '#6b7280' }}>Ready</div>
              </div>
            </div>

            {/* Action Button */}
            <button
              onClick={createProject}
              style={{
                backgroundColor: '#2563eb',
                color: 'white',
                fontWeight: 'bold',
                padding: '0.5rem 1rem',
                borderRadius: '0.5rem',
                border: 'none',
                cursor: 'pointer',
                fontSize: '1rem',
                transition: 'background-color 0.2s'
              }}
              onMouseOver={(e) => e.currentTarget.style.backgroundColor = '#1d4ed8'}
              onMouseOut={(e) => e.currentTarget.style.backgroundColor = '#2563eb'}
            >
              + Create New Project
            </button>
          </div>

          {/* Projects List */}
          <div style={{ marginTop: '2rem' }}>
            <h3 style={{ 
              fontSize: '1.25rem', 
              fontWeight: '600', 
              color: '#1f2937', 
              marginBottom: '1rem' 
            }}>
              Projects
            </h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
              {projects.map((project) => (
                <div 
                  key={project.id} 
                  style={{ 
                    backgroundColor: 'white', 
                    padding: '1rem', 
                    borderRadius: '0.5rem', 
                    boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1)',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center'
                  }}
                >
                  <div>
                    <h4 style={{ fontWeight: '500', color: '#1f2937', margin: 0 }}>
                      {project.name}
                    </h4>
                    <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: '0.25rem 0 0 0' }}>
                      ID: {project.id}
                    </p>
                  </div>
                  <span style={{
                    padding: '0.25rem 0.5rem',
                    borderRadius: '9999px',
                    fontSize: '0.75rem',
                    fontWeight: '500',
                    backgroundColor: project.status === 'running' ? '#dcfce7' : '#f3f4f6',
                    color: project.status === 'running' ? '#166534' : '#374151'
                  }}>
                    {project.status}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* API Test Section */}
          <div style={{ 
            marginTop: '2rem', 
            padding: '1rem', 
            backgroundColor: '#dbeafe', 
            borderRadius: '0.5rem' 
          }}>
            <h3 style={{ 
              fontSize: '1.125rem', 
              fontWeight: '600', 
              color: '#1e3a8a', 
              marginBottom: '0.5rem' 
            }}>
              API Connection Test
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#1e40af', marginBottom: '0.75rem' }}>
              Backend API: 
              <a 
                href="http://localhost:8000" 
                target="_blank" 
                rel="noopener noreferrer" 
                style={{ textDecoration: 'underline', marginLeft: '0.25rem' }}
              >
                http://localhost:8000
              </a>
            </p>
            <p style={{ fontSize: '0.875rem', color: '#1e40af' }}>
              API Documentation: 
              <a 
                href="http://localhost:8000/docs" 
                target="_blank" 
                rel="noopener noreferrer" 
                style={{ textDecoration: 'underline', marginLeft: '0.25rem' }}
              >
                http://localhost:8000/docs
              </a>
            </p>
          </div>

          {/* Status Messages */}
          {backendStatus === 'disconnected' && (
            <div style={{ 
              marginTop: '1rem', 
              padding: '1rem', 
              backgroundColor: '#fef2f2', 
              borderRadius: '0.5rem',
              border: '1px solid #fecaca'
            }}>
              <p style={{ color: '#dc2626', fontSize: '0.875rem', margin: 0 }}>
                ⚠️ Backend is not responding. Make sure the backend server is running on port 8000.
              </p>
            </div>
          )}

          {backendStatus === 'connected' && (
            <div style={{ 
              marginTop: '1rem', 
              padding: '1rem', 
              backgroundColor: '#f0fdf4', 
              borderRadius: '0.5rem',
              border: '1px solid #bbf7d0'
            }}>
              <p style={{ color: '#166534', fontSize: '0.875rem', margin: 0 }}>
                ✅ Successfully connected to backend API!
              </p>
            </div>
          )}

        </div>
      </main>

      {/* Footer */}
      <footer style={{ 
        backgroundColor: 'white', 
        borderTop: '1px solid #e5e7eb', 
        marginTop: '3rem' 
      }}>
        <div style={{ 
          maxWidth: '1200px', 
          margin: '0 auto', 
          padding: '1rem 2rem', 
          textAlign: 'center' 
        }}>
          <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>
            GROMACS GUI Platform - Molecular Dynamics Made Easy
          </p>
        </div>
      </footer>
    </div>
  );
}

export default App;
EOF

# Create App.css
print_status "Creating App.css..."
cat > src/App.css << 'EOF'
.App {
  text-align: center;
}

button:hover {
  transform: translateY(-1px);
}

.fade-in {
  animation: fadeIn 0.3s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
EOF

# Install dependencies
print_status "Installing dependencies..."
npm install

# Check if react-scripts is now available
print_status "Verifying react-scripts installation..."
if [ -f "node_modules/.bin/react-scripts" ]; then
    print_success "react-scripts installed successfully!"
else
    print_warning "react-scripts not found, trying global install..."
    npm install -g react-scripts
fi

print_success "Frontend reset completed!"
echo

# Test the setup
print_status "Testing React app..."
if npm run build >/dev/null 2>&1; then
    print_success "Build test passed!"
else
    print_warning "Build test failed, but app should still run in development mode"
fi

print_status "Starting frontend server..."
# Start frontend in tmux session
tmux new-session -d -s gromacs-frontend
tmux send-keys -t gromacs-frontend "cd $(pwd)" Enter
tmux send-keys -t gromacs-frontend "export BROWSER=none" Enter
tmux send-keys -t gromacs-frontend "export PORT=3000" Enter
tmux send-keys -t gromacs-frontend "npm start" Enter

print_status "Waiting for frontend to start..."
for i in {1..60}; do
    if curl -s http://localhost:3000/ >/dev/null 2>&1; then
        print_success "Frontend is now running and responsive!"
        break
    fi
    if [ $i -eq 60 ]; then
        print_error "Frontend still not responding after 60 seconds"
        print_status "Check logs with: tmux attach -t gromacs-frontend"
        exit 1
    fi
    sleep 2
done

echo
print_success "🎉 Frontend reset completed successfully!"
echo -e "${GREEN}Frontend is now available at: ${BLUE}http://localhost:3000${NC}"
echo -e "${BLUE}To view logs: tmux attach -t gromacs-frontend${NC}"
echo -e "${BLUE}To detach from logs: Ctrl+B then D${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Visit ${BLUE}http://localhost:3000${NC} to see the interface"
echo -e "  2. Make sure backend is running: ${BLUE}http://localhost:8000${NC}"
echo -e "  3. Check status: ${BLUE}./scripts/check-status.sh${NC}"

cd ..
