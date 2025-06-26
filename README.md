# GROMACS GUI Platform 🧬

A modern, web-based platform for managing and executing GROMACS molecular dynamics simulations with an intuitive graphical interface.

## Features

### ✨ **Core Functionality**
- **Project Management**: Create, organize, and manage multiple MD simulation projects
- **File Upload & Validation**: Support for protein structures (.pdb, .gro), ligands (.mol2, .sdf), and topology files (.itp, .top)
- **Force Field Selection**: Support for AMBER, CHARMM, GROMOS, and OPLS-AA force fields
- **Real-time Monitoring**: Live simulation progress tracking with WebSocket connections
- **Interactive Analysis**: Built-in plotting tools for RMSD, RMSF, and energy analysis
- **3D Visualization**: Integrated molecular viewer for structure inspection

### 🎨 **User Experience**
- **Modern UI**: Clean, professional interface with dark/light mode support
- **Responsive Design**: Works seamlessly on desktop and tablet devices
- **Drag & Drop**: Intuitive file upload with progress tracking
- **Real-time Logs**: Live streaming of GROMACS output with filtering and search
- **Dashboard Overview**: Project status, statistics, and quick actions

### ⚡ **Technical Features**
- **GPU Acceleration**: Support for CUDA-enabled GROMACS simulations
- **Scalable Architecture**: FastAPI backend with React frontend
- **Docker Support**: Easy deployment with container orchestration
- **WebSocket Integration**: Real-time communication for live updates
- **RESTful API**: Well-documented API for integration and automation

## Quick Start

### Prerequisites
- **Python 3.8+**
- **Node.js 16+**
- **GROMACS 2023+** (installed and available in PATH)
- **Docker & Docker Compose** (optional, for containerized deployment)

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd gromacs-gui
```

### 2. Backend Setup
```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables
cp .env.example .env
# Edit .env with your configuration

# Initialize database (optional)
alembic upgrade head

# Start the server
python -m app.main
```

The backend will be available at `http://localhost:8000`

### 3. Frontend Setup
```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm start
```

The frontend will be available at `http://localhost:3000`

### 4. Docker Deployment (Alternative)
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Project Structure

```
gromacs-gui/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/            # API endpoints
│   │   ├── core/           # Core functionality
│   │   ├── models/         # Database models
│   │   ├── services/       # Business logic
│   │   └── utils/          # Utilities
│   └── requirements.txt
├── frontend/               # React frontend
│   ├── src/
│   │   ├── components/     # UI components
│   │   ├── pages/          # Page components
│   │   ├── contexts/       # React contexts
│   │   ├── hooks/          # Custom hooks
│   │   └── services/       # API services
│   └── package.json
├── docker-compose.yml      # Container orchestration
└── README.md
```

## Configuration

### Backend Configuration (.env)
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/gromacs_gui

# Redis (for Celery)
REDIS_URL=redis://localhost:6379

# GROMACS
GROMACS_BIN_PATH=/usr/local/gromacs/bin
GROMACS_FORCE_FIELDS_PATH=/usr/local/gromacs/share/gromacs/top

# API Settings
CORS_ORIGINS=http://localhost:3000
```

### Frontend Configuration
Create `.env` in the frontend directory:
```bash
REACT_APP_API_URL=http://localhost:8000
REACT_APP_WS_URL=ws://localhost:8000
```

## Usage Guide

### 1. **Create a New Project**
- Navigate to the Dashboard
- Click "New Project"
- Enter project name and description
- Select the project to begin setup

### 2. **Upload Files**
- Go to "System Setup"
- Drag & drop your structure files (.pdb, .gro)
- Add ligand files if needed (.mol2, .sdf)
- Upload any custom topology files (.itp, .top)

### 3. **Configure Simulation**
- Select appropriate force field
- Set simulation parameters (temperature, pressure, time)
- Configure hardware settings (GPU, threads)
- Save configuration

### 4. **Run Simulation**
- Navigate to "Simulation Run"
- Review parameters
- Start the simulation
- Monitor progress in real-time

### 5. **Analyze Results**
- Go to "Analysis & Results"
- View RMSD, RMSF, and energy plots
- Export data for further analysis
- Generate comprehensive reports

## API Documentation

The API documentation is automatically generated and available at:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

### Key Endpoints
- `POST /api/projects/create` - Create new project
- `POST /api/projects/{id}/upload` - Upload files
- `POST /api/projects/{id}/configure` - Configure simulation
- `POST /api/projects/{id}/start` - Start simulation
- `GET /api/projects/{id}/logs` - Get simulation logs
- `WS /ws/{project_id}` - WebSocket for real-time updates

## Development

### Running Tests
```bash
# Backend tests
cd backend
pytest

# Frontend tests
cd frontend
npm test
```

### Code Style
- **Backend**: Black, isort, flake8
- **Frontend**: ESLint, Prettier

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Deployment

### Production Deployment
1. Update environment variables for production
2. Build frontend: `npm run build`
3. Use the production Docker Compose profile:
   ```bash
   docker-compose --profile production up -d
   ```

### Environment Variables for Production
```bash
# Security
SECRET_KEY=your-secret-key
ALLOWED_HOSTS=your-domain.com

# Database
DATABASE_URL=postgresql://user:password@postgres:5432/gromacs_gui

# SSL/HTTPS
USE_HTTPS=true
SSL_CERT_PATH=/path/to/cert.pem
SSL_KEY_PATH=/path/to/key.pem
```

## Troubleshooting

### Common Issues

**Backend won't start:**
- Check GROMACS installation: `gmx --version`
- Verify database connection
- Check Python dependencies

**Frontend connection issues:**
- Ensure backend is running on port 8000
- Check CORS configuration
- Verify API_URL in frontend .env

**GROMACS errors:**
- Check GROMACS installation and PATH
- Verify force field files are accessible
- Review simulation logs for specific errors

**File upload failures:**
- Check file permissions in upload directory
- Verify file size limits
- Ensure supported file formats

## System Requirements

### Minimum Requirements
- **CPU**: 4 cores
- **RAM**: 8GB
- **Storage**: 20GB free space
- **GPU**: Optional (CUDA-compatible for acceleration)

### Recommended Requirements
- **CPU**: 8+ cores
- **RAM**: 16GB+
- **Storage**: 100GB+ SSD
- **GPU**: NVIDIA GPU with CUDA support

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check the documentation at `/docs`
- Review the troubleshooting section above

## Acknowledgments

- GROMACS development team for the simulation engine
- React and FastAPI communities for excellent frameworks
- Contributors to the open-source libraries used in this project
